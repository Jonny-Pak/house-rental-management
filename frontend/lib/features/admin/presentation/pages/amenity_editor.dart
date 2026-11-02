import 'package:flutter/material.dart';

import '../../../amenity/data/amenity_model.dart';
import '../../../amenity/data/amenity_repository.dart';
import '../../../listing/data/repositories/listing_repository.dart';

class AmenityEditor extends StatefulWidget {
  const AmenityEditor({super.key, required this.repository, this.item});
  final AmenityRepository repository;
  final Amenity? item;
  @override
  State<AmenityEditor> createState() => _AmenityEditorState();
}

class _AmenityEditorState extends State<AmenityEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _description = TextEditingController(
    text: widget.item?.description,
  );
  late String _category = widget.item?.category ?? 'FURNITURE';
  late bool _active = widget.item?.active ?? true;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.save(widget.item?.id, {
        'name': _name.text.trim(),
        'category': _category,
        'description': _description.text.trim(),
        'active': _active,
        'version': widget.item?.version,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = ListingRepository.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(
        widget.item == null
            ? 'Thêm nội thất/tiện ích'
            : 'Sửa nội thất/tiện ích',
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey('amenity-name'),
                  controller: _name,
                  enabled: !_busy,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Tên danh mục'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập tên.'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const ValueKey('amenity-category'),
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Nhóm'),
                  items: const [
                    DropdownMenuItem(
                      value: 'FURNITURE',
                      child: Text('Nội thất'),
                    ),
                    DropdownMenuItem(value: 'UTILITY', child: Text('Tiện ích')),
                  ],
                  onChanged: _busy || (widget.item?.listingCount ?? 0) > 0
                      ? null
                      : (value) => setState(() => _category = value!),
                ),
                if ((widget.item?.listingCount ?? 0) > 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Đã có tin sử dụng: không thể đổi nhóm, có thể sửa tên hoặc ngừng sử dụng.',
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('amenity-description'),
                  controller: _description,
                  enabled: !_busy,
                  maxLength: 255,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                SwitchListTile(
                  title: const Text('Cho phép chọn khi đăng tin'),
                  value: _active,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _active = value),
                ),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Đang lưu…' : 'Lưu danh mục'),
        ),
      ],
    ),
  );
}
