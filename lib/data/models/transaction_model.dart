/// Transaction entity model representing a recorded expense or income.
class TransactionModel {
  final String id;
  final String merchant;
  final String? description;
  final int amount; // Stored as integer Vietnamese đồng (VND)
  final String currency;
  final String transactionDate; // ISO 8601: YYYY-MM-DD
  final String? transactionTime; // HH:mm:ss
  final String transactionType; // 'expense' or 'income'
  final String category;
  final String? paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final String? receiptImagePath;
  final String? rawOcrText;
  final String createdAt;
  final String updatedAt;

  const TransactionModel({
    required this.id,
    required this.merchant,
    this.description,
    required this.amount,
    this.currency = 'VND',
    required this.transactionDate,
    this.transactionTime,
    required this.transactionType,
    required this.category,
    this.paymentMethod,
    this.referenceNumber,
    this.notes,
    this.receiptImagePath,
    this.rawOcrText,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpense => transactionType == 'expense';
  bool get isIncome => transactionType == 'income';

  TransactionModel copyWith({
    String? id,
    String? merchant,
    String? description,
    int? amount,
    String? currency,
    String? transactionDate,
    String? transactionTime,
    String? transactionType,
    String? category,
    String? paymentMethod,
    String? referenceNumber,
    String? notes,
    String? receiptImagePath,
    String? rawOcrText,
    String? createdAt,
    String? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      transactionDate: transactionDate ?? this.transactionDate,
      transactionTime: transactionTime ?? this.transactionTime,
      transactionType: transactionType ?? this.transactionType,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'description': description,
      'amount': amount,
      'currency': currency,
      'transaction_date': transactionDate,
      'transaction_time': transactionTime,
      'transaction_type': transactionType,
      'category': category,
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'notes': notes,
      'receipt_image_path': receiptImagePath,
      'raw_ocr_text': rawOcrText,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      merchant: map['merchant'] as String,
      description: map['description'] as String?,
      amount: (map['amount'] as num).toInt(),
      currency: (map['currency'] as String?) ?? 'VND',
      transactionDate: map['transaction_date'] as String,
      transactionTime: map['transaction_time'] as String?,
      transactionType: map['transaction_type'] as String,
      category: map['category'] as String,
      paymentMethod: map['payment_method'] as String?,
      referenceNumber: map['reference_number'] as String?,
      notes: map['notes'] as String?,
      receiptImagePath: map['receipt_image_path'] as String?,
      rawOcrText: map['raw_ocr_text'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}
