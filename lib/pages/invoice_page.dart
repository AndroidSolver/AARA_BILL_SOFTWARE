import 'package:aara_bill_software/db/db_helper.dart';
import 'package:aara_bill_software/pages/dashboard_page.dart';
import 'package:flutter/material.dart';

class InvoicePage extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Map<int, int> selectedProducts;

  const InvoicePage({required this.products, required this.selectedProducts});

  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  late Map<int, int> items;
  double discount = 0.0;
  double offer = 0.0;
  double total = 0.0;

  @override
  void initState() {
    super.initState();
    items = Map.from(widget.selectedProducts);
  }

  void _changeQty(int productId, int delta) {
    setState(() {
      final qty = (items[productId] ?? 0) + delta;
      if (qty <= 0) {
        items.remove(productId);
      } else {
        items[productId] = qty;
      }
    });
  }

  double get subtotal {
    double total = 0;
    for (final entry in items.entries) {
      final product = widget.products.firstWhere((p) => p['id'] == entry.key);
      total += (product['price'] as num).toDouble() * entry.value;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    total = subtotal - discount - offer;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice Preview"),
        backgroundColor: Colors.indigo,
        centerTitle: true,
        elevation: 2,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // 🔹 Product List
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: items.isEmpty
                      ? const Center(
                          child: Text(
                            "No products added",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = items.entries.elementAt(index);
                            final product = widget.products.firstWhere(
                              (p) => p['id'] == entry.key,
                            );
                            final qty = entry.value;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              title: Text(
                                product['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                "₹${product['price']}  ×  $qty",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _changeQty(product['id'], -1),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  Text(
                                    "$qty",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _changeQty(product['id'], 1),
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),

          // 🔹 Summary Section
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    offset: Offset(0, -2),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAmountRow("Subtotal", subtotal),
                  const SizedBox(height: 10),
                  _buildEditableRow(
                    "Discount",
                    (val) =>
                        setState(() => discount = double.tryParse(val) ?? 0.0),
                  ),
                  const SizedBox(height: 10),
                  _buildEditableRow(
                    "Offer",
                    (val) =>
                        setState(() => offer = double.tryParse(val) ?? 0.0),
                  ),
                  const Divider(height: 24, thickness: 1.2),
                  _buildTotalRow("Total", total),

                  const Spacer(),
                  // Print Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: items.isEmpty ? null : _saveInvoice,
                      icon: const Icon(Icons.print),
                      label: const Text(
                        "Save & Print Invoice",
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        Text(
          "₹${value.toStringAsFixed(2)}",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildEditableRow(String label, Function(String) onChange) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextField(
            onChanged: onChange,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: "0.0",
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          "₹${value.toStringAsFixed(2)}",
          style: const TextStyle(
            fontSize: 20,
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _saveInvoice() async {
    final db = await DBHelper.db;
    final computedTotal = subtotal - discount - offer;

    final invoiceId = await db.insert("invoices", {
      "date": DateTime.now().millisecondsSinceEpoch,
      "total": computedTotal,
    });

    for (final entry in items.entries) {
      final product = widget.products.firstWhere((p) => p['id'] == entry.key);
      final price = (product['price'] as num).toDouble();
      final qty = entry.value;

      await db.insert("invoice_items", {
        "invoiceId": invoiceId,
        "productId": entry.key,
        "quantity": qty,
        "price": price,
      });

      final newStock = (product['stock'] as int) - qty;
      await db.update(
        "products",
        {"stock": newStock},
        where: "id = ?",
        whereArgs: [entry.key],
      );
    }

    if (invoiceId > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invoice saved & printed successfully")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
        (route) => false,
      );
    }
  }
}
