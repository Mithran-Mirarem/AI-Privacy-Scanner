import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});
  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  String cameraStatus = 'Checking…';
  String modelStatus = 'Checking…';
  bool checking = false;

  @override
  void initState() {
    super.initState();
    check();
  }

  Future<void> check() async {
    if (checking) return;
    checking = true;
    if (mounted) setState(() {});
    try {
      final cameras = await availableCameras();
      cameraStatus = cameras.isEmpty ? 'No camera found' : '${cameras.length} camera(s) available';
    } catch (e) {
      cameraStatus = 'Camera error: $e';
    }
    try {
      final interpreter = await Interpreter.fromAsset('assets/models/privacy_scanner.tflite');
      final input = interpreter.getInputTensor(0);
      final output = interpreter.getOutputTensor(0);
      modelStatus = 'Model loaded • input ${input.shape} ${input.type} • output ${output.shape} ${output.type}';
      interpreter.close();
    } catch (e) {
      modelStatus = 'Model unavailable: $e';
    }
    checking = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diagnostics')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      ListTile(title: const Text('Camera'), subtitle: Text(cameraStatus), leading: const Icon(Icons.camera_alt)),
      ListTile(title: const Text('TFLite / LiteRT'), subtitle: Text(modelStatus), leading: const Icon(Icons.memory)),
      const Divider(),
      const Text('Required model asset:'),
      const SelectableText('assets/models/privacy_scanner.tflite'),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: checking ? null : check, icon: const Icon(Icons.refresh), label: Text(checking ? 'CHECKING…' : 'RUN DIAGNOSTICS')),
    ]),
  );
}
