import 'package:flutter/material.dart';

/// 物品分类枚举
enum Category {
  electronic('电子', Icons.phone_android, Colors.blue),
  appliance('家电', Icons.kitchen, Colors.orange),
  clothing('服饰', Icons.checkroom, Colors.purple),
  transport('交通', Icons.directions_car, Colors.red),
  sport('运动', Icons.fitness_center, Colors.green),
  furniture('家具', Icons.chair, Colors.brown),
  book('书籍', Icons.menu_book, Colors.teal),
  other('其他', Icons.inventory_2_outlined, Colors.grey);

  final String label;
  final IconData icon;
  final Color color;

  const Category(this.label, this.icon, this.color);

  /// 根据名称智能匹配分类
  static Category guessFromName(String name) {
    final lower = name.toLowerCase();
    if (_matchAny(lower, ['手机', '电脑', '平板', '耳机', '键盘', '鼠标', '显示器',
        '相机', '充电', '音箱', 'iphone', 'ipad', 'macbook', 'laptop', 'watch'])) {
      return Category.electronic;
    }
    if (_matchAny(lower, ['电视', '冰箱', '洗衣机', '空调', '吸尘', '风扇', '微波'])) {
      return Category.appliance;
    }
    if (_matchAny(lower, ['衣服', '鞋', '包', '裤', '帽', '袜', '裙'])) {
      return Category.clothing;
    }
    if (_matchAny(lower, ['车', '自行车', '摩托'])) {
      return Category.transport;
    }
    if (_matchAny(lower, ['球', '健身', '哑铃', '跑步机', '瑜伽'])) {
      return Category.sport;
    }
    if (_matchAny(lower, ['桌', '椅', '凳', '柜', '床', '灯', '沙发'])) {
      return Category.furniture;
    }
    if (_matchAny(lower, ['书', 'kindle'])) {
      return Category.book;
    }
    return Category.other;
  }

  static bool _matchAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
}
