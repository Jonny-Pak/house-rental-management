import 'package:flutter/material.dart';

import '../../../core/layout/app_layout.dart';
import '../../listing/data/repositories/listing_repository.dart';
import '../data/notification_repository.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key, required this.repository});
  final NotificationRepository repository;
  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  final _title = TextEditingController(), _content = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gửi thông báo chung?'),
        content: SingleChildScrollView(
          child: Text(
            'Thông báo sẽ được gửi đến tất cả tài khoản đang hoạt động và đã xác thực.\n\n${_title.text.trim()}\n\n${_content.text.trim()}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận gửi'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _busy = false);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final count = await widget.repository.broadcast(
        _title.text.trim(),
        _content.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã gửi đến $count tài khoản.')));
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = ListingRepository.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Gửi thông báo chung')),
    body: AppContent(
      maxWidth: AppLayout.formWidth,
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              maxLength: 150,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Tiêu đề'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nhập tiêu đề.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _content,
              maxLength: 500,
              maxLines: 7,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Nội dung'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nhập nội dung.' : null,
            ),
            if (_error != null) Text(_error!),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _send,
              child: Text(_busy ? 'Đang gửi…' : 'Gửi thông báo'),
            ),
          ],
        ),
      ),
    ),
  );
}
