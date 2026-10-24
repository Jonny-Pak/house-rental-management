import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/system_content.dart';

class ContentArticle extends StatelessWidget {
  const ContentArticle({
    super.key,
    required this.slug,
    required this.title,
    required this.body,
    this.publishedAt,
  });
  final String slug, title, body;
  final DateTime? publishedAt;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFFDF0E5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          contentIcon(slug),
          color: const Color(0xFFD66A2B),
          size: 26,
        ),
      ),
      const SizedBox(height: 20),
      SelectableText(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
      if (publishedAt != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            'Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(publishedAt!)}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      const SizedBox(height: 20),
      Divider(color: Theme.of(context).colorScheme.outlineVariant),
      const SizedBox(height: 16),
      SelectableText(body, style: const TextStyle(fontSize: 15, height: 1.8)),
    ],
  );
}
