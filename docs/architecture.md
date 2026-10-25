# System Architecture: Receipt OCR & Expense Tracker

## 1. High-Level Architectural Pattern
The application follows a clean, modular layered architecture designed for Flutter applications:

```text
┌────────────────────────────────────────────────────────┐
│                      UI Layer                          │
│   (Screens, CustomPainter Widgets, Dialogs, Modals)    │
└───────────────────────────▲────────────────────────────┘
                            │ listens / dispatches
┌───────────────────────────▼────────────────────────────┐
│                  Presentation State                    │
│      (ChangeNotifier Providers: Dashboard, Txn)        │
└─────────────▲────────────────────────────▲─────────────┘
              │ uses                       │ uses
┌─────────────▼──────────────┐ ┌───────────▼─────────────┐
│       Domain & OCR         │ │      Repository Layer   │
│ (MlkitOcrService, Parser)  │ │ (TransactionRepository) │
└────────────────────────────┘ └───────────▲─────────────┘
                                           │ persists
                               ┌───────────▼─────────────┐
                               │       Data Layer        │
                               │  (SQLite DAO, Storage)  │
                               └─────────────────────────┘
```

## 2. Layer Responsibilities

### A. Presentation Layer (`lib/features/`, `lib/shared/`)
- Pure UI widgets adhering to Material 3 principles.
- Responsive layout with Vietnamese localization.
- Custom canvas drawing via `CustomPainter` with `AnimationController` for charts.
- Subscribes to `ChangeNotifier` state providers; triggers asynchronous user actions.

### B. State Management Layer (`providers/`)
- Uses Flutter `Provider` (`ChangeNotifier`).
- **`TransactionProvider`**: Manages the list of transactions, active filters (date, category, type), text search, and CRUD lifecycle.
- **`DashboardProvider`**: Computes monthly balances, income, expense totals, and top categories.
- **`SettingsProvider`**: Handles theme mode (`ThemeMode.system`, `light`, `dark`).

### C. OCR & Parsing Engine (`lib/features/ocr/services/`)
- **`MlkitOcrService`**: Wraps `google_mlkit_text_recognition`, running on-device inference without cloud network calls.
- **`ReceiptParser`**: Pure Dart heuristic engine. Evaluates recognized text blocks using regex, label dictionaries, and contextual token analysis to output a `ParsedReceipt` candidate model.

### D. Repository & Data Layer (`lib/data/`)
- **`TransactionRepository`**: Decouples presentation logic from SQLite and file system details. Manages atomic commits: writing data to SQLite and copying receipt images to app-private storage.
- **`TransactionDao` & `AppDatabase`**: Handles SQLite connection, versioning, migrations, indexing, and parameterized SQL queries.
- **`FileStorageHelper`**: Manages image copying into `receipt_images/` and cleanup on transaction deletion.
