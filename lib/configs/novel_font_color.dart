import 'package:daisy/commons.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';

const _propertyKeyLight = "novel_font_color_light";
const _propertyKeyDark = "novel_font_color_dark";

const _defaultValueLight = 0xFF000000;
const _defaultValueDark = 0xFFFFFFFF;

late int _novelFontColorLight;
late int _novelFontColorDark;

getNovelFontColor(BuildContext context) =>
    Color(Theme
        .of(context)
        .brightness == Brightness.dark
        ? _novelFontColorDark
        : _novelFontColorLight);

Future initNovelFontColor() async {
  await _initNovelFontColorLight();
  await _initNovelFontColorDark();
}

Future _initNovelFontColorLight() async {
  var v = await native.loadProperty(k: _propertyKeyLight);
  if (v == "") {
    v = _defaultValueLight.toString();
  }
  _novelFontColorLight = int.parse(v);
}

Future _initNovelFontColorDark() async {
  var v = await native.loadProperty(k: _propertyKeyDark);
  if (v == "") {
    v = _defaultValueDark.toString();
  }
  _novelFontColorDark = int.parse(v);
}

Future modifyNovelFontColor(BuildContext context) async {
  bool dark = Theme
      .of(context)
      .brightness == Brightness.dark;

  Color? color = await chooseColor(
    context,
    title: "选择字体颜色${dark ? " (黑暗模式)" :""}",
    src: Color(dark ? _novelFontColorDark : _novelFontColorLight),
  );
  if (color != null) {
    print("COLOR : $color");
    if (dark) {
      await native.saveProperty(
        k: _propertyKeyDark,
        v: color.value.toString(),
      );
      _novelFontColorDark = color.value;
    } else {
      await native.saveProperty(
        k: _propertyKeyLight,
        v: color.value.toString(),
      );
      _novelFontColorLight = color.value;
    }
  }
}
