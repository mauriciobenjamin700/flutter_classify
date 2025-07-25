Map<String, String> mockImages = {
  'cat1': 'assets/cat1.png',
  'cat2': 'assets/cat2.png',
  'dog1': 'assets/dog1.png',
  'dog2': 'assets/dog2.png',
};

class Constants {
  static const String classifyModel = 'assets/models/best_float16.tflite';
  static const String classifyLabels = 'assets/models/labels.txt';
  static const int classifyImageWidth = 224;  // ou 640 se seu modelo usar
  static const int classifyImageHeight = 224; // ou 640 se seu modelo usar
}