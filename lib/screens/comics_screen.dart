import 'package:daisy/screens/about_screen.dart';
import 'package:daisy/screens/app_screen.dart';
import 'package:daisy/screens/components/badged.dart';
import 'package:flutter/material.dart';
import 'package:daisy/screens/comic_browser_screen.dart';
import 'components/flutter_search_bar.dart' as sb;

import 'comic_bookshelf_screen.dart';
import 'comic_search_screen.dart';

class ComicsScreen extends StatefulWidget {
  const ComicsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ComicsScreenState();
}

class _ComicsScreenState extends State<ComicsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _pageIndex = 1;
  late final _controller = PageController(initialPage: _pageIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navIndexModified(int index) {
    setState(() {
      _pageIndex = index;
    });
  }

  void _navButtonPressed(int index) {
    setState(() {
      _pageIndex = index;
      _controller.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: _searchBar.build(context),
      body: PageView(
        controller: _controller,
        onPageChanged: _navIndexModified,
        children: _navPages.map((e) => e.screen).toList(),
      ),
    );
  }

  AppBar _buildDefaultAppBar(BuildContext context) {
    final iconColor =
        Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.black;
    List<Widget> actions = [];
    actions.add(MaterialButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => const AboutScreen(),
          ),
        );
      },
      minWidth: 50,
      child: Column(children: [
        Expanded(child: Container()),
        VersionBadged(
          child: Icon(Icons.settings, color: iconColor.withAlpha(190)),
        ),
        Text(
          "设置",
          style: TextStyle(
            fontSize: 10,
            color: iconColor.withAlpha(190),
          ),
        ),
        Expanded(child: Container()),
      ]),
    ));
    for (var i = 0; i < _navPages.length; i++) {
      var index = i;
      final color = _pageIndex == i ? iconColor : iconColor.withAlpha(190);
      final background =
          _pageIndex == i ? iconColor.withAlpha(20) : Colors.transparent;
      actions.add(Container(
        color: background,
        child: MaterialButton(
          onPressed: () {
            _navButtonPressed(index);
          },
          minWidth: 50,
          child: Column(children: [
            Expanded(child: Container()),
            Icon(_navPages[i].icon, color: color),
            Text(
              _navPages[i].title,
              style: TextStyle(
                fontSize: 10,
                color: color,
              ),
            ),
            Expanded(child: Container()),
          ]),
        ),
      ));
    }
    actions.add(MaterialButton(
      onPressed: () {
        _searchBar.beginSearch(context);
      },
      minWidth: 50,
      child: Column(children: [
        Expanded(child: Container()),
        Icon(Icons.search, color: iconColor),
        Text(
          "搜索",
          style: TextStyle(
            fontSize: 10,
            color: iconColor,
          ),
        ),
        Expanded(child: Container()),
      ]),
    ));
    return AppBar(
      leading: IconButton(
        onPressed: () {
          appScreenEvent.broadcast(jumpToNovel);
        },
        icon: Icon(Icons.cameraswitch_sharp, color: iconColor.withAlpha(190)),
      ),
      title: Transform.translate(
        offset: const Offset(-20, 0),
        child: const Text("漫画"),
      ),
      actions: actions,
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
        Navigator.push(
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

class NavPage {
  final Widget screen;
  final String title;
  final IconData icon;

  const NavPage({
    required this.screen,
    required this.title,
    required this.icon,
  });
}

const _navPages = [
  NavPage(
    screen: ComicBookshelfScreen(),
    title: "书架",
    icon: Icons.history_edu,
  ),
  NavPage(screen: ComicBrowserScreen(), title: "浏览", icon: Icons.blur_linear),
];
