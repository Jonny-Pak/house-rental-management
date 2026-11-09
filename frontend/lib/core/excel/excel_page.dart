import 'package:flutter/material.dart';

import '../layout/app_layout.dart';
import '../network/api_client.dart';
import '../../features/listing/data/repositories/listing_repository.dart';
import 'excel_files.dart';
import 'excel_repository.dart';

class ExcelPage extends StatefulWidget {
  const ExcelPage({
    super.key,
    required this.module,
    required this.title,
    this.allowImport = true,
    this.repository,
    this.files,
  });
  final String module, title;
  final bool allowImport;
  final ExcelRepository? repository;
  final ExcelFiles? files;
  @override
  State<ExcelPage> createState() => _ExcelPageState();
}

class _ExcelPageState extends State<ExcelPage> {
  late final _repository =
      widget.repository ?? ExcelRepository(ApiClient(), widget.module);
  late final _files = widget.files ?? ExcelFiles();
  bool _busy = false;
  String? _message;
  ExcelUpload? _file;
  ExcelResult? _preview;

  Future<void> _download(bool template) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final bytes = await _repository.download(template: template);
      final name =
          '${template ? 'mau-' : ''}${widget.module == 'contracts' ? 'hop-dong' : 'tin-dang'}.xlsx';
      final saved = await _files.save(bytes, name);
      if (mounted) {
        setState(
          () => _message = saved ? 'Đã lưu file $name.' : 'Đã hủy lưu file.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = ListingRepository.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
      _preview = null;
      _file = null;
    });
    try {
      final file = await _files.pick();
      if (file == null) return;
      final result = await _repository.upload(file, preview: true);
      if (mounted) {
        setState(() {
          _file = file;
          _preview = result;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = ListingRepository.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (_busy ||
        _file == null ||
        _preview == null ||
        _preview!.errors.isNotEmpty ||
        _preview!.totalRows == 0) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await _repository.upload(_file!, preview: false);
      if (!mounted) return;
      if (result.errors.isNotEmpty || result.importedRows != result.totalRows) {
        setState(() {
          _preview = result;
          _message =
              'Chưa nhập dữ liệu. Hãy sửa các dòng lỗi và chọn lại file.';
        });
      } else {
        Navigator.pop(context, result.importedRows);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = ListingRepository.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF8F5),
    appBar: AppBar(title: Text('Excel · ${widget.title}')),
    body: AppContent(
      maxWidth: AppLayout.formWidth,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.table_chart_rounded,
            size: 48,
            color: Color(0xFF387960),
          ),
          const SizedBox(height: 16),
          Text(
            widget.allowImport
                ? 'Nhập và xuất ${widget.title.toLowerCase()}'
                : 'Xuất ${widget.title.toLowerCase()}',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Xuất toàn bộ dữ liệu bạn được phép xem. Bộ lọc trên màn hình danh sách không áp dụng cho file xuất.',
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _download(false),
            icon: const Icon(Icons.download),
            label: const Text('Xuất Excel'),
          ),
          if (widget.allowImport) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _download(true),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Tải file mẫu'),
            ),
            const SizedBox(height: 24),
            Text(
              widget.module == 'contracts'
                  ? 'Hợp đồng nhập mới sẽ chờ người thuê xác nhận; chưa có hiệu lực. Kiểm tra nội dung và thông tin hai bên trước khi nhập.'
                  : 'Tin nhập mới luôn chờ Admin duyệt trước khi xuất hiện công khai.',
            ),
            const SizedBox(height: 10),
            const Text(
              'Dùng file mẫu .xlsx, tối đa 500 dòng và 5 MB. Nếu có dòng lỗi, toàn bộ file chưa được nhập. Không dùng Excel để cập nhật dữ liệu cũ.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.upload_file),
              label: const Text('Chọn file và kiểm tra'),
            ),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_message!, key: const ValueKey('excel-message')),
            ),
          if (_preview != null) ...[
            const SizedBox(height: 24),
            Text(
              _file!.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${_preview!.totalRows} dòng · ${_preview!.errors.length} dòng lỗi',
            ),
            for (final error in _preview!.errors)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: Text('Dòng ${error['row']}'),
                subtitle: Text('${error['message']}'),
              ),
            for (final row in _preview!.rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text('${row['row']}'),
                title: Text('${row['title']}'),
                subtitle: Text('${row['description']}'),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed:
                  _busy ||
                      _preview!.errors.isNotEmpty ||
                      _preview!.totalRows == 0
                  ? null
                  : _import,
              child: Text('Xác nhận nhập ${_preview!.totalRows} dòng'),
            ),
          ],
        ],
      ),
    ),
  );
}
