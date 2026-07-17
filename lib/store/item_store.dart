import 'dart:math';
import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../models/item.dart';
import '../storage/item_repository.dart';

/// 排序维度
enum SortBy {
  purchaseDateDesc('购买日期↓', '购买日期 新→旧'),
  purchaseDateAsc('购买日期↑', '购买日期 旧→新'),
  priceDesc('价格↓', '价格 高→低'),
  priceAsc('价格↑', '价格 低→高'),
  costPerDayDesc('日均↓', '日均成本 高→低'),
  costPerDayAsc('日均↑', '日均成本 低→高'),
  nameAsc('名称A-Z', '名称 A→Z');

  final String shortLabel;
  final String fullLabel;
  const SortBy(this.shortLabel, this.fullLabel);
}

/// 物品数据状态管理，提供 CRUD 操作和统计计算。
class ItemStore extends ChangeNotifier {
  final ItemRepository _repo;
  List<Item> _items = [];
  bool _loading = false;
  SortBy _sortBy = SortBy.purchaseDateDesc;

  ItemStore(this._repo);

  List<Item> get items => _sorted(_items);
  bool get loading => _loading;
  SortBy get sortBy => _sortBy;

  // ── 统计数据（由 _recalculate 缓存） ──

  List<Item> get activeItems => _sorted(_items.where((e) => e.inUse).toList());
  List<Item> get retiredItems => _sorted(_items.where((e) => !e.inUse).toList());

  /// 服役中物品的总价值
  double get assetSum => activeItems.fold(0, (s, e) => s + e.price);

  /// 所有物品的总购入价格
  double get totalPurchase => _items.fold(0, (s, e) => s + e.price);

  /// 所有物品的日均成本之和
  double get totalDailyCost => _items.fold(0, (s, e) => s + e.costPerDay);

  /// 单件物品的最高日均成本
  double get maxDailyCost =>
      _items.isEmpty ? 0.0 : _items.map((e) => e.costPerDay).reduce((a, b) => a > b ? a : b);

  /// 单件物品的最低日均成本
  double get minDailyCost =>
      _items.isEmpty ? 0.0 : _items.map((e) => e.costPerDay).reduce((a, b) => a < b ? a : b);

  /// 保修即将到期（7 天内）或已过期的服役物品
  List<Item> get warrantyAlertItems => _items
      .where((e) => e.inUse && (e.isWarrantyExpiringSoon || e.isWarrantyExpired))
      .toList();

  // ── CRUD 操作 ──

  /// 从存储加载物品列表
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _repo.load();
    _loading = false;
    notifyListeners();
  }

  /// 添加新物品
  Future<void> addItem(
      String name, DateTime purchaseDate, double price, bool inUse,
      {Category category = Category.other, DateTime? warrantyEndDate}) async {
    final item = Item(
      id: _randomId(),
      name: name,
      purchaseDate: purchaseDate,
      price: price,
      inUse: inUse,
      createdAt: DateTime.now(),
      category: category,
      warrantyEndDate: warrantyEndDate,
    );
    _items = [..._items, item];
    await _repo.save(_items);
    notifyListeners();
  }

  /// 更新已有物品
  Future<void> updateItem(Item updated) async {
    _items = _items.map((e) => e.id == updated.id ? updated : e).toList();
    await _repo.save(_items);
    notifyListeners();
  }

  /// 删除指定物品
  Future<void> removeItem(String id) async {
    _items = _items.where((e) => e.id != id).toList();
    await _repo.save(_items);
    notifyListeners();
  }

  /// 切换物品的服役状态
  Future<void> toggleInUse(String id, bool inUse) async {
    _items =
        _items.map((e) => e.id == id ? e.copyWith(inUse: inUse) : e).toList();
    await _repo.save(_items);
    notifyListeners();
  }

  /// 替换全部物品（用于导入数据）
  Future<void> replaceAllItems(List<Item> newItems) async {
    _items = newItems;
    await _repo.save(_items);
    notifyListeners();
  }

  // ── 排序操作 ──

  /// 切换排序方式
  void setSortBy(SortBy sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  /// 按当前排序方式排序列表（不修改原数据）
  List<Item> _sorted(List<Item> list) {
    final sorted = List<Item>.from(list);
    switch (_sortBy) {
      case SortBy.purchaseDateDesc:
        sorted.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      case SortBy.purchaseDateAsc:
        sorted.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
      case SortBy.priceDesc:
        sorted.sort((a, b) => b.price.compareTo(a.price));
      case SortBy.priceAsc:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case SortBy.costPerDayDesc:
        sorted.sort((a, b) => b.costPerDay.compareTo(a.costPerDay));
      case SortBy.costPerDayAsc:
        sorted.sort((a, b) => a.costPerDay.compareTo(b.costPerDay));
      case SortBy.nameAsc:
        sorted.sort((a, b) => a.name.compareTo(b.name));
    }
    return sorted;
  }

  // ── 内部方法 ──

  String _randomId() {
    final rand = Random();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
