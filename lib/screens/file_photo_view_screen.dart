import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../commons.dart';

// 预览图片
class FilePhotoViewScreen extends StatelessWidget {
  final String filePath;

  const FilePhotoViewScreen(this.filePath, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            GestureDetector(
              onLongPress: () async {
                String? choose = await chooseListDialog(
                  context,
                  title: '请选择',
                  values: ['保存图片'],
                );
                switch (choose) {
                  case '保存图片':
                    saveImageFileToGallery(context, filePath);
                    break;
                }
              },
              child: PhotoView(
                imageProvider: FileImage(File(filePath)),
              ),
            ),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.only(top: 30),
                padding: const EdgeInsets.only(left: 4, right: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.75),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Icon(Icons.keyboard_backspace, color: Colors.white),
              ),
            ),
          ],
        ),
      );
}
