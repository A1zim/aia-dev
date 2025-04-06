import 'package:flutter/material.dart';

class Scaling {
  static double _referenceWidth = 360.0;
  static double _minWidth = 320.0;
  static double _scaleFactor = 1.0; // Default value

  static void init(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _scaleFactor = (screenWidth >= _minWidth ? screenWidth : _minWidth) / _referenceWidth;
    if (_scaleFactor > 1.2) _scaleFactor = 1.2;
    if (_scaleFactor < 0.85) _scaleFactor = 0.85;
  }

  static double scale(double size) {
    return size * _scaleFactor;
  }

  static double scaleFont(double fontSize) {
    final scaled = fontSize * _scaleFactor;
    return scaled < 10 ? 10 : scaled;
  }

  static double scalePadding(double padding) {
    final scaled = padding * _scaleFactor;
    return scaled < 8 ? 8 : scaled;
  }

  static double scaleIcon(double iconSize) {
    final scaled = iconSize * _scaleFactor;
    return scaled < 16 ? 16 : scaled;
  }
}