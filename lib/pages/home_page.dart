import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../store/item_store.dart';
import '../store/theme_store.dart';
import '../utils/formatters.dart';
import 'export_import_page.dart';
import 'widgets/stat_box.dart';
import 'widgets/item_card.dart';
import 'widgets/item_form_sheet.dart';
import 'dialogs/delete_confirm.dart';

/// 应用首页：统计概览 + 物品列表 + 筛选 + 增删改入口
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 当前筛选索引：0=全部, 1=服役, 2=退役
  int _filterIndex = 0;

  /// 搜索关键词
  String _searchQuery = '';

  /// 是否展开搜索栏
  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemStore>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = context.watch<ItemStore>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primaryContainer, scheme.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: _searchExpanded ? 80 : 100),
            if (!_searchExpanded) ...[
              _buildStatCard(context, store),
              if (store.warrantyAlertItems.isNotEmpty)
                _buildWarrantyAlert(context, store),
              const SizedBox(height: 12),
            ],
            _buildFilterBar(store),
            Expanded(child: _buildList(context, store)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showItemFormSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('添加物品'),
      ),
    );
  }

  /// 顶部 AppBar
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: _searchExpanded
          ? TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: '搜索物品名称...',
                border: InputBorder.none,
                hintStyle: GoogleFonts.notoSansSc(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              style: GoogleFonts.notoSansSc(),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            )
          : Text('物品记录', style: GoogleFonts.notoSansSc()),
      centerTitle: !_searchExpanded,
      actions: [
        IconButton(
          icon: Icon(_searchExpanded ? Icons.close : Icons.search),
          tooltip: _searchExpanded ? '关闭搜索' : '搜索',
          onPressed: () {
            setState(() {
              _searchExpanded = !_searchExpanded;
              if (!_searchExpanded) _searchQuery = '';
            });
          },
        ),
        IconButton(
          icon: Icon(switch (context.watch<ThemeStore>().themeMode) {
            ThemeMode.light => Icons.light_mode,
            ThemeMode.dark => Icons.dark_mode,
            _ => Icons.brightness_auto,
          }),
          tooltip: '切换主题（${context.read<ThemeStore>().currentLabel}）',
          onPressed: () => context.read<ThemeStore>().cycleThemeMode(),
        ),
        IconButton(
          icon: const Icon(Icons.backup),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExportImportPage()),
            );
          },
          tooltip: '数据备份与恢复',
        ),
      ],
    );
  }

  /// 统计概览卡片
  Widget _buildStatCard(BuildContext context, ItemStore store) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        color: scheme.primaryContainer.withAlpha(230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatBox(
                      title: '我的资产',
                      value: currency(store.assetSum),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatBox(
                      title: '总购入',
                      value: currency(store.totalPurchase),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MiniStatBox(
                      title: '总日均',
                      value: currency(store.totalDailyCost),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MiniStatBox(
                      title: '最高日均',
                      value: currency(store.maxDailyCost),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MiniStatBox(
                      title: '最低日均',
                      value: currency(store.minDailyCost),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 筛选标签栏 + 排序按钮
  Widget _buildFilterBar(ItemStore store) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  label: Text('${store.items.length} 全部', softWrap: false),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('${store.activeItems.length} 服役', softWrap: false),
                ),
                ButtonSegment(
                  value: 2,
                  label: Text('${store.retiredItems.length} 退役', softWrap: false),
                ),
              ],
              selected: {_filterIndex},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _filterIndex = s.first),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<SortBy>(
            icon: Icon(
              Icons.sort,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            tooltip: '排序',
            onSelected: (sort) => store.setSortBy(sort),
            itemBuilder: (_) => SortBy.values
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          if (s == store.sortBy)
                            Icon(Icons.check,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(s.fullLabel),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  /// 保修提醒横幅
  Widget _buildWarrantyAlert(BuildContext context, ItemStore store) {
    final alerts = store.warrantyAlertItems;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.orange.withAlpha(25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.withAlpha(80)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${alerts.length} 件物品保修即将到期或已过期',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 物品列表
  Widget _buildList(BuildContext context, ItemStore store) {
    if (store.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = switch (_filterIndex) {
      1 => store.activeItems,
      2 => store.retiredItems,
      _ => store.items,
    };

    // 按搜索关键词过滤
    final items = _searchQuery.isEmpty
        ? filtered
        : filtered
            .where((e) =>
                e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    if (items.isEmpty) {
      final colors = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: colors.onSurfaceVariant.withAlpha(80),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无物品',
              style: GoogleFonts.notoSansSc(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右下角按钮添加你的第一件物品',
              style: GoogleFonts.notoSansSc(
                fontSize: 14,
                color: colors.onSurfaceVariant.withAlpha(150),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.arrow_downward_rounded,
              size: 32,
              color: colors.primary.withAlpha(150),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          _buildDismissibleItem(context, items[index]),
    );
  }

  /// 带滑动操作的物品卡片
  Widget _buildDismissibleItem(BuildContext context, item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.horizontal,

        // 右滑背景（切换状态）— 外侧圆角、拼接侧直角
        background: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          child: GestureDetector(
            onTap: () => ItemCard.toggleItemStatus(context, item: item),
            child: Container(
              color: item.inUse ? Colors.grey : Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: Icon(
                item.inUse ? Icons.pause_circle : Icons.check_circle,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ),

        // 左滑背景（删除）— 外侧圆角、拼接侧直角
        secondaryBackground: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          child: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white, size: 36),
          ),
        ),

        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // 右滑到头：切换状态，不移除卡片
            ItemCard.toggleItemStatus(context, item: item);
            return false;
          } else {
            // 左滑：确认删除
            final confirmed = await showDeleteConfirmation(context, item);
            if (confirmed && context.mounted) {
              await context.read<ItemStore>().removeItem(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已删除 "${item.name}"'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            }
            return confirmed;
          }
        },

        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ItemCard(item: item),
        ),
      ),
    );
  }
}
