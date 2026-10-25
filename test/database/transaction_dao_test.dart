import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vku_receipt_ocr_expense_tracker/data/database/app_database.dart';
import 'package:vku_receipt_ocr_expense_tracker/data/database/transaction_dao.dart';
import 'package:vku_receipt_ocr_expense_tracker/data/models/transaction_model.dart';
import 'package:vku_receipt_ocr_expense_tracker/data/repositories/sqlite_transaction_repository.dart';

void main() {
  // Initialize sqflite ffi for headless desktop testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late TransactionDao dao;
  late SqliteTransactionRepository repository;

  final sample1 = TransactionModel(
    id: 'tx-1',
    merchant: 'Phúc Long Coffee',
    description: 'Trà đào cam sả',
    amount: 55000,
    currency: 'VND',
    transactionDate: '2026-10-10',
    transactionTime: '09:00:00',
    transactionType: 'expense',
    category: 'Food & Drinks',
    paymentMethod: 'Cash',
    referenceNumber: 'REF001',
    notes: 'Uống cùng bạn bè',
    createdAt: '2026-10-10T09:00:00.000',
    updatedAt: '2026-10-10T09:00:00.000',
  );

  final sample2 = TransactionModel(
    id: 'tx-2',
    merchant: 'Nhà sách VKU',
    description: 'Vở ghi chép và bút',
    amount: 45000,
    currency: 'VND',
    transactionDate: '2026-10-11',
    transactionTime: '14:30:00',
    transactionType: 'expense',
    category: 'Study',
    paymentMethod: 'Bank Transfer',
    referenceNumber: 'REF002',
    notes: 'Dụng cụ học tập',
    createdAt: '2026-10-11T14:30:00.000',
    updatedAt: '2026-10-11T14:30:00.000',
  );

  final sampleIncome = TransactionModel(
    id: 'tx-3',
    merchant: 'Học bổng khuyến khích VKU',
    description: 'Học bổng kỳ 1',
    amount: 1500000,
    currency: 'VND',
    transactionDate: '2026-10-12',
    transactionTime: '10:00:00',
    transactionType: 'income',
    category: 'Study',
    paymentMethod: 'Bank Transfer',
    referenceNumber: 'REF003',
    notes: 'Tiền thưởng học kỳ',
    createdAt: '2026-10-12T10:00:00.000',
    updatedAt: '2026-10-12T10:00:00.000',
  );

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppDatabase.databaseVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE transactions (
              id TEXT PRIMARY KEY,
              merchant TEXT NOT NULL,
              description TEXT,
              amount INTEGER NOT NULL,
              currency TEXT NOT NULL DEFAULT 'VND',
              transaction_date TEXT NOT NULL,
              transaction_time TEXT,
              transaction_type TEXT NOT NULL,
              category TEXT NOT NULL,
              payment_method TEXT,
              reference_number TEXT,
              notes TEXT,
              receipt_image_path TEXT,
              raw_ocr_text TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_transactions_date ON transactions(transaction_date)',
          );
          await db.execute(
            'CREATE INDEX idx_transactions_category ON transactions(category)',
          );
          await db.execute(
            'CREATE INDEX idx_transactions_type ON transactions(transaction_type)',
          );
        },
      ),
    );
    dao = TransactionDao(db);
    repository = SqliteTransactionRepository(dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionDao CRUD Operations', () {
    test('Inserts and retrieves transaction by id', () async {
      await dao.insertTransaction(sample1);
      final retrieved = await dao.getTransactionById(sample1.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, sample1.id);
      expect(retrieved.merchant, 'Phúc Long Coffee');
      expect(retrieved.amount, 55000);
      expect(retrieved.category, 'Food & Drinks');
      expect(retrieved.transactionType, 'expense');
    });

    test('Updates existing transaction record', () async {
      await dao.insertTransaction(sample1);
      final updated = sample1.copyWith(
        merchant: 'Phúc Long Tea & Coffee',
        amount: 60000,
        notes: 'Cập nhật ghi chú mới',
      );

      final rowsAffected = await dao.updateTransaction(updated);
      expect(rowsAffected, 1);

      final retrieved = await dao.getTransactionById(sample1.id);
      expect(retrieved!.merchant, 'Phúc Long Tea & Coffee');
      expect(retrieved.amount, 60000);
      expect(retrieved.notes, 'Cập nhật ghi chú mới');
    });

    test('Deletes transaction by id', () async {
      await dao.insertTransaction(sample1);
      expect(await dao.getTransactionById(sample1.id), isNotNull);

      final rowsDeleted = await dao.deleteTransaction(sample1.id);
      expect(rowsDeleted, 1);
      expect(await dao.getTransactionById(sample1.id), isNull);
    });

    test('Returns all transactions ordered newest first', () async {
      await dao.insertTransaction(sample1);
      await dao.insertTransaction(sample2);
      await dao.insertTransaction(sampleIncome);

      final all = await dao.getAllTransactions();
      expect(all.length, 3);
      // Newest date is 2026-10-12, followed by 2026-10-11, then 2026-10-10
      expect(all[0].id, sampleIncome.id);
      expect(all[1].id, sample2.id);
      expect(all[2].id, sample1.id);
    });
  });

  group('Parameterized Filtering and Search', () {
    setUp(() async {
      await dao.insertTransaction(sample1);
      await dao.insertTransaction(sample2);
      await dao.insertTransaction(sampleIncome);
    });

    test('Filters by transaction type (expense vs income)', () async {
      final expenses = await dao.getFilteredTransactions(type: 'expense');
      expect(expenses.length, 2);
      expect(expenses.every((t) => t.isExpense), isTrue);

      final incomes = await dao.getFilteredTransactions(type: 'income');
      expect(incomes.length, 1);
      expect(incomes.first.id, sampleIncome.id);
    });

    test('Filters by spending category', () async {
      final foodItems = await dao.getFilteredTransactions(
        category: 'Food & Drinks',
      );
      expect(foodItems.length, 1);
      expect(foodItems.first.merchant, 'Phúc Long Coffee');

      final studyItems = await dao.getFilteredTransactions(category: 'Study');
      expect(studyItems.length, 2);
    });

    test('Filters by date interval', () async {
      final range = await dao.getFilteredTransactions(
        startDate: '2026-10-10',
        endDate: '2026-10-11',
      );
      expect(range.length, 2);
      expect(range.any((t) => t.id == sample1.id), isTrue);
      expect(range.any((t) => t.id == sample2.id), isTrue);
      expect(range.any((t) => t.id == sampleIncome.id), isFalse);
    });

    test('Searches by keyword in merchant or description', () async {
      final result1 = await dao.getFilteredTransactions(searchQuery: 'Trà đào');
      expect(result1.length, 1);
      expect(result1.first.id, sample1.id);

      final result2 = await dao.getFilteredTransactions(searchQuery: 'Fahasa');
      expect(result2.isEmpty, isTrue);

      final result3 = await dao.getFilteredTransactions(searchQuery: 'VKU');
      expect(result3.length, 2);
    });
  });

  group('Financial Aggregations', () {
    setUp(() async {
      await dao.insertTransaction(sample1); // 55.000 expense (Food & Drinks)
      await dao.insertTransaction(sample2); // 45.000 expense (Study)
      await dao.insertTransaction(sampleIncome); // 1.500.000 income (Study)
    });

    test('Calculates monthly summary accurately', () async {
      final summary = await dao.getMonthlySummary(year: 2026, month: 10);

      expect(summary.totalExpense, 100000); // 55.000 + 45.000
      expect(summary.totalIncome, 1500000);
      expect(summary.netBalance, 1400000);
      expect(summary.transactionCount, 3);

      expect(summary.expenseByCategory['Food & Drinks'], 55000);
      expect(summary.expenseByCategory['Study'], 45000);
    });

    test('Returns 0 for month without transactions', () async {
      final summary = await dao.getMonthlySummary(year: 2026, month: 1);

      expect(summary.totalExpense, 0);
      expect(summary.totalIncome, 0);
      expect(summary.netBalance, 0);
      expect(summary.transactionCount, 0);
      expect(summary.expenseByCategory.isEmpty, isTrue);
    });

    test('Generates 7-day weekly daily expense series', () async {
      final weekly = await dao.getWeeklyDailyExpenses(
        endDate: DateTime(2026, 10, 12),
      );

      expect(weekly.length, 7);
      expect(weekly['2026-10-10'], 55000);
      expect(weekly['2026-10-11'], 45000);
      expect(weekly['2026-10-12'], 0); // sampleIncome is income, not expense
      expect(weekly['2026-10-09'], 0); // No expense
    });
  });

  group('SqliteTransactionRepository Integration', () {
    test('Full add, fetch, update, delete cycle through repository', () async {
      await repository.addTransaction(sample1);
      final all = await repository.getAllTransactions();
      expect(all.length, 1);

      final summary = await repository.getMonthlySummary(year: 2026, month: 10);
      expect(summary.totalExpense, 55000);

      await repository.deleteTransaction(sample1.id);
      final empty = await repository.getAllTransactions();
      expect(empty.isEmpty, isTrue);
    });
  });
}
