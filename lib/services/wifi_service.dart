import 'package:wifi_scan/wifi_scan.dart';

class WifiScanResult {
  final String ssid;
  final String bssid;
  final int level;
  final int frequency;
  final String capabilities;
  const WifiScanResult({
    required this.ssid,
    required this.bssid,
    required this.level,
    required this.frequency,
    required this.capabilities,
  });

  bool get cameraLike {
    final x = ssid.toLowerCase();
    const words = ['camera', 'cam', 'ipcam', 'cctv', 'dvr', 'nvr', 'security', 'surveillance', 'spycam'];
    return words.any(x.contains);
  }
}

class WifiEvidence {
  final List<WifiScanResult> networks;
  final int cameraLikeNetworks;
  const WifiEvidence(this.networks, this.cameraLikeNetworks);
}

class WifiService {
  Future<List<WifiScanResult>> scan() async {
    final can = await WiFiScan.instance.canStartScan(askPermissions: true);
    if (can != CanStartScan.yes) throw StateError('Wi-Fi scan unavailable: $can');
    await WiFiScan.instance.startScan();
    final canGet = await WiFiScan.instance.canGetScannedResults(askPermissions: true);
    if (canGet != CanGetScannedResults.yes) throw StateError('Wi-Fi results unavailable: $canGet');
    final aps = await WiFiScan.instance.getScannedResults();
    return aps
        .map((a) => WifiScanResult(
              ssid: a.ssid.isEmpty ? '(hidden SSID)' : a.ssid,
              bssid: a.bssid,
              level: a.level,
              frequency: a.frequency,
              capabilities: a.capabilities,
            ))
        .toList();
  }

  WifiEvidence evidence(List<WifiScanResult> networks) {
    final cameraLike = networks.where((a) => a.cameraLike).length;
    return WifiEvidence(networks, cameraLike);
  }
}
