import 'package:frontend/core/theme/app_colors.dart';

import 'package:flutter/material.dart';

import '../../../core/layout/app_layout.dart';
import '../data/incident_repository.dart';
import 'incident_widgets.dart';

class AdminIncidentContent extends StatelessWidget {
  const AdminIncidentContent({
    super.key,
    required this.data,
    required this.busy,
    required this.error,
    required this.search,
    required this.status,
    required this.category,
    required this.onRefresh,
    required this.onSearch,
    required this.onStatus,
    required this.onCategory,
    required this.onClear,
    required this.onPage,
    required this.onDetail,
  });
  final IncidentPageData? data;
  final bool busy;
  final String? error, status, category;
  final TextEditingController search;
  final VoidCallback onRefresh, onSearch, onClear;
  final ValueChanged<String?> onStatus, onCategory;
  final ValueChanged<int> onPage, onDetail;

  Color _statusColor(BuildContext context, String value) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (value) {
      case 'IN_PROGRESS':
        return dark ? const Color(0xFF9EC7FA) : const Color(0xFF397AC0);
      case 'RESOLVED':
        return dark ? const Color(0xFF86E0A1) : AppColors.primary;
      case 'REJECTED':
        return dark ? const Color(0xFFEE9C9C) : const Color(0xFFB34F4F);
      default:
        return dark ? const Color(0xFFE8C476) : const Color(0xFF9A7427);
    }
  }

  Widget _status(BuildContext context, String value) {
    final color = _statusColor(context, value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 6),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              incidentStatuses[value] ?? value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String value) {
    switch (value) {
      case 'ACCOUNT':
        return Icons.person_outline_rounded;
      case 'LISTING':
        return Icons.home_work_outlined;
      case 'CONTRACT':
        return Icons.description_outlined;
      case 'PAYMENT':
        return Icons.payments_outlined;
      case 'TECHNICAL':
        return Icons.build_outlined;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  Widget _panel(BuildContext context, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: Theme.of(context).colorScheme.outlineVariant
            .withValues(alpha: .5),
      ),
    ),
    child: child,
  );

  InputDecoration _input(BuildContext context, String label) => InputDecoration(
    labelText: label,
    counterText: '',
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant
            .withValues(alpha: .6),
      ),
    ),
  );

  Widget _filter(
    BuildContext context,
    String label,
    String? value,
    Map<String, String> options,
    ValueChanged<String?> changed,
  ) => DropdownButtonFormField<String>(
    key: ValueKey('$label-$value'),
    initialValue: value ?? '',
    isExpanded: true,
    decoration: _input(context, label),
    items: [
      const DropdownMenuItem(value: '', child: Text('Tất cả')),
      for (final entry in options.entries)
        DropdownMenuItem(value: entry.key, child: Text(entry.value)),
    ],
    onChanged: busy ? null : (value) => changed(value == '' ? null : value),
  );

  Widget _header(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    spacing: 20,
    runSpacing: 18,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRUNG TÂM HỖ TRỢ',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.7,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Xử lý báo cáo sự cố',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tiếp nhận phản hồi, theo dõi tiến độ và hỗ trợ người dùng.',
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
      OutlinedButton.icon(
        onPressed: busy ? null : onRefresh,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Làm mới'),
      ),
    ],
  );

  Widget _filters(BuildContext context) => _panel(
    context,
    LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 1100;
        return Wrap(
          spacing: 14,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: wide ? box.maxWidth - 634 : box.maxWidth,
              child: TextField(
                key: const ValueKey('incident-search'),
                controller: search,
                enabled: !busy,
                maxLength: 100,
                decoration: _input(context, 'Tìm tiêu đề hoặc nội dung')
                    .copyWith(
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: IconButton(
                        tooltip: 'Tìm báo cáo',
                        onPressed: busy ? null : onSearch,
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ),
                onSubmitted: (_) => onSearch(),
              ),
            ),
            SizedBox(
              width: box.maxWidth < 600 ? box.maxWidth : 240,
              child: _filter(
                context,
                'Trạng thái',
                status,
                incidentStatuses,
                onStatus,
              ),
            ),
            SizedBox(
              width: box.maxWidth < 600 ? box.maxWidth : 230,
              child: _filter(
                context,
                'Loại sự cố',
                category,
                incidentCategories,
                onCategory,
              ),
            ),
            TextButton(
              onPressed: busy ? null : onClear,
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        );
      },
    ),
  );

  Widget _empty(BuildContext context) => _panel(
    context,
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: .07),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: .15),
                  ),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Chưa có báo cáo phù hợp.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            status != null || category != null || search.text.isNotEmpty
                ? 'Thử thay đổi từ khóa hoặc bộ lọc để tìm báo cáo cần xử lý.'
                : 'Báo cáo được gửi từ ứng dụng sẽ hiển thị tại đây để Admin tiếp nhận và phản hồi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (status != null || category != null || search.text.isNotEmpty) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: busy ? null : onClear,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Xem tất cả báo cáo'),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _open(Incident report) => TextButton.icon(
    onPressed: busy ? null : () => onDetail(report.id),
    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
    label: const Text('Xem và xử lý'),
  );

  Widget _reporter(BuildContext context, Incident report) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFF617FB1).withValues(alpha: .09),
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(
          Icons.person_outline_rounded,
          size: 18,
          color: Color(0xFF617FB1),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.reporterName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 5),
            Tooltip(
              message: report.reporterEmail,
              child: Text(
                report.reporterEmail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _list(BuildContext context, double width) {
    if (data!.items.isEmpty) return _empty(context);
    final colors = Theme.of(context).colorScheme;
    if (width >= 1100) {
      return _panel(
        context,
        LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: box.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  colors.onSurface.withValues(alpha: .025),
                ),
                headingTextStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
                headingRowHeight: 48,
                dataRowMinHeight: 104,
                dataRowMaxHeight: 120,
                dividerThickness: .5,
                horizontalMargin: 16,
                columnSpacing: 22,
                columns: const [
                  DataColumn(label: Text('BÁO CÁO')),
                  DataColumn(label: Text('NGƯỜI GỬI')),
                  DataColumn(label: Text('LOẠI SỰ CỐ')),
                  DataColumn(label: Text('TRẠNG THÁI')),
                  DataColumn(label: Text('CẬP NHẬT')),
                  DataColumn(label: Text('THAO TÁC')),
                ],
                rows: [
                  for (final report in data!.items)
                    DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 250,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BC #${report.id}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  report.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  report.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 190,
                            child: _reporter(context, report),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _categoryIcon(report.category),
                                size: 16,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                incidentCategories[report.category] ??
                                    report.category,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        DataCell(_status(context, report.status)),
                        DataCell(
                          Text(
                            incidentDate(report.updatedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        DataCell(_open(report)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final report in data!.items)
          _panel(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Text(
                      'Báo cáo #${report.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                    _status(context, report.status),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(height: 1.5, color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Divider(color: colors.outlineVariant.withValues(alpha: .5)),
                const SizedBox(height: 12),
                _reporter(context, report),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      incidentCategories[report.category] ?? report.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Cập nhật: ${incidentDate(report.updatedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: _open(report)),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF141A1D)
        : const Color(0xFFF6F8FA),
    child: AppContent(
      maxWidth: 1500,
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              const SizedBox(height: 26),
              _filters(context),
              if (busy) const LinearProgressIndicator(),
              if (error != null)
                _panel(
                  context,
                  Column(
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Color(0xFF697586),
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(error!, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: busy ? null : onSearch,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              if (data != null) ...[
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      '${data!.total} báo cáo phù hợp',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Danh sách tiếp nhận',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _list(context, box.maxWidth),
                if (data!.items.isNotEmpty)
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    children: [
                      IconButton(
                        tooltip: 'Trang trước',
                        onPressed: busy || data!.page == 0
                            ? null
                            : () => onPage(data!.page - 1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('Trang ${data!.page + 1}/${data!.totalPages}'),
                      IconButton(
                        tooltip: 'Trang sau',
                        onPressed: busy || data!.page + 1 >= data!.totalPages
                            ? null
                            : () => onPage(data!.page + 1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
