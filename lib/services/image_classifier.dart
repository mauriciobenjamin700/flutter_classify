class ImageClassifierService {
  Future<Map<String, dynamic>> classifyImage(String imagePath) async {

    if (imagePath.startsWith('assets/cat')) {
      return {
        'label': 'Cat',
        'confidence': 0.85,
      };
    }
    return {
      'label': 'Dog',
      'confidence': 0.75,
    };
  }
}