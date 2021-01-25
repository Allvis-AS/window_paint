import 'package:window_paint/src/draw/adapters/draw_pencil_adapter.dart';
import 'package:window_paint/src/draw/adapters/draw_rectangle_adapter.dart';
import 'package:window_paint/src/draw/adapters/draw_rectangle_cross_adapter.dart';
import 'package:window_paint/src/draw/adapters/pan_zoom_adapter.dart';
import 'package:window_paint/src/draw/draw_object_adapter.dart';
import 'package:window_paint/src/window_paint_canvas.dart';
import 'package:window_paint/src/window_paint_controller.dart';
import 'package:flutter/widgets.dart';

class WindowPaint extends StatefulWidget {
  WindowPaint({
    Key? key,
    this.minScale = 1.0,
    this.maxScale = 2.5,
    this.controller,
    this.transformationController,
    this.adapters = const {
      'pan_zoom': PanZoomAdapter(),
      'pencil': DrawPencilAdapter(),
      'rectangle': DrawRectangleAdapter(),
      'rectangle_cross': DrawRectangleCrossAdapter(),
    },
    required this.child,
    this.restorationId,
  }) : super(key: key);

  final double minScale;
  final double maxScale;
  final WindowPaintController? controller;
  final TransformationController? transformationController;
  final Map<String, DrawObjectAdapter> adapters;
  final Widget child;

  /// Restoration ID to save and restore the state of the window paint widget.
  ///
  /// If non-null, and no [controller] has been provided, the window paint
  /// widget will persist and restore its current paint mode and color. If a
  /// [controller] has been provided, it is the responsibility of the owner of
  /// that controller to persist and restore it, e.g. by using
  /// a [RestorableWindowPaintController].
  ///
  /// The state of this widget is persisted in a [RestorationBucket] claimed
  /// from the surrounding [RestorationScope] using the provided restoration ID.
  ///
  /// See also:
  ///
  ///  * [RestorationManager], which explains how state restoration works in
  ///    Flutter.
  final String? restorationId;

  @override
  _WindowPaintState createState() => _WindowPaintState();
}

class _WindowPaintState extends State<WindowPaint> with RestorationMixin {
  RestorableWindowPaintController? _controller;
  WindowPaintController get _effectiveController =>
      widget.controller ?? _controller!.value;

  /// The color of the [controller] before an object was selected, if any.
  /// Will be restored to the controller when the selected object is no
  /// longer selected.
  Color? _colorBeforeSelection;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _createLocalController();
    }
  }

  @override
  void didUpdateWidget(WindowPaint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller != null) {
      _createLocalController(oldWidget.controller!.value);
    } else if (widget.controller != null && oldWidget.controller == null) {
      unregisterFromRestoration(_controller!);
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    if (_controller != null) {
      _registerController();
    }
  }

  void _registerController() {
    assert(_controller != null);
    registerForRestoration(_controller!, 'controller');
  }

  void _createLocalController([WindowPaintValue? value]) {
    assert(_controller == null);
    _controller = value == null
        ? RestorableWindowPaintController()
        : RestorableWindowPaintController.fromValue(value);
    if (!restorePending) {
      _registerController();
    }
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ValueListenableBuilder<WindowPaintValue>(
        valueListenable: _effectiveController,
        builder: (context, value, child) {
          return WindowPaintCanvas(
            controller: widget.transformationController,
            color: value.color,
            minScale: widget.minScale,
            maxScale: widget.maxScale,
            onSelectionStart: (object) {
              _colorBeforeSelection = _effectiveController.color;
              _effectiveController.color = object.primaryColor;
            },
            onSelectionEnd: (object) {
              final colorToRestore = _colorBeforeSelection;
              if (colorToRestore != null) {
                _colorBeforeSelection = null;
                _effectiveController.color = colorToRestore;
              }
            },
            adapter: widget.adapters[value.mode]!,
            child: child!,
          );
        },
        child: widget.child,
      ),
    );
  }
}
