import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContractDocumentView extends StatelessWidget {
  const ContractDocumentView({super.key, required this.content});
  final String content;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Sao chép hợp đồng'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: content));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép nội dung hợp đồng.')),
              );
            }
          },
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SelectableText(
            content,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
        ),
      ),
    ],
  );
}
