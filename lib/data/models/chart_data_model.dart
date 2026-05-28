class MonthlyChartData {
  const MonthlyChartData({
    required this.month,
    required this.paid,
    required this.pending,
    required this.overdue,
  });

  final String month;
  final double paid;
  final double pending;
  final double overdue;
}

class CategoryData {
  const CategoryData({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.count,
  });

  final String category;
  final double amount;
  final double percentage;
  final int count;
}
