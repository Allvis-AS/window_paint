import 'package:flutter/widgets.dart';
import 'package:window_paint/src/draw/draw_object.dart';
import 'package:window_paint/src/draw/draw_object_adapter.dart';
import 'package:window_paint/src/window_paint_painter.dart';

class WindowPaintCanvas extends StatefulWidget {
  final Color color;
  final DrawObjectAdapter adapter;
  final Widget child;

  const WindowPaintCanvas({
    Key? key,
    this.color = const Color(0xFF000000),
    required this.adapter,
    required this.child,
  }) : super(key: key);

  @override
  _WindowPaintCanvasState createState() => _WindowPaintCanvasState();
}

class _WindowPaintCanvasState extends State<WindowPaintCanvas> {
  final _transformationController = TransformationController();
  final objects = <DrawObject>[];

  var _hasActiveInteraction = false;
  late Matrix4 _lockedTransform;

  @override
  void initState() {
    super.initState();
    _lockedTransform = _transformationController.value;
    _transformationController.addListener(() {
      /// In newer versions of [InteractiveViewer], the [onInteractionUpdate]
      /// callback is not called when [panEnabled] and [scaleEnabled] are false.
      ///
      /// To overcome this limitation, we have to manually reset the
      /// transformation with the [transformationController].
      if (widget.adapter.panEnabled || widget.adapter.scaleEnabled) {
        _lockedTransform = _transformationController.value;
      } else if (_transformationController.value != _lockedTransform) {
        _transformationController.value = _lockedTransform;
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformationController,
      onInteractionStart: _onInteractionStart,
      onInteractionUpdate: _onInteractionUpdate,
      onInteractionEnd: _onInteractionEnd,
      child: CustomPaint(
        foregroundPainter: WindowPaintPainter(
          objects: objects,
        ),
        willChange: _hasActiveInteraction,
        child: widget.child,
      ),
    );
  }

  void _onInteractionStart(ScaleStartDetails details) {
    final focalPointScene =
        _transformationController.toScene(details.localFocalPoint);
    setState(() {
      final object = widget.adapter.start(focalPointScene, widget.color);
      objects.add(object);
      _hasActiveInteraction = true;
    });
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    final object = objects.last;
    final focalPointScene =
        _transformationController.toScene(details.localFocalPoint);
    final repaint =
        widget.adapter.update(object, focalPointScene, widget.color);
    if (repaint) {
      setState(() {});
    }
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    final object = objects.last;
    setState(() {
      final keep = widget.adapter.end(object, widget.color);
      if (!keep) {
        objects.removeLast();
      }
      _hasActiveInteraction = false;
    });
  }
}