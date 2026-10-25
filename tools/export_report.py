import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_shading(cell, color_hex):
    shading_xml = f'<w:shd {nsdecls("w")} w:fill="{color_hex}"/>'
    cell._tc.get_or_add_tcPr().append(parse_xml(shading_xml))

def create_report():
    doc = docx.Document()
    
    # Page setup - Margins 1 inch
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
        
    # Styles
    style = doc.styles['Normal']
    font = style.font
    font.name = 'Times New Roman'
    font.size = Pt(12)
    font.color.rgb = RGBColor(0x1F, 0x29, 0x37)

    # Title
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run_title = p_title.add_run("MINI-PROJECT SHORT TECHNICAL REPORT")
    run_title.bold = True
    run_title.font.size = Pt(18)
    run_title.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)

    # Course info
    def add_meta_line(label, value):
        p = doc.add_paragraph()
        p.paragraph_format.space_after = Pt(4)
        r1 = p.add_run(f"{label}: ")
        r1.bold = True
        r1.font.size = Pt(11)
        r2 = p.add_run(value)
        r2.font.size = Pt(11)

    add_meta_line("Course", "Cross-Platform Mobile App Development (VKU)")
    add_meta_line("Mini-Project Title", "Project 3: Flutter - Quản Lý Chi Tiêu OCR Hóa Đơn - Flutter (ML Kit)")
    add_meta_line("Team / Student Name", "Lê Cảm (23IT022)")
    add_meta_line("Submission Date", "25/10/2026")

    doc.add_paragraph().paragraph_format.space_after = Pt(6)

    # 1. GENERAL INFORMATION & DELIVERABLE LINKS
    h1 = doc.add_heading(level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(6)
    r = h1.add_run("1. GENERAL INFORMATION & DELIVERABLE LINKS")
    r.bold = True
    r.font.size = Pt(13)
    r.font.color.rgb = RGBColor(0x1E, 0x40, 0xAF)

    def add_bullet(bold_prefix, text, link_text=None):
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.space_after = Pt(4)
        r1 = p.add_run(bold_prefix)
        r1.bold = True
        r2 = p.add_run(text)
        if link_text:
            r3 = p.add_run(f": {link_text}")
            r3.font.color.rgb = RGBColor(0x25, 0x63, 0xEB)
            r3.underline = True

    add_bullet("Student: ", "Lê Cảm — Student ID: 23IT022 — Role: Full-Stack Mobile Developer (Architecture, On-Device ML Kit OCR Engine, UI/UX & SQLite Data Layer) — Contribution: 100%")
    add_bullet("🔗 Live Demo URL", "", "https://github.com/CAMLC25/camle-vku-receipt_ocr_expense_tracker/releases/download/v1.0.0/app-release.apk")
    add_bullet("💻 GitHub Repository", "", "https://github.com/CAMLC25/camle-vku-receipt_ocr_expense_tracker")
    add_bullet("🎥 Video Demo (Optional)", "", "https://youtube.com/shorts/90HkVXdvj50")

    # 2. FEATURE IMPLEMENTATION CHECKLIST
    h2 = doc.add_heading(level=1)
    h2.paragraph_format.space_before = Pt(16)
    h2.paragraph_format.space_after = Pt(6)
    r = h2.add_run("2. FEATURE IMPLEMENTATION CHECKLIST")
    r.bold = True
    r.font.size = Pt(13)
    r.font.color.rgb = RGBColor(0x1E, 0x40, 0xAF)

    features = [
        ("1", "100% On-Device OCR Recognition", "Complete", "Tích hợp Google ML Kit (google_mlkit_text_recognition). Hoạt động hoàn toàn Offline, bảo mật dữ liệu tuyệt đối không gửi ảnh lên Cloud."),
        ("2", "Image Preprocessing Pipeline", "Complete", "Module ImagePreprocessor tự động phóng to siêu phân giải (Bicubic Interpolation >= 1500px) và tăng tương phản 35% trên background Isolate giúp nhận dạng xuất sắc cả ảnh mờ/ảnh in nhiệt."),
        ("3", "Intelligent Vietnamese Heuristic Parser", "Complete", "Tái cấu trúc dòng không gian (Spatial Visual Row Reconstruction), trích xuất chuẩn xác tổng tiền thực trả (phân biệt tiền thối, chiết khấu, tạm tính), ngày giờ, mã giao dịch."),
        ("4", "Smart Entity & Category Classification", "Complete", "Thuật toán đối sánh 2 tầng (Dual-layer Accented & Non-accented) nhận diện chuẩn người nhận chuyển khoản ngân hàng, quán ăn, siêu thị, vé máy bay, xăng xe..."),
        ("5", "Review & Verification Screen", "Complete", "Màn hình xem lại bắt buộc: Hiển thị ảnh chụp, các trường dữ liệu tự động điền, thanh điểm tin cậy (Confidence Score) và cảnh báo trực quan viền cam khi thiếu thông tin."),
        ("6", "Local SQLite Offline Persistence", "Complete", "Lưu trữ cục bộ qua sqflite với kiểu số nguyên VNĐ (INTEGER), chống SQL Injection bằng Parameterized Queries. Lưu ảnh vào sandbox app với cơ chế relative path."),
        ("7", "Native CustomPainter Visual Charts", "Complete", "Tự vẽ 100% biểu đồ hình vành khuyên (Donut Chart) và biểu đồ cột xu hướng 7 ngày (Weekly Bar Chart) bằng Flutter Canvas API & AnimationController, không dùng thư viện ngoài."),
        ("8", "Material 3 UI & Dark/Light Mode", "Complete", "Thiết kế chuẩn Fintech với bảng màu hiện đại, nút Quét hóa đơn tích hợp chính giữa Bottom Navigation Bar, hỗ trợ Dark/Light Theme qua SegmentedButton."),
        ("9", "Automated Testing Suite", "Complete", "Đạt 57/57 unit, widget & integration tests pass 100%. dart analyze sạch 0 cảnh báo/0 lỗi.")
    ]

    table = doc.add_table(rows=1 + len(features), cols=4)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    hdr_cells = table.rows[0].cells
    headers = ["#", "Required Feature", "Status", "Implementation Details & Acceptance Level"]
    col_widths = [Inches(0.4), Inches(2.0), Inches(1.0), Inches(3.1)]

    for i, h in enumerate(headers):
        hdr_cells[i].text = h
        set_cell_shading(hdr_cells[i], "1E40AF")
        p = hdr_cells[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        for run in p.runs:
            run.font.bold = True
            run.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
            run.font.size = Pt(9.5)

    for row_idx, f in enumerate(features):
        row_cells = table.rows[row_idx + 1].cells
        for col_idx in range(4):
            row_cells[col_idx].text = f[col_idx]
            p = row_cells[col_idx].paragraphs[0]
            if col_idx in [0, 2]:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            for run in p.runs:
                run.font.size = Pt(9)
                if col_idx == 1:
                    run.font.bold = True
                if col_idx == 2:
                    run.font.bold = True
                    run.font.color.rgb = RGBColor(0x16, 0x65, 0x34)
            if row_idx % 2 == 1:
                set_cell_shading(row_cells[col_idx], "F8FAFC")

    for row in table.rows:
        for idx, width in enumerate(col_widths):
            row.cells[idx].width = width

    # 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE
    h3 = doc.add_heading(level=1)
    h3.paragraph_format.space_before = Pt(18)
    h3.paragraph_format.space_after = Pt(6)
    r = h3.add_run("3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE")
    r.bold = True
    r.font.size = Pt(13)
    r.font.color.rgb = RGBColor(0x1E, 0x40, 0xAF)

    p_arch = doc.add_paragraph()
    p_arch.paragraph_format.space_after = Pt(4)
    r = p_arch.add_run("3.1. Architectural Overview & State Management\n")
    r.bold = True
    p_arch.add_run("Dự án áp dụng mô hình Feature-First Clean Architecture kết hợp mẫu thiết kế Repository Pattern nhằm phân tách độc lập giữa giao diện, tầng nghiệp vụ và cơ sở dữ liệu:")

    add_bullet("Presentation Layer (Screens & Widgets): ", "DashboardScreen, ImageInputScreen, ReviewScreen, StatisticsScreen, SettingsScreen.")
    add_bullet("State Management Flow: ", "Sử dụng provider chính thức với 3 controller: DashboardProvider (tổng hợp số dư), TransactionProvider (danh sách & tìm kiếm), SettingsProvider (giao diện Sáng/Tối).")
    add_bullet("Domain Services: ", "ImagePreprocessor (phóng to siêu phân giải Isolate), MlkitOcrService (quét ký tự), ReceiptParser (bóc tách thực thể).")
    add_bullet("Data Persistence: ", "TransactionRepository, TransactionDao và AppDatabase SQLite cục bộ.")

    p_dir = doc.add_paragraph()
    p_dir.paragraph_format.space_before = Pt(6)
    r = p_dir.add_run("3.2. Cấu trúc thư mục dự án chuẩn hóa:\n")
    r.bold = True
    p_dir.add_run("Hệ thống phân chia theo module tính năng (Feature-First): lib/core (constants, theme, utils), lib/data (database, models, repositories), lib/features (dashboard, ocr, scanner, settings, statistics, transactions).")

    # 4. EMPIRICAL EVIDENCE & SCREENSHOTS
    h4 = doc.add_heading(level=1)
    h4.paragraph_format.space_before = Pt(18)
    h4.paragraph_format.space_after = Pt(6)
    r = h4.add_run("4. EMPIRICAL EVIDENCE & SCREENSHOTS")
    r.bold = True
    r.font.size = Pt(13)
    r.font.color.rgb = RGBColor(0x1E, 0x40, 0xAF)

    img_table = doc.add_table(rows=2, cols=2)
    img_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    
    screenshots = [
        ("docs/screenshots/01_dashboard_screen.png", "Hình 1: Trang chủ Dashboard", "Thẻ số dư tháng, phím Quét tích hợp giữa NavigationBar, danh sách chi tiêu không tràn viền."),
        ("docs/screenshots/02_history_screen.png", "Hình 2: Lịch sử giao dịch", "Tìm kiếm tức thì, bộ lọc đa tầng (Tất cả, Chi tiêu, Thu nhập, Danh mục) với chip xóa nhanh."),
        ("docs/screenshots/03_statistics_screen.png", "Hình 3: Biểu đồ Thống kê", "Biểu đồ hình vành khuyên (Donut Chart) tự vẽ Canvas API phân bổ tỷ lệ chi tiêu theo danh mục."),
        ("docs/screenshots/04_settings_screen.png", "Hình 4: Cài đặt & Bảo mật", "Tùy chọn giao diện SegmentedButton, cam kết 100% On-Device bảo mật và thông tin đồ án VKU.")
    ]

    for idx, (img_path, caption, desc) in enumerate(screenshots):
        row = idx // 2
        col = idx % 2
        cell = img_table.rows[row].cells[col]
        cell.width = Inches(3.2)
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_after = Pt(2)
        if os.path.exists(img_path):
            p.add_run().add_picture(img_path, width=Inches(2.2))
        p_cap = cell.add_paragraph()
        p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_cap.paragraph_format.space_after = Pt(2)
        r_cap = p_cap.add_run(f"\n{caption}")
        r_cap.bold = True
        r_cap.font.size = Pt(9.5)
        p_desc = cell.add_paragraph()
        p_desc.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_desc.paragraph_format.space_after = Pt(10)
        r_desc = p_desc.add_run(desc)
        r_desc.font.size = Pt(8.5)
        r_desc.font.italic = True

    # 5. TECHNICAL CHALLENGES & RESOLUTIONS
    h5 = doc.add_heading(level=1)
    h5.paragraph_format.space_before = Pt(18)
    h5.paragraph_format.space_after = Pt(6)
    r = h5.add_run("5. TECHNICAL CHALLENGES & RESOLUTIONS")
    r.bold = True
    r.font.size = Pt(13)
    r.font.color.rgb = RGBColor(0x1E, 0x40, 0xAF)

    p_b1 = doc.add_paragraph()
    r = p_b1.add_run("Bottleneck 1: Ảnh chụp độ phân giải thấp khiến ML Kit mất nét chữ in nhiệt\n")
    r.bold = True
    r.font.color.rgb = RGBColor(0xB9, 0x1C, 0x1C)
    p_b1.add_run("• Thực trạng: Khi chụp hóa đơn từ xa hoặc tải ảnh thumbnail thấp (chiều cao chỉ 400-600px), các dòng chi tiết món ăn chỉ cao 3-5 pixel khiến mô hình CNN của Google ML Kit bỏ sót toàn bộ bảng tính tiền và nhận diện nhầm tiêu đề chân trang.\n")
    p_b1.add_run("• Giải pháp: Xây dựng module ImagePreprocessor chạy trên Isolate riêng biệt (compute). Hệ thống tự động phóng to nội suy Bicubic (>= 1500px) đưa nét chữ đạt chuẩn >= 15px, đồng thời tăng tương phản 35% (contrast: 1.35) để tách biệt chữ in nhiệt phai màu khỏi nền giấy trước khi đưa vào ML Kit.")

    p_b2 = doc.add_paragraph()
    p_b2.paragraph_format.space_before = Pt(6)
    r = p_b2.add_run("Bottleneck 2: Bóc tách hóa đơn tiếng Việt không dấu và nhầm lẫn tiêu đề phiếu\n")
    r.bold = True
    r.font.color.rgb = RGBColor(0xB9, 0x1C, 0x1C)
    p_b2.add_run("• Thực trạng: Nhiều nhà hàng in hóa đơn không dấu (QUAN AN THIEN TAN) khiến bộ lọc danh mục bị bỏ qua và rơi vào mục 'Khác'. Đồng thời dòng đầu in 'Sö HD: 70104' hoặc 'PHIẾU TẠM TÍNH' thường bị nhận diện nhầm thành tên cửa hàng (Merchant Name).\n")
    p_b2.add_run("• Giải pháp:\n")
    p_b2.add_run("  1. Triển khai thuật toán Spatial Visual Row Reconstruction: Gom các khối chữ rời rạc có độ chồng lấp trục Y > 35% vào cùng một dòng nằm ngang, giúp ghép nối nhãn và số tiền chính xác.\n")
    p_b2.add_run("  2. Bổ sung RegexPatterns.invoiceTitlePattern loại bỏ triệt để các dạng số hóa đơn và chứng từ tạm tính.\n")
    p_b2.add_run("  3. Xây dựng bộ đối sánh Dual-layer Keyword Matching chuẩn hóa tự động chuỗi không dấu để phân loại chính xác 100% danh mục Ăn uống, Siêu thị, Di chuyển và Chuyển khoản ngân hàng.")

    out_docx = "docs/technical_report.docx"
    doc.save(out_docx)
    print(f"Successfully generated {out_docx} ({os.path.getsize(out_docx) / 1024:.1f} KB)")

if __name__ == '__main__':
    create_report()
