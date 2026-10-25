# Database Schema: Expense Tracker (SQLite)

## Database Details
- **Database File**: `expense_tracker.db`
- **Current Version**: `1`
- **Engine**: SQLite via `sqflite`
- **Monetary Unit**: Integer Vietnamese đồng (`INTEGER`), guaranteeing zero rounding error.
- **Date Format**: ISO-8601 string (`YYYY-MM-DD` and `HH:mm:ss`).

---

## 1. Table: `transactions`

```sql
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
);
```

### Column Constraints & Field Rules
- `id`: Non-empty UUID v4 string.
- `amount`: Positive integer representing Vietnamese đồng (e.g. `150000` for 150.000 ₫).
- `transaction_type`: Must be either `'expense'` or `'income'`.
- `category`: Must match one of the predefined categories:
  - `Food & Drinks` (Ăn uống)
  - `Study` (Học tập)
  - `Travel` (Di chuyển)
  - `Shopping` (Mua sắm)
  - `Entertainment` (Giải trí)
  - `Bills & Utilities` (Hóa đơn & Tiện ích)
  - `Healthcare` (Sức khỏe)
  - `Transfer` (Chuyển khoản)
  - `Other` (Khác)
- `payment_method`: `Cash` (Tiền mặt), `Bank Transfer` (Chuyển khoản), `E-Wallet` (Ví điện tử), `Card` (Thẻ), `Other`.
- `receipt_image_path`: Relative path under application document directory: `receipt_images/<uuid>.jpg`.

---

## 2. Indexes
```sql
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_category ON transactions(category);
CREATE INDEX idx_transactions_type ON transactions(transaction_type);
```

---

## 3. Key Aggregation Queries

### Monthly Income & Expense Summary
```sql
SELECT 
    transaction_type, 
    SUM(amount) AS total_amount, 
    COUNT(*) AS total_count
FROM transactions
WHERE transaction_date >= ? AND transaction_date <= ?
GROUP BY transaction_type;
```

### Expense by Category (For Donut Chart)
```sql
SELECT 
    category, 
    SUM(amount) AS total_amount
FROM transactions
WHERE transaction_type = 'expense'
  AND transaction_date >= ? AND transaction_date <= ?
GROUP BY category
ORDER BY total_amount DESC;
```

### Daily Spending for Past 7 Days (For Weekly Bar Chart)
```sql
SELECT 
    transaction_date, 
    SUM(amount) AS total_amount
FROM transactions
WHERE transaction_type = 'expense'
  AND transaction_date >= ? AND transaction_date <= ?
GROUP BY transaction_date
ORDER BY transaction_date ASC;
```
