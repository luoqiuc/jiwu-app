import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 计算指定年月的天数
int daysInMonth(int year, int month) {
  final nextMonth = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
  final lastDay = nextMonth.subtract(const Duration(days: 1));
  return lastDay.day;
}

/// 显示中文风格的年月日三列滚轮选择器
///
/// 返回用户选择的 [DateTime]，取消则返回 null。
Future<DateTime?> showChineseDatePicker(BuildContext context, DateTime initial) async {
  int year = initial.year;
  int month = initial.month;
  int day = initial.day;
  final now = DateTime.now();
  final years = List<int>.generate(now.year - 1970 + 1, (i) => 1970 + i);
  final months = List<int>.generate(12, (i) => i + 1);
  int maxDay = daysInMonth(year, month);
  day = day.clamp(1, maxDay);

  final yearCtrl = FixedExtentScrollController(initialItem: years.indexOf(year));
  final monthCtrl = FixedExtentScrollController(initialItem: month - 1);
  final dayCtrl = FixedExtentScrollController(initialItem: day - 1);

  DateTime? result;
  await showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) {
      return Container(
        height: 340,
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      result = DateTime(year, month, day);
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: yearCtrl,
                      itemExtent: 36,
                      onSelectedItemChanged: (i) {
                        HapticFeedback.selectionClick();
                        year = years[i];
                        final newMax = daysInMonth(year, month);
                        if (day > newMax) {
                          day = newMax;
                          dayCtrl.jumpToItem(day - 1);
                        }
                      },
                      children: years.map((y) => Center(child: Text('$y年'))).toList(),
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: monthCtrl,
                      itemExtent: 36,
                      onSelectedItemChanged: (i) {
                        HapticFeedback.selectionClick();
                        month = months[i];
                        final newMax = daysInMonth(year, month);
                        if (day > newMax) {
                          day = newMax;
                          dayCtrl.jumpToItem(day - 1);
                        }
                      },
                      children: months.map((m) => Center(child: Text('$m月'))).toList(),
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: dayCtrl,
                      itemExtent: 36,
                      onSelectedItemChanged: (i) {
                        HapticFeedback.selectionClick();
                        day = i + 1;
                      },
                      children: List<int>.generate(maxDay, (i) => i + 1)
                          .map((d) => Center(child: Text('$d日')))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
  return result;
}
