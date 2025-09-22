// lib/screens/crop_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui'; // Offset için
import 'dart:async'; // Completer için gerekli import
import '../services/image_processor.dart';
import 'document_editor_screen.dart';

class CropScreen extends StatefulWidget {
  final String imagePath;

  CropScreen({required this.imagePath});

  @override
  _CropScreenState createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final ImageProcessor _imageProcessor = ImageProcessor();
  // Dört köşe noktası: top-left, top-right, bottom-right, bottom-left
  // Bunlar orijinal görüntü boyutlarına göre depolanır, render edilirken _widgetSize'a ölçeklenir.
  List<Offset> _rawImageCorners = [];

  Image? _loadedImage; // Görüntüyü yükledikten sonra boyutunu almak için
  Size? _imageSize; // Yüklenen görüntünün gerçek boyutları (piksel cinsinden)
  // _widgetSize artık doğrudan LayoutBuilder tarafından sağlanacak, burada tutmaya gerek kalmayacak.
  // Size? _widgetSize;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print("CropScreen initState: Görüntü yükleniyor ve köşeler algılanıyor.");
    _loadImageAndDetectCorners();
  }

  Future<void> _loadImageAndDetectCorners() async {
    if (mounted) setState(() => _isLoading = true);

    // Görüntüyü yükleyip boyutlarını al
    final Image image = Image.file(File(widget.imagePath));
    final Completer<ImageInfo> completer = Completer();
    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info);
      }),
    );
    final ImageInfo imageInfo = await completer.future;
    _imageSize = Size(imageInfo.image!.width.toDouble(), imageInfo.image!.height.toDouble());
    _loadedImage = image;
    print("CropScreen: Görüntü yüklendi. Gerçek Boyut: $_imageSize");

    try {
      // Köşeleri algıla. Bu fonksiyon her zaman orijinal görüntü boyutlarında köşeler döndürür.
      final detectedCorners = await _imageProcessor.detectDocumentCorners(widget.imagePath);
      if (mounted) {
        setState(() {
          _rawImageCorners = detectedCorners; // Algılanan köşeleri orijinal boyutlarda sakla
          print("CropScreen: Köşeler algılandı (ham): $_rawImageCorners");
        });
      }
    } catch (e) {
      print("CropScreen: Köşe algılama hatası: $e");
      if (mounted) {
        setState(() {
          _rawImageCorners = []; // Hata durumunda boş bırak
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Varsayılan köşeleri orijinal görüntü koordinatlarında ayarlar
  void _setInitialCornersInImageCoords() {
    if (_imageSize == null) {
      print("CropScreen: Hata - _imageSize null olduğu için varsayılan köşe ayarlanamaz.");
      return; // Görüntü boyutu bilinmeden varsayılan köşe ayarlanamaz
    }
    _rawImageCorners = [
      Offset(_imageSize!.width * 0.15, _imageSize!.height * 0.20), // Top-Left
      Offset(_imageSize!.width * 0.85, _imageSize!.height * 0.20), // Top-Right
      Offset(_imageSize!.width * 0.85, _imageSize!.height * 0.80), // Bottom-Right
      Offset(_imageSize!.width * 0.15, _imageSize!.height * 0.80), // Bottom-Left
    ];
    print("CropScreen: Varsayılan köşeler ayarlandı (ham): $_rawImageCorners");
  }

  // Köşeleri orijinal görüntü boyutlarından widget boyutlarına ölçekler
  List<Offset> _scaleCornersToWidget(List<Offset> originalCorners, Size originalSize, Size widgetSize) {
    if (originalSize.width == 0 || originalSize.height == 0 || widgetSize.width == 0 || widgetSize.height == 0) {
      print("CropScreen: Ölçekleme hatası: Boyutlardan biri sıfır. Original: $originalSize, Widget: $widgetSize");
      return originalCorners; // Hata durumunda orijinali döndür
    }
    final double scaleX = widgetSize.width / originalSize.width;
    final double scaleY = widgetSize.height / originalSize.height;
    return originalCorners.map((offset) => Offset(offset.dx * scaleX, offset.dy * scaleY)).toList();
  }

  // Köşeleri widget boyutlarından orijinal görüntü boyutlarına ölçekler
  List<Offset> _scaleCornersToImage(List<Offset> widgetCorners, Size originalSize, Size widgetSize) {
    if (originalSize.width == 0 || originalSize.height == 0 || widgetSize.width == 0 || widgetSize.height == 0) {
      print("CropScreen: Ters ölçekleme hatası: Boyutlardan biri sıfır. Original: $originalSize, Widget: $widgetSize");
      return widgetCorners; // Hata durumunda orijinali döndür
    }
    final double scaleX = originalSize.width / widgetSize.width;
    final double scaleY = originalSize.height / widgetSize.height;
    return widgetCorners.map((offset) => Offset(offset.dx * scaleX, offset.dy * scaleY)).toList();
  }

  // Köşe noktası sürüklendiğinde pozisyonunu günceller
  void _updateCorner(int index, DragUpdateDetails details, Size currentWidgetSize) {
    if (_rawImageCorners.isEmpty || _imageSize == null) {
      print("CropScreen: Köşe güncellenemedi. _rawImageCorners.isEmpty: ${_rawImageCorners.isEmpty}, _imageSize: $_imageSize");
      return;
    }

    // Mevcut widget boyutundaki köşeyi al
    List<Offset> currentWidgetCorners = _scaleCornersToWidget(_rawImageCorners, _imageSize!, currentWidgetSize);
    Offset updatedWidgetCorner = Offset(
      (currentWidgetCorners[index].dx + details.delta.dx).clamp(0.0, currentWidgetSize.width),
      (currentWidgetCorners[index].dy + details.delta.dy).clamp(0.0, currentWidgetSize.height),
    );

    // Güncellenmiş widget boyutundaki köşeyi orijinal görüntü boyutlarına geri ölçekle
    List<Offset> newRawImageCorners = List.from(_rawImageCorners); // Kopyasını al
    newRawImageCorners[index] = _scaleCornersToImage([updatedWidgetCorner], _imageSize!, currentWidgetSize).first;

    setState(() {
      _rawImageCorners = newRawImageCorners;
    });
    print("CropScreen: Köşe $index güncellendi: $updatedWidgetCorner (widget boyutu)");
  }

  // Görüntüyü kırpar ve düzenleyiciye gönderir
  Future<void> _cropAndNavigate(Size currentWidgetSize) async {
    // İşlem devam ediyorsa veya gerekli boyut bilgileri eksikse işlemi durdur
    if (_isLoading || _rawImageCorners.isEmpty || _imageSize == null || currentWidgetSize.isEmpty) {
      if (!mounted) return;
      print("CropScreen: Kırpma işlemi iptal edildi. _isLoading: $_isLoading, _rawImageCorners.isEmpty: ${_rawImageCorners.isEmpty}, _imageSize: $_imageSize, currentWidgetSize: $currentWidgetSize");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kırpma işlemi için gerekli veriler eksik. Lütfen bekleyin veya tekrar deneyin.')),
      );
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      // Kırpma işlemi için _rawImageCorners (orijinal görüntü boyutlarında) kullanılıyor.
      final croppedImagePath = await _imageProcessor.cropAndPerspectiveCorrect(widget.imagePath, _rawImageCorners);
      if (mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentEditorScreen(
              imagePath: croppedImagePath,
              isNewDocument: true,
            ),
          ),
        );
        if (result == true) {
          Navigator.pop(context, true);
        } else {
          Navigator.pop(context, false);
        }
      }
    } catch (e) {
      print('CropScreen: Kırpma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görüntü kırpılırken bir hata oluştu.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _loadedImage == null || _imageSize == null) {
      print("CropScreen Build: Yükleniyor veya görüntü/boyutlar yok. _isLoading: $_isLoading, _loadedImage: ${_loadedImage != null}, _imageSize: $_imageSize");
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Belgeyi Kırp'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, false), // Kırpmayı iptal et ve 'false' dön
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : () {
              print("CropScreen: Refresh butonu tıklandı. Köşeler yeniden algılanacak.");
              _loadImageAndDetectCorners(); // Orijinal görüntüyü ve köşeleri tekrar yükle
            },
            tooltip: 'Köşeleri Tekrar Algıla',
          ),
          Builder(builder: (context) { // _cropAndNavigate fonksiyonu artık bir size parametresi bekliyor
            return TextButton(
              onPressed: _isLoading ? null : () => _cropAndNavigate(MediaQuery.of(context).size),
              child: Text('Kırp', style: TextStyle(color: Colors.white, fontSize: 16)),
            );
          }),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final Size currentWidgetSize = constraints.biggest; // Stack'in mevcut boyutunu alıyoruz
          print("CropScreen LayoutBuilder: currentWidgetSize: $currentWidgetSize");

          // Eğer _rawImageCorners hala boşsa (örn. algılama başarısız olduysa),
          // şimdi _imageSize üzerinden varsayılanları ayarlıyoruz.
          // Bu kontrol LayoutBuilder içinde yapılmalı ki currentWidgetSize bilinsin.
          if (_rawImageCorners.isEmpty && _imageSize != null && !currentWidgetSize.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _setInitialCornersInImageCoords();
                });
              }
            });
            // Varsayılan köşeler ayarlanana kadar yükleniyor göster
            return Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (_rawImageCorners.isEmpty) {
            print("CropScreen LayoutBuilder: _rawImageCorners hala boş. Gösteriliyor: CircularProgressIndicator.");
            return Center(child: CircularProgressIndicator(color: Colors.white));
          }

          // _rawImageCorners'ı currentWidgetSize boyutlarına ölçekle (sadece çizim için)
          List<Offset> _displayCorners = _scaleCornersToWidget(_rawImageCorners, _imageSize!, currentWidgetSize);
          print("CropScreen LayoutBuilder: Ekran köşeleri (ölçekli): $_displayCorners");

          return Stack(
            children: [
              Positioned.fill(
                child: _loadedImage!, // Çekilen fotoğrafı göster
              ),
              // Kırpma çerçevesini çizmek için CustomPaint kullan
              CustomPaint(
                painter: CornerPainter(corners: _displayCorners),
                child: Container(),
              ),
              // Her bir köşe için sürüklenip bırakılabilir daireler
              ..._displayCorners.asMap().entries.map((entry) {
                int index = entry.key;
                Offset offset = entry.value;
                return Positioned(
                  left: offset.dx - 20, // Dairenin merkezini konuma ayarla (daire yarıçapı 20)
                  top: offset.dy - 20,
                  child: GestureDetector(
                    onPanUpdate: (details) => _updateCorner(index, details, currentWidgetSize), // Köşe sürüklenince güncelle
                    child: Container(
                      width: 40, // Dairenin çapı
                      height: 40, // Dairenin çapı
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.5), // Yarı şeffaf mavi
                        shape: BoxShape.circle, // Dairesel şekil
                        border: Border.all(color: Colors.white, width: 2), // Beyaz kenarlık
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}

// Kırpma çerçevesini çizen CustomPainter (değişiklik yok)
class CornerPainter extends CustomPainter {
  final List<Offset> corners;

  CornerPainter({required this.corners});

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(corners[0], corners[1], paint);
    canvas.drawLine(corners[1], corners[2], paint);
    canvas.drawLine(corners[2], corners[3], paint);
    canvas.drawLine(corners[3], corners[0], paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Köşeler değiştiğinde yeniden çiz
    // Listelerin içeriklerinin derinlemesine karşılaştırılması daha doğru olur
    // ancak basit Offset listesi için referans eşitliği genellikle yeterlidir.
    return (oldDelegate as CornerPainter).corners != corners;
  }
}