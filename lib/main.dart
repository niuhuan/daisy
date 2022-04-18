import 'package:daisy/screens/components/mouse_and_touch_scroll_behavior.dart';
import 'package:daisy/themes.dart';
import 'package:flutter/material.dart';
import 'commons.dart';
import 'screens/init_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
