// You called an action you are not supposed to call while camera is loading
class CameraNotReadyException implements Exception {
  final String? message;
  CameraNotReadyException({this.message});

  @override
  String toString() {
    return '''
      CamerAwesome is not ready yet. 
      ==============================================================
      You must call start when current state is PreparingCameraState
      --------------------------------------------------------------
      additional informations: $message
    ''';
  }
}

/// from [PreparingCameraState] you must provide a valid next capture mode
class NoValidCaptureModeException implements Exception {}

/// Audio setup failed - microphone not available or permission denied.
///
/// This exception is thrown when:
/// - Microphone permission is denied
/// - Audio hardware is not available
/// - Audio setup times out
/// - Another app is using the microphone exclusively
class AudioSetupException implements Exception {
  final String message;

  AudioSetupException(this.message);

  @override
  String toString() => 'AudioSetupException: $message';
}
