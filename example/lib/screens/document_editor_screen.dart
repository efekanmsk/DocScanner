// lib/screens/document_editor_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import '../models/document.dart'; // Document modelini import ediyoruz
import '../models/document_page.dart'; // DocumentPage modelini import ediyoruz
import '../services/document_service.dart'; // DocumentService'i import ediyoruz
// import '../services/image_processor.dart'; // Eğer burada kullanılıyorsa

class DocumentEditorScreen extends StatefulWidget {
  final String imagePath; // Düzenlenecek sayfanın dosya yolu
  final bool isNewDocument; // Yeni belge mi, yoksa var olan mı?
  final Document? document; // Eğer var olan bir belge düzenleniyorsa

  DocumentEditorScreen({
    required this.imagePath,
    required this.isNewDocument,
    this.document,
  });

  @override
  _DocumentEditorScreenState createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  final DocumentService _documentService = DocumentService();
  final TextEditingController _nameController = TextEditingController();
  bool isProcessing = false; // Kaydetme veya işlem yapma durumunu gösterir

  // Eğer ImageProcessor burada direkt kullanılıyorsa
  // final ImageProcessor _imageProcessor = ImageProcessor();

  @override
  void initState() {
    super.initState();
    // Belge adı zaten varsa onu kullan, yoksa varsayılan bir isim ver
    if (widget.document != null) {
      _nameController.text = widget.document!.name;
    } else {
      _nameController.text = 'Taranan Belge ${DateTime.now().toIso8601String().substring(5, 16)}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); // TextEditingController'ı dispose et
    super.dispose();
  }

  // Belgeyi kaydetme veya güncelleme metodun
  Future<void> _saveDocument() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lütfen doküman adı girin')));
      return;
    }
    if (mounted) setState(() => isProcessing = true); // İşlem başladığını işaretle

    try {
      Document docToSave;
      if (widget.isNewDocument) {
        final now = DateTime.now();
        // Yeni bir sayfa nesnesi oluştur
        final newPage = DocumentPage(
          id: now.millisecondsSinceEpoch.toString(), // Sayfa için benzersiz ID
          imagePath: widget.imagePath,
          processedImagePath: widget.imagePath, // Başlangıçta işlenmiş hali orijinaliyle aynı
          createdAt: now,
          updatedAt: now,
        );
        // Yeni belgeyi, bu sayfayı içeren bir liste ile oluştur
        docToSave = Document(
          id: now.millisecondsSinceEpoch.toString(), // Belge için benzersiz ID
          name: _nameController.text.trim(),
          pages: [newPage], // Belgenin sayfaları listesi
          createdAt: now,
          updatedAt: now,
        );
      } else {
        // Var olan bir belgeyi güncelleme
        // Bu kısım, mevcut belgeye yeni sayfa eklemek veya var olan bir sayfayı düzenlemek için genişletilebilir.
        // Şimdilik, sadece belge adını güncelliyor ve ilk sayfanın işlenmiş resim yolunu değiştiriyoruz.
        final updatedPage = widget.document!.pages.first.copyWith(processedImagePath: widget.imagePath);
        docToSave = widget.document!.copyWith(
          name: _nameController.text.trim(),
          pages: [updatedPage, ...widget.document!.pages.skip(1)], // İlk sayfayı güncelleyip diğerlerini ekle
          updatedAt: DateTime.now(),
        );
      }

      await _documentService.saveDocument(docToSave); // Belgeyi kaydet
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Doküman kaydedildi')));
        // Belge başarıyla kaydedildiğinde bir önceki ekrana 'true' değerini gönder.
        Navigator.pop(context, true);
      }

    } catch (e) {
      print('Belge kaydetme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Doküman kaydedilemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => isProcessing = false); // İşlem bittiğini işaretle
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Belgeyi Düzenle"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, false), // Kaydetmeden çıkarsa 'false' döner
        ),
        actions: [
          if (isProcessing)
          // İşlem devam ediyorsa yükleme göstergesi
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else
          // Kaydet butonu
            TextButton(
              onPressed: _saveDocument,
              child: Text('Kaydet', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Düzenlenecek görüntüyü gösteren alan
          Expanded(
            child: InteractiveViewer( // Görüntüyü yakınlaştırma/kaydırma özelliği
              child: Container(
                margin: EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(widget.imagePath), fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          // Belge adı girişi
          Container(
            color: Colors.grey.shade900,
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Doküman adı',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}