// pages/product_page.dart
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
        title: Text(product == null ? 'Add Product' : 'Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(hintText: 'Category'),
              ),
              TextField(
                controller: itemNoCtrl,
                decoration: const InputDecoration(hintText: 'Item No'),
              ),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'Product Name'),
              ),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(hintText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(hintText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: sgstCtrl,
                decoration: const InputDecoration(hintText: 'SGST %'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: cgstCtrl,
                decoration: const InputDecoration(hintText: 'CGST %'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockCtrl,
                decoration: const InputDecoration(hintText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (ctx, i) {
          final p = products[i];
          return ListTile(
            title: Text("${p.name} (${p.itemNo})"),
            subtitle: Text(
              "Qty: ${p.quantity}, Price: ₹${p.price}, GST: ${p.totalGst}%",
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showAddDialog(product: p),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await DBHelper.deleteProduct(p.id!);
                    _loadProducts();
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //DBHelper.resetTables();
          _showAddDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
