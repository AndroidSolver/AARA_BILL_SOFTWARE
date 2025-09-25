import 'package:aara_bill_software/db/db_helper.dart';
import 'package:flutter/material.dart';

class InvoiceDetailPage extends StatefulWidget {
  final Map<String, dynamic> invoice;

  InvoiceDetailPage({required this.invoice});

  @override
  _InvoiceDetailPageState createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final data = await DBHelper.getInvoiceItems(widget.invoice['id']);
    setState(() {
      items = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Invoice #${widget.invoice['id']}")),
      body: Column(
        children: [
          ListTile(
            title: Text("Total: ₹${widget.invoice['total']}"),
            subtitle: Text("Date: ${widget.invoice['date']}"),
          ),
          Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final it = items[i];
                return ListTile(
                  title: Text("Product ID: ${it['productId']}"),
                  subtitle: Text("Qty: ${it['quantity']}"),
                  trailing: Text("₹${it['price']}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
