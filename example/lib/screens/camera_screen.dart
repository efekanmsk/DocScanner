// lib/screens/camera_screen.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

import 'crop_screen.dart'; // FileImage için gerekli

// NOT: Bu ekran camera plugin'i kullanıyor
// cunning_document_scanner değil!

// Eğer crop_screen.dart dosyanız yoksa, aşağıdaki import'u kaldırın
// import 'crop_screen.dart';

class CameraScreen extends StatefulWidget {
  // HomeScreen'den gelen kamera listesini burada bekliyoruz
  final List<CameraDescription> cameras;

  const CameraScreen({
    Key? key,
    required this.cameras, // Kamerayı zorunlu parametre olarak tanımlıyoruz
  }) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  CameraDescription? _selectedCamera; // Seçilen kamera (varsayılan olarak ilk kamera)
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isMultiCaptureMode = false; // Yeni: Çoklu çekim modu
  final List<XFile> _capturedFiles = []; // Yeni: Çekilen fotoğrafları tutacak liste

  @override
  void initState() {
    super.initState();
    print("CameraScreen initState: Kamera başlatılıyor.");
    print("CameraScreen: NEW CODE IS RUNNING!"); // Added this line for verification
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Kameranın başlatılıp başlatılmadığını kontrol et
    if (_controller != null && _controller!.value.isInitialized) {
      return;
    }

    if (widget.cameras.isEmpty) {
      print("Kamera ekranı: Kullanılabilir kamera yok.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanılabilir kamera bulunamadı.')),
        );
        Navigator.pop(context, false); // Kamera yoksa bir önceki ekrana dön
      }
      return;
    }

    // Varsayılan olarak ilk kamerayı seç
    _selectedCamera = widget.cameras.first;

    _controller = CameraController(
      _selectedCamera!,
      ResolutionPreset.high, // Yüksek çözünürlük
      enableAudio: false, // Ses kaydını devre dışı bırak
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
      print("CameraScreen: Kamera başarıyla başlatıldı.");
    } catch (e) {
      print("Kamera başlatılırken hata: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kamera başlatılırken hata: ${e.toString()}')),
      );
      // Hata durumunda da geri dön
      Navigator.pop(context, false);
    }
  }

  // Fotoğraf çekme metodu
  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _controller == null || _isCapturing) {
      print("Kamera hazır değil veya zaten çekim yapılıyor.");
      return;
    }

    if (!_controller!.value.isInitialized) {
      print("Kamera kontrolcüsü başlatılmamış.");
      return;
    }

    setState(() {
      _isCapturing = true; // Çekim başladığında butonu devre dışı bırak
    });

    try {
      final XFile file = await _controller!.takePicture(); // Fotoğrafı çek
      print("Fotoğraf çekildi: ${file.path}");

      if (mounted) {
        if (_isMultiCaptureMode) {
          // Çoklu çekim modunda listeye ekle
          setState(() {
            _capturedFiles.add(file);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fotoğraf çekildi! Toplam: ${_capturedFiles.length}'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          // Tekli çekim modunda - kırpma ekranına git veya direkt işle
          // Eğer CropScreen sınıfınız varsa aşağıdaki kodu kullanın:
          /*
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => CropScreen(imagePath: file.path),
            ),
          );
          Navigator.pop(context, result ?? false);
          */

          // Geçici olarak - fotoğraf yolunu yazdırıp geri dön
          print("Tekli çekim tamamlandı: ${file.path}");
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print("Fotoğraf çekilirken hata: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf çekilemedi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false; // Çekim tamamlandığında butonu tekrar etkinleştir
        });
      }
    }
  }

  // Çoklu çekilen fotoğrafları işleme - CropScreen'e gönder
  void _processMultiplePictures() async {
    if (_capturedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Henüz fotoğraf çekilmedi.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print("İşlenecek fotoğraflar:");
    for (var file in _capturedFiles) {
      print(file.path);
    }

    // İlk fotoğrafı CropScreen'e gönder (veya çoklu işleme ekranına yönlendir)
    // Bu kısımda tüm fotoğrafları sırayla işleyebilir veya
    // MultiCropScreen gibi özel bir ekran kullanabilirsiniz

    try {
      // Şimdilik ilk fotoğrafı işle - daha sonra tüm fotoğraflar için genişletilebilir
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => CropScreen(imagePath: _capturedFiles.first.path),
        ),
      );

      // İşlem tamamlandıktan sonra ana ekrana dön
      if (mounted) {
        Navigator.pop(context, result ?? true);
      }
    } catch (e) {
      print("Fotoğraf işleme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf işlenirken hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Belirli bir fotoğrafı listeden sil
  void _removePhoto(int index) {
    setState(() {
      _capturedFiles.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fotoğraf silindi. Kalan: ${_capturedFiles.length}'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Tüm fotoğrafları temizle
  void _clearAllPhotos() {
    if (_capturedFiles.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tüm Fotoğrafları Sil'),
          content: Text('${_capturedFiles.length} fotoğrafı silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              child: Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Sil', style: TextStyle(color: Colors.red)),
              onPressed: () {
                setState(() {
                  _capturedFiles.clear();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tüm fotoğraflar silindi'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose(); // Kamera kontrolcüsünü temizle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Kamera başlatılıyor...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Kamera önizlemesi
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // Üst kısım: Geri butonu ve mod seçimi
          Positioned(
            top: 40,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Geri butonu
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),

                // Çekim modu seçimi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tekli',
                        style: TextStyle(
                          color: _isMultiCaptureMode ? Colors.grey[400] : Colors.white,
                          fontSize: 16,
                          fontWeight: _isMultiCaptureMode ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: _isMultiCaptureMode,
                        onChanged: (value) {
                          setState(() {
                            _isMultiCaptureMode = value;
                            if (!value) {
                              // Tekli moda geçerken fotoğrafları temizle
                              _capturedFiles.clear();
                            }
                          });
                        },
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.blue,
                        inactiveTrackColor: Colors.blue.withOpacity(0.3),
                        activeTrackColor: Colors.green.withOpacity(0.3),
                      ),
                      Text(
                        'Toplu',
                        style: TextStyle(
                          color: _isMultiCaptureMode ? Colors.white : Colors.grey[400],
                          fontSize: 16,
                          fontWeight: _isMultiCaptureMode ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Çoklu çekim modunda temizleme butonu (sağ üst)
          if (_isMultiCaptureMode && _capturedFiles.isNotEmpty)
            Positioned(
              top: 100,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.white, size: 24),
                  onPressed: _clearAllPhotos,
                  tooltip: 'Tümünü Sil',
                ),
              ),
            ),

          // Alt kısım: Fotoğraf çekme butonu ve çoklu çekim kontrolları
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Çoklu çekim modunda çekilen fotoğrafların önizlemesi
                if (_isMultiCaptureMode && _capturedFiles.isNotEmpty)
                  Container(
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 15),
                    child: Column(
                      children: [
                        // Fotoğraf sayısı göstergesi
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            '${_capturedFiles.length} fotoğraf çekildi',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Fotoğraf önizlemeleri
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: _capturedFiles.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white, width: 2),
                                        image: DecorationImage(
                                          image: FileImage(File(_capturedFiles[index].path)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    // Silme butonu
                                    Positioned(
                                      top: -5,
                                      right: -5,
                                      child: GestureDetector(
                                        onTap: () => _removePhoto(index),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 1),
                                          ),
                                          child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Fotoğraf numarası
                                    Positioned(
                                      bottom: 2,
                                      left: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // Butonlar satırı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // İleri butonu (çoklu moddayken ve fotoğraf varsa)
                    if (_isMultiCaptureMode && _capturedFiles.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _processMultiplePictures,
                          icon: const Icon(Icons.arrow_forward, color: Colors.white),
                          label: Text(
                            'İleri (${_capturedFiles.length})',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 100), // Boş alan bırak

                    // Fotoğraf çekme butonu (merkez)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: FloatingActionButton(
                        onPressed: _isCapturing ? null : _takePicture,
                        backgroundColor: _isCapturing ? Colors.grey : Colors.white,
                        heroTag: "camera_button",
                        child: _isCapturing
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                            strokeWidth: 2,
                          ),
                        )
                            : Icon(
                          Icons.camera_alt,
                          color: _isMultiCaptureMode ? Colors.green : Colors.blue,
                          size: 32,
                        ),
                      ),
                    ),

                    // Boş alan (simetri için)
                    const SizedBox(width: 100),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}