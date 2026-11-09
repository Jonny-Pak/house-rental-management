import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../listing/data/repositories/listing_repository.dart';
import '../data/amenity_model.dart';
import '../data/amenity_repository.dart';

class AmenitySelector extends StatefulWidget {
  const AmenitySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.repository,
    this.enabled = true,
  });
  final List<Amenity> selected;
  final ValueChanged<List<Amenity>> onChanged;
  final AmenityRepository? repository;
  final bool enabled;
  @override
  State<AmenitySelector> createState() => _AmenitySelectorState();
}

class _AmenitySelectorState extends State<AmenitySelector> {
  late final repository = widget.repository ?? AmenityRepository(ApiClient());
  List<Amenity> _items = [];
  bool _loading = true;
  String? _error;
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
      final items = await repository.activeItems();
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) {
        setState(() => _error = ListingRepository.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(Amenity item, bool value) {
    final selected = [...widget.selected];
    selected.removeWhere((current) => current.id == item.id);
    if (value) {
      if (selected.length >= 30) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Chọn tối đa 30 mục.')));
        return;
      }
      selected.add(item);
    }
    widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final items = <int, Amenity>{};
    for (final item in widget.selected) {
      items[item.id] = item;
    }
    for (final item in _items) {
      items[item.id] = item;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nội thất & tiện ích',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Không bắt buộc. Chọn những mục thực tế có tại nơi cho thuê.',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(),
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            'Chưa tải được danh mục. $_error',
            style: const TextStyle(color: Colors.red),
          ),
          TextButton(
            onPressed: _loading ? null : _load,
            child: const Text('Tải lại danh mục'),
          ),
        ],
        if (!_loading && _error == null && items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Chưa có nội thất/tiện ích để chọn.'),
          ),
        for (final category in ['FURNITURE', 'UTILITY'])
          if (items.values.any((item) => item.category == category)) ...[
            const SizedBox(height: 12),
            Text(
              category == 'FURNITURE' ? 'Nội thất' : 'Tiện ích',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in items.values)
                  if (item.category == category)
                    FilterChip(
                      key: ValueKey('amenity-${item.id}'),
                      label: Text(
                        item.active
                            ? item.name
                            : '${item.name} (ngừng sử dụng)',
                      ),
                      selected: widget.selected.any(
                        (selected) => selected.id == item.id,
                      ),
                      onSelected:
                          !widget.enabled ||
                              (!item.active &&
                                  !widget.selected.any(
                                    (selected) => selected.id == item.id,
                                  ))
                          ? null
                          : (value) => _select(item, value),
                    ),
              ],
            ),
          ],
      ],
    );
  }
}
