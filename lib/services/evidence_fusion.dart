import '../models/detection.dart';
import 'risk_engine.dart';
import 'wifi_service.dart';
import 'magnetometer_service.dart';

class FusedScan {
  final List<Detection> detections;
  final RiskResult risk;
  final bool opticalSupport;
  final WifiEvidence wifi;
  final MagnetometerEvidence? magnetometer;
  const FusedScan({
    required this.detections,
    required this.risk,
    required this.opticalSupport,
    required this.wifi,
    required this.magnetometer,
  });
}

class EvidenceFusion {
  final RiskEngine riskEngine;
  const EvidenceFusion({this.riskEngine = const RiskEngine()});

  FusedScan combine({
    required List<Detection> detections,
    required bool opticalSupport,
    required WifiEvidence wifi,
    required MagnetometerEvidence? magnetometer,
  }) {
    final risk = riskEngine.evaluate(
      detections,
      opticalSupport: opticalSupport,
      magneticRatio: magnetometer?.ratio,
      cameraLikeWifiNetworks: wifi.cameraLikeNetworks,
    );
    return FusedScan(
      detections: detections,
      risk: risk,
      opticalSupport: opticalSupport,
      wifi: wifi,
      magnetometer: magnetometer,
    );
  }
}
