import 'package:date_format/date_format.dart';

String timeFormat(int time) {
  return formatDate(
    DateTime.fromMillisecondsSinceEpoch(time * 1000),
    [yyyy, "-", mm, "-", dd, " ", hh, ":", nn, ":", ss],
  );
}
