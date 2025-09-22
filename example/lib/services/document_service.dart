// lib/services/document_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/document.dart';
import '../models/document_page.dart'; // DocumentPage'i import ediyoruz
import 'api_service.dart'; // API servisini import ediyoruz
// import 'package:pdf/widgets.dart' as pw; // PDF oluşturma için gerekli olabilir

class DocumentService {
  final ApiService _apiService = ApiService(); // API servisi örneği
  // Cihazın uygulama belgeleri dizinine giden yol
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Belge ID'sine göre JSON dosyasının yolunu döndürür
  Future<File> _localFile(String docId) async {
    final path = await _localPath;
    return File('$path/docs/$docId.json');
  }

  // Belgelerin saklandığı dizin. Yoksa oluşturur.
  Future<Directory> get _docsDir async {
    final path = await _localPath;
    final dir = Directory('$path/docs');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // Bir Document nesnesini hem yerel diske hem de sunucuya kaydeder
  Future<void> saveDocument(Document document) async {
    try {
      // Önce yerel diske kaydet
      final file = await _localFile(document.id);
      final jsonString = json.encode(document.toMap());
      await file.writeAsString(jsonString);

      // Sonra sunucuya yükle
      await _apiService.uploadDocument(document);
    } catch (e) {
      print('Belge kaydetme hatası: $e');
      // Sunucuya yükleme başarısız olsa bile yerel kayıt yapılmış olacak
      rethrow;
    }
  }

  // Belge ID'sine göre bir Document nesnesini yerel diskten okur
  Future<Document?> getDocument(String docId) async {
    try {
      final file = await _localFile(docId);
      if (!await file.exists()) return null; // Dosya yoksa null döndür
      final contents = await file.readAsString();
      final jsonMap = json.decode(contents);
      return Document.fromMap(jsonMap);
    } catch (e) {
      print("Belge okuma hatası ($docId): $e");
      return null;
    }
  }

  // Tüm belgeleri yerel diskten okur
  Future<List<Document>> getAllDocuments() async {
    final dir = await _docsDir;
    // Sadece .json uzantılı dosyaları al
    final files = dir.listSync().whereType<File>().where((file) => file.path.endsWith('.json'));

    List<Document> documents = [];
    for (var file in files) {
      try {
        final contents = await file.readAsString();
        if (contents.isNotEmpty) {
          final jsonMap = json.decode(contents);
          documents.add(Document.fromMap(jsonMap));
        }
      } catch (e) {
        // Hatalı veya bozuk bir dosya okunduğunda uygulamanın çökmesini engeller.
        // Konsola hata bilgisini yazdırır ve bu dosyayı atlar.
        print("Hata: ${file.path} dosyası okunamadı veya bozuk. Hata: $e");
      }
    }

    // Belgeleri en son güncellenen tarihe göre sıralar (en yeni üstte)
    documents.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return documents;
  }

  // Belge ID'sine göre hem yerel diskten hem de sunucudan belgeyi siler
  Future<void> deleteDocument(String docId) async {
    try {
      // Önce yerel diskten sil
      final file = await _localFile(docId);
      if (await file.exists()) {
        await file.delete();
      }

      // Sonra sunucudan sil
      await _apiService.deleteDocument(docId);
    } catch (e) {
      print("Belge silme hatası ($docId): $e");
      // Sunucudan silme başarısız olsa bile yerel silme işlemi yapılmış olacak
      rethrow;
    }
  }

  // PDF oluşturma işlevi için placeholder. Gerçek bir implementasyon gerektirir.
  Future<String> generatePDF(Document document) async {
    print("PDF oluşturma özelliği henüz eklenmedi. (Geliştirme Aşamasında)");
    await Future.delayed(Duration(seconds: 1)); // Simülasyon
    return "path/to/generated.pdf"; // Örnek dönüş değeri
  }

  // Resim yollarından yeni bir belge oluşturur ve kaydeder
  Future<Document> createDocumentFromImages(List<String> imagePaths) async {
    // Yeni bir belge ID'si oluştur (timestamp kullanarak)
    final docId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    
    // Resim yollarından DocumentPage nesneleri oluştur
    final pages = imagePaths.map((path) => 
      DocumentPage(
        id: '${docId}_${imagePaths.indexOf(path)}',
        imagePath: path,
        processedImagePath: null, // İşlenmiş resim yolu başlangıçta null
        createdAt: now,
        updatedAt: now,
      )
    ).toList();
    
    // Yeni belge oluştur
    final document = Document(
      id: docId,
      name: 'Belge ${now.day}.${now.month}.${now.year}',
      pages: pages,
      createdAt: now,
      updatedAt: now,
    );
    
    // Belgeyi kaydet
    await saveDocument(document);
    
    return document;
  }

  // Sunucuyla belgeleri senkronize eder
  Future<void> syncWithServer() async {
    try {
      // Sunucudan tüm belgeleri al
      final serverDocuments = await _apiService.syncDocuments();
      
      // Her bir sunucu belgesini yerel olarak kaydet/güncelle
      for (final doc in serverDocuments) {
        final file = await _localFile(doc.id);
        final jsonString = json.encode(doc.toMap());
        await file.writeAsString(jsonString);
      }
    } catch (e) {
      print('Sunucu senkronizasyon hatası: $e');
      rethrow;
    }
  }
}