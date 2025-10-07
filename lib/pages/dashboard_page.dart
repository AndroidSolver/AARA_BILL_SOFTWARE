import 'package:aara_bill_software/db/db_helper.dart';
import 'package:aara_bill_software/models/product.dart';
import 'package:aara_bill_software/pages/billing_page.dart';
import 'package:aara_bill_software/pages/invoice_list_page.dart';
import 'package:aara_bill_software/pages/low_stock_page.dart';
import 'package:aara_bill_software/settings/low_stock_state.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int invoiceCount = 0;
  double todaySalesCount = 0;
  double weeklySalesCount = 0;
  double monthlySalesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      getInvoiceCountToday(),
      getTotalSalesToday(),
      getTotalSalesWeekly(),
      getTotalSalesMonthly(),
      _loadStockData(),
    ]);
  }

  Future<int> getInvoiceCountToday() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final invoices = await DBHelper.getInvoices(startDate: start, endDate: end);
    setState(() => invoiceCount = invoices.length);
    return invoices.length;
  }

  Future<void> getTotalSalesToday() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final todaySales = await DBHelper.getSalesTotal(
      startDate: start,
      endDate: end,
    );
    setState(() => todaySalesCount = todaySales);
  }

  Future<void> getTotalSalesWeekly() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final weeklySales = await DBHelper.getSalesTotal(
      startDate: startOfWeek,
      endDate: endOfWeek,
    );
    setState(() => weeklySalesCount = weeklySales);
  }

  Future<void> getTotalSalesMonthly() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);
    final monthlySales = await DBHelper.getSalesTotal(
      startDate: startOfMonth,
      endDate: startOfNextMonth,
    );
    setState(() => monthlySalesCount = monthlySales);
  }

  Future<void> _loadStockData() async {
    final lowStock = await DBHelper.getLowStockProducts();
    StockAppState.lowStockCount.value = lowStock.length;
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      DashboardCard(title: "Today Sales", value: "₹$todaySalesCount"),
      DashboardCard(title: "Weekly Sales", value: "₹$weeklySalesCount"),
      DashboardCard(title: "Monthly Sales", value: "₹$monthlySalesCount"),
      DashboardCard(title: "Invoices", value: invoiceCount.toString()),
      ValueListenableBuilder<int>(
        valueListenable: StockAppState.lowStockCount,
        builder: (_, value, __) =>
            DashboardCard(title: "Low Stocks", value: "$value Items"),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        elevation: 3,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: cards,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BillingPage()),
                ),
                icon: const Icon(Icons.shopping_cart),
                label: const Text("Show Products"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;

  const DashboardCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (title == "Invoices") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => InvoiceListPage()),
          );
        } else if (title == "Low Stocks") {
          final lowStockItems = await DBHelper.getLowStockProducts();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LowStockPage(products: lowStockItems),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
