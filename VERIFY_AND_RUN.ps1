$ErrorActionPreference = 'Stop'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter is not on PATH.' }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze reported errors. Read the output above.' }
flutter devices
Write-Host 'If your Android device is listed, run: flutter run -d YOUR_DEVICE_ID' -ForegroundColor Green
