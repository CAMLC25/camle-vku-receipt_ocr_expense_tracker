/// Detected document type from OCR text analysis.
enum DetectedDocumentType {
  /// Standard printed receipt (restaurant, cafe, supermarket, shop).
  receipt,

  /// Bank transfer confirmation screenshot.
  bankTransfer,

  /// E-Wallet transaction screenshot (MoMo, ZaloPay, ShopeePay, etc.).
  eWallet,

  /// Utility bill (electricity, water, internet, phone).
  utilityBill,

  /// Online shopping order confirmation or invoice.
  onlineOrder,

  /// ATM withdrawal slip or notification.
  atmWithdrawal,

  /// Could not determine type with high confidence.
  unknown,
}

/// Holds heuristic candidate fields extracted from recognized receipt/screenshot text.
class ParsedReceipt {
  final String? merchantCandidate;
  final String? sellerAddressCandidate;
  final int? amountCandidate;
  final String? dateCandidate; // ISO format: YYYY-MM-DD
  final String? timeCandidate; // HH:mm:ss
  final String transactionTypeCandidate; // 'expense' or 'income'
  final String categoryCandidate;
  final String? paymentMethodCandidate;
  final String? referenceCandidate;
  final String rawText;
  final List<String> warnings;
  final double confidenceScore; // 0.0 to 1.0
  final DetectedDocumentType detectedDocumentType;
  final double documentTypeConfidence; // 0.0 to 1.0

  const ParsedReceipt({
    this.merchantCandidate,
    this.sellerAddressCandidate,
    this.amountCandidate,
    this.dateCandidate,
    this.timeCandidate,
    this.transactionTypeCandidate = 'expense',
    this.categoryCandidate = 'Other',
    this.paymentMethodCandidate,
    this.referenceCandidate,
    required this.rawText,
    this.warnings = const [],
    this.confidenceScore = 0.5,
    this.detectedDocumentType = DetectedDocumentType.unknown,
    this.documentTypeConfidence = 0.0,
  });

  factory ParsedReceipt.empty([String rawText = '']) =>
      const ParsedReceipt(rawText: '', confidenceScore: 0.0);

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasAmount => amountCandidate != null && amountCandidate! > 0;
  bool get hasDate => dateCandidate != null && dateCandidate!.isNotEmpty;
  bool get hasMerchant =>
      merchantCandidate != null && merchantCandidate!.isNotEmpty;

  /// Vietnamese label for the detected document type.
  String get documentTypeLabelVi {
    switch (detectedDocumentType) {
      case DetectedDocumentType.receipt:
        return 'Hóa đơn mua hàng';
      case DetectedDocumentType.bankTransfer:
        return 'Chuyển khoản ngân hàng';
      case DetectedDocumentType.eWallet:
        return 'Ví điện tử';
      case DetectedDocumentType.utilityBill:
        return 'Hóa đơn dịch vụ';
      case DetectedDocumentType.onlineOrder:
        return 'Đơn hàng online';
      case DetectedDocumentType.atmWithdrawal:
        return 'Rút tiền ATM';
      case DetectedDocumentType.unknown:
        return 'Chưa xác định';
    }
  }

  /// Icon for the detected document type.
  String get documentTypeEmoji {
    switch (detectedDocumentType) {
      case DetectedDocumentType.receipt:
        return '🧾';
      case DetectedDocumentType.bankTransfer:
        return '🏦';
      case DetectedDocumentType.eWallet:
        return '📱';
      case DetectedDocumentType.utilityBill:
        return '💡';
      case DetectedDocumentType.onlineOrder:
        return '📦';
      case DetectedDocumentType.atmWithdrawal:
        return '🏧';
      case DetectedDocumentType.unknown:
        return '❓';
    }
  }
}
