import 'package:daisy/commons.dart';
import 'package:daisy/configs/login.dart';
import 'package:daisy/screens/comic_detail_screen.dart';
import 'package:daisy/screens/components/images.dart';
import 'package:flutter/material.dart';
import 'package:daisy/const.dart';
import '../../utils.dart';

class ComicInListCard {
  final int id;
  final String title;
  final String? status1;
  final int? status2;
  final String types;
  final String cover;
  final String authors;
  final int? lastUpdateTime;
  final int? addtime;
  final int? downloadStatus;
  final int imageCountDownload;
  final int imageCount;

  ComicInListCard({
    required this.id,
    required this.title,
    this.status1,
    this.status2,
    required this.types,
    required this.cover,
    required this.authors,
    this.lastUpdateTime,
    this.addtime,
    this.downloadStatus,
    this.imageCountDownload = 0,
    this.imageCount = 0,
  });
}

class ComicPager extends StatefulWidget {
  final Future<List<ComicInListCard>> Function(int page) loadComic;

  const ComicPager(this.loadComic, {super.key});

  @override
  State<StatefulWidget> createState() => _ComicPagerState();
}

class _ComicPagerState extends State<ComicPager> {
  // page 从0开始
  int _currentPage = 0;

  final List<ComicInListCard> _list = [];
  bool _loading = false;
  bool _over = false;
  bool _fail = false;

  final _controller = ScrollController();

  Future _loadNextPage() async {
    setState(() {
      _fail = false;
      _loading = true;
    });
    try {
      var list = await widget.loadComic(_currentPage);
      if (list.isEmpty) {
        _over = true;
      }
      _list.addAll(list);
      _currentPage++;
    } catch (e, s) {
      print("$e");
      print("$s");
      _fail = true;
    }
    setState(() {
      _loading = false;
    });
  }

  void _onScroll() {
    if (_controller.position.pixels + MediaQuery.of(context).size.height / 2 >
        _controller.position.maxScrollExtent) {
      if (!_fail && !_over && !_loading) {
        _loadNextPage();
      }
    }
  }

  @override
  void initState() {
    _loadNextPage();
    _controller.addListener(_onScroll);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_over && _list.isEmpty) {
      return const Center(child: Text("这里没有任何资源"));
    }
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _currentPage = 0;
          _list.clear();
        });
        _loadNextPage();
      },
      child: ListView(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        children: [
          ..._buildList(),
          _buildLoadingView(),
        ],
      ),
    );
  }

  List<Widget> _buildList() {
    return _list.map((e) {
      return GestureDetector(
        onTap: () async {
          if (loginInfo.status == 1) {
            defaultToast(context, "请先登录");
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (BuildContext context) {
              return ComicDetailScreen(comicId: e.id);
            }),
          );
        },
        child: ComicCardInPager(comic: e),
      );
    }).toList();
  }

  Widget _buildLoadingView() {
    if (_loading) {
      return Container(
        margin: const EdgeInsets.all(10),
        color: Colors.grey.withAlpha(30),
        child: const Center(
          child: Text("加载中"),
        ),
      );
    }
    if (_fail) {
      return GestureDetector(
        onTap: () {
          _loadNextPage();
        },
        child: Container(
          margin: const EdgeInsets.all(10),
          color: Colors.grey.withAlpha(30),
          child: const Center(
            child: Text("加载失败"),
          ),
        ),
      );
    }
    if (_over) {
      return Container(
        margin: const EdgeInsets.all(10),
        color: Colors.grey.withAlpha(30),
        child: const Center(
          child: Text("全部加载完"),
        ),
      );
    }
    return Container();
  }
}

class ComicCardInPager extends StatelessWidget {
  final ComicInListCard comic;

  const ComicCardInPager({super.key, required this.comic});

  @override
  Widget build(BuildContext context) {
    double width = coverWidth * .3;
    double height = coverHeight * .3;
    Widget statusIcon = Container();
    if (comic.status1 != null) {
      late String log;
      late Color logColor;
      switch (comic.status1) {
        case '连载中':
          log = "更";
          logColor = Colors.green.shade200;
          break;
        case '已完结':
          log = "完";
          logColor = Colors.orange.shade200;
          break;
        default:
          log = "无";
          logColor = Colors.grey;
          break;
      }
      statusIcon = Container(
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
      );
    }
    var theme = Theme.of(context);
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
            fit: BoxFit.cover,
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
                Text(
                  comic.authors,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                Container(height: 10),
                Text(
                  comic.types,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                ...comic.lastUpdateTime != null
                    ? [
                        Container(height: 10),
                        Text(
                          "U : ${timeFormat(comic.lastUpdateTime!)}",
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ]
                    : [],
                ...comic.addtime != null
                    ? [
                        Container(height: 10),
                        Text(
                          "A : ${timeFormat(comic.addtime!)}",
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ]
                    : [],
                ...comic.downloadStatus != null
                    ? [
                        Container(height: 10),
                        Text(
                          "${comic.downloadStatus == 0
                                  ? "未完成"
                                  : comic.downloadStatus == 1
                                      ? "成功"
                                      : comic.downloadStatus == 2
                                          ? "成功"
                                          : "其他"} : ${comic.imageCountDownload} / ${comic.imageCount}",
                          style: TextStyle(
                            fontSize: 12,
                            color: comic.downloadStatus == 0
                                ? Colors.blue
                                : comic.downloadStatus == 1
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        )
                      ]
                    : [],
              ],
            ),
          ),
          SizedBox(
            height: height,
            child: Column(
              children: [
                statusIcon,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
