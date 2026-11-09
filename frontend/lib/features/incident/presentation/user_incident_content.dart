import 'package:flutter/material.dart';

import '../../../core/layout/app_layout.dart';
import '../../content/presentation/help_widgets.dart';
import '../data/incident_repository.dart';
import 'incident_widgets.dart';

class UserIncidentContent extends StatelessWidget {
  const UserIncidentContent({
    super.key,
    required this.data,
    required this.busy,
    required this.error,
    required this.search,
    required this.status,
    required this.category,
    required this.onCreate,
    required this.onRefresh,
    required this.onGuide,
    required this.onContact,
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
  final VoidCallback onCreate, onRefresh, onGuide, onContact, onSearch, onClear;
  final ValueChanged<String?> onStatus, onCategory;
  final ValueChanged<int> onPage, onDetail;

  Widget _filter(
    String label,
    String? value,
    Map<String, String> options,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String>(
    key: ValueKey('$label-$value'),
    initialValue: value ?? '',
    isExpanded: true,
    decoration: incidentInput(label),
    items: [
      const DropdownMenuItem(value: '', child: Text('Tất cả')),
      for (final entry in options.entries)
        DropdownMenuItem(value: entry.key, child: Text(entry.value)),
    ],
    onChanged: busy ? null : (value) => onChanged(value == '' ? null : value),
  );

  Widget _report(BuildContext context, Incident report) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: IncidentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '#${report.id} · ${incidentCategories[report.category]}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              IncidentStatus(report.status),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            report.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            report.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              height: 1.5,
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Cập nhật ${incidentDate(report.updatedAt)}',
                style: const TextStyle(fontSize: 11),
              ),
              TextButton.icon(
                onPressed: busy ? null : () => onDetail(report.id),
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: const Text('Xem chi tiết'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AppContent(
    maxWidth: 960,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HelpHero(
            title: 'Chúng tôi luôn lắng nghe',
            caption: 'Gửi vấn đề bạn gặp phải và theo dõi phản hồi từ đội ngũ quản trị ngay tại đây.',
            icon: Icons.support_agent_rounded,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: busy ? null : onCreate,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Gửi báo cáo mới',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Làm mới'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Báo cáo của bạn',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              if (data != null)
                Text(
                  '${data!.total}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
            ],
          ),
          const SizedBox(height: 14),
          IncidentPanel(
            child: Column(
              children: [
                TextField(
                  key: const ValueKey('incident-search'),
                  controller: search,
                  enabled: !busy,
                  maxLength: 100,
                  decoration: incidentInput('Tìm tiêu đề hoặc nội dung')
                      .copyWith(
                        counterText: '',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(
                          tooltip: 'Tìm báo cáo',
                          onPressed: busy ? null : onSearch,
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                      ),
                  onSubmitted: (_) => onSearch(),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, box) => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: box.maxWidth >= 540
                            ? (box.maxWidth - 12) / 2
                            : box.maxWidth,
                        child: _filter(
                          'Trạng thái',
                          status,
                          incidentStatuses,
                          onStatus,
                        ),
                      ),
                      SizedBox(
                        width: box.maxWidth >= 540
                            ? (box.maxWidth - 12) / 2
                            : box.maxWidth,
                        child: _filter(
                          'Loại sự cố',
                          category,
                          incidentCategories,
                          onCategory,
                        ),
                      ),
                    ],
                  ),
                ),
                if (status != null ||
                    category != null ||
                    search.text.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: busy ? null : onClear,
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 17),
                      label: const Text('Xóa bộ lọc'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(),
            ),
          if (error != null)
            IncidentPanel(
              child: Column(
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 32),
                  const SizedBox(height: 12),
                  Text(error!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: onRefresh,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          if (data != null && data!.items.isEmpty)
            const IncidentPanel(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Color(0x1415803D),
                    child: Icon(
                      Icons.mark_chat_read_outlined,
                      color: Color(0xFF15803D),
                      size: 30,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có báo cáo phù hợp.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Khi bạn gửi báo cáo, tiến độ và phản hồi sẽ xuất hiện ở đây.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          for (final report in data?.items ?? <Incident>[])
            _report(context, report),
          if (data != null && data!.totalPages > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Trang trước',
                  onPressed: busy || data!.page == 0
                      ? null
                      : () => onPage(data!.page - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Flexible(
                  child: Text(
                    'Trang ${data!.page + 1}/${data!.totalPages}',
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  tooltip: 'Trang sau',
                  onPressed: busy || data!.page + 1 >= data!.totalPages
                      ? null
                      : () => onPage(data!.page + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          const SizedBox(height: 24),
          HelpLink(
            title: 'Hướng dẫn báo sự cố',
            subtitle: 'Chuẩn bị thông tin để được hỗ trợ hiệu quả hơn',
            icon: Icons.help_outline_rounded,
            onTap: onGuide,
          ),
          const SizedBox(height: 10),
          HelpLink(
            title: 'Liên hệ',
            subtitle: 'Xem các kênh liên hệ được công bố',
            icon: Icons.mail_outline_rounded,
            onTap: onContact,
          ),
        ],
      ),
    ),
  );
}
