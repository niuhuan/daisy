import 'package:daisy/commons.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';

import '../src/rust/anime_home/proto.dart';

class ComicCreateDownloadScreen extends StatefulWidget {
  final ComicDetail comic;

  const ComicCreateDownloadScreen({super.key, required this.comic});

  @override
  State<StatefulWidget> createState() => _ComicCreateDownloadScreenState();
}

class _ComicCreateDownloadScreenState extends State<ComicCreateDownloadScreen> {
  final List<int> _selected = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("下载 - ${widget.comic.title}"),
        actions: [
          downloadIcon(),
        ],
      ),
      body: ListView(
        children: [
          ..._buildChapters(widget.comic),
        ],
      ),
    );
  }

  List<Widget> _buildChapters(ComicDetail comic) {
    return comic.chapters
        .map((chapter) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(
                    top: 15,
                    bottom: 5,
                    left: 10,
                    right: 10,
                  ),
                  child: SelectableText(chapter.title),
                ),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: 10,
                    runSpacing: 5,
                    children: [
                      ...chapter.data.map(
                        (e) => Container(
                          margin: const EdgeInsets.all(3),
                          child: MaterialButton(
                            onPressed: () {
                              if (_selected.contains(e.chapterId)) {
                                _selected.remove(e.chapterId);
                              } else {
                                _selected.add(e.chapterId);
                              }
                              setState(() {});
                            },
                            color: _selected.contains(e.chapterId)
                                ? Colors.blueGrey
                                : Colors.white,
                            child: Text(
                              e.chapterTitle,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ))
        .toList();
  }

  Widget downloadIcon() {
    return IconButton(
      onPressed: () {
        if (_selected.isEmpty) {
          defaultToast(context, "请选择章节");
          return;
        }
        List<ComicChapter> list = [];
        for (var element in widget.comic.chapters) {
          ComicChapter chapter = ComicChapter(title: element.title, data: []);
          for (var value in element.data) {
            if (_selected.contains(value.chapterId)) {
              chapter.data.add(value);
            }
          }
          if (chapter.data.isNotEmpty) {
            list.add(chapter);
          }
        }
        var request = ComicDetail(
          id: widget.comic.id,
          title: widget.comic.title,
          direction: widget.comic.direction,
          isLong: widget.comic.isLong,
          isAnimeHome: widget.comic.isAnimeHome,
          cover: widget.comic.cover,
          description: widget.comic.description,
          lastUpdateTime: widget.comic.lastUpdateTime,
          lastUpdateChapterName: widget.comic.lastUpdateChapterName,
          copyright: widget.comic.copyright,
          firstLetter: widget.comic.firstLetter,
          comicPy: widget.comic.comicPy,
          hidden: widget.comic.hidden,
          hotNum: widget.comic.hotNum,
          hitNum: widget.comic.hitNum,
          uid: widget.comic.uid,
          isLock: widget.comic.isLock,
          lastUpdateChapterId: widget.comic.lastUpdateChapterId,
          types: widget.comic.types,
          status: widget.comic.status,
          authors: widget.comic.authors,
          subscribeNum: widget.comic.subscribeNum,
          chapters: list,
          isNeedLogin: widget.comic.isNeedLogin,
          isHideChapter: widget.comic.isHideChapter,
        );
        download(request);
      },
      icon: const Icon(Icons.check),
    );
  }

  void download(ComicDetail request) async {
    try {
      await native.createDownload(buff: request);
      defaultToast(context, "success");
      Navigator.pop(context);
    } catch (e, s) {
      print("$e\n$s");
      defaultToast(context, "失败 : $e");
    }
  }
}
