import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/material.dart';

import '../../commons.dart';
import '../../configs/login.dart';
import '../login_screen.dart';

class SubscribedIcon extends StatefulWidget {
  final int objType;
  final int objId;

  const SubscribedIcon({
    required this.objType,
    required this.objId,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _SubscribedIconState();
}

class _SubscribedIconState extends State<SubscribedIcon> {
  @override
  void initState() {
    loginEvent.subscribe(_setState);
    super.initState();
  }

  @override
  void dispose() {
    loginEvent.unsubscribe(_setState);
    super.dispose();
  }

  _setState(_) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loginInfo.status == 0) {
      return _LoginSubscribedIcon(objType: widget.objType, objId: widget.objId);
    } else {
      return IconButton(
        onPressed: () async {
          if (await confirmDialog(context, "需要登录", "登录以便订阅漫画?")) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) {
                return const LoginScreen();
              },
            ));
          }
        },
        icon: const Icon(Icons.notifications_off),
      );
    }
  }
}

class _LoginSubscribedIcon extends StatefulWidget {
  final int objType;
  final int objId;

  const _LoginSubscribedIcon({
    required this.objType,
    required this.objId,
  });

  @override
  State<StatefulWidget> createState() => _LoginSubscribedIconState();
}

class _LoginSubscribedIconState extends State<_LoginSubscribedIcon> {
  late Future<bool> _future = native.subscribedObj(
    subType: widget.objType,
    objId: widget.objId,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasError) {
          return IconButton(
            onPressed: () {
              setState(() {
                _future = native.subscribedObj(
                  subType: widget.objType,
                  objId: widget.objId,
                );
              });
            },
            icon: const Icon(Icons.error),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return IconButton(
            onPressed: () {},
            icon: const Icon(Icons.loop),
          );
        }
        return IconButton(
          onPressed: () async {
            setState(() {
              _future = () async {
                final fn = snapshot.requireData
                    ? native.subscribeCancel
                    : native.subscribeAdd;
                try {
                  await fn.call(
                      objType: widget.objType == 0 ? "mh" : "xs",
                      objId: widget.objId);
                  return !snapshot.requireData;
                } catch (e, s) {
                  defaultToast(context, "操作失败 : $e");
                  print("$e\n$s");
                  return snapshot.requireData;
                }
              }();
            });
          },
          icon: Icon(
            snapshot.requireData
                ? Icons.notifications
                : Icons.notifications_none,
          ),
        );
      },
    );
  }
}
