import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/database/app_database.dart';
import 'data/database/transaction_dao.dart';
import 'data/repositories/sqlite_transaction_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/transactions/providers/transaction_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite Database and Repository
  final db = await AppDatabase.instance.database;
  final dao = TransactionDao(db);
  final TransactionRepository repository = SqliteTransactionRepository(dao);

  // Clean up any remaining demo sample records so database is clean for real receipts
  final existing = await repository.getAllTransactions();
  for (final item in existing) {
    if (item.id.startsWith('demo-')) {
      await repository.deleteTransaction(item.id);
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(repository: repository),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(repository: repository),
        ),
      ],
      child: const ExpenseTrackerApp(),
    ),
  );
}
