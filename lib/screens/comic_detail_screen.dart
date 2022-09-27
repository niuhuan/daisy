import 'package:daisy/screens/components/content_error.dart';
import 'package:daisy/screens/components/images.dart';
import 'package:daisy/screens/components/subscribed_icon.dart';
import 'package:flutter/material.dart';
import 'package:daisy/ffi.dart';
import 'package:uuid/uuid.dart';

import '../commons.dart';
import '../const.dart';
import '../utils.dart';
import 'comic_reader_screen.dart';
import 'components/comment_pager.dart';
import 'components/content_loading.dart';

class ComicDetailScreen extends StatefulWidget {
  final int comicId;

  const ComicDetailScreen({
    required this.comicId,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicDetailScreenState();
}

class _ComicDetailScreenState extends State<ComicDetailScreen> with RouteAware {
  late Key _loadKey;
  late Future<ComicDetail> _load;
  late Future<ComicViewLog?> _viewLog;
  int _tabIndex = 0;

  void _reload() {
    _loadKey = Key((const Uuid()).v4());
    _load = native.comicDetail(id: widget.comicId);
  }

  void _loadViewLog() {
    _viewLog = native.viewLogByComicId(comicId: widget.comicId);
  }

  @override
  void initState() {
    _reload();
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
      key: _loadKey,
      future: _load,
      builder: (BuildContext context, AsyncSnapshot<ComicDetail> snapshot) {
        if (snapshot.hasError) {
          return ContentError(
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
            onRefresh: () async {
              setState(() {
                _reload();
              });
            },
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("加载中"),
            ),
            body: const ContentLoading(),
          );
        }
        var comic = snapshot.requireData;
        const _tabs = <Widget>[
          Tab(text: '章节'),
          Tab(text: '评论'),
        ];
        var _views = <Widget>[
          Column(children: [
            Container(height: 20),
            _buildContinueButton(comic),
            ..._buildChapters(comic),
          ]),
          CommentPager(ObjType.comic, comic.id, false),
        ];
        final theme = Theme.of(context);
        return DefaultTabController(
          length: _tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text(comic.title),
              actions: [
                SubscribedIcon(objType: 0, objId: widget.comicId),
              ],
            ),
            body: ListView(
              children: [
                Container(height: 3),
                ComicCard(comic: comic),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: SelectableText(comic.description),
                ),
                const Divider(),
                Container(
                  height: 40,
                  color: theme.colorScheme.secondary.withOpacity(.025),
                  child: TabBar(
                    tabs: _tabs,
                    indicatorColor: theme.colorScheme.secondary,
                    labelColor: theme.colorScheme.secondary,
                    onTap: (val) async {
                      setState(() {
                        _tabIndex = val;
                      });
                    },
                  ),
                ),
                _views[_tabIndex],
                const Divider(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueButton(ComicDetail comic) {
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
                      comic: comic,
                      chapterId: viewLog.chapterId,
                      loadChapter: _loadChapterF(comic),
                      initRank: viewLog.pageRank,
                    ),
                  ),
                );
              },
              text: "继续阅读 ${viewLog.chapterTitle} - P.${viewLog.pageRank + 1}",
            );
          }
        }
        if (comic.chapters.isNotEmpty) {
          if (comic.chapters[0].data.isNotEmpty) {
            final f = comic.chapters[0].data.reduce(
                (o1, o2) => o1.chapterOrder < o2.chapterOrder ? o1 : o2);
            return _continueButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComicReaderScreen(
                        comic: comic,
                        chapterId: f.chapterId,
                        loadChapter: _loadChapterF(comic),
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
                          margin: EdgeInsets.all(3),
                          child: MaterialButton(
                            onPressed: () {
                              print("=========");
                              print(comic.id);
                              print(e.chapterId);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ComicReaderScreen(
                                    comic: comic,
                                    chapterId: e.chapterId,
                                    loadChapter: _loadChapterF(comic),
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
                        ),
                      )
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
                        .bodyText1!
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

  Future<ComicChapterDetail> Function(int) _loadChapterF(ComicDetail comic) {
    return (int chapterId) {
      return native.comicChapterDetail(comicId: comic.id, chapterId: chapterId);
    };
  }
}

class ComicCard extends StatelessWidget {
  final ComicDetail comic;

  const ComicCard({Key? key, required this.comic}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = coverWidth * .3;
    double height = coverHeight * .3;
    var statuses = comic.status.map((e) => e.title).toList();

    var theme = Theme.of(context);
    late String log;
    late Color logColor;
    if (statuses.contains('连载中')) {
      log = "更";
      logColor = Colors.green.shade200;
    } else if (statuses.contains('已完结')) {
      log = "完";
      logColor = Colors.orange.shade200;
    } else {
      log = "无";
      logColor = Colors.grey;
    }
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          LoadingCacheImage(
            url: comic.cover,
            useful: 'comic_cover',
            extendsFieldIntFirst: comic.id,
            width: width,
            height: height,
          ),
          Container(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comic.title,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                Container(height: 10),
                Wrap(
                  spacing: 10,
                  children: comic.authors
                      .map((e) => Text(
                            e.title,
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ))
                      .toList(),
                ),
                Container(height: 10),
                Wrap(
                  spacing: 10,
                  children: comic.types
                      .map((e) => Text(
                            e.title,
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ))
                      .toList(),
                ),
                Container(height: 10),
                Text(
                  timeFormat(comic.lastUpdateTime),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: height,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(3),
                  padding: const EdgeInsets.fromLTRB(5, 3, 5, 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: logColor,
                  ),
                  child: Text(
                    log,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      color: Colors.white,
                    ),
                    strutStyle: const StrutStyle(
                      fontSize: 10,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
