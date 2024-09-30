import 'dart:async';
import 'dart:io';

import 'package:another_xlider/another_xlider.dart';
import 'package:daisy/configs/reader_controller_type.dart';
import 'package:daisy/configs/reader_direction.dart';
import 'package:daisy/configs/reader_slider_position.dart';
import 'package:daisy/configs/reader_type.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:daisy/screens/components/content_error.dart';
import 'package:daisy/screens/components/content_loading.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../commons.dart';
import '../configs/two_page_gallery_direction.dart';
import '../src/rust/anime_home/proto.dart';
import 'components/image_cache_provider.dart';
import 'components/images.dart';

class ComicReaderScreen extends StatefulWidget {
  final ComicDetail comic;
  final int chapterId;
  final int initRank;
  final Future<ComicChapterDetail> Function(int chapterId) loadChapter;
  final bool fullScreenOnInit;

  const ComicReaderScreen({
    super.key,
    required this.comic,
    required this.chapterId,
    required this.initRank,
    required this.loadChapter,
    this.fullScreenOnInit = false,
  });

  @override
  State<StatefulWidget> createState() => _ComicReaderScreenState();
}

class _ComicReaderScreenState extends State<ComicReaderScreen> {
  late ReaderType _readerType;
  late ReaderDirection _readerDirection;
  late Future<ComicChapterDetail> _chapterFuture;
  bool _loaded = false;
  late bool _fullScreen;
  var _replace = false;

  void _load() {
    // todo multiple used setState and FutureBuilder, it is not good.
    setState(() {
      _readerType = currentReaderType;
      _readerDirection = currentReaderDirection;
      _chapterFuture = widget.loadChapter(widget.chapterId).then((value) {
        var _ = native.comicViewPage(
          comicId: value.comicId,
          chapterId: value.chapterId,
          chapterTitle: value.title,
          chapterOrder: value.chapterOrder,
          pageRank: widget.initRank,
        ); // 在后台
        setState(() {
          _loaded = true;
        });
        return value;
      });
    });
  }

  @override
  void initState() {
    _load();
    super.initState();
    _fullScreen = widget.fullScreenOnInit;
    if (_fullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    }
  }

  @override
  void dispose() {
    if (Platform.isAndroid || Platform.isIOS) {
      if (!_replace) {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _loaded ? null : AppBar(),
      body: FutureBuilder(
        future: _chapterFuture,
        builder:
            (BuildContext context, AsyncSnapshot<ComicChapterDetail> snapshot) {
          if (snapshot.hasError) {
            return ContentError(
              onRefresh: () async {
                setState(() {
                  _chapterFuture = native.comicChapterDetail(
                    comicId: widget.comic.id,
                    chapterId: widget.chapterId,
                  );
                });
              },
              error: snapshot.error,
              stackTrace: snapshot.stackTrace,
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const ContentLoading();
          }
          final chapter = snapshot.requireData;
          final screen = _ComicReader(
            comic: widget.comic,
            chapter: chapter,
            startIndex: widget.initRank,
            fullScreen: _fullScreen,
            reload: (int index) async {
              _replace = true;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (BuildContext context) {
                  return ComicReaderScreen(
                    comic: widget.comic,
                    chapterId: widget.chapterId,
                    initRank: index,
                    loadChapter: widget.loadChapter,
                    fullScreenOnInit: _fullScreen,
                  );
                }),
              );
            },
            onChangeEp: (int chapterId) async {
              _replace = true;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (BuildContext context) {
                  return ComicReaderScreen(
                    comic: widget.comic,
                    chapterId: chapterId,
                    initRank: 0,
                    loadChapter: widget.loadChapter,
                    fullScreenOnInit: _fullScreen,
                  );
                }),
              );
            },
            readerType: _readerType,
            readerDirection: _readerDirection,
            onFullScreenChange: _onFullScreenChange,
          );
          return readerKeyboardHolder(screen);
        },
      ),
    );
  }

  Future _onFullScreenChange(bool fullScreen) async {
    setState(() {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: fullScreen ? [] : SystemUiOverlay.values,
      );
      _fullScreen = fullScreen;
    });
  }
}

////////////////////////////////
// 仅支持安卓
// 监听后会拦截安卓手机音量键
// 仅最后一次监听生效
// event可能为DOWN/UP

const _listVolume = false;

var _volumeListenCount = 0;

void _onVolumeEvent(dynamic args) {
  _readerControllerEvent.broadcast(_ReaderControllerEventArgs("$args"));
}

EventChannel volumeButtonChannel = const EventChannel("volume_button");
StreamSubscription? volumeS;

void addVolumeListen() {
  _volumeListenCount++;
  if (_volumeListenCount == 1) {
    volumeS =
        volumeButtonChannel.receiveBroadcastStream().listen(_onVolumeEvent);
  }
}

void delVolumeListen() {
  _volumeListenCount--;
  if (_volumeListenCount == 0) {
    volumeS?.cancel();
  }
}

Widget readerKeyboardHolder(Widget widget) {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    widget = RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
            _readerControllerEvent.broadcast(_ReaderControllerEventArgs("UP"));
          }
          if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
            _readerControllerEvent
                .broadcast(_ReaderControllerEventArgs("DOWN"));
          }
        }
      },
      child: widget,
    );
  }
  return widget;
}

////////////////////////////////
bool noAnimation() => false;

Event<_ReaderControllerEventArgs> _readerControllerEvent =
    Event<_ReaderControllerEventArgs>();

class _ReaderControllerEventArgs extends EventArgs {
  final String key;

  _ReaderControllerEventArgs(this.key);
}

class _ComicReader extends StatefulWidget {
  final ComicDetail comic;
  final ComicChapterDetail chapter;
  final FutureOr Function(int) reload;
  final FutureOr Function(int) onChangeEp;
  final int startIndex;
  final ReaderType readerType;
  final ReaderDirection readerDirection;
  final bool fullScreen;
  final Function(bool) onFullScreenChange;

  const _ComicReader({
    required this.comic,
    required this.chapter,
    required this.reload,
    required this.onChangeEp,
    required this.startIndex,
    required this.readerType,
    required this.readerDirection,
    required this.fullScreen,
    required this.onFullScreenChange,
  });

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() {
    switch (readerType) {
      case ReaderType.webtoon:
        return _ComicReaderWebToonState();
      case ReaderType.gallery:
        return _ComicReaderGalleryState();
      case ReaderType.webToonFreeZoom:
        return _ListViewReaderState();
      case ReaderType.towPageGallery:
        return _TwoPageGalleryReaderState();
    }
  }
}

abstract class _ComicReaderState extends State<_ComicReader> {
  Widget _buildViewer();

  _needJumpTo(int pageIndex, bool animation);

  late int _current;
  late int _slider;

  void _onCurrentChange(int index) {
    if (index != _current) {
      setState(() {
        _current = index;
        _slider = index;
        // update viewLog
        var _ = native.comicViewPage(
          comicId: widget.chapter.comicId,
          chapterId: widget.chapter.chapterId,
          chapterTitle: widget.chapter.title,
          chapterOrder: widget.chapter.chapterOrder,
          pageRank: index,
        ); // 在后台线程入库
      });
    }
  }

  @override
  void initState() {
    _current = widget.startIndex;
    _slider = widget.startIndex;
    _readerControllerEvent.subscribe(_onPageControl);
    if (_listVolume) {
      addVolumeListen();
    }
    super.initState();
  }

  @override
  void dispose() {
    _readerControllerEvent.unsubscribe(_onPageControl);
    if (_listVolume) {
      delVolumeListen();
    }
    super.dispose();
  }

  void _onPageControl(_ReaderControllerEventArgs? args) {
    if (args != null) {
      var event = args.key;
      switch (event) {
        case "UP":
          if (_current > 0) {
            _needJumpTo(_current - 1, true);
          }
          break;
        case "DOWN":
          if (_current < widget.chapter.pageUrl.length - 1) {
            _needJumpTo(_current + 1, true);
          }
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (currentReaderControllerType) {
      // 按钮
      case ReaderControllerType.controller:
        return Stack(
          children: [
            _buildViewer(),
            _buildBar(_buildFullScreenControllerStackItem()),
          ],
        );
      case ReaderControllerType.touchOnce:
        return Stack(
          children: [
            _buildTouchOnceControllerAction(_buildViewer()),
            _buildBar(Container()),
          ],
        );
      case ReaderControllerType.touchDouble:
        return Stack(
          children: [
            _buildTouchDoubleControllerAction(_buildViewer()),
            _buildBar(Container()),
          ],
        );
      case ReaderControllerType.touchDoubleOnceNext:
        return Stack(
          children: [
            _buildTouchDoubleOnceNextControllerAction(_buildViewer()),
            _buildBar(Container()),
          ],
        );
      case ReaderControllerType.threeArea:
        return Stack(
          children: [
            _buildViewer(),
            _buildBar(_buildThreeAreaControllerAction()),
          ],
        );
    }
  }

  Widget _buildFullScreenControllerStackItem() {
    if (currentReaderSliderPosition == ReaderSliderPosition.bottom &&
        !widget.fullScreen) {
      return Container();
    }
    return Align(
      alignment: Alignment.bottomLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 4),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            color: Color(0x88000000),
          ),
          child: GestureDetector(
            onTap: () {
              widget.onFullScreenChange(!widget.fullScreen);
            },
            child: Icon(
              widget.fullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen_outlined,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTouchOnceControllerAction(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        widget.onFullScreenChange(!widget.fullScreen);
      },
      child: child,
    );
  }

  Widget _buildTouchDoubleControllerAction(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () {
        widget.onFullScreenChange(!widget.fullScreen);
      },
      child: child,
    );
  }

  Widget _buildTouchDoubleOnceNextControllerAction(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _readerControllerEvent.broadcast(_ReaderControllerEventArgs("DOWN"));
      },
      onDoubleTap: () {
        widget.onFullScreenChange(!widget.fullScreen);
      },
      child: child,
    );
  }

  Widget _buildThreeAreaControllerAction() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        var up = Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _readerControllerEvent
                  .broadcast(_ReaderControllerEventArgs("UP"));
            },
            child: Container(),
          ),
        );
        var down = Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _readerControllerEvent
                  .broadcast(_ReaderControllerEventArgs("DOWN"));
            },
            child: Container(),
          ),
        );
        var fullScreen = Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => widget.onFullScreenChange(!widget.fullScreen),
            child: Container(),
          ),
        );
        late Widget child;
        switch (currentReaderDirection) {
          case ReaderDirection.topToBottom:
            child = Column(children: [
              up,
              fullScreen,
              down,
            ]);
            break;
          case ReaderDirection.leftToRight:
            child = Row(children: [
              up,
              fullScreen,
              down,
            ]);
            break;
          case ReaderDirection.rightToLeft:
            child = Row(children: [
              down,
              fullScreen,
              up,
            ]);
            break;
        }
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: child,
        );
      },
    );
  }

  Widget _buildBar(Widget child) {
    switch (currentReaderSliderPosition) {
      case ReaderSliderPosition.bottom:
        return Column(
          children: [
            _buildAppBar(),
            Expanded(child: child),
            widget.fullScreen
                ? Container()
                : Container(
                    height: 45,
                    color: const Color(0x88000000),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(width: 15),
                        IconButton(
                          icon: const Icon(Icons.fullscreen),
                          color: Colors.white,
                          onPressed: () {
                            widget.onFullScreenChange(!widget.fullScreen);
                          },
                        ),
                        Container(width: 10),
                        Expanded(
                          child: currentReaderType != ReaderType.webToonFreeZoom
                              ? _buildSliderBottom()
                              : Container(),
                        ),
                        Container(width: 10),
                        IconButton(
                          icon: const Icon(Icons.skip_next_outlined),
                          color: Colors.white,
                          onPressed: _onNextAction,
                        ),
                        Container(width: 15),
                      ],
                    ),
                  ),
            widget.fullScreen
                ? Container()
                : Container(
                    color: const Color(0x88000000),
                    child: SafeArea(
                      top: false,
                      child: Container(),
                    ),
                  ),
          ],
        );
      case ReaderSliderPosition.right:
        return Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Stack(
                children: [
                  child,
                  _buildSliderRight(),
                ],
              ),
            ),
          ],
        );
      case ReaderSliderPosition.left:
        return Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Stack(
                children: [
                  child,
                  _buildSliderLeft(),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildAppBar() => widget.fullScreen
      ? Container()
      : AppBar(
          backgroundColor: Colors.black.withOpacity(.5),
          title: Text(widget.chapter.title),
          actions: [
            IconButton(
              onPressed: _onChooseEp,
              icon: const Icon(Icons.menu_open),
            ),
            IconButton(
              onPressed: _onMoreSetting,
              icon: const Icon(Icons.more_horiz),
            ),
          ],
        );

  Widget _buildSliderBottom() {
    return Column(
      children: [
        Expanded(child: Container()),
        SizedBox(
          height: 25,
          child: _buildSliderWidget(Axis.horizontal),
        ),
        Expanded(child: Container()),
      ],
    );
  }

  Widget _buildSliderLeft() => widget.fullScreen
      ? Container()
      : Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 35,
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0x66000000),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              padding:
                  const EdgeInsets.only(top: 10, bottom: 10, left: 6, right: 5),
              child: Center(
                child: _buildSliderWidget(Axis.vertical),
              ),
            ),
          ),
        );

  Widget _buildSliderRight() => widget.fullScreen
      ? Container()
      : Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 35,
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0x66000000),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              padding:
                  const EdgeInsets.only(top: 10, bottom: 10, left: 5, right: 6),
              child: Center(
                child: _buildSliderWidget(Axis.vertical),
              ),
            ),
          ),
        );

  Widget _buildSliderWidget(Axis axis) {
    return FlutterSlider(
      axis: axis,
      values: [_slider.toDouble()],
      min: 0,
      max: (widget.chapter.pageUrl.length - 1).toDouble(),
      onDragging: (handlerIndex, lowerValue, upperValue) {
        _slider = (lowerValue.toInt());
      },
      onDragCompleted: (handlerIndex, lowerValue, upperValue) {
        _slider = (lowerValue.toInt());
        if (_slider != _current) {
          _needJumpTo(_slider, false);
        }
      },
      trackBar: FlutterSliderTrackBar(
        inactiveTrackBar: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.shade300,
        ),
        activeTrackBar: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      step: const FlutterSliderStep(
        step: 1,
        isPercentRange: false,
      ),
      tooltip: FlutterSliderTooltip(custom: (value) {
        double a = value + 1;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: ShapeDecoration(
            color: Colors.black.withAlpha(0xCC),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.circular(3)),
          ),
          child: Text(
            '${a.toInt()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        );
      }),
    );
  }

  Future _onChooseEp() async {
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xAA000000),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * (.45),
          child: _EpChooser(widget.comic, widget.chapter, widget.onChangeEp),
        );
      },
    );
  }

  //
  _onMoreSetting() async {
    await showMaterialModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xAA000000),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height / 2,
          child: _SettingPanel(),
        );
      },
    );
    if (widget.readerDirection != currentReaderDirection ||
        widget.readerType != currentReaderType) {
      widget.reload(_current);
    } else {
      setState(() {});
    }
  }

  //
  double _appBarHeight() {
    return Scaffold.of(context).appBarMaxHeight ?? 0;
  }

  double _bottomBarHeight() {
    return 45;
  }

  bool _fullscreenController() {
    switch (currentReaderControllerType) {
      case ReaderControllerType.touchOnce:
        return false;
      case ReaderControllerType.controller:
        return false;
      case ReaderControllerType.touchDouble:
        return false;
      case ReaderControllerType.touchDoubleOnceNext:
        return false;
      case ReaderControllerType.threeArea:
        return true;
    }
  }

  bool _hasNextEp() {
    // 确定分卷
    ComicChapter? v;
    ComicChapterInfo? c;
    for (var _v in widget.comic.chapters) {
      for (var _c in _v.data) {
        if (_c.chapterId == widget.chapter.chapterId) {
          v = _v;
          c = _c;
        }
      }
    }
    if (v == null || c == null) {
      return false;
    }
    // 收集orders
    List<int> orders = [];
    for (var i = 0; i < v.data.length; i++) {
      orders.add(v.data[i].chapterOrder);
    }
    orders.sort((a, b) => a - b);
    // 确定有没有下一章节
    return c.chapterOrder < orders.last;
  }

  void _onNextAction() {
    if (_hasNextEp()) {
      // 确定分卷
      ComicChapter? v;
      ComicChapterInfo? c;
      for (var _v in widget.comic.chapters) {
        for (var _c in _v.data) {
          if (_c.chapterId == widget.chapter.chapterId) {
            v = _v;
            c = _c;
          }
        }
      }
      if (v == null || c == null) {
        defaultToast(context, "已经到头了");
        return;
      }
      // 收集orders
      List<int> orders = [];
      for (var i = 0; i < v.data.length; i++) {
        orders.add(v.data[i].chapterOrder);
      }
      orders.sort((a, b) => a - b);
      // 确定有没有下一章节
      int newEpOrder = orders[orders.indexOf(c.chapterOrder) + 1];
      for (var i = 0; i < v.data.length; i++) {
        if (v.data[i].chapterOrder == newEpOrder) {
          widget.onChangeEp(v.data[i].chapterId);
        }
      }
    } else {
      defaultToast(context, "已经到头了");
    }
  }
}

class _EpChooser extends StatefulWidget {
  final ComicDetail comicDetail;
  final ComicChapterDetail chapter;
  final FutureOr Function(int) onChangeEp;

  const _EpChooser(this.comicDetail, this.chapter, this.onChangeEp);

  @override
  State<StatefulWidget> createState() => _EpChooserState();
}

class _EpChooserState extends State<_EpChooser> {
  int position = 0;
  List<Widget> widgets = [];

  @override
  void initState() {
    for (var c in widget.comicDetail.chapters) {
      widgets.add(Container(
        margin: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 5),
        child: Text(
          c.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
      final cd = [...c.data];
      cd.sort((o1, o2) => o1.chapterOrder - o2.chapterOrder);
      for (var ci in c.data) {
        if (widget.chapter.chapterId == ci.chapterId) {
          position = widgets.length > 2 ? widgets.length - 2 : 0;
        }
        widgets.add(Container(
          margin: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
          decoration: BoxDecoration(
            color: widget.chapter.chapterId == ci.chapterId
                ? Colors.grey.withAlpha(100)
                : null,
            border: Border.all(
              color: const Color(0xff484c60),
              style: BorderStyle.solid,
              width: .5,
            ),
          ),
          child: MaterialButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onChangeEp(ci.chapterId);
            },
            textColor: Colors.white,
            child: Text(ci.chapterTitle),
          ),
        ));
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      initialScrollIndex: position,
      itemCount: widgets.length,
      itemBuilder: (BuildContext context, int index) => widgets[index],
    );
  }
}

class _SettingPanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingPanelState();
}

class _SettingPanelState extends State<_SettingPanel> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          children: [
            _bottomIcon(
              icon: Icons.crop_sharp,
              title: readerDirectionName(currentReaderDirection, context),
              onPressed: () async {
                await chooseReaderDirection(context);
                setState(() {});
              },
            ),
            _bottomIcon(
              icon: Icons.view_day_outlined,
              title: readerTypeName(currentReaderType, context),
              onPressed: () async {
                await chooseReaderType(context);
                setState(() {});
              },
            ),
            _bottomIcon(
              icon: Icons.control_camera_outlined,
              title: currentReaderControllerTypeName(),
              onPressed: () async {
                await chooseReaderControllerType(context);
                setState(() {});
              },
            ),
            _bottomIcon(
              icon: Icons.straighten_sharp,
              title: currentReaderSliderPositionName,
              onPressed: () async {
                await chooseReaderSliderPosition(context);
                setState(() {});
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _bottomIcon({
    required IconData icon,
    required String title,
    required void Function() onPressed,
  }) {
    return Expanded(
      child: Center(
        child: Column(
          children: [
            IconButton(
              iconSize: 55,
              icon: Column(
                children: [
                  Container(height: 3),
                  Icon(
                    icon,
                    size: 25,
                    color: Colors.white,
                  ),
                  Container(height: 3),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  Container(height: 3),
                ],
              ),
              onPressed: onPressed,
            )
          ],
        ),
      ),
    );
  }
}

class _ComicReaderWebToonState extends _ComicReaderState {
  var _controllerTime = DateTime.now().millisecondsSinceEpoch + 400;
  late final List<Size?> _trueSizes = [];
  late final ItemScrollController _itemScrollController;
  late final ItemPositionsListener _itemPositionsListener;

  @override
  void initState() {
    for (var e in widget.chapter.pageUrl) {
      _trueSizes.add(null);
    }
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
    _itemPositionsListener.itemPositions.addListener(_onListCurrentChange);
    super.initState();
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onListCurrentChange);
    super.dispose();
  }

  void _onListCurrentChange() {
    var to = _itemPositionsListener.itemPositions.value.first.index;
    // 包含一个下一章, 假设5张图片 0,1,2,3,4 length=5, 下一章=5
    if (to >= 0 && to < widget.chapter.pageUrl.length) {
      super._onCurrentChange(to);
    }
  }

  @override
  void _needJumpTo(int index, bool animation) {
    if (noAnimation() || animation == false) {
      _itemScrollController.jumpTo(
        index: index,
      );
    } else {
      if (DateTime.now().millisecondsSinceEpoch < _controllerTime) {
        return;
      }
      _controllerTime = DateTime.now().millisecondsSinceEpoch + 400;
      _itemScrollController.scrollTo(
        index: index, // 减1 当前position 再减少1 前一个
        duration: const Duration(milliseconds: 400),
      );
    }
  }

  @override
  Widget _buildViewer() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: _buildList(),
    );
  }

  Widget _buildList() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // reload _images size
        List<Widget> images = [];
        for (var index = 0; index < widget.chapter.pageUrl.length; index++) {
          late Size renderSize;
          if (_trueSizes[index] != null) {
            if (widget.readerDirection == ReaderDirection.topToBottom) {
              renderSize = Size(
                constraints.maxWidth,
                constraints.maxWidth *
                    _trueSizes[index]!.height /
                    _trueSizes[index]!.width,
              );
            } else {
              var maxHeight = constraints.maxHeight -
                  super._appBarHeight() -
                  (widget.fullScreen
                      ? super._appBarHeight()
                      : super._bottomBarHeight());
              renderSize = Size(
                maxHeight *
                    _trueSizes[index]!.width /
                    _trueSizes[index]!.height,
                maxHeight,
              );
            }
          } else {
            if (widget.readerDirection == ReaderDirection.topToBottom) {
              renderSize = Size(constraints.maxWidth, constraints.maxWidth / 2);
            } else {
              // ReaderDirection.LEFT_TO_RIGHT
              // ReaderDirection.RIGHT_TO_LEFT
              renderSize =
                  Size(constraints.maxWidth / 2, constraints.maxHeight);
            }
          }
          var currentIndex = index;
          onTrueSize(Size size) {
            setState(() {
              _trueSizes[currentIndex] = size;
            });
          }

          images.add(
            LoadingCacheImage(
              url: widget.chapter.pageUrl[index],
              useful: 'comic_reader',
              extendsFieldIntFirst: widget.comic.id,
              extendsFieldIntSecond: widget.chapter.chapterId,
              extendsFieldIntThird: index,
              onTrueSize: onTrueSize,
              width: renderSize.width,
              height: renderSize.height,
            ),
          );
        }
        return ScrollablePositionedList.builder(
          initialScrollIndex: widget.startIndex,
          scrollDirection: widget.readerDirection == ReaderDirection.topToBottom
              ? Axis.vertical
              : Axis.horizontal,
          reverse: widget.readerDirection == ReaderDirection.rightToLeft,
          padding: EdgeInsets.only(
            // 不管全屏与否, 滚动方向如何, 顶部永远保持间距
            top: super._appBarHeight(),
            bottom: widget.readerDirection == ReaderDirection.topToBottom
                ? 130 // 纵向滚动 底部永远都是130的空白
                : ( // 横向滚动
                    widget.fullScreen
                        ? super._appBarHeight() // 全屏时底部和顶部到屏幕边框距离一样保持美观
                        : super._bottomBarHeight())
            // 非全屏时, 顶部去掉顶部BAR的高度, 底部去掉底部BAR的高度, 形成看似填充的效果
            ,
          ),
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          itemCount: widget.chapter.pageUrl.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (widget.chapter.pageUrl.length == index) {
              return _buildNextEp();
            }
            return images[index];
          },
        );
      },
    );
  }

  Widget _buildNextEp() {
    if (super._fullscreenController()) {
      return Container();
    }
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(20),
      child: MaterialButton(
        onPressed: () {
          if (super._hasNextEp()) {
            super._onNextAction();
          } else {
            Navigator.of(context).pop();
          }
        },
        textColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.only(top: 40, bottom: 40),
          child: Text(super._hasNextEp() ? '下一章' : '结束阅读'),
        ),
      ),
    );
  }
}

class _ComicReaderGalleryState extends _ComicReaderState {
  late PageController _pageController;
  late PhotoViewGallery _gallery;
  final List<ImageProvider> _providers = [];

  @override
  void initState() {
    for (var i = 0; i < widget.chapter.pageUrl.length; i++) {
      _providers.add(ImageCacheProvider(
        url: widget.chapter.pageUrl[i],
        useful: 'comic_reader',
        extendsFieldIntFirst: widget.comic.id,
        extendsFieldIntSecond: widget.chapter.chapterId,
        extendsFieldIntThird: i,
      ));
    }
    _pageController = PageController(initialPage: widget.startIndex);
    _gallery = PhotoViewGallery.builder(
      scrollDirection: widget.readerDirection == ReaderDirection.topToBottom
          ? Axis.vertical
          : Axis.horizontal,
      reverse: widget.readerDirection == ReaderDirection.rightToLeft,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: (context, event) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return buildLoading(constraints.maxWidth, constraints.maxHeight);
        },
      ),
      pageController: _pageController,
      onPageChanged: _onGalleryPageChange,
      itemCount: widget.chapter.pageUrl.length,
      allowImplicitScrolling: true,
      builder: (BuildContext context, int index) {
        return PhotoViewGalleryPageOptions(
          filterQuality: FilterQuality.high,
          imageProvider: _providers[index],
          errorBuilder: (c, e, s) => LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return buildError(constraints.maxWidth, constraints.maxHeight);
            },
          ),
        );
      },
    );
    super.initState();
    _preloadJump(widget.startIndex, init: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget _buildViewer() {
    return Column(
      children: [
        Container(height: widget.fullScreen ? 0 : super._appBarHeight()),
        Expanded(
          child: Stack(
            children: [
              _gallery,
              _buildNextEpController(),
            ],
          ),
        ),
        Container(height: widget.fullScreen ? 0 : super._bottomBarHeight()),
      ],
    );
  }

  @override
  _needJumpTo(int pageIndex, bool animation) {
    if (animation) {
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.ease,
      );
    } else {
      _pageController.jumpToPage(pageIndex);
    }
    _preloadJump(widget.startIndex, init: false);
  }

  void _onGalleryPageChange(int to) {
    for (var i = to; i < to + 3 && i < _providers.length; i++) {
      final ip = _providers[i];
      precacheImage(ip, context);
    }
    super._onCurrentChange(to);
  }

  Widget _buildNextEpController() {
    if (super._fullscreenController()) {
      return Container();
    }
    if (_current < widget.chapter.pageUrl.length - 1) return Container();
    return Align(
      alignment: Alignment.bottomRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 4),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
            color: Color(0x88000000),
          ),
          child: GestureDetector(
            onTap: () {
              if (super._hasNextEp()) {
                super._onNextAction();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text(super._hasNextEp() ? '下一章' : '结束阅读',
                style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  _preloadJump(int index, {bool init = false}) {
    fn() {
      for (var i = index - 1; i < index + 3; i++) {
        if (i < 0 || i >= _providers.length) continue;
        final ip = _providers[i];
        precacheImage(ip, context);
      }
    }

    if (init) {
      WidgetsBinding.instance?.addPostFrameCallback((_) => fn());
    } else {
      fn();
    }
  }
}

class _ListViewReaderState extends _ComicReaderState
    with SingleTickerProviderStateMixin {
  final List<Size?> _trueSizes = [];
  final _transformationController = TransformationController();
  late TapDownDetails _doubleTapDetails;
  late final _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  @override
  void initState() {
    for (var e in widget.chapter.pageUrl) {
      _trueSizes.add(null);
    }
    super.initState();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void _needJumpTo(int index, bool animation) {}

  @override
  Widget _buildViewer() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: _buildList(),
    );
  }

  Widget _buildList() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // reload _images size
        List<Widget> images = [];
        for (var index = 0; index < widget.chapter.pageUrl.length; index++) {
          late Size renderSize;
          if (_trueSizes[index] != null) {
            if (currentReaderDirection == ReaderDirection.topToBottom) {
              renderSize = Size(
                constraints.maxWidth,
                constraints.maxWidth *
                    _trueSizes[index]!.height /
                    _trueSizes[index]!.width,
              );
            } else {
              var maxHeight = constraints.maxHeight -
                  super._appBarHeight() -
                  (widget.fullScreen
                      ? super._appBarHeight()
                      : super._bottomBarHeight());
              renderSize = Size(
                maxHeight *
                    _trueSizes[index]!.width /
                    _trueSizes[index]!.height,
                maxHeight,
              );
            }
          } else {
            if (currentReaderDirection == ReaderDirection.topToBottom) {
              renderSize = Size(constraints.maxWidth, constraints.maxWidth / 2);
            } else {
              // ReaderDirection.LEFT_TO_RIGHT
              // ReaderDirection.RIGHT_TO_LEFT
              renderSize =
                  Size(constraints.maxWidth / 2, constraints.maxHeight);
            }
          }
          var currentIndex = index;
          onTrueSize(Size size) {
            setState(() {
              _trueSizes[currentIndex] = size;
            });
          }

          images.add(
            LoadingCacheImage(
              url: widget.chapter.pageUrl[index],
              useful: 'comic_reader',
              extendsFieldIntFirst: widget.comic.id,
              extendsFieldIntSecond: widget.chapter.chapterId,
              extendsFieldIntThird: index,
              onTrueSize: onTrueSize,
              width: renderSize.width,
              height: renderSize.height,
            ),
          );
        }
        var list = ListView.builder(
          scrollDirection: currentReaderDirection == ReaderDirection.topToBottom
              ? Axis.vertical
              : Axis.horizontal,
          reverse: currentReaderDirection == ReaderDirection.rightToLeft,
          padding: EdgeInsets.only(
            // 不管全屏与否, 滚动方向如何, 顶部永远保持间距
            top: super._appBarHeight(),
            bottom: currentReaderDirection == ReaderDirection.topToBottom
                ? 130 // 纵向滚动 底部永远都是130的空白
                : ( // 横向滚动
                    widget.fullScreen
                        ? super._appBarHeight() // 全屏时底部和顶部到屏幕边框距离一样保持美观
                        : super._bottomBarHeight())
            // 非全屏时, 顶部去掉顶部BAR的高度, 底部去掉底部BAR的高度, 形成看似填充的效果
            ,
          ),
          itemCount: widget.chapter.pageUrl.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (widget.chapter.pageUrl.length == index) {
              return _buildNextEp();
            }
            return images[index];
          },
        );
        var viewer = InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1,
          maxScale: 2,
          child: list,
        );
        return GestureDetector(
          onDoubleTap: _handleDoubleTap,
          onDoubleTapDown: _handleDoubleTapDown,
          child: viewer,
        );
      },
    );
  }

  Widget _buildNextEp() {
    if (super._fullscreenController()) {
      return Container();
    }
    return Container(
      padding: const EdgeInsets.all(20),
      child: MaterialButton(
        onPressed: () {
          if (super._hasNextEp()) {
            super._onNextAction();
          } else {
            Navigator.of(context).pop();
          }
        },
        textColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.only(top: 40, bottom: 40),
          child: Text(super._hasNextEp() ? '下一章' : '结束阅读'),
        ),
      ),
    );
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_animationController.isAnimating) {
      return;
    }
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      var position = _doubleTapDetails.localPosition;
      var animation = Tween(begin: 0, end: 1.0).animate(_animationController);
      animation.addListener(() {
        _transformationController.value = Matrix4.identity()
          ..translate(
              -position.dx * animation.value, -position.dy * animation.value)
          ..scale(animation.value + 1.0);
      });
      _animationController.forward(from: 0);
    }
  }
}

class _TwoPageGalleryReaderState extends _ComicReaderState {
  late PageController _pageController;
  var _controllerTime = DateTime.now().millisecondsSinceEpoch + 400;
  late final List<Size?> _trueSizes = [];
  List<ImageProvider> ips = [];
  List<PhotoViewGalleryPageOptions> options = [];
  late PhotoViewGallery _view;

  @override
  void initState() {
    // 需要先初始化 super._startIndex 才能使用, 所以在上面
    for (var e in widget.chapter.pageUrl) {
      _trueSizes.add(null);
    }
    super.initState();
    _pageController = PageController(initialPage: widget.startIndex ~/ 2);
    for (var index = 0; index < widget.chapter.pageUrl.length; index++) {
      var item = widget.chapter.pageUrl[index];
      late ImageProvider ip;
      ip = ImageCacheProvider(
        url: widget.chapter.pageUrl[index],
        useful: 'comic_reader',
        extendsFieldIntFirst: widget.comic.id,
        extendsFieldIntSecond: widget.chapter.chapterId,
        extendsFieldIntThird: index,
      );
      ips.add(ip);
    }
    for (var index = 0; index < ips.length; index += 2) {
      // 两页
      late ImageProvider leftIp = ips[index];
      late ImageProvider rightIp = ips[index + 1];
      if (index + 1 < ips.length) {
        leftIp = ips[index];
        rightIp = ips[index + 1];
      } else {
        leftIp = ips[index];
        // ImageProvider by color black
        rightIp = const AssetImage('lib/assets/0.png');
      }
      if (currentTwoPageDirection == TwoPageDirection.rightToLeft) {
        final temp = leftIp;
        leftIp = rightIp;
        rightIp = temp;
      }
      options.add(
        PhotoViewGalleryPageOptions.customChild(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Image(
                        image: leftIp,
                        fit: BoxFit.contain,
                        // loadingBuilder: (context, child, event) => buildLoading(constraints.maxWidth, constraints.maxHeight),
                        errorBuilder: (b, e, s) {
                          print("$e,$s");
                          return buildError(
                            constraints.maxWidth / 2,
                            constraints.maxHeight / 2,
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Image(
                        image: rightIp,
                        fit: BoxFit.contain,
                        // loadingBuilder: (context, child, event) => buildLoading(constraints.maxWidth, constraints.maxHeight),
                        errorBuilder: (b, e, s) {
                          print("$e,$s");
                          return buildError(
                            constraints.maxWidth / 2,
                            constraints.maxHeight / 2,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }
    _view = PhotoViewGallery(
      pageController: _pageController,
      pageOptions: options,
      scrollDirection: widget.readerDirection == ReaderDirection.topToBottom
          ? Axis.vertical
          : Axis.horizontal,
      reverse: widget.readerDirection == ReaderDirection.rightToLeft,
      onPageChanged: _onGalleryPageChange,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
    );
    _preloadJump(widget.startIndex, init: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void _needJumpTo(int index, bool animation) {
    if (noAnimation() || animation == false) {
      _pageController.jumpToPage(
        index ~/ 2,
      );
    } else {
      _pageController.animateToPage(
        index ~/ 2,
        duration: const Duration(milliseconds: 400),
        curve: Curves.ease,
      );
    }
    _preloadJump(index);
  }

  _preloadJump(int index, {bool init = false}) {
    fn() {
      for (var i = index - 2; i < index + 5; i++) {
        if (i < 0 || i >= ips.length) continue;
        final ip = ips[i];
        precacheImage(ip, context);
      }
    }

    if (init) {
      WidgetsBinding.instance?.addPostFrameCallback((_) => fn());
    } else {
      fn();
    }
  }

  @override
  Widget _buildViewer() {
    return Stack(
      children: [
        GestureDetector(
          child: _view,
        ),
        _buildNextEpController(),
      ],
    );
  }

  void _onGalleryPageChange(int to) {
    var toIndex = to * 2;
    // 提前加载
    for (var i = toIndex + 2; i < toIndex + 5 && i < ips.length; i++) {
      final ip = ips[i];
      precacheImage(ip, context);
    }
    // 包含一个下一章, 假设5张图片 0,1,2,3,4 length=5, 下一章=5
    if (to >= 0 && to < widget.chapter.pageUrl.length) {
      super._onCurrentChange(toIndex);
    }
  }

  Widget _buildNextEpController() {
    if (super._fullscreenController() ||
        _current < widget.chapter.pageUrl.length - 2) return Container();
    return Align(
      alignment: Alignment.bottomRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 4),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
            color: Color(0x88000000),
          ),
          child: GestureDetector(
            onTap: () {
              if (_hasNextEp()) {
                _onNextAction();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text(
              _hasNextEp() ? '下一章' : '结束阅读',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
