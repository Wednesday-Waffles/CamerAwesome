import 'dart:ui' show Size;

import 'package:camerawesome/pigeon.dart';

/// Extension methods for PreviewSize to restore functionality
/// that was previously inline in the Pigeon-generated class.
extension PreviewSizeExtensions on PreviewSize {
  /// Converts this PreviewSize to a dart:ui Size.
  Size toSize() => Size(width, height);

  /// Returns a new [PreviewSize] with [width] and [height] inverted.
  /// Useful when the preview size is given in portrait mode but the camera
  /// is in landscape mode.
  /// Ex: for tablets, the preview size is given in landscape mode but the
  /// device is in portrait mode.
  PreviewSize inverted() => PreviewSize(width: height, height: width);
}
