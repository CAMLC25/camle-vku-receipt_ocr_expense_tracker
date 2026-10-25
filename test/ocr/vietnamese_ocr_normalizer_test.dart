import 'package:flutter_test/flutter_test.dart';
import 'package:vku_receipt_ocr_expense_tracker/core/utils/vietnamese_ocr_normalizer.dart';

void main() {
  group('VietnameseOcrNormalizer Unit Tests (VietOCR & PaddleOCR inspired)', () {
    test('1. removeDiacritics converts Vietnamese accented text to clean ASCII', () {
      expect(
        VietnameseOcrNormalizer.removeDiacritics('TỔNG TIỀN THANH TOÁN: 150.000 đ'),
        'TONG TIEN THANH TOAN: 150.000 d',
      );
      expect(
        VietnameseOcrNormalizer.removeDiacritics('Hóa đơn bán lẻ - Phở Thìn'),
        'Hoa don ban le - Pho Thin',
      );
      expect(
        VietnameseOcrNormalizer.removeDiacritics('Đặng Văn Lâm & Bùi Tiến Dũng'),
        'Dang Van Lam & Bui Tien Dung',
      );
    });

    test('2. normalizeOcrLine fixes spaces around dots and commas', () {
      expect(
        VietnameseOcrNormalizer.normalizeOcrLine('TONG CONG: 89 .000 VND'),
        'TONG CONG: 89.000 VND',
      );
      expect(
        VietnameseOcrNormalizer.normalizeOcrLine('Thành tiền: 120 ,000 đ'),
        'Thành tiền: 120.000 đ',
      );
    });

    test('3. normalizeOcrLine fixes "O" and "o" misread as "0" in amounts', () {
      expect(
        VietnameseOcrNormalizer.normalizeOcrLine('1OO.OOO'),
        '100.000',
      );
      expect(
        VietnameseOcrNormalizer.normalizeOcrLine('Tong: 25O.OOO d'),
        'Tong: 250.000 đ',
      );
    });

    test('4. normalizeOcrLine standardizes lowercase or uppercase "d" as currency marker', () {
      expect(
        VietnameseOcrNormalizer.normalizeOcrLine('TONG CONG: 89.000 d'),
        'TONG CONG: 89.000 đ',
      );
      expect(
        VietnameseOcrNormalizer.normalizeOcrLine('TONG CONG: 89.000D'),
        'TONG CONG: 89.000 đ',
      );
    });

    test('5. isFinalTotalLabel accurately identifies total lines with or without accents', () {
      expect(VietnameseOcrNormalizer.isFinalTotalLabel('TỔNG CỘNG: 105.000 đ'), isTrue);
      expect(VietnameseOcrNormalizer.isFinalTotalLabel('TONG CONG: 89.000'), isTrue);
      expect(VietnameseOcrNormalizer.isFinalTotalLabel('THÀNH TIỀN: 108.000 VND'), isTrue);
      expect(VietnameseOcrNormalizer.isFinalTotalLabel('THANH TIEN: 50.000'), isTrue);
      expect(VietnameseOcrNormalizer.isFinalTotalLabel('Tổng tiền thanh toán: 247.500'), isTrue);
      expect(VietnameseOcrNormalizer.isFinalTotalLabel('GRAND TOTAL'), isTrue);
      expect(VietnameseOcrNormalizer.isFinalTotalLabel('1 Freeze Tra Xanh L'), isFalse);
    });

    test('6. isSubtotalOrDiscount accurately identifies subtotals and discounts', () {
      expect(VietnameseOcrNormalizer.isSubtotalOrDiscount('Tiền hàng: 120.000'), isTrue);
      expect(VietnameseOcrNormalizer.isSubtotalOrDiscount('Tien hang: 89.000'), isTrue);
      expect(VietnameseOcrNormalizer.isSubtotalOrDiscount('Giảm giá: -20.000'), isTrue);
      expect(VietnameseOcrNormalizer.isSubtotalOrDiscount('Chiet khau: 10%'), isTrue);
      expect(VietnameseOcrNormalizer.isSubtotalOrDiscount('VAT 8%: 8.000'), isTrue);
      expect(VietnameseOcrNormalizer.isSubtotalOrDiscount('TỔNG CỘNG: 100.000'), isFalse);
    });

    test('7. isCashOrChange accurately identifies cash tendered and returned change', () {
      expect(VietnameseOcrNormalizer.isCashOrChange('Tiền khách đưa: 100.000 đ'), isTrue);
      expect(VietnameseOcrNormalizer.isCashOrChange('Tien khach dua: 200.000'), isTrue);
      expect(VietnameseOcrNormalizer.isCashOrChange('Tiền thối lại: 11.000 đ'), isTrue);
      expect(VietnameseOcrNormalizer.isCashOrChange('Tien thua: 15.000'), isTrue);
      expect(VietnameseOcrNormalizer.isCashOrChange('Change: 50.000'), isTrue);
      expect(VietnameseOcrNormalizer.isCashOrChange('TỔNG CỘNG: 100.000'), isFalse);
    });
  });
}
