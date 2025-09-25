import 'package:aara_bill_software/db/db_helper.dart';
import 'package:aara_bill_software/pages/invoice_detail_page.dart';
import 'package:flutter/material.dart';

class InvoiceListPage extends StatefulWidget {
  @override
  _InvoiceListPageState createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  List<Map<String, dynamic>> invoices = [];
  String filter = "today";

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    DateTime now = DateTime.now();
    DateTime? start, end;

    if (filter == "today") {
      start = DateTime(now.year, now.month, now.day);
      end = start.add(Duration(days: 1));
    } else if (filter == "week") {
      start = now.subtract(Duration(days: now.weekday - 1));
      end = start.add(Duration(days: 7));
    } else if (filter == "month") {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1);
    }

    final data = await DBHelper.getInvoices(startDate: start, endDate: end);
    setState(() {
      invoices = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Invoices")),
      body: Column(
        children: [
          // 🔹 Filter buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ChoiceChip(
                label: Text("Today"),
                selected: filter == "today",
                onSelected: (_) {
                  setState(() => filter = "today");
                  _loadInvoices();
                },
              ),
              ChoiceChip(
                label: Text("Week"),
                selected: filter == "week",
                onSelected: (_) {
                  setState(() => filter = "week");
                  _loadInvoices();
                },
              ),
              ChoiceChip(
                label: Text("Month"),
                selected: filter == "month",
                onSelected: (_) {
                  setState(() => filter = "month");
                  _loadInvoices();
                },
              ),
              ChoiceChip(
                label: Text("Custom"),
                selected: filter == "custom",
                onSelected: (value) {
                  showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  ).then((range) {
                    if (range != null) {
                      DBHelper.getInvoices(
                        startDate: range.start,
                        endDate: range.end,
                      ).then((data) {
                        setState(() => invoices = data);
                      });
                    }
                  });
                },
              ),
            ],
          ),
          Divider(),
          // 🔹 Invoice List
          Expanded(
            child: ListView.builder(
              itemCount: invoices.length,
              itemBuilder: (_, i) {
                final inv = invoices[i];
                return ListTile(
                  title: Text("Invoice #${inv['id']}"),
                  subtitle: Text("Date: ${inv['date']}"),
                  trailing: Text("₹${inv['total']}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvoiceDetailPage(invoice: inv),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
