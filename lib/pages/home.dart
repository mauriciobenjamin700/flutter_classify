import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../widgets/image_gallery.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  String? _selectedImage;

  void _onImageSelected(String ImagePath) {
    setState(() {
      _selectedImage = ImagePath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Page')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.0),
            margin: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              _selectedImage != null
                  ? 'Selected Image: $_selectedImage'
                  : 'No image selected',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _selectedImage != null ? Colors.blue.shade800 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ImageGallery(
              imagePaths: [
                mockImages['cat1']!,
                mockImages['cat2']!,
                mockImages['dog1']!,
                mockImages['dog2']!,
              ],
              onImageTap: _onImageSelected,
            ),
          )
        ]
      ),
    );
  }
}
