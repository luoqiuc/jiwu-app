import 'package:flutter/material.dart';

/// 根据物品名称自动匹配合适的图标。
///
/// 基于关键词匹配，返回最相关的 Material Icon。
IconData matchIconForItem(String name) {
  final lower = name.toLowerCase();

  // 电子产品
  if (_containsAny(lower, ['手机', 'iphone', 'phone', '小米', '华为', '三星', 'oppo', 'vivo'])) {
    return Icons.phone_android;
  }
  if (_containsAny(lower, ['电脑', '笔记本', 'macbook', 'laptop', 'thinkpad'])) {
    return Icons.laptop;
  }
  if (_containsAny(lower, ['平板', 'ipad', 'tablet'])) {
    return Icons.tablet;
  }
  if (_containsAny(lower, ['耳机', 'earphone', 'airpods', 'headphone'])) {
    return Icons.headphones;
  }
  if (_containsAny(lower, ['手表', 'watch', '手环'])) {
    return Icons.watch;
  }
  if (_containsAny(lower, ['相机', 'camera', '镜头'])) {
    return Icons.camera_alt;
  }
  if (_containsAny(lower, ['键盘', 'keyboard'])) {
    return Icons.keyboard;
  }
  if (_containsAny(lower, ['鼠标', 'mouse'])) {
    return Icons.mouse;
  }
  if (_containsAny(lower, ['显示器', 'monitor', '屏幕'])) {
    return Icons.desktop_windows;
  }
  if (_containsAny(lower, ['音箱', 'speaker', '音响'])) {
    return Icons.speaker;
  }
  if (_containsAny(lower, ['充电', 'charger', '充电宝', '移动电源'])) {
    return Icons.battery_charging_full;
  }

  // 家电
  if (_containsAny(lower, ['电视', 'tv'])) {
    return Icons.tv;
  }
  if (_containsAny(lower, ['冰箱', 'fridge'])) {
    return Icons.kitchen;
  }
  if (_containsAny(lower, ['洗衣机', 'washer'])) {
    return Icons.local_laundry_service;
  }
  if (_containsAny(lower, ['空调', 'ac', '风扇', 'fan'])) {
    return Icons.ac_unit;
  }
  if (_containsAny(lower, ['吸尘器', '扫地', 'vacuum'])) {
    return Icons.cleaning_services;
  }

  // 服饰
  if (_containsAny(lower, ['衣服', 'shirt', 't恤', '外套', '夹克', '卫衣'])) {
    return Icons.checkroom;
  }
  if (_containsAny(lower, ['鞋', 'shoe', 'nike', 'adidas', '运动鞋', '皮鞋'])) {
    return Icons.directions_run;
  }
  if (_containsAny(lower, ['包', 'bag', '背包', '手提包'])) {
    return Icons.work;
  }

  // 交通
  if (_containsAny(lower, ['车', 'car', '汽车'])) {
    return Icons.directions_car;
  }
  if (_containsAny(lower, ['自行车', 'bike', '单车'])) {
    return Icons.directions_bike;
  }

  // 运动
  if (_containsAny(lower, ['球', 'ball', '足球', '篮球'])) {
    return Icons.sports_soccer;
  }
  if (_containsAny(lower, ['健身', 'gym', '哑铃', '跑步机'])) {
    return Icons.fitness_center;
  }

  // 书籍
  if (_containsAny(lower, ['书', 'book', 'kindle'])) {
    return Icons.menu_book;
  }

  // 家具
  if (_containsAny(lower, ['桌', 'desk', 'table'])) {
    return Icons.desk;
  }
  if (_containsAny(lower, ['椅', 'chair', '凳'])) {
    return Icons.chair;
  }
  if (_containsAny(lower, ['灯', 'lamp', 'light'])) {
    return Icons.light;
  }

  // 默认
  return Icons.inventory_2_outlined;
}

bool _containsAny(String text, List<String> keywords) {
  return keywords.any((k) => text.contains(k));
}
