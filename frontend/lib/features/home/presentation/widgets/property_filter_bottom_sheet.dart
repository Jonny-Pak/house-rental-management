import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/api_client.dart';
import '../../../preferences/data/models/area_models.dart';
import '../../../property/data/repositories/property_repository.dart';

class PropertyFilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;

  const PropertyFilterBottomSheet({super.key, this.initialFilters});

  @override
  State<PropertyFilterBottomSheet> createState() =>
      _PropertyFilterBottomSheetState();
}

class _PropertyFilterBottomSheetState extends State<PropertyFilterBottomSheet> {
  final PropertyRepository _repository = PropertyRepository(
    GetIt.I<ApiClient>(),
  );

  List<Province> provinces = [];
  List<Ward> wards = [];

  Province? selectedProvince;
  Ward? selectedWard;

  String? selectedPropertyType;
  RangeValues priceRange = const RangeValues(0, 15000000);

  bool isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _loadInitialFilters();
  }

  Future<void> _loadInitialFilters() async {
    try {
      final pList = await _repository.getProvinces();
      if (!mounted) return;
      setState(() {
        provinces = pList;
        isLoadingLocations = false;
      });

      if (widget.initialFilters != null) {
        final init = widget.initialFilters!;
        selectedPropertyType = init['propertyType'];
        if (init['minPrice'] != null || init['maxPrice'] != null) {
          priceRange = RangeValues(
            (init['minPrice'] as num?)?.toDouble() ?? 0,
            (init['maxPrice'] as num?)?.toDouble() ?? 15000000,
          );
        }

        if (init['provinceId'] != null) {
          selectedProvince = provinces.cast<Province?>().firstWhere(
            (p) => p?.id == init['provinceId'],
            orElse: () => provinces.isNotEmpty ? provinces.first : null,
          );
          await _onProvinceChanged(selectedProvince);

          if (init['wardId'] != null) {
            selectedWard = wards.cast<Ward?>().firstWhere(
              (w) => w?.id == init['wardId'],
              orElse: () => null,
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingLocations = false;
      });
    }
  }

  Future<void> _onProvinceChanged(Province? province) async {
    setState(() {
      selectedProvince = province;
      selectedWard = null;
      wards = [];
    });
    if (province != null) {
      final wList = await _repository.getWardsByProvince(province.id);
      if (!mounted || selectedProvince?.id != province.id) {
        return;
      }
      setState(() {
        wards = wList;
      });
    }
  }

  void _applyFilter() {
    final filters = <String, dynamic>{};
    if (selectedProvince != null) filters['provinceId'] = selectedProvince!.id;
    if (selectedWard != null) filters['wardId'] = selectedWard!.id;
    if (selectedPropertyType != null) {
      filters['propertyType'] = selectedPropertyType;
    }

    if (priceRange.start > 0) filters['minPrice'] = priceRange.start;
    if (priceRange.end < 15000000) filters['maxPrice'] = priceRange.end;

    Navigator.pop(context, filters);
  }

  void _clearFilter() {
    setState(() {
      selectedProvince = null;
      selectedWard = null;
      selectedPropertyType = null;
      priceRange = const RangeValues(0, 15000000);
      wards = [];
    });
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} triệu';
    }
    return '${(value / 1000).toStringAsFixed(0)}k';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bộ lọc tìm kiếm',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Khu vực',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (isLoadingLocations)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    DropdownButtonFormField<Province>(
                      decoration: const InputDecoration(
                        labelText: 'Tỉnh/Thành phố',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedProvince,
                      items: provinces
                          .map(
                            (p) =>
                                DropdownMenuItem(value: p, child: Text(p.name)),
                          )
                          .toList(),
                      onChanged: _onProvinceChanged,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Ward>(
                      key: ValueKey(selectedWard?.id),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Phường / xã / đặc khu',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedWard,
                      items: wards
                          .map(
                            (w) =>
                                DropdownMenuItem(value: w, child: Text(w.name)),
                          )
                          .toList(),
                      onChanged: (w) => setState(() => selectedWard = w),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Loại hình',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Nhà nguyên căn'),
                        selected: selectedPropertyType == 'WHOLE_HOUSE',
                        onSelected: (val) => setState(
                          () =>
                              selectedPropertyType = val ? 'WHOLE_HOUSE' : null,
                        ),
                      ),
                      FilterChip(
                        label: const Text('Khu trọ'),
                        selected: selectedPropertyType == 'BOARDING_HOUSE',
                        onSelected: (val) => setState(
                          () => selectedPropertyType = val
                              ? 'BOARDING_HOUSE'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Khoảng giá',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Từ ${_formatCurrency(priceRange.start)} - ${_formatCurrency(priceRange.end)}',
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: priceRange,
                    min: 0,
                    max: 15000000,
                    divisions: 30,
                    labels: RangeLabels(
                      _formatCurrency(priceRange.start),
                      _formatCurrency(priceRange.end),
                    ),
                    onChanged: (values) => setState(() => priceRange = values),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilter,
                  child: const Text('Xóa bộ lọc'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _applyFilter,
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
