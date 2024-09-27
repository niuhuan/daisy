import 'package:daisy/screens/components/mouse_and_touch_scroll_behavior.dart';
import 'package:daisy/configs/themes.dart';
import 'package:daisy/src/rust/frb_generated.dart';
import 'package:flutter/material.dart';
import 'commons.dart';
import 'screens/init_screen.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    themeEvent.subscribe(_setState);
    super.initState();
  }

  @override
  void dispose() {
    themeEvent.unsubscribe(_setState);
    super.dispose();
  }

  _setState(_) => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: mouseAndTouchScrollBehavior,
      navigatorObservers: [
        routeObserver,
      ],
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const InitScreen(),
    );
  }
}
