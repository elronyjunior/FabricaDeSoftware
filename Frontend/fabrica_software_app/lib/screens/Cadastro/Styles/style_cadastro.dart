import 'package:flutter/material.dart';

class StyleCadastro {
  static ButtonStyle btnGoogle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 14),
    foregroundColor: Colors.black87,
    backgroundColor: Colors.white,
    side: BorderSide(color: Colors.white.withOpacity(0.90)),
    shadowColor: Colors.transparent,
    minimumSize: const Size(double.infinity, 50),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
  );
}
