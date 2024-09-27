import 'dart:async';
import 'dart:io';

import 'package:daisy/configs/novel_background_color.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:daisy/screens/components/content_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../configs/novel_font_color.dart';
import '../configs/novel_font_size.dart';
import '../src/rust/anime_home/proto.dart';
import 'components/content_loading.dart';

class NovelHtmlReaderScreen extends StatefulWidget {
  final NovelDetail novel;
  final NovelVolume volume;
  final NovelChapter chapter;
  final List<NovelVolume> volumes;

  const NovelHtmlReaderScreen({
    required this.novel,
    required this.volume,
    required this.chapter,
    required this.volumes,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _NovelHtmlReaderScreenState();
}

class _NovelHtmlReaderScreenState extends State<NovelHtmlReaderScreen> {
  late Future<String> _contentFuture;

  @override
  void initState() {
    native.novelViewPage(
      novelId: widget.novel.id,
      volumeId: widget.volume.id,
      volumeTitle: widget.volume.title,
      volumeOrder: widget.volume.rank,
      chapterId: widget.chapter.chapterId,
      chapterTitle: widget.chapter.chapterName,
      chapterOrder: widget.chapter.chapterOrder,
      progress: 0,
    );
    _contentFuture = native.novelContent(
      volumeId: widget.volume.id,
      chapterId: widget.chapter.chapterId,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _contentFuture,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.chapter.chapterName),
            ),
            body: ContentError(
              error: snapshot.error,
              stackTrace: snapshot.stackTrace,
              onRefresh: () async {
                setState(() {
                  _contentFuture = native.novelContent(
                    volumeId: widget.volume.id,
                    chapterId: widget.chapter.chapterId,
                  );
                });
              },
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.chapter.chapterName),
            ),
            body: const ContentLoading(),
          );
        }

        return _buildReader(snapshot.requireData);
      },
    );
  }

  bool _inFullScreen = false;

  bool get _fullScreen => _inFullScreen;

  set _fullScreen(bool val) {
    _inFullScreen = val;
    if (Platform.isIOS || Platform.isAndroid) {
      if (val) {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [],
        );
      } else {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      }
    }
  }

  Widget _buildReader(String text) {
    return Scaffold(
      body: StatefulBuilder(
        builder: (
            BuildContext context,
            void Function(void Function()) setState,
            ) {
          return Stack(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _fullScreen = !_fullScreen;
                  });
                },
                child: Container(
                  color: getNovelBackgroundColor(context),
                  child: ListView(
                    padding: EdgeInsets.only(
                      left: 10,
                      right: 10,
                      top: 15 + (Scaffold.of(context).appBarMaxHeight ?? 0),
                      bottom: 15 + (Scaffold.of(context).appBarMaxHeight ?? 0),
                    ),
                    children: [
                      Html(
                        data: text,
                        style: {
                          "body": Style(
                            fontSize: FontSize(novelFontSize),
                            color: getNovelFontColor(context),
                          ),
                        },
                      ),
                    ],
                  ),
                ),
              ),
              ..._fullScreen
                  ? []
                  : [
                Column(
                  children: [
                    AppBar(
                      backgroundColor: Colors.black.withOpacity(.5),
                      title: Text(widget.chapter.chapterName),
                      actions: [
                        IconButton(
                          onPressed: _onChooseEp,
                          icon: const Icon(Icons.menu_open),
                        ),
                        IconButton(
                          onPressed: _bottomMenu,
                          icon: const Icon(Icons.more_horiz),
                        )
                      ],
                    ),
                    Expanded(child: Container()),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future _onChooseEp() async {
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xAA000000),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * (.45),
          child: _EpChooser(
            widget.novel,
            widget.volume,
            widget.chapter,
            widget.volumes,
            onChangeEp,
          ),
        );
      },
    );
  }

  void _bottomMenu() async {
    await showMaterialModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xAA000000),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * (.45),
          child: ListView(
            children: [
              Row(
                children: [
                  _bottomIcon(
                    icon: Icons.text_fields,
                    title: novelFontSize.toString(),
                    onPressed: () async {
                      await modifyNovelFontSize(context);
                      setState(() => {});
                    },
                  ),
                  _bottomIcon(
                    icon: Icons.format_color_text,
                    title: "颜色",
                    onPressed: () async {
                      await modifyNovelFontColor(context);
                      setState(() => {});
                    },
                  ),
                  _bottomIcon(
                    icon: Icons.format_shapes,
                    title: "颜色",
                    onPressed: () async {
                      await modifyNovelBackgroundColor(context);
                      setState(() => {});
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

  Future onChangeEp(NovelDetail n, NovelVolume v, NovelChapter c) async {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (BuildContext context) => NovelHtmlReaderScreen(
        novel: n,
        volume: v,
        chapter: c,
        volumes: widget.volumes,
      ),
    ));
  }
}

class _EpChooser extends StatefulWidget {
  final NovelDetail novel;
  final NovelVolume volume;
  final NovelChapter chapter;
  final List<NovelVolume> volumes;
  final FutureOr Function(NovelDetail, NovelVolume, NovelChapter) onChangeEp;

  const _EpChooser(
      this.novel,
      this.volume,
      this.chapter,
      this.volumes,
      this.onChangeEp,
      );

  @override
  State<StatefulWidget> createState() => _EpChooserState();
}

class _EpChooserState extends State<_EpChooser> {
  int position = 0;
  List<Widget> widgets = [];

  @override
  void initState() {
    for (var c in widget.volumes) {
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
      final cd = [...c.chapters];
      cd.sort((o1, o2) => o1.chapterOrder - o2.chapterOrder);
      for (var ci in c.chapters) {
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
              widget.onChangeEp(widget.novel, c, ci);
            },
            textColor: Colors.white,
            child: Text(ci.chapterName),
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
