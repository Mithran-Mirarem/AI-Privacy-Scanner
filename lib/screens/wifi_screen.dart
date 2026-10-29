import 'package:flutter/material.dart';
import '../services/wifi_service.dart';

class WifiScreen extends StatefulWidget {
  const WifiScreen({super.key});
  @override
  State<WifiScreen> createState() => _WifiScreenState();
}

class _WifiScreenState extends State<WifiScreen> {
  final service = WifiService();
  List<WifiScanResult> aps = [];
  bool busy = false;
  String status = 'Tap SCAN to request visible Wi-Fi access points.';

  Future<void> scan() async {
    setState(() => busy = true);
    try {
      final r = await service.scan();
      if (!mounted) return;
      setState(() {
        aps = r..sort((a, b) => b.level.compareTo(a.level));
        status = 'Found ${aps.length} visible access point(s). Camera-like count is only an SSID heuristic.';
        busy = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        busy = false;
        status = 'Wi-Fi scan unavailable: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraLike = aps.where((a) => a.cameraLike).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Wi-Fi Scanner')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : scan, icon: const Icon(Icons.wifi_find), label: Text(busy ? 'SCANNING...' : 'SCAN WI-FI'))),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(status, style: const TextStyle(color: Colors.white70))),
          if (aps.isNotEmpty) Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Camera-like SSID heuristic matches: $cameraLike', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w700)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Wi-Fi results show nearby access points. They are supporting evidence, not proof of a surveillance device.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: aps.isEmpty
                ? const Center(child: Text('No results yet'))
                : ListView.builder(
                    itemCount: aps.length,
                    itemBuilder: (context, i) {
                      final a = aps[i];
                      return ListTile(
                        leading: Icon(a.cameraLike ? Icons.videocam : (a.level >= -70 ? Icons.signal_wifi_4_bar : Icons.wifi), color: a.cameraLike ? Colors.orangeAccent : null),
                        title: Text(a.ssid),
                        subtitle: Text('${a.level} dBm • ${a.frequency} MHz\n${a.capabilities}'),
                        isThreeLine: true,
                        trailing: Text(a.bssid, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
