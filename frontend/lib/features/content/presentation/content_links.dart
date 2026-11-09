import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' as html;

Future<void> openContentLink(
  BuildContext context,
  String value, {
  Future<bool> Function(Uri)? opener,
}) async {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || !['https', 'http', 'mailto', 'tel'].contains(uri.scheme)) {
    return;
  }
  bool opened = false;
  try {
    opened = opener == null
        ? await launchUrl(uri, mode: LaunchMode.externalApplication)
        : await opener(uri);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Không mở được liên kết. Bạn có thể sao chép thông tin trong nội dung để liên hệ.',
        ),
      ),
    );
  }
}

List<Uri> contactLinks(String body) {
  final document = html.parse(body);
  final text = document.body?.nodes.map((node) => node.text).join(' ') ?? body;
  final result = <Uri>[];
  for (final element in document.querySelectorAll('a[href]')) {
    final uri = Uri.tryParse(element.attributes['href'] ?? '');
    if (uri != null &&
        ['mailto', 'tel'].contains(uri.scheme) &&
        uri.path.isNotEmpty &&
        !result.contains(uri)) {
      result.add(uri);
    }
  }
  for (final match in RegExp(
    r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',
  ).allMatches(text)) {
    final uri = Uri(scheme: 'mailto', path: match[0]);
    if (!result.any(
      (item) => item.scheme == 'mailto' && item.path == uri.path,
    )) {
      result.add(uri);
    }
  }
  for (final match in RegExp(
    r'(?:hotline|điện thoại)\s*:?\s*(\+?\d[\d .()-]{7,18}\d)',
    caseSensitive: false,
  ).allMatches(text)) {
    final phone = match[1]!.replaceAll(RegExp(r'[^+0-9]'), '');
    final uri = Uri(scheme: 'tel', path: phone);
    if (!result.contains(uri)) result.add(uri);
  }
  return result.take(6).toList();
}
