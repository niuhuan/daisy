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

  Future<List<NovelInPager>> _loadNovel(int page) async {
    return (await native.subscribedList(subType: 1, page: page))
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
    return loginScreen(() => NovelPager(_loadNovel));
  }
}
