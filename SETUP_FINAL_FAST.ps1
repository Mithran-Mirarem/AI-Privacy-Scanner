$ErrorActionPreference = 'Stop'
Write-Host 'AI Privacy Scanner - Android setup' -ForegroundColor Cyan
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter is not on PATH. Install Flutter stable and Android Studio, then reopen PowerShell.' }
flutter --version
if (-not (Test-Path '.\android\app\src\main\AndroidManifest.xml')) {
  Write-Host 'Generating Android platform files with Flutter...' -ForegroundColor Yellow
  flutter create . --platforms=android
}
$manifest = '.\android\app\src\main\AndroidManifest.xml'
if (-not (Test-Path $manifest)) { throw "Android manifest still missing: $manifest" }
$xml = Get-Content -Path $manifest -Raw
$permissions = @(
  'android.permission.CAMERA',
  'android.permission.ACCESS_WIFI_STATE',
  'android.permission.CHANGE_WIFI_STATE',
  'android.permission.ACCESS_FINE_LOCATION',
  'android.permission.ACCESS_COARSE_LOCATION',
  'android.permission.NEARBY_WIFI_DEVICES'
)
foreach ($permission in $permissions) {
  if ($xml -notmatch [regex]::Escape($permission)) {
    $line = "    <uses-permission android:name=`"$permission`" />`r`n"
    $xml = [regex]::Replace($xml, '</manifest>', ($line + '</manifest>'), 1)
  }
}
# Wi-Fi scan on Android may need location permission; neverForLocation is not added here to retain compatibility across OS versions.
Set-Content -Path $manifest -Value $xml -Encoding UTF8
# Use the Flutter-generated Android Gradle configuration, but request a modern minimum SDK for TFLite.
$gradle = '.\android\app\build.gradle.kts'
if (Test-Path $gradle) {
  $g = Get-Content $gradle -Raw
  if ($g -match 'minSdk\s*=\s*flutter\.minSdkVersion') { $g = $g -replace 'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 26' }
  elseif ($g -match 'minSdk\s*=\s*\d+') { $g = [regex]::Replace($g, 'minSdk\s*=\s*\d+', 'minSdk = 26', 1) }
  Set-Content $gradle $g -Encoding UTF8
} else {
  $gradle = '.\android\app\build.gradle'
  if (Test-Path $gradle) {
    $g = Get-Content $gradle -Raw
    if ($g -match 'minSdkVersion\s+flutter\.minSdkVersion') { $g = $g -replace 'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 26' }
    Set-Content $gradle $g -Encoding UTF8
  }
}
if (-not (Test-Path '.\assets\models\privacy_scanner.tflite')) { throw 'Model file missing: assets\models\privacy_scanner.tflite' }
Write-Host 'Setup files prepared. Now run: flutter pub get; flutter analyze; flutter run -d <your-device-id>' -ForegroundColor Green
