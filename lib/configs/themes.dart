import 'package:daisy/commons.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final _pink = ThemeData.light().copyWith(
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
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 20,
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
  dividerTheme: DividerThemeData(
    color: Colors.grey.shade700,
  ),
);

final _dark = ThemeData.dark().copyWith(
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
  dividerTheme: DividerThemeData(
    color: Colors.grey.shade700,
  ),
  listTileTheme: ListTileThemeData(
    tileColor: Colors.grey.shade800,
    selectedColor: Colors.grey.shade900,
    iconColor: Colors.white,
    textColor: Colors.white,
  ),
);

const _propertyNameLight = "theme.light";
const _propertyNameDark = "theme.dark";
String _themeLight = "", _themeDark = "";

Future initTheme() async {
  _themeLight = await native.loadProperty(k: _propertyNameLight);
  if (_themeLight == "") {
    _themeLight = "pink";
  }
  _themeDark = await native.loadProperty(k: _propertyNameDark);
  if (_themeDark == "") {
    _themeDark = "dark";
  }
  themeEvent.broadcast();
}

ThemeData? get lightTheme => _themeByCode(_themeLight);

ThemeData? get darkTheme => _themeByCode(_themeDark);

ThemeData? _themeByCode(String code) {
  if ("pink" == code) return _pink;
  if ("dark" == code) return _dark;
  return null;
}

Event themeEvent = Event();

Widget lightThemeSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: const Text("主题"),
        subtitle: Text(_themeLight),
        onTap: () async {
          String? choose = await chooseMapDialog(
            context,
            title: "选择主题",
            values: {
              "origin": "origin",
              "pink": "pink",
              "dark": "dark",
            },
          );
          if (choose != null) {
            await native.saveProperty(k: _propertyNameLight, v: choose);
            _themeLight = choose;
            setState(() {});
            themeEvent.broadcast();
          }
        },
      );
    },
  );
}

Widget darkThemeSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: const Text("主题 (黑暗模式) (如果设备支持)"),
        subtitle: Text(_themeDark),
        onTap: () async {
          String? choose = await chooseMapDialog(
            context,
            title: "选择主题 (黑暗模式)",
            values: {
              "origin": "origin",
              "pink": "pink",
              "dark": "dark",
            },
          );
          if (choose != null) {
            await native.saveProperty(k: _propertyNameDark, v: choose);
            _themeDark = choose;
            setState(() {});
            themeEvent.broadcast();
          }
        },
      );
    },
  );
}
