class PredictionResult {
  final int id;
  final String label;
  final double confidence;

  PredictionResult({
    required this.id,
    required this.label,
    required this.confidence,
  });

  @override
  String toString() {
    return 'PredictionResult(id: $id, confidence: $confidence, label: $label)';
  }
}