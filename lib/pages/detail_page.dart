import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/item.dart';
import '../utils/formatters.dart';

/// 物品详情页：展示完整信息 + 快速操作（编辑/复制/切换状态）
class DetailPage extends StatelessWidget {
  final Item item;
  const DetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('物品详情'),
        backgroundColor: scheme.surfaceContainerLow,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(context, scheme, textTheme),
          const SizedBox(height: 20),
          _buildActionCard(context, scheme, textTheme),
        ],
      ),
    );
  }

  /// 物品信息卡片
  Widget _buildInfoCard(
      BuildContext context, ColorScheme scheme, TextTheme textTheme) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.inUse ? Colors.green : Colors.grey,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(scheme, textTheme),
            const SizedBox(height: 24),
            _detailRow(context, '购买日期', formatDate(item.purchaseDate)),
            _detailRow(context, '购买价格', '¥${formatPriceCompact(item.price)}'),
            _detailRow(context, '已使用天数', '${item.daysUsed} 天'),
            _detailRow(
                context, '每日成本', '¥${formatCostPerDay(item.costPerDay)}/天'),
            _detailRow(context, '当前状态', item.inUse ? '服役中' : '已退役',
                statusColor: item.inUse ? Colors.green : Colors.grey),
            if (item.warrantyEndDate != null)
              _detailRow(context, '保修到期',
                  item.isWarrantyExpired
                      ? '已过期'
                      : '剩余 ${item.warrantyDaysLeft} 天',
                  statusColor: item.isWarrantyExpired
                      ? Colors.red
                      : item.isWarrantyExpiringSoon
                          ? Colors.orange
                          : Colors.green),
            const SizedBox(height: 8),
            Divider(height: 1, color: scheme.outline.withAlpha(77)),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                title: Text('详细信息',
                    style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600)),
                children: [
                  _infoRow(context, '物品ID', item.id),
                  _infoRow(context, '购买日期(原始)',
                      item.purchaseDate.toIso8601String().split('T')[0]),
                  _infoRow(context, '购买价格(原始)',
                      '¥${item.price.toStringAsFixed(2)}'),
                  _infoRow(context, '每日成本(计算)',
                      '¥${item.costPerDay.toStringAsFixed(4)}'),
                  _infoRow(context, '创建时间', formatDate(item.createdAt)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 头部：图标 + 名称 + ID
  Widget _buildHeader(ColorScheme scheme, TextTheme textTheme) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.category.icon,
              size: 32, color: item.inUse ? item.category.color : scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700, fontSize: 22),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${item.id.substring(0, 8)}...',
                style: textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 快速操作卡片
  Widget _buildActionCard(
      BuildContext context, ColorScheme scheme, TextTheme textTheme) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('快速操作',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _actionButton(context,
                    icon: Icons.edit,
                    label: '编辑',
                    color: scheme.primary,
                    onTap: () => Navigator.pop(context, 'edit')),
                _actionButton(context,
                    icon: Icons.copy,
                    label: '复制信息',
                    color: scheme.secondary,
                    onTap: () => _copyItemInfo(context)),
                _actionButton(context,
                    icon: item.inUse ? Icons.toggle_off : Icons.toggle_on,
                    label: item.inUse ? '设为退役' : '设为服役',
                    color: item.inUse ? Colors.orange : Colors.green,
                    onTap: () => Navigator.pop(context, !item.inUse)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 复制物品信息到剪贴板
  void _copyItemInfo(BuildContext context) {
    final info = '''
物品名称: ${item.name}
购买日期: ${formatDate(item.purchaseDate)}
购买价格: ¥${formatPriceCompact(item.price)}
已使用天数: ${item.daysUsed}天
每日成本: ¥${formatCostPerDay(item.costPerDay)}/天
状态: ${item.inUse ? '服役中' : '已退役'}''';
    Clipboard.setData(ClipboardData(text: info));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('物品信息已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value,
      {Color? statusColor}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant)),
          Text(value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: statusColor ?? scheme.onSurface,
              )),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style:
                    TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                overflow: TextOverflow.ellipsis,
                maxLines: 2),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(onPressed: onTap, icon: Icon(icon, color: color)),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}