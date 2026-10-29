class Detection {
  final int classId;
  final String label;
  final double confidence;
  final double left, top, right, bottom;
  const Detection({required this.classId, required this.label, required this.confidence,
    required this.left, required this.top, required this.right, required this.bottom});
}
