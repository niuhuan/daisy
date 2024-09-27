import 'package:daisy/commons.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';

const _propertyKeyLight = "novel_background_color_light";
const _propertyKeyDark = "novel_background_color_dark";

const _defaultValueLight = 0xFFFFFFFF;
const _defaultValueDark = 0xFF000000;

late int _novelBackgroundColorLight;
late int _novelBackgroundColorDark;

getNovelBackgroundColor(BuildContext context) =>
    Color(Theme.of(context).brightness == Brightness.dark
        ? _novelBackgroundColorDark
        : _novelBackgroundColorLight);

Future initNovelBackgroundColor() async {
  await _initNovelBackgroundColorLight();
  await _initNovelBackgroundColorDark();
}

Future _initNovelBackgroundColorLight() async {
  var v = await native.loadProperty(k: _propertyKeyLight);
  if (v == "") {
    v = _defaultValueLight.toString();
  }
  _novelBackgroundColorLight = int.parse(v);
}

Future _initNovelBackgroundColorDark() async {
  var v = await native.loadProperty(k: _propertyKeyDark);
  if (v == "") {
    v = _defaultValueDark.toString();
  }
  _novelBackgroundColorDark = int.parse(v);
}

Future modifyNovelBackgroundColor(BuildContext context) async {
  bool dark = Theme.of(context).brightness == Brightness.dark;
  Color? color = await chooseColor(
    context,
    title: "选择背景颜色${dark ? " (黑暗模式)" : ""}",
    src: Color(dark ? _novelBackgroundColorDark : _novelBackgroundColorLight),
  );
  if (color != null) {
    print("COLOR : $color");
    if (dark) {
      await native.saveProperty(
        k: _propertyKeyDark,
        v: color.value.toString(),
      );
      _novelBackgroundColorDark = color.value;
    } else {
      await native.saveProperty(
        k: _propertyKeyLight,
        v: color.value.toString(),
      );
      _novelBackgroundColorLight = color.value;
    }
  }
}
