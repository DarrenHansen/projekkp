/// Model Item
class Item {
  int? id;
  int invoiceId;
  String productName;
  String description;
  double price;
  int qty;

  Item({
    this.id,
    required this.invoiceId,
    required this.productName,
    this.description = '',
    required this.price,
    required this.qty,
  });

  /// Total per item = harga x jumlah
  double get total => price * qty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_name': productName,
      'description': description,
      'price': price,
      'qty': qty,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      invoiceId: map['invoice_id'] ?? 0,
      productName: map['product_name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      qty: (map['qty'] as num?)?.toInt() ?? 0,
    );
  }

  Item copyWith({
    int? id,
    int? invoiceId,
    String? productName,
    String? description,
    double? price,
    int? qty,
  }) {
    return Item(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      price: price ?? this.price,
      qty: qty ?? this.qty,
    );
  }
}
