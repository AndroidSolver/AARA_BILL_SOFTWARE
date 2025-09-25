import 'package:aara_bill_software/db/db_helper.dart';
import 'package:aara_bill_software/models/product.dart';
import 'package:aara_bill_software/pages/billing_page.dart';
import 'package:aara_bill_software/pages/invoice_list_page.dart';
import 'package:aara_bill_software/pages/low_stock_page.dart';
import 'package:aara_bill_software/pages/product_page.dart';
import 'package:aara_bill_software/settings/low_stock_state.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPage();
}

class _DashboardPage extends State<DashboardPage> {
  int invoiceCount = 0;
  double todaySalesCount = 0;
  double weeklySalesCount = 0;
  double monthlySalesCount = 0;
  int _lowStockCount = 0;

  @override
  void initState() {
    print("This runs after build, similar to initState");
    getInvoiceCountToday();
    getTotalSalesToday();
    getTotalSalesWeekly();
    getTotalSalesMonthly();
    _loadStockData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   print("This runs after build, similar to initState");
    //   getInvoiceCountToday();
    // });
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DashboardCard(title: "Today Sales", value: "₹$todaySalesCount"),
                DashboardCard(
                  title: "Weekly Sales",
                  value: "₹$weeklySalesCount",
                ),
                DashboardCard(
                  title: "Invoices",
                  value: invoiceCount.toString(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DashboardCard(
                  title: "Monthly Sales",
                  value: "₹$monthlySalesCount",
                ),
                ValueListenableBuilder<int>(
                  valueListenable: StockAppState.lowStockCount,
                  builder: (context, value, _) {
                    return DashboardCard(
                      title: "Low Stocks",
                      value: "$value Items",
                    );
                  },
                ),

                // DashboardCard(
                //   title: "Low Stocks",
                //   value: "$_lowStockCount Items",
                // ),
              ],
            ),
            // const SizedBox(height: 40),
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (_) => const ProductPage()),
            //     );
            //   },
            //   child: const Text("Add Product"),
            // ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BillingPage()),
                );
              },
              child: const Text("Show Products"),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> getInvoiceCountToday() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(Duration(days: 1));
    final invoices = await DBHelper.getInvoices(startDate: start, endDate: end);
    print('InvoicesLength=====${invoices.length}');
    setState(() {
      invoiceCount = invoices.length;
    });
    return invoices.length;
  }

  Future<void> getTotalSalesToday() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(Duration(days: 1));
    final todaySales = await DBHelper.getSalesTotal(
      startDate: start,
      endDate: end,
    );
    print("Today Sales = $todaySales");
    setState(() {
      todaySalesCount = todaySales;
    });
  }

  Future<void> getTotalSalesWeekly() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final endOfWeek = startOfWeek.add(Duration(days: 7));

    final weeklySales = await DBHelper.getSalesTotal(
      startDate: startOfWeek,
      endDate: endOfWeek,
    );
    print("Weekly Sales = $weeklySales");

    setState(() {
      weeklySalesCount = weeklySales;
    });
  }

  Future<void> getTotalSalesMonthly() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

    final monthlySales = await DBHelper.getSalesTotal(
      startDate: startOfMonth,
      endDate: startOfNextMonth,
    );
    print("Monthly Sales = $monthlySales");

    setState(() {
      monthlySalesCount = monthlySales;
    });
  }

  Future<void> _loadStockData() async {
    final lowStock = await DBHelper.getLowStockProducts();
    setState(() {
      _lowStockCount = lowStock.length;
    });
    StockAppState.lowStockCount.value = lowStock.length;
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;

  const DashboardCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (title == "Invoices") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => InvoiceListPage()),
          );
        } else if (title == "Low Stocks") {
          final lowStockItems = await DBHelper.getLowStockProducts();
          final result = Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LowStockPage(products: lowStockItems),
            ),
          );
          print("result====$result");
          // if (result == true) {
          //   // 👇 Refresh low stock count when coming back
          //   (context as Element).markNeedsBuild(); //force rebuild if needed
          //   await (context
          //       .findAncestorStateOfType<_DashboardPage>()
          //       ?._loadStockData());
          // }
        }
      },
      child: Card(
        elevation: 3,
        child: Container(
          width: 150,
          height: 100,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(fontSize: 18, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
