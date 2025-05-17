import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:daisy/configs/novel_background_color.dart';
import 'package:daisy/configs/novel_margins.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:daisy/screens/components/content_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../configs/novel_font_color.dart';
import '../configs/novel_font_size.dart';
import '../configs/novel_line_height.dart';
import '../configs/novel_paragraph_spacing.dart';
import '../src/rust/anime_home/proto.dart';
import 'components/content_loading.dart';
import 'components/novel_fan_component.dart';

class NovelNewReaderScreen extends StatefulWidget {
  final NovelDetail novel;
  final List<NovelVolume> volumes;
  final int initChapterId;

  const NovelNewReaderScreen({
    required this.novel,
    required this.volumes,
    required this.initChapterId,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _NovelNewReaderScreenState();
}

enum LoadingState {
  loading,
  success,
  fail,
}

class _NovelNewReaderScreenState extends State<NovelNewReaderScreen> {
  final Map<int, String> _chapterTexts = {};
  final Map<int, List<PageEntry>> _chapterTextsPages = {};
  final Map<int, LoadingState> _chapterLoadingState = {};

  late int _currentChapterId;
  NovelChapter? _nc;
  NovelChapter? _pc;

  int _fIndex = 0;

  List<PageEntry> _reRenderTextIn(String fullBookText) {
    fullBookText = fullBookText.replaceAll("<br />\n", "\n");
    fullBookText = fullBookText.replaceAll("<br />\n", "\n");
    fullBookText = fullBookText.replaceAll("<br />", "\n");
    fullBookText = fullBookText.replaceAll("<br/>", "\n");
    fullBookText = fullBookText.replaceAll("&nbsp;", " ");
    fullBookText = fullBookText.replaceAll("&amp;", "&");
    fullBookText = fullBookText.replaceAll("&hellip;", "…");
    fullBookText = fullBookText.replaceAll("&bull;", "·");
    fullBookText = fullBookText.replaceAll("&lt;", "<");
    fullBookText = fullBookText.replaceAll("&gt;", ">");
    fullBookText = fullBookText.replaceAll("&quot;", "\"");
    fullBookText = fullBookText.replaceAll("&copy;", "©");
    fullBookText = fullBookText.replaceAll("&reg;", "®");
    fullBookText = fullBookText.replaceAll("&times;", "×");
    fullBookText = fullBookText.replaceAll("&pide;", "÷");
    fullBookText = fullBookText.replaceAll("&emsp;", " ");
    fullBookText = fullBookText.replaceAll("&ensp;", " ");
    fullBookText = fullBookText.replaceAll("&ldquo;", "“");
    fullBookText = fullBookText.replaceAll("&rdquo;", "”");
    fullBookText = fullBookText.replaceAll("&mdash;", "—");
    fullBookText = fullBookText.replaceAll("&middot;", "·");
    fullBookText = fullBookText.replaceAll("&lsquo;", "‘");
    fullBookText = fullBookText.replaceAll("&rsquo;", "’");

    fullBookText = fullBookText.trim();
    final mq = MediaQuery.of(context);
    final width = mq.size.width - novelLeftMargin - novelRightMargin;
    final height = mq.size.height - novelTopMargin - novelBottomMargin - 14 * novelFontSize * novelLineHeight;

    // 恢复图片分割逻辑
    List<PageEntry> preEntries = [];
    final RegExp imgTagReg = RegExp('<img[^>]+/?>');
    Iterable<RegExpMatch> matches = imgTagReg.allMatches(fullBookText);
    int position = 0;
    for (var match in matches) {
      final imgTag = match.group(0)!;
      if (match.start > position) {
        final text = fullBookText.substring(position, match.start).trim();
        if (text.isNotEmpty) {
          preEntries.add(PageEntry(text, ""));
        }
      }
      position = match.end;
      final imgSrcMatch = RegExp('src="([^"]+)"').firstMatch(imgTag);
      if (imgSrcMatch == null) {
        continue;
      }
      preEntries.add(PageEntry("", imgSrcMatch.group(1)!));
    }
    if (position < fullBookText.length) {
      final text = fullBookText.substring(position).trim();
      if (text.isNotEmpty) {
        preEntries.add(PageEntry(text, ""));
      }
    }

    List<PageEntry> resultPages = [];
    final paragraphSpacing = 14 * novelFontSize * novelParagraphSpacing;
    var currentPageText = "";
    var currentPageHeight = 0.0;

    for (var entry in preEntries) {
      if (entry.img.isNotEmpty) {
        // 图片单独成页，确保当前页为空
        if (currentPageText.isNotEmpty) {
          resultPages.add(PageEntry(currentPageText, ""));
          currentPageText = "";
          currentPageHeight = 0;
        }
        resultPages.add(PageEntry("", entry.img));
        continue;
      }

      if (entry.text.isEmpty) continue;

      final paragraphs = entry.text.split("\n\n");

      for (var i = 0; i < paragraphs.length; i++) {
        var paragraph = paragraphs[i].trim();
        if (paragraph.isEmpty) continue;

        // 计算当前段落的总高度
        final paragraphSpan = TextSpan(
          text: paragraph,
          style: TextStyle(
            fontSize: 14 * novelFontSize,
            height: novelLineHeight,
          ),
        );
        final paragraphPainter = TextPainter(
          text: paragraphSpan,
          textDirection: TextDirection.ltr,
          maxLines: null,
          strutStyle: StrutStyle(
            fontSize: 14 * novelFontSize,
            height: novelLineHeight,
            forceStrutHeight: true,
          ),
        );
        paragraphPainter.layout(maxWidth: width);
        final paragraphHeight = paragraphPainter.height;

        // 如果当前段落加上段落间距会超出页面高度，且当前页已有内容，则先保存当前页
        if (currentPageHeight + paragraphHeight + (i < paragraphs.length - 1 ? paragraphSpacing : 0) > height) {
          if (currentPageText.isNotEmpty) {
            resultPages.add(PageEntry(currentPageText, ""));
            currentPageText = "";
            currentPageHeight = 0;
          }
        }

        // 处理段落内容
        if (paragraphHeight > height) {
          // 如果段落高度超过页面高度，需要分割
          var remainingText = paragraph;
          while (remainingText.isNotEmpty) {
            final testSpan = TextSpan(
              text: remainingText,
              style: TextStyle(
                fontSize: 14 * novelFontSize,
                height: novelLineHeight,
              ),
            );
            final testPainter = TextPainter(
              text: testSpan,
              textDirection: TextDirection.ltr,
              maxLines: null,
              strutStyle: StrutStyle(
                fontSize: 14 * novelFontSize,
                height: novelLineHeight,
                forceStrutHeight: true,
              ),
            );
            testPainter.layout(maxWidth: width);

            // 使用 getPositionForOffset 找到合适的分割点
            final maxHeight = height - currentPageHeight;
            if (maxHeight <= 0) {
              // 如果当前页已满，保存并开始新页
              if (currentPageText.isNotEmpty) {
                resultPages.add(PageEntry(currentPageText, ""));
                currentPageText = "";
                currentPageHeight = 0;
              }
              continue;
            }

            final offset = testPainter.getPositionForOffset(Offset(width, maxHeight));
            final splitIndex = offset.offset;

            if (splitIndex <= 0) {
              // 如果无法分割，保存当前页并开始新页
              if (currentPageText.isNotEmpty) {
                resultPages.add(PageEntry(currentPageText, ""));
                currentPageText = "";
                currentPageHeight = 0;
              }
              // 强制分割一个字符
              if (remainingText.isNotEmpty) {
                resultPages.add(PageEntry(remainingText.substring(0, 1), ""));
                remainingText = remainingText.substring(1);
              }
              continue;
            }

            final splitText = remainingText.substring(0, splitIndex).trim();
            if (splitText.isEmpty) {
              // 如果分割后是空文本，保存当前页并继续
              if (currentPageText.isNotEmpty) {
                resultPages.add(PageEntry(currentPageText, ""));
                currentPageText = "";
                currentPageHeight = 0;
              }
              remainingText = remainingText.substring(splitIndex).trim();
              continue;
            }

            if (currentPageText.isEmpty) {
              currentPageText = splitText;
              currentPageHeight = testPainter.height;
            } else {
              resultPages.add(PageEntry(currentPageText, ""));
              currentPageText = splitText;
              currentPageHeight = testPainter.height;
            }
            remainingText = remainingText.substring(splitIndex).trim();
          }
        } else {
          // 如果段落高度在页面范围内，直接添加
          if (currentPageHeight + paragraphHeight > height) {
            if (currentPageText.isNotEmpty) {
              resultPages.add(PageEntry(currentPageText, ""));
              currentPageText = paragraph;
              currentPageHeight = paragraphHeight;
            } else {
              // 如果当前页为空但段落仍然放不下，强制分割
              resultPages.add(PageEntry(paragraph, ""));
            }
          } else {
            if (currentPageText.isNotEmpty) {
              currentPageText += "\n\n";
            }
            currentPageText += paragraph;
            currentPageHeight += paragraphHeight;
          }
        }

        // 添加段落间距（如果不是最后一个段落）
        if (i < paragraphs.length - 1) {
          if (currentPageHeight + paragraphSpacing > height) {
            if (currentPageText.isNotEmpty) {
              resultPages.add(PageEntry(currentPageText, ""));
              currentPageText = "";
              currentPageHeight = 0;
            }
          } else {
            currentPageHeight += paragraphSpacing;
          }
        }
      }

      // 保存最后一页
      if (currentPageText.isNotEmpty) {
        resultPages.add(PageEntry(currentPageText, ""));
      }
    }

    // 过滤掉空页面
    resultPages = resultPages.where((page) => page.text.isNotEmpty || page.img.isNotEmpty).toList();

    if (resultPages.isEmpty) {
      resultPages.add(PageEntry("", ""));
    }
    return resultPages;
  }

  // 注意:
  // 最优解: 缩放完还保持第一个字不变
  resetFont() {
    _chapterTexts.forEach((key, value) {
      _chapterTextsPages[key] = _reRenderTextIn(value);
    });
    if (_fIndex >= _chapterTextsPages[_currentChapterId]!.length) {
      _fIndex = _chapterTextsPages[_currentChapterId]!.length - 1;
    }
    ///////////////////////////////////////////////////
    // todo
    // if (_chapterLoadingState[_currentChapterId] == LoadingState.success) {
    //   int z = 0;
    //   for (var i = 0; i < _fIndex; i++) {
    //     z += _chapterTextsPages[_currentChapterId]![i].length;
    //   }
    //   _chapterTextsPages[_currentChapterId] =
    //       _reRenderTextIn(_chapterTexts[_currentChapterId]!);
    //   _fIndex = 0;
    //   var y = 0;
    //   for (var i = 0; i < _chapterTextsPages.length; i++) {
    //     if (y >= z) {
    //       _fIndex = i;
    //       break;
    //     }
    //     y += _chapterTextsPages[_currentChapterId]![i].length;
    //   }
    // }
    // _chapterTexts.forEach((key, value) {
    //   if (key != _currentChapterId) {
    //     _chapterTextsPages[key] = _reRenderTextIn(value);
    //   }
    // });
  }

  Future _loadChapter(int chapterId) async {
    if (_chapterLoadingState[chapterId] != null &&
        _chapterLoadingState[chapterId] != LoadingState.fail) {
      setState(() {});
      return;
    }
    _chapterLoadingState[chapterId] = LoadingState.loading;
    setState(() {});
    NovelVolume? volume;
    NovelChapter? chapter;
    VF:
    for (var v in widget.volumes) {
      for (var c in v.chapters) {
        if (c.chapterId == chapterId) {
          chapter = c;
          volume = v;
          break VF;
        }
      }
    }
    try {
      _chapterTexts[chapterId] = await native.novelContent(
        volumeId: volume!.id,
        chapterId: chapter!.chapterId,
      );
      _chapterTextsPages[chapterId] =
          _reRenderTextIn(_chapterTexts[chapterId]!);
      _chapterLoadingState[chapterId] = LoadingState.success;
    } catch (e) {
      _chapterLoadingState[chapterId] = LoadingState.fail;
    } finally {
      setState(() {});
    }
  }

  // 记录看到哪里
  void saveRecord() {
    NovelVolume? volume;
    NovelChapter? chapter;
    VF:
    for (var v in widget.volumes) {
      for (var c in v.chapters) {
        if (c.chapterId == _currentChapterId) {
          chapter = c;
          volume = v;
          break VF;
        }
      }
    }
    volume = volume!;
    chapter = chapter!;
    native.novelViewPage(
      novelId: widget.novel.id,
      volumeId: volume.id,
      volumeTitle: volume.title,
      volumeOrder: volume.rank,
      chapterId: chapter.chapterId,
      chapterTitle: chapter.chapterName,
      chapterOrder: chapter.chapterOrder,
      progress: 0,
    );
  }

  void _init() async {
    await _loadChapter(_currentChapterId);
  }

  @override
  void initState() {
    _currentChapterId = widget.initChapterId;
    _nc = _nextChapter();
    _pc = _previousChapter();
    saveRecord();
    _init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    late NovelChapter chapter;
    for (var v in widget.volumes) {
      for (var c in v.chapters) {
        if (c.chapterId == _currentChapterId) {
          chapter = c;
        }
      }
    }
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
                  child: move(), //_buildHtmlViewer(text),
                ),
              ),
              ..._fullScreen
                  ? []
                  : [
                      Column(
                        children: [
                          AppBar(
                            backgroundColor: Colors.black.withOpacity(.5),
                            title: Text(chapter.chapterName),
                            elevation: 0,
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

  Future _onChooseEp() async {
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xAA000000),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * (.45),
          child: _EpChooser(
            widget.novel,
            widget.volumes,
            _currentChapterId,
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
                      resetFont();
                      setState(() => {});
                    },
                  ),
                  _bottomIcon(
                    icon: Icons.format_line_spacing_sharp,
                    title: novelLineHeight.toString(),
                    onPressed: () async {
                      await modifyNovelLineHeight(context);
                      resetFont();
                      setState(() => {});
                    },
                  ),
                  _bottomIcon(
                    icon: Icons.format_line_spacing,
                    title: novelParagraphSpacing.toString(),
                    onPressed: () async {
                      await modifyNovelParagraphSpacing(context);
                      resetFont();
                      setState(() => {});
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  _bottomIcon(
                    icon: Icons.fullscreen_exit_outlined,
                    title: "边距",
                    onPressed: () async {
                      await novelMarginsSettingsPop(context);
                      resetFont();
                      setState(() => {});
                    },
                  ),
                ],
              ),
              Row(
                children: [
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
      builder: (BuildContext context) => NovelNewReaderScreen(
        novel: n,
        volumes: widget.volumes,
        initChapterId: c.chapterId,
      ),
    ));
  }

  final _nfController = NovelFanComponentController();

  Widget move() {
    return NovelFanComponent(
      controller: _nfController,
      previous: _movePrevious(),
      current: _moveCurrent(),
      next: _moveNext(),
      onNextSetState: _moveOnNextSetState,
      onPreviousSetState: _moveOnPreviousSetState,
    );
  }

  void _moveOnPreviousSetState() {
    if (_fIndex > 0) {
      _fIndex--;
      if (_fIndex == 0) {
        if (_pc != null) {
          // 如果为0预先加载上一章
          _loadChapter(_pc!.chapterId);
        }
      }
    } else if (_pc != null) {
      if (_chapterLoadingState[_pc!.chapterId] == LoadingState.success) {
        //  如果上一章加载好了跳到最后一页
        _currentChapterId = _pc!.chapterId;
        _nc = _nextChapter();
        _pc = _previousChapter();
        _fIndex = _chapterTextsPages[_currentChapterId]!.length - 1;
        saveRecord();
      } else {
        // todo 加载完成后跳到最后一页, 似乎不是很好实现
        _currentChapterId = _pc!.chapterId;
        _nc = _nextChapter();
        _pc = _previousChapter();
        _fIndex = 0;
        saveRecord();
        // note 如果只有一页 或者是第一页往前翻 可能不加载前后页 这里进行补偿
        if (_chapterLoadingState[_currentChapterId] == null) {
          _loadChapter(_currentChapterId);
        }
      }
    }
    setState(() {});
  }

  void _moveOnNextSetState() {
    if (_fIndex < _chapterTextsPages[_currentChapterId]!.length - 1) {
      _fIndex++;
      // 预先加载下一章内容
      if (_fIndex == _chapterTextsPages[_currentChapterId]!.length - 1) {
        if (_nc != null) {
          // note: 状态判断在_loadChapter里
          _loadChapter(_nc!.chapterId);
        }
      }
    } else if (_nc != null) {
      // note 跳到下一章第一页
      _currentChapterId = _nc!.chapterId;
      _nc = _nextChapter();
      _pc = _previousChapter();
      _fIndex = 0;
      saveRecord();
      // note 如果只有一页 或者是第一页往前翻 可能不加载前后页 这里进行补偿
      if (_chapterLoadingState[_currentChapterId] == null) {
        _loadChapter(_currentChapterId);
      }
    }
    setState(() {});
  }

  Widget? _movePrevious() {
    // 没有加载成功不能前后章移动
    if (_chapterLoadingState[_currentChapterId] != LoadingState.success) {
      return null;
    }
    //
    if (_fIndex != 0) {
      return page(
        _chapterTextsPages[_currentChapterId]![_fIndex - 1],
      );
    }
    if (_pc == null) {
      return null;
    }
    // 上一章最后一页
    if (_chapterLoadingState[_pc!.chapterId] == LoadingState.success) {
      //  如果上一章加载好了跳到最后一页
      return page(_chapterTextsPages[_pc!.chapterId]![
          _chapterTextsPages[_pc!.chapterId]!.length - 1]);
    } else {
      // todo 失败没有特别显示
      return const ContentLoading();
    }
  }

  Widget _moveCurrent() {
    if (_chapterLoadingState[_currentChapterId] == LoadingState.fail) {
      // todo 更明确错误信息(用map预先保存)
      return ContentError(error: "e", stackTrace: null, onRefresh: () async {});
    }
    if (_chapterLoadingState[_currentChapterId] == LoadingState.loading) {
      return const ContentLoading();
    }
    if (_chapterLoadingState[_currentChapterId] == LoadingState.success) {
      return page(
        _chapterTextsPages[_currentChapterId]![_fIndex],
      );
    }
    // null
    return Container();
  }

  Widget? _moveNext() {
    // 没有加载成功不能前后章移动
    if (_chapterLoadingState[_currentChapterId] != LoadingState.success) {
      return null;
    }
    if (_nc == null) {
      return null;
    }
    if (_fIndex >= _chapterTextsPages[_currentChapterId]!.length - 1) {
      if (_chapterLoadingState[_nc!.chapterId] == LoadingState.success) {
        //  如果下一章加载好了显示第一页
        return page(_chapterTextsPages[_nc!.chapterId]![0]);
      } else {
        // todo 失败没有特别显示
        return const ContentLoading();
      }
    }
    return page(
      _chapterTextsPages[_currentChapterId]![_fIndex + 1],
    );
  }

  Widget page(PageEntry pageEntry) {
    late Widget child;
    if (pageEntry.text.isNotEmpty) {
      // Split text into paragraphs and add spacing between them
      final paragraphs = pageEntry.text.split('\n\n');
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paragraphs.map((paragraph) {
          return Padding(
            padding: EdgeInsets.only(bottom: 14 * novelFontSize * novelParagraphSpacing),
            child: Text(
              paragraph,
              style: TextStyle(
                fontSize: 14 * novelFontSize,
                height: novelLineHeight,
                color: getNovelFontColor(context),
              ),
              strutStyle: StrutStyle(
                fontSize: 14 * novelFontSize,
                height: novelLineHeight,
                forceStrutHeight: true,
              ),
            ),
          );
        }).toList(),
      );
    } else if (pageEntry.img.isNotEmpty) {
      // todo cache
      child = Image.network(
        pageEntry.img,
        fit: BoxFit.fitWidth,
      );
    } else {
      child = Container();
    }
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: getNovelBackgroundColor(context),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              offset: Offset(0.0, 15.0), //阴影xy轴偏移量
              blurRadius: 15.0, //阴影模糊程度
              spreadRadius: 1.0 //阴影扩散程度
              ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: novelTopMargin,
          bottom: novelBottomMargin,
          left: novelLeftMargin,
          right: novelRightMargin,
        ),
        child: child,
      ),
    );
  }

  NovelChapter? _nextChapter() {
    bool flag = false;
    for (var v in widget.volumes) {
      for (var c in v.chapters) {
        if (flag) {
          return c;
        }
        if (c.chapterId == _currentChapterId) {
          flag = true;
        }
      }
    }
    return null;
  }

  _previousChapter() {
    bool flag = false;
    for (var v in widget.volumes.reversed) {
      for (var c in v.chapters.reversed) {
        if (flag) {
          return c;
        }
        if (c.chapterId == _currentChapterId) {
          flag = true;
        }
      }
    }
    return null;
  }
}

class _EpChooser extends StatefulWidget {
  final NovelDetail novel;
  final List<NovelVolume> volumes;
  final int chapterId;
  final FutureOr Function(NovelDetail, NovelVolume, NovelChapter) onChangeEp;

  const _EpChooser(
    this.novel,
    this.volumes,
    this.chapterId,
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
        if (widget.chapterId == ci.chapterId) {
          position = widgets.length > 2 ? widgets.length - 2 : 0;
        }
        widgets.add(Container(
          margin: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
          decoration: BoxDecoration(
            color: widget.chapterId == ci.chapterId
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
    // todo 对上一章进行提前加载
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

class PageEntry {
  final String text;
  final String img;

  PageEntry(this.text, this.img);
}
