import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database Helper - Singleton pattern
/// Mengelola semua operasi CRUD untuk invoices dan items
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
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Membuat tabel database saat pertama kali
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNull = 'TEXT';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE invoices(
        id $idType,
        invoice_number $textType,
        customer_name $textType,
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

    // Index untuk pencarian
    await db.execute(
      'CREATE INDEX idx_invoice_number ON invoices(invoice_number)',
    );
    await db.execute(
      'CREATE INDEX idx_customer_name ON invoices(customer_name)',
    );
    await db.execute(
      'CREATE INDEX idx_invoice_status ON invoices(status)',
    );
    await db.execute(
      'CREATE INDEX idx_item_invoice_id ON items(invoice_id)',
    );
  }

  /// Migrasi database saat upgrade version
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration v1 -> v2: tambah kolom baru
      await db.execute(
        'ALTER TABLE invoices ADD COLUMN customer_email TEXT',
      );
      await db.execute(
        'ALTER TABLE invoices ADD COLUMN customer_phone TEXT',
      );
      await db.execute(
        'ALTER TABLE invoices ADD COLUMN notes TEXT',
      );
      await db.execute(
        'ALTER TABLE invoices ADD COLUMN created_at TEXT DEFAULT (datetime("now","localtime"))',
      );
      await db.execute(
        'ALTER TABLE items ADD COLUMN description TEXT',
      );
    }
  }

  // ==========================================
  // INVOICE CRUD OPERATIONS
  // ==========================================

  /// Insert invoice baru
  Future<int> insertInvoice(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('invoices', data);
  }

  /// Update invoice berdasarkan id
  Future<int> updateInvoice(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update(
      'invoices',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hapus invoice berdasarkan id (cascade ke items)
  Future<int> deleteInvoice(int id) async {
    final db = await instance.database;
    return await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Ambil semua invoice, diurutkan berdasarkan tanggal terbaru
  Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await instance.database;
    return await db.query(
      'invoices',
      orderBy: 'created_at DESC',
    );
  }

  /// Ambil invoice berdasarkan id
  Future<Map<String, dynamic>?> getInvoiceById(int id) async {
    final db = await instance.database;
    final results = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  /// Cari invoice berdasarkan keyword (nama customer / nomor invoice)
  Future<List<Map<String, dynamic>>> searchInvoices(String keyword) async {
    final db = await instance.database;
    return await db.query(
      'invoices',
      where: 'customer_name LIKE ? OR invoice_number LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'created_at DESC',
    );
  }

  /// Filter invoice berdasarkan status
  Future<List<Map<String, dynamic>>> filterInvoicesByStatus(
    String status,
  ) async {
    final db = await instance.database;
    return await db.query(
      'invoices',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
  }

  /// Update status invoice
  Future<int> updateInvoiceStatus(int id, String status) async {
    final db = await instance.database;
    return await db.update(
      'invoices',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Ambil statistik invoice
  Future<Map<String, dynamic>> getInvoiceStats() async {
    final db = await instance.database;

    final totalInvoices = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM invoices'),
    );

    final paidInvoices = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM invoices WHERE status = 'paid'",
      ),
    );

    final unpaidInvoices = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM invoices WHERE status = 'unpaid'",
      ),
    );

    final overdueInvoices = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM invoices WHERE status = 'overdue'",
      ),
    );

    final totalRevenue = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT CAST(SUM(total) AS INTEGER) FROM invoices WHERE status = 'paid'",
      ),
    );

    return {
      'total': totalInvoices ?? 0,
      'paid': paidInvoices ?? 0,
      'unpaid': unpaidInvoices ?? 0,
      'overdue': overdueInvoices ?? 0,
      'revenue': totalRevenue ?? 0,
    };
  }

  // ==========================================
  // ITEM CRUD OPERATIONS
  // ==========================================

  /// Insert item baru
  Future<int> insertItem(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('items', data);
  }

  /// Insert banyak items sekaligus (batch)
  Future<void> insertItems(List<Map<String, dynamic>> items) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var item in items) {
      batch.insert('items', item);
    }
    await batch.commit(noResult: true);
  }

  /// Update item berdasarkan id
  Future<int> updateItem(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update(
      'items',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hapus item berdasarkan id
  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Ambil semua items berdasarkan invoice_id
  Future<List<Map<String, dynamic>>> getItems(int invoiceId) async {
    final db = await instance.database;
    return await db.query(
      'items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'id ASC',
    );
  }

  /// Hapus semua items berdasarkan invoice_id
  Future<int> deleteItemsByInvoiceId(int invoiceId) async {
    final db = await instance.database;
    return await db.delete(
      'items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
  }

  // ==========================================
  // UTILITY
  // ==========================================

  /// Cek apakah invoice_number sudah ada
  Future<bool> isInvoiceNumberExists(String invoiceNumber) async {
    final db = await instance.database;
    final results = await db.query(
      'invoices',
      where: 'invoice_number = ?',
      whereArgs: [invoiceNumber],
    );
    return results.isNotEmpty;
  }

  /// Generate nomor invoice unik
  /// Format: INV-YYYYMMDD-XXXX
  Future<String> generateInvoiceNumber() async {
    final now = DateTime.now();
    final dateStr = '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}';
    final prefix = 'INV-$dateStr';

    // Cari invoice terakhir dengan prefix yang sama hari ini
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
