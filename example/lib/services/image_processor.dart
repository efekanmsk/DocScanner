// lib/services/image_processor.dart

import 'dart:io';
import 'dart:ui'; // Offset için
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img; // 'image' paketi için
import 'dart:math'; // min/max için

class ImageProcessor {
  Future<String> get _processedImagesDir async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String processedDirPath = '${appDir.path}/processed_images';
    await Directory(processedDirPath).create(recursive: true);
    return processedDirPath;
  }

  // Görüntüdeki belgenin köşelerini otomatik olarak algılar.
  //
  // **BURADA YAPAY ZEKA/BİLGİSAYAR GÖRÜŞÜ ENTEGRASYONU YAPILACAKTIR.**
  //
  // Şu anki implementasyon, karmaşık kenar algılama algoritmalarını içermemektedir.
  // Bunun yerine, belgenin kabaca ortasında yer alan varsayılan bir dikdörtgenin
  // köşelerini döndürmektedir.
  //
  // Gerçek AI tabanlı bir kenar algılama için (örneğin eğik veya bozuk belgeler için):
  // 1. **OpenCV Entegrasyonu:** Flutter'ın Method Channels (Platform Kanalları)
  //    aracılığıyla Android (Kotlin/Java) ve iOS (Swift/Objective-C) tarafında
  //    OpenCV kütüphanesini kullanarak Canny kenar algılama, kontur bulma ve
  //    perspektif düzeltme algoritmaları uygulanmalıdır.
  // 2. **TensorFlow Lite/PyTorch Mobile:** Önceden eğitilmiş bir derin öğrenme (DL)
  //    modeli (örneğin bir segmentasyon modeli) kullanılarak belgenin sınırları
  //    algılanabilir. Bu model, tflite_flutter gibi paketlerle entegre edilebilir.
  // 3. **Hazır Flutter Eklentileri:** `flutter_document_scanner` gibi eklentiler
  //    bu karmaşık entegrasyonu sizin için zaten yapmış olabilir.
  //
  // Bu metot, gelecekteki bir AI/CV entegrasyonu için bir yer tutucu görevi görür.
  // Eğer burada gerçek bir algılama yapmazsanız, kullanıcı kırpma ekranında
  // varsayılan bir kutuyu manuel olarak ayarlamak zorunda kalacaktır.
  Future<List<Offset>> detectDocumentCorners(String imagePath) async {
    print("AI/CV tabanlı kenar algılama yer tutucusu çalışıyor: $imagePath");
    await Future.delayed(Duration(milliseconds: 700)); // Algılama simülasyon gecikmesi

    final File imageFile = File(imagePath);
    final img.Image? originalImage = img.decodeImage(imageFile.readAsBytesSync());

    if (originalImage == null) {
      throw Exception("Görüntü yüklenemedi: $imagePath");
    }

    final double width = originalImage.width.toDouble();
    final double height = originalImage.height.toDouble();

    // **ŞİMDİLİK:** Görüntünün ortasında yer alan varsayılan bir dikdörtgenin
    // köşelerini döndürüyoruz. Bu, AI/CV entegre edilene kadar bir başlangıç noktasıdır.
    // Gerçek bir AI/CV burada belgenin eğimli kenarlarını tespit edecektir.
    List<Offset> defaultCorners = [
      Offset(width * 0.15, height * 0.20), // Top-Left
      Offset(width * 0.85, height * 0.20), // Top-Right
      Offset(width * 0.85, height * 0.80), // Bottom-Right
      Offset(width * 0.15, height * 0.80), // Bottom-Left
    ];

    print("AI/CV yer tutucusu varsayılan köşeleri döndürdü: $defaultCorners");
    return defaultCorners;
  }

  // Görüntüyü verilen dört köşeye göre kırpar ve perspektif düzeltmesi uygular.
  // Şu anki implementasyon sadece dikdörtgen kırpma yapar.
  // Gerçek bir perspektif düzeltme için yine gelişmiş CV kütüphaneleri gerekir.
  Future<String> cropAndPerspectiveCorrect(String imagePath, List<Offset> corners) async {
    print("Görüntü kırpılıyor ve perspektif düzeltiliyor: $imagePath");
    await Future.delayed(Duration(seconds: 1)); // Simülasyon gecikmesi

    final File originalFile = File(imagePath);
    final img.Image? originalImage = img.decodeImage(originalFile.readAsBytesSync());

    if (originalImage == null) {
      throw Exception("Görüntü yüklenemedi: $imagePath");
    }

    // Köşelerin ortalama en küçük ve en büyük x/y değerlerini bularak basit bir dikdörtgen kırpma yaparız.
    // Gerçek bir perspektif düzeltme için daha karmaşık algoritmalar gerekir (OpenCV).
    double minX = corners.map((o) => o.dx).reduce(min);
    double maxX = corners.map((o) => o.dx).reduce(max);
    double minY = corners.map((o) => o.dy).reduce(min);
    double maxY = corners.map((o) => o.dy).reduce(max);

    // Görüntü sınırlarını aşmamak için kontrol
    minX = minX.clamp(0.0, originalImage.width.toDouble());
    maxX = maxX.clamp(0.0, originalImage.width.toDouble());
    minY = minY.clamp(0.0, originalImage.height.toDouble());
    maxY = maxY.clamp(0.0, originalImage.height.toDouble());

    // Kırpma işlemi
    img.Image croppedImage = img.copyCrop(
      originalImage,
      x: minX.toInt(),
      y: minY.toInt(),
      width: (maxX - minX).toInt().clamp(1, originalImage.width),
      height: (maxY - minY).toInt().clamp(1, originalImage.height),
    );

    // İşlenmiş dosyayı kaydet
    final String processedDirPath = await _processedImagesDir;
    final String fileName = 'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String newPath = '$processedDirPath/$fileName';

    final File processedFile = File(newPath);
    await processedFile.writeAsBytes(img.encodeJpg(croppedImage, quality: 90));

    print("Görüntü kırpıldı ve kaydedildi: $newPath");
    return newPath;
  }
}