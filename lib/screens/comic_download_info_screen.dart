import 'dart:convert';

import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';
import '../commons.dart';
import '../src/rust/anime_home/proto.dart';
import '../src/rust/api/bridge.dart';
import 'comic_detail_screen.dart';
import 'comic_reader_screen.dart';

class ComicDownloadInfoScreen extends StatefulWidget {
  final DownloadComic comic;

  const ComicDownloadInfoScreen({super.key, required this.comic});

  @override
  State<StatefulWidget> createState() => _ComicDownloadInfoScreen();
}

class _ComicDownloadInfoScreen extends State<ComicDownloadInfoScreen>
    with RouteAware {
  late Future<ComicViewLog?> _viewLog;
  late Future<List<ComicChapter>> _f;

  void _loadViewLog() {
    _viewLog = native.viewLogByComicId(comicId: widget.comic.id);
  }

  @override
  void initState() {
    _f = native.downloadComicChaptersByComicId(id: widget.comic.id);
    _loadViewLog();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    setState(() {
      _loadViewLog();
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _f,
      builder:
          (BuildContext context, AsyncSnapshot<List<ComicChapter>> snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("完了, 芭比Q了"),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Text("加载中"),
          );
        }
        return _buildBody(context, snapshot.requireData);
      },
    );
  }

  Widget _buildBody(BuildContext context, List<ComicChapter> chapters) {
    final mockDetail = ComicDetail(
      id: widget.comic.id,
      title: widget.comic.title,
      direction: widget.comic.direction,
      isLong: widget.comic.isLong,
      isAnimeHome: widget.comic.isAnimeHome,
      cover: widget.comic.cover,
      description: widget.comic.description,
      lastUpdateTime: 0,
      lastUpdateChapterName: "",
      copyright: widget.comic.copyright,
      firstLetter: widget.comic.firstLetter,
      comicPy: widget.comic.comicPy,
      hidden: 0,
      hotNum: 0,
      hitNum: 0,
      uid: 0,
      isLock: 0,
      lastUpdateChapterId: 0,
      types: List.of(jsonDecode(widget.comic.types))
          .cast<Map>()
          .map((e) => Item(id: e["id"], title: e["title"]))
          .toList(),
      status: List.of(jsonDecode(widget.comic.status))
          .cast<Map>()
          .map((e) => Item(id: e["id"], title: e["title"]))
          .toList(),
      authors: List.of(jsonDecode(widget.comic.authors))
          .cast<Map>()
          .map((e) => Item(id: e["id"], title: e["title"]))
          .toList(),
      subscribeNum: 0,
      chapters: chapters,
      isNeedLogin: 0,
      isHideChapter: 0,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.comic.title),
      ),
      body: ListView(
        children: [
          Container(height: 3),
          ComicCard(comic: mockDetail),
          Container(height: 20),
          _buildContinueButton(mockDetail, chapters),
          ..._buildChapters(chapters),
        ],
      ),
    );
  }

  Widget _buildContinueButton(
      ComicDetail mockDetail, List<ComicChapter> chapters) {
    return FutureBuilder(
      future: _viewLog,
      builder: (BuildContext context, AsyncSnapshot<ComicViewLog?> snapshot) {
        if (snapshot.hasError) {
          return _continueButton(
              text: "加载失败,点击重试",
              onPressed: () {
                setState(() {
                  _loadViewLog();
                });
              });
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return _continueButton(text: "加载中", onPressed: () {});
        }
        final viewLog = snapshot.data;
        if (viewLog != null) {
          if (viewLog.chapterId != 0) {
            return _continueButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComicReaderScreen(
                      comic: mockDetail,
                      chapterId: viewLog.chapterId,
                      loadChapter: _loadChapterF(chapters),
                      initRank: viewLog.pageRank,
                    ),
                  ),
                );
              },
              text: "继续阅读 ${viewLog.chapterTitle} - P.${viewLog.pageRank + 1}",
            );
          }
        }
        if (chapters.isNotEmpty) {
          if (chapters[0].data.isNotEmpty) {
            final f = chapters[0].data.reduce(
                (o1, o2) => o1.chapterOrder < o2.chapterOrder ? o1 : o2);
            return _continueButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComicReaderScreen(
                        comic: mockDetail,
                        chapterId: f.chapterId,
                        loadChapter: _loadChapterF(chapters),
                        initRank: 0,
                      ),
                    ),
                  );
                },
                text: "从头开始 ${f.chapterTitle}");
          }
        }
        return Container();
      },
    );
  }

  List<Widget> _buildChapters(List<ComicChapter> chapters) {
    final comic = widget.comic;
    return chapters
        .map((chapterColl) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(
                    top: 15,
                    bottom: 5,
                    left: 10,
                    right: 10,
                  ),
                  child: SelectableText(chapterColl.title),
                ),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: 10,
                    runSpacing: 5,
                    children: [
                      ...chapterColl.data.map((e) => Container(
                            margin: const EdgeInsets.all(3),
                            child: MaterialButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ComicReaderScreen(
                                      comic: ComicDetail(
                                        id: comic.id,
                                        title: comic.title,
                                        direction: comic.direction,
                                        isLong: comic.isLong,
                                        isAnimeHome: comic.isAnimeHome,
                                        cover: comic.cover,
                                        description: comic.description,
                                        lastUpdateTime: 0,
                                        lastUpdateChapterName: "",
                                        copyright: comic.copyright,
                                        firstLetter: comic.firstLetter,
                                        comicPy: comic.comicPy,
                                        hidden: 0,
                                        hotNum: 0,
                                        hitNum: 0,
                                        uid: 0,
                                        isLock: 0,
                                        lastUpdateChapterId: 0,
                                        types: List.of(
                                                jsonDecode(widget.comic.types))
                                            .cast<Map>()
                                            .map((e) => Item(
                                                id: e["id"], title: e["title"]))
                                            .toList(),
                                        status: List.of(
                                                jsonDecode(widget.comic.status))
                                            .cast<Map>()
                                            .map((e) => Item(
                                                id: e["id"], title: e["title"]))
                                            .toList(),
                                        authors: List.of(jsonDecode(
                                                widget.comic.authors))
                                            .cast<Map>()
                                            .map((e) => Item(
                                                id: e["id"], title: e["title"]))
                                            .toList(),
                                        subscribeNum: 0,
                                        chapters: chapters,
                                        isNeedLogin: 0,
                                        isHideChapter: 0,
                                      ),
                                      chapterId: e.chapterId,
                                      loadChapter: _loadChapterF(chapters),
                                      initRank: 0,
                                    ),
                                  ),
                                );
                              },
                              color: Colors.white,
                              child: Text(
                                e.chapterTitle,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          ))
                    ],
                  ),
                ),
              ],
            ))
        .toList();
  }

  Widget _continueButton({
    required Function() onPressed,
    required String text,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        var width = constraints.maxWidth;
        return Container(
          padding: const EdgeInsets.only(left: 10, right: 10),
          margin: const EdgeInsets.only(bottom: 10),
          width: width,
          child: MaterialButton(
            onPressed: onPressed,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .color!
                        .withOpacity(.05),
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<ComicChapterDetail> Function(int) _loadChapterF(
    List<ComicChapter> chapters,
  ) {
    return (int chapterId) async {
      for (var value in chapters) {
        for (var value1 in value.data) {
          if (value1.chapterId == chapterId) {
            var urls =
                await native.downloadComicPageByChapterId(chapterId: chapterId);
            return ComicChapterDetail(
              chapterId: chapterId,
              comicId: widget.comic.id,
              title: value1.chapterTitle,
              chapterOrder: value1.chapterOrder,
              direction: 0,
              pageUrl: urls,
              picnum: urls.length,
              pageUrlHd: urls,
              commentCount: 0,
            );
          }
        }
      }
      throw "章节未找到";
    };
  }
}
