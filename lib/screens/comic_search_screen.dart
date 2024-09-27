import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';
import 'components/flutter_search_bar.dart' as sb;

import 'components/comic_pager.dart';

class ComicSearchScreen extends StatefulWidget {
  final String content;

  const ComicSearchScreen(this.content, {super.key});

  @override
  State<StatefulWidget> createState() => _ComicSearchScreenState();
}

class _ComicSearchScreenState extends State<ComicSearchScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<List<ComicInListCard>> _loadComic(int page) async {
    return (await native.comicSearch(content: widget.content, page: page))
        .map((e) => ComicInListCard(
              id: e.id,
              title: e.title,
              types: e.types,
              cover: e.cover,
              authors: e.authors,
              addtime: e.addtime,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _searchBar.build(context),
      body: ComicPager(_loadComic),
    );
  }

  AppBar _buildDefaultAppBar(BuildContext context) {
    return AppBar(
      title: Text("搜索 - ${widget.content}"),
      actions: [
        IconButton(
          onPressed: () {
            _textEditController.text = widget.content;
            _searchBar.beginSearch(context);
          },
          icon: const Icon(Icons.search),
        ),
      ],
    );
  }

  late final TextEditingController _textEditController =
      TextEditingController(text: '');

  late final sb.SearchBar _searchBar = sb.SearchBar(
    hintText: '搜索',
    controller: _textEditController,
    inBar: false,
    setState: setState,
    onSubmitted: (value) {
      if (value.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ComicSearchScreen(value),
          ),
        );
      }
    },
    buildDefaultAppBar: _buildDefaultAppBar,
  );
}
