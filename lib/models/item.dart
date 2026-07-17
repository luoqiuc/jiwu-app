import 'dart:convert';
import 'category.dart';

/// 物品实体，记录购买信息和使用状态。
class Item {
  /// 唯一标识符（32 位十六进制字符串）
  final String id;

  /// 物品名称
  final String name;

  /// 购买日期
  final DateTime purchaseDate;

  /// 购买价格（元）
  final double price;

  /// 是否在服役中
  final bool inUse;

  /// 记录创建时间
  final DateTime createdAt;

  /// 物品分类
  final Category category;

  /// 保修到期日期（可选，null 表示未设置）
  final DateTime? warrantyEndDate;

  const Item({
    required this.id,
    required this.name,
    required this.purchaseDate,
    required this.price,
    required this.inUse,
    required this.createdAt,
    this.category = Category.other,
    this.warrantyEndDate,
  });

  /// 已使用天数，最少为 1 天
  int get daysUsed {
    final now = DateTime.now();
    final diff = now
        .difference(
            DateTime(purchaseDate.year, purchaseDate.month, purchaseDate.day))
        .inDays;
    return diff <= 0 ? 1 : diff;
  }

  /// 每日使用成本（元/天）
  double get costPerDay {
    return price / daysUsed;
  }

  /// 保修剩余天数，null 表示未设置保修期
  int? get warrantyDaysLeft {
    if (warrantyEndDate == null) return null;
    final days = warrantyEndDate!.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  /// 保修是否已过期
  bool get isWarrantyExpired =>
      warrantyEndDate != null && warrantyEndDate!.isBefore(DateTime.now());

  /// 保修是否即将到期（7 天内）
  bool get isWarrantyExpiringSoon {
    final left = warrantyDaysLeft;
    return left != null && left > 0 && left <= 7;
  }

  Item copyWith({
    String? id,
    String? name,
    DateTime? purchaseDate,
    double? price,
    bool? inUse,
    DateTime? createdAt,
    Category? category,
    DateTime? warrantyEndDate,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      price: price ?? this.price,
      inUse: inUse ?? this.inUse,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      warrantyEndDate: warrantyEndDate ?? this.warrantyEndDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'purchaseDate': purchaseDate.toIso8601String(),
      'price': price,
      'inUse': inUse,
      'createdAt': createdAt.toIso8601String(),
      'category': category.index,
      if (warrantyEndDate != null)
        'warrantyEndDate': warrantyEndDate!.toIso8601String(),
    };
  }

  /// 从 Map 创建 Item，包含数据校验。
  ///
  /// 对缺失的 `createdAt` 字段向后兼容（使用 purchaseDate）。
  /// 对非法数据抛出 [FormatException]。
  factory Item.fromMap(Map<String, dynamic> map) {
    // 校验必填字段
    if (map['id'] is! String || (map['id'] as String).isEmpty) {
      throw const FormatException('物品 ID 缺失或格式无效');
    }
    if (map['name'] is! String || (map['name'] as String).trim().isEmpty) {
      throw const FormatException('物品名称缺失或为空');
    }
    if (map['price'] is! num || (map['price'] as num) <= 0) {
      throw const FormatException('价格必须为正数');
    }

    final purchaseDate = DateTime.parse(map['purchaseDate'] as String);
    final createdAt = map.containsKey('createdAt')
        ? DateTime.parse(map['createdAt'] as String)
        : purchaseDate;
    // 分类字段向后兼容：缺失时根据名称智能推断
    final categoryIndex = map['category'] as int?;
    final category = categoryIndex != null
        ? Category.values[categoryIndex]
        : Category.guessFromName((map['name'] as String).trim());

    // 保修日期向后兼容
    final warrantyStr = map['warrantyEndDate'] as String?;

    return Item(
      id: map['id'] as String,
      name: (map['name'] as String).trim(),
      purchaseDate: purchaseDate,
      price: (map['price'] as num).toDouble(),
      inUse: map['inUse'] as bool? ?? true,
      createdAt: createdAt,
      category: category,
      warrantyEndDate:
          warrantyStr != null ? DateTime.tryParse(warrantyStr) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Item.fromJson(String source) =>
      Item.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Item(id: $id, name: $name, price: $price, inUse: $inUse)';
}
