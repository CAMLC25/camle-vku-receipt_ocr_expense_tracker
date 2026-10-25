# Implementation Plan: Receipt OCR & Expense Tracker
## University Mini-Project: Flutter + Dart + Google ML Kit + SQLite

### 1. Environment & Baseline Assessment
- **Workspace Directory**: `d:\Study\Cross-Platform Mobile Application Development\Mini-Project 3\vku-receipt_ocr_expense_tracker`
- **Flutter Version**: Flutter `3.47.2` (Channel `stable`)
- **Dart Version**: Dart `3.13.2`
- **Android SDK**: Android SDK `37.0.0` located at `D:\Android\SDK`
- **Java Runtime**: OpenJDK (build `25.0.2`) located at `D:\Android\Android Studio\jbr\bin\java`
- **Emulators / Devices**: `Medium_Phone` Android emulator available; Windows Desktop & Chrome/Edge connected.
- **Initial Workspace State**: Clean empty directory, ready for initialization.

---

### 2. Technology Stack & Package Dependencies
All dependencies are verified for compatibility with Flutter 3.47.2 and Dart 3.13.2:
- **Flutter Framework & Material 3**: UI components, Material Design 3 theme system.
- **`provider` (`^6.1.2`)**: Predictable, clean reactive state management adhering to academic modular design.
- **`google_mlkit_text_recognition` (`^0.14.0` / `^0.15.0`)**: Local on-device Latin script OCR.
- **`image_picker` (`^1.1.2`)**: Camera capture and device gallery receipt import.
- **`sqflite` (`^2.4.1`) & `path` (`^1.9.0`)**: Persistent SQLite storage with migration and indexing.
- **`path_provider` (`^2.1.5`)**: Access to internal application storage (`getApplicationDocumentsDirectory`).
- **`intl` (`^0.20.2`)**: Vietnamese currency (`#,### ₫`) and localized date formatting.
- **`uuid` (`^4.5.1`)**: Unique ID generation for transactions.
- **`flutter_lints` (`^5.0.0`)**: Static analysis rules for clean Dart code.
- **Zero Third-Party Charting**: Both charts will be constructed natively using Flutter's `CustomPainter` and `AnimationController`.

---

### 3. Target Folder Structure
```text
vku-receipt_ocr_expense_tracker/
├── android/                             # Android native configuration (minSdk 21, permissions)
├── assets/
│   ├── icons/                           # App icons and markers
│   └── samples/                         # Sample receipt test images
├── docs/                                # Project documentation
│   ├── implementation_plan.md
│   ├── architecture.md
│   ├── database_schema.md
│   ├── test_plan.md
│   └── technical_report.md
├── lib/
│   ├── main.dart                        # App entry point, database initialization
│   ├── app.dart                         # MaterialApp, theme configuration, routes
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart          # M3 color palettes (light & dark)
│   │   │   ├── app_constants.dart       # Categories, payment methods, transaction types
│   │   │   └── regex_patterns.dart      # OCR regex rules for amounts, dates, keywords
│   │   ├── theme/
│   │   │   └── app_theme.dart           # Light/Dark Material 3 ThemeData
│   │   ├── utils/
│   │   │   ├── currency_formatter.dart  # Integer VND formatting (e.g. 150.000 ₫)
│   │   │   ├── date_formatter.dart      # Vietnamese & ISO 8601 formatting
│   │   │   └── file_storage_helper.dart # App-private receipt image storage & deletion
│   │   └── errors/
│   │       └── failure.dart             # Typed domain failures & error handling
│   ├── data/
│   │   ├── database/
│   │   │   ├── app_database.dart        # DatabaseOpenHelper, migrations, indexes
│   │   │   └── transaction_dao.dart     # SQLite CRUD, aggregations, parameterized queries
│   │   ├── models/
│   │   │   ├── transaction_model.dart   # Immutable transaction entity & JSON serialization
│   │   │   ├── parsed_receipt.dart      # Parser candidate results, warnings, confidence
│   │   │   └── spending_summary.dart    # Aggregated metrics for dashboard & charts
│   │   └── repositories/
│   │       └── transaction_repository.dart # Abstract contract & SQLite implementation
│   ├── features/
│   │   ├── dashboard/
│   │   │   ├── providers/
│   │   │   │   └── dashboard_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── dashboard_screen.dart # Monthly summary, balance, quick actions, recent items
│   │   │   └── widgets/
│   │   │       ├── summary_card.dart
│   │   │       └── recent_transaction_tile.dart
│   │   ├── scanner/
│   │   │   ├── screens/
│   │   │   │   └── image_input_screen.dart # Camera/Gallery selector, preview, retake
│   │   │   └── widgets/
│   │   │       └── image_preview_box.dart
│   │   ├── ocr/
│   │   │   ├── services/
│   │   │   │   ├── mlkit_ocr_service.dart  # Google ML Kit on-device text recognition
│   │   │   │   └── receipt_parser.dart     # Heuristic extraction engine (amount, date, merchant, category)
│   │   │   └── widgets/
│   │   │       └── raw_ocr_sheet.dart      # Raw text inspector sheet
│   │   ├── transactions/
│   │   │   ├── providers/
│   │   │   │   └── transaction_provider.dart # CRUD state, filters, search, sorting
│   │   │   ├── screens/
│   │   │   │   ├── review_screen.dart        # Editable manual verification form
│   │   │   │   ├── transaction_history_screen.dart # List, filter by date/category, search
│   │   │   │   ├── transaction_detail_screen.dart  # Full details, receipt viewer, edit/delete
│   │   │   │   └── manual_entry_screen.dart        # Direct manual transaction addition
│   │   │   └── widgets/
│   │   │       ├── transaction_filter_bar.dart
│   │   │       └── transaction_list_item.dart
│   │   ├── statistics/
│   │   │   ├── screens/
│   │   │   │   └── statistics_screen.dart # Donut chart & Weekly bar chart view
│   │   │   └── widgets/
│   │   │       ├── donut_chart_painter.dart     # CustomPainter for animated category breakdown
│   │   │       └── weekly_bar_chart_painter.dart # CustomPainter for 7-day spending trends
│   │   └── settings/
│   │       └── screens/
│   │           └── settings_screen.dart # Theme toggle (light/dark/system), clear data, info
│   └── shared/
│       └── widgets/
│           ├── app_button.dart
│           ├── empty_state_view.dart
│           ├── confirmation_dialog.dart
│           └── loading_overlay.dart
├── test/
│   ├── ocr/
│   │   └── receipt_parser_test.dart     # 15+ test cases covering amounts, dates, banks, categories
│   ├── database/
│   │   └── transaction_dao_test.dart    # SQLite CRUD & aggregation logic tests
│   └── widgets/
│       └── review_screen_test.dart      # Validation & editable field widget tests
└── README.md
```

---

### 4. Database Schema Design (SQLite via `sqflite`)
- **Database Name**: `expense_tracker.db`
- **Schema Version**: `1`
- **Monetary Unit**: Integer Vietnamese đồng (`INTEGER` in VND) to eliminate floating-point arithmetic errors.
- **Date Format**: Unambiguous ISO-8601 strings (`YYYY-MM-DD` and `HH:mm:ss`).

#### Table: `transactions`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `TEXT` | `PRIMARY KEY` | UUID v4 unique identifier |
| `merchant` | `TEXT` | `NOT NULL` | Business name / recipient / payee |
| `description` | `TEXT` | `NULL` | Transaction details / transfer note |
| `amount` | `INTEGER` | `NOT NULL` | Value in Vietnamese đồng (VND) |
| `currency` | `TEXT` | `NOT NULL DEFAULT 'VND'` | Currency string |
| `transaction_date`| `TEXT` | `NOT NULL` | ISO 8601 date: `YYYY-MM-DD` |
| `transaction_time`| `TEXT` | `NULL` | Time: `HH:mm:ss` |
| `transaction_type`| `TEXT` | `NOT NULL` | `'expense'` or `'income'` |
| `category` | `TEXT` | `NOT NULL` | Spending category (e.g. `Food & Drinks`) |
| `payment_method` | `TEXT` | `NULL` | `Cash`, `Bank Transfer`, `E-Wallet`, `Card`, etc. |
| `reference_number`| `TEXT`| `NULL` | Masked transfer ref or invoice code |
| `notes` | `TEXT` | `NULL` | Optional user annotations |
| `receipt_image_path` | `TEXT` | `NULL` | Relative path inside app storage |
| `raw_ocr_text` | `TEXT` | `NULL` | Full raw text output from ML Kit |
| `created_at` | `TEXT` | `NOT NULL` | ISO 8601 timestamp |
| `updated_at` | `TEXT` | `NOT NULL` | ISO 8601 timestamp |

#### Indexes:
```sql
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_category ON transactions(category);
CREATE INDEX idx_transactions_type ON transactions(transaction_type);
```

#### Storage Strategy for Receipt Images:
- Images captured or picked are **not** stored as binary blobs in SQLite.
- Images are copied to an internal, app-private folder: `<AppDocuments>/receipt_images/<uuid>.jpg`.
- The database stores only the relative file path.
- When deleting a transaction, the corresponding file is safely removed from disk.

---

### 5. Data Flow & Component Architecture
1. **Input Phase**:
   User selects Camera or Gallery (`ImageInputScreen`). The image is displayed with options to retake or confirm.
2. **Recognition Phase**:
   `MlkitOcrService` executes `TextRecognizer(script: TextRecognitionScript.latin)` on-device. Raw text blocks and lines are extracted preserving vertical ordering.
3. **Parsing Phase**:
   `ReceiptParser` analyzes text:
   - **Amount**: Normalizes Vietnamese numbers (`150.000 đ`, `150,000 VND`, `150000`, `TOTAL: 89.500`). Contextual matching favors labels such as `Tổng cộng`, `Thành tiền`, `Số tiền`, `Amount`, `Total`.
   - **Date/Time**: Matches `dd/MM/yyyy`, `dd-MM-yyyy`, `yyyy-MM-dd` and accompanying timestamps.
   - **Merchant/Payee**: Detects header lines, recipient keywords (`Người nhận`, `Đơn vị bán`, `Merchant`).
   - **Screenshot/Bank Detection**: Identifies keywords (`Giao dịch thành công`, `Chuyển khoản thành công`, `Transaction Successful`).
   - **Category Suggestion**: Keyword classification matching keywords to categories (`Food & Drinks`, `Study`, `Travel`, `Shopping`, `Entertainment`, `Bills & Utilities`, `Healthcare`, `Transfer`, `Other`).
   - Generates confidence score and warnings for ambiguous amounts or missing dates.
4. **Verification & Manual Edit Phase**:
   `ReviewScreen` presents an editable Material 3 form pre-filled with candidate values.
   - Displays receipt thumbnail.
   - Requires valid positive amount, valid date, and merchant/description.
   - User can override transaction type (`expense` vs `income`), category, and payment method.
   - Shows raw OCR text in an expandable bottom sheet for manual inspection.
5. **Persistence Phase**:
   - Receipt image is saved to app-private directory.
   - Transaction model is committed to SQLite via `TransactionRepository`.
6. **State & Reactive Refresh**:
   `DashboardProvider` and `TransactionProvider` reload data; dashboard metrics, history list, and custom charts update smoothly.

---

### 6. Custom Canvas Visualization Requirements
- **Donut/Pie Chart (`donut_chart_painter.dart`)**:
  - Excludes income by default; calculates category percentage slices from real SQLite expense records.
  - Slices drawn via `drawArc` with distinct palette colors.
  - Center cutout drawn with `drawCircle` displaying total spending formatted in VND.
  - Driven by `AnimationController` (sweep angle progression from 0 to 2π).
  - Handles empty state (displays placeholder ring with "Chưa có chi tiêu").
- **Weekly Spending Bar Chart (`weekly_bar_chart_painter.dart`)**:
  - Calculates daily spending for the past 7 days from SQLite.
  - Draws proportional vertical rounded bars via `drawRRect`.
  - Displays day-of-week labels (`T2`, `T3`, `T4`, `T5`, `T6`, `T7`, `CN`) and baseline axis.
  - Animates bar height growth smoothly via `AnimationController`.
  - Handles days with zero spending.

---

### 7. Risk Analysis & Mitigation Strategies
1. **On-Device OCR Latin Limitations**:
   - *Risk*: Standard Latin script recognition may omit Vietnamese diacritics (e.g. `Tổng cộng` read as `Tong cong`) or misread bank transaction numbers.
   - *Mitigation*: Unaccented regex patterns (`[Tt][oôòõó][nñ]g\s*[cç][oôòõó][nñ]g`), multiple fallback keyword variations, and mandatory user verification on the Review Screen.
2. **Amount Ambiguity**:
   - *Risk*: Receipts contain VAT, subtotals, cash given, change returned, and invoice phone numbers.
   - *Mitigation*: Prefer amounts explicitly tied to total keywords; compute subtotal/discount relations; generate warnings and highlight the amount field when confidence is moderate/low.
3. **Android Permissions**:
   - *Risk*: Camera and gallery access rejection on modern Android versions (Android 13+ `READ_MEDIA_IMAGES` vs older `READ_EXTERNAL_STORAGE`).
   - *Mitigation*: Use `image_picker` standard contract which handles modern photo pickers cleanly without broad storage permissions; handle camera permission denial with descriptive explanations.
4. **App-Private Storage Leaks**:
   - *Risk*: Deleting a transaction might leave orphaned receipt images on the file system.
   - *Mitigation*: Repository delete method always verifies and cleans up the associated image file from disk.

---

### 8. Testing Strategy
- **Unit Tests (`test/ocr/receipt_parser_test.dart`)**:
  1. Vietnamese restaurant receipt with `Tổng cộng` and `đ`.
  2. Supermarket receipt with subtotal, discount, and final total.
  3. Receipt with multiple monetary figures (VAT, cash given, change).
  4. Successful bank transfer screenshot (`Chuyển khoản thành công`).
  5. Bank transfer with sender, recipient, and transfer note.
  6. Transaction screenshot with no clearly labeled amount (fallback & warning).
  7. Vietnamese date format (`dd/MM/yyyy`).
  8. English date format (`yyyy-MM-dd`).
  9. Invalid date handling (leaves field empty for user input).
  10. Missing merchant name fallback.
  11. OCR text with strange spacing or broken line wraps.
  12. Vietnamese thousands separators (`150.000`).
  13. English thousands/decimal separators (`150,000` / `125.00`).
  14. Expense vs. income classification.
  15. Category classification by keyword sets.
- **Database Tests (`test/database/transaction_dao_test.dart`)**:
  - In-memory SQLite CRUD tests, aggregation queries for monthly totals, category totals, and weekly spending.
- **Widget Tests (`test/widgets/review_screen_test.dart`)**:
  - Form validation: positive amount check, empty date check, manual edits.

---

### 9. Phased Execution Acceptance Criteria
- **Phase 0 (Current)**: Implementation plan, architecture design, and database schema documented. Stop for approval.
- **Phase 1**: Flutter app initialized, dependencies installed, M3 theme (Light/Dark), App layout, bottom navigation (Dashboard, History, Statistics, Settings), base providers.
- **Phase 2**: Camera capture and gallery picker working, on-device Google ML Kit OCR service integrated, image preview, raw text viewer, loading indicators.
- **Phase 3**: Heuristic parsing engine implemented, candidate extraction, bank screenshot recognition, Review Screen with manual editing and validation, comprehensive parser unit tests passing.
- **Phase 4**: SQLite database initialized, migrations, Transaction DAO & Repository, receipt image disk persistence, full CRUD operations connected to UI.
- **Phase 5**: CustomPainter Donut Chart & Weekly Bar Chart implemented with animations, dark mode polish, empty states, and responsive layout.
- **Phase 6**: `flutter analyze` & `flutter test` passing, technical documentation (`README.md`, `architecture.md`, `database_schema.md`, `test_plan.md`, `technical_report.md`), release APK build verification.
