import 'package:flutter_test/flutter_test.dart';
import 'package:vku_receipt_ocr_expense_tracker/data/models/parsed_receipt.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/ocr/models/recognized_text_result.dart';
import 'package:vku_receipt_ocr_expense_tracker/features/ocr/services/receipt_parser.dart';

void main() {
  group('ReceiptParser Comprehensive Test Suite (15 Test Cases)', () {
    // 1. Vietnamese restaurant receipt
    test('1. Vietnamese restaurant receipt extracts merchant, amount, date and category', () {
      const rawText = '''
PHỞ THÌN HÀ NỘI
13 Lò Đúc, Hai Bà Trưng, Hà Nội
Ngày: 12/10/2026 08:30
1 Phở đặc biệt       90.000
1 Quẩy               10.000
1 Trà đá              5.000
TỔNG CỘNG:          105.000 đ
Cảm ơn quý khách!
''';
      final ocr = RecognizedTextResult(
        rawText: rawText,
        lines: rawText
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList(),
        blocks: const [],
        imagePath: '/test/phothin.jpg',
      );

      final parsed = ReceiptParser.parse(ocr);
      expect(parsed.merchantCandidate, 'PHỞ THÌN HÀ NỘI');
      expect(parsed.amountCandidate, 105000);
      expect(parsed.dateCandidate, '2026-10-12');
      expect(parsed.categoryCandidate, 'Food & Drinks');
      expect(parsed.transactionTypeCandidate, 'expense');
    });

    // 2. Supermarket receipt with subtotal, discount, and final total
    test(
      '2. Supermarket receipt prefers final total over subtotal and discount',
      () {
        const rawText = '''
WINMART+ ĐÀ NẴNG
HÓA ĐƠN BÁN LẺ
Ngày: 15/09/2026
Tiền hàng: 120.000
Giảm giá khuyến mãi: -20.000
VAT (8%): 8.000
THÀNH TIỀN: 108.000 VND
''';
        final ocr = RecognizedTextResult(
          rawText: rawText,
          lines: rawText
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .toList(),
          blocks: const [],
          imagePath: '/test/winmart.jpg',
        );

        final parsed = ReceiptParser.parse(ocr);
        expect(parsed.merchantCandidate, 'WINMART+ ĐÀ NẴNG');
        expect(parsed.amountCandidate, 108000);
        expect(parsed.dateCandidate, '2026-09-15');
        expect(parsed.categoryCandidate, 'Shopping');
      },
    );

    // 3. Receipt containing several monetary values (cash given, change, total)
    test(
      '3. Distinguishes final total from cash tendered and change returned',
      () {
        const rawText = '''
HIGHLANDS COFFEE
TỔNG THANH TOÁN: 89.000 đ
Tiền khách đưa: 100.000 đ
Tiền thối lại: 11.000 đ
Ngày GD: 01/10/2026
''';
        final ocr = RecognizedTextResult(
          rawText: rawText,
          lines: rawText
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .toList(),
          blocks: const [],
          imagePath: '/test/highlands.jpg',
        );

        final parsed = ReceiptParser.parse(ocr);
        expect(parsed.amountCandidate, 89000);
        expect(parsed.categoryCandidate, 'Food & Drinks');
      },
    );

    // 4. Successful bank transfer screenshot
    test('4. Successful bank transfer screenshot recognizes transfer category and recipient', () {
      const rawText = '''
Giao dịch thành công
Người nhận: NGUYEN VAN ANH
Số tài khoản: 1029384756
Số tiền giao dịch: 350.000 VND
Nội dung: Tien phong tro thang 10
Mã giao dịch: VCB202610129876
Ngày: 12/10/2026 14:22:10
''';
      final ocr = RecognizedTextResult(
        rawText: rawText,
        lines: rawText
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList(),
        blocks: const [],
        imagePath: '/test/vcb.jpg',
      );

      final parsed = ReceiptParser.parse(ocr);
      expect(parsed.amountCandidate, 350000);
      expect(parsed.merchantCandidate, contains('NGUYEN VAN ANH'));
      expect(parsed.referenceCandidate, 'VCB202610129876');
      expect(parsed.paymentMethodCandidate, 'Bank Transfer');
      expect(parsed.dateCandidate, '2026-10-12');
    });

    // 5. Bank transfer with sender and recipient information
    test('5. Bank transfer correctly selects recipient over sender', () {
      const rawText = '''
Chuyển tiền thành công
Người chuyển: LE THI B
Người nhận: TRAN VAN C
Số tiền: 500.000 VND
Ngày thực hiện: 05/10/2026
''';
      final ocr = RecognizedTextResult(
        rawText: rawText,
        lines: rawText
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList(),
        blocks: const [],
        imagePath: '/test/transfer.jpg',
      );

      final parsed = ReceiptParser.parse(ocr);
      expect(parsed.merchantCandidate, contains('TRAN VAN C'));
      expect(parsed.amountCandidate, 500000);
      expect(parsed.dateCandidate, '2026-10-05');
    });

    // 6. Transaction screenshot with no clearly labeled amount
    test('6. Screenshot without labeled amount generates warning for user verification', () {
      const rawText = '''
Xác nhận chuyển khoản
Người nhận: Dịch vụ công
250000
Cảm ơn quý khách
''';
      final ocr = RecognizedTextResult(
        rawText: rawText,
        lines: rawText
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList(),
        blocks: const [],
        imagePath: '/test/unlabeled.jpg',
      );

      final parsed = ReceiptParser.parse(ocr);
      expect(parsed.amountCandidate, 250000);
      expect(parsed.hasWarnings, isTrue);
      expect(
        parsed.warnings.any(
          (w) => w.contains('xác minh') || w.contains('không có nhãn'),
        ),
        isTrue,
      );
    });

    // 7. Vietnamese date formats
    test('7. Recognizes dd/MM/yyyy and dd-MM-yyyy formats', () {
      const raw1 = 'Cửa hàng tiện lợi\nNgày: 25/12/2026\nTổng cộng: 50.000 đ';
      final parsed1 = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw1,
          lines: raw1.split('\n'),
          blocks: const [],
          imagePath: '/t1.jpg',
        ),
      );
      expect(parsed1.dateCandidate, '2026-12-25');

      const raw2 =
          'Cửa hàng tiện lợi\nNgày giao dịch: 04-07-2026\nTổng cộng: 50.000 đ';
      final parsed2 = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw2,
          lines: raw2.split('\n'),
          blocks: const [],
          imagePath: '/t2.jpg',
        ),
      );
      expect(parsed2.dateCandidate, '2026-07-04');
    });

    // 8. English date formats
    test('8. Recognizes yyyy-MM-dd format', () {
      const raw = 'COFFEE HOUSE\nDate: 2026-06-18\nTOTAL: 45.000';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n'),
          blocks: const [],
          imagePath: '/t.jpg',
        ),
      );
      expect(parsed.dateCandidate, '2026-06-18');
    });

    // 9. Invalid date handling
    test('9. Rejects invalid date value and alerts user via warning', () {
      const raw = 'QUÁN CƠM BÌNH DÂN\nNgày: 32/13/2026\nTổng cộng: 35.000 đ';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n'),
          blocks: const [],
          imagePath: '/invalid_date.jpg',
        ),
      );
      expect(parsed.dateCandidate, isNull);
      expect(parsed.warnings.any((w) => w.contains('ngày giao dịch')), isTrue);
    });

    // 10. Missing merchant name
    test('10. Handles missing merchant and warns user', () {
      const raw = 'HÓA ĐƠN BÁN LẺ\nTổng cộng: 75.000 đ\nNgày: 10/10/2026';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n'),
          blocks: const [],
          imagePath: '/no_merchant.jpg',
        ),
      );
      expect(parsed.warnings.any((w) => w.contains('đơn vị')), isTrue);
    });

    // 11. OCR text with unusual spacing
    test('11. Handles spaced digits or unaccented total labels', () {
      const raw = 'Highlands Coffee\nTong cong: 65.000 d\nNgay: 02/10/2026';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n'),
          blocks: const [],
          imagePath: '/spaced.jpg',
        ),
      );
      expect(parsed.amountCandidate, 65000);
      expect(parsed.dateCandidate, '2026-10-02');
    });

    // 12. Vietnamese thousands separators
    test('12. Accurately normalizes Vietnamese period-separated amount', () {
      const raw = 'Cửa hàng điện máy\nTổng cộng: 1.250.000 đ\nNgày: 01/01/2026';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n'),
          blocks: const [],
          imagePath: '/vn_amount.jpg',
        ),
      );
      expect(parsed.amountCandidate, 1250000);
    });

    // 13. English decimal and thousands separators
    test(
      '13. Accurately normalizes English amounts with comma or decimal point',
      () {
        const raw1 = 'BOOKSTORE\nTOTAL 125.00\nDate: 2026-05-10';
        final parsed1 = ReceiptParser.parse(
          RecognizedTextResult(
            rawText: raw1,
            lines: raw1.split('\n'),
            blocks: const [],
            imagePath: '/en1.jpg',
          ),
        );
        expect(parsed1.amountCandidate, 125);

        const raw2 = 'ELECTRONICS\nAMOUNT: 1,500,000 VND\nDate: 2026-05-10';
        final parsed2 = ReceiptParser.parse(
          RecognizedTextResult(
            rawText: raw2,
            lines: raw2.split('\n'),
            blocks: const [],
            imagePath: '/en2.jpg',
          ),
        );
        expect(parsed2.amountCandidate, 1500000);
      },
    );

    // 14. Expense versus income classification
    test('14. Correctly classifies scholarship or salary as income', () {
      const raw =
          'Ngân hàng thông báo\nBạn vừa nhận tiền học bổng\nSố tiền: 2.000.000 VND\nNgày: 10/10/2026';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n'),
          blocks: const [],
          imagePath: '/income.jpg',
        ),
      );
      expect(parsed.transactionTypeCandidate, 'income');
      expect(parsed.amountCandidate, 2000000);
    });

    // 15. Category keyword classification
    test('15. Accurately maps keywords to appropriate spending categories', () {
      final tests = [
        ('Trà sữa Gong Cha\nTổng cộng: 55.000 đ', 'Food & Drinks'),
        ('Nhà sách Fahasa Đà Nẵng\nTổng cộng: 85.000 đ', 'Study'),
        ('Cây xăng Petrolimex\nTổng cộng: 70.000 đ', 'Travel'),
        ('Siêu thị Co.opmart\nTổng cộng: 210.000 đ', 'Shopping'),
        ('CGV Cinema Vincom\nTổng cộng: 150.000 đ', 'Entertainment'),
        ('Hóa đơn tiền điện EVN\nTổng cộng: 320.000 đ', 'Bills & Utilities'),
        ('Nhà thuốc Long Châu\nTổng cộng: 45.000 đ', 'Healthcare'),
      ];

      for (final t in tests) {
        final parsed = ReceiptParser.parse(
          RecognizedTextResult(
            rawText: t.$1,
            lines: t.$1.split('\n'),
            blocks: const [],
            imagePath: '/test.jpg',
          ),
        );
        expect(parsed.categoryCandidate, t.$2, reason: 'Failed for ${t.$1}');
      }
    });

    // 16. Document Type: Paper receipt detection
    test('16. Auto-detects paper receipt document type', () {
      const raw = '''
HÓA ĐƠN BÁN LẺ
Cửa hàng tiện lợi Circle K
Thu ngân: NV01
1 Nước khoáng Lavie   10.000
1 Snack Khoai tây     20.000
TỔNG CỘNG:            30.000 đ
Tiền mặt:             50.000 đ
Tiền thối:            20.000 đ
Cảm ơn quý khách!
''';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n'),
          blocks: const [],
          imagePath: '/receipt.jpg',
        ),
      );
      expect(parsed.detectedDocumentType, DetectedDocumentType.receipt);
      expect(parsed.documentTypeLabelVi, 'Hóa đơn mua hàng');
      expect(parsed.documentTypeConfidence, greaterThan(0.5));
    });

    // 17. Document Type: Bank transfer screenshot detection
    test('17. Auto-detects bank transfer screenshot', () {
      const raw = '''
Vietcombank
GIAO DỊCH THÀNH CÔNG
Chuyển khoản thành công
Số tiền: 250.000 VND
Người nhận: NGUYEN VAN A
Tài khoản thụ hưởng: 0123456789
Mã giao dịch: VCB1234567890
''';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n'),
          blocks: const [],
          imagePath: '/vcb.jpg',
        ),
      );
      expect(parsed.detectedDocumentType, DetectedDocumentType.bankTransfer);
      expect(parsed.documentTypeLabelVi, 'Chuyển khoản ngân hàng');
      expect(parsed.documentTypeConfidence, greaterThan(0.6));
    });

    // 18. Document Type: E-Wallet screenshot detection
    test('18. Auto-detects e-wallet screenshot (MoMo / ZaloPay)', () {
      const raw = '''
MoMo
Thanh toán thành công
Đến: Highlands Coffee
Số tiền: 65.000 đ
Mã giao dịch: 987654321
Ví MoMo liên kết
''';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n'),
          blocks: const [],
          imagePath: '/momo.jpg',
        ),
      );
      expect(parsed.detectedDocumentType, DetectedDocumentType.eWallet);
      expect(parsed.documentTypeLabelVi, 'Ví điện tử');
      expect(parsed.documentTypeConfidence, greaterThan(0.5));
    });

    // 19. Document Type: Utility bill detection
    test('19. Auto-detects utility bill document type (EVN)', () {
      const raw = '''
TỔNG CÔNG TY ĐIỆN LỰC MIỀN TRUNG
GIẤY BÁO TIỀN ĐIỆN EVN
Kỳ hóa đơn: Tháng 10/2026
Mã khách hàng: PE01000123456
Chỉ số mới: 1250 - Chỉ số cũ: 1100
Tổng cộng tiền điện thanh toán: 450.000 VND
''';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n'),
          blocks: const [],
          imagePath: '/evn.jpg',
        ),
      );
      expect(parsed.detectedDocumentType, DetectedDocumentType.utilityBill);
      expect(parsed.documentTypeLabelVi, 'Hóa đơn dịch vụ');
      expect(parsed.categoryCandidate, 'Bills & Utilities');
    });

    // 20. Document Type: Unknown fallback
    test('20. Returns unknown for documents with ambiguous content', () {
      const raw = 'Xin chào thế giới. Chúc một ngày tốt lành!';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n'),
          blocks: const [],
          imagePath: '/random.jpg',
        ),
      );
      expect(parsed.detectedDocumentType, DetectedDocumentType.unknown);
      expect(parsed.documentTypeLabelVi, 'Chưa xác định');
    });

    // 21. Real user MB Bank transfer screenshot
    test('21. Real user MB Bank transfer screenshot', () {
      const raw = '''
Chuyển tiền thành công
500,000 VND
21:07 - 14/11/2025
NGUYEN TRONG THI
Chia sẻ
Vietinbank (CTG)
107005518938
ban TUYEN chuc mung hanh phuc
Cảm ơn bạn đã sử dụng dịch vụ của MBBank
MB
Lưu ảnh
Lưu mẫu
''';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList(),
          blocks: const [],
          imagePath: '/mbbank.jpg',
        ),
      );
      expect(parsed.detectedDocumentType, DetectedDocumentType.bankTransfer);
      expect(parsed.documentTypeLabelVi, 'Chuyển khoản ngân hàng');
      expect(parsed.amountCandidate, 500000);
      expect(parsed.merchantCandidate, 'NGUYEN TRONG THI');
      expect(parsed.dateCandidate, '2025-11-14');
      expect(parsed.timeCandidate, '21:07');
      expect(parsed.categoryCandidate, 'Transfer');
      expect(parsed.paymentMethodCandidate, 'Bank Transfer');
      expect(parsed.warnings, isEmpty);
    });

    // 22. Sales invoice with phone number, discount, and multi-line code
    test('22. Sales invoice ignores phone number and extracts correct total and invoice code', () {
      const raw = '''
Ngày: 08/06/2018
Số hóa đơn:
CNHP0000029
HÓA ĐƠN BÁN HÀNG
Thu ngân: Giáp Nguyên Nhựt
Khách hàng: BDF
ĐC: aaaaaaaaaaaaaaaaaaaaa
ĐT: 0962122573
Tên hàng
1111111111111
1111111111
5
5
90.000,00
450.000
Tổng tiền hàng:
Tổng tiền chiết khấu:
Tổng tiền thanh toán
247.500
202.500
247.500
''';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList(),
          blocks: const [],
          imagePath: '/hoadon.jpg',
        ),
      );
      expect(parsed.detectedDocumentType, DetectedDocumentType.receipt);
      expect(parsed.amountCandidate, 247500); // Must NOT be 962122573
      expect(parsed.dateCandidate, '2018-06-08');
      expect(parsed.referenceCandidate, 'CNHP0000029');
      expect(parsed.merchantCandidate, isNot('CNHP0000029'));
      expect(parsed.merchantCandidate, isNot(contains('0962122573')));
    });

    // 23. Highlands Coffee receipt extracts total 89.000 instead of first item 65.000
    test('23. Highlands Coffee receipt extracts total 89.000 instead of first item 65.000', () {
      const raw = '''
HIGHLANDS COFFEE
Chi nhanh Da Nang - 15 Le Duan
So HD: HD882912 - Ban 04
Ngay: 15/10/2026 14:30
1 Freeze Tra Xanh L    65.000
1 Banh Mi Que Ga       24.000
Tien hang: 89.000
TONG CONG: 89.000 VND
Tien khach dua: 100.000 VND
Tien thoi lai: 11.000 VND
Cam on quy khach - Hen gap lai!
''';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList(),
          blocks: const [],
          imagePath: '/highlands.jpg',
        ),
      );
      expect(parsed.detectedDocumentType, DetectedDocumentType.receipt);
      expect(parsed.merchantCandidate, 'HIGHLANDS COFFEE');
      expect(parsed.amountCandidate, 89000); // Must be 89.000, NOT 65.000
      expect(parsed.dateCandidate, '2026-10-15');
      expect(parsed.categoryCandidate, 'Food & Drinks');
      expect(parsed.warnings, isEmpty);
    });

    // 24. Highlands Coffee fallback without explicit label still selects bottom total 89.000 over item 65.000
    test('24. Highlands Coffee fallback selects bottom total 89.000 over first item 65.000', () {
      const raw = '''
HIGHLANDS COFFEE
Ngay: 15/10/2026
1 Freeze Tra Xanh L    65.000 VND
1 Banh Mi Que Ga       24.000 VND
89.000 VND
''';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList(),
          blocks: const [],
          imagePath: '/highlands_fallback.jpg',
        ),
      );
      expect(parsed.detectedDocumentType, DetectedDocumentType.unknown);
      expect(parsed.amountCandidate, 89000); // Must be 89.000, NOT 65.000
    });

    // 25. MC-OCR Benchmark: Extracts 4 Core Entities (Seller, Address, Timestamp, Total Cost)
    test('25. MC-OCR Benchmark extracts Seller, Address, Timestamp, and Total Cost', () {
      const raw = '''
PHỞ 24
Đ/C: 15 Lê Duẩn, P. Hải Châu 1, Q. Hải Châu, TP. Đà Nẵng
ĐT: 0236 3822 822
Ngày: 18/10/2026 12:30:00
1 Phở Tái Bò       55.000
1 Trà Đá           5.000
TỔNG CỘNG          60.000 đ
TIỀN MẶT           100.000 đ
TIỀN THỐI          40.000 đ
''';
      final parsed = ReceiptParser.parse(
        RecognizedTextResult(
          rawText: raw,
          lines: raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList(),
          blocks: const [],
          imagePath: '/pho24.jpg',
        ),
      );
      expect(parsed.merchantCandidate, 'PHỞ 24');
      expect(parsed.sellerAddressCandidate, '15 Lê Duẩn, P. Hải Châu 1, Q. Hải Châu, TP. Đà Nẵng');
      expect(parsed.dateCandidate, '2026-10-18');
      expect(parsed.timeCandidate, '12:30:00');
      expect(parsed.amountCandidate, 60000); // Excludes cash given (100k) & change (40k)
      expect(parsed.categoryCandidate, 'Food & Drinks');
    });
  });
}

