import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

/// 基于 SharedPreferences 的物品数据持久化层。
///
/// 将物品列表以 JSON 字符串形式存储在本地。
class ItemRepository {
  static const _key = 'items';

  /// 从本地存储加载物品列表。
  Future<List<Item>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = json.decode(raw) as List<dynamic>;
    return list.map((e) => Item.fromMap(e as Map<String, dynamic>)).toList();
  }

  /// 将物品列表保存到本地存储。
  Future<void> save(List<Item> items) async {
    final prefs = await SharedPreferences.getInstance();
    final data = items.map((e) => e.toMap()).toList();
    await prefs.setString(_key, json.encode(data));
  }
}
