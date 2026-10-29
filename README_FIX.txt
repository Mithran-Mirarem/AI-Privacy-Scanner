AI Privacy Scanner - NCHW input compatibility fix

Replace the existing file:
  flutter_app/lib/services/tflite_detector.dart

with:
  lib/services/tflite_detector.dart (inside this archive)

Extract this archive directly into the flutter_app folder and allow the file to be overwritten.
The fix accepts both NHWC [1,640,640,3] and NCHW [1,3,640,640] float32 input tensors and builds image input in the matching layout.
