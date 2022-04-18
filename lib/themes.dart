import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final lightTheme = ThemeData.light().copyWith(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    secondary: Colors.pink.shade200,
  ),
  appBarTheme: AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle.light,
    color: Colors.pink.shade200,
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    selectedItemColor: Colors.pink[300],
    unselectedItemColor: Colors.grey[500],
  ),
  dividerColor: Colors.grey.shade200,
  primaryColor: Colors.pink.shade200,
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Colors.pink.shade200,
    selectionColor: Colors.pink.shade300.withAlpha(150),
    selectionHandleColor: Colors.pink.shade300.withAlpha(200),
  ),
  inputDecorationTheme: InputDecorationTheme(
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.pink.shade200),
    ),
  ),
);

final darkTheme = ThemeData.dark().copyWith(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.light(
    secondary: Colors.pink.shade200,
  ),
  appBarTheme: const AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle.light,
    color: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
    iconTheme: IconThemeData(
      color: Colors.white,
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.grey.shade300,
    backgroundColor: Colors.grey.shade900,
  ),
  primaryColor: Colors.pink.shade200,
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Colors.pink.shade200,
    selectionColor: Colors.pink.shade300.withAlpha(150),
    selectionHandleColor: Colors.pink.shade300.withAlpha(200),
  ),
  inputDecorationTheme: InputDecorationTheme(
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.pink.shade200),
    ),
  ),
);
