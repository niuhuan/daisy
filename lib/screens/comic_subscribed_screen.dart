import 'dart:convert';

import 'package:daisy/configs/login.dart';
import 'package:daisy/ffi.dart';
import 'package:flutter/material.dart';

import 'components/comic_pager.dart';

class ComicSubscribedScreen extends StatefulWidget {
  const ComicSubscribedScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicSubscribedScreenState();
}

class _ComicSubscribedScreenState extends State<ComicSubscribedScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  Future<List<ComicInListCard>> _loadComic(int page) async {
    return (await native.subscribed(subType: 0, page: page))
        .map((e) => ComicInListCard(
              id: e.id,
              title: e.name,
              cover: e.subImg,
              authors: "",
              types: "",
              status1: e.status,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return loginScreen(() => ComicPager(_loadComic));
  }
}
