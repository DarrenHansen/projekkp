/// Model Product / Barang
class Product {
  int? id;
  String name;
  String description;
  double price;
  String photoPath;
  String createdAt;

  Product({
    this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.photoPath = '',
    this.createdAt = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'photo_path': photoPath,
      'created_at': createdAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      photoPath: map['photo_path'] ?? '',
      createdAt: map['created_at'] ?? '',
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? photoPath,
    String? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
