// // file: face_recognition_service.dart

// import 'dart:io';
// import 'dart:math';
// import 'package:image/image.dart' as img;
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter/material.dart';

// class FaceRecognitionService {
//   static const double THRESHOLD = 0.7;
//   static const int INPUT_SIZE = 112;
//   static const int OUTPUT_SIZE = 128;
//   static const double MIN_FACE_PERCENTAGE = 0.15;
//   static const double MAX_FACE_PERCENTAGE = 0.65;
//   static const double MAX_HEAD_ROTATION = 15.0;

//   Interpreter? _interpreter;
//   late FaceDetector _faceDetector;
//   bool _isInitialized = false;

//   bool get isInitialized => _isInitialized;

//   Future<void> initialize() async {
//     if (_isInitialized) return;

//     try {
//       print('Initializing FaceRecognitionService...');

//       final options = InterpreterOptions()..threads = 4;

//       _interpreter = await Interpreter.fromAsset(
//         'assets/MobileFaceNet.tflite',
//         options: options,
//       );

//       _faceDetector = GoogleMlKit.vision.faceDetector(
//         FaceDetectorOptions(
//           enableLandmarks: true,
//           enableClassification: true,
//           enableTracking: true,
//           minFaceSize: 0.15,
//           performanceMode: FaceDetectorMode.accurate,
//         ),
//       );

//       if (_interpreter != null) {
//         var inputShape = _interpreter!.getInputTensor(0).shape;
//         var outputShape = _interpreter!.getOutputTensor(0).shape;
//         print('Model input shape: $inputShape');
//         print('Model output shape: $outputShape');
//         _isInitialized = true;
//         print('FaceRecognitionService initialized successfully');
//       } else {
//         throw Exception('Failed to load TensorFlow Lite model');
//       }
//     } catch (e) {
//       print('Error initializing FaceRecognitionService: $e');
//       _isInitialized = false;
//       rethrow;
//     }
//   }

//   Future<FaceDetectionResult> detectFace(File imageFile) async {
//     if (!_isInitialized) {
//       throw Exception('FaceRecognitionService is not initialized');
//     }
//     try {
//       final inputImage = InputImage.fromFile(imageFile);
//       final faces = await _faceDetector.processImage(inputImage);

//       if (faces.isEmpty) {
//         print('No face detected');
//         return FaceDetectionResult(
//             isValid: false,
//             message: 'No face detected. Please look at the camera.',
//             face: null);
//       }

//       // Get the first detected face
//       final face = faces.first;

//       // Calculate face visibility percentage
//       final imageSize = await _getImageSize(imageFile);
//       final faceArea = face.boundingBox.width * face.boundingBox.height;
//       final imageArea = imageSize.width * imageSize.height;
//       final facePercentage = faceArea / imageArea;

//       // Check face position and size requirements
//       final positionValidation = _validateFacePosition(face, imageSize);

//       // Debug information
//       print('Face bounds: ${face.boundingBox}');
//       print('Face landmarks detected: ${face.landmarks.length}');
//       print(
//           'Face percentage of image: ${(facePercentage * 100).toStringAsFixed(2)}%');
//       print('Face position validation: $positionValidation');

//       if (facePercentage < MIN_FACE_PERCENTAGE) {
//         return FaceDetectionResult(
//             isValid: false,
//             message: 'Please move closer to the camera',
//             face: face);
//       }

//       if (facePercentage > MAX_FACE_PERCENTAGE) {
//         return FaceDetectionResult(
//             isValid: false,
//             message: 'Please move away from the camera',
//             face: face);
//       }

//       if (!positionValidation.isValid) {
//         return FaceDetectionResult(
//             isValid: false, message: positionValidation.message, face: face);
//       }

//       // Check head rotation
//       if (face.headEulerAngleY != null &&
//           face.headEulerAngleY!.abs() > MAX_HEAD_ROTATION) {
//         return FaceDetectionResult(
//             isValid: false,
//             message: 'Please face directly towards the camera',
//             face: face);
//       }

//       if (face.headEulerAngleZ != null &&
//           face.headEulerAngleZ!.abs() > MAX_HEAD_ROTATION) {
//         return FaceDetectionResult(
//             isValid: false,
//             message: 'Please keep your head straight',
//             face: face);
//       }

//       // Validation criteria
//       bool meetsRequirements = face.landmarks.length >= 3 &&
//           positionValidation.isValid &&
//           facePercentage >= MIN_FACE_PERCENTAGE &&
//           facePercentage <= MAX_FACE_PERCENTAGE;

//       return FaceDetectionResult(
//           isValid: meetsRequirements,
//           message: meetsRequirements
//               ? 'Face detected successfully'
//               : 'Please adjust your position',
//           face: face);
//     } catch (e) {
//       print('Error during face detection: $e');
//       return FaceDetectionResult(
//           isValid: false, message: 'Error during face detection', face: null);
//     }
//   }

//   FacePositionValidation _validateFacePosition(Face face, Size imageSize) {
//     final rect = face.boundingBox;

//     // Calculate center of the face
//     final faceCenterX = rect.center.dx;
//     final faceCenterY = rect.center.dy;

//     // Calculate acceptable ranges for face center (middle 60% of image)
//     final minX = imageSize.width * 0.2;
//     final maxX = imageSize.width * 0.8;
//     final minY = imageSize.height * 0.2;
//     final maxY = imageSize.height * 0.8;

//     String message = '';

//     if (faceCenterX < minX) {
//       message = 'Move your face right';
//     } else if (faceCenterX > maxX) {
//       message = 'Move your face left';
//     }

//     if (faceCenterY < minY) {
//       message = message.isEmpty ? 'Move your face down' : '$message and down';
//     } else if (faceCenterY > maxY) {
//       message = message.isEmpty ? 'Move your face up' : '$message and up';
//     }

//     bool isCentered = faceCenterX >= minX &&
//         faceCenterX <= maxX &&
//         faceCenterY >= minY &&
//         faceCenterY <= maxY;

//     return FacePositionValidation(
//         isValid: isCentered,
//         message: message.isEmpty ? 'Face is well positioned' : message);
//   }

//   Future<Size> _getImageSize(File imageFile) async {
//     final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
//     if (image == null) throw Exception('Failed to decode image');
//     return Size(image.width.toDouble(), image.height.toDouble());
//   }

//   Future<List<double>> getFaceEmbedding(File imageFile) async {
//     if (!_isInitialized || _interpreter == null) {
//       throw Exception('FaceRecognitionService is not initialized');
//     }

//     try {
//       // First validate the face
//       final detectionResult = await detectFace(imageFile);
//       if (!detectionResult.isValid) {
//         throw Exception('Invalid face detected: ${detectionResult.message}');
//       }

//       var bytes = await imageFile.readAsBytes();
//       var image = img.decodeImage(bytes);
//       if (image == null) throw Exception('Failed to decode image');

//       var resizedImage =
//           img.copyResize(image, width: INPUT_SIZE, height: INPUT_SIZE);
//       var input = _imageToByteListFloat32(resizedImage);

//       var outputShape = _interpreter!.getOutputTensor(0).shape;
//       var outputBuffer = List.generate(
//         outputShape[0],
//         (_) => List<double>.filled(outputShape[1], 0),
//       );

//       _interpreter!.run(input, outputBuffer);

//       var flattened = outputBuffer.expand((list) => list).toList();

//       if (flattened.length != OUTPUT_SIZE) {
//         print(
//             'Warning: Output size mismatch. Expected $OUTPUT_SIZE, got ${flattened.length}');
//       }

//       return flattened;
//     } catch (e) {
//       print('Error getting face embedding: $e');
//       rethrow;
//     }
//   }

//   List<List<List<List<double>>>> _imageToByteListFloat32(img.Image image) {
//     var convertedBytes = List.generate(
//       1,
//       (i) => List.generate(
//         INPUT_SIZE,
//         (y) => List.generate(
//           INPUT_SIZE,
//           (x) {
//             var pixel = image.getPixel(x, y);
//             return [
//               (pixel.r.toDouble() - 127.5) / 128,
//               (pixel.g.toDouble() - 127.5) / 128,
//               (pixel.b.toDouble() - 127.5) / 128,
//             ];
//           },
//         ),
//       ),
//     );
//     return convertedBytes;
//   }

//   double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
//     if (embedding1.length != embedding2.length) {
//       print(
//           'Warning: Embedding length mismatch: ${embedding1.length} vs ${embedding2.length}');
//       var minLength = min(embedding1.length, embedding2.length);
//       embedding1 = embedding1.sublist(0, minLength);
//       embedding2 = embedding2.sublist(0, minLength);
//     }

//     double dotProduct = 0.0;
//     double norm1 = 0.0;
//     double norm2 = 0.0;

//     for (int i = 0; i < embedding1.length; i++) {
//       dotProduct += embedding1[i] * embedding2[i];
//       norm1 += embedding1[i] * embedding1[i];
//       norm2 += embedding2[i] * embedding2[i];
//     }

//     return dotProduct / (sqrt(norm1) * sqrt(norm2));
//   }

//   void dispose() {
//     _interpreter?.close();
//     _faceDetector.close();
//     _isInitialized = false;
//   }
// }

// class FaceDetectionResult {
//   final bool isValid;
//   final String message;
//   final Face? face;

//   FaceDetectionResult({
//     required this.isValid,
//     required this.message,
//     this.face,
//   });
// }

// class FacePositionValidation {
//   final bool isValid;
//   final String message;

//   FacePositionValidation({
//     required this.isValid,
//     required this.message,
//   });
// }

// import 'dart:io';
// import 'dart:math';
// import 'package:image/image.dart' as img;
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter/material.dart';

// class FaceRecognitionService {
//   static const double THRESHOLD = 0.7;
//   static const int INPUT_SIZE = 112;
//   static const int OUTPUT_SIZE = 128;
//   static const double MIN_FACE_PERCENTAGE = 0.15;
//   static const double MAX_FACE_PERCENTAGE = 0.65;
//   static const double MAX_HEAD_ROTATION = 15.0;

//   Interpreter? _interpreter;
//   late FaceDetector _faceDetector;
//   bool _isInitialized = false;

//   bool get isInitialized => _isInitialized;

//   Future<void> initialize() async {
//     if (_isInitialized) return;

//     try {
//       print('Initializing FaceRecognitionService...');

//       final options = InterpreterOptions()..threads = 4;

//       _interpreter = await Interpreter.fromAsset(
//         'assets/MobileFaceNet.tflite',
//         options: options,
//       );

//       _faceDetector = GoogleMlKit.vision.faceDetector(
//         FaceDetectorOptions(
//           enableLandmarks: true,
//           enableClassification: true,
//           enableTracking: true,
//           minFaceSize: 0.15,
//           performanceMode: FaceDetectorMode.accurate,
//         ),
//       );

//       if (_interpreter != null) {
//         var inputShape = _interpreter!.getInputTensor(0).shape;
//         var outputShape = _interpreter!.getOutputTensor(0).shape;
//         print('Model input shape: $inputShape');
//         print('Model output shape: $outputShape');
//         _isInitialized = true;
//         print('FaceRecognitionService initialized successfully');
//       } else {
//         throw Exception('Failed to load TensorFlow Lite model');
//       }
//     } catch (e) {
//       print('Error initializing FaceRecognitionService: $e');
//       _isInitialized = false;
//       rethrow;
//     }
//   }

//   Future<FaceDetectionResult> detectFace(File imageFile) async {
//     if (!_isInitialized) {
//       throw Exception('FaceRecognitionService is not initialized');
//     }
//     try {
//       final inputImage = InputImage.fromFile(imageFile);
//       final faces = await _faceDetector.processImage(inputImage);

//       if (faces.isEmpty) {
//         print('No face detected');
//         return FaceDetectionResult(
//             isValid: false,
//             message: 'No face detected. Please look at the camera.',
//             face: null);
//       }

//       // Get the first detected face
//       final face = faces.first;

//       // Calculate face visibility percentage
//       final imageSize = await _getImageSize(imageFile);
//       final faceArea = face.boundingBox.width * face.boundingBox.height;
//       final imageArea = imageSize.width * imageSize.height;
//       final facePercentage = faceArea / imageArea;

//       // Check face position and size requirements
//       final positionValidation = _validateFacePosition(face, imageSize);

//       // Debug information
//       print('Face bounds: ${face.boundingBox}');
//       print('Face landmarks detected: ${face.landmarks.length}');
//       print(
//           'Face percentage of image: ${(facePercentage * 100).toStringAsFixed(2)}%');
//       print('Face position validation: $positionValidation');

//       if (facePercentage < MIN_FACE_PERCENTAGE) {
//         return FaceDetectionResult(
//             isValid: false,
//             message: 'Please move closer to the camera',
//             face: face);
//       }

//       if (facePercentage > MAX_FACE_PERCENTAGE) {
//         return FaceDetectionResult(
//             isValid: false,
//             message: 'Please move away from the camera',
//             face: face);
//       }

//       if (!positionValidation.isValid) {
//         return FaceDetectionResult(
//             isValid: false, message: positionValidation.message, face: face);
//       }

//       // Check head rotation
//       if (face.headEulerAngleY != null &&
//           face.headEulerAngleY!.abs() > MAX_HEAD_ROTATION) {
//         return FaceDetectionResult(
//             isValid: false,
//             message: 'Please face directly towards the camera',
//             face: face);
//       }

//       if (face.headEulerAngleZ != null &&
//           face.headEulerAngleZ!.abs() > MAX_HEAD_ROTATION) {
//         return FaceDetectionResult(
//             isValid: false,
//             message: 'Please keep your head straight',
//             face: face);
//       }

//       // Validation criteria
//       bool meetsRequirements = face.landmarks.length >= 3 &&
//           positionValidation.isValid &&
//           facePercentage >= MIN_FACE_PERCENTAGE &&
//           facePercentage <= MAX_FACE_PERCENTAGE;

//       return FaceDetectionResult(
//           isValid: meetsRequirements,
//           message: meetsRequirements
//               ? 'Face detected successfully'
//               : 'Please adjust your position',
//           face: face);
//     } catch (e) {
//       print('Error during face detection: $e');
//       return FaceDetectionResult(
//           isValid: false, message: 'Error during face detection', face: null);
//     }
//   }

//   FacePositionValidation _validateFacePosition(Face face, Size imageSize) {
//     final rect = face.boundingBox;

//     // Calculate center of the face
//     final faceCenterX = rect.center.dx;
//     final faceCenterY = rect.center.dy;

//     // Calculate acceptable ranges for face center (middle 60% of image)
//     final minX = imageSize.width * 0.2;
//     final maxX = imageSize.width * 0.8;
//     final minY = imageSize.height * 0.2;
//     final maxY = imageSize.height * 0.8;

//     String message = '';

//     if (faceCenterX < minX) {
//       message = 'Move your face right';
//     } else if (faceCenterX > maxX) {
//       message = 'Move your face left';
//     }

//     if (faceCenterY < minY) {
//       message = message.isEmpty ? 'Move your face down' : '$message and down';
//     } else if (faceCenterY > maxY) {
//       message = message.isEmpty ? 'Move your face up' : '$message and up';
//     }

//     bool isCentered = faceCenterX >= minX &&
//         faceCenterX <= maxX &&
//         faceCenterY >= minY &&
//         faceCenterY <= maxY;

//     return FacePositionValidation(
//         isValid: isCentered,
//         message: message.isEmpty ? 'Face is well positioned' : message);
//   }

//   Future<Size> _getImageSize(File imageFile) async {
//     final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
//     if (image == null) throw Exception('Failed to decode image');
//     return Size(image.width.toDouble(), image.height.toDouble());
//   }

//   // Advanced Augmentation and Embedding Extraction
//   Future<List<double>> getFaceEmbedding(File imageFile) async {
//     if (!_isInitialized || _interpreter == null) {
//       throw Exception('FaceRecognitionService is not initialized');
//     }

//     try {
//       // First validate the face
//       final detectionResult = await detectFace(imageFile);
//       if (!detectionResult.isValid) {
//         throw Exception('Invalid face detected: ${detectionResult.message}');
//       }

//       var bytes = await imageFile.readAsBytes();
//       var image = img.decodeImage(bytes);
//       if (image == null) throw Exception('Failed to decode image');

//       // Apply augmentations: rotation, brightness, blur
//       List<img.Image> augmentedImages = _augmentImage(image);

//       // Extract embeddings for each augmented image
//       List<double> embeddings = [];
//       for (var augmentedImage in augmentedImages) {
//         var embedding = await _extractEmbeddingFromImage(augmentedImage);
//         embeddings
//             .addAll(embedding); // Storing all embeddings in a combined list
//       }

//       return embeddings;
//     } catch (e) {
//       print('Error getting face embedding: $e');
//       rethrow;
//     }
//   }

//   List<img.Image> _augmentImage(img.Image originalImage) {
//     List<img.Image> augmentedImages = [];

//     // Add original image to list
//     augmentedImages.add(originalImage);

//     // Rotation augmentation
//     augmentedImages.add(img.copyRotate(originalImage, angle: 5));
//     augmentedImages.add(img.copyRotate(originalImage, angle: -5));

//     // Brightness augmentation
//     augmentedImages.add(_adjustBrightness(originalImage, 30));
//     augmentedImages.add(_adjustBrightness(originalImage, -30));

//     // Gaussian blur augmentation
//     //augmentedImages.add(applyGaussianBlur(originalImage));
//     return augmentedImages;
//   }

//   img.Image _adjustBrightness(img.Image image, int amount) {
//     var brightened = img.Image.from(image);
//     for (var y = 0; y < brightened.height; y++) {
//       for (var x = 0; x < brightened.width; x++) {
//         var pixel = brightened.getPixel(x, y);
//         var r = (pixel.r + amount).clamp(0, 255);
//         var g = (pixel.g + amount).clamp(0, 255);
//         var b = (pixel.b + amount).clamp(0, 255);
//         brightened.setPixelRgba(x, y, r, g, b, pixel.a);
//       }
//     }
//     return brightened;
//   }

//   Future<List<double>> _extractEmbeddingFromImage(img.Image image) async {
//     // Resize the image to the required input size
//     var resizedImage =
//         img.copyResize(image, width: INPUT_SIZE, height: INPUT_SIZE);
//     var input = _imageToByteListFloat32(resizedImage);

//     // Prepare output tensor
//     var outputShape = _interpreter!.getOutputTensor(0).shape;
//     var outputBuffer = List.generate(
//       outputShape[0],
//       (_) => List<double>.filled(outputShape[1], 0),
//     );

//     _interpreter!.run(input, outputBuffer);

//     // Flatten the result into a single list
//     return outputBuffer.expand((list) => list).toList();
//   }

//   List<List<List<List<double>>>> _imageToByteListFloat32(img.Image image) {
//     var convertedBytes = List.generate(
//       1,
//       (i) => List.generate(
//         INPUT_SIZE,
//         (y) => List.generate(
//           INPUT_SIZE,
//           (x) {
//             var pixel = image.getPixel(x, y);
//             return [
//               (pixel.r.toDouble() - 127.5) / 128,
//               (pixel.g.toDouble() - 127.5) / 128,
//               (pixel.b.toDouble() - 127.5) / 128,
//             ];
//           },
//         ),
//       ),
//     );
//     return convertedBytes;
//   }

//   double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
//     if (embedding1.length != embedding2.length) {
//       print(
//           'Warning: Embedding length mismatch: ${embedding1.length} vs ${embedding2.length}');
//       var minLength = min(embedding1.length, embedding2.length);
//       embedding1 = embedding1.sublist(0, minLength);
//       embedding2 = embedding2.sublist(0, minLength);
//     }

//     double dotProduct = 0.0;
//     double norm1 = 0.0;
//     double norm2 = 0.0;

//     for (int i = 0; i < embedding1.length; i++) {
//       dotProduct += embedding1[i] * embedding2[i];
//       norm1 += embedding1[i] * embedding1[i];
//       norm2 += embedding2[i] * embedding2[i];
//     }

//     return dotProduct / (sqrt(norm1) * sqrt(norm2));
//   }

//   void dispose() {
//     _interpreter?.close();
//     _faceDetector.close();
//     _isInitialized = false;
//   }
// }

// class FaceDetectionResult {
//   final bool isValid;
//   final String message;
//   final Face? face;

//   FaceDetectionResult({
//     required this.isValid,
//     required this.message,
//     this.face,
//   });
// }

// class FacePositionValidation {
//   final bool isValid;
//   final String message;

//   FacePositionValidation({
//     required this.isValid,
//     required this.message,
//   });
// }

// import 'dart:io';
// import 'dart:math';
// import 'dart:ui';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:image/image.dart' as img;
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';

// class FaceRecognitionService {
//   static const double THRESHOLD =
//       0.92; // Increased threshold for single user case
//   static const double UNKNOWN_THRESHOLD = 0.85; // You can adjust this threshold
//   static const int INPUT_SIZE = 112;
//   static const int OUTPUT_SIZE = 128;
//   static const double MIN_FACE_PERCENTAGE = 0.15;
//   static const double MAX_FACE_PERCENTAGE = 0.65;
//   static const double MAX_HEAD_ROTATION = 15.0;

//   Interpreter? _interpreter;
//   late FaceDetector _faceDetector;
//   bool _isInitialized = false;

//   bool get isInitialized => _isInitialized;

//   Future<void> initialize() async {
//     if (_isInitialized) return;

//     try {
//       print('Initializing FaceRecognitionService...');

//       final options = InterpreterOptions()..threads = 4;

//       _interpreter = await Interpreter.fromAsset(
//         'assets/MobileFaceNet.tflite',
//         options: options,
//       );

//       _faceDetector = GoogleMlKit.vision.faceDetector(
//         FaceDetectorOptions(
//           enableLandmarks: true,
//           enableClassification: true,
//           enableTracking: true,
//           minFaceSize: 0.15,
//           performanceMode: FaceDetectorMode.accurate,
//         ),
//       );

//       if (_interpreter != null) {
//         var inputShape = _interpreter!.getInputTensor(0).shape;
//         var outputShape = _interpreter!.getOutputTensor(0).shape;
//         print('Model input shape: $inputShape');
//         print('Model output shape: $outputShape');
//         _isInitialized = true;
//         print('FaceRecognitionService initialized successfully');
//       } else {
//         throw Exception('Failed to load TensorFlow Lite model');
//       }
//     } catch (e) {
//       print('Error initializing FaceRecognitionService: $e');
//       _isInitialized = false;
//       rethrow;
//     }
//   }

//   Future<FaceDetectionResult> detectFace(File imageFile) async {
//     if (!_isInitialized) {
//       throw Exception('FaceRecognitionService is not initialized');
//     }
//     try {
//       final inputImage = InputImage.fromFile(imageFile);
//       final faces = await _faceDetector.processImage(inputImage);

//       if (faces.isEmpty) {
//         print('No face detected');
//         return FaceDetectionResult(
//             isValid: false,
//             message: 'No face detected. Please look at the camera.',
//             face: null);
//       }

//       // Get the first detected face
//       final face = faces.first;

//       // Calculate face visibility percentage
//       final imageSize = await _getImageSize(imageFile);
//       final faceArea = face.boundingBox.width * face.boundingBox.height;
//       final imageArea = imageSize.width * imageSize.height;
//       final facePercentage = faceArea / imageArea;

//       // Check face position and size requirements
//       final positionValidation = _validateFacePosition(face, imageSize);

//       // Debug information
//       print('Face bounds: ${face.boundingBox}');
//       print('Face landmarks detected: ${face.landmarks.length}');
//       print(
//           'Face percentage of image: ${(facePercentage * 100).toStringAsFixed(2)}%');
//       print('Face position validation: $positionValidation');

//       if (facePercentage < MIN_FACE_PERCENTAGE) {
//         return FaceDetectionResult(
//             isValid: false,
//             message: 'Please move closer to the camera',
//             face: face);
//       }

//       if (facePercentage > MAX_FACE_PERCENTAGE) {
//         return FaceDetectionResult(
//             isValid: false,
//             message: 'Please move away from the camera',
//             face: face);
//       }

//       if (!positionValidation.isValid) {
//         return FaceDetectionResult(
//             isValid: false, message: positionValidation.message, face: face);
//       }

//       // Check head rotation
//       if (face.headEulerAngleY != null &&
//           face.headEulerAngleY!.abs() > MAX_HEAD_ROTATION) {
//         return FaceDetectionResult(
//             isValid: false,
//             message: 'Please face directly towards the camera',
//             face: face);
//       }

//       if (face.headEulerAngleZ != null &&
//           face.headEulerAngleZ!.abs() > MAX_HEAD_ROTATION) {
//         return FaceDetectionResult(
//             isValid: false,
//             message: 'Please keep your head straight',
//             face: face);
//       }

//       // Validation criteria
//       bool meetsRequirements = face.landmarks.length >= 3 &&
//           positionValidation.isValid &&
//           facePercentage >= MIN_FACE_PERCENTAGE &&
//           facePercentage <= MAX_FACE_PERCENTAGE;

//       return FaceDetectionResult(
//           isValid: meetsRequirements,
//           message: meetsRequirements
//               ? 'Face detected successfully'
//               : 'Please adjust your position',
//           face: face);
//     } catch (e) {
//       print('Error during face detection: $e');
//       return FaceDetectionResult(
//           isValid: false, message: 'Error during face detection', face: null);
//     }
//   }

//   FacePositionValidation _validateFacePosition(Face face, Size imageSize) {
//     final rect = face.boundingBox;

//     // Calculate center of the face
//     final faceCenterX = rect.center.dx;
//     final faceCenterY = rect.center.dy;

//     // Calculate acceptable ranges for face center (middle 60% of image)
//     final minX = imageSize.width * 0.2;
//     final maxX = imageSize.width * 0.8;
//     final minY = imageSize.height * 0.2;
//     final maxY = imageSize.height * 0.8;

//     String message = '';

//     if (faceCenterX < minX) {
//       message = 'Move your face right';
//     } else if (faceCenterX > maxX) {
//       message = 'Move your face left';
//     }

//     if (faceCenterY < minY) {
//       message = message.isEmpty ? 'Move your face down' : '$message and down';
//     } else if (faceCenterY > maxY) {
//       message = message.isEmpty ? 'Move your face up' : '$message and up';
//     }

//     bool isCentered = faceCenterX >= minX &&
//         faceCenterX <= maxX &&
//         faceCenterY >= minY &&
//         faceCenterY <= maxY;

//     return FacePositionValidation(
//         isValid: isCentered,
//         message: message.isEmpty ? 'Face is well positioned' : message);
//   }

//   Future<Size> _getImageSize(File imageFile) async {
//     final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
//     if (image == null) throw Exception('Failed to decode image');
//     return Size(image.width.toDouble(), image.height.toDouble());
//   }

//   Future<List<double>> getFaceEmbedding(File imageFile) async {
//     if (!_isInitialized || _interpreter == null) {
//       throw Exception('FaceRecognitionService is not initialized');
//     }

//     try {
//       // First validate the face
//       final detectionResult = await detectFace(imageFile);
//       if (!detectionResult.isValid) {
//         throw Exception('Invalid face detected: ${detectionResult.message}');
//       }

//       var bytes = await imageFile.readAsBytes();
//       var image = img.decodeImage(bytes);
//       if (image == null) throw Exception('Failed to decode image');

//       // Apply augmentations: rotation, brightness, blur
//       List<img.Image> augmentedImages = _augmentImage(image);

//       // Extract embeddings for each augmented image
//       List<double> embeddings = [];
//       for (var augmentedImage in augmentedImages) {
//         var embedding = await _extractEmbeddingFromImage(augmentedImage);
//         embeddings
//             .addAll(embedding); // Storing all embeddings in a combined list
//       }

//       return embeddings;
//     } catch (e) {
//       print('Error getting face embedding: $e');
//       rethrow;
//     }
//   }

//   List<img.Image> _augmentImage(img.Image originalImage) {
//     List<img.Image> augmentedImages = [];

//     // Add original image to list
//     augmentedImages.add(originalImage);

//     // Rotation augmentation
//     augmentedImages.add(img.copyRotate(originalImage, angle: 5));
//     augmentedImages.add(img.copyRotate(originalImage, angle: -5));

//     // Brightness augmentation
//     augmentedImages.add(_adjustBrightness(originalImage, 30));
//     augmentedImages.add(_adjustBrightness(originalImage, -30));

//     return augmentedImages;
//   }

//   img.Image _adjustBrightness(img.Image image, int amount) {
//     var brightened = img.Image.from(image);
//     for (var y = 0; y < brightened.height; y++) {
//       for (var x = 0; x < brightened.width; x++) {
//         var pixel = brightened.getPixel(x, y);
//         var r = (pixel.r + amount).clamp(0, 255);
//         var g = (pixel.g + amount).clamp(0, 255);
//         var b = (pixel.b + amount).clamp(0, 255);
//         brightened.setPixelRgba(x, y, r, g, b, pixel.a);
//       }
//     }
//     return brightened;
//   }

//   Future<List<double>> _extractEmbeddingFromImage(img.Image image) async {
//     // Resize the image to the required input size
//     var resizedImage =
//         img.copyResize(image, width: INPUT_SIZE, height: INPUT_SIZE);
//     var input = _imageToByteListFloat32(resizedImage);

//     // Prepare output tensor
//     var outputShape = _interpreter!.getOutputTensor(0).shape;
//     var outputBuffer = List.generate(
//       outputShape[0],
//       (_) => List<double>.filled(outputShape[1], 0),
//     );

//     _interpreter!.run(input, outputBuffer);

//     // Flatten the result into a single list
//     return outputBuffer.expand((list) => list).toList();
//   }

//   List<List<List<List<double>>>> _imageToByteListFloat32(img.Image image) {
//     var convertedBytes = List.generate(
//       1,
//       (i) => List.generate(
//         INPUT_SIZE,
//         (y) => List.generate(
//           INPUT_SIZE,
//           (x) {
//             var pixel = image.getPixel(x, y);
//             return [
//               (pixel.r.toDouble() - 127.5) / 128,
//               (pixel.g.toDouble() - 127.5) / 128,
//               (pixel.b.toDouble() - 127.5) / 128,
//             ];
//           },
//         ),
//       ),
//     );
//     return convertedBytes;
//   }

//   // Similarity calculation (cosine similarity)
//   double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
//     if (embedding1.length != embedding2.length) {
//       print(
//           'Warning: Embedding length mismatch: ${embedding1.length} vs ${embedding2.length}');
//       var minLength = min(embedding1.length, embedding2.length);
//       embedding1 = embedding1.sublist(0, minLength);
//       embedding2 = embedding2.sublist(0, minLength);
//     }

//     double dotProduct = 0.0;
//     double norm1 = 0.0;
//     double norm2 = 0.0;

//     for (int i = 0; i < embedding1.length; i++) {
//       dotProduct += embedding1[i] * embedding2[i];
//       norm1 += embedding1[i] * embedding1[i];
//       norm2 += embedding2[i] * embedding2[i];
//     }

//     return dotProduct / (sqrt(norm1) * sqrt(norm2));
//   }

//   Future<Map<String, dynamic>?> _findMatchingUser(
//       List<double> faceEmbedding) async {
//     try {
//       var users = await FirebaseFirestore.instance.collection('users').get();
//       double highestSimilarity = 0;
//       Map<String, dynamic>? matchedUser;

//       // First check if we have any users at all
//       if (users.docs.isEmpty) {
//         print('No users registered in the system');
//         return null;
//       }

//       // For each user in database
//       for (var doc in users.docs) {
//         var userData = doc.data();
//         var storedEmbeddings =
//             List<Map<String, dynamic>>.from(userData['embeddings']);

//         // Calculate similarity with all stored embeddings
//         List<double> similarities = [];
//         for (var embeddingMap in storedEmbeddings) {
//           var embedding = List<double>.from(embeddingMap['values']);
//           double similarity = calculateSimilarity(faceEmbedding, embedding);
//           similarities.add(similarity);
//         }

//         // Get average of top 3 similarities (or less if we have fewer samples)
//         similarities.sort((a, b) => b.compareTo(a));
//         double averageSimilarity = similarities
//                 .take(min(3, similarities.length))
//                 .reduce((a, b) => a + b) /
//             min(3, similarities.length);

//         // Update highest similarity if this is better
//         if (averageSimilarity > highestSimilarity) {
//           highestSimilarity = averageSimilarity;
//           matchedUser = userData;
//           matchedUser['id'] = doc.id;
//           matchedUser['matchConfidence'] = averageSimilarity;
//         }
//       }

//       // Debug print to help understand matching
//       print('Highest similarity found: $highestSimilarity');
//       print('Required threshold: $THRESHOLD');
//       print('Matched user: ${matchedUser?['name'] ?? 'Unknown'}');

//       // Only return a match if we're very confident
//       if (highestSimilarity >= THRESHOLD) {
//         return matchedUser;
//       }

//       // If similarity is too low, return null (unknown user)
//       return null;
//     } catch (e) {
//       print('Error finding matching user: $e');
//       return null;
//     }
//   }

//   void dispose() {
//     _interpreter?.close();
//     _faceDetector.close();
//     _isInitialized = false;
//   }
// }

// class FaceDetectionResult {
//   final bool isValid;
//   final String message;
//   final Face? face;

//   FaceDetectionResult({
//     required this.isValid,
//     required this.message,
//     this.face,
//   });
// }

// class FacePositionValidation {
//   final bool isValid;
//   final String message;

//   FacePositionValidation({
//     required this.isValid,
//     required this.message,
//   });
// // }import 'dart:io';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class FaceRecognitionService {
  // Optimized constants
  static const double THRESHOLD = 0.80;
  static const int INPUT_SIZE = 112;
  static const int OUTPUT_SIZE = 128;
  static const double MIN_FACE_PERCENTAGE = 0.15;
  static const double MAX_FACE_PERCENTAGE = 0.65;
  static const double MAX_HEAD_ROTATION = 20.0;

  Interpreter? _interpreter;
  late FaceDetector _faceDetector;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('Initializing FaceRecognitionService...');

      final options = InterpreterOptions()..threads = 4;

      _interpreter = await Interpreter.fromAsset(
        'assets/MobileFaceNet.tflite',
        options: options,
      );

      _faceDetector = GoogleMlKit.vision.faceDetector(
        FaceDetectorOptions(
          enableLandmarks: true,
          enableClassification: true,
          enableTracking: true,
          minFaceSize: 0.15,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      if (_interpreter != null) {
        var inputShape = _interpreter!.getInputTensor(0).shape;
        var outputShape = _interpreter!.getOutputTensor(0).shape;
        print('Model input shape: $inputShape');
        print('Model output shape: $outputShape');
        _isInitialized = true;
        print('FaceRecognitionService initialized successfully');
      } else {
        throw Exception('Failed to load TensorFlow Lite model');
      }
    } catch (e) {
      print('Error initializing FaceRecognitionService: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  List<img.Image> _augmentImage(img.Image originalImage) {
    List<img.Image> augmentedImages = [];

    // Original image
    augmentedImages.add(originalImage);

    // Subtle rotation variations
    augmentedImages.add(img.copyRotate(originalImage, angle: 2));
    augmentedImages.add(img.copyRotate(originalImage, angle: -2));

    // Mild brightness variations
    augmentedImages.add(_adjustBrightness(originalImage, 12));
    augmentedImages.add(_adjustBrightness(originalImage, -12));

    // Subtle contrast variations
    augmentedImages.add(_adjustContrast(originalImage, 1.1));
    augmentedImages.add(_adjustContrast(originalImage, 0.9));

    return augmentedImages;
  }

  img.Image _adjustBrightness(img.Image image, int amount) {
    var brightened = img.Image.from(image);
    for (var y = 0; y < brightened.height; y++) {
      for (var x = 0; x < brightened.width; x++) {
        var pixel = brightened.getPixel(x, y);
        var r = (pixel.r + amount).clamp(0, 255);
        var g = (pixel.g + amount).clamp(0, 255);
        var b = (pixel.b + amount).clamp(0, 255);
        brightened.setPixelRgba(x, y, r, g, b, pixel.a);
      }
    }
    return brightened;
  }

  img.Image _adjustContrast(img.Image image, double factor) {
    var contrasted = img.Image.from(image);
    for (var y = 0; y < contrasted.height; y++) {
      for (var x = 0; x < contrasted.width; x++) {
        var pixel = contrasted.getPixel(x, y);
        var r = (((pixel.r - 128) * factor) + 128).clamp(0, 255).toInt();
        var g = (((pixel.g - 128) * factor) + 128).clamp(0, 255).toInt();
        var b = (((pixel.b - 128) * factor) + 128).clamp(0, 255).toInt();
        contrasted.setPixelRgba(x, y, r, g, b, pixel.a);
      }
    }
    return contrasted;
  }

  Future<FaceDetectionResult> detectFace(File imageFile) async {
    if (!_isInitialized) {
      throw Exception('FaceRecognitionService is not initialized');
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return FaceDetectionResult(
          isValid: false,
          message: 'No face detected. Please look at the camera.',
          face: null,
        );
      }

      if (faces.length > 1) {
        return FaceDetectionResult(
          isValid: false,
          message:
              'Multiple faces detected. Please ensure only one face is visible.',
          face: null,
        );
      }

      final face = faces.first;
      final imageSize = await _getImageSize(imageFile);
      final faceArea = face.boundingBox.width * face.boundingBox.height;
      final imageArea = imageSize.width * imageSize.height;
      final facePercentage = faceArea / imageArea;

      // Position validation
      final positionValidation = _validateFacePosition(face, imageSize);
      if (!positionValidation.isValid) {
        return FaceDetectionResult(
          isValid: false,
          message: positionValidation.message,
          face: face,
        );
      }

      // Size validation
      if (facePercentage < MIN_FACE_PERCENTAGE) {
        return FaceDetectionResult(
          isValid: false,
          message: 'Please move closer to the camera',
          face: face,
        );
      }

      if (facePercentage > MAX_FACE_PERCENTAGE) {
        return FaceDetectionResult(
          isValid: false,
          message: 'Please move away from the camera',
          face: face,
        );
      }

      // Rotation validation
      if (face.headEulerAngleY != null &&
          face.headEulerAngleY!.abs() > MAX_HEAD_ROTATION) {
        return FaceDetectionResult(
          isValid: false,
          message: 'Please face directly towards the camera',
          face: face,
        );
      }

      bool meetsRequirements = face.landmarks.length >= 3 &&
          positionValidation.isValid &&
          facePercentage >= MIN_FACE_PERCENTAGE &&
          facePercentage <= MAX_FACE_PERCENTAGE;

      return FaceDetectionResult(
        isValid: meetsRequirements,
        message: meetsRequirements
            ? 'Face detected successfully'
            : 'Please adjust your position',
        face: face,
      );
    } catch (e) {
      print('Error during face detection: $e');
      return FaceDetectionResult(
        isValid: false,
        message: 'Error during face detection',
        face: null,
      );
    }
  }

  FacePositionValidation _validateFacePosition(Face face, Size imageSize) {
    final rect = face.boundingBox;
    final faceCenterX = rect.center.dx;
    final faceCenterY = rect.center.dy;

    final minX = imageSize.width * 0.3;
    final maxX = imageSize.width * 0.7;
    final minY = imageSize.height * 0.3;
    final maxY = imageSize.height * 0.7;

    String message = '';

    if (faceCenterX < minX) {
      message = 'Move your face right';
    } else if (faceCenterX > maxX) {
      message = 'Move your face left';
    }

    if (faceCenterY < minY) {
      message = message.isEmpty ? 'Move your face down' : '$message and down';
    } else if (faceCenterY > maxY) {
      message = message.isEmpty ? 'Move your face up' : '$message and up';
    }

    bool isCentered = faceCenterX >= minX &&
        faceCenterX <= maxX &&
        faceCenterY >= minY &&
        faceCenterY <= maxY;

    return FacePositionValidation(
      isValid: isCentered,
      message: message.isEmpty ? 'Face is well positioned' : message,
    );
  }

  Future<List<double>> getFaceEmbedding(File imageFile) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('FaceRecognitionService is not initialized');
    }

    try {
      final detectionResult = await detectFace(imageFile);
      if (!detectionResult.isValid) {
        throw Exception('Invalid face detected: ${detectionResult.message}');
      }

      var bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // Generate augmented images
      List<img.Image> augmentedImages = _augmentImage(image);

      // Extract embeddings for each augmented image
      List<double> allEmbeddings = [];
      for (var augmentedImage in augmentedImages) {
        var embedding = await _extractEmbeddingFromImage(augmentedImage);
        allEmbeddings.addAll(embedding);
      }

      return allEmbeddings;
    } catch (e) {
      print('Error getting face embedding: $e');
      rethrow;
    }
  }

  Future<List<double>> _extractEmbeddingFromImage(img.Image image) async {
    var resizedImage =
        img.copyResize(image, width: INPUT_SIZE, height: INPUT_SIZE);
    var input = _imageToByteListFloat32(resizedImage);

    var outputShape = _interpreter!.getOutputTensor(0).shape;
    var outputBuffer = List.generate(
      outputShape[0],
      (_) => List<double>.filled(outputShape[1], 0),
    );

    _interpreter!.run(input, outputBuffer);
    return outputBuffer.expand((list) => list).toList();
  }

  List<List<List<List<double>>>> _imageToByteListFloat32(img.Image image) {
    var convertedBytes = List.generate(
      1,
      (i) => List.generate(
        INPUT_SIZE,
        (y) => List.generate(
          INPUT_SIZE,
          (x) {
            var pixel = image.getPixel(x, y);
            return [
              (pixel.r.toDouble() - 127.5) / 128,
              (pixel.g.toDouble() - 127.5) / 128,
              (pixel.b.toDouble() - 127.5) / 128,
            ];
          },
        ),
      ),
    );
    return convertedBytes;
  }

  double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.isEmpty || embedding2.isEmpty) {
      return 0.0;
    }

    if (embedding1.length != embedding2.length) {
      var minLength = min(embedding1.length, embedding2.length);
      embedding1 = embedding1.sublist(0, minLength);
      embedding2 = embedding2.sublist(0, minLength);
    }

    // Normalize embeddings
    embedding1 = _normalizeEmbedding(embedding1);
    embedding2 = _normalizeEmbedding(embedding2);

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }

    if (norm1 == 0 || norm2 == 0) return 0.0;

    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  List<double> _normalizeEmbedding(List<double> embedding) {
    double sumSquares = embedding.fold(0.0, (sum, val) => sum + val * val);
    double norm = sqrt(sumSquares);
    if (norm == 0) return embedding;
    return embedding.map((val) => val / norm).toList();
  }

  Future<Map<String, dynamic>?> findMatchingUser(
      List<double> faceEmbedding) async {
    try {
      var users = await FirebaseFirestore.instance.collection('users').get();

      if (users.docs.isEmpty) {
        print('No users registered in the system');
        return null;
      }

      double highestSimilarity = 0;
      Map<String, dynamic>? matchedUser;

      for (var doc in users.docs) {
        var userData = doc.data();
        var storedEmbeddings =
            List<Map<String, dynamic>>.from(userData['embeddings']);

        print(
            'Checking user: ${userData['name']} with ${storedEmbeddings.length} embeddings');

        List<double> similarities = [];
        for (var embeddingMap in storedEmbeddings) {
          var embedding = List<double>.from(embeddingMap['values']);
          double similarity = calculateSimilarity(faceEmbedding, embedding);
          similarities.add(similarity);
        }

        similarities.sort((a, b) => b.compareTo(a));
        // Take average of top 3 similarities
        double averageSimilarity =
            similarities.take(3).reduce((a, b) => a + b) / 3;

        print(
            'Average similarity with ${userData['name']}: $averageSimilarity');

        if (averageSimilarity > highestSimilarity &&
            averageSimilarity >= THRESHOLD) {
          highestSimilarity = averageSimilarity;
          matchedUser = userData;
          matchedUser['id'] = doc.id;
          matchedUser['matchConfidence'] = averageSimilarity;
        }
      }

      print('Highest similarity found: $highestSimilarity');
      print('Required threshold: $THRESHOLD');
      print('Matched user: ${matchedUser?['name'] ?? 'Unknown'}');

      return matchedUser;
    } catch (e) {
      print('Error finding matching user: $e');
      return null;
    }
  }

  Future<Size> _getImageSize(File imageFile) async {
    final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) throw Exception('Failed to decode image');
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  void dispose() {
    _interpreter?.close();
    _faceDetector.close();
    _isInitialized = false;
  }
}

class FaceDetectionResult {
  final bool isValid;
  final String message;
  final Face? face;

  FaceDetectionResult({
    required this.isValid,
    required this.message,
    this.face,
  });
}

class FacePositionValidation {
  final bool isValid;
  final String message;

  FacePositionValidation({
    required this.isValid,
    required this.message,
  });
}
