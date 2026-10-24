import 'dart:typed_data';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../network/api_client.dart';

class ExcelUpload {
  const ExcelUpload(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

class ExcelResult {
  const ExcelResult({
    required this.totalRows,
    required this.importedRows,
    required this.rows,
    required this.errors,
  });
  final int totalRows, importedRows;
  final List<Map<String, dynamic>> rows, errors;
  factory ExcelResult.fromJson(Map<String, dynamic> json) => ExcelResult(
    totalRows: json['totalRows'] as int,
    importedRows: json['importedRows'] as int,
    rows: (json['rows'] as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList(),
    errors: (json['errors'] as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList(),
  );
}

class ExcelRepository {
  ExcelRepository(this.api, this.module);
  final ApiClient api;
  final String module;

  Future<Uint8List> download({required bool template}) async {
    try {
      final response = await api.getBytes(
        '/$module/excel/${template ? 'template' : 'export'}',
      );
      return Uint8List.fromList((response.data as List).cast<int>());
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is List<int>) {
        try {
          error.response!.data = jsonDecode(utf8.decode(data));
        } on FormatException {
          /* Keep the original response if it is not JSON. */
        }
      }
      rethrow;
    }
  }

  Future<ExcelResult> upload(ExcelUpload file, {required bool preview}) async {
    final data = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes, filename: file.name),
    });
    final response = await api.post(
      '/$module/excel/${preview ? 'preview' : 'import'}',
      data,
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    return ExcelResult.fromJson(Map<String, dynamic>.from(response.data));
  }
}
