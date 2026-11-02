import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MapRadiusControls extends StatefulWidget {
  const MapRadiusControls({
    super.key,
    required this.enabled,
    required this.centerName,
    required this.radiusKm,
    required this.busy,
    required this.error,
    required this.onToggle,
    required this.onSearch,
    required this.onCurrentLocation,
    required this.onRadiusChanged,
  });

  final bool enabled, busy;
  final String? centerName, error;
  final double radiusKm;
  final VoidCallback onToggle, onCurrentLocation;
  final ValueChanged<String> onSearch;
  final ValueChanged<double> onRadiusChanged;

  @override
  State<MapRadiusControls> createState() => _MapRadiusControlsState();
}

class _MapRadiusControlsState extends State<MapRadiusControls> {
  final _address = TextEditingController();
  late double _radius = widget.radiusKm;

  @override
  void didUpdateWidget(covariant MapRadiusControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.radiusKm != widget.radiusKm) _radius = widget.radiusKm;
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  void _search() {
    final query = _address.text.trim();
    if (query.isNotEmpty) widget.onSearch(query);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: widget.busy ? null : widget.onToggle,
                icon: Icon(widget.enabled ? Icons.radar : Icons.radar_outlined),
                label: Text(
                  widget.enabled
                      ? 'Đang tìm theo bán kính'
                      : 'Tìm theo bán kính',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  backgroundColor: widget.enabled
                      ? AppColors.primaryLight
                      : Colors.white,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            if (widget.enabled)
              IconButton(
                tooltip: 'Tắt tìm theo bán kính',
                onPressed: widget.busy ? null : widget.onToggle,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        if (widget.enabled) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('map-radius-address'),
                  controller: _address,
                  enabled: !widget.busy,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Địa điểm làm tâm tìm kiếm',
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Tìm địa điểm trên bản đồ',
                onPressed: widget.busy ? null : _search,
                icon: const Icon(Icons.search),
              ),
              IconButton(
                tooltip: 'Tìm quanh vị trí hiện tại',
                onPressed: widget.busy ? null : widget.onCurrentLocation,
                icon: const Icon(Icons.my_location),
              ),
            ],
          ),
          if (widget.busy) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${widget.centerName ?? 'Tâm bản đồ'} • Chạm bản đồ để đổi tâm.',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
          Row(
            children: [
              const Text('Bán kính', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  key: const ValueKey('map-radius-slider'),
                  value: _radius.clamp(0.1, 50),
                  min: 0.1,
                  max: 50,
                  divisions: 499,
                  activeColor: AppColors.primary,
                  label: '${_radius.toStringAsFixed(1)} km',
                  onChanged: widget.busy
                      ? null
                      : (value) => setState(() => _radius = value),
                  onChangeEnd: widget.onRadiusChanged,
                ),
              ),
              Text(
                '${_radius.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const Text(
            'Khoảng cách đường chim bay.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          if (widget.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                widget.error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ],
    ),
  );
}
