import 'package:flutter/widgets.dart';
import 'package:window_paint/src/draw/draw_object_adapter.dart';

abstract class DrawObject {
  const DrawObject();

  void paint(Canvas canvas, Size size);
  bool shouldRepaint();

  DrawObjectAdapter get adapter;

  /// Used primarily for updating [WindowPaintController.color] when selected.
  Color get primaryColor;

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJSON();
}
