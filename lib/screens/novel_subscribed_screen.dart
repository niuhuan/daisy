import 'package:daisy/configs/login.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';

import 'components/novel_pager.dart';

class NovelSubscribedScreen extends StatefulWidget {
  const NovelSubscribedScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NovelSubscribedScreenState();
}

class _NovelSubscribedScreenState extends State<NovelSubscribedScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  var _tabIdx = 0;

  Future<List<NovelInPager>> _loadNovel(int page) async {
    return (await native.subscribedList(type: 1, page: page, subType: _tabIdx + 1))
        .map((e) => NovelInPager(
              id: e.id,
              name: e.name,
              cover: e.subImg,
              authors: "",
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
                  () => NovelPager(
                key: Key("_NovelSubscribedScreenState:${_tabIdx + 1}"),
                    _loadNovel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
