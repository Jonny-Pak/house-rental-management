import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/layout/app_layout.dart';
import '../../content/data/repositories/system_content_repository.dart';
import '../../content/presentation/system_content_page.dart';
import '../data/incident_repository.dart';
import 'create_incident_page.dart';
import 'incident_detail_page.dart';
import 'incident_widgets.dart';

class IncidentsPage extends StatefulWidget {
  const IncidentsPage({
    super.key,
    this.admin = false,
    this.repository,
    this.contentRepository,
  });
  final bool admin;
  final IncidentRepository? repository;
  final SystemContentRepository? contentRepository;
  @override
  State<IncidentsPage> createState() => _IncidentsPageState();
}

class _IncidentsPageState extends State<IncidentsPage> {
  late final _repository = widget.repository ?? IncidentRepository(ApiClient());
  final _search = TextEditingController();
  IncidentPageData? _data;
  String? _status, _category, _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load([int page = 0]) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _repository.fetch(
        admin: widget.admin,
        query: _search.text,
        status: _status,
        category: _category,
        page: page,
      );
      if (mounted) setState(() => _data = result);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = incidentError(error);
          _data = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _detail(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidentDetailPage(
          id: id,
          admin: widget.admin,
          repository: _repository,
        ),
      ),
    );
    if (mounted) await _load(_data?.page ?? 0);
  }

  Future<void> _create() async {
    final report = await Navigator.push<Incident>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateIncidentPage(repository: _repository),
      ),
    );
    if (report == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã tiếp nhận báo cáo #${report.id}.')),
    );
    await _load();
    if (mounted) await _detail(report.id);
  }

  Widget _filter(
    String label,
    String? selected,
    Map<String, String> values,
    ValueChanged<String?> onChanged,
  ) => SizedBox(
    width: 240,
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label-$selected'),
      initialValue: selected ?? '',
      isExpanded: true,
      decoration: incidentInput(label),
      items: [
        const DropdownMenuItem(value: '', child: Text('Tất cả')),
        for (final entry in values.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: _busy
          ? null
          : (value) {
              onChanged(value == '' ? null : value);
              _load();
            },
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFF8F9FB)
        : null,
    appBar: widget.admin
        ? null
        : AppBar(title: const Text('Báo cáo sự cố của tôi')),
    body: AppContent(
      maxWidth: widget.admin ? 1300 : 860,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IncidentHeader(
              title: widget.admin
                  ? 'Xử lý báo cáo sự cố'
                  : 'Cần hỗ trợ điều gì?',
              description: widget.admin
                  ? 'Tiếp nhận, phản hồi và theo dõi tiến độ hỗ trợ người dùng.'
                  : 'Gửi báo cáo và theo dõi phản hồi từ Admin tại đây.',
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (!widget.admin)
                  FilledButton.icon(
                    onPressed: _busy ? null : _create,
                    icon: const Icon(Icons.add),
                    label: const Text('Gửi báo cáo mới'),
                  ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Làm mới'),
                ),
                if (!widget.admin)
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SystemContentPage(
                          slug: 'support',
                          repository: widget.contentRepository,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Hướng dẫn báo sự cố'),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            IncidentPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const ValueKey('incident-search'),
                    controller: _search,
                    enabled: !_busy,
                    maxLength: 100,
                    decoration: incidentInput('Tìm tiêu đề hoặc nội dung')
                        .copyWith(
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            tooltip: 'Tìm báo cáo',
                            onPressed: _busy ? null : () => _load(),
                            icon: const Icon(Icons.arrow_forward),
                          ),
                        ),
                    onSubmitted: (_) => _load(),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _filter(
                        'Trạng thái',
                        _status,
                        incidentStatuses,
                        (value) => setState(() => _status = value),
                      ),
                      _filter(
                        'Loại sự cố',
                        _category,
                        incidentCategories,
                        (value) => setState(() => _category = value),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () {
                                setState(() {
                                  _status = null;
                                  _category = null;
                                  _search.clear();
                                });
                                _load();
                              },
                        child: const Text('Xóa bộ lọc'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              IncidentPanel(
                child: Column(
                  children: [
                    Text(_error!),
                    TextButton(
                      onPressed: () => _load(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            if (_data != null) ...[
              Text('${_data!.total} báo cáo phù hợp'),
              const SizedBox(height: 16),
              if (_data!.items.isEmpty)
                const IncidentPanel(
                  child: Column(
                    children: [
                      Icon(
                        Icons.mark_chat_read_outlined,
                        size: 48,
                        color: Color(0xFF589B90),
                      ),
                      SizedBox(height: 14),
                      Text('Chưa có báo cáo phù hợp.'),
                    ],
                  ),
                ),
              for (final report in _data!.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: IncidentPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '#${report.id} · ${incidentCategories[report.category]}',
                            ),
                            IncidentStatus(report.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          report.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.admin) ...[
                          const SizedBox(height: 10),
                          Text('Người gửi: ${report.reporterName}'),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          'Cập nhật: ${incidentDate(report.updatedAt)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _busy ? null : () => _detail(report.id),
                            icon: const Icon(Icons.arrow_forward),
                            label: Text(
                              widget.admin ? 'Xem và xử lý' : 'Xem chi tiết',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  IconButton(
                    tooltip: 'Trang trước',
                    onPressed: _busy || _data!.page == 0
                        ? null
                        : () => _load(_data!.page - 1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    'Trang ${_data!.totalPages == 0 ? 0 : _data!.page + 1}/${_data!.totalPages}',
                  ),
                  IconButton(
                    tooltip: 'Trang sau',
                    onPressed: _busy || _data!.page + 1 >= _data!.totalPages
                        ? null
                        : () => _load(_data!.page + 1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
