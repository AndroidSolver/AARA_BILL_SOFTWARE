import 'package:aara_bill_software/db/db_helper.dart';
import 'package:aara_bill_software/pages/dashboard_page.dart';
import 'package:flutter/material.dart';

class InvoicePage extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Map<int, int> selectedProducts;

  InvoicePage({required this.products, required this.selectedProducts});

  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  late Map<int, int> items; // editable copy

  @override
  void initState() {
    super.initState();
    items = Map.from(widget.selectedProducts);
  }

  void _changeQty(int productId, int delta) {
    setState(() {
      final qty = (items[productId] ?? 0) + delta;
      if (qty <= 0) {
        items.remove(productId); // remove row if qty zero
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

  double discount = 0.0;
  double offer = 0.0;
  double total = 0.0;

  @override
  Widget build(BuildContext context) {
    total = subtotal - discount - offer;

    return Scaffold(
      appBar: AppBar(title: Text("Invoice Preview")),
      body: Column(
        children: [
          // 🔹 Top 50% – Product List
          Expanded(
            flex: 5,
            child: ListView(
              children: items.entries.map((entry) {
                final product = widget.products.firstWhere(
                  (p) => p['id'] == entry.key,
                );
                final qty = entry.value;

                return ListTile(
                  title: Text("${product['name']} - ₹${product['price']}"),
                  subtitle: Text("Quantity: $qty"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () => _changeQty(entry.key, -1),
                      ),
                      Text("$qty"),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => _changeQty(entry.key, 1),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // 🔹 Bottom 40% – Summary + Print
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.grey[200],
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Subtotal: ₹$subtotal"),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text("Discount:")),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(hintText: "0"),
                          onChanged: (val) {
                            setState(() {
                              discount = double.tryParse(val) ?? 0.0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text("Offer:")),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(hintText: "0"),
                          onChanged: (val) {
                            setState(() {
                              offer = double.tryParse(val) ?? 0.0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                  Text(
                    "Total: ₹$total",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // 👉 Here you can call DB insert + print

                      final db = await DBHelper.db;
                      // Calculated Total

                      setState(() {
                        total = subtotal - discount - offer;
                      });
                      // insert invoice
                      final invoiceId = await db.insert("invoices", {
                        "date": DateTime.now().millisecondsSinceEpoch,
                        "total": total,
                      });

                      for (final entry in items.entries) {
                        final product = widget.products.firstWhere(
                          (p) => p['id'] == entry.key,
                        );
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
                      }

                      if (invoiceId > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Invoice Saved & Printed")),
                        );

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DashboardPage(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    icon: Icon(Icons.print),
                    label: Text("Print Invoice"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(16),
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
}
