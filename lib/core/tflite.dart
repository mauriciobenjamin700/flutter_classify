import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../schemas/result.dart';
import './image_handler.dart';

/// Classe responsável pelo gerenciamento e execução de modelos TensorFlow Lite
/// para classificação de imagens.
///
/// Esta classe encapsula toda a lógica necessária para:
/// - Carregar modelos TFLite e arquivos de labels
/// - Executar inferência em imagens
/// - Processar e retornar resultados de classificação
class TFLiteHandler {
  /// Caminho para o arquivo do modelo TFLite
  final String modelPath;

  /// Caminho para o arquivo de labels/classes
  final String labelsPath;

  /// Instância do interpretador TensorFlow Lite
  Interpreter? _interpreter;

  /// Lista de labels/classes do modelo
  List<String>? _labels;

  /// Flag indicando se o modelo foi carregado com sucesso
  bool _isModelLoaded = false;

  /// Construtor da classe TFLiteHandler
  ///
  /// [modelPath] - Caminho para o arquivo .tflite do modelo
  /// [labelsPath] - Caminho para o arquivo .txt contendo os labels
  TFLiteHandler({required this.modelPath, required this.labelsPath});

  /// Carrega o modelo TensorFlow Lite e os arquivos de labels.
  ///
  /// Este método:
  /// - Verifica se o modelo já foi carregado para evitar recarregamento desnecessário
  /// - Carrega o modelo TFLite dos assets
  /// - Carrega e processa o arquivo de labels
  /// - Exibe informações de debug sobre o modelo
  ///
  /// Throws [Exception] se houver falha no carregamento
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

  /// Classifica uma imagem e retorna as probabilidades de cada classe.
  ///
  /// [imagePath] - Caminho para a imagem a ser classificada (asset ou arquivo local)
  ///
  /// Returns: Lista de probabilidades para cada classe (já normalizadas pelo modelo)
  /// Returns: Lista vazia em caso de erro
  ///
  /// Throws: Exception em caso de falha na classificação
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
      final output = List.generate(
        outputShape[0],
        (index) => List<double>.filled(outputShape[1], 0.0),
      );

      _interpreter!.run(inputTensor, output);

      // ✅ Usa valores diretos (modelo já aplica softmax)
      final probabilities = output[0];

      // 🎨 Log formatado com 2 casas decimais
      final formattedProbs = probabilities
          .map((prob) => '${(prob * 100).toStringAsFixed(2)}%')
          .toList();

      print('🎯 Probabilidades: $formattedProbs');
      return probabilities;
    } catch (e) {
      print('❌ Erro ao classificar imagem: $e');
      return [];
    }
  }

  /// Classifica uma imagem e retorna o resultado completo com label e confiança.
  ///
  /// Este método combina a classificação com o processamento dos resultados,
  /// retornando a classe mais provável junto com sua confiança.
  ///
  /// [imagePath] - Caminho para a imagem a ser classificada
  ///
  /// Returns: [PredictionResult] contendo ID, label e confiança da predição
  /// Returns: Resultado com "Desconhecido" em caso de erro
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

    return PredictionResult(id: maxIndex, label: label, confidence: maxProb);
  }

  /// Retorna informações detalhadas sobre o modelo carregado.
  ///
  /// Inclui informações como:
  /// - Dimensões de entrada e saída do modelo
  /// - Número de labels/classes
  /// - Lista completa de labels
  ///
  /// Returns: Map com informações do modelo ou erro se não inicializado
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

  /// Libera todos os recursos utilizados pelo interpretador TensorFlow Lite.
  ///
  /// Este método deve ser chamado quando o classificador não for mais utilizado
  /// para evitar vazamentos de memória. Após chamar este método, é necessário
  /// recarregar o modelo para utilizá-lo novamente.
  ///
  /// Limpa:
  /// - Instância do interpretador
  /// - Lista de labels
  /// - Flag de modelo carregado
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
    _isModelLoaded = false;
    print('🧹 Recursos do TFLite liberados');
  }
}
