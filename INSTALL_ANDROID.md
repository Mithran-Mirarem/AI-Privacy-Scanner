# Flutter Android setup — fixed package

## Requirements
- Flutter 3.38.6 or newer compatible stable release; Dart 3.10.7 is supported by the pinned dependency ranges in this package.
- Android Studio / Android SDK and a physical Android device with USB debugging enabled.
- Internet connection for the first `flutter pub get`.

## First run (PowerShell)
Open PowerShell in this `flutter_app` folder and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\SETUP_FINAL_FAST.ps1
flutter pub get
flutter analyze
flutter devices
flutter run -d YOUR_DEVICE_ID
```

The setup script creates Android platform scaffolding if absent, inserts permissions without replacing the XML root tag, and sets the Android minimum SDK to 26 where a standard Gradle file is present. If you already have a customized Android folder, back it up first.

## Included model
`assets/models/privacy_scanner.tflite` is the exported V2 model included in this package. `pubspec.yaml` declares it as an asset. Do not rename it unless you also update `TfliteDetector` and `DiagnosticsScreen`.

## Notes
- Camera inference is on-demand: tap **AI SCAN**. Enhanced scan runs one full-frame pass plus four overlapping crops.
- Wi-Fi scans show visible access points; Android may throttle scans or require location/nearby-device permissions and Location services to be enabled.
- Magnetometer data is a supporting physical measurement only. It cannot prove that a hidden camera exists.
- The detector is a screening aid. Ordinary phone-camera modules can produce false positives; no phone RGB camera can reliably identify every concealed camera.
