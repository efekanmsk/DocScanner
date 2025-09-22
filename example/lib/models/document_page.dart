// lib/models/document_page.dart

class DocumentPage {
  final String id;
  final String imagePath;           // Orijinal çekilen fotoğrafın yolu
  final String? processedImagePath; // İşlenmiş (kırpılmış, filtre uygulanmış) fotoğrafın yolu
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentPage({
    required this.id,
    required this.imagePath,
    this.processedImagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  // Nesnenin bir kopyasını oluştururken belirli alanları güncellemeyi sağlar.
  DocumentPage copyWith({
    String? id,
    String? imagePath,
    String? processedImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentPage(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      processedImagePath: processedImagePath ?? this.processedImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Nesneyi JSON'a dönüştürmek için Map'e çevirir.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'processedImagePath': processedImagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // JSON'dan (Map'ten) nesne oluşturur.
  factory DocumentPage.fromMap(Map<String, dynamic> map) {
    return DocumentPage(
      id: map['id'],
      imagePath: map['imagePath'],
      processedImagePath: map['processedImagePath'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}