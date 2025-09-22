// lib/models/document.dart

import 'document_page.dart'; // DocumentPage modelini import ediyoruz

class Document {
  final String id;
  final String name;
  final List<DocumentPage> pages; // Belgenin sayfaları artık DocumentPage nesnelerinin listesi
  final DateTime createdAt;
  final DateTime updatedAt;

  Document({
    required this.id,
    required this.name,
    required this.pages,
    required this.createdAt,
    required this.updatedAt,
  });

  // Nesnenin bir kopyasını oluştururken belirli alanları güncellemeyi sağlar.
  Document copyWith({
    String? id,
    String? name,
    List<DocumentPage>? pages, // Kopyalama işleminde de List<DocumentPage> beklenir
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      pages: pages ?? this.pages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Nesneyi JSON'a dönüştürmek için Map'e çevirir.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      // Her bir DocumentPage nesnesini de kendi toMap metoduyla Map'e çeviriyoruz
      'pages': pages.map((page) => page.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // JSON'dan (Map'ten) nesne oluşturur.
  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      name: map['name'],
      // Map listesini DocumentPage nesnelerinin listesine çeviriyoruz
      pages: (map['pages'] as List)
          .map((pageData) => DocumentPage.fromMap(pageData))
          .toList(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}