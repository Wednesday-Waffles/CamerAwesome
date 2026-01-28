import 'dart:ui';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/camera_context.dart';

/// When Camera is in Video mode
class VideoCameraState extends CameraState {
  VideoCameraState({
    required CameraContext cameraContext,
    required this.filePathBuilder,
  }) : super(cameraContext);

  factory VideoCameraState.from(CameraContext cameraContext) =>
      VideoCameraState(
        cameraContext: cameraContext,
        filePathBuilder: cameraContext.saveConfig!.videoPathBuilder!,
      );

  final CaptureRequestBuilder filePathBuilder;

  @override
  void setState(CaptureMode captureMode) {
    if (captureMode == CaptureMode.video) {
      return;
    }
    cameraContext.changeState(captureMode.toCameraState(cameraContext));
  }

  @override
  CaptureMode get captureMode => CaptureMode.video;

  /// You can listen to [cameraSetup.mediaCaptureStream] to get updates
  /// of the photo capture (capturing, success/failure)
  Future<CaptureRequest> startRecording() async {
    final debugConfig = CamerawesomeDebugConfig.instance;

    CaptureRequest captureRequest =
        await filePathBuilder(sensorConfig.sensors.nonNulls.toList());
    _mediaCapture = MediaCapture.capturing(
        captureRequest: captureRequest, videoState: VideoState.started);
    try {
      // Debug injection point for reproducing recording failure
      if (debugConfig.forceRecordingFailure) {
        await Future.delayed(
            Duration(milliseconds: debugConfig.recordingFailureDelayMs));
        throw Exception(debugConfig.recordingFailureMessage);
      }
      await CamerawesomePlugin.recordVideo(captureRequest);
    } on Exception catch (e) {
      _mediaCapture =
          MediaCapture.failure(captureRequest: captureRequest, exception: e);

      // Toggle between buggy and fixed behavior for testing
      if (debugConfig.useBuggyStateMachineBehavior) {
        // BUGGY: State transitions even on failure (original behavior)
        // This causes "video is not recording" crash when user taps stop
        cameraContext.changeState(VideoRecordingCameraState.from(cameraContext));
        return captureRequest;
      } else {
        // FIXED: Don't transition to recording state if recording failed
        // Rethrow so caller knows recording failed and can handle appropriately
        rethrow;
      }
    }
    // Only transition to recording state if we get here (no exception)
    cameraContext.changeState(VideoRecordingCameraState.from(cameraContext));
    return captureRequest;
  }

  /// If the video recording should [enableAudio].
  /// This method applies to the next recording. If a recording is ongoing, it will not be affected.
  // TODO Add ability to mute temporarly a video recording
  Future<void> enableAudio(bool enableAudio) {
    return CamerawesomePlugin.setAudioMode(enableAudio);
  }

  /// PRIVATES

  set _mediaCapture(MediaCapture media) {
    if (!cameraContext.mediaCaptureController.isClosed) {
      cameraContext.mediaCaptureController.add(media);
    }
  }

  @override
  void dispose() {
    // Nothing to do
  }

  focus() {
    cameraContext.focus();
  }

  Future<void> focusOnPoint({
    required Offset flutterPosition,
    required PreviewSize pixelPreviewSize,
    required PreviewSize flutterPreviewSize,
    AndroidFocusSettings? androidFocusSettings,
  }) {
    return cameraContext.focusOnPoint(
      flutterPosition: flutterPosition,
      pixelPreviewSize: pixelPreviewSize,
      flutterPreviewSize: flutterPreviewSize,
      androidFocusSettings: androidFocusSettings,
    );
  }
}
