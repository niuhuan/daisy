import 'package:flutter/material.dart';
import '../../configs/versions.dart';

// 提示信息, 组件右上角的小红点
class Badged extends StatelessWidget {
  final String? badge;
  final Widget child;

  const Badged({Key? key, required this.child, this.badge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (badge == null) {
      return child;
    }
    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            constraints: const BoxConstraints(
              minWidth: 12,
              minHeight: 12,
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class VersionBadged extends StatefulWidget {
  final Widget child;

  const VersionBadged({required this.child, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VersionBadgedState();
}

class _VersionBadgedState extends State<VersionBadged> {
  @override
  void initState() {
    versionEvent.subscribe(_onVersion);
    super.initState();
  }

  @override
  void dispose() {
    versionEvent.unsubscribe(_onVersion);
    super.dispose();
  }

  void _onVersion(dynamic a) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Badged(
      child: widget.child,
      badge: latestVersion == null ? null : "1",
    );
  }
}
