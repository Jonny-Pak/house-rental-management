import 'package:frontend/core/theme/app_colors.dart';

import 'package:flutter/material.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/network/api_client.dart';
import '../data/models/system_content.dart';
import '../data/repositories/system_content_repository.dart';
import 'content_article.dart';
import 'content_links.dart';
import 'help_widgets.dart';
import '../../incident/data/incident_repository.dart';
import '../../incident/presentation/incidents_page.dart';

class SystemContentPage extends StatefulWidget {
  const SystemContentPage({
    super.key,
    required this.slug,
    this.repository,
    this.incidentRepository,
  });
  final String slug;
  final SystemContentRepository? repository;
  final IncidentRepository? incidentRepository;
  @override
  State<SystemContentPage> createState() => _SystemContentPageState();
}

class _SystemContentPageState extends State<SystemContentPage> {
  late final _repository =
      widget.repository ?? SystemContentRepository(ApiClient());
  PublishedContent? _content;
  String? _error;
  bool _loading = true;

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
      final content = await _repository.published(widget.slug);
      if (mounted) {
        setState(() {
          _content = content;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = contentError(error);
          _loading = false;
        });
      }
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 42,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    final content = _content!;
    return AppContent(
      maxWidth: 960,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContentArticle(
              slug: widget.slug,
              title: content.title,
              body: content.body,
              publishedAt: content.publishedAt,
            ),
            if (widget.slug == 'contact')
              for (final uri in contactLinks(content.body)) ...[
                HelpLink(
                  title: uri.scheme == 'tel' ? 'Gọi hỗ trợ' : 'Gửi email',
                  subtitle: uri.path,
                  icon: uri.scheme == 'tel'
                      ? Icons.call_outlined
                      : Icons.mail_outline_rounded,
                  onTap: () => openContentLink(context, uri.toString()),
                ),
                const SizedBox(height: 10),
              ],
            if (widget.slug == 'contact' || widget.slug == 'support') ...[
              HelpLink(
                title: 'Gửi và theo dõi báo cáo',
                subtitle: 'Trao đổi về vấn đề gặp phải trong ứng dụng',
                icon: Icons.support_agent_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IncidentsPage(
                      repository: widget.incidentRepository,
                      contentRepository: _repository,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              'Khám phá thêm',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final page in contentPages.entries)
                    if (page.key != widget.slug)
                      SizedBox(
                        width: constraints.maxWidth >= 640
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth,
                        child: HelpLink(
                          title: page.value,
                          subtitle: contentCaption(page.key),
                          icon: contentIcon(page.key),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SystemContentPage(
                                slug: page.key,
                                repository: _repository,
                                incidentRepository: widget.incidentRepository,
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).brightness == Brightness.light
        ? AppColors.background
        : null,
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      title: Text(contentPages[widget.slug] ?? 'Thông tin'),
      actions: [
        IconButton(
          tooltip: 'Tải lại nội dung',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: _buildBody(),
  );
}
