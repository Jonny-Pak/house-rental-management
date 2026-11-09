import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/network/api_client.dart';
import '../../data/qr_login_repository.dart';
import 'qr_login_confirmation_page.dart';

class QrLoginScannerPage extends StatefulWidget {
  const QrLoginScannerPage({
    super.key,
    this.repository,
    this.enableCamera = true,
  });
  final QrLoginRepository? repository;
  final bool enableCamera;
  @override
  State<QrLoginScannerPage> createState() => _QrLoginScannerPageState();
}

class _QrLoginScannerPageState extends State<QrLoginScannerPage>
    with WidgetsBindingObserver {
  late final repository = widget.repository ?? QrLoginRepository(ApiClient());
  MobileScannerController? _controller;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enableCamera &&
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      _controller = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null ||
        _busy ||
        !_controller!.value.hasCameraPermission) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_camera(true));
    } else {
      unawaited(_camera(false));
    }
  }

  Future<void> _camera(bool start) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      if (start) {
        if (!controller.value.isRunning) await controller.start();
      } else {
        await controller.stop();
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = 'Chưa mở được camera. Bạn có thể nhập nội dung mã QR.',
        );
      }
    }
  }

  Future<void> _scan(String text) async {
    if (!mounted || _busy) return;
    QrLoginCode code;
    try {
      code = QrLoginCode.parse(text);
    } catch (error) {
      setState(() => _error = QrLoginRepository.errorMessage(error));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await _camera(false);
    if (!mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            QrLoginConfirmationPage(code: code, repository: repository),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result
                ? 'Đã xác nhận. Website sẽ đăng nhập vào tài khoản Admin của bạn.'
                : 'Đã từ chối đăng nhập.',
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() => _busy = false);
      await _camera(true);
    }
  }

  Future<void> _manual() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _camera(false);
    if (!mounted) return;
    String input = '';
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập nội dung mã QR'),
        content: TextField(
          onChanged: (value) => input = value,
          maxLength: 512,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Dán nội dung mã QR từ website Admin',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input),
            child: const Text('Kiểm tra mã'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (text != null) await _scan(text);
    if (mounted && !_busy) await _camera(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quét QR Admin')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Hướng camera vào mã QR trên trang đăng nhập Admin.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (_controller != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 300,
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      for (final barcode in capture.barcodes) {
                        if (barcode.rawValue != null) {
                          _scan(barcode.rawValue!);
                          break;
                        }
                      }
                    },
                    errorBuilder: (context, error) => const ColoredBox(
                      color: Color(0xFFEDF8F0),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Chưa có quyền camera hoặc camera không khả dụng. '
                            'Hãy cấp quyền camera trong cài đặt ứng dụng, hoặc nhập nội dung mã QR.',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 90,
                  color: Color(0xFF15803D),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Quét mã chỉ mở bước kiểm tra. Website chỉ đăng nhập sau khi bạn xác nhận trên app.',
              style: TextStyle(height: 1.6),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _busy ? null : _manual,
              icon: const Icon(Icons.keyboard),
              label: const Text('Nhập nội dung mã QR'),
            ),
          ],
        ),
      ),
    ),
  );
}
