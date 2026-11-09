import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../data/qr_login_repository.dart';

class QrLoginConfirmationPage extends StatefulWidget {
  const QrLoginConfirmationPage({
    super.key,
    required this.code,
    this.repository,
  });
  final QrLoginCode code;
  final QrLoginRepository? repository;
  @override
  State<QrLoginConfirmationPage> createState() =>
      _QrLoginConfirmationPageState();
}

class _QrLoginConfirmationPageState extends State<QrLoginConfirmationPage> {
  late final repository = widget.repository ?? QrLoginRepository(ApiClient());
  QrLoginPreview? _preview;
  bool _loading = true, _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preview = await repository.preview(widget.code);
      if (mounted) setState(() => _preview = preview);
    } catch (error) {
      if (mounted) {
        setState(() => _error = QrLoginRepository.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(bool approve) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.decide(widget.code, approve);
      if (mounted) Navigator.pop(context, approve);
    } catch (error) {
      if (mounted) {
        setState(() => _error = QrLoginRepository.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Xác nhận đăng nhập Admin')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 56,
                        color: Color(0xFF15803D),
                      ),
                      const SizedBox(height: 20),
                      if (preview != null) ...[
                        const Text(
                          'Bạn có đang đăng nhập trên máy tính này?',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SelectableText(
                          preview.website,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(preview.browserName),
                        const SizedBox(height: 20),
                        const Text('So sánh mã này với mã trên website:'),
                        const SizedBox(height: 10),
                        Text(
                          preview.verificationCode,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            letterSpacing: 5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hết hạn lúc ${DateFormat('HH:mm:ss').format(preview.expiresAt.toLocal())}',
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Chỉ xác nhận nếu bạn tự mở website Admin trên máy tính của mình và mã đối chiếu trùng nhau. '
                          'Không xác nhận mã do người khác gửi.',
                          style: TextStyle(height: 1.6),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (preview != null) ...[
                        FilledButton(
                          onPressed: _busy ? null : () => _decide(true),
                          child: Text(
                            _busy ? 'Đang xử lý…' : 'Xác nhận đăng nhập',
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _busy ? null : () => _decide(false),
                          child: const Text('Từ chối'),
                        ),
                      ] else
                        TextButton(
                          onPressed: _load,
                          child: const Text('Thử lại'),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
