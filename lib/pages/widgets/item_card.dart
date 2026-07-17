import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/item.dart';
import '../../store/item_store.dart';
import '../../utils/formatters.dart';

import '../detail_page.dart';
import 'item_form_sheet.dart';

/// 物品列表项卡片组件
///
/// 展示物品基本信息，支持点击进入详情、状态切换按钮。
class ItemCard extends StatelessWidget {
  final Item item;

  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.inUse ? Colors.green : Colors.grey,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetail(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.inUse
                      ? item.category.color.withAlpha(20)
                      : scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.category.icon,
                  color: item.inUse ? item.category.color : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildInfo(context)),
              const SizedBox(width: 8),
              _buildStatusBadge(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 跳转到详情页，根据返回值执行编辑或状态切换
  Future<void> _navigateToDetail(BuildContext context) async {
    final store = context.read<ItemStore>();
    final navigator = Navigator.of(context);
    final currentContext = context;

    final result = await navigator.push(
      MaterialPageRoute(builder: (_) => DetailPage(item: item)),
    );

    if (result == 'edit') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showItemFormSheet(currentContext, item: item);
      });
    } else if (result is bool) {
      store.toggleInUse(item.id, result);
    }
  }

  /// 物品名称、日期、价格信息
  Widget _buildInfo(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${formatDateShort(item.purchaseDate)} · ${item.daysUsed}天',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '¥${formatPrice(item.price)} · ¥${item.costPerDay.toStringAsFixed(2)}/天',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 右侧彩色胶囊状态标签（可点击切换）
  Widget _buildStatusBadge(BuildContext context) {
    final isActive = item.inUse;
    return GestureDetector(
      onTap: () => toggleItemStatus(context, item: item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.withAlpha(25) : Colors.grey.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.green : Colors.grey,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.pause_circle,
              size: 14,
              color: isActive ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              isActive ? '服役' : '退役',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 切换服役/退役状态并显示 SnackBar 提示
  static void toggleItemStatus(BuildContext context, {required Item item}) {
    final store = context.read<ItemStore>();
    final newInUse = !item.inUse;
    store.toggleInUse(item.id, newInUse);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已${newInUse ? '标记为服役' : '标记为退役'}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
