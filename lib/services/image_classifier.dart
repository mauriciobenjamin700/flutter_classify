import '../core/tflite.dart';
import '../core/constants.dart';

class ImageClassifierService {

  final TFLiteHandler _tflite = TFLiteHandler(
    modelPath: Constants.classifyModel,
    labelsPath: Constants.classifyLabels,
  );
  TFLiteHandler get tflite => _tflite;

  Future<Map<String, dynamic>> classifyImage(String imagePath) async {
    
    await tflite.loadModel();

    final output = await tflite.classifyImageWithLabels(imagePath);

    print('🔍 Resultado da classificação: ${output.toString()}');

    return {
      'label': output.label,
      'confidence': output.confidence,
    };
  }
}