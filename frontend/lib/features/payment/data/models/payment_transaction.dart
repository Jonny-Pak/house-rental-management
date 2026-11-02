class PaymentTransaction {
  const PaymentTransaction({
    required this.reference,
    required this.packageName,
    required this.amount,
    required this.status,
    this.responseCode,
    this.createdAt,
  });
  final String reference, packageName, status;
  final double amount;
  final String? responseCode;
  final DateTime? createdAt;
  bool get pending => status == 'PENDING';
  bool get success => status == 'SUCCESS';

  String get statusLabel {
    if (success) return 'Thanh toán thành công';
    if (status == 'CANCELLED') return 'Đã hủy thanh toán';
    if (status == 'FAILED') return 'Thanh toán thất bại';
    if (status == 'EXPIRED') return 'Đã hết thời gian thanh toán';
    return 'Đang chờ xác nhận';
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) =>
      PaymentTransaction(
        reference: json['reference'] as String? ?? '',
        packageName: json['packageName'] as String? ?? 'Gói dịch vụ',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'PENDING',
        responseCode: json['responseCode'] as String?,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}
