import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/item.dart';
import '../utils/formatters.dart';

/// 数据导出/导入服务。
///
/// 负责将物品数据序列化为 JSON/CSV 文件，以及从 JSON 文件反序列化。
class ExportService {
  static const _currentVersion = '1.0';

  /// 将物品列表导出为 JSON 文件，返回文件路径。
  static Future<String> exportToJson(List<Item> items) async {
    final exportData = {
      'version': _currentVersion,
      'exportTime': DateTime.now().toIso8601String(),
      'itemCount': items.length,
      'items': items.map((item) => item.toMap()).toList(),
    };

    final jsonString = JsonEncoder.withIndent('  ').convert(exportData);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/traejiwu_backup_$timestamp.json';

    final file = File(filePath);
    await file.writeAsString(jsonString, encoding: utf8);

    return filePath;
  }

  /// 将物品列表导出为 CSV 文件（方便 Excel 打开），返回文件路径。
  static Future<String> exportToCsv(List<Item> items) async {
    final buffer = StringBuffer();
    // BOM + 表头
    buffer.write('﻿');
    buffer.writeln('名称,分类,购买日期,购买价格,已使用天数,日均成本,状态,创建时间');

    for (final item in items) {
      final row = [
        _escapeCsv(item.name),
        item.category.label,
        formatDateIso(item.purchaseDate),
        item.price.toStringAsFixed(2),
        item.daysUsed.toString(),
        item.costPerDay.toStringAsFixed(2),
        item.inUse ? '服役' : '退役',
        formatDateIso(item.createdAt),
      ];
      buffer.writeln(row.join(','));
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/traejiwu_export_$timestamp.csv';

    final file = File(filePath);
    await file.writeAsString(buffer.toString(), encoding: utf8);

    return filePath;
  }

  /// 通过系统分享功能分享导出文件。
  static Future<void> shareExportFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await SharePlus.instance.share(ShareParams(files: [XFile(filePath)], text: 'Traejiwu 数据备份'));
    }
  }

  /// 从 JSON 文件导入物品列表。
  ///
  /// 校验文件版本和数据格式，对非法数据抛出 [FormatException]。
  static Future<List<Item>> importFromJson(String filePath) async {
    final items = await _parseItemsFromFile(filePath);
    debugPrint('[ExportService] 导入成功，共 ${items.length} 条物品');
    return items;
  }

  /// 预览导入文件的元信息（物品数量、总价值等），不执行实际导入。
  static Future<Map<String, dynamic>> previewImportFile(
      String filePath) async {
    final file = File(filePath);
    final jsonString = await file.readAsString(encoding: utf8);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    _validateVersion(data);

    final items = _parseItemsFromData(data);

    final inUseCount = items.where((item) => item.inUse).length;
    final totalPrice = items.fold(0.0, (sum, item) => sum + item.price);
    final exportTime = DateTime.parse(data['exportTime'] as String);

    return {
      'itemCount': items.length,
      'inUseCount': inUseCount,
      'retiredCount': items.length - inUseCount,
      'totalPrice': totalPrice,
      'exportTime': exportTime,
      'fileName': path.basename(file.path),
      'fileSize': await file.length(),
    };
  }

  // ── 内部方法 ──

  /// CSV 字段转义：含逗号/引号/换行的字段用双引号包裹
  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// 校验备份文件版本
  static void _validateVersion(Map<String, dynamic> data) {
    if (data['version'] != _currentVersion) {
      throw const FormatException('不支持的备份文件版本，请使用最新版本导出的文件');
    }
  }

  /// 从文件读取并解析物品列表
  static Future<List<Item>> _parseItemsFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString(encoding: utf8);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      _validateVersion(data);

      return _parseItemsFromData(data);
    } on FormatException {
      rethrow;
    } catch (e) {
      throw Exception('导入失败: $e');
    }
  }

  /// 从已解析的 JSON 数据中提取物品列表
  static List<Item> _parseItemsFromData(Map<String, dynamic> data) {
    final itemsData = data['items'] as List<dynamic>;
    final items = <Item>[];

    for (int i = 0; i < itemsData.length; i++) {
      final itemData = itemsData[i];
      try {
        if (itemData is String) {
          // 兼容旧格式：字符串形式的 JSON
          final itemMap = jsonDecode(itemData) as Map<String, dynamic>;
          items.add(Item.fromMap(itemMap));
        } else if (itemData is Map<String, dynamic>) {
          items.add(Item.fromMap(itemData));
        } else {
          throw const FormatException('无效的物品数据格式');
        }
      } on FormatException catch (e) {
        debugPrint('[ExportService] 跳过第 ${i + 1} 条数据: $e');
        // 继续解析其余数据，而非全部失败
      }
    }

    return items;
  }
}