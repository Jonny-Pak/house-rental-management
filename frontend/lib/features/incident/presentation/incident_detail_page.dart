import 'package:flutter/material.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/network/api_client.dart';
import '../data/incident_repository.dart';
import 'incident_widgets.dart';

class IncidentDetailPage extends StatefulWidget {
  const IncidentDetailPage({
    super.key,
    required this.id,
    this.admin = false,
    this.repository,
  });
  final int id;
  final bool admin;
  final IncidentRepository? repository;
  @override
  State<IncidentDetailPage> createState() => _IncidentDetailPageState();
}

class _IncidentDetailPageState extends State<IncidentDetailPage> {
  late final _repository = widget.repository ?? IncidentRepository(ApiClient());
  final _message = TextEditingController();
  final _form = GlobalKey<FormState>();
  Incident? _report;
  String? _error;
  String _nextStatus = 'IN_PROGRESS';
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final report = await _repository.detail(widget.id, admin: widget.admin);
      if (mounted) {
        setState(() {
          _report = report;
          _nextStatus = report.status == 'OPEN' ? 'IN_PROGRESS' : report.status;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = incidentError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _report == null || !_form.currentState!.validate()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gửi phản hồi xử lý?'),
        content: Text(
          'Trạng thái: ${incidentStatuses[_nextStatus]}. Người gửi sẽ nhận được thông báo và xem phản hồi này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final report = await _repository.update(
        widget.id,
        _report!.version,
        _nextStatus,
        _message.text,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _message.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi phản hồi và cập nhật báo cáo.')),
      );
    } catch (error) {
      if (mounted) setState(() => _error = incidentError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _content(Incident report) {
    final closed = report.status == 'RESOLVED' || report.status == 'REJECTED';
    final choices = <String>['IN_PROGRESS'];
    if (closed) {
      choices.add(report.status);
    } else {
      choices.addAll(['RESOLVED', 'REJECTED']);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IncidentPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '#${report.id} · ${incidentCategories[report.category]}',
                  ),
                  IncidentStatus(report.status),
                ],
              ),
              const SizedBox(height: 18),
              SelectableText(
                report.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              SelectableText(
                report.description,
                style: const TextStyle(height: 1.6),
              ),
              const SizedBox(height: 20),
              if (widget.admin) ...[
                Text('Người gửi: ${report.reporterName}'),
                const SizedBox(height: 6),
                SelectableText(report.reporterEmail),
                const SizedBox(height: 12),
              ],
              Text(
                'Ngày gửi: ${incidentDate(report.createdAt)}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                'Cập nhật: ${incidentDate(report.updatedAt)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        IncidentPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Lịch sử xử lý',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              for (final item in report.history)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            item.actorName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          IncidentStatus(item.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        item.message,
                        style: const TextStyle(height: 1.6),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        incidentDate(item.createdAt),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (widget.admin) ...[
          const SizedBox(height: 20),
          IncidentPanel(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    closed
                        ? 'Phản hồi bổ sung / mở lại báo cáo'
                        : 'Xử lý báo cáo',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    key: ValueKey('incident-status-${report.version}'),
                    initialValue: _nextStatus,
                    isExpanded: true,
                    decoration: incidentInput('Trạng thái xử lý'),
                    items: [
                      for (final status in choices)
                        DropdownMenuItem(
                          value: status,
                          child: Text(incidentStatuses[status]!),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) => setState(() => _nextStatus = value!),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const ValueKey('incident-reply'),
                    controller: _message,
                    enabled: !_busy,
                    maxLength: 2000,
                    minLines: 4,
                    maxLines: 9,
                    decoration: incidentInput('Phản hồi cho người gửi'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập phản hồi hoặc lý do xử lý.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Gửi phản hồi'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Báo cáo sự cố #${widget.id}'),
      actions: [
        IconButton(
          tooltip: 'Tải lại báo cáo',
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: AppContent(
      maxWidth: AppLayout.formWidth,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(bottom: 18),
                child: LinearProgressIndicator(),
              ),
            if (_error != null) ...[
              IncidentPanel(
                child: Column(
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _load,
                      child: const Text('Thử tải lại'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (_report != null) _content(_report!),
          ],
        ),
      ),
    ),
  );
}
