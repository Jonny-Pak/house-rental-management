import 'package:flutter/material.dart';

class ContentEditor extends StatelessWidget {
  const ContentEditor({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextFormField(
    key: const ValueKey('content-body'),
    controller: controller,
    enabled: enabled,
    maxLength: 20000,
    minLines: 10,
    maxLines: 18,
    decoration: const InputDecoration(
      labelText: 'Nội dung',
      border: OutlineInputBorder(),
    ),
    onChanged: onChanged,
    validator: (value) => value == null || value.trim().isEmpty
        ? 'Vui lòng nhập nội dung.'
        : null,
  );
}
