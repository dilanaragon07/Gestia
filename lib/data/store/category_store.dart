import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';

class CategoryStore extends ChangeNotifier {
  static final CategoryStore instance = CategoryStore._();
  CategoryStore._();

  final _repo = CategoryRepository();

  List<CategoryModel> _categories = [];
  bool _loading = false;

  List<CategoryModel> get categories => List.unmodifiable(_categories);
  bool get isLoading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _categories = await _repo.fetchAll();
    } catch (_) {
      _categories = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create(String name, String colorHex) async {
    final created = await _repo.create(name, colorHex);
    _categories = [..._categories, created]..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> update(String id, String name, String colorHex) async {
    final updated = await _repo.update(id, name, colorHex);
    _categories = _categories.map((c) => c.id == id ? updated : c).toList();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _categories = _categories.where((c) => c.id != id).toList();
    notifyListeners();
  }

  void reset() {
    _categories = [];
    _loading = false;
    notifyListeners();
  }
}
