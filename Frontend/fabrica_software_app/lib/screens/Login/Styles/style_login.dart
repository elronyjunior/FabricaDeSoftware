import 'package:flutter/material.dart';

class StyleLogin {

static ButtonStyle btnGoogle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 14),
    foregroundColor: Colors.black87,
    backgroundColor: Colors.white,
    side: const BorderSide(color: Color(0xFFE9E9E9)),
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    minimumSize: const Size(double.infinity, 52),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
  );

}