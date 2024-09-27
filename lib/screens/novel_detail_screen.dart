import 'package:daisy/configs/novel_reader_type.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../commons.dart';
import '../const.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import '../src/rust/anime_home/proto.dart';
import '../src/rust/api/bridge.dart';
import '../utils.dart';
import 'components/comment_pager.dart';
import 'components/content_error.dart';
import 'components/content_loading.dart';
import 'components/images.dart';
import 'components/subscribed_icon.dart';
import 'novel_html_reader_screen.dart';
import 'novel_new_reader_screen.dart';
import 'novel_reader_screen.dart';

class NovelDetailScreen extends StatefulWidget {
  final int novelId;

  const NovelDetailScreen({
    required this.novelId,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _NovelDetailScreenState();
}

class _NovelDetailScreenState extends State<NovelDetailScreen> with RouteAware {
  late Key _loadKey;
  late NovelDetail _detail;
  late List<NovelVolume> _volumes;
  late Future _load;

  late Future<NovelViewLog?> _viewLog;
  int _tabIndex = 0;

  void _reload() {
    _loadKey = Key((const Uuid()).v4());
    _load = () async {
      _detail = await native.novelDetail(id: widget.novelId);
      _volumes = await native.novelChapters(id: widget.novelId);
    }();
  }

  void _loadViewLog() {
    _viewLog = native.viewLogByNovelId(novelId: widget.novelId);
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
      builder: (BuildContext context, AsyncSnapshot snapshot) {
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
        const tabs = <Widget>[
          Tab(text: '章节'),
          Tab(text: '评论'),
        ];
        var views = <Widget>[
          Column(children: [
            Container(height: 20),
            _buildContinueButton(),
            ..._buildChapters(),
          ]),
          CommentPager(ObjType.novel, widget.novelId, false),
        ];
        final theme = Theme.of(context);
        final dividerColor = theme.dividerColor;
        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text(_detail.name),
              actions: [
                SubscribedIcon(objType: 1, objId: widget.novelId),
              ],
            ),
            body: ListView(
              children: [
                Container(height: 3),
                NovelCard(novel: _detail),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: SelectableText(_detail.introduction),
                ),
                Divider(color: dividerColor),
                Container(
                  height: 40,
                  color: theme.colorScheme.secondary.withOpacity(.025),
                  child: TabBar(
                    tabs: tabs,
                    indicatorColor: theme.colorScheme.secondary,
                    labelColor: theme.colorScheme.secondary,
                    onTap: (val) async {
                      setState(() {
                        _tabIndex = val;
                      });
                    },
                    dividerColor: dividerColor,
                  ),
                ),
                views[_tabIndex],
                Divider(color: dividerColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueButton() {
    return FutureBuilder(
      future: _viewLog,
      builder: (BuildContext context, AsyncSnapshot<NovelViewLog?> snapshot) {
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
            for (var volume in _volumes) {
              if (volume.id == viewLog.volumeId) {
                for (var chapter in volume.chapters) {
                  if (chapter.chapterId == viewLog.chapterId) {
                    return _continueButton(
                        onPressed: () {
                          switch (currentNovelReaderType) {
                            case NovelReaderType.move:
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NovelReaderScreen(
                                    novel: _detail,
                                    volumes: _volumes,
                                    initChapterId: chapter.chapterId,
                                  ),
                                ),
                              );
                              break;
                            case NovelReaderType.html:
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NovelHtmlReaderScreen(
                                    novel: _detail,
                                    volumes: _volumes,
                                    chapter: chapter,
                                    volume: volume,
                                  ),
                                ),
                              );
                              break;
                            case NovelReaderType.picMove:
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NovelNewReaderScreen(
                                    novel: _detail,
                                    volumes: _volumes,
                                    initChapterId: chapter.chapterId,
                                  ),
                                ),
                              );
                              break;
                          }
                        },
                        text:
                            "继续阅读 ${viewLog.chapterTitle}"); // - P.${viewLog.pageRank + 1}
                  }
                }
              }
            }
          }
        }
        if (_volumes.isNotEmpty) {
          final volume =
              _volumes.reduce((o1, o2) => o1.rank < o2.rank ? o1 : o2);
          if (volume.chapters.isNotEmpty) {
            final chapter = _volumes[0].chapters.reduce(
                (o1, o2) => o1.chapterOrder < o2.chapterOrder ? o1 : o2);
            return _continueButton(
                onPressed: () {
                  switch (currentNovelReaderType) {
                    case NovelReaderType.move:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NovelReaderScreen(
                            novel: _detail,
                            volumes: _volumes,
                            initChapterId: chapter.chapterId,
                          ),
                        ),
                      );
                      break;
                    case NovelReaderType.html:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NovelHtmlReaderScreen(
                            novel: _detail,
                            volumes: _volumes,
                            chapter: chapter,
                            volume: volume,
                          ),
                        ),
                      );
                      break;
                    case NovelReaderType.picMove:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NovelNewReaderScreen(
                            novel: _detail,
                            volumes: _volumes,
                            initChapterId: chapter.chapterId,
                          ),
                        ),
                      );
                      break;
                  }
                },
                text: "从头开始 ${chapter.chapterName}");
          }
        }
        return Container();
      },
    );
  }

  List<Widget> _buildChapters() {
    return _volumes
        .map((volume) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(
                    top: 15,
                    bottom: 5,
                    left: 10,
                    right: 10,
                  ),
                  child: SelectableText(volume.title),
                ),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: 10,
                    runSpacing: 5,
                    children: [
                      ...volume.chapters.map(
                        (e) => Container(
                          margin: const EdgeInsets.all(3),
                          child: MaterialButton(
                            onPressed: () {
                              print("=========");
                              print(_detail.id);
                              print(volume.id);
                              print(e.chapterId);

                              switch (currentNovelReaderType) {
                                case NovelReaderType.move:
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NovelReaderScreen(
                                        novel: _detail,
                                        initChapterId: e.chapterId,
                                        volumes: _volumes,
                                        // loadChapter: _loadChapterF(),
                                        // initRank: 0,
                                      ),
                                    ),
                                  );
                                  break;
                                case NovelReaderType.html:
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          NovelHtmlReaderScreen(
                                        novel: _detail,
                                        volume: volume,
                                        chapter: e,
                                        volumes: _volumes,
                                        // loadChapter: _loadChapterF(),
                                        // initRank: 0,
                                      ),
                                    ),
                                  );
                                  break;
                                case NovelReaderType.picMove:
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          NovelNewReaderScreen(
                                        novel: _detail,
                                        initChapterId: e.chapterId,
                                        volumes: _volumes,
                                        // loadChapter: _loadChapterF(),
                                        // initRank: 0,
                                      ),
                                    ),
                                  );
                                  break;
                              }
                            },
                            color: Colors.white,
                            child: Text(
                              e.chapterName,
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

// Future<ChapterDetail> Function(int) _loadChapterF(NovelDetail novel) {
//   return (int chapterId) {
//     return native.novelChapterDetail(novelId: novel.id, chapterId: chapterId);
//   };
// }
}

class NovelCard extends StatelessWidget {
  final NovelDetail novel;

  const NovelCard({super.key, required this.novel});

  @override
  Widget build(BuildContext context) {
    double width = coverWidth * .3;
    double height = coverHeight * .3;
    var statuses = novel.status;

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
            url: novel.cover,
            useful: 'novel_cover',
            extendsFieldIntFirst: novel.id,
            width: width,
            height: height,
          ),
          Container(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  novel.name,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                Container(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    Text(
                      novel.authors,
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(height: 10),
                Wrap(
                  spacing: 10,
                  children: novel.types
                      .map((e) => Text(
                            e,
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ))
                      .toList(),
                ),
                Container(height: 10),
                Text(
                  timeFormat(novel.lastUpdateTime),
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
