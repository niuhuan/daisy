import 'package:daisy/configs/login.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';
import 'components/comic_pager.dart';

class ComicSubscribedScreen extends StatefulWidget {
  const ComicSubscribedScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ComicSubscribedScreenState();
}

class _ComicSubscribedScreenState extends State<ComicSubscribedScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  var _tabIdx = 0;

  Future<List<ComicInListCard>> _loadComic(int page) async {
    return (await native.subscribedList(
      type: 0,
      page: page,
      subType: _tabIdx + 1,
    ))
        .map((e) => ComicInListCard(
              id: e.id,
              title: e.name,
              cover: e.subImg,
              authors: "",
              types: "",
              status1: e.status,
              subReaded: e.subReaded,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final AppBarTheme appBarTheme = AppBarTheme.of(context);
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: appBarTheme.backgroundColor,
            child: TabBar(
              onTap: (index) {
                setState(() {
                  _tabIdx = index;
                });
              },
              tabs: const [
                Tab(child: Text("全部")),
                Tab(child: Text("未读")),
                Tab(child: Text("已读")),
                Tab(child: Text("完结")),
              ],
            ),
          ),
          Expanded(
            child: loginScreen(
              () => ComicPager(
                key: Key("_ComicSubscribedScreenStatePager:${_tabIdx + 1}"),
                _loadComic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
