class Product {
  final int? id;
  final String category;
  final String itemNo;
  final String name;
  final int quantity;
  final double price;
  final double sgst;
  final double cgst;
  final int? stock;

  Product({
    this.id,
    required this.category,
    required this.itemNo,
    required this.name,
    required this.quantity,
    required this.price,
    required this.sgst,
    required this.cgst,
    required this.stock,
  });

  double get totalGst => sgst + cgst;
  double get totalPrice => (price * quantity) + totalGst;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'itemNo': itemNo,
      'name': name,
      'quantity': quantity,
      'price': price,
      'sgst': sgst,
      'cgst': cgst,
      'stock': stock,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      category: map['category'],
      itemNo: map['itemNo'],
      name: map['name'],
      quantity: map['quantity'],
      price: map['price'],
      sgst: map['sgst'],
      cgst: map['cgst'],
      stock: map['stock'],
    );
  }

  /// ✅ Add copyWith here
  Product copyWith({
    int? id,
    String? category,
    String? itemNo,
    String? name,
    int? quantity,
    double? price,
    double? sgst,
    double? cgst,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      category: category ?? this.category,
      itemNo: itemNo ?? this.itemNo,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      sgst: sgst ?? this.sgst,
      cgst: cgst ?? this.cgst,
      stock: stock ?? this.stock,
    );
  }
}
