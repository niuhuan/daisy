import 'dart:typed_data';

import 'package:daisy/commons.dart';
import 'package:daisy/screens/components/content_error.dart';
import 'package:daisy/screens/components/content_loading.dart';
import 'package:flutter/material.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;

import '../const.dart';
import '../src/rust/anime_home/entities.dart';
import 'components/comic_pager.dart';

class ComicBrowserScreen extends StatefulWidget {
  const ComicBrowserScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ComicBrowserScreenState();
}

class _ComicBrowserScreenState extends State<ComicBrowserScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _selectedComicCategories = ComicCategoryGroup<ComicCategory?>(
    null,
    null,
    null,
    null,
  );

  final _sorts = {
    0: "人气",
    1: "更新",
  };

  int _sort = 1;

  late Future<ComicCategoryGroup<List<ComicCategory>>> _filterGroupsFuture =
      _loadFilterGroups();

  Future<ComicCategoryGroup<List<ComicCategory>>> _loadFilterGroups() async {
    try {
      final serverCategories = await _loadFilters();
      return ComicCategoryGroup<List<ComicCategory>>(
        _mapToCategory(serverCategories[0]),
        _mapToCategory(serverCategories[1]),
        _mapToCategory(serverCategories[2]),
        _mapToCategory(serverCategories[3]),
      );
    } catch (e, s) {
      print("$e\n$s");
      return comicCategories;
    }
  }

  List<ComicCategory> _mapToCategory(ComicFilter serverCategory) {
    List<ComicCategory> c = [];
    for (var value in serverCategory.items) {
      if (value.tagId != 0) {
        c.add(ComicCategory(
          title: value.tagName,
          cover: '',
          tagId: value.tagId,
        ));
      }
    }
    return c;
  }

  Future<List<ComicFilter>> _loadFilters() async {
    try {
      return await native.comicClassifyFilters();
    } catch (e, s) {
      print("$e\n$s");
      return await native.comicClassifyFiltersOld();
    }
  }

  Future<List<ComicInListCard>> _loadComic(int page) async {
    return (await native.comicClassifyWithLevel(
      sort: _sort,
      page: page,
      categories: Int32List.fromList(
          _selectedComicCategories.filtered().map((e) => e!.tagId).toList()),
    ))
        .map((e) => ComicInListCard(
              id: e.id,
              title: e.title,
              types: e.types,
              cover: e.cover,
              authors: e.authors,
              lastUpdateTime: e.lastUpdateTime,
              status1: e.status,
            ))
        .toList();
  }

  Widget _filterBar(ComicCategoryGroup<List<ComicCategory>> comicCategories) {
    final borderColor = Theme.of(context).dividerColor;
    return Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: .25),
          ),
          child: GestureDetector(
            onTap: () async {
              List<Entity<ComicCategory?>> entities = [];
              entities.add(Entity("全部", null));
              for (var c in comicCategories.matter) {
                entities.add(Entity(c.title, c));
              }
              final choose = await chooseEntity(context, "选择题材", entities);
              if (choose != null) {
                setState(() {
                  _selectedComicCategories.matter = choose.value;
                });
              }
            },
            child: Row(
              children: [
                Expanded(child: Container()),
                const Icon(Icons.category),
                Container(width: 3),
                Text(_selectedComicCategories.matter?.title ?? "题材"),
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
              List<Entity<ComicCategory?>> entities = [];
              entities.add(Entity("全部", null));
              for (var c in comicCategories.userGroup) {
                entities.add(Entity(c.title, c));
              }
              final choose = await chooseEntity(context, "选择用户群体", entities);
              if (choose != null) {
                setState(() {
                  _selectedComicCategories.userGroup = choose.value;
                });
              }
            },
            child: Row(
              children: [
                Expanded(child: Container()),
                const Icon(Icons.group),
                Container(width: 3),
                Text(_selectedComicCategories.userGroup?.title ?? "群体"),
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
              List<Entity<ComicCategory?>> entities = [];
              entities.add(Entity("全部", null));
              for (var c in comicCategories.processStatus) {
                entities.add(Entity(c.title, c));
              }
              final choose = await chooseEntity(context, "选择进度", entities);
              if (choose != null) {
                setState(() {
                  _selectedComicCategories.processStatus = choose.value;
                });
              }
            },
            child: Row(
              children: [
                Expanded(child: Container()),
                const Icon(Icons.percent),
                Container(width: 3),
                Text(_selectedComicCategories.processStatus?.title ?? "进度"),
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
              List<Entity<ComicCategory?>> entities = [];
              entities.add(Entity("全部", null));
              for (var c in comicCategories.region) {
                entities.add(Entity(c.title, c));
              }
              final choose = await chooseEntity(context, "选择地区", entities);
              if (choose != null) {
                setState(() {
                  _selectedComicCategories.region = choose.value;
                });
              }
            },
            child: Row(
              children: [
                Expanded(child: Container()),
                const Icon(Icons.public),
                Container(width: 3),
                Text(_selectedComicCategories.region?.title ?? "地区"),
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
    return FutureBuilder(
      future: _filterGroupsFuture,
      builder: (BuildContext context,
          AsyncSnapshot<ComicCategoryGroup<List<ComicCategory>>> snapshot) {
        if (snapshot.hasError) {
          return ContentError(
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
            onRefresh: () async {
              setState(() {
                _filterGroupsFuture = _loadFilterGroups();
              });
            },
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const ContentLoading();
        }
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: _filterBar(snapshot.requireData),
          ),
          body: ComicPager(
            _loadComic,
            key: Key(
                "${_selectedComicCategories.filtered().map((e) => e!.tagId.toString()).join("_")}:$_sort"),
          ),
        );
      },
    );
  }
}
