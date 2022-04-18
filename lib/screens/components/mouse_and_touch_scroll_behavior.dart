import 'dart:ui';
import 'package:flutter/material.dart';

final mouseAndTouchScrollBehavior = MouseAndTouchScrollBehavior();

class MouseAndTouchScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}