import 'package:aara_bill_software/db/db_helper.dart';
import 'package:aara_bill_software/models/product.dart';
import 'package:aara_bill_software/pages/invoice_page.dart';
import 'package:flutter/material.dart';

class BillingPage extends StatefulWidget {
  @override
  _BillingPageState createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  List<Map<String, dynamic>> products = [];
  Map<int, int> selectedProducts = {}; // productId → quantity
  Map<int, TextEditingController> qtyControllers = {}; // productId → quantity

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final db = await DBHelper.db;
    final data = await db.query("products");
    setState(() {
      products = data;
    });
  }

  void _toggleProduct(int productId) {
    setState(() {
      if (selectedProducts.containsKey(productId)) {
        selectedProducts.remove(productId);
        qtyControllers.remove(productId); // also remove controller
      } else {
        selectedProducts[productId] = 1;
        qtyControllers[productId] = TextEditingController(text: "1");
      }
    });
  }

  void _changeQty(int productId, int delta) {
    setState(() {
      final qty = (selectedProducts[productId] ?? 0) + delta;
      if (qty <= 0) {
        selectedProducts.remove(productId);
      } else {
        selectedProducts[productId] = qty;
      }
    });
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

  Future<void> _saveInvoice() async {
    /*final db = await DBHelper.db;

    // calculate total
    double total = 0;
    for (final entry in selectedProducts.entries) {
      final product = products.firstWhere((p) => p['id'] == entry.key);
      total += (product['price'] as double) * entry.value;
    }

    // insert invoice
    final invoiceId = await db.insert("invoices", {
      "date": DateTime.now().toIso8601String(),
      "total": total,
    });

    // insert invoice_items + update stock
    for (final entry in selectedProducts.entries) {
      final product = products.firstWhere((p) => p['id'] == entry.key);
      final price = product['price'] as double;
      final qty = entry.value;

      await db.insert("invoice_items", {
        "invoiceId": invoiceId,
        "productId": entry.key,
        "quantity": qty,
        "price": price,
      });

      // reduce stock
      final newStock = (product['stock'] as int) - qty;
      await db.update(
        "products",
        {"stock": newStock},
        where: "id = ?",
        whereArgs: [entry.key],
      );
    } */

    // ScaffoldMessenger.of(
    //   context,
    // ).showSnackBar(SnackBar(content: Text("Invoice #$invoiceId saved!")));

    // _loadProducts(); // reload stock

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            InvoicePage(products: products, selectedProducts: selectedProducts),
      ),
    );

    // Clear selection after save
    // setState(() {
    //   selectedProducts.clear();

    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Billing")),
      body: ListView(
        children: products.map((p) {
          final isSelected = selectedProducts.containsKey(p['id']);
          final qty = selectedProducts[p['id']] ?? 0;

          return ListTile(
            title: Text("${p['name']} - ₹${p['price']} (Stock: ${p['stock']})"),
            trailing: isSelected
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _changeQty(p['id'] as int, -1),
                        icon: Icon(Icons.remove),
                      ),
                      // Text("$qty"),

                      // Editable TextField for Quantity
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: qtyControllers[p['id']],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.all(6),
                          ),
                          onChanged: (value) {
                            final newQty = int.tryParse(value) ?? 0;
                            setState(() {
                              if (newQty <= 0) {
                                selectedProducts.remove(p['id']);
                                qtyControllers.remove(p['id']);
                              } else {
                                selectedProducts[p['id']] = newQty;
                              }
                            });
                          },
                        ),
                      ),

                      IconButton(
                        onPressed: () => _changeQty(p['id'] as int, 1),
                        icon: Icon(Icons.add),
                      ),
                    ],
                  )
                : IconButton(
                    icon: Icon(Icons.add_shopping_cart),
                    onPressed: () => _toggleProduct(p['id'] as int),
                  ),
          );
        }).toList(),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _showAddDialog,
            label: Text("Add Product"),
            icon: Icon(Icons.add),
          ),
          SizedBox(width: 12), // spacing between FABs
          FloatingActionButton.extended(
            onPressed: _saveInvoice,
            label: Text("Load Invoice"),
            icon: Icon(Icons.upload),
          ),
        ],
      ),
    );
  }

  void _changeQtyDirect(int productId, int qty) {
    setState(() {
      if (qty <= 0) {
        selectedProducts.remove(productId);
      } else {
        selectedProducts[productId] = qty;
      }
    });
  }

  @override
  void dispose() {
    for (var controller in qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
