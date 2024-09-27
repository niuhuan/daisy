import 'package:daisy/src/rust/api/bridge.dart' as native;

const _propertyKey = "last_module";

late int lastModule;

Future initLastModule() async {
  final val = await native.loadProperty(k: _propertyKey);
  if (val == "") {
    lastModule = 0;
  } else {
    lastModule = int.parse(val);
  }
}

Future setLastModule(int jumpTo) async {
  await native.saveProperty(k: _propertyKey, v: jumpTo.toString());
}
