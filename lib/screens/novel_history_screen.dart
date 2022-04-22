import 'dart:convert';

import 'package:daisy/ffi.dart';
import 'package:flutter/material.dart';

import 'components/novel_pager.dart';

class NovelHistoryScreen extends StatefulWidget {
  const NovelHistoryScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NovelHistoryScreenState();
}

class _NovelHistoryScreenState extends State<NovelHistoryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  Future<List<NovelInPager>> _loadNovel(int page) async {
    return (await native.loadNovelViewLogs(page: page))
        .map((e) => NovelInPager(
              id: e.novelId,
              name: e.novelTitle,
              cover: e.novelCover,
              authors: e.novelAuthors,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NovelPager(_loadNovel);
  }
}
