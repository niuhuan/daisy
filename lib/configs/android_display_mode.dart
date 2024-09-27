/// 显示模式, 仅安卓有效
library;

import 'dart:io';

import 'package:daisy/cross.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';
import '../commons.dart';
import 'android_version.dart';

const _propertyName = "androidDisplayMode";
List<String> _modes = [];
String _androidDisplayMode = "";

Future initAndroidDisplayMode() async {
  if (Platform.isAndroid) {
    _androidDisplayMode = await native.loadProperty(k: _propertyName);
    _modes = await cross.loadAndroidModes();
    await _changeMode();
  }
}

Future _changeMode() async {
  await cross.setAndroidMode(_androidDisplayMode);
}

Future<void> _chooseAndroidDisplayMode(BuildContext context) async {
  if (Platform.isAndroid) {
    List<String> list = [""];
    list.addAll(_modes);
    String? result = await chooseListDialog<String>(
      context,
      title: "安卓屏幕刷新率",
      values: list,
    );
    if (result != null) {
      await native.saveProperty(k: _propertyName, v: result);
      _androidDisplayMode = result;
      await _changeMode();
    }
  }
}

Widget androidDisplayModeSetting() {
  if (Platform.isAndroid && androidVersion >= 23) {
    return StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        return ListTile(
          title: const Text("屏幕刷新率(安卓)"),
          subtitle: Text(_androidDisplayMode),
          onTap: () async {
            await _chooseAndroidDisplayMode(context);
            setState(() {});
          },
        );
      },
    );
  }
  return Container();
}
