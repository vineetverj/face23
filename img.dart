// // file: services/image_augmentor.dart

// import 'dart:io';
// import 'dart:math';
// import 'package:image/image.dart' as img;

// class ImageAugmentor {
//   final Random _random = Random();
  
//   static const double maxRotation = 20.0;
//   static const double maxScale = 1.2;
//   static const double minScale = 0.8;
//   static const double maxTranslation = 10.0;
//   static const double maxNoise = 20.0;
//   static const double maxBlur = 1.5;
//   static const double maxBrightness = 50.0;
//   static const double maxContrast = 1.3;
//   static const double minContrast = 0.7;
//   static const double maxSaturation = 1.3;
//   static const double minSaturation = 0.7;

//   Future<List<File>> augmentFaceImage(File imageFile, int numAugmentations) async {
//     final List<File> augmentedImages = [];
//     final imageBytes = await imageFile.readAsBytes();
//     final originalImage = img.decodeImage(imageBytes);
    
//     if (originalImage == null) throw Exception('Failed to decode image');

//     for (int i = 0; i < numAugmentations; i++) {
//       var augmentedImage = img.Image.from(originalImage);
//       augmentedImage = _applyRandomAugmentations(augmentedImage);
      
//       final tempDir = await Directory.systemTemp.createTemp();
//       final tempFile = File(
//         '${tempDir.path}/aug_${DateTime.now().millisecondsSinceEpoch}_$i.jpg'
//       );
      
//       await tempFile.writeAsBytes(img.encodeJpg(augmentedImage, quality: 95));
//       augmentedImages.add(tempFile);
//     }
    
//     return augmentedImages;
//   }

//   img.Image _applyRandomAugmentations(img.Image image) {
//     var augmented = image;
    
//     if (_random.nextBool()) augmented = _rotate(augmented);
//     if (_random.nextBool()) augmented = _scale(augmented);
//     if (_random.nextBool()) augmented = _translate(augmented);
//     if (_random.nextBool()) augmented = _addNoise(augmented);
//     if (_random.nextBool()) augmented = _adjustBrightness(augmented);
//     if (_random.nextBool()) augmented = _adjustContrast(augmented);
//     if (_random.nextBool()) augmented = _adjustSaturation(augmented);
//     if (_random.nextBool()) augmented = _addBlur(augmented);
//     if (_random.nextBool()) augmented = _flipHorizontal(augmented);
//     if (_random.nextBool()) augmented = _addJpegNoise(augmented);
    
//     return augmented;
//   }

//   img.Image _rotate(img.Image image) {
//     final angle = _random.nextDouble() * maxRotation * 2 - maxRotation;
//     return img.copyRotate(image, angle: angle);
//   }

//   img.Image _scale(img.Image image) {
//     final scale = minScale + _random.nextDouble() * (maxScale - minScale);
//     final newWidth = (image.width * scale).round();
//     final newHeight = (image.height * scale).round();
//     return img.copyResize(image, width: newWidth, height: newHeight);
//   }

//   img.Image _translate(img.Image image) {
//     final dx = _random.nextDouble() * maxTranslation * 2 - maxTranslation;
//     final dy = _random.nextDouble() * maxTranslation * 2 - maxTranslation;
    
//     var translated = img.Image(image.width, image.height);
//     for (var y = 0; y < image.height; y++) {
//       for (var x = 0; x < image.width; x++) {
//         final sourceX = (x - dx).round();
//         final sourceY = (y - dy).round();
        
//         if (sourceX >= 0 && sourceX < image.width && 
//             sourceY >= 0 && sourceY < image.height) {
//           translated.setPixel(x, y, image.getPixel(sourceX, sourceY));
//         }
//       }
//     }
//     return translated;
//   }

//   img.Image _addNoise(img.Image image) {
//     var noisy = img.Image.from(image);
//     for (var y = 0; y < image.height; y++) {
//       for (var x = 0; x < image.width; x++) {
//         final pixel = image.getPixel(x, y);
//         final noise = (_random.nextDouble() * maxNoise * 2 - maxNoise).round();
        
//         noisy.setPixelRgba(
//           x, y,
//           (pixel.r + noise).clamp(0, 255),
//           (pixel.g + noise).clamp(0, 255),
//           (pixel.b + noise).clamp(0, 255),
//           pixel.a
//         );
//       }
//     }
//     return noisy;
//   }

//   img.Image _adjustBrightness(img.Image image) {
//     final brightness = _random.nextDouble() * maxBrightness * 2 - maxBrightness;
//     return img.brightness(image, brightness.round());
//   }

//   img.Image _adjustContrast(img.Image image) {
//     final contrast = minContrast + _random.nextDouble() * (maxContrast - minContrast);
//     return img.contrast(image, contrast);
//   }

//   img.Image _adjustSaturation(img.Image image) {
//     final saturation = minSaturation + _random.nextDouble() * (maxSaturation - minSaturation);
//     return img.modulate(image, saturation: saturation);
//   }

//   img.Image _addBlur(img.Image image) {
//     final sigma = _random.nextDouble() * maxBlur;
//     return img.gaussianBlur(image, sigma);
//   }

//   img.Image _flipHorizontal(img.Image image) {
//     return img.flip(image, direction: img.FlipDirection.horizontal);
//   }

//   img.Image _addJpegNoise(img.Image image) {
//     final quality = 60 + _random.nextInt(35);
//     final compressed = img.encodeJpg(image, quality: quality);
//     return img.decodeImage(compressed)!;
//   }
// }