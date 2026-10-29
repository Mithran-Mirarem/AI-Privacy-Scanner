import 'dart:async';
import 'package:flutter/material.dart';
import '../services/magnetometer_service.dart';

class MagnetometerScreen extends StatefulWidget {
  const MagnetometerScreen({super.key});
  @override
  State<MagnetometerScreen> createState() => _MagnetometerScreenState();
}

class _MagnetometerScreenState extends State<MagnetometerScreen> {
  final service = MagnetometerService();
  StreamSubscription<double>? sub;
  double current = 0;
  double? baseline;
  String status = 'Tap CALIBRATE while the phone is away from strong magnets/electronics.';
  bool calibrating = false;

  @override
  void initState() {
    super.initState();
    service.start();
    sub = service.magnitudeStream.listen((m) {
      if (!mounted) return;
      setState(() => current = m);
    });
  }

  Future<void> calibrate() async {
    setState(() {
      calibrating = true;
      status = 'Calibrating baseline...';
    });
    final value = await service.calibrate();
    if (!mounted) return;
    setState(() {
      baseline = value;
      calibrating = false;
      status = value == null ? 'No magnetometer samples available.' : 'Baseline calibrated.';
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = baseline == null || baseline == 0 ? null : current / baseline!;
    final anomaly = ratio != null && ratio >= 1.45;
    return Scaffold(
      appBar: AppBar(title: const Text('Magnetometer')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore, size: 72, color: anomaly ? Colors.orangeAccent : Colors.cyanAccent),
            const SizedBox(height: 16),
            Text(current.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800)),
            const Text('µT magnitude', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 10),
            Text(baseline == null ? 'Baseline: not calibrated' : 'Baseline: ${baseline!.toStringAsFixed(1)} µT'),
            if (ratio != null) Text('Current / baseline: ${ratio.toStringAsFixed(2)}×'),
            const SizedBox(height: 12),
            Text(anomaly ? 'MAGNETIC VARIATION' : 'NORMAL RANGE', style: TextStyle(color: anomaly ? Colors.orangeAccent : Colors.cyanAccent, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: calibrating ? null : calibrate, icon: const Icon(Icons.tune), label: Text(calibrating ? 'CALIBRATING...' : 'CALIBRATE')),
            const SizedBox(height: 16),
            const Text('Magnetometer readings are supporting evidence only and cannot identify a hidden camera by themselves.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
