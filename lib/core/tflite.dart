import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../schemas/result.dart';
import './image_handler.dart';

class TFLiteHandler {
  final String modelPath;
  final String labelsPath;

  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isModelLoaded = false;

  TFLiteHandler({required this.modelPath, required this.labelsPath});

  Future<void> loadModel() async {
    try {

      if (_isModelLoaded) {
        print('⚠️ Modelo já carregado. Reutilizando...');
        return;
      }

      _interpreter = await Interpreter.fromAsset(modelPath);

      if (_interpreter == null) {
        print('❌ Erro ao inicializar o interpretador');
        return;
      }

      print('✅ Modelo carregado com sucesso');

      final labelsData = await rootBundle.loadString(labelsPath);
      _labels = labelsData
          .split('\n')
          .where((label) => label.isNotEmpty)
          .toList();

      _isModelLoaded = true;

      // Informações do modelo para debug
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      print('✅ Modelo carregado com sucesso!');
      print('📥 Input shape: $inputShape');
      print('📤 Output shape: $outputShape');
      print('🏷️ Labels carregados: ${_labels!.length}');
    } catch (e) {
      print('❌ Erro ao carregar modelo: $e');
    }
  }

  Future<List<double>> classifyImage(String imagePath) async {
    if (!_isModelLoaded) {
      await loadModel();
    }
    if (_interpreter == null) {
      print('❌ Erro: Interprete não inicializado');
      return [];
    }
    
    try {
      final inputTensor = await ImageHandler.imageToTensor(
        imagePath,
        _interpreter!.getInputTensor(0).shape[2],
        _interpreter!.getInputTensor(0).shape[1],
      );

      final outputShape = _interpreter!.getOutputTensor(0).shape;
      print('📤 Output shape do modelo: $outputShape'); // Debug
      
      // ✅ CORREÇÃO: Cria output no formato correto [1, 2]
      final output = List.generate(
        outputShape[0], // Usa outputShape[0] = 1 (batch)
        (index) => List<double>.filled(outputShape[1], 0.0), // outputShape[1] = 2 (classes)
      );

      _interpreter!.run(inputTensor, output);

      final probabilities = _applySoftmax(output[0]);

      print('🎯 Probabilidades: $probabilities');
      return probabilities;
      
    } catch (e) {
      print('❌ Erro ao classificar imagem: $e');
      return [];
    }
  }

  Future<PredictionResult> classifyImageWithLabels(String imagePath) async {
    final probabilities = await classifyImage(imagePath);

    // Encontra a classe com maior probabilidade
    double maxProb = 0.0;
    int maxIndex = 0;

    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }

    final label = _labels != null && maxIndex < _labels!.length
        ? _labels![maxIndex]
        : 'Desconhecido';

    return PredictionResult(
      id: maxIndex,
      label: label,
      confidence: maxProb,
    );
  }




  /// Aplica função softmax para normalizar probabilidades
  List<double> _applySoftmax(List<double> logits) {
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    final expValues = logits.map((x) => math.exp(x - maxLogit)).toList();
    final sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((x) => x / sumExp).toList();
  }

  /// Retorna informações do modelo
  Map<String, dynamic> getModelInfo() {
    if (!_isModelLoaded) {
      return {'error': 'Modelo não inicializado'};
    }

    final inputShape = _interpreter!.getInputTensor(0).shape;
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    
    return {
      'input_shape': inputShape,
      'output_shape': outputShape,
      'labels_count': _labels?.length ?? 0,
      'labels': _labels,
    };
  }

  /// Libera recursos
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
    _isModelLoaded = false;
    print('🧹 Recursos do TFLite liberados');
  }

}
