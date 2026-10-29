import '../models/detection.dart';

class RiskResult {
  final String label;
  final int score;
  final List<String> evidence;
  const RiskResult(this.label, this.score, {this.evidence = const []});
}

class RiskEngine {
  const RiskEngine();
  static const suspicious = {'hidden_camera', 'spy_camera', 'spy_lens'};
  static const weights = {
    'camera': 0.30,
    'cctv': 0.45,
    'hidden_camera': 0.95,
    'spy_camera': 0.90,
    'spy_lens': 0.85,
  };

  RiskResult evaluate(
    List<Detection> detections, {
    required bool opticalSupport,
    double? magneticRatio,
    int cameraLikeWifiNetworks = 0,
  }) {
    final evidence = <String>[];
    final suspiciousDetections = detections.where((d) => suspicious.contains(d.label)).toList();

    if (opticalSupport) evidence.add('optical highlight');
    if (cameraLikeWifiNetworks > 0) evidence.add('$cameraLikeWifiNetworks camera-like Wi-Fi SSID(s)');
    if (magneticRatio != null && magneticRatio >= 1.45) evidence.add('magnetic anomaly');

    if (suspiciousDetections.isEmpty) {
      final n = detections
          .where((d) => d.label == 'camera' || d.label == 'cctv')
          .map((d) => d.confidence * (weights[d.label] ?? 0.25))
          .fold<double>(0, (a, b) => a > b ? a : b);
      final score = (n * 30).round();
      return RiskResult(score >= 20 ? 'LOW CAMERA-LIKE FINDING' : 'NO STRONG FINDING', score,
          evidence: evidence);
    }

    var best = suspiciousDetections
        .map((d) => d.confidence * (weights[d.label] ?? 0.0))
        .fold<double>(0, (a, b) => a > b ? a : b);

    // A single visual hidden-camera prediction is deliberately capped until
    // another independent signal supports it. This reduces false positives
    // from ordinary smartphone camera modules and visually similar objects.
    final hasIndependentSupport = opticalSupport ||
        (magneticRatio != null && magneticRatio >= 1.45) ||
        cameraLikeWifiNetworks > 0;
    if (!hasIndependentSupport && suspiciousDetections.any((d) => d.label == 'hidden_camera')) {
      best = best.clamp(0.0, 0.54);
      evidence.add('visual-only hidden-camera candidate');
    }

    if (opticalSupport) best += 0.08;
    if (magneticRatio != null && magneticRatio >= 1.45) best += 0.06;
    if (cameraLikeWifiNetworks > 0) best += 0.04;
    best = best.clamp(0.0, 1.0);

    final score = (best * 100).round();
    if (score >= 80) return RiskResult('HIGH SUSPICION', score, evidence: evidence);
    if (score >= 55) return RiskResult('MEDIUM SUSPICION', score, evidence: evidence);
    if (score >= 35) return RiskResult('LOW SUSPICION', score, evidence: evidence);
    return RiskResult('NO STRONG FINDING', score, evidence: evidence);
  }
}
