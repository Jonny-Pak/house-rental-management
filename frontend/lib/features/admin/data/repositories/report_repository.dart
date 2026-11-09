import 'dart:typed_data';

import '../../../../core/network/api_client.dart';

class ReportDay {
  ReportDay(Map<String, dynamic> json)
    : date = DateTime.parse(json['date']),
      members = (json['members'] as num).toInt(),
      listings = (json['listings'] as num).toInt(),
      contracts = (json['contracts'] as num).toInt(),
      revenue = (json['revenue'] as num).toDouble();
  final DateTime date;
  final int members, listings, contracts;
  final double revenue;
}

class ReportData {
  ReportData(Map<String, dynamic> json)
    : from = DateTime.parse(json['from']),
      to = DateTime.parse(json['to']),
      generatedAt = DateTime.parse(json['generatedAt']),
      members = (json['members'] as num).toInt(),
      listings = (json['listings'] as num).toInt(),
      contracts = (json['contracts'] as num).toInt(),
      revenue = (json['revenue'] as num).toDouble(),
      successfulPayments = (json['successfulPayments'] as num).toInt() {
    for (final day in json['daily']) {
      daily.add(ReportDay(Map<String, dynamic>.from(day)));
    }
    for (final item in json['listingStatuses']) {
      listingStatuses[item['status']] = (item['count'] as num).toInt();
    }
    for (final item in json['contractStatuses']) {
      contractStatuses[item['status']] = (item['count'] as num).toInt();
    }
  }
  final DateTime from, to, generatedAt;
  final int members, listings, contracts, successfulPayments;
  final double revenue;
  final daily = <ReportDay>[];
  final listingStatuses = <String, int>{};
  final contractStatuses = <String, int>{};
}

String reportDate(DateTime value) => value.toIso8601String().substring(0, 10);

class ReportRepository {
  ReportRepository(this.api);
  final ApiClient api;
  Future<ReportData> load(DateTime from, DateTime to) async {
    final response = await api.get(
      '/admin/reports',
      queryParams: {'from': reportDate(from), 'to': reportDate(to)},
    );
    return ReportData(Map<String, dynamic>.from(response.data['data']));
  }

  Future<Uint8List> export(DateTime from, DateTime to) async {
    final response = await api.getBytes(
      '/admin/reports/export?from=${reportDate(from)}&to=${reportDate(to)}',
    );
    return Uint8List.fromList(List<int>.from(response.data));
  }
}
