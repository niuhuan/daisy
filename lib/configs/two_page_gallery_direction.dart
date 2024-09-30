import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';

import '../commons.dart';

enum TwoPageDirection {
  leftToRight,
  rightToLeft,
}

const _propertyName = "twoPageDirection";
late TwoPageDirection _twoPageDirection;

Future initTwoPageDirection() async {
  _twoPageDirection = _fromString(await native.loadProperty(k: _propertyName));
}

TwoPageDirection _fromString(String valueForm) {
  for (var value in TwoPageDirection.values) {
    if (value.toString() == valueForm) {
      return value;
    }
  }
  return TwoPageDirection.values.first;
}

TwoPageDirection get currentTwoPageDirection => _twoPageDirection;

String twoPageDirectionName(TwoPageDirection direction, BuildContext context) {
  switch (direction) {
    case TwoPageDirection.leftToRight:
      return "从左到右";
    case TwoPageDirection.rightToLeft:
      return "从右到左";
  }
}

Future chooseTwoPageDirection(BuildContext context) async {
  final Map<String, TwoPageDirection> map = {};
  for (var element in TwoPageDirection.values) {
    map[twoPageDirectionName(element, context)] = element;
  }
  final newTwoPageDirection = await chooseMapDialog(
    context,
    title: "请选择阅读器方向",
    values: map,
  );
  if (newTwoPageDirection != null) {
    await native.saveProperty(k: _propertyName, v: "$newTwoPageDirection");
    _twoPageDirection = newTwoPageDirection;
  }
}

Widget twoGalleryDirectionSetting(BuildContext context) {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        onTap: () async {
          await chooseTwoPageDirection(context);
          setState(() {});
        },
        title: const Text("小说阅读器类型"),
        subtitle: Text(twoPageDirectionName(_twoPageDirection, context)),
      );
    },
  );
}
