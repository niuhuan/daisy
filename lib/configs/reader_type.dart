import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';

import '../commons.dart';

enum ReaderType {
  webtoon,
  gallery,
  webToonFreeZoom,
  towPageGallery,
}

const _propertyName = "readerType";
late ReaderType _readerType;

Future initReaderType() async {
  _readerType = _fromString(await native.loadProperty(k: _propertyName));
}

ReaderType _fromString(String valueForm) {
  for (var value in ReaderType.values) {
    if (value.toString() == valueForm) {
      return value;
    }
  }
  return ReaderType.values.first;
}

ReaderType get currentReaderType => _readerType;

String readerTypeName(ReaderType type, BuildContext context) {
  switch (type) {
    case ReaderType.webtoon:
      return "WebToon";
    case ReaderType.gallery:
      return "相册";
    case ReaderType.webToonFreeZoom:
      return "自由放大滚动 无法翻页";
    case ReaderType.towPageGallery:
      return "双页相册";
  }
}

Future chooseReaderType(BuildContext context) async {
  final Map<String, ReaderType> map = {};
  for (var element in ReaderType.values) {
    map[readerTypeName(element, context)] = element;
  }
  final newReaderType = await chooseMapDialog(
    context,
    title: "请选择阅读器类型",
    values: map,
  );
  if (newReaderType != null) {
    await native.saveProperty(k: _propertyName, v: "$newReaderType");
    _readerType = newReaderType;
  }
}
