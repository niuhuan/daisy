import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:daisy/screens/login_screen.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';

import '../commons.dart';

final loginEvent = Event();

var _loginInfo = const native.LoginInfo(status: 1, message: "");

native.LoginInfo get loginInfo => _loginInfo;

set loginInfo(native.LoginInfo info) {
  _loginInfo = info;
  loginEvent.broadcast();
}

Future initLogin() async {
  var username = await native.loadProperty(k: "username");
  var password = await native.loadProperty(k: "password");
  if (username.isNotEmpty && password.isNotEmpty) {
    loginInfo = await native.preLogin(
      nickname: username,
      passwd: generateMD5(password).toUpperCase(),
    );
  }
  loginEvent.broadcast();
}

_LoginScreen loginScreen(Widget Function() builder) {
  return _LoginScreen(builder);
}

class _LoginScreen extends StatefulWidget {
  final Widget Function() builder;

  const _LoginScreen(this.builder);

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
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
    if (loginInfo.status == 0) return widget.builder();
    return Center(
      child: MaterialButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) {
              return const LoginScreen();
            },
          ));
        },
        child: const Text("去登录"),
      ),
    );
  }
}
