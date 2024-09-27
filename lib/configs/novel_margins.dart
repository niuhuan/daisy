import 'package:flutter/material.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;

const _defaultTopMargin = 40.0;
const _defaultBottomMargin = 30.0;
const _defaultLeftMargin = 20.0;
const _defaultRightMargin = 20.0;

late double novelTopMargin;
late double novelBottomMargin;
late double novelLeftMargin;
late double novelRightMargin;

Future initNovelMargins() async {
  var v = await native.loadProperty(k: "novel_top_margin");
  if (v == "") {
    novelTopMargin = _defaultTopMargin;
  } else {
    novelTopMargin = double.parse(v);
  }
  v = await native.loadProperty(k: "novel_bottom_margin");
  if (v == "") {
    novelBottomMargin = _defaultBottomMargin;
  } else {
    novelBottomMargin = double.parse(v);
  }
  v = await native.loadProperty(k: "novel_left_margin");
  if (v == "") {
    novelLeftMargin = _defaultLeftMargin;
  } else {
    novelLeftMargin = double.parse(v);
  }
  v = await native.loadProperty(k: "novel_right_margin");
  if (v == "") {
    novelRightMargin = _defaultRightMargin;
  } else {
    novelRightMargin = double.parse(v);
  }
}

Future novelMarginsSettingsPop(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (c) => NovelMarginsSettings(
        novelTopMargin,
        novelBottomMargin,
        novelLeftMargin,
        novelRightMargin,
      ),
    ),
  );
}

class NovelMarginsSettings extends StatefulWidget {
  final double initTopMargin;
  final double initBottomMargin;
  final double initLeftMargin;
  final double initRightMargin;

  const NovelMarginsSettings(this.initTopMargin, this.initBottomMargin,
      this.initLeftMargin, this.initRightMargin,
      {super.key});

  @override
  State<StatefulWidget> createState() => _NovelMarginsSettingsState();
}

class _NovelMarginsSettingsState extends State<NovelMarginsSettings> {
  late double topMargin;
  late double bottomMargin;
  late double leftMargin;
  late double rightMargin;

  @override
  void initState() {
    topMargin = widget.initTopMargin;
    bottomMargin = widget.initBottomMargin;
    leftMargin = widget.initLeftMargin;
    rightMargin = widget.initRightMargin;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("小说边距设置"),
      ),
      body: ListView(children: [
        ListTile(
          title: const Text("上边距"),
          subtitle: Slider(
            value: topMargin,
            min: 0,
            max: 200,
            divisions: 200,
            label: topMargin.toString(),
            onChanged: (v) {
              setState(() {
                topMargin = v;
              });
            },
          ),
        ),
        ListTile(
          title: const Text("下边距"),
          subtitle: Slider(
            value: bottomMargin,
            min: 0,
            max: 200,
            divisions: 200,
            label: bottomMargin.toString(),
            onChanged: (v) {
              setState(() {
                bottomMargin = v;
              });
            },
          ),
        ),
        ListTile(
          title: const Text("左边距"),
          subtitle: Slider(
            value: leftMargin,
            min: 0,
            max: 200,
            divisions: 200,
            label: leftMargin.toString(),
            onChanged: (v) {
              setState(() {
                leftMargin = v;
              });
            },
          ),
        ),
        ListTile(
          title: const Text("右边距"),
          subtitle: Slider(
            value: rightMargin,
            min: 0,
            max: 200,
            divisions: 200,
            label: rightMargin.toString(),
            onChanged: (v) {
              setState(() {
                rightMargin = v;
              });
            },
          ),
        ),
        ListTile(
          title: const Text("重置"),
          onTap: () {
            setState(() {
              topMargin = _defaultTopMargin;
              bottomMargin = _defaultBottomMargin;
              leftMargin = _defaultLeftMargin;
              rightMargin = _defaultRightMargin;
            });
          },
        ),
        ListTile(
          title: const Text("保存"),
          onTap: () async {
            novelTopMargin = topMargin;
            novelBottomMargin = bottomMargin;
            novelLeftMargin = leftMargin;
            novelRightMargin = rightMargin;
            await native.saveProperty(
              k: "novel_top_margin",
              v: topMargin.toString(),
            );
            await native.saveProperty(
              k: "novel_bottom_margin",
              v: bottomMargin.toString(),
            );
            await native.saveProperty(
              k: "novel_left_margin",
              v: leftMargin.toString(),
            );
            await native.saveProperty(
              k: "novel_right_margin",
              v: rightMargin.toString(),
            );
            Navigator.of(context).pop();
          },
        ),
      ]),
    );
  }
}
