import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

class MagnetometerEvidence {
  final double current;
  final double baseline;
  final double ratio;
  const MagnetometerEvidence({required this.current, required this.baseline, required this.ratio});
  bool get anomalous => ratio >= 1.45;
}

class MagnetometerService {
  StreamSubscription<MagnetometerEvent>? _sub;
  final _controller = StreamController<double>.broadcast();
  Stream<double> get magnitudeStream => _controller.stream;

  double _ema = 0;
  double _baseline = 0;

  void start() {
    _sub?.cancel();
    _sub = magnetometerEventStream(samplingPeriod: const Duration(milliseconds: 200)).listen((e) {
      final m = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      _ema = _ema == 0 ? m : (_ema * 0.85 + m * 0.15);
      _controller.add(_ema);
    }, onError: (Object _) {});
  }

  Future<double?> calibrate({Duration duration = const Duration(seconds: 2)}) async {
    start();
    final samples = <double>[];
    final sub = magnitudeStream.listen(samples.add);
    await Future<void>.delayed(duration);
    await sub.cancel();
    if (samples.isEmpty) return null;
    _baseline = samples.reduce((a, b) => a + b) / samples.length;
    return _baseline;
  }

  MagnetometerEvidence? readEvidence() {
    if (_baseline <= 0 || _ema <= 0) return null;
    return MagnetometerEvidence(
      current: _ema,
      baseline: _baseline,
      ratio: _ema / _baseline,
    );
  }

  double? get baseline => _baseline > 0 ? _baseline : null;
  double? get current => _ema > 0 ? _ema : null;

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
