import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:image/image.dart' as img;
// Importa math para usar exp
import 'dart:math' as math;

class ImageClassifier {
  OrtSession? _session;
  List<String> _labels = ['Cat', 'Dog']; // Ajuste conforme suas classes
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Por enquanto, vamos simular a inicialização
      await Future.delayed(const Duration(milliseconds: 500));
      _isInitialized = true;

      print('Classificador simulado inicializado!');
      print('Classes disponíveis: $_labels');
    } catch (e) {
      print('Erro ao inicializar classificador: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> classifyImage(String imagePath) async {
    if (!_isInitialized) {
      throw Exception('Classificador não foi inicializado');
    }

    try {
      // Carrega a imagem
      final imageData = await rootBundle.load(imagePath);
      final imageBytes = imageData.buffer.asUint8List();

      // Decodifica e pré-processa a imagem
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Não foi possível decodificar a imagem');
      }

      // Simula processamento baseado no nome da imagem
      await Future.delayed(const Duration(milliseconds: 800));

      final imageName = imagePath.toLowerCase();
      List<double> mockPredictions;

      if (imageName.contains('cat')) {
        // Se é uma imagem de gato, maior probabilidade para gato
        mockPredictions = [
          0.85 + (math.Random().nextDouble() * 0.1),
          0.15 - (math.Random().nextDouble() * 0.1),
        ];
      } else if (imageName.contains('dog')) {
        // Se é uma imagem de cachorro, maior probabilidade para cachorro
        mockPredictions = [
          0.15 - (math.Random().nextDouble() * 0.1),
          0.85 + (math.Random().nextDouble() * 0.1),
        ];
      } else {
        // Classificação aleatória
        final random = math.Random().nextDouble();
        mockPredictions = [random, 1.0 - random];
      }

      // Processa resultado
      final result = _processMockOutput({
        'output': [mockPredictions],
      });

      print(
        'Classificação para $imagePath: ${result['predicted_class']} (${(result['confidence'] * 100).toStringAsFixed(1)}%)',
      );

      return result;
    } catch (e) {
      print('Erro na classificação: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _processMockOutput(Map<String, dynamic> outputs) {
    final mockPredictions = outputs['output'][0] as List<double>;

    // Encontra a classe com maior probabilidade
    double maxProb = mockPredictions[0];
    int maxIndex = 0;

    for (int i = 1; i < mockPredictions.length; i++) {
      if (mockPredictions[i] > maxProb) {
        maxProb = mockPredictions[i];
        maxIndex = i;
      }
    }

    // Aplica softmax para obter probabilidades
    final probabilities = _softmax(mockPredictions);

    return {
      'predicted_class': _labels[maxIndex],
      'confidence': probabilities[maxIndex],
      'all_probabilities': Map.fromIterables(_labels, probabilities),
    };
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    final expValues = logits.map((x) => math.exp(x - maxLogit)).toList();
    final sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((x) => x / sumExp).toList();
  }

  void dispose() {
    _session?.release();
    _isInitialized = false;
  }
}
