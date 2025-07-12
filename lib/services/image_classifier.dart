class ImageClassifierService {
  Map<String, dynamic> classifyImage(String imagePath) {

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