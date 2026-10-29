import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Color get accent {
    if (slug == 'rules') return const Color(0xFFAE7545);
    if (slug == 'guide') return const Color(0xFF318A7C);
    if (slug == 'support') return const Color(0xFFBB6478);
    return const Color(0xFF4D83BB);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: .14),
                accent.withValues(alpha: .04),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accent.withValues(alpha: .14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(contentIcon(slug), color: accent, size: 34),
              ),
              const SizedBox(height: 22),
              Text(
                'RENTAL • ${contentPages[slug] ?? 'Thông tin'}',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              SelectableText(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              if (publishedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Icon(
                        Icons.update_rounded,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      Text(
                        'Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(publishedAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: .45),
            ),
          ),
          child: RegExp(r'<[a-z][\s\S]*>', caseSensitive: false).hasMatch(body)
              ? Html(
                  data: body,
                  onlyRenderTheseTags: const {
                    'wrapper-element',
                    'body',
                    'html',
                    'p',
                    'br',
                    'h2',
                    'h3',
                    'h4',
                    'strong',
                    'b',
                    'em',
                    'i',
                    'u',
                    's',
                    'span',
                    'ul',
                    'ol',
                    'li',
                    'blockquote',
                    'hr',
                    'figure',
                    'table',
                    'thead',
                    'tbody',
                    'tr',
                    'td',
                    'th',
                    'a',
                  },
                  onLinkTap: (url, attributes, element) async {
                    final uri = Uri.tryParse(url ?? '');
                    if (uri != null &&
                        ['https', 'http', 'mailto'].contains(uri.scheme)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  extensions: [
                    TagWrapExtension(
                      tagsToWrap: {'table'},
                      builder: (child) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: child,
                      ),
                    ),
                    const TableHtmlExtension(),
                  ],
                  style: {
                    'body': Style(
                      margin: Margins.zero,
                      fontSize: FontSize(15),
                      lineHeight: const LineHeight(1.9),
                      color: colors.onSurface,
                    ),
                    'td': Style(
                      padding: HtmlPaddings.all(8),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    'th': Style(
                      padding: HtmlPaddings.all(8),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                  },
                )
              : SelectableText(
                  body,
                  style: const TextStyle(fontSize: 15, height: 1.9),
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
