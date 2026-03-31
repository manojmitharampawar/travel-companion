import 'package:flutter/cupertino.dart';

Route<T> adaptivePageRoute<T>(Widget page) {
  return CupertinoPageRoute<T>(builder: (_) => page);
}
