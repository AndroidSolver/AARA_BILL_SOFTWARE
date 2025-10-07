import 'package:aara_bill_software/db/db_helper.dart';
import 'package:aara_bill_software/pages/invoice_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  _InvoiceListPageState createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  List<Map<String, dynamic>> invoices = [];
  String filter = "today";
  final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

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
      end = start.add(const Duration(days: 1));
    } else if (filter == "week") {
      start = now.subtract(Duration(days: now.weekday - 1));
      end = start.add(const Duration(days: 7));
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
      appBar: AppBar(
        title: const Text(
          "Invoices",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildFilterChips(),
          const Divider(height: 20),
          Expanded(
            child: invoices.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadInvoices,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: invoices.length,
                      itemBuilder: (_, i) {
                        final inv = invoices[i];
                        final date = DateTime.fromMillisecondsSinceEpoch(
                          inv['date'] ?? 0,
                        );
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              "Invoice #${inv['id']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              "Date: ${dateFormatter.format(date)}",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: Text(
                              "₹${inv['total']}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      InvoiceDetailPage(invoice: inv),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ["today", "week", "month", "custom"];
    final filterLabels = {
      "today": "Today",
      "week": "This Week",
      "month": "This Month",
      "custom": "Custom",
    };

    return SizedBox(
      height: 45,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final f = filters[index];
          return ChoiceChip(
            label: Text(filterLabels[f]!),
            selected: filter == f,
            labelStyle: TextStyle(
              color: filter == f ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
            selectedColor: Colors.blueAccent,
            backgroundColor: Colors.grey[200],
            onSelected: (_) async {
              if (f == "custom") {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (range != null) {
                  final data = await DBHelper.getInvoices(
                    startDate: range.start,
                    endDate: range.end,
                  );
                  setState(() {
                    filter = f;
                    invoices = data;
                  });
                }
              } else {
                setState(() => filter = f);
                _loadInvoices();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Text(
              "No Invoices Found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              "Try changing the date filter or refresh the page.",
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
