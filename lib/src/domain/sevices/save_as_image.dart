import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/control_provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/rendering_notifier.dart';
import 'package:stories_editor/src/presentation/utils/constants/render_state.dart';

Future takePicture(
    {required contentKey,
    required BuildContext context,
    required saveToGallery}) async {
  try {
    /// converter widget to image
    RenderRepaintBoundary boundary =
        contentKey.currentContext.findRenderObject();

    ui.Image image = await boundary.toImage(pixelRatio: 3);

    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    /// create file
    final String dir = (await getApplicationDocumentsDirectory()).path;
    String imagePath = '$dir/stories_creator${DateTime.now()}.png';
    File capturedFile = File(imagePath);
    await capturedFile.writeAsBytes(pngBytes);

    if (saveToGallery) {
      final result = await ImageGallerySaver.saveImage(pngBytes,
          quality: 100, name: "stories_creator${DateTime.now()}.png");
      if (result != null) {
        return true;
      } else {
        return false;
      }
    } else {
      return imagePath;
    }
  } catch (e) {
    debugPrint('exception => $e');
    return false;
  }
}

class WidgetRecorderController extends ChangeNotifier {
  WidgetRecorderController() : _containerKey = GlobalKey();

  /// key of the content widget to render
  final GlobalKey _containerKey;

  /// frame callback
  final SchedulerBinding _binding = SchedulerBinding.instance;

  /// save frames
  final List<ui.Image> _frames = [];

  /// start render
  void start(
      {required ControlNotifier controlNotifier,
      required RenderingNotifier renderingNotifier}) {
    controlNotifier.isRenderingWidget = true;
    renderingNotifier.renderState = RenderState.preparing;
    _binding.addPostFrameCallback(
      (timeStamp) {
        _postFrameCallback(timeStamp, controlNotifier, renderingNotifier);
      },
    );
    notifyListeners();
  }

  /// stop render
  void stop(
      {required ControlNotifier controlNotifier,
      required RenderingNotifier renderingNotifier}) {
    renderingNotifier.renderState = RenderState.preparing;
    controlNotifier.isRenderingWidget = false;
    notifyListeners();
  }

  /// add frame to list
  void _postFrameCallback(Duration timestamp, ControlNotifier controlNotifier,
      RenderingNotifier renderingNotifier) async {
    if (controlNotifier.isRenderingWidget == false) {
      return;
    } else {
      renderingNotifier.renderState = RenderState.frames;
      notifyListeners();
      try {
        final image = await _captureFrame();
        _frames.add(image!);
        renderingNotifier.totalFrames = _frames.length;
        notifyListeners();
      } catch (e) {
        debugPrint(e.toString());
      }
      _binding.addPostFrameCallback(
        (timeStamp) {
          _postFrameCallback(timeStamp, controlNotifier, renderingNotifier);
        },
      );
      notifyListeners();
    }
  }

  /// capture widget to render
  Future<ui.Image?> _captureFrame() async {
    final renderObject = _containerKey.currentContext?.findRenderObject();
    notifyListeners();
    if (renderObject is RenderRepaintBoundary) {
      final image = await renderObject.toImage(pixelRatio: 2);
      return image;
    } else {
      FlutterError.reportError(_noRenderObject());
    }
    return null;
  }

  /// error details
  FlutterErrorDetails _noRenderObject() {
    return FlutterErrorDetails(
      exception: Exception(
        '_containerKey.currentContext is null. '
        'Thus we can\'t create a screenshot',
      ),
      library: 'feedback',
      context: ErrorDescription(
        'Tried to find a context to use it to create a screenshot',
      ),
    );
  }
}

class ScreenRecorder extends StatelessWidget {
  const ScreenRecorder({
    Key? key,
    required this.child,
    required this.controller,
  }) : super(key: key);

  /// The child which should be recorded.
  final Widget child;

  /// This controller starts and stops the recording.
  final WidgetRecorderController controller;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: controller._containerKey,
      child: child,
    );
  }
}
