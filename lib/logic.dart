import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Classifier {
  Interpreter? _interpreter;
  List<String>? _labels;

  Classifier._();

  static Future<Classifier> create() async {
    final classifier = Classifier._();
    await classifier._loadModel();
    return classifier;
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/mobilenetv2.tflite');
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n');
    } catch (e) {
      print('Error loading model or labels: $e');
    }
  }

  String predict(img.Image image) {
    if (_interpreter == null || _labels == null) {
      return "Error: Classifier not ready";
    }


    final input = _preprocessInput(image).reshape([1, 224, 224, 3]);


    final output = List.filled(1 * 1001, 0.0).reshape([1, 1001]);


    _interpreter!.run(input, output);


    final outputList = output[0] as List<double>;
    double maxScore = 0.0;
    int maxIndex = -1;

    for (int i = 0; i < outputList.length; i++) {
      if (outputList[i] > maxScore) {
        maxScore = outputList[i];
        maxIndex = i;
      }
    }

    return _labels![maxIndex];
  }

  Float32List _preprocessInput(img.Image image) {

    final resizedImage = img.copyResize(image, width: 224, height: 224);


    final preprocessedList = Float32List(1 * 224 * 224 * 3);
    int offset = 0;


    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        final pixel = resizedImage.getPixel(x, y);

        preprocessedList[offset++] = pixel.r / 255.0;
        preprocessedList[offset++] = pixel.g / 255.0;
        preprocessedList[offset++] = pixel.b / 255.0;
      }
    }
    
    return preprocessedList;
  }
}