import 'package:flutter/material.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/network/api_client.dart';
import '../data/models/system_content.dart';
import '../data/repositories/system_content_repository.dart';
import 'content_article.dart';

class SystemContentPage extends StatefulWidget {
  const SystemContentPage({super.key, required this.slug, this.repository});
  final String slug;
  final SystemContentRepository? repository;
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
                color: Color(0xFFD66A2B),
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
      maxWidth: AppLayout.formWidth,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ContentArticle(
          slug: widget.slug,
          title: content.title,
          body: content.body,
          publishedAt: content.publishedAt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
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
