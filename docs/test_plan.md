# Test Plan: Receipt OCR & Expense Tracker

## 1. Overview
This test plan defines the testing strategy for the **Receipt OCR & Expense Tracker** application, verifying unit correctness, heuristic parsing accuracy across edge cases, database integrity, and UI validation behavior.

---

## 2. Test Suites

### Suite A: Heuristic Parser Unit Tests (`test/ocr/receipt_parser_test.dart`)
1. **Vietnamese Restaurant Receipt**: Text with `Tổng cộng: 150.000 đ`, merchant header, date `12/10/2026`.
2. **Supermarket Multi-item Receipt**: Subtotal, 10% discount, tax, final total `THÀNH TIỀN: 89.500`. Verifies parser picks final total over subtotal.
3. **Multi-monetary Figure Receipt**: Contains cash given (`Tiền khách đưa: 200.000`), change returned (`Tiền thối: 50.000`), total `150.000`. Verifies parser does not confuse cash given/change with total.
4. **Successful Bank Transfer Screenshot**: Contains `Chuyển khoản thành công`, recipient name, amount `500.000 VND`, ref ID.
5. **Bank Transfer with Sender & Recipient**: Confirms recipient extraction and transfer category suggestion.
6. **Screenshot with Ambiguous/Unlabeled Amount**: Returns amount candidate with low confidence and warning.
7. **Vietnamese Date Format**: Matches `15/08/2026` and `15-08-2026`.
8. **ISO / English Date Format**: Matches `2026-08-15`.
9. **Invalid Date Value**: E.g., `32/13/2026` rejected, leaving date empty for manual entry.
10. **Missing Merchant Name**: Fallback to default or empty merchant with warning.
11. **Messy Spacing / Broken Lines**: OCR with extra spaces `1 5 0 . 0 0 0 d` or line breaks properly normalized.
12. **Vietnamese Thousands Separators**: Normalizes `1.250.000` to integer `1250000`.
13. **English Decimal / Comma Separators**: Normalizes `125.00` and `1,250.00` correctly without dropping magnitude.
14. **Expense vs. Income Classification**: Distinguishes incoming transfer / salary indicators from regular expenses.
15. **Category Classification Rules**: Verifies keyword mapping for all 9 categories (`Food & Drinks`, `Study`, `Travel`, `Shopping`, `Entertainment`, `Bills & Utilities`, `Healthcare`, `Transfer`, `Other`).

---

### Suite B: Database DAO & Repository Tests (`test/database/transaction_dao_test.dart`)
- **CRUD Operations**: Insert, query by ID, update fields, delete transaction.
- **Monthly Summary Aggregation**: Validates income, expense, and net balance calculations.
- **Category Grouping**: Verifies spending breakdown sums match expected category totals.
- **Weekly Trend Calculation**: Verifies 7-day chronological bucket aggregation.

---

### Suite C: UI & Widget Tests (`test/widgets/review_screen_test.dart`)
- **Form Validation**: Blocks submission when amount is zero or negative.
- **Required Fields**: Prompts user when date or merchant is missing.
- **Editable Values**: Validates that updating text controllers modifies saved values.

---

## 3. Execution Commands
```bash
flutter analyze
flutter test
```
