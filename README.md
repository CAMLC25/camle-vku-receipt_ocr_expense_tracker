# Receipt OCR & Expense Tracker (VKU)
> **Sổ Thu Chi & Quét Hóa Đơn Thông Minh Dành Cho Sinh Viên**  
> Xây dựng bằng **Flutter + Dart + Google ML Kit + SQLite (`sqflite`)**  
> *Hoạt động 100% Offline • Trí tuệ nhân tạo trên thiết bị (On-Device AI) • Biểu đồ bản địa CustomPainter*

---

## 📱 Giới thiệu tổng quan

**Receipt OCR & Expense Tracker** là ứng dụng di động hoàn chỉnh giúp sinh viên đại học và thủ quỹ câu lạc bộ số hóa, quản lý và theo dõi các khoản chi tiêu hằng ngày thông qua ảnh chụp biên lai, hóa đơn bán lẻ hoặc ảnh chụp màn hình chuyển khoản ngân hàng (VietQR / Napas247 / MoMo).

Ứng dụng hoạt động **hoàn toàn ngoại tuyến (Offline-First)**:
- **Không gửi ảnh lên Cloud**: Sử dụng mô hình Google ML Kit Text Recognition chạy trực tiếp trên thiết bị (On-Device), bảo vệ tuyệt đối quyền riêng tư tài chính cá nhân.
- **Không phát sinh chi phí API**: Không dùng Cloud Vision hay OpenAI API có phí.
- **Không dùng thư viện biểu đồ bên thứ ba**: Tự vẽ biểu đồ Donut phân bổ danh mục và biểu đồ cột xu hướng 7 ngày bằng `CustomPainter` và `AnimationController`.

---

## ✨ Tính năng chính

| Phân hệ | Chi tiết tính năng |
|---|---|
| 📸 **Thu thập ảnh thông minh** | Chụp trực tiếp từ Camera thiết bị hoặc chọn ảnh hóa đơn/ảnh chuyển khoản có sẵn trong Thư viện ảnh. |
| 🔍 **On-Device OCR** | Nhận diện ký tự quang học tốc độ cao, hiển thị toàn bộ văn bản gốc kèm tính năng sao chép clipboard qua `RawOcrSheet`. |
| 🏷️ **Phân loại ảnh tự động** | Tự động phân loại tài liệu theo 5 nhóm: Hóa đơn bán lẻ (`receipt`), Ảnh chuyển khoản ngân hàng (`bankTransfer`), Ví điện tử (`eWallet`), Hóa đơn dịch vụ (`utilityBill`), hoặc Chưa xác định (`unknown`). |
| 🧠 **Heuristic Parsing Engine** | Tự động bóc tách số tiền VNĐ (chuẩn hóa `.`, `,`, khoảng cách), ngày giao dịch, người nhận chuyển khoản, và tự động gợi ý danh mục chi tiêu. |
| 🛡️ **Xác minh trước khi lưu** | Màn hình `ReviewScreen` hiển thị badge phân loại ảnh, độ tin cậy OCR (Confidence Score), cảnh báo bất thường, cho phép chỉnh sửa toàn bộ thông tin trước khi ghi sổ. |
| 💾 **Lưu trữ cục bộ SQLite** | Cơ sở dữ liệu SQLite (`sqflite`) với đơn vị tiền tệ số nguyên VNĐ (`INTEGER`), truy vấn tham số hóa chống SQL Injection, đánh chỉ mục (`Index`) tăng tốc. |
| 🖼️ **Quản lý ảnh an toàn** | Sao chép ảnh vào thư mục riêng của ứng dụng (`receipt_images/<uuid>.jpg`), lưu đường dẫn tương đối và tự động xóa ảnh mồ côi khi xóa giao dịch. |
| 📊 **Trực quan hóa bản địa** | Biểu đồ Donut phân bổ danh mục và biểu đồ cột 7 ngày tự vẽ bằng `CustomPainter`, kèm bộ chọn tháng linh hoạt. |
| 🎨 **Material 3 UI** | Giao diện chuẩn Material 3, hỗ trợ chuyển đổi mượt mà giữa chế độ Sáng (Light) và Tối (Dark). |

---

## 🏗️ Kiến trúc dự án (Feature-First Clean Architecture)

```text
lib/
├── core/
│   ├── constants/       # AppColors (M3 Palette), AppConstants, RegexPatterns
│   ├── errors/          # Typed domain failure handling
│   ├── theme/           # Material 3 Light/Dark Themes
│   └── utils/           # CurrencyFormatter, DateFormatter, FileStorageHelper
├── data/
│   ├── database/        # AppDatabase (SQLite helper), TransactionDao (CRUD & Aggregations)
│   ├── models/          # TransactionModel, ParsedReceipt, SpendingSummary
│   └── repositories/    # TransactionRepository (Interface & SqliteTransactionRepository)
├── features/
│   ├── dashboard/       # Trang chủ, thẻ tổng quan tài chính, giao dịch gần nhất
│   ├── ocr/             # MlkitOcrService, ReceiptParser, RawOcrSheet
│   ├── scanner/         # ImageInputScreen (Camera / Gallery picker)
│   ├── settings/        # Cài đặt giao diện (Sáng/Tối), thông tin sinh viên
│   ├── statistics/      # DonutChartPainter, WeeklyBarChartPainter, StatisticsScreen
│   └── transactions/    # ReviewScreen, TransactionHistoryScreen, TransactionDetailScreen
└── main.dart            # Điểm khởi chạy ứng dụng & tiêm phụ thuộc (Dependency Injection)
```

---

## 🧪 Kết quả kiểm thử tự động (100% Pass Rate)

Dự án được xây dựng với hệ thống kiểm thử tự động toàn diện đạt **44 ca kiểm thử**:

- **20 Test Cases - Receipt Parser & Document Detection Engine (`test/ocr/receipt_parser_test.dart`)**:
  - Hóa đơn nhà hàng, quán cà phê tiếng Việt.
  - Hóa đơn siêu thị (ưu tiên tổng thanh toán cuối so với tạm tính & chiết khấu).
  - Phân biệt tổng tiền với tiền khách đưa và tiền thối lại.
  - Ảnh chụp chuyển khoản ngân hàng (Napas247 / VietQR, phát hiện người nhận).
  - Chuẩn hóa các định dạng ngày `dd/MM/yyyy`, `dd-MM-yyyy`, `yyyy-MM-dd`.
  - Phân loại học bổng/lương vào mục thu nhập.
  - Tự động nhận diện phân loại ảnh: Hóa đơn giấy (`receipt`), Ảnh chuyển khoản (`bankTransfer`), Ví điện tử (`eWallet`), Hóa đơn điện EVN (`utilityBill`), Chưa xác định (`unknown`).
  - Xử lý cảnh báo khi biên lai thiếu số tiền hoặc thiếu tên đơn vị.
- **11 Test Cases - SQLite DAO & Aggregations (`test/database/transaction_dao_test.dart`)**:
  - Chu trình CRUD cơ sở dữ liệu in-memory (`sqflite_common_ffi`).
  - Lọc theo tham số an toàn (loại, danh mục, khoảng ngày, từ khóa tìm kiếm).
  - Hàm tính toán tổng thu, tổng chi, số dư ròng và phân bổ 7 ngày.
- **13 Test Cases - Widget & Screen Tests (`test/widgets/`)**:
  - `review_screen_test.dart`: Hiển thị ứng viên OCR, kiểm tra validation khi để trống, lưu dữ liệu.
  - `transaction_detail_screen_test.dart`: Chi tiết giao dịch, xem ảnh, hộp thoại xác nhận xóa.
  - `statistics_screen_test.dart`: Bộ chọn tháng, chuyển đổi tab Donut Chart và Bar Chart.
  - `widget_test.dart`: Khởi chạy màn hình chính, thanh điều hướng và nút FAB.

---

## 🚀 Hướng dẫn cài đặt và chạy ứng dụng

### 1. Yêu cầu môi trường
- **Flutter SDK**: `>= 3.24.0` (Khuyến nghị Flutter 3.47.2 hoặc mới hơn)
- **Dart SDK**: `>= 3.5.0`
- **Android Studio / Android SDK**: `minSdkVersion 21`, `targetSdkVersion 34`
- **Java**: JDK 17

### 2. Cài đặt các gói phụ thuộc
```bash
flutter pub get
```

### 3. Chạy kiểm thử tự động (Unit & Widget Tests)
```bash
flutter test
```

### 4. Kiểm tra phân tích tĩnh mã nguồn
```bash
flutter analyze
```

### 5. Chạy ứng dụng trên thiết bị Android hoặc máy ảo
```bash
flutter run
```

### 6. Đóng gói tệp cài đặt Android APK (Release Build)
```bash
flutter build apk --release
```
*Tệp APK sau khi đóng gói sẽ nằm tại: `build/app/outputs/flutter-apk/app-release.apk`*

---

## 📑 Tài liệu kỹ thuật chi tiết

- [Báo cáo kỹ thuật đồ án (Technical Report)](docs/technical_report.md)
- [Kiến trúc hệ thống (Architecture)](docs/architecture.md)
- [Lược đồ cơ sở dữ liệu SQLite (Database Schema)](docs/database_schema.md)
- [Kế hoạch kiểm thử (Test Plan)](docs/test_plan.md)
- [Kế hoạch triển khai (Implementation Plan)](docs/implementation_plan.md)

---

## 👥 Nhóm tác giả & Đơn vị đào tạo
- **Học phần**: Phát triển ứng dụng di động đa nền tảng
- **Đơn vị đào tạo**: Trường Đại học Công nghệ Thông tin và Truyền thông Việt - Hàn (VKU) - Đại học Đà Nẵng
