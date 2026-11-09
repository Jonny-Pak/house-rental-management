import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';

import '../data/models/system_content.dart';
import 'help_widgets.dart';
import 'content_links.dart';

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

  Color get iconColor {
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
        HelpHero(
          title: title,
          caption: contentCaption(slug),
          icon: contentIcon(slug),
          accent: iconColor,
          footer: publishedAt == null
              ? null
              : Text(
                  'Cập nhật ${DateFormat('dd/MM/yyyy').format(publishedAt!.toLocal())}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
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
                    'h1',
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
                  onLinkTap: (url, attributes, element) =>
                      openContentLink(context, url ?? ''),
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
