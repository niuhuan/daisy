import 'dart:io';

import 'package:flutter/services.dart';
import 'package:daisy/ffi.dart';
import 'package:url_launcher/url_launcher.dart';

const cross = Cross._();

class Cross {
  const Cross._();

  static const _channel = MethodChannel("cross");

  Future<String> root() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await _channel.invokeMethod("root");
    }
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return await native.desktopRoot();
    }
    throw "没有适配的平台";
  }

  Future saveImageToGallery(String path) async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await _channel.invokeMethod("saveImageToGallery", path);
    }
    throw "没有适配的平台";
  }
}

/// 打开web页面
Future<dynamic> openUrl(String url) async {
  if (await canLaunch(url)) {
    await launch(
      url,
      forceSafariVC: false,
    );
  }
}
