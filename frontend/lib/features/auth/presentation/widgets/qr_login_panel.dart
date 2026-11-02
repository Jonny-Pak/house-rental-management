import 'dart:async';

import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/auth_models.dart';
import '../../data/qr_login_repository.dart';

class QrLoginPanel extends StatefulWidget {
  const QrLoginPanel({
    super.key,
    required this.onAuthenticated,
    required this.onCancel,
    this.repository,
  });
  final Future<void> Function(AuthResponse) onAuthenticated;
  final VoidCallback onCancel;
  final QrLoginRepository? repository;
  @override
  State<QrLoginPanel> createState() => _QrLoginPanelState();
}

class _QrLoginPanelState extends State<QrLoginPanel> {
  late final repository = widget.repository ?? QrLoginRepository(ApiClient());
  QrLoginSession? _session;
  Timer? _timer;
  String _status = 'PENDING';
  String? _error;
  bool _loading = false,
      _checking = false,
      _finishing = false,
      _consumed = false;

  @override
  void initState() {
    super.initState();
    _create();
  }

  Future<void> _cancel(QrLoginSession session) async {
    try {
      await repository.cancel(session);
    } catch (_) {}
  }

  Future<void> _copy() async {
    final session = _session;
    if (session == null) return;
    try {
      await Clipboard.setData(ClipboardData(text: session.qrData));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã sao chép nội dung QR để dán vào ứng dụng của bạn.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa sao chép được. Bạn có thể dùng camera để quét mã.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _create() async {
    if (_loading || _finishing) return;
    _timer?.cancel();
    final previous = _session;
    setState(() {
      _loading = true;
      _error = null;
      _session = null;
      _status = 'PENDING';
      _consumed = false;
    });
    if (previous != null) await _cancel(previous);
    try {
      final session = await repository.start();
      if (!mounted) {
        await _cancel(session);
        return;
      }
      setState(() => _session = session);
      _timer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) _check();
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = QrLoginRepository.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _check() async {
    final session = _session;
    if (_checking || _finishing || session == null) return;
    _checking = true;
    try {
      final status = await repository.status(session);
      if (!mounted || session != _session) return;
      setState(() => _status = status);
      if (status == 'APPROVED') {
        _timer?.cancel();
        setState(() => _finishing = true);
        final auth = await repository.consume(session);
        _consumed = true;
        if (mounted) await widget.onAuthenticated(auth);
      } else if (!['PENDING', 'SCANNED'].contains(status)) {
        _timer?.cancel();
      }
    } catch (error) {
      _timer?.cancel();
      if (mounted) {
        setState(() => _error = QrLoginRepository.errorMessage(error));
      }
    } finally {
      _checking = false;
      if (mounted) setState(() => _finishing = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    final session = _session;
    if (session != null && !_consumed) unawaited(_cancel(session));
    super.dispose();
  }

  String get _message {
    if (_finishing) return 'Đang đăng nhập…';
    if (_status == 'SCANNED') return 'Đã quét mã. Hãy xác nhận trên app.';
    if (_status == 'EXPIRED') return 'Mã đã hết hạn. Hãy tạo mã mới.';
    if (_status == 'REJECTED') return 'Bạn đã từ chối đăng nhập trên app.';
    if (_status == 'CANCELLED' || _status == 'CONSUMED') {
      return 'Mã không còn sử dụng được. Hãy tạo mã mới.';
    }
    return 'Mở app bằng tài khoản Admin → Cá nhân → Quét QR đăng nhập Admin.';
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final active =
        ['PENDING', 'SCANNED'].contains(_status) &&
        _error == null &&
        !_consumed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading || _finishing) const LinearProgressIndicator(),
        if (session != null && active && !_finishing) ...[
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth.clamp(0.0, 260.0).toDouble();
                return Container(
                  width: size,
                  height: size,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDCE8E0)),
                  ),
                  child: SvgPicture.string(
                    Barcode.qrCode().toSvg(
                      session.qrData,
                      width: 220,
                      height: 220,
                      drawText: false,
                    ),
                    semanticsLabel: 'Mã QR đăng nhập Admin',
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Mã đối chiếu: ${session.verificationCode}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: _copy,
                tooltip: 'Sao chép nội dung QR',
                constraints: const BoxConstraints.tightFor(
                  width: 24,
                  height: 24,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Mã có hiệu lực 2 phút. Chỉ xác nhận nếu bạn đang đăng nhập trên máy tính của mình.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          _error ?? _message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _error == null ? null : Colors.red,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _loading || _finishing ? null : _create,
          icon: const Icon(Icons.refresh),
          label: const Text('Tạo mã QR mới'),
        ),
        TextButton(
          onPressed: _finishing ? null : widget.onCancel,
          child: const Text('Dùng email và mật khẩu'),
        ),
      ],
    );
  }
}
