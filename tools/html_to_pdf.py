import os
import subprocess

html_content = """<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<title>MINI-PROJECT SHORT TECHNICAL REPORT</title>
<style>
  @page { size: A4; margin: 18mm; }
  body { font-family: 'Times New Roman', Times, serif; font-size: 11pt; line-height: 1.45; color: #1f2937; margin: 0; }
  h1 { text-align: center; font-size: 17pt; color: #0f172a; margin-bottom: 20px; text-transform: uppercase; }
  h2 { font-size: 13pt; color: #1e40af; border-bottom: 2px solid #e2e8f0; padding-bottom: 3px; margin-top: 18px; margin-bottom: 10px; }
  .meta-p { margin: 3px 0; font-size: 11pt; }
  .meta-p strong { color: #0f172a; }
  table { width: 100%; border-collapse: collapse; margin: 12px 0; font-size: 9pt; }
  th, td { border: 1px solid #cbd5e1; padding: 6px 8px; text-align: left; vertical-align: top; }
  th { background-color: #1e40af; color: white; text-align: center; font-weight: bold; }
  tr:nth-child(even) { background-color: #f8fafc; }
  .img-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin: 12px 0; text-align: center; }
  .img-card { border: 1px solid #cbd5e1; border-radius: 6px; padding: 6px; background: #fff; }
  .img-card img { max-width: 85%; border-radius: 4px; }
  .img-cap { font-weight: bold; font-size: 9.5pt; margin-top: 4px; color: #0f172a; }
  .img-desc { font-style: italic; font-size: 8.5pt; color: #64748b; }
  .badge-success { color: #166534; font-weight: bold; text-align: center; }
  .bullet-list { margin: 6px 0; padding-left: 20px; }
  .bullet-list li { margin-bottom: 4px; }
  .bottleneck-title { color: #b91c1c; font-weight: bold; margin-top: 10px; font-size: 10.5pt; }
</style>
</head>
<body>

<h1>MINI-PROJECT SHORT TECHNICAL REPORT</h1>
<div class="meta-p"><strong>Course:</strong> Cross-Platform Mobile App Development (VKU)</div>
<div class="meta-p"><strong>Mini-Project Title:</strong> Project 3: Flutter - Quản Lý Chi Tiêu OCR Hóa Đơn - Flutter (ML Kit)</div>
<div class="meta-p"><strong>Team / Student Name:</strong> Lê Cảm (23IT022)</div>
<div class="meta-p"><strong>Submission Date:</strong> 25/10/2026</div>

<h2>1. GENERAL INFORMATION & DELIVERABLE LINKS</h2>
<ul class="bullet-list">
  <li><strong>Student:</strong> Lê Cảm — Student ID: 23IT022 — Role: Full-Stack Mobile Developer (Architecture, On-Device ML Kit OCR Engine, UI/UX & SQLite Data Layer) — Contribution: 100%</li>
  <li><strong>🔗 Live Demo URL:</strong> <a href="https://github.com/CAMLC25/camle-vku-receipt_ocr_expense_tracker/releases/download/v1.0.0/app-release.apk">https://github.com/CAMLC25/camle-vku-receipt_ocr_expense_tracker/releases/download/v1.0.0/app-release.apk</a></li>
  <li><strong>💻 GitHub Repository:</strong> <a href="https://github.com/CAMLC25/camle-vku-receipt_ocr_expense_tracker">https://github.com/CAMLC25/camle-vku-receipt_ocr_expense_tracker</a></li>
  <li><strong>🎥 Video Demo (Optional):</strong> <a href="https://youtube.com/shorts/90HkVXdvj50">https://youtube.com/shorts/90HkVXdvj50</a></li>
</ul>

<h2>2. FEATURE IMPLEMENTATION CHECKLIST</h2>
<table>
  <thead>
    <tr>
      <th style="width: 5%;">#</th>
      <th style="width: 28%;">Required Feature</th>
      <th style="width: 14%;">Status</th>
      <th style="width: 53%;">Implementation Details & Acceptance Level</th>
    </tr>
  </thead>
  <tbody>
    <tr><td style="text-align:center;">1</td><td><strong>100% On-Device OCR Recognition</strong></td><td class="badge-success">✅ Complete</td><td>Tích hợp Google ML Kit (google_mlkit_text_recognition). Hoạt động hoàn toàn Offline, bảo mật dữ liệu tuyệt đối không gửi ảnh lên Cloud.</td></tr>
    <tr><td style="text-align:center;">2</td><td><strong>Image Preprocessing Pipeline</strong></td><td class="badge-success">✅ Complete</td><td>Module ImagePreprocessor tự động phóng to siêu phân giải (Bicubic Interpolation >= 1500px) và tăng tương phản 35% trên background Isolate giúp nhận dạng xuất sắc cả ảnh mờ/ảnh in nhiệt.</td></tr>
    <tr><td style="text-align:center;">3</td><td><strong>Intelligent Vietnamese Heuristic Parser</strong></td><td class="badge-success">✅ Complete</td><td>Tái cấu trúc dòng không gian (Spatial Visual Row Reconstruction), trích xuất chuẩn xác tổng tiền thực trả (phân biệt tiền thối, chiết khấu, tạm tính), ngày giờ, mã giao dịch.</td></tr>
    <tr><td style="text-align:center;">4</td><td><strong>Smart Entity & Category Classification</strong></td><td class="badge-success">✅ Complete</td><td>Thuật toán đối sánh 2 tầng (Dual-layer Accented & Non-accented) nhận diện chuẩn người nhận chuyển khoản ngân hàng, quán ăn, siêu thị, vé máy bay, xăng xe...</td></tr>
    <tr><td style="text-align:center;">5</td><td><strong>Review & Verification Screen</strong></td><td class="badge-success">✅ Complete</td><td>Màn hình xem lại bắt buộc: Hiển thị ảnh chụp, các trường dữ liệu tự động điền, thanh điểm tin cậy (Confidence Score) và cảnh báo trực quan viền cam khi thiếu thông tin.</td></tr>
    <tr><td style="text-align:center;">6</td><td><strong>Local SQLite Offline Persistence</strong></td><td class="badge-success">✅ Complete</td><td>Lưu trữ cục bộ qua sqflite với kiểu số nguyên VNĐ (INTEGER), chống SQL Injection bằng Parameterized Queries. Lưu ảnh vào sandbox app với cơ chế relative path.</td></tr>
    <tr><td style="text-align:center;">7</td><td><strong>Native CustomPainter Visual Charts</strong></td><td class="badge-success">✅ Complete</td><td>Tự vẽ 100% biểu đồ hình vành khuyên (Donut Chart) và biểu đồ cột xu hướng 7 ngày (Weekly Bar Chart) bằng Flutter Canvas API & AnimationController, không dùng thư viện ngoài.</td></tr>
    <tr><td style="text-align:center;">8</td><td><strong>Material 3 UI & Dark/Light Mode</strong></td><td class="badge-success">✅ Complete</td><td>Thiết kế chuẩn Fintech với bảng màu hiện đại, nút Quét hóa đơn tích hợp chính giữa Bottom Navigation Bar, hỗ trợ Dark/Light Theme qua SegmentedButton.</td></tr>
    <tr><td style="text-align:center;">9</td><td><strong>Automated Testing Suite</strong></td><td class="badge-success">✅ Complete</td><td>Đạt 57/57 unit, widget & integration tests pass 100%. dart analyze sạch 0 cảnh báo/0 lỗi.</td></tr>
  </tbody>
</table>

<h2>3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE</h2>
<p><strong>3.1. Architectural Overview & State Management:</strong> Dự án áp dụng mô hình Feature-First Clean Architecture kết hợp Repository Pattern phân tách độc lập giữa Presentation, Domain và Data Layer.</p>
<ul class="bullet-list">
  <li><strong>Presentation Layer:</strong> DashboardScreen, ImageInputScreen, ReviewScreen, StatisticsScreen, SettingsScreen.</li>
  <li><strong>State Management:</strong> Provider với 3 controller: DashboardProvider, TransactionProvider, SettingsProvider.</li>
  <li><strong>Domain Services:</strong> ImagePreprocessor (phóng to siêu phân giải Isolate), MlkitOcrService, ReceiptParser.</li>
  <li><strong>Data Persistence:</strong> TransactionRepository, TransactionDao và AppDatabase SQLite cục bộ.</li>
</ul>

<h2>4. EMPIRICAL EVIDENCE & SCREENSHOTS</h2>
<div class="img-grid">
  <div class="img-card">
    <img src="screenshots/01_dashboard_screen.png" alt="Trang chủ Dashboard">
    <div class="img-cap">Hình 1: Trang chủ Dashboard</div>
    <div class="img-desc">Thẻ số dư tháng, phím Quét tích hợp giữa NavigationBar, danh sách không tràn viền.</div>
  </div>
  <div class="img-card">
    <img src="screenshots/02_history_screen.png" alt="Lịch sử giao dịch">
    <div class="img-cap">Hình 2: Lịch sử giao dịch</div>
    <div class="img-desc">Tìm kiếm tức thì, bộ lọc đa tầng với chip xóa nhanh trực quan.</div>
  </div>
  <div class="img-card">
    <img src="screenshots/03_statistics_screen.png" alt="Biểu đồ Thống kê">
    <div class="img-cap">Hình 3: Biểu đồ Thống kê</div>
    <div class="img-desc">Biểu đồ hình vành khuyên (Donut Chart) tự vẽ Canvas API phân bổ chi tiêu theo danh mục.</div>
  </div>
  <div class="img-card">
    <img src="screenshots/04_settings_screen.png" alt="Cài đặt & Bảo mật">
    <div class="img-cap">Hình 4: Cài đặt & Bảo mật</div>
    <div class="img-desc">Tùy chọn giao diện SegmentedButton, cam kết 100% On-Device bảo mật và thông tin đồ án VKU.</div>
  </div>
</div>

<h2>5. TECHNICAL CHALLENGES & RESOLUTIONS</h2>
<div class="bottleneck-title">Bottleneck 1: Ảnh chụp độ phân giải thấp khiến ML Kit mất nét chữ in nhiệt</div>
<ul class="bullet-list">
  <li><strong>Thực trạng:</strong> Khi chụp từ xa hoặc ảnh thumbnail nhỏ (400-600px), nét chữ chỉ 3-5px khiến CNN bỏ sót bảng tính tiền.</li>
  <li><strong>Giải pháp:</strong> Xây dựng module ImagePreprocessor chạy trên Isolate riêng biệt, tự động phóng to Bicubic (>= 1500px) và tăng tương phản 35% trước khi đưa vào ML Kit.</li>
</ul>

<div class="bottleneck-title">Bottleneck 2: Bóc tách hóa đơn tiếng Việt không dấu và nhầm lẫn tiêu đề phiếu</div>
<ul class="bullet-list">
  <li><strong>Thực trạng:</strong> Hóa đơn không dấu (QUAN AN THIEN TAN) bị phân loại nhầm vào "Khác"; số hóa đơn (Sö HD: 70104) bị nhầm thành tên quán.</li>
  <li><strong>Giải pháp:</strong> Triển khai thuật toán Spatial Visual Row Reconstruction gom dòng chữ theo trục Y, loại bỏ invoice title bằng Regex, và áp dụng Dual-layer Keyword Matching.</li>
</ul>

</body>
</html>
"""

with open("docs/report.html", "w", encoding="utf-8") as f:
    f.write(html_content)

edge_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
pdf_path = os.path.abspath("docs/technical_report.pdf")
html_path = os.path.abspath("docs/report.html")

cmd = f'"{edge_path}" --headless --disable-gpu --run-all-compositor-stages-before-draw --print-to-pdf="{pdf_path}" "{html_path}"'
subprocess.run(cmd, shell=True)
print("PDF generated successfully:", os.path.exists(pdf_path), f"{os.path.getsize(pdf_path)/1024:.1f} KB")
