import 'package:daisy/commons.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';

const _defaultValue = 1.5;
const _propertyKey = "novel_paragraph_spacing";

late double novelParagraphSpacing;

Future initNovelParagraphSpacing() async {
  var v = await native.loadProperty(k: _propertyKey);
  if (v == "") {
    v = _defaultValue.toString();
  }
  novelParagraphSpacing = double.parse(v);
}

Future modifyNovelParagraphSpacing(BuildContext context) async {
  final input = await displayTextInputDialog(context,
      title: "段落间距", src: novelParagraphSpacing.toString(), hint: "输入0.1-10之间的数字");
  if (input != null && RegExp("^\\d{1,3}(\\.\\d{1,3})?\$").hasMatch(input)) {
    final v = double.parse(input);
    if (v >= 0.1 && v <= 10) {
      await native.saveProperty(k: _propertyKey, v: v.toString());
      novelParagraphSpacing = v;
    }
  }
} 