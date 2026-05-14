import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database Helper - Singleton pattern
class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('invoice_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNull = 'TEXT';
    const realType = 'REAL NOT NULL';

    // Invoices table
    await db.execute('''
      CREATE TABLE invoices(
        id $idType,
        invoice_number $textType,
        customer_name $textType,
        customer_address $textTypeNull,
        customer_email $textTypeNull,
        customer_phone $textTypeNull,
        date $textType,
        due_date $textType,
        total $realType DEFAULT 0,
        tax $realType DEFAULT 0,
        discount $realType DEFAULT 0,
        notes $textTypeNull,
        status $textType DEFAULT 'unpaid',
        created_at TEXT DEFAULT (datetime('now','localtime'))
      )
    ''');

    // Items table
    await db.execute('''
      CREATE TABLE items(
        id $idType,
        invoice_id INTEGER NOT NULL,
        product_name $textType,
        description $textTypeNull,
        price $realType DEFAULT 0,
        qty INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE customers(
        id $idType,
        name $textType,
        phone $textTypeNull,
        email $textTypeNull,
        address $textTypeNull,
        created_at TEXT DEFAULT (datetime('now','localtime'))
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products(
        id $idType,
        name $textType,
        description $textTypeNull,
        price $realType DEFAULT 0,
        photo_path $textTypeNull,
        created_at TEXT DEFAULT (datetime('now','localtime'))
      )
    ''');

    // Business profile table
    await db.execute('''
      CREATE TABLE business_profile(
        id $idType,
        business_name $textTypeNull,
        business_address $textTypeNull,
        business_phone $textTypeNull,
        business_email $textTypeNull,
        logo_path $textTypeNull,
        bank_name $textTypeNull,
        bank_account $textTypeNull,
        bank_holder $textTypeNull,
        notes $textTypeNull
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_invoice_number ON invoices(invoice_number)');
    await db.execute('CREATE INDEX idx_customer_name ON invoices(customer_name)');
    await db.execute('CREATE INDEX idx_customer_phone ON invoices(customer_phone)');
    await db.execute('CREATE INDEX idx_invoice_status ON invoices(status)');
    await db.execute('CREATE INDEX idx_item_invoice_id ON items(invoice_id)');
    await db.execute('CREATE INDEX idx_customer_name_idx ON customers(name)');
    await db.execute('CREATE INDEX idx_customer_phone_idx ON customers(phone)');
    await db.execute('CREATE INDEX idx_product_name_idx ON products(name)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE invoices ADD COLUMN customer_email TEXT');
      await db.execute('ALTER TABLE invoices ADD COLUMN customer_phone TEXT');
      await db.execute('ALTER TABLE invoices ADD COLUMN notes TEXT');
      await db.execute('ALTER TABLE invoices ADD COLUMN created_at TEXT DEFAULT (datetime("now","localtime"))');
      await db.execute('ALTER TABLE items ADD COLUMN description TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE invoices ADD COLUMN customer_address TEXT');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          email TEXT,
          address TEXT,
          created_at TEXT DEFAULT (datetime('now','localtime'))
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS products(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          price REAL NOT NULL DEFAULT 0,
          photo_path TEXT,
          created_at TEXT DEFAULT (datetime('now','localtime'))
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS business_profile(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          business_name TEXT,
          business_address TEXT,
          business_phone TEXT,
          business_email TEXT,
          logo_path TEXT,
          bank_name TEXT,
          bank_account TEXT,
          bank_holder TEXT,
          notes TEXT
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_customer_phone ON invoices(customer_phone)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_customer_name_idx ON customers(name)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_customer_phone_idx ON customers(phone)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_product_name_idx ON products(name)');
    }
  }

  // ==========================================
  // INVOICE CRUD
  // ==========================================

  Future<int> insertInvoice(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('invoices', data);
  }

  Future<int> updateInvoice(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('invoices', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteInvoice(int id) async {
    final db = await instance.database;
    return await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await instance.database;
    return await db.query('invoices', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getInvoiceById(int id) async {
    final db = await instance.database;
    final results = await db.query('invoices', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return results.first;
  }

  /// Search by customer name, invoice number, or phone number
  Future<List<Map<String, dynamic>>> searchInvoices(String keyword) async {
    final db = await instance.database;
    return await db.query(
      'invoices',
      where: 'customer_name LIKE ? OR invoice_number LIKE ? OR customer_phone LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> filterInvoicesByStatus(String status) async {
    final db = await instance.database;
    return await db.query('invoices', where: 'status = ?', whereArgs: [status], orderBy: 'created_at DESC');
  }

  Future<int> updateInvoiceStatus(int id, String status) async {
    final db = await instance.database;
    return await db.update('invoices', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  /// Get invoices that are overdue (for auto-status update)
  Future<List<Map<String, dynamic>>> getOverdueCandidates() async {
    final db = await instance.database;
    return await db.query(
      'invoices',
      where: "status != 'paid' AND due_date < date('now')",
      orderBy: 'due_date ASC',
    );
  }

  /// Get invoices approaching due date for notifications
  Future<List<Map<String, dynamic>>> getInvoicesApproachingDue(int daysBefore) async {
    final db = await instance.database;
    return await db.query(
      'invoices',
      where: "status != 'paid' AND due_date = date('now', '+$daysBefore days')",
      orderBy: 'due_date ASC',
    );
  }

  Future<Map<String, dynamic>> getInvoiceStats() async {
    final db = await instance.database;
    final totalInvoices = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM invoices'));
    final paidInvoices = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM invoices WHERE status = 'paid'"));
    final unpaidInvoices = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM invoices WHERE status = 'unpaid'"));
    final overdueInvoices = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM invoices WHERE status = 'overdue'"));
    final totalRevenue = Sqflite.firstIntValue(await db.rawQuery("SELECT CAST(SUM(total) AS INTEGER) FROM invoices WHERE status = 'paid'"));

    return {
      'total': totalInvoices ?? 0,
      'paid': paidInvoices ?? 0,
      'unpaid': unpaidInvoices ?? 0,
      'overdue': overdueInvoices ?? 0,
      'revenue': totalRevenue ?? 0,
    };
  }

  // ==========================================
  // ITEM CRUD
  // ==========================================

  Future<int> insertItem(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('items', data);
  }

  Future<void> insertItems(List<Map<String, dynamic>> items) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var item in items) {
      batch.insert('items', item);
    }
    await batch.commit(noResult: true);
  }

  Future<int> updateItem(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('items', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getItems(int invoiceId) async {
    final db = await instance.database;
    return await db.query('items', where: 'invoice_id = ?', whereArgs: [invoiceId], orderBy: 'id ASC');
  }

  Future<int> deleteItemsByInvoiceId(int invoiceId) async {
    final db = await instance.database;
    return await db.delete('items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
  }

  // ==========================================
  // CUSTOMER CRUD
  // ==========================================

  Future<int> insertCustomer(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('customers', data);
  }

  Future<int> updateCustomer(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('customers', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await instance.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await instance.database;
    return await db.query('customers', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> searchCustomers(String keyword) async {
    final db = await instance.database;
    return await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'name ASC',
    );
  }

  // ==========================================
  // PRODUCT CRUD
  // ==========================================

  Future<int> insertProduct(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('products', data);
  }

  Future<int> updateProduct(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('products', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> searchProducts(String keyword) async {
    final db = await instance.database;
    return await db.query(
      'products',
      where: 'name LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'name ASC',
    );
  }

  // ==========================================
  // BUSINESS PROFILE
  // ==========================================

  Future<Map<String, dynamic>?> getBusinessProfile() async {
    final db = await instance.database;
    final results = await db.query('business_profile', limit: 1);
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<int> saveBusinessProfile(Map<String, dynamic> data) async {
    final db = await instance.database;
    final existing = await getBusinessProfile();
    if (existing != null) {
      return await db.update('business_profile', data, where: 'id = ?', whereArgs: [existing['id']]);
    } else {
      return await db.insert('business_profile', data);
    }
  }

  // ==========================================
  // UTILITY
  // ==========================================

  Future<bool> isInvoiceNumberExists(String invoiceNumber) async {
    final db = await instance.database;
    final results = await db.query('invoices', where: 'invoice_number = ?', whereArgs: [invoiceNumber]);
    return results.isNotEmpty;
  }

  Future<String> generateInvoiceNumber() async {
    final now = DateTime.now();
    final dateStr = '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}';
    final prefix = 'INV-$dateStr';
    final db = await instance.database;
    final results = await db.rawQuery(
      "SELECT invoice_number FROM invoices WHERE invoice_number LIKE '$prefix%' ORDER BY invoice_number DESC LIMIT 1",
    );
    int seq = 1;
    if (results.isNotEmpty) {
      final lastNumber = results.first['invoice_number'] as String;
      final parts = lastNumber.split('-');
      if (parts.length == 3) {
        seq = int.tryParse(parts[2]) ?? 0;
        seq++;
      }
    }
    return '$prefix-${_fourDigits(seq)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
  String _fourDigits(int n) => n.toString().padLeft(4, '0');
}
