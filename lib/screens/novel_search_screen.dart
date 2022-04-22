import 'package:daisy/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';

import 'components/novel_pager.dart';

class NovelSearchScreen extends StatefulWidget {
  final String content;

  const NovelSearchScreen(this.content, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NovelSearchScreenState();
}

class _NovelSearchScreenState extends State<NovelSearchScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<List<NovelInPager>> _loadNovel(int page) async {
    return (await native.novelSearch(content: widget.content, page: page))
        .map((e) => NovelInPager(
              id: e.id,
              name: e.title,
              cover: e.cover,
              authors: e.authors,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _searchBar.build(context),
      body: NovelPager(_loadNovel),
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

  late final SearchBar _searchBar = SearchBar(
    hintText: '搜索',
    controller: _textEditController,
    inBar: false,
    setState: setState,
    onSubmitted: (value) {
      if (value.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NovelSearchScreen(value),
          ),
        );
      }
    },
    buildDefaultAppBar: _buildDefaultAppBar,
  );
}
