import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/excel/excel_files.dart';
import '../../../../content/data/repositories/system_content_repository.dart'
    show contentError;
import '../../../data/repositories/report_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.repository, this.files});
  final ReportRepository? repository;
  final ExcelFiles? files;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final _repository = widget.repository ?? ReportRepository(ApiClient());
  late final _files = widget.files ?? ExcelFiles();
  late DateTime _from, _to;
  ReportData? _report;
  bool _loading = false, _exporting = false;
  String? _error;
  int _page = 0;
  static const _accent = Color(0xFF15803D);
  static const _green = Color(0xFF298774);
  final _number = NumberFormat.decimalPattern('vi_VN');
  String _money(num value) => '${_number.format(value)} ₫';
  String _date(DateTime value) => DateFormat('dd/MM/yyyy').format(value);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = DateTime(now.year, now.month, 1);
    _load();
  }

  Future<void> _load() async {
    if (_loading || _exporting) return;
    setState(() {
      _loading = true;
      _error = null;
      _report = null;
    });
    try {
      final report = await _repository.load(_from, _to);
      if (mounted) {
        setState(() {
          _report = report;
          _page = 0;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = contentError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chooseDates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      helpText: 'Chọn khoảng báo cáo (tối đa 366 ngày)',
      saveText: 'Áp dụng',
    );
    if (range == null || !mounted) return;
    if (range.end.difference(range.start).inDays > 365) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chọn tối đa 366 ngày.')));
      return;
    }
    setState(() {
      _from = range.start;
      _to = range.end;
    });
    await _load();
  }

  Future<void> _export() async {
    final report = _report;
    if (report == null || _loading || _exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _repository.export(report.from, report.to);
      if (!mounted) return;
      final saved = await _files.save(
        bytes,
        'bao-cao-${reportDate(report.from)}-${reportDate(report.to)}.xlsx',
      );
      if (mounted && saved) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xuất báo cáo Excel.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(contentError(error))));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _panel(String title, Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: .15),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );

  Widget _metric(String label, String value, IconData icon, double width) =>
      SizedBox(
        width: width,
        child: _panel(
          label,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: _accent),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );

  String _status(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ duyệt';
      case 'APPROVED':
        return 'Đã duyệt';
      case 'REJECTED':
        return 'Bị từ chối';
      case 'DRAFT':
        return 'Bản nháp';
      case 'ACTIVE':
        return 'Đang hiệu lực';
      case 'EXPIRED':
        return 'Hết hạn';
      case 'TERMINATED':
        return 'Đã chấm dứt';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Widget _statuses(String title, Map<String, int> items) => _panel(
    title,
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty) const Text('Chưa có dữ liệu trong khoảng đã chọn.'),
        for (final item in items.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text(_status(item.key))),
                Text(
                  _number.format(item.value),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _green,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _revenue(ReportData report) {
    final months = <String, double>{};
    double largest = 0;
    for (final day in report.daily) {
      final month = DateFormat('MM/yyyy').format(day.date);
      months[month] = (months[month] ?? 0) + day.revenue;
      if (months[month]! > largest) largest = months[month]!;
    }
    return _panel(
      'Doanh thu dịch vụ theo tháng',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${report.successfulPayments} giao dịch thành công trong khoảng đã chọn',
          ),
          if (report.revenue == 0)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Chưa phát sinh doanh thu dịch vụ.'),
            ),
          for (final month in months.entries)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    children: [Text(month.key), Text(_money(month.value))],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: largest == 0 ? 0 : month.value / largest,
                    minHeight: 10,
                    color: _accent,
                    borderRadius: BorderRadius.circular(6),
                    backgroundColor: _accent.withValues(alpha: .1),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _daily(ReportData report) {
    final start = _page * 10;
    int end = start + 10;
    if (end > report.daily.length) end = report.daily.length;
    return _panel(
      'Chi tiết theo ngày',
      Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Ngày')),
                DataColumn(label: Text('Member mới')),
                DataColumn(label: Text('Tin mới')),
                DataColumn(label: Text('Hợp đồng mới')),
                DataColumn(label: Text('Doanh thu dịch vụ')),
              ],
              rows: [
                for (final day in report.daily.sublist(start, end))
                  DataRow(
                    cells: [
                      DataCell(Text(_date(day.date))),
                      DataCell(Text('${day.members}')),
                      DataCell(Text('${day.listings}')),
                      DataCell(Text('${day.contracts}')),
                      DataCell(Text(_money(day.revenue))),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: [
              IconButton(
                tooltip: 'Trang trước',
                onPressed: _page == 0 ? null : () => setState(() => _page--),
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Trang ${_page + 1}/${(report.daily.length / 10).ceil()}'),
              IconButton(
                tooltip: 'Trang sau',
                onPressed: end >= report.daily.length
                    ? null
                    : () => setState(() => _page++),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _results(ReportData report, double width) {
    final metricWidth = width >= 1100
        ? (width - 48) / 4
        : width >= 600
        ? (width - 16) / 2
        : width;
    final columns = width >= 900;
    final listing = _statuses(
      'Tin tạo trong kỳ · trạng thái hiện tại',
      report.listingStatuses,
    );
    final contracts = _statuses(
      'Hợp đồng tạo trong kỳ · trạng thái hiện tại',
      report.contractStatuses,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _metric(
              'Doanh thu dịch vụ',
              _money(report.revenue),
              Icons.payments_outlined,
              metricWidth,
            ),
            _metric(
              'Member đăng ký mới',
              _number.format(report.members),
              Icons.people_outline,
              metricWidth,
            ),
            _metric(
              'Tin đăng tạo mới',
              _number.format(report.listings),
              Icons.home_work_outlined,
              metricWidth,
            ),
            _metric(
              'Hợp đồng tạo mới',
              _number.format(report.contracts),
              Icons.description_outlined,
              metricWidth,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Dữ liệu từ ${_date(report.from)} đến ${_date(report.to)} (bao gồm cả hai ngày). Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(report.generatedAt)}.',
        ),
        const SizedBox(height: 10),
        const Text(
          'Doanh thu tính giao dịch SUCCESS theo ngày tạo giao dịch, không gồm tiền thuê và tiền cọc. Trạng thái dưới đây là trạng thái hiện tại của bản ghi tạo trong kỳ, không phải lịch sử tại ngày kết thúc.',
          style: TextStyle(fontSize: 12, height: 1.6),
        ),
        const SizedBox(height: 20),
        _revenue(report),
        const SizedBox(height: 20),
        if (columns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: listing),
              const SizedBox(width: 20),
              Expanded(child: contracts),
            ],
          )
        else ...[
          listing,
          const SizedBox(height: 20),
          contracts,
        ],
        const SizedBox(height: 20),
        _daily(report),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final padding = box.maxWidth < 650 ? 16.0 : 28.0;
      final busy = _loading || _exporting;
      return SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Thống kê & báo cáo',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('Theo dõi hoạt động từ dữ liệu hệ thống.'),
            const SizedBox(height: 22),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : _chooseDates,
                  icon: const Icon(Icons.date_range),
                  label: Text('${_date(_from)} – ${_date(_to)}'),
                ),
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () {
                          final now = DateTime.now();
                          setState(() {
                            _to = DateTime(now.year, now.month, now.day);
                            _from = _to.subtract(const Duration(days: 29));
                          });
                          _load();
                        },
                  child: const Text('30 ngày gần nhất'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Làm mới'),
                ),
                FilledButton.icon(
                  onPressed: busy || _report == null ? null : _export,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(_exporting ? 'Đang xuất...' : 'Xuất Excel'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              _panel(
                'Không tải được báo cáo',
                Column(
                  children: [
                    Text(_error!),
                    TextButton(onPressed: _load, child: const Text('Thử lại')),
                  ],
                ),
              ),
            if (_report != null) _results(_report!, box.maxWidth - padding * 2),
          ],
        ),
      );
    },
  );
}
