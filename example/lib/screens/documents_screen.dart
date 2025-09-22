// lib/screens/documents_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import '../models/document.dart'; // Document modelini import ediyoruz
import '../models/document_page.dart'; // DocumentPage modelini import ediyoruz
import '../services/cunning_document_scanner.dart';
import '../services/document_service.dart'; // DocumentService'i import ediyoruz
import 'document_editor_screen.dart'; // DocumentEditorScreen'i import ediyoruz
// import 'camera_screen.dart'; // Yeni sayfa eklemek için kamera ekranını açmak gerekebilir

class DocumentsScreen extends StatefulWidget {
  final Document document; // Gösterilecek belge nesnesi

  DocumentsScreen({required this.document});

  @override
  _DocumentsScreenState createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final DocumentService _documentService = DocumentService();
  late Document document; // State içinde tutulan belge

  @override
  void initState() {
    super.initState();
    document = widget.document; // Widget'tan gelen belgeyi state'e kopyala
  }

  // Belgeyi paylaşma işlevi (placeholder)
  void _shareDocument() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Paylaşım özelliği geliştirme aşamasında')));
  }

  // Belgeyi PDF olarak dışa aktarma işlevi (placeholder)
  void _exportToPDF() async {
    try {
      final pdfPath = await _documentService.generatePDF(document);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF oluşturuldu: $pdfPath')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF oluşturulamadı: $e')));
    }
  }

  // Belgeyi yeniden adlandırma işlevi
  void _renameDocument() async {
    final controller = TextEditingController(text: document.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dokümanı Yeniden Adlandır'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Yeni ad', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text('Kaydet')),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != document.name) {
      final updatedDocument = document.copyWith(name: newName, updatedAt: DateTime.now());
      await _documentService.saveDocument(updatedDocument);
      if (mounted) {
        setState(() => document = updatedDocument); // UI'ı güncelle
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Doküman adı güncellendi')));
      }
    }
  }

  // Belgeyi silme işlevi
  void _deleteDocument() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dokümanı Sil'),
        content: Text('${document.name} dokümanını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Sil')),
        ],
      ),
    );

    if (confirm == true) {
      await _documentService.deleteDocument(document.id);
      if (mounted) Navigator.pop(context); // Belge silindi, önceki ekrana dön
    }
  }

  // Belge sayfasını düzenleme işlevi
  void _editPage(DocumentPage page) async {
    // Düzenleyici ekranına git ve dönüşte belgeyi yeniden yükle
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentEditorScreen(
          imagePath: page.processedImagePath ?? page.imagePath,
          isNewDocument: false, // Var olan bir sayfayı düzenliyoruz
          document: document,
        ),
      ),
    );
    // Düzenleme ekranından dönüldüğünde belgeyi yeniden yükle
    if (mounted) {
      final updatedDoc = await _documentService.getDocument(document.id);
      if (updatedDoc != null) {
        setState(() => document = updatedDoc);
      }
    }
  }

  // Belge sayfasını silme işlevi
  void _deletePage(int index) async {
    if (document.pages.length <= 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Doküman en az bir sayfa içermelidir')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sayfayı Sil'),
        content: Text('Bu sayfayı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Sil')),
        ],
      ),
    );

    if (confirm == true) {
      final pages = List<DocumentPage>.from(document.pages); // Mevcut sayfaların kopyasını al
      pages.removeAt(index); // Seçilen sayfayı sil
      final updatedDocument = document.copyWith(pages: pages, updatedAt: DateTime.now());
      await _documentService.saveDocument(updatedDocument); // Güncellenmiş belgeyi kaydet
      if (mounted) {
        setState(() => document = updatedDocument); // UI'ı güncelle
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sayfa başarıyla silindi')));
      }
    }
  }

  // Yeni sayfa ekleme işlevi (placeholder)
  void _addNewPage() async {
    try {
      // Cunning Scanner ile yeni sayfa ekle
      final List<String>? imagePaths = await CunningDocumentScanner.getPictures(
        noOfPages: 3, // Maksimum 3 yeni sayfa
        isGalleryImportAllowed: true,
      );

      if (imagePaths != null && imagePaths.isNotEmpty) {
        // Her bir yeni sayfayı mevcut belgeye ekle
        List<DocumentPage> newPages = [];
        for (String imagePath in imagePaths) {
          final now = DateTime.now();
          newPages.add(DocumentPage(
            id: now.millisecondsSinceEpoch.toString(),
            imagePath: imagePath,
            processedImagePath: imagePath,
            createdAt: now,
            updatedAt: now,
          ));
        }

        final now = DateTime.now();
        // Belgeyi güncelle
        final updatedDocument = document.copyWith(
          pages: [...document.pages, ...newPages],
          updatedAt: now,
        );

        await _documentService.saveDocument(updatedDocument);
        if (mounted) {
          setState(() => document = updatedDocument);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${newPages.length} yeni sayfa eklendi')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sayfa eklenemedi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(document.name),
        actions: [
          IconButton(icon: Icon(Icons.share), onPressed: _shareDocument, tooltip: 'Belgeyi Paylaş'),
          IconButton(icon: Icon(Icons.picture_as_pdf), onPressed: _exportToPDF, tooltip: 'PDF Olarak Dışa Aktar'),
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'rename') _renameDocument();
              else if (value == 'delete') _deleteDocument();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Yeniden Adlandır')])),
              PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete), SizedBox(width: 8), Text('Sil')])),
            ],
          ),
        ],
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7, // Her bir öğenin oranını ayarla
        ),
        itemCount: document.pages.length,
        itemBuilder: (context, index) {
          final page = document.pages[index];
          final imagePath = page.processedImagePath ?? page.imagePath; // İşlenmiş veya orijinal resim yolu
          final imageFile = File(imagePath);

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            clipBehavior: Clip.antiAlias, // Köşeleri yuvarlamak için
            child: Column(
              children: [
                Expanded(
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.cover,
                    width: double.infinity, // Genişliği tam doldur
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey.shade500)),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sayfa ${index + 1}', style: TextStyle(fontWeight: FontWeight.w500)),
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert, size: 20),
                        onSelected: (value) {
                          if (value == 'edit') _editPage(page);
                          else if (value == 'delete') _deletePage(index);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                          PopupMenuItem(value: 'delete', child: Text('Sil')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPage,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue.shade700,
        tooltip: 'Yeni Sayfa Ekle',
      ),
    );
  }
}