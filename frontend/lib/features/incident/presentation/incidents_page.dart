import 'package:frontend/core/theme/app_colors.dart';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../content/data/repositories/system_content_repository.dart';
import '../../content/presentation/system_content_page.dart';
import '../data/incident_repository.dart';
import 'create_incident_page.dart';
import 'incident_detail_page.dart';
import 'user_incident_content.dart';
import 'admin_incident_content.dart';

class IncidentsPage extends StatefulWidget {
  const IncidentsPage({
    super.key,
    this.admin = false,
    this.repository,
    this.contentRepository,
  });
  final bool admin;
  final IncidentRepository? repository;
  final SystemContentRepository? contentRepository;
  @override
  State<IncidentsPage> createState() => _IncidentsPageState();
}

class _IncidentsPageState extends State<IncidentsPage> {
  late final _repository = widget.repository ?? IncidentRepository(ApiClient());
  final _search = TextEditingController();
  IncidentPageData? _data;
  String? _status, _category, _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load([int page = 0]) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _repository.fetch(
        admin: widget.admin,
        query: _search.text,
        status: _status,
        category: _category,
        page: page,
      );
      if (mounted) setState(() => _data = result);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = incidentError(error);
          _data = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _detail(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidentDetailPage(
          id: id,
          admin: widget.admin,
          repository: _repository,
        ),
      ),
    );
    if (mounted) await _load(_data?.page ?? 0);
  }

  Future<void> _create() async {
    final report = await Navigator.push<Incident>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateIncidentPage(repository: _repository),
      ),
    );
    if (report == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã tiếp nhận báo cáo #${report.id}.')),
    );
    await _load();
    if (mounted) await _detail(report.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).brightness == Brightness.light
        ? AppColors.background
        : null,
    appBar: widget.admin
        ? null
        : AppBar(title: const Text('Báo cáo sự cố của tôi')),
    body: widget.admin
        ? AdminIncidentContent(
            data: _data,
            busy: _busy,
            error: _error,
            search: _search,
            status: _status,
            category: _category,
            onRefresh: () => _load(_data?.page ?? 0),
            onSearch: () => _load(),
            onStatus: (value) {
              setState(() => _status = value);
              _load();
            },
            onCategory: (value) {
              setState(() => _category = value);
              _load();
            },
            onClear: () {
              setState(() {
                _status = null;
                _category = null;
                _search.clear();
              });
              _load();
            },
            onPage: _load,
            onDetail: _detail,
          )
        : UserIncidentContent(
            data: _data,
            busy: _busy,
            error: _error,
            search: _search,
            status: _status,
            category: _category,
            onCreate: _create,
            onRefresh: () => _load(_data?.page ?? 0),
            onSearch: () => _load(),
            onStatus: (value) {
              setState(() => _status = value);
              _load();
            },
            onCategory: (value) {
              setState(() => _category = value);
              _load();
            },
            onClear: () {
              setState(() {
                _status = null;
                _category = null;
                _search.clear();
              });
              _load();
            },
            onPage: _load,
            onDetail: _detail,
            onGuide: () => _openContent('support'),
            onContact: () => _openContent('contact'),
          ),
  );

  void _openContent(String slug) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SystemContentPage(
          slug: slug,
          repository: widget.contentRepository,
          incidentRepository: _repository,
        ),
      ),
    );
  }
}
