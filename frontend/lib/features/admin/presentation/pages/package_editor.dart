import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../membership/data/models/membership_package_model.dart';
import '../../data/repositories/admin_package_repository.dart';

class PackageEditor extends StatefulWidget {
  const PackageEditor({super.key, required this.repository, this.item});
  final AdminPackageRepository repository;
  final MembershipPackage? item;
  @override
  State<PackageEditor> createState() => _PackageEditorState();
}

class _PackageEditorState extends State<PackageEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.item?.packageName ?? '',
  );
  late final _price = TextEditingController(
    text: widget.item?.price.toStringAsFixed(0) ?? '0',
  );
  late final _standard = TextEditingController(
    text: '${widget.item?.standardPostQuota ?? 0}',
  );
  late final _vip = TextEditingController(
    text: '${widget.item?.vipPostQuota ?? 0}',
  );
  late final _refresh = TextEditingController(
    text: '${widget.item?.refreshQuota ?? 0}',
  );
  late final _description = TextEditingController(
    text: widget.item?.description ?? '',
  );
  late bool _active = widget.item?.active ?? true;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _standard.dispose();
    _vip.dispose();
    _refresh.dispose();
    _description.dispose();
    super.dispose();
  }

  InputDecoration _input(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
  Widget _number(
    String label,
    String key,
    TextEditingController controller,
    int maximum,
  ) => TextFormField(
    key: ValueKey(key),
    controller: controller,
    enabled: !_busy,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: _input(label),
    validator: (value) {
      final number = int.tryParse(value ?? '');
      if (number == null || number < 0 || number > maximum) {
        return 'Nhập số nguyên từ 0 đến $maximum.';
      }
      return null;
    },
  );
  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (int.parse(_standard.text) +
            int.parse(_vip.text) +
            int.parse(_refresh.text) ==
        0) {
      setState(
        () => _error = 'Gói cần có ít nhất một lượt đăng tin hoặc làm mới.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.save(widget.item?.id, {
        'packageName': _name.text.trim(),
        'price': int.parse(_price.text),
        'standardPostQuota': int.parse(_standard.text),
        'vipPostQuota': int.parse(_vip.text),
        'refreshQuota': int.parse(_refresh.text),
        'description': _description.text.trim(),
        'active': _active,
        'version': widget.item?.version,
      });
      if (!mounted) return;
      setState(() => _busy = false);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = packageError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(widget.item == null ? 'Thêm gói dịch vụ' : 'Sửa gói dịch vụ'),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Thay đổi chỉ áp dụng cho lần mua mới. Gói đã mua và giao dịch đang chờ giữ thông tin cũ.',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                TextFormField(
                  key: const ValueKey('package-name'),
                  controller: _name,
                  enabled: !_busy,
                  maxLength: 20,
                  decoration: _input('Tên gói'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập tên gói dịch vụ.'
                      : null,
                ),
                const SizedBox(height: 16),
                _number(
                  'Giá gói (VND, 0 là miễn phí)',
                  'package-price',
                  _price,
                  99999999,
                ),
                const SizedBox(height: 20),
                _number(
                  'Lượt đăng thường',
                  'package-standard',
                  _standard,
                  32767,
                ),
                const SizedBox(height: 20),
                _number('Lượt đăng VIP', 'package-vip', _vip, 32767),
                const SizedBox(height: 20),
                _number('Lượt làm mới', 'package-refresh', _refresh, 32767),
                const SizedBox(height: 20),
                TextFormField(
                  key: const ValueKey('package-description'),
                  controller: _description,
                  enabled: !_busy,
                  maxLength: 255,
                  minLines: 3,
                  maxLines: 5,
                  decoration: _input('Mô tả quyền lợi'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Đang bán'),
                  subtitle: const Text(
                    'Hiển thị trong danh sách gói của người dùng.',
                  ),
                  value: _active,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _active = value),
                ),
                if (_busy) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Lưu gói'),
        ),
      ],
    ),
  );
}
