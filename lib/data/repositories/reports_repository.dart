import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chart_data_model.dart';

class ReportsRepository {
  final _client = Supabase.instance.client;

  Future<List<MonthlyChartData>> getMonthlyFlow() async {
    final response = await _client.rpc('get_monthly_flow');
    return (response as List)
        .map((row) => MonthlyChartData(
              month: row['month'] as String,
              paid: (row['paid'] as num).toDouble(),
              pending: (row['pending'] as num).toDouble(),
              overdue: (row['overdue'] as num).toDouble(),
            ))
        .toList();
  }

  Future<List<CategoryData>> getCategoryBreakdown() async {
    final response = await _client.rpc('get_category_breakdown');
    return (response as List)
        .map((row) => CategoryData(
              category: row['category'] as String,
              amount: (row['amount'] as num).toDouble(),
              percentage: (row['percentage'] as num).toDouble(),
              count: (row['count'] as num).toInt(),
            ))
        .toList();
  }
}
