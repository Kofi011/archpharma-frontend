class CreditAgingItem {
  final String invoiceId;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double grandTotal;
  final double balance;
  final int daysOverdue;
  final String agingBucket; // current, 30, 60, 90+

  const CreditAgingItem({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.invoiceDate,
    required this.dueDate,
    required this.grandTotal,
    required this.balance,
    required this.daysOverdue,
    required this.agingBucket,
  });

  bool get isCurrent => agingBucket == 'current';
  bool get is30Days => agingBucket == '30';
  bool get is60Days => agingBucket == '60';
  bool get is90PlusDays => agingBucket == '90+';
}
