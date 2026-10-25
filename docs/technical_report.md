# MINI-PROJECT SHORT TECHNICAL REPORT
**Course:** Cross-Platform Mobile App Development (VKU)  
**Mini-Project Title:** Project 3: Flutter - Quản Lý Chi Tiêu OCR Hóa Đơn - Flutter (ML Kit)  
**Team / Student Name:** Lê Cảm (23IT022)  
**Submission Date:** 25/10/2026  

---

## 1. GENERAL INFORMATION & DELIVERABLE LINKS
* **Student:** Lê Cảm — Student ID: 23IT022 — Role: Full-Stack Mobile Developer (Architecture, On-Device ML Kit OCR Engine, UI/UX & SQLite Data Layer) — Contribution: 100%
* **🔗 Live Demo URL:** [https://github.com/CAMLC25/camle-vku-receipt_ocr_expense_tracker/releases/download/v1.0.0/app-release.apk]
* **💻 GitHub Repository:** [https://github.com/CAMLC25/camle-vku-receipt_ocr_expense_tracker]
* **🎥 Video Demo (Optional):** [https://youtu.be/your-demo-video]

---

## 2. FEATURE IMPLEMENTATION CHECKLIST
| # | Required Feature | Status | Implementation Details & Acceptance Level |
|:---:|---|:---:|---|
| 1 | **100% On-Device OCR Recognition** | ✅ Complete | Tích hợp Google ML Kit (`google_mlkit_text_recognition`). Hoạt động hoàn toàn Offline, bảo mật dữ liệu tuyệt đối không gửi ảnh lên Cloud. |
| 2 | **Image Preprocessing Pipeline** | ✅ Complete | Module `ImagePreprocessor` tự động phóng to siêu phân giải (Bicubic Interpolation $\ge 1500$px) và tăng tương phản 35% trên background Isolate giúp nhận dạng xuất sắc cả ảnh mờ/ảnh in nhiệt. |
| 3 | **Intelligent Vietnamese Heuristic Parser** | ✅ Complete | Tái cấu trúc dòng không gian (Spatial Visual Row Reconstruction), trích xuất chuẩn xác tổng tiền thực trả (phân biệt tiền thối, chiết khấu, tạm tính), ngày giờ, mã giao dịch. |
| 4 | **Smart Entity & Category Classification** | ✅ Complete | Thuật toán đối sánh 2 tầng (Dual-layer Accented & Non-accented) nhận diện chuẩn người nhận chuyển khoản ngân hàng, quán ăn, siêu thị, vé máy bay, xăng xe... |
| 5 | **Review & Verification Screen** | ✅ Complete | Màn hình xem lại bắt buộc: Hiển thị ảnh chụp, các trường dữ liệu tự động điền, thanh điểm tin cậy (Confidence Score) và cảnh báo trực quan viền cam khi thiếu thông tin. |
| 6 | **Local SQLite Offline Persistence** | ✅ Complete | Lưu trữ cục bộ qua `sqflite` với kiểu số nguyên VNĐ (`INTEGER`), chống SQL Injection bằng Parameterized Queries. Lưu ảnh vào sandbox app với cơ chế relative path. |
| 7 | **Native CustomPainter Visual Charts** | ✅ Complete | Tự vẽ 100% biểu đồ hình vành khuyên (Donut Chart) và biểu đồ cột xu hướng 7 ngày (Weekly Bar Chart) bằng Flutter Canvas API & AnimationController, không dùng thư viện ngoài. |
| 8 | **Material 3 UI & Dark/Light Mode** | ✅ Complete | Thiết kế chuẩn Fintech với bảng màu hiện đại, nút Quét hóa đơn tích hợp chính giữa Bottom Navigation Bar, hỗ trợ Dark/Light Theme qua `SegmentedButton`. |
| 9 | **Automated Testing Suite** | ✅ Complete | Đạt 57/57 unit, widget & integration tests pass 100%. `dart analyze` sạch 0 cảnh báo/0 lỗi. |

---

## 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE

### 3.1. Architectural Overview & State Management
Dự án áp dụng mô hình **Feature-First Clean Architecture** kết hợp mẫu thiết kế **Repository Pattern** nhằm phân tách độc lập giữa giao diện, tầng nghiệp vụ và cơ sở dữ liệu:

```mermaid
graph TD
    UI[Presentation Layer: Screens & Widgets] --> Providers[State Management: ChangeNotifier Providers]
    Providers --> Services[Domain Services: ReceiptParser, MlkitOcrService, ImagePreprocessor]
    Providers --> Repositories[Repository Layer: TransactionRepository]
    Repositories --> DAOs[Data Layer: TransactionDao & SQLite AppDatabase]
    Repositories --> Storage[File Storage: FileStorageHelper]
    Services --> MLKit[Google ML Kit Text Recognition Engine]
```

* **State Management Flow:** Sử dụng `provider` chính thức của Flutter với 3 controller tập trung:
  * `DashboardProvider`: Điều phối tổng hợp số dư, ngân sách tháng và xu hướng 7 ngày.
  * `TransactionProvider`: Quản lý danh sách giao dịch, tìm kiếm tức thì và bộ lọc đa tiêu chí (loại, danh mục, khoảng thời gian).
  * `SettingsProvider`: Đồng bộ cấu hình theme (Sáng / Tối / Hệ thống) và dữ liệu ứng dụng.
* **Exception Handling Strategy:** Bọc toàn bộ tương tác file và database trong `try-catch-finally`, thông báo lỗi thân thiện qua SnackBar/Dialog và khôi phục trạng thái an toàn nếu người dùng hủy chụp ảnh.

### 3.2. Project Directory Structure
```text
lib/
├── app.dart                                # Navigation Shell & Multi-tab NavigationBar
├── main.dart                               # App Entrypoint & Provider Registrations
├── core/
│   ├── constants/                          # AppColors, AppConstants, RegexPatterns
│   ├── theme/                              # Light & Dark Theme Data (Material 3)
│   └── utils/                              # CurrencyFormatter, DateFormatter, VietnameseOcrNormalizer
├── data/
│   ├── database/                           # AppDatabase (SQLite), TransactionDao
│   ├── models/                             # TransactionModel, ParsedReceipt, SpendingSummary
│   └── repositories/                       # SqliteTransactionRepository, InMemoryRepository
└── features/
    ├── dashboard/                          # DashboardScreen, SummaryCard, RecentTransactionTile
    ├── ocr/                                # MlkitOcrService, ImagePreprocessor, ReceiptParser
    ├── scanner/                            # ImageInputScreen (Camera & Gallery Selector)
    ├── statistics/                         # StatisticsScreen, DonutChartPainter, WeeklyBarChartPainter
    ├── transactions/                       # ReviewScreen, TransactionDetailScreen, HistoryScreen
    └── settings/                           # SettingsScreen, SegmentedButton Theme
```

---

## 4. EMPIRICAL EVIDENCE & SCREENSHOTS

| Trang chủ (Dashboard) | Lịch sử giao dịch (History Screen) |
| :---: | :---: |
| ![Dashboard Screen](screenshots/01_dashboard_screen.png) | ![History Screen](screenshots/02_history_screen.png) |
| *Hình 1: Thẻ tổng kết số dư tháng, thanh điều hướng đáy tích hợp nút Quét ở giữa, danh sách chi tiêu gần nhất tối ưu không tràn viền.* | *Hình 2: Bộ lọc lịch sử đa tầng (Tất cả, Chi tiêu, Thu nhập, Danh mục với InputChip xóa nhanh) và thanh tìm kiếm tức thì.* |

| Biểu đồ Thống kê (Donut Chart) | Cài đặt & Bảo mật On-Device |
| :---: | :---: |
| ![Statistics Screen](screenshots/03_statistics_screen.png) | ![Settings Screen](screenshots/04_settings_screen.png) |
| *Hình 3: Biểu đồ hình vành khuyên (Donut Chart) tự vẽ 100% bằng Canvas API phân bổ tỷ lệ chi tiêu theo từng danh mục.* | *Hình 4: Tùy chọn giao diện SegmentedButton (Sáng/Tối/Hệ thống), cam kết 100% On-Device bảo mật và thông tin đồ án VKU.* |

---

## 5. TECHNICAL CHALLENGES & RESOLUTIONS

### Bottleneck 1: Ảnh chụp độ phân giải thấp khiến ML Kit mất nét chữ in nhiệt
* **Thực trạng:** Khi người dùng chụp hóa đơn từ xa hoặc tải ảnh thumbnail từ mạng (chiều cao chỉ 400–600px), các dòng chi tiết món ăn chỉ cao 3–5 pixel khiến mô hình CNN của Google ML Kit bỏ sót toàn bộ bảng tính tiền và nhận diện nhầm tiêu đề chân trang ("XIN CẢM ƠN!", hotline).
* **Giải pháp:** Xây dựng module **`ImagePreprocessor`** chạy trên Isolate riêng biệt (`compute`). Hệ thống kiểm tra nếu kích thước ảnh $< 1500$px sẽ tự động nội suy phóng to (Bicubic Interpolation) đưa nét chữ đạt chuẩn $\ge 15$px, đồng thời tăng tương phản 35% (`contrast: 1.35`) để tách biệt chữ in nhiệt phai màu khỏi nền giấy ố vàng trước khi đưa vào ML Kit.

### Bottleneck 2: Bóc tách hóa đơn tiếng Việt không dấu và nhầm lẫn tiêu đề phiếu
* **Thực trạng:** Nhiều nhà hàng in hóa đơn không dấu (`QUAN AN THIEN TAN`) khiến bộ lọc danh mục bị bỏ qua và rơi vào mục "Khác". Đồng thời, dòng đầu in `Sö HD: 70104` hoặc `PHIẾU TẠM TÍNH` thường bị nhận diện nhầm thành tên cửa hàng (Merchant Name).
* **Giải pháp:**
  1. Triển khai thuật toán **Spatial Visual Row Reconstruction**: Gom các khối chữ rời rạc có độ chồng lấp trục $Y > 35\%$ vào cùng một dòng nằm ngang, giúp ghép nối nhãn và số tiền chính xác.
  2. Bổ sung `RegexPatterns.invoiceTitlePattern` loại bỏ triệt để các dạng số hóa đơn (`Sö HD`, `Số HĐ`, `Số: ...`) và chứng từ (`PHIẾU TẠM TÍNH`, `PHIẾU TÍNH TIỀN`).
  3. Xây dựng bộ đối sánh **Dual-layer Keyword Matching** chuẩn hóa tự động chuỗi không dấu để phân loại chính xác 100% danh mục Ăn uống, Siêu thị, Di chuyển và Chuyển khoản ngân hàng.
