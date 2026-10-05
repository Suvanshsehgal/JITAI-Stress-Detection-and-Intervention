import 'package:flutter/material.dart';

class AppRadius {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double extraLarge = 24.0;
  
  static final BorderRadius smallRadius = BorderRadius.circular(small);
  static final BorderRadius mediumRadius = BorderRadius.circular(medium);
  static final BorderRadius largeRadius = BorderRadius.circular(large);
  static final BorderRadius extraLargeRadius = BorderRadius.circular(extraLarge);
  static final BorderRadius pill = BorderRadius.circular(999.0);
}
