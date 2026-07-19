import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../store/item_store.dart';
import '../services/export_service.dart';
import '../utils/formatters.dart' as fmt;

class ExportImportPage extends StatefulWidget {
  const ExportImportPage({super.key});

  @override
  State<ExportImportPage> createState() => _ExportImportPageState();
}

class _ExportImportPageState extends State<ExportImportPage> {
  String? _selectedFilePath;
  Map<String, dynamic>? _importPreview;
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportData({bool csv = false}) async {
    if (!mounted) return;

    final itemStore = Provider.of<ItemStore>(context, listen: false);

    setState(() {
      _isExporting = true;
    });

    try {
      final filePath = csv
          ? await ExportService.exportToCsv(itemStore.items)
          : await ExportService.exportToJson(itemStore.items);

      await ExportService.shareExportFile(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出完成（${csv ? "CSV" : "JSON"}），文件已保存'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _selectImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path!;
        setState(() {
          _selectedFilePath = filePath;
          _importPreview = null;
        });

        try {
          final preview = await ExportService.previewImportFile(filePath);
          if (mounted) {
            setState(() {
              _importPreview = preview;
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('预览文件失败: $e')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  Future<void> _importData() async {
    if (_selectedFilePath == null || !mounted) return;

    final itemStore = Provider.of<ItemStore>(context, listen: false);
    
    setState(() {
      _isImporting = true;
    });

    try {
      final items = await ExportService.importFromJson(_selectedFilePath!);
      await itemStore.replaceAllItems(items);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导入成功')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据备份与恢复'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 导出部分
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '导出数据',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '将当前所有物品数据导出为 JSON 文件，可用于备份或迁移到其他设备。',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isExporting ? null : () => _exportData(),
                              icon: _isExporting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.download),
                              label: _isExporting
                                  ? const Text('导出中...')
                                  : const Text('JSON 备份'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isExporting ? null : () => _exportData(csv: true),
                              icon: const Icon(Icons.table_chart),
                              label: const Text('CSV 导出'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 导入部分
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '导入数据',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '从 JSON 备份文件导入数据，将替换当前所有物品数据。',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      // 文件选择
                      OutlinedButton.icon(
                        onPressed: _selectImportFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('选择备份文件'),
                      ),

                      if (_selectedFilePath != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          '已选择: ${_selectedFilePath!.split(Platform.pathSeparator).last}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],

                      // 预览信息
                      if (_importPreview != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '备份文件信息',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildPreviewItem('文件大小', fmt.formatFileSize(_importPreview!['fileSize'] as int)),
                              _buildPreviewItem('物品总数', '${_importPreview!['itemCount']} 个'),
                              _buildPreviewItem('服役中', '${_importPreview!['inUseCount']} 个'),
                              _buildPreviewItem('已退役', '${_importPreview!['retiredCount']} 个'),
                              _buildPreviewItem('总价值', '¥${(_importPreview!['totalPrice'] as double).toStringAsFixed(2)}'),
                              _buildPreviewItem('备份时间', fmt.formatDateTime(_importPreview!['exportTime'] as DateTime)),
                            ],
                          ),
                        ),

                        // 导入按钮
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedFilePath = null;
                                    _importPreview = null;
                                  });
                                },
                                child: const Text('取消'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isImporting ? null : _importData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  foregroundColor: Theme.of(context).colorScheme.onError,
                                ),
                                child: _isImporting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('确认导入'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 注意事项
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.errorContainer.withAlpha(76),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '重要提示',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• 导入数据将完全替换当前所有物品数据，请谨慎操作\n'
                      '• 建议在导入前先导出当前数据作为备份\n'
                      '• 仅支持从本应用导出的 JSON 格式备份文件\n'
                      '• 导入后无法撤销，请确认备份文件内容正确',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

}