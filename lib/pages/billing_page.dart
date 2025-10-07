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
  Map<int, TextEditingController> qtyControllers = {};

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
        qtyControllers.remove(productId);
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

  Future<void> _saveInvoice() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            InvoicePage(products: products, selectedProducts: selectedProducts),
      ),
    );
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
              _buildTextField(categoryCtrl, 'Category'),
              _buildTextField(itemNoCtrl, 'Item No'),
              _buildTextField(nameCtrl, 'Product Name'),
              _buildTextField(qtyCtrl, 'Quantity', isNumber: true),
              _buildTextField(priceCtrl, 'Price', isNumber: true),
              _buildTextField(sgstCtrl, 'SGST %', isNumber: true),
              _buildTextField(cgstCtrl, 'CGST %', isNumber: true),
              _buildTextField(stockCtrl, 'Stock', isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
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
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Billing"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: products.isEmpty
            ? const Center(
                child: Text(
                  "No products found. Please add a product.",
                  style: TextStyle(fontSize: 16),
                ),
              )
            : ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  final isSelected = selectedProducts.containsKey(p['id']);
                  final qty = selectedProducts[p['id']] ?? 1;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Colors.indigo : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        p['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        "₹${p['price']} | Stock: ${p['stock']}",
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                      trailing: isSelected
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _changeQty(p['id'] as int, -1),
                                    icon: const Icon(
                                      Icons.remove,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: TextField(
                                      controller: qtyControllers[p['id']],
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) {
                                        final v = int.tryParse(val) ?? 0;
                                        setState(() {
                                          if (v > 0) {
                                            selectedProducts[p['id']] = v;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _changeQty(p['id'] as int, 1),
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.add_shopping_cart,
                                color: Colors.indigo,
                              ),
                              onPressed: () => _toggleProduct(p['id'] as int),
                            ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add Product"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: selectedProducts.isEmpty ? null : _saveInvoice,
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            label: const Text(
              "Generate Invoice",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
