import 'package:daisy/screens/novel_detail_screen.dart';
import 'package:daisy/screens/components/images.dart';
import 'package:flutter/material.dart';
import 'package:daisy/const.dart';

class NovelInPager {
  final String cover;
  final String name;
  final String authors;
  final int id;

  NovelInPager({
    required this.cover,
    required this.name,
    required this.authors,
    required this.id,
  });
}

class NovelPager extends StatefulWidget {
  final Future<List<NovelInPager>> Function(int page) loadNovel;

  const NovelPager(this.loadNovel, {super.key});

  @override
  State<StatefulWidget> createState() => _NovelPagerState();
}

class _NovelPagerState extends State<NovelPager> {
  // page 从0开始
  int _currentPage = 0;

  final List<NovelInPager> _list = [];
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
      var list = await widget.loadNovel(_currentPage);
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
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (BuildContext context) {
              return NovelDetailScreen(novelId: e.id);
            }),
          );
        },
        child: NovelCardInPager(novel: e),
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

class NovelCardInPager extends StatelessWidget {
  final NovelInPager novel;

  const NovelCardInPager({super.key, required this.novel});

  @override
  Widget build(BuildContext context) {
    double width = coverWidth * .3;
    double height = coverHeight * .3;
    Widget statusIcon = Container();
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
            url: novel.cover,
            useful: 'novel_cover',
            extendsFieldIntFirst: novel.id,
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
                  novel.name,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                Container(height: 10),
                Text(
                  novel.authors,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                Container(height: 10),
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
