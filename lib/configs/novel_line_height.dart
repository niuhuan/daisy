import 'package:daisy/commons.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';

const _defaultValue = 1.15;
const _propertyKey = "novel_line_height";

late double novelLineHeight;

Future initNovelLineHeight() async {
  var v = await native.loadProperty(k: _propertyKey);
  if (v == "") {
    v = _defaultValue.toString();
  }
  novelLineHeight = double.parse(v);
}

Future modifyNovelLineHeight(BuildContext context) async {
  final input = await displayTextInputDialog(context,
      title: "文字大小", src: novelLineHeight.toString(), hint: "输入0.1-10之间的数字");
  if (input != null && RegExp("^\\d{1,3}(\\.\\d{1,3})?\$").hasMatch(input)) {
    final v = double.parse(input);
    if (v >= 0.1 && v <= 10) {
      await native.saveProperty(k: _propertyKey, v: v.toString());
      novelLineHeight = v;
    }
  }
}
