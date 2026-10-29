import 'package:flutter/material.dart';
import '../services/scan_history.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final records = ScanHistory.instance.items;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan History')),
      body: records.isEmpty
          ? const Center(child: Text('No scans saved in this session.'))
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final r = records[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(r.image, width: 64, height: 64, fit: BoxFit.cover),
                  ),
                  title: Text('${r.risk.label} • ${r.risk.score}/100'),
                  subtitle: Text('${r.time}\n${r.detections.length} visual detection(s) • Optical: ${r.optical ? 'supporting' : 'none'}'),
                  isThreeLine: true,
                );
              },
            ),
    );
  }
}
