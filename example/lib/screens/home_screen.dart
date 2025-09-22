// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io'; // Dosya işlemleri için
import '../models/document.dart'; // Document modelini import ediyoruz
import '../services/cunning_document_scanner.dart';
import '../services/document_service.dart'; // DocumentService'i import ediyoruz
import '../services/ios_options.dart';
import 'documents_screen.dart'; // Belge detay ekranını import ediyoruz

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DocumentService _documentService = DocumentService();
  late Future<List<Document>> _documentsFuture;
  String _searchQuery = '';

  // Tarih ve saati formatlayan yardımcı fonksiyon
  String formatDateTime(DateTime dateTime) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(dateTime.day)}.${twoDigits(dateTime.month)}.${dateTime.year} ${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
  }

  @override
  void initState() {
    super.initState();
    _refreshDocuments(); // Ekran yüklendiğinde belgeleri çek
  }

  // Belge listesini yenilemek için kullanılan metod
  void _refreshDocuments() {
    setState(() {
      _documentsFuture = _documentService.getAllDocuments().then((documents) {
        if (_searchQuery.isEmpty) {
          return documents;
        }
        return documents
            .where((doc) =>
                doc.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshDocuments();
        },
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: false,
              //title: Text('EFE')
              bottom: AppBar(
                automaticallyImplyLeading: false,
                title: Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                        _refreshDocuments();
                      },
                      decoration: InputDecoration(
                        hintText: 'Ara...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
              actions: [],
            ),
            FutureBuilder<List<Document>>(
              future: _documentsFuture, // Belgeleri asenkron olarak yükler
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Veri yükleniyor ise yükleme göstergesi göster
                  return SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  // Hata oluştuysa hata mesajı göster
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                          'Belgeler yüklenirken bir hata oluştu: ${snapshot.error}'),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  // Hiç belge yoksa bilgi mesajı göster
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Henüz belgeniz yok.\nYeni bir tane eklemek için kamera ikonuna dokunun.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ),
                  );
                }

                // Belgeler yüklendiyse listeyi göster
                final documents = snapshot.data!;
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = documents[index];
                      // Belgenin ilk sayfasının görüntüsünü almak için DocumentPage modelini kullanıyoruz
                      final firstPage = doc.pages.first;
                      final imagePath =
                          firstPage.processedImagePath ?? firstPage.imagePath;
                      final imageFile = File(imagePath);

                      return Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        elevation: 2,
                        child: ListTile(
                          leading: imageFile.existsSync()
                              ? Image.file(imageFile,
                                  width: 60, height: 80, fit: BoxFit.cover)
                              : Container(
                                  width: 60,
                                  height: 80,
                                  color: Colors.grey.shade300,
                                  child: Icon(Icons.broken_image,
                                      color: Colors.grey.shade600)),
                          title: Text(doc.name,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${formatDateTime(doc.updatedAt)}'),
                          onTap: () {
                            // Belge detay ekranına git. Dönüşte listeyi yenile.
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      DocumentsScreen(document: doc)),
                            ).then((_) => _refreshDocuments());
                          },
                        ),
                      );
                    },
                    childCount: documents.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onPressed,
        child: Icon(Icons.camera_alt),
        tooltip: 'Yeni Belge Tara',
      ),
    );
  }

  void onPressed() async {
    try {
      final pictures = await CunningDocumentScanner.getPictures(
              iosScannerOptions: IosScannerOptions(
            imageFormat: IosImageFormat.jpg,
            jpgCompressionQuality: 0.5,
          )) ??
          [];

      if (!mounted) return;

      if (pictures.isNotEmpty) {
        // Yeni bir belge oluştur ve kaydet
        await _documentService.createDocumentFromImages(pictures);
        // Belge listesini yenile
        _refreshDocuments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hiç resim seçilmedi')),
        );
      }
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: ${exception.toString()}')),
      );
    }
  }
}