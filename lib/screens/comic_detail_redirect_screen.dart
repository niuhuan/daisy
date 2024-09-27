import 'dart:async';

import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:daisy/screens/comic_detail_screen.dart';
import 'package:daisy/screens/components/content_error.dart';
import 'package:daisy/screens/components/content_loading.dart';
import 'package:flutter/material.dart';

class ComicDetailRedirectScreen extends StatefulWidget {
  final String comicIdString;

  const ComicDetailRedirectScreen({super.key, required this.comicIdString});

  @override
  State<StatefulWidget> createState() => _ComicDetailRedirectScreenState();
}

class _ComicDetailRedirectScreenState extends State<ComicDetailRedirectScreen> {
  late Future _future;

  @override
  void initState() {
    _future =
        native.loadComicId(comicIdString: widget.comicIdString).then(push);
    super.initState();
  }

  push(int comicId) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (BuildContext context) {
        return ComicDetailScreen(comicId: comicId);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasError) {
          return ContentError(
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
            onRefresh: () async {
              setState(() {
                _future = native
                    .loadComicId(comicIdString: widget.comicIdString)
                    .then(push);
              });
            },
          );
        }
        return const ContentLoading();
      },
    );
  }
}
