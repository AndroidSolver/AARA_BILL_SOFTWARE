import 'package:aara_bill_software/settings/low_stock_state.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../db/db_helper.dart';

class LowStockPage extends StatefulWidget {
  final List<Product> products;
  const LowStockPage({super.key, required this.products});

  @override
  State<LowStockPage> createState() => _LowStockPageState();
}

class _LowStockPageState extends State<LowStockPage> {
  late List<Product> lowStockProducts;
  ValueNotifier<List<Product>> lowStockNotifier = ValueNotifier([]);
  @override
  void initState() {
    super.initState();
    lowStockProducts = widget.products;
  }

  Future<void> _updateStock(Product product) async {
    final controller = TextEditingController(text: product.stock.toString());

    final newStock = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Update Stock"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: "New Quantity"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(controller.text) ?? product.stock;
              print('updatedStock====$val');
              final updated = product.copyWith(stock: val);
              await DBHelper.updateProduct(updated);

              // after update, re-calculate low stock count
              final lowStockProducts = await DBHelper.getLowStockProducts();
              StockAppState.lowStockCount.value = lowStockProducts.length;

              Navigator.pop(context, val);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );

    if (newStock != null && newStock != product.stock) {
      final updatedProduct = product.copyWith(
        stock: newStock,
      ); // make sure Product has copyWith
      await DBHelper.updateProduct(updatedProduct);

      setState(() {
        final index = lowStockProducts.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          lowStockProducts[index] = updatedProduct;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Low Stock Items")),
      body: ListView.builder(
        itemCount: lowStockProducts.length,
        itemBuilder: (_, index) {
          final product = lowStockProducts[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text("Stock: ${product.stock}"),
            trailing: IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _updateStock(product),
            ),
          );
        },
      ),
    );
  }
}
