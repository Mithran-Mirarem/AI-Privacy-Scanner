import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/detection.dart';
import '../services/tflite_detector.dart';
import '../services/reflection_detector.dart';
import '../services/risk_engine.dart';
import '../services/wifi_service.dart';
import '../services/magnetometer_service.dart';
import '../services/evidence_fusion.dart';
import '../widgets/detection_overlay.dart';
import '../services/scan_history.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? camera;
  final detector = TfliteDetector();
  final reflection = ReflectionDetector();
  final wifiService = WifiService();
  final magnetometer = MagnetometerService();
  final fusion = const EvidenceFusion();

  List<Detection> detections = [];
  Uint8List? resultImage;
  RiskResult? risk;
  bool optical = false;
  bool enhanced = true;
  bool useWifi = true;
  bool useMagnetometer = true;
  bool busy = false;
  String status = 'Initializing...';
  WifiEvidence? wifiEvidence;
  MagnetometerEvidence? magnetometerEvidence;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    camera?.dispose();
    detector.close();
    magnetometer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = camera;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
      camera = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _load() async {
    try {
      await detector.load();
      await _initCamera();
      await magnetometer.calibrate();
      if (mounted) {
        setState(() => status = 'Ready — frame the room and tap AI SCAN');
      }
    } catch (e) {
      if (mounted) setState(() => status = 'Setup required: $e');
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw StateError('No camera found');
    final selected = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final c = CameraController(selected, ResolutionPreset.high, enableAudio: false);
    camera = c;
    await c.initialize();
    await c.setFlashMode(FlashMode.off);
    if (mounted) setState(() {});
  }

  Future<void> _flash() async {
    final c = camera;
    if (c == null) return;
    final next = c.value.flashMode == FlashMode.torch ? FlashMode.off : FlashMode.torch;
    await c.setFlashMode(next);
    if (mounted) setState(() {});
  }

  Future<List<WifiScanResult>> _safeWifiScan() async {
    if (!useWifi) return const [];
    try {
      return await wifiService.scan().timeout(const Duration(seconds: 4));
    } catch (_) {
      return const [];
    }
  }

  Future<MagnetometerEvidence?> _safeMagnetometer() async {
    if (!useMagnetometer) return null;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return magnetometer.readEvidence();
    } catch (_) {
      return null;
    }
  }

  Future<void> _scan() async {
    final c = camera;
    if (c == null || busy || !detector.isReady) return;
    setState(() => busy = true);
    try {
      final shot = await c.takePicture();
      final bytes = await shot.readAsBytes();
      final imageBytes = Uint8List.fromList(bytes);

      final results = enhanced
          ? await detector.detectBytesTiled(imageBytes)
          : await detector.detectBytes(imageBytes);
      final accepted = results
          .where((d) => d.confidence >= (TfliteDetector.acceptance[d.label] ?? 0.30))
          .toList();

      final opticalResult = reflection.analyze(imageBytes, accepted);

      // Run secondary sensors in parallel. They are supporting evidence only.
      final sensorResults = await Future.wait<dynamic>([
        _safeWifiScan(),
        _safeMagnetometer(),
      ]);
      final wifi = wifiService.evidence(sensorResults[0] as List<WifiScanResult>);
      final mag = sensorResults[1] as MagnetometerEvidence?;
      final fused = fusion.combine(
        detections: accepted,
        opticalSupport: opticalResult.suspicious,
        wifi: wifi,
        magnetometer: mag,
      );

      ScanHistory.instance.add(ScanRecord(
        time: DateTime.now(),
        detections: List<Detection>.unmodifiable(accepted),
        risk: fused.risk,
        optical: opticalResult.suspicious,
        image: imageBytes,
      ));

      if (mounted) {
        setState(() {
          resultImage = imageBytes;
          detections = fused.detections;
          optical = fused.opticalSupport;
          wifiEvidence = fused.wifi;
          magnetometerEvidence = fused.magnetometer;
          risk = fused.risk;
          busy = false;
          status = accepted.isEmpty
              ? 'No strong trained-model detection'
              : '${accepted.length} accepted visual detection(s)';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          status = 'Scan error: $e';
        });
      }
    }
  }

  void _reset() {
    setState(() {
      resultImage = null;
      detections = [];
      risk = null;
      optical = false;
      wifiEvidence = null;
      magnetometerEvidence = null;
      status = 'Ready — frame the room and tap AI SCAN';
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = camera;
    final showing = resultImage != null;
    final rr = risk;
    final score = rr?.score ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Camera Scan'),
        actions: [
          if (!showing)
            IconButton(
              onPressed: c == null ? null : _flash,
              icon: Icon(c?.value.flashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_off),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (showing)
                  Image.memory(resultImage!, fit: BoxFit.cover)
                else if (c != null && c.value.isInitialized)
                  CameraPreview(c)
                else
                  const Center(child: CircularProgressIndicator()),
                if (showing) DetectionOverlay(detections: detections),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: Card(
                    color: Colors.black.withValues(alpha: .80),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rr?.label ?? 'READY',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: score >= 55 ? Colors.redAccent : Colors.cyanAccent,
                            ),
                          ),
                          if (rr != null) Text('Score $score/100'),
                          Text(status),
                          const SizedBox(height: 4),
                          Text('Optical: ${optical ? 'supporting' : 'none'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('Wi-Fi: ${wifiEvidence?.networks.length ?? 0} APs • camera-like: ${wifiEvidence?.cameraLikeNetworks ?? 0}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('Magnetic: ${magnetometerEvidence == null ? 'unavailable' : '${magnetometerEvidence!.current.toStringAsFixed(1)} µT • x${magnetometerEvidence!.ratio.toStringAsFixed(2)}'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          if (rr != null && rr.evidence.isNotEmpty)
                            Text('Evidence: ${rr.evidence.join(' + ')}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              children: [
                if (!showing) ...[
                  Row(
                    children: [
                      const Expanded(child: Text('Enhanced small-object scan')),
                      Switch(value: enhanced, onChanged: busy ? null : (v) => setState(() => enhanced = v)),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(child: Text('Wi-Fi supporting scan')),
                      Switch(value: useWifi, onChanged: busy ? null : (v) => setState(() => useWifi = v)),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(child: Text('Magnetometer supporting scan')),
                      Switch(value: useMagnetometer, onChanged: busy ? null : (v) => setState(() => useMagnetometer = v)),
                    ],
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: showing || busy ? null : _scan,
                    icon: busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.center_focus_strong),
                    label: Text(busy ? 'SCANNING...' : 'AI SCAN'),
                  ),
                ),
                if (showing)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: _reset, child: const Text('SCAN AGAIN')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
