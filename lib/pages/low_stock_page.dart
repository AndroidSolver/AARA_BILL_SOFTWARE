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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.inventory_2_rounded, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text("Update Stock"),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Enter New Quantity",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_rounded),
            label: const Text("Save"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final val = int.tryParse(controller.text) ?? product.stock;
              final updated = product.copyWith(stock: val);
              await DBHelper.updateProduct(updated);

              // refresh low stock count
              final lowStockProducts = await DBHelper.getLowStockProducts();
              StockAppState.lowStockCount.value = lowStockProducts.length;

              // close dialog
              Navigator.pop(context, val);
            },
          ),
        ],
      ),
    );

    // if (newStock != null && newStock != product.stock) {
    //   final updatedProduct = product.copyWith(stock: newStock);
    //   await DBHelper.updateProduct(updatedProduct);

    //   setState(() {
    //     final index = lowStockProducts.indexWhere((p) => p.id == product.id);
    //     if (index != -1) {
    //       lowStockProducts[index] = updatedProduct;
    //     }
    //   });
    // }

    if (newStock != null && newStock != product.stock) {
      // refresh the low stock list from DB
      final updatedList = await DBHelper.getLowStockProducts();
      setState(() {
        lowStockProducts = updatedList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Low Stock Items",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: lowStockProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 80,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "All stocks are sufficient!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: ListView.builder(
                itemCount: lowStockProducts.length,
                itemBuilder: (_, index) {
                  final product = lowStockProducts[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.redAccent.withOpacity(0.1),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                        ),
                      ),
                      title: Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        "Current Stock: ${product.stock}",
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        tooltip: "Update Stock",
                        onPressed: () => _updateStock(product),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
