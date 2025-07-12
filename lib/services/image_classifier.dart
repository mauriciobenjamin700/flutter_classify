class ImageClassifierService {
  Future<Map<String, dynamic>> classifyImage(String imagePath) {
    // Simulate a delay for image classification
    return Future.delayed(Duration(seconds: 2), () {
      if (imagePath.length % 2 == 0) {
        return {
          'label': 'Cat',
          'confidence': 0.85,
        };
      }
      return {
        'label': 'Dog',
        'confidence': 0.75,
      };
    });
  }
}
