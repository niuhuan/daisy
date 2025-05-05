import 'package:daisy/configs/android_display_mode.dart';
import 'package:daisy/configs/android_version.dart';
import 'package:daisy/configs/login.dart';
import 'package:daisy/configs/novel_background_color.dart';
import 'package:daisy/configs/novel_font_color.dart';
import 'package:daisy/configs/novel_line_height.dart';
import 'package:daisy/configs/novel_margins.dart';
import 'package:daisy/configs/novel_reader_type.dart';
import 'package:daisy/configs/reader_controller_type.dart';
import 'package:daisy/configs/reader_direction.dart';
import 'package:daisy/configs/reader_slider_position.dart';
import 'package:daisy/configs/reader_type.dart';
import 'package:daisy/configs/versions.dart';
import 'package:daisy/screens/app_screen.dart';
import 'package:flutter/material.dart';
import 'package:daisy/cross.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;

import '../configs/app_orientation.dart';
import '../configs/auto_clean.dart';
import '../configs/last_module.dart';
import '../configs/novel_font_size.dart';
import '../configs/themes.dart';
import '../configs/two_page_gallery_direction.dart';

class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<StatefulWidget> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  Future _init() async {
    await native.init(root: await cross.root());
    await initAppOrientation();
    await initAndroidVersion();
    await initAndroidDisplayMode();
    await initAutoClean();
    await initReaderControllerType();
    await initReaderDirection();
    await initReaderSliderPosition();
    await initReaderType();
    await initTwoPageDirection();
    await initNovelReaderType();
    await initNovelFontSize();
    await initNovelLineHeight();
    await initNovelMargins();
    await initNovelFontColor();
    await initNovelBackgroundColor();
    await initVersion();
    await initLastModule();
    await initTheme();
    await initLogin();
    autoCheckNewVersion();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (BuildContext context) => AppScreen(lastModule),
      ),
    );
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            var width = 1081;
            var height = 1536;
            var min = constraints.maxWidth > constraints.maxHeight
                ? constraints.maxHeight
                : constraints.maxWidth;
            var newHeight = min;
            var newWidth = min * (width / height);
            return Center(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.95, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  "lib/assets/startup.png",
                  width: newWidth,
                  height: newHeight,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
