import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/product.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final list = await DBHelper.getProducts();
    setState(() => products = list);
  }

  Future<void> _showAddDialog({Product? product}) async {
    final categoryCtrl = TextEditingController(text: product?.category ?? '');
    final itemNoCtrl = TextEditingController(text: product?.itemNo ?? '');
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final qtyCtrl = TextEditingController(
      text: product?.quantity.toString() ?? '',
    );
    final priceCtrl = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    final sgstCtrl = TextEditingController(
      text: product?.sgst.toString() ?? '',
    );
    final cgstCtrl = TextEditingController(
      text: product?.cgst.toString() ?? '',
    );
    final stockCtrl = TextEditingController(
      text: product?.stock.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              product == null ? Icons.add_box_rounded : Icons.edit_note_rounded,
              color: Colors.blueAccent,
            ),
            const SizedBox(width: 8),
            Text(
              product == null ? 'Add New Product' : 'Edit Product',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildInputField(
                categoryCtrl,
                'Category',
                Icons.category_rounded,
              ),
              _buildInputField(
                itemNoCtrl,
                'Item Number',
                Icons.confirmation_number_rounded,
              ),
              _buildInputField(
                nameCtrl,
                'Product Name',
                Icons.shopping_bag_rounded,
              ),
              _buildInputField(
                qtyCtrl,
                'Quantity',
                Icons.inventory_rounded,
                isNumber: true,
              ),
              _buildInputField(
                priceCtrl,
                'Price',
                Icons.currency_rupee_rounded,
                isNumber: true,
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      sgstCtrl,
                      'SGST %',
                      Icons.percent_rounded,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputField(
                      cgstCtrl,
                      'CGST %',
                      Icons.percent_rounded,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              _buildInputField(
                stockCtrl,
                'Stock',
                Icons.storage_rounded,
                isNumber: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final newProduct = Product(
                id: product?.id,
                category: categoryCtrl.text,
                itemNo: itemNoCtrl.text,
                name: nameCtrl.text,
                quantity: int.tryParse(qtyCtrl.text) ?? 0,
                price: double.tryParse(priceCtrl.text) ?? 0,
                sgst: double.tryParse(sgstCtrl.text) ?? 0,
                cgst: double.tryParse(cgstCtrl.text) ?? 0,
                stock: int.tryParse(stockCtrl.text) ?? 0,
              );

              if (product == null) {
                await DBHelper.insertProduct(newProduct);
              } else {
                await DBHelper.updateProduct(newProduct);
              }

              if (mounted) Navigator.pop(context);
              _loadProducts();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Product List',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: products.isEmpty
          ? const Center(
              child: Text(
                "No products found.\nTap + to add one!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(10),
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (ctx, i) {
                  final p = products[i];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent.withOpacity(0.1),
                        child: const Icon(
                          Icons.shopping_bag,
                          color: Colors.blueAccent,
                        ),
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        "Item No: ${p.itemNo}\nQty: ${p.quantity}, Price: ₹${p.price.toStringAsFixed(2)}, GST: ${p.totalGst}%",
                        style: const TextStyle(height: 1.3),
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            tooltip: "Edit Product",
                            onPressed: () => _showAddDialog(product: p),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            tooltip: "Delete Product",
                            onPressed: () async {
                              await DBHelper.deleteProduct(p.id!);
                              _loadProducts();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add),
        label: const Text("Add Product"),
        onPressed: () => _showAddDialog(),
      ),
    );
  }
}
