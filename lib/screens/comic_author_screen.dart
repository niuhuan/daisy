import 'package:daisy/screens/components/comic_pager.dart';
import 'package:daisy/screens/components/content_error.dart';
import 'package:daisy/screens/components/content_loading.dart';
import 'package:daisy/src/rust/anime_home/entities.dart';
import 'package:flutter/material.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;

import 'comic_detail_screen.dart';

class ComicAuthorScreen extends StatefulWidget {
  final int authorId;

  const ComicAuthorScreen({required this.authorId, super.key});

  @override
  State<ComicAuthorScreen> createState() => _ComicAuthorScreenState();
}

class _ComicAuthorScreenState extends State<ComicAuthorScreen> {
  late Future<Author> _future;

  @override
  void initState() {
    _loadPage();
    super.initState();
  }

  void _loadPage() {
    _future = native.author(id: widget.authorId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('作者详情'),
        ),
        body: FutureBuilder<Author>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ContentLoading();
            } else if (snapshot.hasError) {
              return ContentError(
                  error: snapshot.error!,
                  stackTrace: snapshot.stackTrace!,
                  onRefresh: () async {
                    _loadPage();
                  });
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No data found'));
            } else {
              final author = snapshot.data!;
              return ListView(
                children: [...author.data.map(mapToCard)],
              );
            }
          },
        ));
  }

  Widget mapToCard(ComicInAuthor e) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (BuildContext context) {
            return ComicDetailScreen(comicId: e.id);
          }),
        );
      },
      child: ComicCardInPager(
        comic: ComicInListCard(
          id: e.id,
          title: e.name,
          types: '',
          cover: e.cover,
          authors: '',
        ),
      ),
    );
  }
}
