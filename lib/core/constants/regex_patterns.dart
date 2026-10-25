/// Regular expression patterns used for OCR candidate extraction.
class RegexPatterns {
  RegexPatterns._();

  // Date formats: dd/MM/yyyy, dd-MM-yyyy, yyyy-MM-dd, dd.MM.yyyy
  static final RegExp datePattern = RegExp(
    r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})\b|\b(\d{4})[/.-](\d{1,2})[/.-](\d{1,2})\b',
  );

  // Time format: HH:mm or HH:mm:ss
  static final RegExp timePattern = RegExp(
    r'\b([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?\b',
  );

  // Monetary numbers: 150.000, 150,000, 150000, 125.00
  static final RegExp amountNumberPattern = RegExp(
    r'(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?|\d+(?:[.,]\d{2})?)\s*(?:đ|vnd|vnđ|\$)?',
    caseSensitive: false,
  );

  // Contextual labels for Total
  static final RegExp totalLabelPattern = RegExp(
    r'(t[oổô]ng\s*ti[eề]n\s*thanh\s*to[aá]n|t[oổô]ng\s*thanh\s*to[aá]n|t[oổô]ng\s*c[oộô]ng|th[aà]nh\s*ti[eề]n|t[oổô]ng\s*ti[eề]n|s[oốô]\s*ti[eề]n\s*thanh\s*to[aá]n|s[oốô]\s*ti[eề]n\s*giao\s*d[iị]ch|ti[eề]n\s*thanh\s*to[aá]n|s[oốô]\s*ti[eề]n|total|grand\s*total|amount|transfer\s*amount|thanh\s*to[aá]n)',
    caseSensitive: false,
  );

  // Invoice / Bill headers and numbers (must NEVER be treated as Merchant Name)
  static final RegExp invoiceTitlePattern = RegExp(
    r'^(s[oốôö][\s.:\-_]*(?:hđ|hd|hóa\s*đơn|hoa\s*don|phiếu|phieu|ct|chứng\s*từ|bill|inv)[\s.:\-_]*\d*|phiếu\s*(?:tạm\s*tính|thanh\s*toán|thu|chi|bán\s*hàng|tính\s*tiền|gọi\s*món)|hóa\s*đơn\s*(?:bán\s*hàng|giá\s*trị\s*gia\s*tăng|gtgt|bán\s*lẻ|điện\s*tử)|receipt|invoice|bill|statement|tax\s*invoice|vat\s*invoice)\b',
    caseSensitive: false,
  );

  // Phone numbers (e.g. "ĐT: 0962122573", "+84 912 345 678", 10-digit mobile)
  static final RegExp phonePattern = RegExp(
    r'(?:đt|đ/t|dt|tel|phone|hotline|sđt|sdt|mobile)[\s:.]*([0-9\s.-]{8,15})|\b(0[35789]\d{8})\b|(?:\+84|84)[\s.-]*\d{2,3}[\s.-]*\d{3}[\s.-]*\d{3,4}',
    caseSensitive: false,
  );

  // Subtotal, Discount, VAT, Cash given, Change returned (to distinguish and avoid false totals)
  static final RegExp subtotalPattern = RegExp(
    r'(ti[eề]n\s*h[aà]ng|t[oổô]ng\s*ti[eề]n\s*h[aà]ng|subtotal)',
    caseSensitive: false,
  );

  static final RegExp discountPattern = RegExp(
    r'(gi[aả]m\s*gi[aá]|chi[eế]t\s*kh[aấ]u|discount|khuy[eế]n\s*m[aã]i)',
    caseSensitive: false,
  );

  static final RegExp vatPattern = RegExp(
    r'(thu[eế]|vat|tax)',
    caseSensitive: false,
  );

  static final RegExp cashGivenPattern = RegExp(
    r'(kh[aá]ch\s*đ[uư]a|ti[eề]n\s*kh[aá]ch\s*đ[uư]a|cash\s*tendered|cash)',
    caseSensitive: false,
  );

  static final RegExp changePattern = RegExp(
    r'(ti[eề]n\s*th[oốô]i|ti[eề]n\s*tr[aả]\s*l[aạ]i|change)',
    caseSensitive: false,
  );

  // Bank Transfer Success Indicators
  static final RegExp bankTransferPattern = RegExp(
    r'(giao\s*d[iị]ch\s*th[aà]nh\s*c[oô]ng|chuy[eể]n\s*kho[aả]n\s*th[aà]nh\s*c[oô]ng|chuy[eể]n\s*ti[eề]n\s*th[aà]nh\s*c[oô]ng|transaction\s*successful|transfer\s*successful)',
    caseSensitive: false,
  );

  // Recipient / Sender
  static final RegExp recipientPattern = RegExp(
    r'(ng[uư][oờ]i\s*nh[aậ]n|t[eê]n\s*ng[uư][oờ]i\s*nh[aậ]n|recipient|đ[oơ]n\s*v[iị]\s*nh[aậ]n)',
    caseSensitive: false,
  );

  static final RegExp senderPattern = RegExp(
    r'(ng[uư][oờ]i\s*chuy[eể]n|t[eê]n\s*ng[uư][oờ]i\s*chuy[eể]n|sender)',
    caseSensitive: false,
  );

  // Reference Code / Transfer Note
  static final RegExp referencePattern = RegExp(
    r'(m[aã]\s*giao\s*d[iị]ch|m[aã]\s*tham\s*chi[eế]u|transaction\s*id|ref\s*no|reference\s*number|m[aã]\s*gd)[\s:]*([A-Za-z0-9-_]+)',
    caseSensitive: false,
  );

  static final RegExp transferNotePattern = RegExp(
    r'(n[oộ]i\s*dung|n[oộ]i\s*dung\s*chuy[eể]n\s*kho[aả]n|l[yý]\s*do|ghi\s*ch[uú]|description)[\s:]*(.*)',
    caseSensitive: false,
  );
}
