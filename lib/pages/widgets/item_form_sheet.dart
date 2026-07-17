import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../models/item.dart';
import '../../store/item_store.dart';
import '../../utils/date_picker.dart';
import '../../utils/formatters.dart';

/// 统一的物品添加/编辑表单 BottomSheet
///
/// [item] 为 null 时为添加模式，否则为编辑模式。
Future<void> showItemFormSheet(BuildContext context, {Item? item}) async {
  final store = context.read<ItemStore>();
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController(text: item?.name ?? '');
  final priceCtrl = TextEditingController(text: item?.price.toString() ?? '');
  DateTime date = item?.purchaseDate ?? DateTime.now();
  bool inUse = item?.inUse ?? true;
  Category category = item?.category ?? Category.other;
  DateTime? warrantyEndDate = item?.warrantyEndDate;
  final isEditing = item != null;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 拖拽条（BottomSheet 标准手势指示器）
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant.withAlpha(80),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: '名称',
                          hintText: '请输入名称',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? '请输入名称' : null,
                      ),
                      const SizedBox(height: 12),
                      // 分类选择
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: Category.values.map((c) {
                            final selected = c == category;
                            return ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(c.icon, size: 16, color: selected ? Colors.white : c.color),
                                  const SizedBox(width: 4),
                                  Text(c.label),
                                ],
                              ),
                              selected: selected,
                              selectedColor: c.color,
                              onSelected: (_) {
                                setModalState(() => category = c);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceCtrl,
                        decoration: const InputDecoration(
                          labelText: '购买价格',
                          hintText: '0.00',
                          prefixText: '¥',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return '请输入价格';
                          final p = double.tryParse(v);
                          if (p == null || p <= 0) return '价格需为正数';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: Text('购买日期 ${formatDate(date)}')),
                          TextButton(
                            onPressed: () async {
                              final picked =
                                  await showChineseDatePicker(ctx, date);
                              if (picked != null) {
                                setModalState(() {
                                  date = picked;
                                });
                              }
                            },
                            child: const Text('选择日期'),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        value: inUse,
                        onChanged: (v) {
                          setModalState(() {
                            inUse = v;
                          });
                        },
                        title: const Text('是否在用'),
                      ),
                      const SizedBox(height: 12),
                      // 保修到期日期（可选）
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              warrantyEndDate != null
                                  ? '保修到期 ${formatDate(warrantyEndDate!)}'
                                  : '保修到期（未设置）',
                            ),
                          ),
                          if (warrantyEndDate != null)
                            TextButton(
                              onPressed: () {
                                setModalState(() => warrantyEndDate = null);
                              },
                              child: const Text('清除'),
                            ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showChineseDatePicker(
                                  ctx, warrantyEndDate ?? date);
                              if (picked != null) {
                                setModalState(() => warrantyEndDate = picked);
                              }
                            },
                            child: const Text('选择日期'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final name = nameCtrl.text.trim();
                          final price = double.parse(priceCtrl.text.trim());
                          final navigator = Navigator.of(ctx);

                          if (isEditing) {
                            final updated = item.copyWith(
                              name: name,
                              purchaseDate: date,
                              price: price,
                              inUse: inUse,
                              category: category,
                              warrantyEndDate: warrantyEndDate,
                            );
                            await store.updateItem(updated);
                          } else {
                            await store.addItem(name, date, price, inUse,
                                category: category,
                                warrantyEndDate: warrantyEndDate);
                          }

                          if (navigator.canPop()) navigator.pop();
                        },
                        icon: const Icon(Icons.check),
                        label: Text(isEditing ? '保存' : '添加'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
