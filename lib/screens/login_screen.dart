import 'package:daisy/cross.dart';
import 'package:daisy/src/rust/api/bridge.dart' as native;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../commons.dart';
import '../configs/login.dart';
import 'components/content_loading.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late bool _logging = false;
  late String _username = "";
  late String _password = "";

  @override
  void initState() {
    _loadProperties();
    super.initState();
  }

  Future _loadProperties() async {
    var username = await native.loadProperty(k: "username");
    var password = await native.loadProperty(k: "password");
    setState(() {
      _username = username;
      _password = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_logging) {
      return _buildLogging();
    }
    return _buildGui();
  }

  Widget _buildLogging() {
    return const Scaffold(
      body: ContentLoading(label: '登录中'),
    );
  }

  Widget _buildGui() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配置选项'),
        actions: [
          IconButton(
            onPressed: _logIn,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("账号"),
            subtitle: Text(_username == "" ? "未设置" : _username),
            onTap: () async {
              String? input = await displayTextInputDialog(
                context,
                src: _username,
                title: '账号',
                hint: '请输入账号',
              );
              if (input != null) {
                await native.saveProperty(k: "username", v: input);
                setState(() {
                  _username = input;
                });
              }
            },
          ),
          ListTile(
            title: const Text("密码"),
            subtitle: Text(_password == "" ? "未设置" : '\u2022' * 10),
            onTap: () async {
              String? input = await displayTextInputDialog(
                context,
                src: _password,
                title: '密码',
                hint: '请输入密码',
                isPasswd: true,
              );
              if (input != null) {
                await native.saveProperty(k: "password", v: input);
                setState(() {
                  _password = input;
                });
              }
            },
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  child: Text.rich(TextSpan(
                    text: '没有账号,我要注册',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        openUrl("https://m.dmzj.com/register.html");
                      },
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _logIn() async {
    if (_username.isEmpty || _password.isEmpty) return;
    setState(() {
      _logging = true;
    });
    try {
      loginInfo = await native.reLogin(
        nickname: _username,
        passwd: generateMD5(_password).toUpperCase(),
      );
      if (loginInfo.status == 0) {
        Navigator.pop(context);
      } else {
        print("登录失败 : ${loginInfo.message}");
        defaultToast(
          context,
          "登录失败 : ${loginInfo.message}",
        );
      }
    } catch (e, s) {
      print("$e\n$s");
      setState(() {
        _logging = false;
      });
      var message = "请检查账号密码或网络环境";
      defaultToast(
        context,
        "登录失败 : $message\n$e",
      );
    } finally {
      setState(() {
        _logging = false;
      });
    }
  }
}
