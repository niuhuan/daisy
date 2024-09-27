import 'dart:io';

import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../commons.dart';
import '../file_photo_view_screen.dart';

Widget buildError(double? width, double? height) {
  return Image(
    image: const AssetImage('lib/assets/error.png'),
    width: width,
    height: height,
  );
}

Widget buildLoading(double? width, double? height) {
  double? size;
  if (width != null && height != null) {
    size = width < height ? width : height;
  }
  return SizedBox(
    width: width,
    height: height,
    child: Center(
      child: Icon(
        Icons.downloading,
        size: size,
        color: Colors.black12,
      ),
    ),
  );
}

//
class LoadingCacheImage extends StatefulWidget {
  final String url;
  final String useful;
  final int? extendsFieldIntFirst;
  final int? extendsFieldIntSecond;
  final int? extendsFieldIntThird;
  final double? width;
  final double? height;
  final Function(Size size)? onTrueSize;
  final BoxFit fit;

  const LoadingCacheImage({
    super.key,
    required this.url,
    required this.useful,
    this.extendsFieldIntFirst,
    this.extendsFieldIntSecond,
    this.extendsFieldIntThird,
    this.width,
    this.height,
    this.onTrueSize,
    this.fit = BoxFit.cover,
  });

  @override
  State<StatefulWidget> createState() => _LoadingCacheImageState();
}

class _LoadingCacheImageState extends State<LoadingCacheImage> {
  late Future<String> _future;

  @override
  void initState() {
    _future = _init();
    super.initState();
  }

  Future<String> _init() async {
    final loadedImage = await native.loadCacheImage(
      url: widget.url,
      useful: widget.useful,
      extendsFieldIntFirst: widget.extendsFieldIntFirst,
      extendsFieldIntSecond: widget.extendsFieldIntSecond,
      extendsFieldIntThird: widget.extendsFieldIntThird,
    );
    widget.onTrueSize?.call(Size(
        loadedImage.imageWidth.toDouble(), loadedImage.imageHeight.toDouble()));
    return loadedImage.absPath;
  }

  @override
  Widget build(BuildContext context) {
    return pathFutureImage(
      _future,
      widget.width,
      widget.height,
      fit: widget.fit,
    );
  }
}

Widget pathFutureImage(Future<String> future, double? width, double? height,
    {BoxFit fit = BoxFit.cover, BuildContext? context}) {
  return FutureBuilder(
      future: future,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasError) {
          print("${snapshot.error}");
          print("${snapshot.stackTrace}");
          return buildError(width, height);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return buildLoading(width, height);
        }
        return buildFile(
          snapshot.data!,
          width,
          height,
          fit: fit,
          context: context,
        );
      });
}

// 通用方法

Widget buildSvg(String source, double? width, double? height,
    {Color? color, double? margin}) {
  var widget = Container(
    width: width,
    height: height,
    padding: margin != null ? const EdgeInsets.all(10) : null,
    child: Center(
      child: SvgPicture.asset(
        source,
        width: width,
        height: height,
        color: color,
      ),
    ),
  );
  return GestureDetector(onLongPress: () {}, child: widget);
}

Widget buildFile(String file, double? width, double? height,
    {BoxFit fit = BoxFit.cover, BuildContext? context}) {
  var image = Image(
    image: FileImage(File(file)),
    width: width,
    height: height,
    errorBuilder: (a, b, c) {
      print("$b");
      print("$c");
      return buildError(width, height);
    },
    fit: fit,
  );
  if (context == null) return image;
  return GestureDetector(
    onLongPress: () async {
      String? choose = await chooseListDialog(
        context,
        title: '请选择',
        values: ['预览图片', '保存图片'],
      );
      switch (choose) {
        case '预览图片':
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => FilePhotoViewScreen(file),
          ));
          break;
        case '保存图片':
          saveImageFileToGallery(context, file);
          break;
      }
    },
    child: image,
  );
}
