import 'package:aara_bill_software/models/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

class DBHelper {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;

    Directory dir = await getApplicationDocumentsDirectory();
    String path = join(dir.path, "billing_app.db");

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          // Create Users table
          await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            password TEXT NOT NULL
          )
        ''');

          // Create dummy user
          await db.insert("users", {"username": "admin", "password": "1234"});

          // Create/Add Product
          await db.execute('''
              CREATE TABLE products(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                category TEXT,
                itemNo TEXT,
                name TEXT,
                quantity INTEGER,
                price REAL,
                sgst REAL,
                cgst REAL,
                stock INTEGER
              )
            ''');

          // Create Invoice/Bill
          await db.execute('''
              CREATE TABLE invoices(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                billNo TEXT,
                date INTEGER,
                total REAL
              )
            ''');
          // Create/ADD Invoice's items
          await db.execute('''
              CREATE TABLE invoice_items(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                invoiceId INTEGER,
                productId INTEGER,
                quantity INTEGER,
                price REAL,
                FOREIGN KEY(invoiceId) REFERENCES invoices(id),
                FOREIGN KEY(productId) REFERENCES products(id)
              )
            ''');
        },
      ),
    );
  }

  static Future<Map<String, dynamic>?> getUser(
    String username,
    String password,
  ) async {
    final dbClient = await db;
    final res = await dbClient.query(
      "users",
      where: "username=? AND password=?",
      whereArgs: [username, password],
    );

    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  // Product CRUD
  static Future<int> insertProduct(Product product) async {
    final dbInsert = await db;
    return await dbInsert.insert('products', product.toMap());
  }

  static Future<List<Product>> getProducts() async {
    final dbGet = await db;
    final res = await dbGet.query('products');
    return res.map((e) => Product.fromMap(e)).toList();
  }

  static Future<int> updateProduct(Product product) async {
    final dbUpdate = await db;
    return await dbUpdate.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  static Future<int> deleteProduct(int id) async {
    final dbDel = await db;
    return await dbDel.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> resetTables() async {
    final dbClient = await db;
    await dbClient.execute("DROP TABLE IF EXISTS invoices");
    await dbClient.execute("DROP TABLE IF EXISTS invoice_items");
    await dbClient.execute("DROP TABLE IF EXISTS products");
    // re-run your table creation scripts here
  }

  // Get Invoices
  static Future<List<Map<String, dynamic>>> getInvoices({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final dbClient = await db;

    String where = "";
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      where = "date BETWEEN ? AND ?";
      args = [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch];
    }

    return await dbClient.query(
      "invoices",
      where: where.isNotEmpty ? where : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: "date DESC",
    );
  }

  // Get Invoice's items
  static Future<List<Map<String, dynamic>>> getInvoiceItems(
    int invoiceId,
  ) async {
    final dbClient = await db;
    return await dbClient.query(
      "invoice_items",
      where: "invoiceId = ?",
      whereArgs: [invoiceId],
    );
  }

  // Get Total Sales
  static Future<double> getSalesTotal({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final dbClient = await db;

    String where = "";
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      where = "date BETWEEN ? AND ?";
      args = [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch];
    }

    final result = await dbClient.rawQuery('''
    SELECT SUM(total) as totalSales
    FROM invoices
    ${where.isNotEmpty ? "WHERE $where" : ""}
    ''', args);

    final value = result.first["totalSales"];
    return value != null ? (value as num).toDouble() : 0.0;
  }

  // Get Low Stock Products (< 10)
  static Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    final dbClient = await db;
    final res = await dbClient.query(
      "products",
      where: "stock < ?",
      whereArgs: [threshold],
      orderBy: "stock ASC",
    );
    return res.map((e) => Product.fromMap(e)).toList();
  }
}
