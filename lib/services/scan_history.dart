import 'dart:typed_data';
import '../models/detection.dart';
import 'risk_engine.dart';

class ScanRecord {
  final DateTime time;
  final List<Detection> detections;
  final RiskResult risk;
  final bool optical;
  final Uint8List image;
  const ScanRecord({
    required this.time,
    required this.detections,
    required this.risk,
    required this.optical,
    required this.image,
  });
}

class ScanHistory {
  static final ScanHistory instance = ScanHistory._();
  ScanHistory._();
  final List<ScanRecord> items = [];

  void add(ScanRecord record) {
    items.insert(0, record);
    if (items.length > 20) items.removeLast();
  }
}
