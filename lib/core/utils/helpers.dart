import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Helpers {
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  static void showToast(String message) {
    Fluttertoast.showToast(msg: message);
  }
}
