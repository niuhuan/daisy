import 'dart:async';
import 'dart:io';

import 'package:daisy/screens/comics_screen.dart';
import 'package:daisy/screens/novels_screen.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../commons.dart';
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

  const AppScreen(this.initModule, {super.key});

  @override
  State<StatefulWidget> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  late final _controller = PageController(initialPage: widget.initModule);
  late final StreamSubscription<Uri?> _ls;

  @override
  void initState() {
    appScreenEvent.subscribe(_onEvent);
    _ls = linkSubscript(context);
    if (Platform.isAndroid || Platform.isIOS) {
      firstLink();
    }
    super.initState();
  }

  firstLink() async {
    try {
      var initUrl = (await appLinks.getInitialLink())?.toString();
      processLink(initUrl, context);
      // Use the uri and warn the user, if it is not correct,
      // but keep in mind it could be `null`.
    } on FormatException {
      // Handle exception by warning the user their action did not succeed
      // return?
    }
  }

  @override
  void dispose() {
    _ls.cancel();
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
