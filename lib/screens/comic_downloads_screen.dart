import 'dart:convert';

import 'package:daisy/commons.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';

import '../src/rust/api/bridge.dart';
import 'comic_download_info_screen.dart';
import 'components/comic_pager.dart';

class ComicDownloadsScreen extends StatefulWidget {
  const ComicDownloadsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ComicDownloadsScreenState();
}

class _ComicDownloadsScreenState extends State<ComicDownloadsScreen> {
  late Future<List<DownloadComic>> _f;

  void resetLoad() {
    _f = native.allDownloads();
  }

  @override
  void initState() {
    resetLoad();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _f,
      builder:
          (BuildContext context, AsyncSnapshot<List<DownloadComic>> snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("完了, 芭比Q了"),
          );
        }
        print(snapshot.connectionState);
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Text("加载中"),
          );
        }
        return _list(snapshot.requireData);
      },
    );
  }

  Widget _list(List<DownloadComic> requireData) {
    return RefreshIndicator(
      onRefresh: () async {
        resetLoad();
      },
      child: ListView(
        children: [
          ...(requireData.map((e) => GestureDetector(
                onTap: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (BuildContext context) {
                    return ComicDownloadInfoScreen(comic: e);
                  }));
                },
                onLongPress: () {
                  () async {
                    final choose =
                        await confirmDialog(context, "是否删除下载?", e.title);
                    if (choose) {
                      await native.deleteDownload(id: e.id);
                      setState(() {
                        resetLoad();
                      });
                    }
                  }();
                },
                child: ComicCardInPager(
                  comic: ComicInListCard(
                    id: e.id,
                    title: e.title,
                    types: List.of(jsonDecode(e.types))
                        .cast<Map>()
                        .map((e) => e["title"].toString())
                        .join(","),
                    cover: e.cover,
                    authors: List.of(jsonDecode(e.authors))
                        .cast<Map>()
                        .map((e) => e["title"].toString())
                        .join(","),
                    downloadStatus: e.downloadStatus,
                    imageCount: e.imageCount,
                    imageCountDownload: e.imageCountDownload,
                  ),
                ),
              )))
        ],
      ),
    );
  }
}
