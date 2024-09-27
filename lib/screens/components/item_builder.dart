import 'package:flutter/material.dart';

// 非全屏FutureBuilder封装
class ItemBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final AsyncWidgetBuilder<T> successBuilder;
  final Future<dynamic> Function() onRefresh;
  final double? loadingHeight;
  final double? height;

  const ItemBuilder({
    super.key,
    required this.future,
    required this.successBuilder,
    required this.onRefresh,
    this.height,
    this.loadingHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        var maxWidth = constraints.maxWidth;
        var loadingHeight = height ?? this.loadingHeight ?? maxWidth / 2;
        return FutureBuilder(
            future: future,
            builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
              if (snapshot.hasError) {
                print("${snapshot.error}");
                print("${snapshot.stackTrace}");
                return InkWell(
                  onTap: onRefresh,
                  child: SizedBox(
                    width: maxWidth,
                    height: loadingHeight,
                    child: Center(
                      child:
                          Icon(Icons.sync_problem, size: loadingHeight / 1.5),
                    ),
                  ),
                );
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return SizedBox(
                  width: maxWidth,
                  height: loadingHeight,
                  child: Center(
                    child: Icon(Icons.sync, size: loadingHeight / 1.5),
                  ),
                );
              }
              return SizedBox(
                width: maxWidth,
                height: height,
                child: successBuilder(context, snapshot),
              );
            });
      },
    );
  }
}
