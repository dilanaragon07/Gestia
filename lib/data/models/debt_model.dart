class DebtEvolutionData {
  const DebtEvolutionData({
    required this.month,
    required this.newDebt,
    required this.paymentsMade,
  });

  final String month;
  final double newDebt;
  final double paymentsMade;
}

class InvoiceDebtPoint {
  const InvoiceDebtPoint({
    required this.invoiceNumber,
    required this.issueDate,
    required this.finalAmount,
    required this.balance,
    required this.status,
  });

  final String invoiceNumber;
  final DateTime issueDate;
  final double finalAmount;
  final double balance;
  final String status;
}

class AdminStats {
  const AdminStats({
    required this.totalDebt,
    required this.paidThisMonth,
    required this.activeUsers,
    required this.supplierCount,
  });

  final double totalDebt;
  final double paidThisMonth;
  final int activeUsers;
  final int supplierCount;

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalDebt: (json['total_debt'] as num).toDouble(),
        paidThisMonth: (json['paid_this_month'] as num).toDouble(),
        activeUsers: (json['active_users'] as num).toInt(),
        supplierCount: (json['supplier_count'] as num).toInt(),
      );
}
