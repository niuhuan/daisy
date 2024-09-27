import 'package:flutter/material.dart';
import '../commons.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
const _propertyName = "auto_clean";
late String autoClean;

Map<String, String> _nameMap(BuildContext context) => {
      (1000 * 3600 * 24 * 7).toString(): "一周",
      (1000 * 3600 * 24 * 30).toString(): "一月",
      (1000 * 3600 * 24 * 30 * 12).toString(): "一年",
    };

Future initAutoClean() async {
  autoClean = await native.loadProperty(k: _propertyName);
  if (autoClean == "") {
    autoClean = "${(1000 * 3600 * 24 * 7)}";
  }
  await native.autoClean(time: int.parse(autoClean));
}

String autoCleanName(BuildContext context) {
  return _nameMap(context)[autoClean] ?? "-";
}

Future chooseAutoClean(BuildContext context) async {
  String? choose = await chooseMapDialog(context,
      title: "自动清理",
      values: _nameMap(context).map((key, value) => MapEntry(value, key)));
  if (choose != null) {
    await native.saveProperty(k: _propertyName, v: choose);
    autoClean = choose;
  }
}

Widget autoCleanSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: const Text("自动清理"),
        subtitle: Text(autoCleanName(context)),
        onTap: () async {
          await chooseAutoClean(context);
          setState(() {});
        },
      );
    },
  );
}
