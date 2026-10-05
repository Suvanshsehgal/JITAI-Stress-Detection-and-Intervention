import 'package:flutter/material.dart';

class AppShadows {
  static const List<BoxShadow> lightCardShadow = [
    BoxShadow(
      color: Color(0x0C000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> darkCardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
}
