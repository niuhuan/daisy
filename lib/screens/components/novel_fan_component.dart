import 'package:flutter/material.dart';

class NovelFanComponentController {
  _NovelFanComponentState? _state;

  toPrevious() {
    _state?._toPrevious();
  }

  toNext() {
    _state?._toNext();
  }
}

class NovelFanComponent extends StatefulWidget {
  final Widget? previous;
  final Widget? next;
  final Widget current;
  final void Function()? onNextSetState;
  final void Function()? onPreviousSetState;
  final NovelFanComponentController? controller;

  const NovelFanComponent({
    this.previous,
    this.onPreviousSetState,
    this.next,
    this.onNextSetState,
    this.controller,
    required this.current,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _NovelFanComponentState();
}

class _NovelFanComponentState extends State<NovelFanComponent>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController =
      AnimationController(vsync: this);

  @override
  void initState() {
    animationController.addListener(_onAnimat);
    widget.controller?._state = this;
    super.initState();
  }

  @override
  void dispose() {
    animationController.removeListener(_onAnimat);
    animationController.dispose();
    widget.controller?._state = null;
    super.dispose();
  }

  void _onAnimat() {
    moved = movedAnimeStar +
        (movedAnimeEnd - movedAnimeStar) * animationController.value;
    setState(() {});
  }

  int touchState = 0; // 0未触摸
  late Offset prePosition;
  late int direction;
  late int lastDirection;
  late double moved;

  late double movedAnimeStar;
  late double movedAnimeEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (detail) {
        if (animationController.isAnimating) {
          return;
        }
        touchState = 1;
        prePosition = detail.globalPosition;
        moved = 0;
      },
      onPanUpdate: (detail) {
        if (detail.globalPosition.dx != prePosition.dx) {
          if (touchState == 1) {
            touchState = 2;
            direction = detail.globalPosition.dx < prePosition.dx ? -1 : 1;
            lastDirection = detail.globalPosition.dx < prePosition.dx ? -1 : 1;
            moved += detail.globalPosition.dx - prePosition.dx;
            if (direction < 0 && widget.next == null) {
              // 直到下次touchDown不响应
              touchState = 0;
            } else if (direction > 0 && widget.previous == null) {
              // 直到下次touchDown不响应
              touchState = 0;
            }
          } else if (touchState == 2) {
            lastDirection = detail.globalPosition.dx < prePosition.dx ? -1 : 1;
            moved += detail.globalPosition.dx - prePosition.dx;
          }
        }
        prePosition = detail.globalPosition;
        setState(() {});
      },
      onPanEnd: (detail) async {
        if (touchState == 2) {
          // 滑动过
          if (direction == lastDirection) {
            movedAnimeStar = moved;
            movedAnimeEnd = direction * MediaQuery.of(context).size.width;
            animationController.duration = const Duration(milliseconds: 240);
            await animationController.forward(from: 0);
            touchState = 0;
            if (direction < 0) {
              if (widget.onNextSetState != null) {
                widget.onNextSetState!();
              }
            }
            if (direction > 0) {
              if (widget.onPreviousSetState != null) {
                widget.onPreviousSetState!();
              }
            }
            // 滑动
          } else {
            // 滑回
            movedAnimeStar = moved;
            movedAnimeEnd = 0;
            animationController.duration = const Duration(milliseconds: 240);
            await animationController.forward(from: 0);
          }
        }
      },
      child: Stack(children: [
        _previous(),
        _current(),
        _next(),
      ]),
    );
  }

  void _toPrevious() async {
    if (animationController.isAnimating) {
      return;
    }
    if (widget.previous == null) {
      return;
    }
    touchState = 2;
    direction = 1;
    movedAnimeStar = 0;
    movedAnimeEnd = direction * MediaQuery.of(context).size.width;
    animationController.duration = const Duration(milliseconds: 140);
    await animationController.forward(from: 0);
    touchState = 0;
    widget.onPreviousSetState!();
  }

  void _toNext() async {
    if (animationController.isAnimating) {
      return;
    }
    if (widget.next == null) {
      return;
    }
    touchState = 2;
    direction = -1;
    movedAnimeStar = 0;
    movedAnimeEnd = direction * MediaQuery.of(context).size.width;
    animationController.duration = const Duration(milliseconds: 140);
    await animationController.forward(from: 0);
    touchState = 0;
    widget.onNextSetState!();
  }

  Widget _previous() {
    if (widget.previous != null) {
      return widget.previous!;
    }
    return Container();
  }

  Widget _current() {
    if (widget.previous != null && touchState > 0 && direction > 0) {
      return Transform.translate(
        offset: Offset(
          moved,
          0,
        ),
        child: widget.current,
      );
    }
    return widget.current;
  }

  Widget _next() {
    if (widget.next != null && touchState > 0 && direction < 0) {
      return Transform.translate(
        offset: Offset(
          MediaQuery.of(context).size.width + moved,
          0,
        ),
        child: widget.next,
      );
    }
    return Container();
  }
}
