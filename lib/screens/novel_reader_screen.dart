import 'dart:convert';
import 'dart:io';

import 'package:daisy/configs/novel_background_color.dart';
import 'package:daisy/ffi.dart';
import 'package:daisy/screens/components/connect_loading.dart';
import 'package:daisy/screens/components/content_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../configs/novel_font_color.dart';
import '../configs/novel_font_size.dart';

class NovelReaderScreen extends StatefulWidget {
  final NovelDetail novel;
  final NovelVolume volume;
  final NovelChapter chapter;

  const NovelReaderScreen({
    required this.novel,
    required this.volume,
    required this.chapter,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NovelReaderScreenState();
}

class _NovelReaderScreenState extends State<NovelReaderScreen> {
  late Future<String> _contentFuture;

  @override
  void initState() {
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
                            fontSize: FontSize.em(novelFontSize),
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
}
