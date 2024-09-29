import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:daisy/screens/comic_detail_redirect_screen.dart';
import 'package:daisy/screens/comic_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_links/app_links.dart';
import 'cross.dart';

final appLinks = AppLinks();

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class ObjType {
  static const novel = 1;
  static const comic = 4;
}

class Entity<T> {
  final String title;
  final T value;

  Entity(this.title, this.value);
}

/// 创建一个单选对话框, 用户取消选择返回null, 否则返回所选内容
Future<Entity<T>?> chooseEntity<T>(
  BuildContext context,
  String title,
  List<Entity<T>> items, {
  String? tips,
}) async {
  return showDialog<Entity<T>>(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text(title),
        children: [
          ...items.map((e) => SimpleDialogOption(
                onPressed: () {
                  Navigator.of(context).pop(e);
                },
                child: Text(e.title),
              )),
          ...tips != null
              ? [
                  Container(
                    padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                    child: Text(tips),
                  ),
                ]
              : [],
        ],
      );
    },
  );
}

Future<T?> chooseMapDialog<T>(
  BuildContext buildContext, {
  required String title,
  required Map<String, T> values,
}) async {
  return await showDialog<T>(
    context: buildContext,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text(title),
        children: values.entries
            .map((e) => SimpleDialogOption(
                  child: Text(e.key),
                  onPressed: () {
                    Navigator.of(context).pop(e.value);
                  },
                ))
            .toList(),
      );
    },
  );
}

/// 显示一个toast
void defaultToast(BuildContext context, String title) {
  showToast(
    title,
    context: context,
    position: StyledToastPosition.center,
    animation: StyledToastAnimation.scale,
    reverseAnimation: StyledToastAnimation.fade,
    duration: const Duration(seconds: 4),
    animDuration: const Duration(seconds: 1),
    curve: Curves.elasticOut,
    reverseCurve: Curves.linear,
  );
}

Future<T?> chooseListDialog<T>(BuildContext context,
    {required List<T> values, required String title, String? tips}) async {
  return showDialog<T>(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text(title),
        children: [
          ...values.map((e) => SimpleDialogOption(
                onPressed: () {
                  Navigator.of(context).pop(e);
                },
                child: Text('$e'),
              )),
          ...tips != null
              ? [
                  Container(
                    padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                    child: Text(tips),
                  ),
                ]
              : [],
        ],
      );
    },
  );
}

Future saveImageFileToGallery(BuildContext context, String path) async {
  if (Platform.isAndroid) {
    if (!(await Permission.storage.request()).isGranted) {
      return;
    }
  }
  if (Platform.isIOS || Platform.isAndroid) {
    await cross.saveImageToGallery(path);
    defaultToast(context, "保存成功");
    return;
  }
  defaultToast(context, "暂不支持该平台");
}

/// 格式化时间 2012-34-56 12:34:56
String formatTimeToDateTime(int time) {
  try {
    var c = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    return "${add0(c.year, 4)}-${add0(c.month, 2)}-${add0(c.day, 2)} ${add0(c.hour, 2)}:${add0(c.minute, 2)}";
  } catch (e) {
    return "-";
  }
}

/// 将字符串前面加0直至满足len位
String add0(int num, int len) {
  var rsp = "$num";
  while (rsp.length < len) {
    rsp = "0$rsp";
  }
  return rsp;
}

var _controller =
    TextEditingController.fromValue(const TextEditingValue(text: ''));

Future<String?> displayTextInputDialog(BuildContext context,
    {String? title,
    String src = "",
    String? hint,
    String? desc,
    bool isPasswd = false}) {
  _controller.text = src;
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: title == null ? null : Text(title),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(hintText: hint),
                obscureText: isPasswd,
                obscuringCharacter: '\u2022',
              ),
              ...(desc == null
                  ? []
                  : [
                      Container(
                        padding: const EdgeInsets.only(top: 20, bottom: 10),
                        child: Text(
                          desc,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(.5)),
                        ),
                      )
                    ]),
            ],
          ),
        ),
        actions: <Widget>[
          MaterialButton(
            child: const Text('取消'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          MaterialButton(
            child: const Text('确认'),
            onPressed: () {
              Navigator.of(context).pop(_controller.text);
            },
          ),
        ],
      );
    },
  );
}

Future chooseColor(
  BuildContext context, {
  String? title,
  Color? src,
}) async {
  Color color = src ?? Colors.black;
  bool? hasOk = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title ?? 'Pick a color!'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (BuildContext context,
                void Function(void Function()) setState) {
              return ColorPicker(
                pickerColor: color,
                onColorChanged: (c) {
                  setState(() {
                    color = c;
                  });
                },
              );
            },
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('确认'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );
  return hasOk != null ? color : null;
}

Future<bool> confirmDialog(
  BuildContext context,
  String title,
  String content,
) async {
  return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(title),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[Text(content)],
                  ),
                ),
                actions: <Widget>[
                  MaterialButton(
                    child: const Text('取消'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  MaterialButton(
                    child: const Text('确定'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              )) ??
      false;
}

String generateMD5(String data) {
  Uint8List content = (const Utf8Encoder()).convert(data);
  Digest digest = md5.convert(content);
  return digest.toString();
}

processLink(String? uri, BuildContext context) {
  print("processLink : $uri");
  if (uri == null) return;
  if (RegExp(r"^dmzj://comic/([0-9A-z]+)/$").allMatches(uri).isNotEmpty) {
    String comicId =
        RegExp(r"^dmzj://comic/([0-9A-z]+)/$").allMatches(uri).first.group(1)!;
    if (RegExp(r"^\d+$").hasMatch(comicId)) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) {
          return ComicDetailScreen(comicId: int.parse(comicId));
        },
      ));
    } else {
      print("ComicDetailRedirectScreen : $comicId");
      Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) {
          return ComicDetailRedirectScreen(comicIdString: comicId);
        },
      ));
    }
    return;
  } else if (RegExp(r"^https?://m\.idmzj\.com/info/(\w+)\.html$")
      .allMatches(uri)
      .isNotEmpty) {
    String comicId = RegExp(r"^https?://m\.idmzj\.com/info/(\w+)\.html$")
        .allMatches(uri)
        .first
        .group(1)!;
    if (RegExp(r"^\d+$").hasMatch(comicId)) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) {
          return ComicDetailScreen(comicId: int.parse(comicId));
        },
      ));
    } else {
      print("ComicDetailRedirectScreen : $comicId");
      Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) {
          return ComicDetailRedirectScreen(comicIdString: comicId);
        },
      ));
    }
    return;
  }
}

StreamSubscription<Uri?> linkSubscript(BuildContext context) {
  return appLinks.uriLinkStream.listen((Uri? uri) {
    processLink(uri.toString(), context);
  });
}
