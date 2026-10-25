import '../../../core/constants/app_constants.dart';
import '../../../core/constants/regex_patterns.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/vietnamese_ocr_normalizer.dart';
import '../../../data/models/parsed_receipt.dart';
import '../models/recognized_text_result.dart';

/// Heuristic-based parsing engine for extracting structured expense fields from OCR text.
class ReceiptParser {
  ReceiptParser._();

  /// Analyzes the OCR result and returns candidate fields, confidence score, and warnings.
  static ParsedReceipt parse(RecognizedTextResult ocrResult) {
    final rawText = ocrResult.rawText;
    final lines = ocrResult.lines
        .map(VietnameseOcrNormalizer.normalizeOcrLine)
        .where((l) => l.trim().isNotEmpty)
        .toList();
    final warnings = <String>[];

    if (!ocrResult.hasText || lines.isEmpty) {
      return ParsedReceipt(
        rawText: rawText,
        warnings: const ['Không phát hiện thấy văn bản nào trên ảnh.'],
        confidenceScore: 0.0,
      );
    }

    // 1. Auto-detect Document Type (receipt, bank transfer, e-wallet, etc.)
    final docTypeResult = _classifyDocumentType(rawText);
    final isBankTransfer = docTypeResult.type == DetectedDocumentType.bankTransfer ||
        docTypeResult.type == DetectedDocumentType.eWallet;

    // 2. Extract Amount
    final amountResult = _extractAmount(
      lines,
      rawText,
      isBankTransfer: isBankTransfer,
    );
    final amountCandidate = amountResult.amount;
    if (amountResult.warning != null) {
      warnings.add(amountResult.warning!);
    }

    // 3. Extract Date & Time
    final dateTimeResult = _extractDateTime(lines, rawText);
    final dateCandidate = dateTimeResult.date;
    final timeCandidate = dateTimeResult.time;
    if (dateCandidate == null) {
      warnings.add(
        'Không tìm thấy ngày giao dịch rõ ràng. Vui lòng chọn ngày.',
      );
    }

    // 4. Extract Merchant / Recipient & Address (MC-OCR Task 2 KIE)
    final merchantCandidate = isBankTransfer
        ? _extractTransferRecipient(lines, rawText)
        : _extractMerchantName(lines);
    final sellerAddressCandidate =
        isBankTransfer ? null : _extractSellerAddress(lines);

    if (merchantCandidate == null || merchantCandidate.isEmpty) {
      warnings.add(
        'Không xác định chắc chắn tên đơn vị. Vui lòng kiểm tra lại.',
      );
    }

    // 5. Extract Reference / Transaction Code
    final referenceCandidate = _extractReference(rawText, lines);

    // 6. Transaction Type (Expense vs Income)
    final transactionType = _classifyTransactionType(rawText, isBankTransfer);

    // 7. Category Suggestion
    final categoryCandidate = _suggestCategory(
      merchant: merchantCandidate,
      rawText: rawText,
      isBankTransfer: isBankTransfer,
    );

    // 8. Payment Method
    final paymentMethodCandidate = _detectPaymentMethod(
      rawText,
      isBankTransfer,
    );

    // 9. Calculate Confidence Score
    double confidence = 0.2;
    if (amountCandidate != null && amountCandidate > 0) {
      confidence += 0.35;
    }
    if (dateCandidate != null) {
      confidence += 0.2;
    }
    if (merchantCandidate != null && merchantCandidate.isNotEmpty) {
      confidence += 0.15;
    }
    if (amountResult.confidenceBonus) {
      confidence += 0.1;
    }
    if (confidence > 1.0) {
      confidence = 1.0;
    }

    return ParsedReceipt(
      merchantCandidate: merchantCandidate,
      sellerAddressCandidate: sellerAddressCandidate,
      amountCandidate: amountCandidate,
      dateCandidate: dateCandidate,
      timeCandidate: timeCandidate,
      transactionTypeCandidate: transactionType,
      categoryCandidate: categoryCandidate,
      paymentMethodCandidate: paymentMethodCandidate,
      referenceCandidate: referenceCandidate,
      rawText: rawText,
      warnings: warnings,
      confidenceScore: confidence,
      detectedDocumentType: docTypeResult.type,
      documentTypeConfidence: docTypeResult.confidence,
    );
  }

  // ===========================================================================
  // Amount Extraction
  // ===========================================================================

  static _AmountParseResult _extractAmount(
    List<String> lines,
    String rawText, {
    bool isBankTransfer = false,
  }) {
    int? bestAmount;
    bool hasTotalLabel = false;
    final List<int> candidates = [];
    final List<int> candidatesWithCurrency = [];

    // Tier 1: Explicit final total labels (Highest Priority for retail / restaurant receipts)
    final tier1TotalPattern = RegExp(
      r'(t[oổô]ng\s*ti[eề]n\s*thanh\s*to[aá]n|t[oổô]ng\s*thanh\s*to[aá]n|t[oổô]ng\s*c[oộô]ng|th[aà]nh\s*ti[eề]n|grand\s*total|\btotal\b)',
      caseSensitive: false,
    );

    // Tier 2: Generic total or bank transfer labels
    final tier2TotalPattern = RegExp(
      r'(t[oổô]ng\s*ti[eề]n|s[oốô]\s*ti[eề]n\s*thanh\s*to[aá]n|s[oốô]\s*ti[eề]n\s*giao\s*d[iị]ch|ti[eề]n\s*thanh\s*to[aá]n|s[oốô]\s*ti[eề]n|amount)',
      caseSensitive: false,
    );

    // Pass 1A: Check for Tier 1 final total labels
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isFinalTotal = tier1TotalPattern.hasMatch(line) ||
          VietnameseOcrNormalizer.isFinalTotalLabel(line);
      if (isFinalTotal && !_isExcludedAmountLine(line)) {
        final amountOnSameLine = _extractAmountFromLine(line);
        if (amountOnSameLine != null && amountOnSameLine > 0) {
          bestAmount = amountOnSameLine;
          hasTotalLabel = true;
          break;
        }
        for (int step = 1; step <= 3 && (i + step) < lines.length; step++) {
          final nextLine = lines[i + step];
          if (!_isExcludedAmountLine(nextLine)) {
            final amountOnNextLine = _extractAmountFromLine(nextLine);
            if (amountOnNextLine != null && amountOnNextLine > 0) {
              bestAmount = amountOnNextLine;
              hasTotalLabel = true;
              break;
            }
          }
        }
        if (bestAmount != null) break;
      }
    }

    // Pass 1B: If no Tier 1 found, check for Tier 2 or bank transfer success headers
    if (bestAmount == null) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final isTier2 = tier2TotalPattern.hasMatch(line);
        final isBankSuccess =
            isBankTransfer && RegexPatterns.bankTransferPattern.hasMatch(line);

        if ((isTier2 || isBankSuccess) && !_isExcludedAmountLine(line)) {
          final amountOnSameLine = _extractAmountFromLine(line);
          if (amountOnSameLine != null && amountOnSameLine > 0) {
            bestAmount = amountOnSameLine;
            hasTotalLabel = true;
            break;
          }
          for (int step = 1; step <= 3 && (i + step) < lines.length; step++) {
            final nextLine = lines[i + step];
            if (!_isExcludedAmountLine(nextLine)) {
              final amountOnNextLine = _extractAmountFromLine(nextLine);
              if (amountOnNextLine != null && amountOnNextLine > 0) {
                bestAmount = amountOnNextLine;
                hasTotalLabel = true;
                break;
              }
            }
          }
          if (bestAmount != null) break;
        }
      }
    }

    // Second pass: if no explicit total label found, collect all valid amounts
    if (bestAmount == null) {
      for (final line in lines) {
        if (_isExcludedAmountLine(line)) continue;
        final val = _extractAmountFromLine(line);
        if (val != null && val > 0) {
          candidates.add(val);
          final lower = line.toLowerCase();
          if (lower.contains('đ') ||
              lower.contains('vnd') ||
              lower.contains('vnđ') ||
              lower.contains('\$') ||
              RegExp(r'\b\d+[\.,]?\d*\s*d\b', caseSensitive: false)
                  .hasMatch(lower)) {
            candidatesWithCurrency.add(val);
          }
        }
      }

      // Prioritize numbers that have explicit currency marks (đ, vnd, d)
      final pool = candidatesWithCurrency.isNotEmpty
          ? candidatesWithCurrency
          : candidates;

      if (pool.isNotEmpty) {
        // Exclude astronomical numbers (> 500 million) and sub-1000 numbers in unlabeled mode
        final sensible =
            pool.where((c) => c >= 1000 && c <= 500000000).toList();
        if (sensible.isNotEmpty) {
          if (isBankTransfer) {
            // For bank transfers: transfer amount is prominently at the top
            bestAmount = sensible.first;
          } else {
            // For retail receipts/invoices/bills:
            // Items are listed first, total is at the bottom.
            bestAmount = sensible.last;
          }
        }
      }
    }

    if (bestAmount == null) {
      return _AmountParseResult(
        amount: null,
        warning:
            'Không nhận diện được số tiền thanh toán. Vui lòng nhập thủ công.',
        confidenceBonus: false,
      );
    }

    if (!hasTotalLabel) {
      return _AmountParseResult(
        amount: bestAmount,
        warning:
            'Số tiền được ước tính từ văn bản nhưng không có nhãn tổng cộng rõ ràng. Vui lòng xác minh lại.',
        confidenceBonus: false,
      );
    }

    return _AmountParseResult(
      amount: bestAmount,
      warning: null,
      confidenceBonus: true,
    );
  }

  static bool _isExcludedAmountLine(String line) {
    // Exclude phone numbers & contact info
    if (RegexPatterns.phonePattern.hasMatch(line) ||
        RegExp(r'(?:đt|đ/t|dt|tel|phone|hotline|sđt)[\s:]', caseSensitive: false)
            .hasMatch(line) ||
        RegExp(r'\+84[\s.-]*\d').hasMatch(line) ||
        line.contains('+84')) {
      return true;
    }

    // Exclude subtotal, discount, cash given, change returned, account number
    if (VietnameseOcrNormalizer.isCashOrChange(line) ||
        RegexPatterns.cashGivenPattern.hasMatch(line) ||
        RegexPatterns.changePattern.hasMatch(line)) {
      return true;
    }
    if (VietnameseOcrNormalizer.isSubtotalOrDiscount(line) ||
        RegexPatterns.discountPattern.hasMatch(line)) {
      return true;
    }
    if (RegExp(
      r'(s[oốô]\s*t[aà]i\s*kho[aả]n|stk|account\s*no|card\s*no)',
      caseSensitive: false,
    ).hasMatch(line)) {
      return true;
    }

    // Exclude lines that are purely dates or times (e.g. "21:07 - 14/11/2025") without currency
    final lower = line.toLowerCase();
    final hasCurrency = lower.contains('đ') ||
        lower.contains('vnd') ||
        lower.contains('vnđ') ||
        lower.contains('\$');
    if (!hasCurrency) {
      if (RegexPatterns.datePattern.hasMatch(line) ||
          RegexPatterns.timePattern.hasMatch(line)) {
        return true;
      }
    }

    return false;
  }

  static int? _extractAmountFromLine(String line) {
    final lower = line.toLowerCase();
    // Exclude phone lines directly
    if (lower.contains('đt:') ||
        lower.contains('đ/t:') ||
        lower.contains('dt:') ||
        lower.contains('tel:') ||
        lower.contains('hotline') ||
        lower.contains('sđt:')) {
      return null;
    }

    // Find all number patterns on the line
    final matches = RegexPatterns.amountNumberPattern.allMatches(line);
    int? candidate;

    for (final match in matches) {
      final rawMatch = match.group(1);
      final parsed = CurrencyFormatter.parseVND(rawMatch);
      if (parsed != null && parsed > 0) {
        // Exclude Vietnamese phone numbers (10 digits starting with 03, 05, 07, 08, 09)
        final digits = rawMatch?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
        if (digits.length == 10 &&
            (digits.startsWith('03') ||
                digits.startsWith('05') ||
                digits.startsWith('07') ||
                digits.startsWith('08') ||
                digits.startsWith('09'))) {
          continue;
        }
        if (digits.length == 9 &&
            (digits.startsWith('3') ||
                digits.startsWith('5') ||
                digits.startsWith('7') ||
                digits.startsWith('8') ||
                digits.startsWith('9')) &&
            (lower.contains('đt') || lower.contains('tel'))) {
          continue;
        }
        candidate = parsed;
      }
    }

    return candidate;
  }

  // ===========================================================================
  // Date & Time Extraction
  // ===========================================================================

  static _DateTimeParseResult _extractDateTime(
    List<String> lines,
    String rawText,
  ) {
    String? foundDate;
    String? foundTime;

    // Search for time
    final timeMatch = RegexPatterns.timePattern.firstMatch(rawText);
    if (timeMatch != null) {
      foundTime = timeMatch.group(0);
    }

    // Search lines for dates
    for (final line in lines) {
      final dateMatch = RegexPatterns.datePattern.firstMatch(line);
      if (dateMatch != null) {
        final rawDateStr = dateMatch.group(0);
        if (rawDateStr != null) {
          final normalized = DateFormatter.normalizeToIsoDate(rawDateStr);
          if (normalized != null) {
            foundDate = normalized;
            break;
          }
        }
      }
    }

    // If still not found, search in rawText
    if (foundDate == null) {
      final allDateMatches = RegexPatterns.datePattern.allMatches(rawText);
      for (final m in allDateMatches) {
        final raw = m.group(0);
        if (raw != null) {
          final normalized = DateFormatter.normalizeToIsoDate(raw);
          if (normalized != null) {
            foundDate = normalized;
            break;
          }
        }
      }
    }

    return _DateTimeParseResult(date: foundDate, time: foundTime);
  }

  // ===========================================================================
  // Merchant / Recipient Extraction
  // ===========================================================================

  static String? _extractMerchantName(List<String> lines) {
    // For standard receipts, merchant name is typically in the first 1-3 lines
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i].trim();

      // Skip lines that are dates, phone numbers, tax codes, or generic headers
      if (line.isEmpty) continue;
      if (_isSkipMerchantLine(line)) continue;

      // Found candidate merchant line
      return line;
    }
    return null;
  }

  /// Extracts the merchant's physical address (Task 2 ADDRESS in MC-OCR benchmark)
  static String? _extractSellerAddress(List<String> lines) {
    for (int i = 0; i < lines.length && i < 10; i++) {
      final line = lines[i].trim();
      final clean = VietnameseOcrNormalizer.removeDiacritics(line).toLowerCase();

      // Explicit address prefixes
      if (clean.startsWith('dc:') ||
          clean.startsWith('d/c:') ||
          clean.startsWith('dia chi:') ||
          clean.startsWith('dia chi') ||
          clean.startsWith('add:') ||
          clean.startsWith('address:')) {
        final colonIdx = line.indexOf(':');
        if (colonIdx != -1 && colonIdx < line.length - 1) {
          final candidate = line.substring(colonIdx + 1).trim();
          if (candidate.isNotEmpty) return candidate;
        }
        return line;
      }

      // Street / District / Ward / City indicators commonly in Vietnamese receipts
      final containsLoc = clean.contains('duong ') ||
          clean.contains('phuong ') ||
          clean.contains('quan ') ||
          clean.contains('tp.') ||
          clean.contains('tp ') ||
          clean.contains('tinh ') ||
          clean.contains('to ');
      if (containsLoc &&
          (clean.contains('so ') || RegExp(r'\d+/\d+|\d+\s+[a-z]+').hasMatch(clean))) {
        return line;
      }
    }
    return null;
  }

  static String? _extractTransferRecipient(List<String> lines, String rawText) {
    // 1. First priority: look for labeled "Người nhận", "Tên người nhận", "Tài khoản thụ hưởng", "Đến", "Tới"
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (RegexPatterns.recipientPattern.hasMatch(line)) {
        // Check if recipient name is on the same line after colon
        final parts = line.split(RegExp(r'[:\-]'));
        if (parts.length > 1 && parts[1].trim().isNotEmpty) {
          final candidate = parts[1].trim();
          if (!_isSkipMerchantLine(candidate) && !_isBankNameOrSystem(candidate)) {
            return candidate;
          }
        }

        // Or on the line immediately following
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (nextLine.isNotEmpty &&
              !_isSkipMerchantLine(nextLine) &&
              !_isBankNameOrSystem(nextLine)) {
            return nextLine;
          }
        }
      }
    }

    // 2. Second priority: Unlabeled Vietnamese recipient name in ALL-CAPS
    // In banking transfers (MB, Vietcombank, Techcombank, etc.), the recipient name
    // is consistently formatted in ALL-CAPS (e.g. "NGUYEN TRONG THI").
    final uppercaseNameRegex = RegExp(
      r'^[A-ZÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ\s]{4,40}$',
    );

    for (final line in lines) {
      final trimmed = line.trim();
      if (_isSkipMerchantLine(trimmed)) continue;
      if (_isBankNameOrSystem(trimmed)) continue;

      if (uppercaseNameRegex.hasMatch(trimmed)) {
        final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (words.length >= 2 && words.length <= 6) {
          return trimmed;
        }
      }
    }

    // 3. Fallback: look for generic merchant name (excluding UI buttons, banks, amounts)
    return _extractMerchantName(lines);
  }

  static bool _isBankNameOrSystem(String line) {
    final lower = line.toLowerCase().trim();
    final systemKeywords = [
      'chuyển tiền thành công',
      'chuyển khoản thành công',
      'giao dịch thành công',
      'thanh toán thành công',
      'chia sẻ',
      'chia se',
      'lưu ảnh',
      'luu anh',
      'lưu mẫu',
      'luu mau',
      'trang chủ',
      'home',
      'thực hiện giao dịch khác',
      'cảm ơn bạn đã sử dụng',
      'vietcombank',
      'techcombank',
      'mbbank',
      'vietinbank',
      'vietinbank (ctg)',
      'bidv',
      'agribank',
      'tpbank',
      'vpbank',
      'acb',
      'sacombank',
      'vib',
      'shb',
      'mb',
    ];
    for (final kw in systemKeywords) {
      if (lower == kw || lower.startsWith(kw)) return true;
    }
    return false;
  }

  static bool _isSkipMerchantLine(String line) {
    final lower = line.toLowerCase().trim();

    // Skip amounts with currency (e.g. "500,000 VND" or "105.000 đ")
    if ((lower.contains('vnd') ||
            lower.contains('vnđ') ||
            lower.contains('đ') ||
            lower.contains('\$')) &&
        RegExp(r'\d').hasMatch(line)) {
      return true;
    }

    // Skip transaction action buttons
    if (lower == 'chia sẻ' ||
        lower == 'chia se' ||
        lower == 'lưu ảnh' ||
        lower == 'luu anh' ||
        lower == 'lưu mẫu' ||
        lower == 'luu mau' ||
        lower == 'trang chủ' ||
        lower == 'home') {
      return true;
    }

    // Skip bank brands when standalone
    final bankStandalone = [
      'vietcombank',
      'vcb',
      'techcombank',
      'tcb',
      'mb bank',
      'mbbank',
      'mb',
      'tpbank',
      'bidv',
      'agribank',
      'vpbank',
      'acb',
      'sacombank',
      'vietinbank',
      'vietinbank (ctg)',
      'vib',
      'shb',
    ];
    if (bankStandalone.contains(lower)) return true;

    final clean = VietnameseOcrNormalizer.removeDiacritics(line).toLowerCase().trim();

    // Skip thank-you and farewell notes (e.g. "XIN CẢM ƠN!", "Cảm ơn quý khách")
    if (clean.contains('xin cam on') ||
        clean.contains('cam on quy khach') ||
        clean.contains('cam on') ||
        clean.contains('thank you') ||
        clean.contains('hen gap lai') ||
        clean.contains('chao quy khach')) {
      return true;
    }

    // Skip invoice/receipt headers and invoice numbers (e.g. "Sö HD: 70104", "PHIẾU TẠM TÍNH")
    if (RegexPatterns.invoiceTitlePattern.hasMatch(line) ||
        RegexPatterns.invoiceTitlePattern.hasMatch(clean)) {
      return true;
    }

    if (clean.contains('hoa don') ||
        clean.contains('phieu thanh toan') ||
        clean.contains('phieu tam tinh') ||
        clean.contains('tam tinh') ||
        clean.contains('phieu tinh tien') ||
        clean.contains('phieu thu') ||
        clean.contains('phieu chi') ||
        clean.contains('phieu ban hang') ||
        clean.startsWith('so hd') ||
        clean.startsWith('so hđ') ||
        clean.startsWith('so:') ||
        clean.startsWith('so :') ||
        clean.startsWith('so phieu') ||
        clean.startsWith('so bill') ||
        clean.contains('receipt') ||
        clean.contains('invoice')) {
      return true;
    }

    // Skip invoice numbering like "No: 12345", "HD: 70104", "Số: 9982"
    if (RegExp(r'^(s[oốôö]|\bno\b|\bcode\b|\bhd\b|\bhđ\b)[\s.:\-_]*[A-Za-z0-9\-_./]+$', caseSensitive: false).hasMatch(line)) {
      return true;
    }
    if (RegexPatterns.totalLabelPattern.hasMatch(line) ||
        clean.contains('tong cong') ||
        clean.contains('thanh tien') ||
        clean.contains('tien mat') ||
        clean.contains('tien thua') ||
        clean.contains('thanh toan') ||
        clean.contains('tong tien') ||
        clean.contains('subtotal') ||
        clean.contains('total')) {
      return true;
    }
    // Skip invoice codes / reference patterns (e.g. CNHP0000029, INV12345)
    if (RegExp(r'^[A-Z]{2,6}\d{4,14}$').hasMatch(line.trim())) {
      return true;
    }

    // Skip cashier, customer, and staff lines
    if (clean.contains('thu ngan') ||
        clean.contains('khach hang') ||
        clean.contains('nhan vien') ||
        clean.contains('cashier') ||
        clean.contains('customer')) {
      return true;
    }

    // Skip address lines
    if (clean.contains('dc:') ||
        clean.contains('d/c:') ||
        clean.contains('dia chi') ||
        clean.contains('address')) {
      return true;
    }

    // Skip table column headers
    if (lower.contains('tên hàng') ||
        lower.contains('đơn giá') ||
        lower.contains('thành tiền') ||
        lower.contains('số lượng') ||
        lower == 'sl') {
      return true;
    }

    if (RegexPatterns.phonePattern.hasMatch(line) ||
        lower.contains('tel:') ||
        lower.contains('hotline') ||
        lower.contains('phone') ||
        lower.contains('đt:') ||
        lower.contains('đ/t:') ||
        lower.contains('sđt:')) {
      return true;
    }
    if (lower.contains('mst:') ||
        lower.contains('mã số thuế') ||
        lower.contains('tax id')) {
      return true;
    }
    if (lower.contains('ngày') ||
        lower.contains('date') ||
        lower.contains('thời gian') ||
        lower.contains('ngay:')) {
      return true;
    }
    if (RegexPatterns.datePattern.hasMatch(line)) {
      return true;
    }
    if (RegexPatterns.bankTransferPattern.hasMatch(line)) {
      return true;
    }
    if (RegExp(r'^\d+$').hasMatch(line)) {
      return true; // Only numbers
    }
    return false;
  }

  // ===========================================================================
  // Document Type Auto-Classification
  // ===========================================================================

  /// Analyzes the full OCR text and classifies the document into one of the
  /// supported [DetectedDocumentType] values using weighted keyword scoring.
  static _DocumentTypeResult _classifyDocumentType(String rawText) {
    final lower = rawText.toLowerCase();

    // Score accumulators for each document type
    final scores = <DetectedDocumentType, double>{};
    for (final t in DetectedDocumentType.values) {
      scores[t] = 0.0;
    }

    // --- Bank Transfer signals (high-weight) ---
    final bankHighSignals = [
      'chuyển tiền thành công',
      'chuyển khoản thành công',
      'giao dịch thành công',
      'transfer successful',
      'transaction successful',
    ];
    final bankKeywords = [
      'chuyển khoản',
      'chuyển tiền',
      'người nhận',
      'tên người nhận',
      'người chuyển',
      'tên người chuyển',
      'số tài khoản',
      'tài khoản thụ hưởng',
      'ngân hàng thụ hưởng',
      'ngân hàng nhận',
      'nội dung chuyển khoản',
      'biên lai giao dịch',
      'bank transfer',
    ];
    final bankBrands = [
      'vietcombank', 'vcb', 'techcombank', 'tcb', 'mb bank', 'mbbank', 'mb',
      'tpbank', 'bidv', 'agribank', 'vpbank', 'acb', 'sacombank',
      'vietinbank', 'ctg', 'oceanbank', 'hdbank', 'shb', 'lienvietpostbank',
      'msb', 'bac a bank', 'pvcombank', 'seabank', 'nam a bank',
    ];
    for (final kw in bankHighSignals) {
      if (lower.contains(kw)) scores[DetectedDocumentType.bankTransfer] = scores[DetectedDocumentType.bankTransfer]! + 5.0;
    }
    for (final kw in bankKeywords) {
      if (lower.contains(kw)) scores[DetectedDocumentType.bankTransfer] = scores[DetectedDocumentType.bankTransfer]! + 3.0;
    }
    for (final kw in bankBrands) {
      if (lower.contains(kw)) scores[DetectedDocumentType.bankTransfer] = scores[DetectedDocumentType.bankTransfer]! + 2.0;
    }

    // --- E-Wallet signals ---
    final eWalletKeywords = [
      'momo', 'zalopay', 'zalo pay', 'shopeepay', 'shopee pay',
      'viettel money', 'vnpay', 'ví điện tử', 'ví momo',
      'thanh toán qua ví', 'quét qr', 'qr code', 'mã giao dịch',
      'ví zalopay', 'appotapay', 'smartpay',
    ];
    for (final kw in eWalletKeywords) {
      if (lower.contains(kw)) scores[DetectedDocumentType.eWallet] = scores[DetectedDocumentType.eWallet]! + 3.0;
    }

    // --- Utility Bill signals ---
    final utilityKeywords = [
      'tiền điện', 'tiền nước', 'hóa đơn tiền điện', 'hóa đơn tiền nước',
      'cước phí', 'cước viễn thông', 'thuê bao', 'nạp điện thoại',
      'tiền internet', 'cước internet', 'tiền phòng', 'tiền nhà',
      'tiền thuê', 'electricity bill', 'water bill',
    ];
    final utilityBrands = [
      'evn', 'điện lực', 'sawaco', 'cấp nước', 'viettel', 'vnpt',
      'fpt telecom', 'mobifone', 'vinaphone',
    ];
    for (final kw in utilityKeywords) {
      if (lower.contains(kw)) scores[DetectedDocumentType.utilityBill] = scores[DetectedDocumentType.utilityBill]! + 3.0;
    }
    for (final kw in utilityBrands) {
      if (lower.contains(kw)) scores[DetectedDocumentType.utilityBill] = scores[DetectedDocumentType.utilityBill]! + 1.5;
    }

    // --- Online Order signals ---
    final onlineOrderKeywords = [
      'đơn hàng', 'mã đơn hàng', 'order id', 'order no',
      'đặt hàng thành công', 'giao hàng', 'vận chuyển',
      'phí vận chuyển', 'shipping fee', 'delivery',
      'xác nhận đơn hàng', 'order confirmation',
    ];
    final onlineBrands = [
      'shopee', 'lazada', 'tiki', 'tiktok shop', 'sendo', 'amazon',
    ];
    for (final kw in onlineOrderKeywords) {
      if (lower.contains(kw)) scores[DetectedDocumentType.onlineOrder] = scores[DetectedDocumentType.onlineOrder]! + 3.0;
    }
    for (final kw in onlineBrands) {
      if (lower.contains(kw)) scores[DetectedDocumentType.onlineOrder] = scores[DetectedDocumentType.onlineOrder]! + 1.5;
    }

    // --- ATM Withdrawal signals ---
    final atmKeywords = [
      'rút tiền', 'rút tiền mặt', 'atm', 'cash withdrawal',
      'rút tiền thành công', 'máy atm', 'phí rút tiền',
    ];
    for (final kw in atmKeywords) {
      if (lower.contains(kw)) scores[DetectedDocumentType.atmWithdrawal] = scores[DetectedDocumentType.atmWithdrawal]! + 3.0;
    }

    // --- Receipt signals (standard purchase receipt) ---
    final receiptKeywords = [
      'hóa đơn', 'hoa don', 'phiếu thanh toán', 'phieu thanh toan',
      'phiếu tính tiền', 'phieu tinh tien', 'phiếu thu', 'phieu thu',
      'receipt', 'invoice', 'tổng cộng', 'tong cong', 'tổng tiền', 'tong tien',
      'thành tiền', 'thanh tien', 'tổng thanh toán', 'tong thanh toan',
      'grand total', 'subtotal',
      'tiền khách đưa', 'tien khach dua', 'tiền thừa', 'tien thua',
      'tiền thối lại', 'tien thoi lai', 'tiền thối', 'tien thoi',
      'tiền mặt', 'tien mat', 'tiền hàng', 'tien hang',
      'thuế vat', 'thue vat', 'mã số thuế', 'ma so thue', 'mst:',
      'cashier', 'thu ngân', 'thu ngan', 'bill no',
      'số hóa đơn', 'so hoa don', 'so hd', 'số hd', 'table', 'bàn số', 'ban so',
    ];
    for (final kw in receiptKeywords) {
      if (lower.contains(kw)) scores[DetectedDocumentType.receipt] = scores[DetectedDocumentType.receipt]! + 2.0;
    }

    // Find the type with the highest score
    DetectedDocumentType bestType = DetectedDocumentType.unknown;
    double bestScore = 0.0;
    double totalScore = 0.0;

    for (final entry in scores.entries) {
      if (entry.key == DetectedDocumentType.unknown) continue;
      totalScore += entry.value;
      if (entry.value > bestScore) {
        bestScore = entry.value;
        bestType = entry.key;
      }
    }

    // Minimum threshold: at least 2 keyword hits (~score of 4.0) to classify
    if (bestScore < 4.0) {
      // Fallback: if the old bankTransfer regex matches, use that
      if (RegexPatterns.bankTransferPattern.hasMatch(rawText)) {
        return _DocumentTypeResult(
          type: DetectedDocumentType.bankTransfer,
          confidence: 0.6,
        );
      }
      return _DocumentTypeResult(
        type: DetectedDocumentType.unknown,
        confidence: 0.0,
      );
    }

    // Confidence = proportion of best score vs total (capped at 1.0)
    double confidence = totalScore > 0 ? bestScore / totalScore : 0.0;
    // Also factor in absolute signal strength
    if (bestScore >= 9.0) {
      confidence = (confidence + 1.0) / 2.0; // Boost high-signal matches
    }
    if (confidence > 1.0) confidence = 1.0;

    return _DocumentTypeResult(type: bestType, confidence: confidence);
  }

  static String? _extractReference(String rawText, List<String> lines) {
    // 1. Regex match for "Mã GD: 123", "Số HĐ: CNHP..."
    final match = RegexPatterns.referencePattern.firstMatch(rawText);
    if (match != null && match.groupCount >= 2) {
      final code = match.group(2)?.trim();
      if (code != null && code.length >= 4) {
        return code;
      }
    }

    // 2. Multi-line invoice code (e.g. Line i: "Số hóa đơn:", Line i+1: "CNHP0000029")
    for (int i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase().trim();
      if (lower.contains('số hóa đơn') ||
          lower.contains('so hoa don') ||
          lower.contains('mã hóa đơn') ||
          lower.contains('số chứng từ') ||
          lower.contains('invoice no') ||
          lower.contains('bill no')) {
        // Try same line after colon
        final parts = lines[i].split(RegExp(r'[:\-]'));
        if (parts.length > 1 && parts[1].trim().isNotEmpty) {
          final c = parts[1].trim();
          if (c.length >= 4) return c;
        }
        // Try next line
        if (i + 1 < lines.length) {
          final next = lines[i + 1].trim();
          if (next.isNotEmpty && RegExp(r'^[A-Za-z0-9-_]{4,25}$').hasMatch(next)) {
            return next;
          }
        }
      }
    }

    return null;
  }

  static String _classifyTransactionType(String rawText, bool isBankTransfer) {
    final lower = rawText.toLowerCase();

    // Income keywords
    if (lower.contains('tiền vào') ||
        lower.contains('nhận tiền') ||
        lower.contains('tiền lương') ||
        lower.contains('học bổng') ||
        lower.contains('hoàn tiền') ||
        lower.contains('thưởng') ||
        lower.contains('received')) {
      return AppConstants.typeIncome;
    }

    // Default to expense
    return AppConstants.typeExpense;
  }

  // ===========================================================================
  // Category Classification
  // ===========================================================================

  static String _suggestCategory({
    String? merchant,
    required String rawText,
    required bool isBankTransfer,
  }) {
    final lower = '${merchant ?? ""} $rawText'.toLowerCase();
    final clean = VietnameseOcrNormalizer.removeDiacritics(lower);

    bool matches(List<String> keywords) {
      for (final kw in keywords) {
        final kwLower = kw.toLowerCase();
        final kwClean = VietnameseOcrNormalizer.removeDiacritics(kwLower);
        if (lower.contains(kwLower) || clean.contains(kwClean)) return true;
      }
      return false;
    }

    // 1. Food & Drinks (Ăn uống)
    if (matches([
      'coffee', 'cafe', 'cà phê', 'highlands', 'phúc long', 'starbucks', 'katinat', 'the coffee house',
      'trà sữa', 'trà', 'tea', 'tocotoco', 'gong cha', 'koi thé', 'mixue', 'ding tea',
      'ăn uống', 'ẩm thực', 'nhà hàng', 'restaurant', 'quán', 'quán ăn', 'tiệm ăn',
      'quán cơm', 'quán nước', 'quán lẩu', 'quán ốc', 'quán nhậu', 'quán nướng',
      'phở', 'bún', 'bún bò', 'bún chả', 'bún đậu', 'miến', 'cháo',
      'cơm', 'cơm tấm', 'cơm gà', 'cơm niêu', 'cơm trưa', 'cơm sườn',
      'bánh mì', 'bánh cuốn', 'bánh xèo', 'bánh canh', 'bakery', 'tiệm bánh',
      'pizza', 'kfc', 'lotteria', 'jollibee', 'mcdonald', 'gà rán', 'mì cay',
      'lẩu', 'nướng', 'bbq', 'buffet', 'haidilao', 'manwah', 'kichi kichi', 'gogi', 'king bbq',
      'hải sản', 'đồ ăn', 'đồ uống', 'food', 'drink', 'beverage', 'snack', 'kem', 'chè',
    ])) {
      return 'Food & Drinks';
    }

    // 2. Travel & Transport (Di chuyển, vé máy bay, xăng xe)
    if (matches([
      'xăng', 'petrolimex', 'pv oil', 'pvoil', 'nhiên liệu',
      'grab', 'be', 'gojek', 'xanh sm', 'taxi', 'mai linh', 'vinasun',
      'xe buýt', 'bus', 'vé xe', 'gửi xe', 'bãi đỗ', 'parking', 'trông xe',
      'vé tàu', 'đường sắt', 'vé máy bay', 'boarding', 'boarding pass', 'flight', 'airline',
      'vietnam airlines', 'vietjet', 'bamboo airways', 'di chuyển', 'cầu đường', 'phí bot', 'toll',
    ])) {
      return 'Travel';
    }

    // 3. Study & Education (Học tập, sách vở, học phí VKU)
    if (matches([
      'nhà sách', 'fahasa', 'phương nam', 'tiệm sách', 'sách', 'book', 'stationery',
      'văn phòng phẩm', 'giáo trình', 'học phí', 'đại học', 'university', 'vku', 'việt - hàn',
      'photo', 'in ấn', 'học tập', 'khóa học', 'course', 'bút', 'vở', 'thư viện',
    ])) {
      return 'Study';
    }

    // 4. Shopping & Supermarket (Siêu thị, mua sắm)
    if (matches([
      'siêu thị', 'supermarket', 'mart', 'coopmart', 'co.opmart', 'winmart', 'winmart+', 'vinmart', 'big c', 'go!', 'tops market',
      'lotte mart', 'emart', 'aeon', 'mega market', 'bách hóa xanh', 'bách hóa',
      'circle k', '7-eleven', 'ministop', 'familymart', 'gs25',
      'shopee', 'lazada', 'tiki', 'tiktok shop',
      'quần áo', 'thời trang', 'giày', 'mỹ phẩm', 'điện thoại', 'tgdd', 'thế giới di động',
      'fpt shop', 'cellphones', 'viettel store', 'shopping',
    ])) {
      return 'Shopping';
    }

    // 5. Bills & Utilities (Hóa đơn điện nước, tiền phòng trọ)
    if (matches([
      'tiền điện', 'evn', 'điện lực', 'tiền nước', 'sawaco', 'cấp nước',
      'internet', 'viettel', 'vnpt', 'fpt', 'nạp điện thoại', 'thẻ cào', 'cước',
      'hóa đơn', 'tiền phòng', 'tiền nhà', 'tiền trọ', 'đóng trọ', 'phòng trọ', 'thuê nhà',
    ])) {
      return 'Bills & Utilities';
    }

    // 6. Healthcare (Y tế & Sức khỏe)
    if (matches([
      'nhà thuốc', 'pharmacy', 'long châu', 'fpt long châu', 'an khang', 'pharmacity',
      'bệnh viện', 'phòng khám', 'thuốc', 'khám bệnh', 'nha khoa', 'y tế', 'sức khỏe',
    ])) {
      return 'Healthcare';
    }

    // 7. Entertainment (Giải trí)
    if (matches([
      'cinema', 'cgv', 'lotte cinema', 'bhd', 'galaxy', 'cinestar', 'xem phim',
      'game', 'billiards', 'bida', 'karaoke', 'net', 'cyber', 'vé tham quan', 'du lịch', 'giải trí',
    ])) {
      return 'Entertainment';
    }

    // 8. Bank Transfer (Chuyển khoản)
    if (isBankTransfer ||
        matches(['chuyển khoản', 'chuyển tiền', 'transfer', 'nạp tiền', 'rút tiền'])) {
      return 'Transfer';
    }

    return 'Other';
  }


  static String _detectPaymentMethod(String rawText, bool isBankTransfer) {
    final lower = rawText.toLowerCase();

    if (isBankTransfer ||
        lower.contains('chuyển khoản') ||
        lower.contains('bank transfer') ||
        lower.contains('vietcombank') ||
        lower.contains('mb bank') ||
        lower.contains('techcombank')) {
      return 'Bank Transfer';
    }

    if (lower.contains('momo') ||
        lower.contains('zalopay') ||
        lower.contains('viettel money') ||
        lower.contains('ví điện tử') ||
        lower.contains('shopeepay')) {
      return 'E-Wallet';
    }

    if (lower.contains('thẻ tín dụng') ||
        lower.contains('visa') ||
        lower.contains('mastercard') ||
        lower.contains('napas') ||
        lower.contains('quẹt thẻ')) {
      return 'Card';
    }

    if (lower.contains('tiền mặt') || lower.contains('cash')) {
      return 'Cash';
    }

    return isBankTransfer ? 'Bank Transfer' : 'Cash';
  }
}

class _AmountParseResult {
  final int? amount;
  final String? warning;
  final bool confidenceBonus;

  _AmountParseResult({
    required this.amount,
    required this.warning,
    required this.confidenceBonus,
  });
}

class _DateTimeParseResult {
  final String? date;
  final String? time;

  _DateTimeParseResult({required this.date, required this.time});
}

class _DocumentTypeResult {
  final DetectedDocumentType type;
  final double confidence;

  _DocumentTypeResult({required this.type, required this.confidence});
}
