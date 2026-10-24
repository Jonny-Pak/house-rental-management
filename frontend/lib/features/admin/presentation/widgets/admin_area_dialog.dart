import 'package:flutter/material.dart';

import '../../data/models/admin_area.dart';
import 'admin_area_style.dart';
import '../../data/repositories/admin_area_repository.dart';
import '../../data/repositories/admin_user_repository.dart' show adminUserError;

class AdminAreaDialog extends StatefulWidget {
  const AdminAreaDialog({
    super.key,
    required this.repository,
    required this.parents,
    this.area,
  });
  final AdminAreaRepository repository;
  final List<AdminArea> parents;
  final AdminArea? area;
  @override
  State<AdminAreaDialog> createState() => _AdminAreaDialogState();
}

class _AdminAreaDialogState extends State<AdminAreaDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.area?.name ?? '');
  late final _code = TextEditingController(text: widget.area?.code ?? '');
  late String _type = widget.area?.type ?? 'WARD';
  late int? _parent = widget.area?.parentId;
  bool _saving = false;
  String? _error;
  bool get _locked => widget.area?.used ?? false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.save(
        id: widget.area?.id,
        name: _name.text,
        code: _code.text,
        type: _type,
        parentId: _type == 'PROVINCE' ? null : _parent,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = adminUserError(error);
        });
      }
    }
  }

  InputDecoration _decoration(String label) => areaInput(context, label);

  @override
  Widget build(BuildContext context) {
    final parents = widget.parents
        .where(
          (p) =>
              p.id != widget.area?.id &&
              (p.type == 'PROVINCE' ||
                  (_type == 'WARD' && p.type == 'DISTRICT')),
        )
        .toList();
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E232C)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: areaBorder(context)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: areaAccent.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                widget.area == null
                    ? Icons.add_location_alt_outlined
                    : Icons.edit_location_alt_outlined,
                color: areaAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.area == null ? 'Thêm khu vực' : 'Chỉnh sửa khu vực',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Điền thông tin và chọn đơn vị trực thuộc cho khu vực.',
                    style: TextStyle(fontSize: 13, color: areaMuted(context)),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const ValueKey('area-name'),
                    controller: _name,
                    enabled: !_saving,
                    maxLength: 150,
                    decoration: areaInput(
                      context,
                      'Tên khu vực',
                      icon: Icons.location_on_outlined,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Vui lòng nhập tên khu vực.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('area-code'),
                    controller: _code,
                    enabled: !_saving,
                    maxLength: 20,
                    decoration: areaInput(
                      context,
                      'Mã khu vực',
                      icon: Icons.tag_rounded,
                    ),
                    validator: (v) =>
                        RegExp(r'^[A-Za-z0-9_-]{1,20}$')
                            .hasMatch(v?.trim() ?? '')
                        ? null
                        : 'Dùng 1–20 chữ, số, dấu gạch ngang hoặc gạch dưới.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('area-type'),
                    initialValue: _type,
                    isExpanded: true,
                    decoration: _decoration('Cấp hành chính'),
                    items: [
                      for (final entry in areaTypes.entries)
                        if (entry.key != 'DISTRICT' ||
                            widget.area?.type == 'DISTRICT')
                          DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                    ],
                    onChanged: _saving || _locked
                        ? null
                        : (value) => setState(() {
                            _type = value!;
                            _parent = null;
                          }),
                  ),
                  if (_type != 'PROVINCE') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      key: ValueKey('area-parent-$_type-$_parent'),
                      initialValue: _parent,
                      isExpanded: true,
                      decoration: _decoration('Đơn vị cấp trên'),
                      items: [
                        for (final p in parents)
                          DropdownMenuItem(
                            value: p.id,
                            enabled: p.active || p.id == _parent,
                            child: Text(
                              '${p.name}${p.active ? '' : ' (ngừng sử dụng)'}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      validator: (v) =>
                          v == null ? 'Vui lòng chọn đơn vị cấp trên.' : null,
                      onChanged: _saving || _locked
                          ? null
                          : (value) => setState(() => _parent = value),
                    ),
                  ],
                  if (widget.area != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: areaMuted(context).withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DỮ LIỆU LIÊN QUAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .6,
                              color: areaMuted(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.area!.children} đơn vị con · ${widget.area!.listingCount} tin đăng · ${widget.area!.propertyCount} khu trọ',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (_locked)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 14,
                                    color: areaAccent,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      'Đã có dữ liệu liên quan nên chỉ sửa tên và mã khu vực.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: areaMuted(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: areaMuted(context)),
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: areaAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Đang lưu...' : 'Lưu khu vực'),
          ),
        ],
      ),
    );
  }
}
