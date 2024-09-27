import 'dart:convert';

import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';

import 'components/comic_pager.dart';

class ComicHistoryScreen extends StatefulWidget {
  const ComicHistoryScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ComicHistoryScreenState();
}

class _ComicHistoryScreenState extends State<ComicHistoryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  Future<List<ComicInListCard>> _loadComic(int page) async {
    return (await native.loadComicViewLogs(page: page))
        .map((e) => ComicInListCard(
              id: e.comicId,
              title: e.comicTitle,
              cover: e.comicCover,
              authors: mapTitle(e.comicAuthors),
              types: mapTitle(e.comicTypes),
            ))
        .toList();
  }

  String mapTitle(String json) {
    try {
      List maps = jsonDecode(json);
      return maps.cast<Map>().map((e) {
        try {
          String title = e["title"];
          return title;
        } catch (e, s) {
          print("$e\n$s");
        }
        return "";
      }).join("/");
    } catch (e, s) {
      print("$e\n$s");
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ComicPager(_loadComic);
  }
}
