/// 格式化日期为中文格式：2024年01月05日
String formatDate(DateTime dt) {
  return '${dt.year}年${dt.month.toString().padLeft(2, '0')}月${dt.day.toString().padLeft(2, '0')}日';
}

/// 格式化日期为短格式：24年01月05日
String formatDateShort(DateTime dt) {
  final y = dt.year.toString().substring(2);
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y年$m月$d日';
}

/// 格式化日期为 ISO 短格式：2024-01-05
String formatDateIso(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

/// 格式化价格，带千分位逗号：1,234.56
String formatPrice(double price) {
  final s = price.toStringAsFixed(2);
  final parts = s.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
  return '$whole.${parts[1]}';
}

/// 格式化价格用于详情页展示（大数用"万"单位）
String formatPriceCompact(double price) {
  if (price >= 10000) {
    return '${(price / 10000).toStringAsFixed(1)}万';
  }
  return price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2);
}

/// 格式化日均成本：始终保留 2 位小数
String formatCostPerDay(double cost) {
  return cost.toStringAsFixed(2);
}

/// 格式化为货币字符串：¥1234.56
String currency(double v) => '¥${v.toStringAsFixed(2)}';

/// 格式化日期时间：2024-01-05 14:30
String formatDateTime(DateTime date) {
  return '${formatDateIso(date)} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

/// 格式化文件大小
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
