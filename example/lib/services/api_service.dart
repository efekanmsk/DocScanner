// D:/Projeler/cam_scanner/lib/services/api_service.dart

import 'dart:io'; // Dosya işlemleri için
import 'dart:convert'; // JSON işlemleri için
import 'package:dio/dio.dart'; // HTTP istekleri için

import '../models/document.dart'; // Document modelini import ediyoruz
import '../models/document_page.dart'; // DocumentPage modelini import ediyoruz (API servisi içinde sayfa detayları da işlenebilir)

class ApiService {
  late Dio _dio;
  final String baseUrl = 'http://45.136.6.213:3000/api'; // API'nin temel URL'si

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 30), // Bağlantı zaman aşımı
      receiveTimeout: Duration(seconds: 30), // Cevap alma zaman aşımı
    ));
  }

  Future<void> uploadDocument(Document document) async {
    try {
      final formData = FormData();

      // Belge meta verilerini (ID, ad, tarihler vb.) JSON string'ine çevirip ekliyoruz.
      // toMap() metodu ile Map'i alıp, json.encode() ile JSON string'ine dönüştürüyoruz.
      formData.fields.add(MapEntry('document', json.encode(document.toMap())));

      // Her bir sayfanın görüntüsünü (hem orijinal hem de işlenmiş) yükle
      for (int i = 0; i < document.pages.length; i++) {
        final page = document.pages[i];

        // Orijinal görüntü dosyasını ekle
        if (await File(page.imagePath).exists()) {
          formData.files.add(MapEntry(
            'image_$i', // Sunucuda bu isimle alınacak (örneğin image_0, image_1)
            await MultipartFile.fromFile(page.imagePath, filename: page.imagePath.split('/').last),
          ));
        }

        // İşlenmiş görüntü dosyası varsa onu da ekle
        if (page.processedImagePath != null && await File(page.processedImagePath!).exists()) {
          formData.files.add(MapEntry(
            'processed_image_$i', // Sunucuda bu isimle alınacak (örneğin processed_image_0)
            await MultipartFile.fromFile(page.processedImagePath!, filename: page.processedImagePath!.split('/').last),
          ));
        }
      }

      // '/documents' endpoint'ine POST isteği gönder
      final response = await _dio.post('/documents', data: formData);
      print('Doküman sunucuya yüklendi: ${response.statusCode}');
      // İsteğe bağlı: Başarılı yükleme sonrası sunucudan dönen veriyi işleyebilirsiniz: response.data
    } catch (e) {
      // Hata durumunda konsola yazdır
      print('Doküman yükleme hatası: $e');
      if (e is DioException) { // Dio'ya özgü hataları daha detaylı yakalayabiliriz
        print('Dio Hata Tipi: ${e.type}');
        print('Dio Hata Mesajı: ${e.message}');
        if (e.response != null) {
          print('Dio Hata Durum Kodu: ${e.response?.statusCode}');
          print('Dio Hata Yanıtı: ${e.response?.data}');
        }
      }
      rethrow; // Hatayı tekrar fırlat, böylece çağıran kod da haberdar olabilir
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _dio.delete('/documents/$documentId');
      print('Doküman sunucudan silindi: $documentId');
    } catch (e) {
      print('Doküman silme hatası ($documentId): $e');
      rethrow;
    }
  }

  Future<List<Document>> syncDocuments() async {
    try {
      final response = await _dio.get('/documents');
      final List<dynamic> jsonList = response.data;
      // Sunucudan gelen JSON listesini Document nesneleri listesine çevir
      return jsonList.map((json) => Document.fromMap(json)).toList();
    } catch (e) {
      print('Doküman senkronizasyon hatası: $e');
      rethrow;
    }
  }
}