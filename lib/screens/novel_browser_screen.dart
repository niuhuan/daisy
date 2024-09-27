import 'package:flutter/material.dart';

import '../commons.dart';
import '../const.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'components/novel_pager.dart';

class NovelBrowserScreen extends StatefulWidget {
  const NovelBrowserScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NovelBrowserScreenState();
}

class _NovelBrowserScreenState extends State<NovelBrowserScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _processMap = {
    0: "全部",
    1: "连载中",
    2: "已完结",
  };

  final _sorts = {
    0: "人气",
    1: "更新",
  };

  NovelCategoryDart? _selectedNovelCategory;

  int _process = 0;
  int _sort = 1;

  Future<List<NovelInPager>> _loadNovel(int page) async {
    return (await native.novelList(
      category: _selectedNovelCategory?.tagId ?? 0,
      process: _process,
      sort: _sort,
      page: page,
    ))
        .map((e) => NovelInPager(
            cover: e.cover, name: e.name, authors: e.authors, id: e.id))
        .toList();
  }

  Widget _filterBar() {
    final borderColor = Theme.of(context).dividerColor;
    return Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: .25),
          ),
          child: GestureDetector(
            onTap: () async {
              List<Entity<NovelCategoryDart?>> entities = [];
              entities.add(Entity("全部", null));
              for (var c in novelCategories) {
                entities.add(Entity(c.title, c));
              }
              final choose = await chooseEntity(context, "选择题材", entities);
              if (choose != null) {
                setState(() {
                  _selectedNovelCategory = choose.value;
                });
              }
            },
            child: Row(
              children: [
                Expanded(child: Container()),
                const Icon(Icons.category),
                Container(width: 3),
                Text(_selectedNovelCategory?.title ?? "题材"),
                Expanded(child: Container()),
              ],
            ),
          ),
        ),
      ),
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: .25),
          ),
          child: GestureDetector(
            onTap: () async {
              final choose = await chooseMapDialog(context,
                  title: "选择进度",
                  values:
                      _processMap.map((key, value) => MapEntry(value, key)));
              if (choose != null) {
                setState(() {
                  _process = choose;
                });
              }
            },
            child: Row(
              children: [
                Expanded(child: Container()),
                const Icon(Icons.percent),
                Container(width: 3),
                Text(_processMap[_process] ?? "进度"),
                Expanded(child: Container()),
              ],
            ),
          ),
        ),
      ),
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: .25),
          ),
          child: Center(
            child: PopupMenuButton<int>(
              offset: const Offset(-10, 50),
              child: Row(
                children: [
                  Expanded(child: Container()),
                  const Icon(Icons.mobiledata_off),
                  Container(width: 3),
                  Text(_sorts[_sort] ?? ""),
                  Expanded(child: Container()),
                ],
              ),
              itemBuilder: (BuildContext context) {
                return _sorts.entries
                    .map((e) => PopupMenuItem(
                          value: e.key,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Text(e.value),
                          ),
                        ))
                    .toList();
              },
              onSelected: (int value) {
                setState(() {
                  _sort = value;
                });
              },
            ),
          ),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: _filterBar(),
      ),
      body: NovelPager(
        _loadNovel,
        key: Key("$_selectedNovelCategory|$_process|$_sort"),
      ),
    );
  }
}
