import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';

import '../commons.dart';

enum NovelReaderType {
  picMove,
  move,
  html,
}

const _propertyName = "NovelReaderType";
late NovelReaderType _NovelReaderType;

Future initNovelReaderType() async {
  _NovelReaderType = _fromString(await native.loadProperty(k: _propertyName));
}

NovelReaderType _fromString(String valueForm) {
  for (var value in NovelReaderType.values) {
    if (value.toString() == valueForm) {
      return value;
    }
  }
  return NovelReaderType.values.first;
}

NovelReaderType get currentNovelReaderType => _NovelReaderType;

String novelReaderTypeName(NovelReaderType direction, BuildContext context) {
  switch (direction) {
    case NovelReaderType.picMove:
      return "混合";
    case NovelReaderType.move:
      return "平移";
    case NovelReaderType.html:
      return "网页";
  }
}

Future chooseNovelReaderType(BuildContext context) async {
  final Map<String, NovelReaderType> map = {};
  for (var element in NovelReaderType.values) {
    map[novelReaderTypeName(element, context)] = element;
  }
  final newNovelReaderType = await chooseMapDialog(
    context,
    title: "请选择小说阅读器",
    values: map,
  );
  if (newNovelReaderType != null) {
    await native.saveProperty(k: _propertyName, v: "$newNovelReaderType");
    _NovelReaderType = newNovelReaderType;
  }
}

Widget novelReaderTypeSetting(BuildContext context) {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        onTap: () async {
          await chooseNovelReaderType(context);
          setState(() {});
        },
        title: const Text("小说阅读器类型"),
        subtitle: Text(novelReaderTypeName(_NovelReaderType, context)),
      );
    },
  );
}
