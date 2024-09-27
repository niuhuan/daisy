import 'package:daisy/screens/comic_downloads_screen.dart';
import 'package:daisy/screens/comic_history_screen.dart';
import 'package:daisy/screens/comic_subscribed_screen.dart';
import 'package:flutter/material.dart';


class ComicBookshelfScreen extends StatefulWidget {
  const ComicBookshelfScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ComicBookshelfScreenState();
}

class _ComicBookshelfScreenState extends State<ComicBookshelfScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ThemeData theme = Theme.of(context);
    final AppBarTheme appBarTheme = AppBarTheme.of(context);
    return DefaultTabController(
      length: _navPages.length,
      child: Scaffold(
        appBar: PreferredSizeContainer(
          color: appBarTheme.backgroundColor,
          child: TabBar(
            indicatorColor: theme.dividerColor,
            tabs: _navPages
                .map((e) => Tab(
                      child: Text.rich(TextSpan(children: [
                        WidgetSpan(
                          child: Icon(e.icon),
                          alignment: PlaceholderAlignment.middle,
                        ),
                        const TextSpan(text: " "),
                        TextSpan(text: e.title)
                      ])),
                    ))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: _navPages.map((e) => e.screen).toList(),
        ),
      ),
    );
  }
}

class PreferredSizeContainer extends StatelessWidget
    implements PreferredSizeWidget {
  final PreferredSizeWidget child;
  final Color? color;

  const PreferredSizeContainer({
    required this.child,
    this.color,
    super.key,
  });

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: child,
    );
  }
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
    screen: ComicHistoryScreen(),
    title: "历史",
    icon: Icons.history,
  ),
  NavPage(
    screen: ComicSubscribedScreen(),
    title: "订阅",
    icon: Icons.subscriptions,
  ),
  NavPage(
    screen: ComicDownloadsScreen(),
    title: "下载",
    icon: Icons.download,
  ),
];
