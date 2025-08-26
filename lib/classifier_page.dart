import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:object_classifier/logic.dart';
import 'package:image/image.dart' as img;

enum ClassifierState { initial, loading, success }

class ClassifierPage extends StatefulWidget {
  const ClassifierPage({super.key});

  @override
  State<ClassifierPage> createState() => _ClassifierPageState();
}

class _ClassifierPageState extends State<ClassifierPage> {
  
  Classifier? _classifier;

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String _prediction = "";


  ClassifierState _classifierState = ClassifierState.initial;

  @override
  void initState() {
    super.initState();

    _initializeClassifier();
  }


  Future<void> _initializeClassifier() async {
    final classifier = await Classifier.create();
    setState(() {
      _classifier = classifier;
    });
  }

  Future<void> _pickImage() async {

    if (_classifier == null) return;

    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final File imageFile = File(pickedFile.path);
    final img.Image? image = img.decodeImage(await imageFile.readAsBytes());

    if (image == null) return;


    setState(() {
      _imageFile = imageFile;
      _classifierState = ClassifierState.loading;
    });


    final prediction = _classifier!.predict(image);

    setState(() {
      _prediction = prediction;
      _classifierState = ClassifierState.success;
    });
  }

  Widget _buildUIForState() {
    switch (_classifierState) {
      case ClassifierState.initial:
        return const Text(
          'Pick an image to classify.',
          style: TextStyle(fontSize: 18),
        );
      case ClassifierState.loading:
        return const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Classifying...', style: TextStyle(fontSize: 18)),
          ],
        );
      case ClassifierState.success:
        return Text(
          'Prediction: $_prediction',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TFLite Image Classifier'),
      ),

      body: _classifier == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (_imageFile != null)
                    Container(
                      margin: const EdgeInsets.all(16),
                      constraints: const BoxConstraints(maxHeight: 350),
                      child: Image.file(_imageFile!),
                    )
                  else
                    Container(
                      height: 350,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(Icons.image_search,
                            size: 50, color: Colors.grey.shade400),
                      ),
                    ),
                  const SizedBox(height: 20),

                  _buildUIForState(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        tooltip: 'Pick Image',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}