import 'package:flutter/material.dart';

import '../../../core/layout/app_layout.dart';
import '../data/incident_repository.dart';
import 'incident_widgets.dart';

class CreateIncidentPage extends StatefulWidget {
  const CreateIncidentPage({super.key, required this.repository});
  final IncidentRepository repository;
  @override
  State<CreateIncidentPage> createState() => _CreateIncidentPageState();
}

class _CreateIncidentPageState extends State<CreateIncidentPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _description = TextEditingController();
  final _requestKey = DateTime.now().microsecondsSinceEpoch.toString();
  String _category = 'TECHNICAL';
  String? _error;
  bool _busy = false;
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final report = await widget.repository.create(
        _requestKey,
        _title.text,
        _category,
        _description.text,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, report);
    } catch (error) {
      if (mounted) setState(() => _error = incidentError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFF8F9FB)
          : null,
      appBar: AppBar(title: const Text('Gửi báo cáo sự cố')),
      body: AppContent(
        maxWidth: AppLayout.formWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const IncidentHeader(
                  title: 'Chúng tôi luôn sẵn sàng hỗ trợ',
                  description: 'Hãy mô tả sự cố và các bước bạn đã thực hiện để Admin có thể hỗ trợ.',
                ),
                const SizedBox(height: 22),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: incidentInput('Loại sự cố'),
                  items: [
                    for (final item in incidentCategories.entries)
                      DropdownMenuItem(
                        value: item.key,
                        child: Text(item.value),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _category = value!),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const ValueKey('incident-title'),
                  controller: _title,
                  enabled: !_busy,
                  maxLength: 150,
                  decoration: incidentInput('Tiêu đề'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập tiêu đề.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('incident-description'),
                  controller: _description,
                  enabled: !_busy,
                  maxLength: 5000,
                  minLines: 7,
                  maxLines: 14,
                  decoration: incidentInput('Mô tả sự cố'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng mô tả sự cố.'
                      : null,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _busy ? null : _send,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Gửi báo cáo'),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
