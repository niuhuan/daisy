import 'package:daisy/commons.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';

const _defaultValue = 1.15;
const _propertyKey = "novel_font_size";

late double novelFontSize;

Future initNovelFontSize() async {
  var v = await native.loadProperty(k: _propertyKey);
  if (v == "") {
    v = _defaultValue.toString();
  }
  novelFontSize = double.parse(v);
}

Future modifyNovelFontSize(BuildContext context) async {
  final input = await displayTextInputDialog(context,
      title: "文字大小", src: novelFontSize.toString(), hint: "输入0.1-10之间的数字");
  if (input != null && RegExp("^\\d{1,3}(\\.\\d{1,3})?\$").hasMatch(input)) {
    final v = double.parse(input);
    if (v >= 0.1 && v <= 10) {
      await native.saveProperty(k: _propertyKey, v: v.toString());
      novelFontSize = v;
    }
  }
}
