import 'package:daisy/screens/comics_screen.dart';
import 'package:daisy/screens/novels_screen.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';

import '../configs/last_module.dart';

final Event<AppScreenEventArgs> appScreenEvent = Event<AppScreenEventArgs>();

class AppScreenEventArgs extends EventArgs {
  final int jumpTo;

  AppScreenEventArgs(this.jumpTo);
}

AppScreenEventArgs jumpToComic = AppScreenEventArgs(0);
AppScreenEventArgs jumpToNovel = AppScreenEventArgs(1);

class AppScreen extends StatefulWidget {
  final int initModule;

  const AppScreen(this.initModule, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  late final _controller = PageController(initialPage: widget.initModule);

  @override
  void initState() {
    appScreenEvent.subscribe(_onEvent);
    super.initState();
  }

  @override
  void dispose() {
    appScreenEvent.unsubscribe(_onEvent);
    _controller.dispose();
    super.dispose();
  }

  void _onEvent(AppScreenEventArgs? args) {
    if (args != null) {
      _controller.jumpToPage(args.jumpTo);
      setLastModule(args.jumpTo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      children: const [
        ComicsScreen(),
        NovelsScreen(),
      ],
    );
  }
}
