import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../content/data/models/system_content.dart';
import '../../../content/data/repositories/system_content_repository.dart';
import '../../../content/presentation/content_article.dart';
import '../../../content/presentation/content_editor.dart';
import '../widgets/admin_user_badges.dart' show AdminUserBadge;

class AdminContentPage extends StatefulWidget {
  const AdminContentPage({super.key, this.repository});
  final SystemContentRepository? repository;
  @override
  State<AdminContentPage> createState() => AdminContentPageState();
}

class AdminContentPageState extends State<AdminContentPage> {
  late final _repository =
      widget.repository ?? SystemContentRepository(ApiClient());
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  List<SystemContent> _items = [];
  SystemContent? _selected;
  bool _busy = false;
  String? _error;
  static const _accent = Color(0xFF15803D);
  bool get _dirty {
    final content = _selected;
    if (content == null) {
      return false;
    }
    final titleChanged = _title.text.trim() != content.title;
    final bodyChanged = _body.text.trim() != content.body;
    return titleChanged || bodyChanged;
  }

  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  Color get _muted => _dark ? const Color(0xFFADB5C3) : const Color(0xFF7A8495);
  Color get _border =>
      _dark ? const Color(0xFF343A45) : const Color(0xFFE7EAF0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _apply(SystemContent content) {
    setState(() {
      _selected = content;
      _title.text = content.title;
      _body.text = content.body;
      _error = null;
      for (int i = 0; i < _items.length; i++) {
        if (_items[i].slug == content.slug) _items[i] = content;
      }
    });
  }

  Future<bool> _confirm(
    String title,
    String message, {
    String accept = 'Xác nhận',
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(accept),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<bool> _discard() async {
    if (!_dirty) return true;
    return _confirm(
      'Bỏ thay đổi chưa lưu?',
      'Nội dung bạn vừa nhập chưa được lưu. Bạn muốn bỏ các thay đổi này?',
      accept: 'Bỏ thay đổi',
    );
  }

  Future<bool> confirmLeave() async {
    if (_busy) return false;
    return _discard();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final items = await _repository.list();
      if (!mounted) return;
      if (items.isEmpty) {
        setState(() {
          _items = [];
          _selected = null;
        });
        return;
      }
      final slug = _selected?.slug ?? 'about';
      String selectedSlug = items.first.slug;
      for (final item in items) {
        if (item.slug == slug) {
          selectedSlug = item.slug;
          break;
        }
      }
      final selected = await _repository.detail(selectedSlug);
      if (!mounted) return;
      _items = items;
      _apply(selected);
    } catch (error) {
      if (mounted) setState(() => _error = contentError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    if (_busy) return;
    final discard = await _discard();
    if (!discard || !mounted) return;
    await _load();
  }

  Future<void> _select(String slug) async {
    if (_busy || slug == _selected?.slug) return;
    final discard = await _discard();
    if (!discard || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final content = await _repository.detail(slug);
      if (mounted) _apply(content);
    } catch (error) {
      if (mounted) setState(() => _error = contentError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save({bool publish = false}) async {
    if (_busy || _selected == null || !_form.currentState!.validate()) return;
    if (publish) {
      final confirmed = await _confirm(
        'Xuất bản nội dung?',
        'Nội dung hiện tại sẽ được hiển thị cho người dùng trên ứng dụng.',
      );
      if (!confirmed) return;
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      SystemContent content;
      String message;
      if (publish) {
        content = await _repository.publish(
          _selected!.slug,
          _title.text,
          _body.text,
          _selected!.version,
        );
        message = 'Đã xuất bản nội dung.';
      } else {
        content = await _repository.saveDraft(
          _selected!.slug,
          _title.text,
          _body.text,
          _selected!.version,
        );
        message = 'Đã lưu bản nháp. Nội dung công khai chưa thay đổi.';
      }
      if (!mounted) return;
      _apply(content);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted) setState(() => _error = contentError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unpublish() async {
    if (_busy || _selected == null || _dirty) return;
    final confirmed = await _confirm(
      'Gỡ xuất bản?',
      'Người dùng sẽ tạm thời không xem được trang này. Bản soạn thảo vẫn được giữ để xuất bản lại.',
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final content = await _repository.unpublish(
        _selected!.slug,
        _selected!.version,
      );
      if (!mounted) return;
      _apply(content);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã gỡ xuất bản nội dung.')));
    } catch (error) {
      if (mounted) setState(() => _error = contentError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _preview() {
    if (!_form.currentState!.validate()) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xem trước nội dung'),
        content: SizedBox(
          width: 640,
          height: MediaQuery.sizeOf(context).height * .65,
          child: SingleChildScrollView(
            child: ContentArticle(
              slug: _selected!.slug,
              title: _title.text.trim(),
              body: _body.text.trim(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _viewPublished() async {
    if (_busy || _selected == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final content = await _repository.published(_selected!.slug);
      if (!mounted) return;
      setState(() => _busy = false);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nội dung đang công khai'),
          content: SizedBox(
            width: 640,
            height: MediaQuery.sizeOf(context).height * .65,
            child: SingleChildScrollView(
              child: ContentArticle(
                slug: content.slug,
                title: content.title,
                body: content.body,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = contentError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _compactSections() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final content in _items)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              avatar: Icon(contentIcon(content.slug), size: 18),
              label: Text(contentPages[content.slug] ?? content.title),
              selected: _selected?.slug == content.slug,
              onSelected: _busy ? null : (_) => _select(content.slug),
            ),
          ),
      ],
    ),
  );

  Widget _panel(Widget child) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: _dark ? const Color(0xFF1E232C) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: child,
  );

  InputDecoration _input(String label) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: _border),
    );
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: _dark ? const Color(0xFF242933) : const Color(0xFFF9FAFC),
      labelStyle: TextStyle(color: _muted),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
      contentPadding: const EdgeInsets.all(16),
      alignLabelWithHint: true,
    );
  }

  Widget _status(SystemContent content) {
    Color color;
    if (!content.published) {
      color = const Color(0xFF7A8495);
    } else if (content.hasDraft) {
      color = const Color(0xFFB58131);
    } else {
      color = const Color(0xFF298774);
    }
    return AdminUserBadge(label: content.statusLabel, color: color, dot: true);
  }

  Widget _sections() => _panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'CÁC TRANG NỘI DUNG',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: .8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        for (final content in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: _selected?.slug == content.slug
                  ? _accent.withValues(alpha: .08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: _busy ? null : () => _select(content.slug),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        contentIcon(content.slug),
                        color: _selected?.slug == content.slug
                            ? _accent
                            : _muted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contentPages[content.slug] ?? content.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _status(content),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _editor() {
    final content = _selected!;
    return _panel(
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  contentPages[content.slug] ?? content.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _dirty
                    ? const AdminUserBadge(
                        label: 'Chưa lưu',
                        color: Color(0xFFB58131),
                        dot: true,
                      )
                    : _status(content),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _busy ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tải lại bản đã lưu'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextFormField(
              key: const ValueKey('content-title'),
              controller: _title,
              enabled: !_busy,
              maxLength: 150,
              decoration: _input('Tiêu đề'),
              onChanged: (_) => setState(() {}),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập tiêu đề.'
                  : null,
            ),
            const SizedBox(height: 14),
            ContentEditor(
              controller: _body,
              enabled: !_busy,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 6),
            Text(
              'Định dạng nội dung bằng thanh công cụ. Xem trước trước khi xuất bản.',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
            if (_dirty || (content.published && content.hasDraft))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Thay đổi chỉ hiển thị cho người dùng sau khi xuất bản. Hãy lưu nháp nếu bạn muốn tiếp tục chỉnh sửa sau.',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
              ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 12,
              children: [
                if (content.published)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _viewPublished,
                    icon: const Icon(Icons.public, size: 18),
                    label: const Text('Xem bản công khai'),
                  ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _preview,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Xem trước'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || !_dirty ? null : () => _save(),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Lưu nháp'),
                ),
                FilledButton.icon(
                  onPressed:
                      _busy ||
                          (content.published && !content.hasDraft && !_dirty)
                      ? null
                      : () => _save(publish: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.publish_outlined, size: 18),
                  label: const Text('Xuất bản'),
                ),
                if (content.published)
                  OutlinedButton.icon(
                    onPressed: _busy || _dirty ? null : _unpublish,
                    icon: const Icon(Icons.visibility_off_outlined, size: 18),
                    label: const Text('Gỡ xuất bản'),
                  ),
              ],
            ),
            if (content.updatedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  'Lần lưu gần nhất: ${DateFormat('dd/MM/yyyy HH:mm').format(content.updatedAt!)}',
                  style: TextStyle(fontSize: 11, color: _muted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _dark ? const Color(0xFF171C24) : const Color(0xFFF5F7FA),
    child: SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: EdgeInsets.all(box.maxWidth < 650 ? 16 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 12,
                children: [
                  const Text(
                    'Nội dung hệ thống',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tải lại nội dung'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Quản lý thông tin hiển thị trên ứng dụng.',
                style: TextStyle(fontSize: 13, color: _muted),
              ),
              const SizedBox(height: 24),
              if (_selected == null)
                _panel(
                  Column(
                    children: [
                      if (_busy)
                        const CircularProgressIndicator()
                      else ...[
                        Text(
                          _error ?? 'Chưa có dữ liệu nội dung.',
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ],
                  ),
                )
              else if (box.maxWidth >= 1100)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 280, child: _sections()),
                    const SizedBox(width: 22),
                    Expanded(child: _editor()),
                  ],
                )
              else ...[
                _compactSections(),
                const SizedBox(height: 20),
                _editor(),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
