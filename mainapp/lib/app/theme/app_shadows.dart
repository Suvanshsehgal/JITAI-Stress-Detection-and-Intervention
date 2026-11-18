import 'package:flutter/material.dart';

class AppShadows {
  // Layered dual-shadow for natural, distinct card separation from the canvas
  static const List<BoxShadow> lightCardShadow = [
    BoxShadow(
      color: Color(0x12352520), // 7% ambient shadow
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A352520), // 4% subtle contact shadow
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> floatingNavShadow = [
    BoxShadow(
      color: Color(0x22352520), // 13% soft elevation
      blurRadius: 28,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> darkCardShadow = [
    BoxShadow(
      color: Color(0x38000000),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];
}
