import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'excel_repository.dart';

class ExcelFiles {
  Future<ExcelUpload?> pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (file == null) return null;
    final length = await file.length();
    if (length != null && length > 5 * 1024 * 1024) {
      throw Exception('File Excel tối đa 5 MB.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw Exception('Chọn file Excel không rỗng, tối đa 5 MB.');
    }
    return ExcelUpload(file.name, bytes);
  }

  Future<bool> save(Uint8List bytes, String name) async {
    final uri = await FilePicker.saveFile(
      fileName: name,
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    return uri != null;
  }
}
