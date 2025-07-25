
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

Future<Map<String, dynamic>?> classifyImage(String imagePath) async {
  // Inicializa o ambiente ONNX
  OrtEnv.instance.init();

  // Carrega o modelo ONNX dos assets
  final sessionOptions = OrtSessionOptions();
  const assetFileName = 'assets/models/best.onnx'; // Seu modelo
  final rawAssetFile = await rootBundle.load(assetFileName);
  final bytes = rawAssetFile.buffer.asUint8List();
  final session = OrtSession.fromBuffer(bytes, sessionOptions);

  // Carrega e pré-processa a imagem
  final imageBytes = await File(imagePath).readAsBytes();
  final image = img.decodeImage(imageBytes);
  if (image == null) return null;

  // Redimensiona a imagem para o tamanho esperado pelo modelo
  final resized = img.copyResize(image, width: 224, height: 224);
  final input = <double>[];

  // Forma CORRETA de acessar pixels usando iterador (conforme documentação)
  for (final pixel in resized) {
    // Normaliza os valores dos canais RGB (0-255 para 0.0-1.0)
    input.add(pixel.r / pixel.maxChannelValue); // Canal Red
    input.add(pixel.g / pixel.maxChannelValue); // Canal Green  
    input.add(pixel.b / pixel.maxChannelValue); // Canal Blue
  }

  // Cria o tensor de entrada
  final shape = [1, 224, 224, 3]; // Formato NHWC - ajuste conforme seu modelo
  final inputOrt = OrtValueTensor.createTensorWithDataList(input, shape);
  final inputs = {'input': inputOrt}; // Ajuste o nome conforme seu modelo
  final runOptions = OrtRunOptions();

  // Executa a inferência
  final outputs = await session.runAsync(runOptions, inputs);

  // Processa a saída
  final outputTensor = outputs?.first;
  if (outputTensor == null) return null; // Nenhum resultado retornado

  final tensorData = outputTensor.value as Float32List;
  final outputList = tensorData.cast<double>();


  // Encontra o índice da classe com maior confiança
  int classId = -1;
  double confidence = 0.0;
  classId = outputList.indexOf(outputList.reduce((a, b) => a > b ? a : b));
  confidence = outputList[classId];

  // Libera recursos
  inputOrt.release();
  runOptions.release();
  outputs?.forEach((element) => element?.release());
  session.release();
  sessionOptions.release();
  OrtEnv.instance.release();

  // Retorna o resultado com mapeamento de classes
  final classNames = ['cat', 'dog']; // Ajuste conforme suas classes
  final className = classId >= 0 && classId < classNames.length 
      ? classNames[classId] 
      : 'unknown';

  return {
    'id': classId,
    'label': className,
    'confidence': confidence,
    'all_probabilities': outputList,
  };
}
