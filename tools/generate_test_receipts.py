import os
from PIL import Image, ImageDraw, ImageFont

output_dir = r"d:\Study\Cross-Platform Mobile Application Development\Mini-Project 3\vku-receipt_ocr_expense_tracker\test_receipts"
os.makedirs(output_dir, exist_ok=True)

def create_receipt_image(filename, lines, title_color=(15, 15, 15), bg_color=(255, 255, 255), width=900, height=1300):
    img = Image.new("RGB", (width, height), bg_color)
    draw = ImageDraw.Draw(img)
    
    # Crisp typography for on-device OCR
    try:
        font_title = ImageFont.truetype("arial.ttf", 36)
        font_large = ImageFont.truetype("arial.ttf", 28)
        font_body = ImageFont.truetype("arial.ttf", 24)
        font_small = ImageFont.truetype("arial.ttf", 20)
    except Exception:
        font_title = ImageFont.load_default()
        font_large = ImageFont.load_default()
        font_body = ImageFont.load_default()
        font_small = ImageFont.load_default()

    # Draw border
    draw.rectangle([(25, 25), (width - 25, height - 25)], outline=(210, 210, 210), width=3)
    
    y = 60
    for line in lines:
        text, style = line
        if style == "title":
            draw.text((width // 2, y), text, fill=title_color, font=font_title, anchor="mt")
            y += 55
        elif style == "subtitle":
            draw.text((width // 2, y), text, fill=(80, 80, 80), font=font_small, anchor="mt")
            y += 36
        elif style == "divider":
            draw.line([(50, y), (width - 50, y)], fill=(180, 180, 180), width=2)
            y += 26
        elif style == "bold_row":
            parts = text.split("||")
            if len(parts) == 2:
                label = parts[0] + ":" if not parts[0].endswith(":") else parts[0]
                draw.text((60, y), label, fill=(15, 15, 15), font=font_large)
                draw.text((width - 60, y), parts[1], fill=(15, 15, 15), font=font_large, anchor="ra")
                dot_start = 60 + len(label) * 16
                dot_end = width - 60 - len(parts[1]) * 16
                if dot_end > dot_start:
                    dots = ". " * max(1, (dot_end - dot_start) // 20)
                    draw.text((dot_start + 6, y), dots, fill=(180, 180, 180), font=font_body)
            else:
                draw.text((60, y), text, fill=(15, 15, 15), font=font_large)
            y += 48
        elif style == "body_row":
            parts = text.split("||")
            if len(parts) == 2:
                label = parts[0]
                draw.text((60, y), label, fill=(40, 40, 40), font=font_body)
                draw.text((width - 60, y), parts[1], fill=(40, 40, 40), font=font_body, anchor="ra")
                dot_start = 60 + len(label) * 14
                dot_end = width - 60 - len(parts[1]) * 14
                if dot_end > dot_start:
                    dots = ". " * max(1, (dot_end - dot_start) // 18)
                    draw.text((dot_start + 6, y), dots, fill=(200, 200, 200), font=font_small)
            else:
                draw.text((60, y), text, fill=(40, 40, 40), font=font_body)
            y += 40
        elif style == "highlight":
            draw.rectangle([(50, y - 6), (width - 50, y + 54)], fill=(238, 246, 255), outline=(150, 195, 255), width=2)
            parts = text.split("||")
            if len(parts) == 2:
                label = parts[0] + ":" if not parts[0].endswith(":") else parts[0]
                draw.text((65, y + 4), label, fill=(10, 50, 140), font=font_large)
                draw.text((width - 65, y + 4), parts[1], fill=(10, 50, 140), font=font_large, anchor="ra")
            else:
                draw.text((65, y + 4), text, fill=(10, 50, 140), font=font_large)
            y += 66
        elif style == "footer":
            draw.text((width // 2, y), text, fill=(110, 110, 110), font=font_small, anchor="mt")
            y += 34

    filepath = os.path.join(output_dir, filename)
    img.save(filepath, "PNG")
    print(f"Created {filepath}")

# ==============================================================================
# 10 BỘ MẪU HÓA ĐƠN CHUẨN ĐỘ PHÂN GIẢI CAO (HD REALISTIC VIETNAMESE RECEIPTS)
# ==============================================================================

# 1. Highlands Coffee (F&B / Ăn uống)
create_receipt_image(
    "01_highlands_coffee.png",
    [
        ("HIGHLANDS COFFEE", "title"),
        ("Đ/C: 15 Lê Duẩn, P. Hải Châu 1, Q. Hải Châu, TP. Đà Nẵng", "subtitle"),
        ("Số HĐ: HD882912 - Bàn: 04", "subtitle"),
        ("Ngày: 15/10/2026  14:30:00", "subtitle"),
        ("", "divider"),
        ("1 Freeze Trà Xanh L||65.000 đ", "body_row"),
        ("1 Bánh Mì Que Gà||24.000 đ", "body_row"),
        ("", "divider"),
        ("Tiền hàng||89.000 đ", "body_row"),
        ("TỔNG CỘNG||89.000 đ", "highlight"),
        ("Tiền khách đưa||100.000 đ", "body_row"),
        ("Tiền thừa||11.000 đ", "body_row"),
        ("", "divider"),
        ("Cảm ơn quý khách - Hẹn gặp lại!", "footer"),
    ]
)

# 2. WinMart Supermarket (Groceries / Siêu thị)
create_receipt_image(
    "02_winmart_sieu_thi.png",
    [
        ("SIÊU THỊ WINMART+", "title"),
        ("Đ/C: 240 Nguyễn Hữu Thọ, Q. Cẩm Lệ, TP. Đà Nẵng", "subtitle"),
        ("Số HĐ: WM-908123 - Thu ngân: Mai Anh", "subtitle"),
        ("Ngày: 12/10/2026  09:45:00", "subtitle"),
        ("", "divider"),
        ("1 Sữa tươi Vinamilk 1L||36.000 đ", "body_row"),
        ("2 Mì Hảo Hảo Sa Tế||9.000 đ", "body_row"),
        ("1 Dầu ăn Simply 1L||63.000 đ", "body_row"),
        ("", "divider"),
        ("Tiền hàng||108.000 đ", "body_row"),
        ("Giảm giá||0 đ", "body_row"),
        ("TỔNG TIỀN THANH TOÁN||108.000 đ", "highlight"),
        ("Tiền mặt||200.000 đ", "body_row"),
        ("Tiền thừa||92.000 đ", "body_row"),
        ("", "divider"),
        ("Hotline: 1800 6968", "footer"),
        ("Xin cảm ơn quý khách!", "footer"),
    ]
)

# 3. Vietcombank Transfer (Banking / Chuyển khoản)
create_receipt_image(
    "03_vietcombank_chuyen_khoan.png",
    [
        ("Vietcombank", "title"),
        ("GIAO DỊCH THÀNH CÔNG", "title"),
        ("Chuyển tiền thành công", "subtitle"),
        ("", "divider"),
        ("SỐ TIỀN||1.250.000 VND", "highlight"),
        ("Ngày: 10/10/2026  09:15:30", "subtitle"),
        ("", "divider"),
        ("Người nhận||LÊ THỊ MINH ANH", "bold_row"),
        ("Ngân hàng||Vietcombank (VCB)", "body_row"),
        ("Tài khoản thụ hưởng||0121000987654", "body_row"),
        ("Nội dung||Tiền phòng trọ tháng 10", "body_row"),
        ("Mã giao dịch||VCB982736152", "body_row"),
        ("", "divider"),
        ("Giao dịch bảo mật qua VCB Digibank", "footer"),
    ]
)

# 4. MoMo E-Wallet (E-Wallet / Ví điện tử)
create_receipt_image(
    "04_momo_vi_dien_tu.png",
    [
        ("Ví MoMo", "title"),
        ("THANH TOÁN THÀNH CÔNG", "title"),
        ("Đến: Trà sữa Phúc Long Đà Nẵng", "subtitle"),
        ("", "divider"),
        ("SỐ TIỀN||55.000 đ", "highlight"),
        ("Thời gian: 14/10/2026  20:15:00", "subtitle"),
        ("", "divider"),
        ("Dịch vụ||Thanh toán quét mã QR", "body_row"),
        ("Nguồn tiền||Ví MoMo", "body_row"),
        ("Mã giao dịch||MM20261014881", "body_row"),
        ("", "divider"),
        ("Cảm ơn bạn đã sử dụng MoMo", "footer"),
    ]
)

# 5. EVN Electricity Bill (Bills / Tiền điện)
create_receipt_image(
    "05_evn_hoa_don_dien.png",
    [
        ("TỔNG CÔNG TY ĐIỆN LỰC MIỀN TRUNG", "title"),
        ("GIẤY BÁO TIỀN ĐIỆN EVN", "bold_row"),
        ("Đ/C: 393 Trưng Nữ Vương, Q. Hải Châu, TP. Đà Nẵng", "subtitle"),
        ("Kỳ hóa đơn: Tháng 10/2026", "subtitle"),
        ("Ngày: 05/10/2026", "subtitle"),
        ("", "divider"),
        ("Khách hàng||TRẦN VĂN HOÀNG", "body_row"),
        ("Mã khách hàng||PE0100088992", "body_row"),
        ("Chỉ số mới: 1450 - Chỉ số cũ: 1280", "subtitle"),
        ("Điện năng tiêu thụ: 170 kWh", "subtitle"),
        ("", "divider"),
        ("TỔNG CỘNG TIỀN ĐIỆN||385.000 VND", "highlight"),
        ("", "divider"),
        ("Tổng đài CSKH: 1900 1909", "footer"),
    ]
)

# 6. Petrolimex Gas (Travel / Đổ xăng)
create_receipt_image(
    "06_petrolimex_xang_xe.png",
    [
        ("TẬP ĐOÀN XĂNG DẦU VIỆT NAM", "title"),
        ("CỬA HÀNG XĂNG DẦU PETROLIMEX SỐ 12", "bold_row"),
        ("Đ/C: 120 Điện Biên Phủ, Thanh Khê, Đà Nẵng", "subtitle"),
        ("Ngày: 16/10/2026  17:45:00", "subtitle"),
        ("", "divider"),
        ("Mặt hàng||Xăng RON 95-III", "body_row"),
        ("Đơn giá||23.500 đ/lít", "body_row"),
        ("Số lượng||2.98 lít", "body_row"),
        ("", "divider"),
        ("TỔNG CỘNG||70.000 đ", "highlight"),
        ("Hình thức thanh toán||Tiền mặt", "body_row"),
        ("", "divider"),
        ("Chúc quý khách thượng lộ bình an!", "footer"),
    ]
)

# 7. Fahasa Books (Study / Sách vở giáo trình)
create_receipt_image(
    "07_fahasa_hoc_tap.png",
    [
        ("NHÀ SÁCH FAHASA ĐÀ NẴNG", "title"),
        ("Đ/C: 300 Lê Duẩn, Q. Thanh Khê, TP. Đà Nẵng", "subtitle"),
        ("Số HĐ: FH-778219", "subtitle"),
        ("Ngày: 11/10/2026  10:20:00", "subtitle"),
        ("", "divider"),
        ("1 Giáo trình Lập trình Di động||85.000 đ", "body_row"),
        ("2 Sổ tay sinh viên VKU||50.000 đ", "body_row"),
        ("", "divider"),
        ("Tổng tiền hàng||135.000 đ", "body_row"),
        ("TỔNG TIỀN THANH TOÁN||135.000 đ", "highlight"),
        ("Phương thức||Thẻ ATM Napas", "body_row"),
        ("", "divider"),
        ("Fahasa xin cảm ơn quý khách!", "footer"),
    ]
)

# 8. Cơm Tấm Sài Gòn (Food & Drinks / Quán cơm trưa)
create_receipt_image(
    "08_com_tam_sai_gon.png",
    [
        ("QUÁN CƠM TẤM SÀI GÒN", "title"),
        ("Đ/C: 45 Ngũ Hành Sơn, Q. Ngũ Hành Sơn, TP. Đà Nẵng", "subtitle"),
        ("Số phiếu: 088 - Bàn 02", "subtitle"),
        ("Ngày: 18/10/2026  11:45:00", "subtitle"),
        ("", "divider"),
        ("1 Cơm sườn bì chả đặc biệt||45.000 đ", "body_row"),
        ("1 Canh rong biển thịt bằm||10.000 đ", "body_row"),
        ("1 Trà đá hoa cúc||5.000 đ", "body_row"),
        ("", "divider"),
        ("TỔNG CỘNG||60.000 đ", "highlight"),
        ("Tiền mặt||100.000 đ", "body_row"),
        ("Tiền thối lại||40.000 đ", "body_row"),
        ("", "divider"),
        ("Cơm tấm ngon - Kính chúc quý khách ngon miệng!", "footer"),
    ]
)

# 9. MB Bank Transfer (Bank Transfer / MB Bank Tiền học phí)
create_receipt_image(
    "09_mbbank_chuyen_tien.png",
    [
        ("MB BANK", "title"),
        ("GIAO DỊCH THÀNH CÔNG", "title"),
        ("Chuyển khoản thành công Napas 247", "subtitle"),
        ("", "divider"),
        ("SỐ TIỀN||2.500.000 VND", "highlight"),
        ("Ngày: 20/10/2026  15:10:25", "subtitle"),
        ("", "divider"),
        ("Người nhận||TRƯỜNG ĐẠI HỌC CNTT & TT VIỆT - HÀN", "bold_row"),
        ("Ngân hàng thụ hưởng||MB Bank (MB)", "body_row"),
        ("Số tài khoản||098877665544", "body_row"),
        ("Nội dung||Nộp học phí kỳ 1 năm học 2026-2027", "body_row"),
        ("Mã giao dịch||FT26293881920", "body_row"),
        ("", "divider"),
        ("Giao dịch trên App MB Bank", "footer"),
    ]
)

# 10. Nhà thuốc FPT Long Châu (Health / Y tế thuốc men)
create_receipt_image(
    "10_nha_thuoc_long_chau.png",
    [
        ("NHÀ THUỐC FPT LONG CHÂU", "title"),
        ("Đ/C: 80 Nam Kỳ Khởi Nghĩa, Q. Ngũ Hành Sơn, TP. Đà Nẵng", "subtitle"),
        ("Số HĐ: LC-2026-88190", "subtitle"),
        ("Ngày: 19/10/2026  16:30:00", "subtitle"),
        ("", "divider"),
        ("1 Panadol Extra đỏ hộp 15 vỉ||85.000 đ", "body_row"),
        ("1 Chai nước muối súc miệng 500ml||15.000 đ", "body_row"),
        ("1 Hộp khẩu trang y tế 4 lớp||35.000 đ", "body_row"),
        ("", "divider"),
        ("Tiền hàng||135.000 đ", "body_row"),
        ("TỔNG TIỀN THANH TOÁN||135.000 đ", "highlight"),
        ("Hình thức||Chuyển khoản VietQR", "body_row"),
        ("", "divider"),
        ("Dược sĩ tư vấn: DS. Nguyễn Lan", "footer"),
        ("Long Châu chúc quý khách mau khỏe!", "footer"),
    ]
)

print("Created 10 HD Realistic Vietnamese Receipts successfully!")
