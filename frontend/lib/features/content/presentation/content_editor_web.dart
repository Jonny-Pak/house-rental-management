import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class ContentEditor extends StatefulWidget {
  const ContentEditor({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  @override
  State<ContentEditor> createState() => _ContentEditorState();
}

class _ContentEditorState extends State<ContentEditor> {
  web.HTMLIFrameElement? _frame;
  late final JSFunction _listener;
  Timer? _timeout;
  bool _ready = false;
  bool _connected = false;
  bool _fromEditor = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listener = ((web.Event event) {
      final message = event as web.MessageEvent;
      if (message.origin != web.window.location.origin ||
          message.source != _frame?.contentWindow ||
          message.data == null ||
          !message.data.isA<JSString>()) {
        return;
      }
      final data =
          jsonDecode((message.data as JSString).toDart) as Map<String, dynamic>;
      if (data['type'] == 'ready') {
        _connected = true;
        _send();
      } else if (data['type'] == 'initialized') {
        _timeout?.cancel();
        setState(() {
          _ready = true;
          _error = null;
        });
      } else if (data['type'] == 'change' && widget.enabled && _ready) {
        _fromEditor = true;
        widget.controller.text = data['html'] as String;
        _fromEditor = false;
        widget.onChanged(widget.controller.text);
      } else if (data['type'] == 'error') {
        setState(() => _error = 'Không tải được CKEditor. Hãy tải lại trang.');
      }
    }).toJS;
    web.window.addEventListener('message', _listener);
    widget.controller.addListener(_controllerChanged);
    _timeout = Timer(const Duration(seconds: 30), () {
      if (mounted && !_ready) {
        setState(() => _error = 'Không tải được CKEditor. Hãy tải lại trang.');
      }
    });
  }

  void _controllerChanged() {
    if (!_fromEditor) _send();
  }

  void _send() {
    if (!_connected) return;
    _frame?.contentWindow?.postMessage(
      jsonEncode({
        'type': 'set',
        'html': widget.controller.text,
        'enabled': widget.enabled,
        'licenseKey': const String.fromEnvironment(
          'CKEDITOR_LICENSE_KEY',
          defaultValue: 'GPL',
        ),
      }).toJS,
      web.window.location.origin.toJS,
    );
  }

  @override
  void didUpdateWidget(ContentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _send();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    web.window.removeEventListener('message', _listener);
    widget.controller.removeListener(_controllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormField<String>(
    validator: (_) {
      if (!_ready || _error != null) {
        return _error ?? 'Trình soạn thảo đang tải.';
      }
      final text = widget.controller.text
          .replaceAll(RegExp('<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .trim();
      if (text.isEmpty) return 'Vui lòng nhập nội dung.';
      if (widget.controller.text.length > 20000) {
        return 'Nội dung tối đa 20.000 ký tự, bao gồm định dạng.';
      }
      return null;
    },
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 620,
          child: HtmlElementView.fromTagName(
            tagName: 'iframe',
            onElementCreated: (element) {
              _frame = element as web.HTMLIFrameElement;
              _frame!.src = Uri.parse(web.document.baseURI)
                  .resolve('content_editor.html')
                  .toString();
              _frame!.title = 'Soạn thảo nội dung CKEditor';
              _frame!.style.border = '0';
              _frame!.style.width = '100%';
              _frame!.style.height = '100%';
            },
          ),
        ),
        if (!_ready && _error == null) const LinearProgressIndicator(),
        if (field.errorText != null || _error != null)
          Text(
            field.errorText ?? _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        Text(
          '${widget.controller.text.length}/20000',
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}
