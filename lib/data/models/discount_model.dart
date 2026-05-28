class DiscountDetail {
  const DiscountDetail({
    required this.product,
    required this.quantity,
    required this.originalValue,
    required this.discountedValue,
    required this.reason,
  });

  final String product;
  final double quantity;
  final double originalValue;
  final double discountedValue;
  final String reason;

  double get lineDiscount => (originalValue - discountedValue) * quantity;
}

class DiscountModel {
  const DiscountModel({required this.items});

  final List<DiscountDetail> items;

  double get totalDiscount => items.fold(0.0, (s, i) => s + i.lineDiscount);
}
