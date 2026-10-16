import 'package:flutter/material.dart';

import '../../../../core/layout/app_layout.dart';

import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_client.dart';
import '../../../preferences/data/datasources/area_remote_data_source.dart';
import '../../../preferences/data/models/area_models.dart';
import '../../data/models/listing_filter.dart';
import '../../data/repositories/listing_repository.dart';
import 'listing_area_selector.dart';

class ListingFilterBar extends StatefulWidget {
  const ListingFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    this.autofocus = false,
    this.areas,
  });
  final ListingFilter filter;
  final ValueChanged<ListingFilter> onChanged;
  final bool autofocus;
  final AreaRemoteDataSource? areas;
  @override
  State<ListingFilterBar> createState() => _ListingFilterBarState();
}

class _ListingFilterBarState extends State<ListingFilterBar> {
  late final _search = TextEditingController(text: widget.filter.query);
  @override
  void didUpdateWidget(covariant ListingFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_search.text != widget.filter.query) _search.text = widget.filter.query;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _filters() async {
    final Widget sheet = ListingFilterSheet(
      initial: widget.filter,
      areas: widget.areas,
    );
    final ListingFilter? result;
    if (MediaQuery.sizeOf(context).width >= AppLayout.compact) {
      result = await showDialog<ListingFilter>(
        context: context,
        builder: (_) => Dialog(child: SizedBox(width: 560, child: sheet)),
      );
    } else {
      result = await showModalBottomSheet<ListingFilter>(
        context: context,
        isScrollControlled: true,
        builder: (_) => sheet,
      );
    }
    if (mounted && result != null) widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  autofocus: widget.autofocus,
                  onChanged: (q) =>
                      widget.onChanged(widget.filter.withQuery(q)),
                  decoration: InputDecoration(
                    hintText: 'Tìm tên nhà, địa chỉ…',
                    prefixIcon: const Icon(Symbols.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xóa từ khóa',
                            onPressed: () =>
                                widget.onChanged(widget.filter.withQuery('')),
                            icon: const Icon(Symbols.close),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Bộ lọc',
                onPressed: _filters,
                icon: const Icon(Symbols.tune),
              ),
            ],
          ),
          if (widget.filter.count > 0)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.filter.count} bộ lọc${widget.filter.areaName == null ? '' : ' • ${widget.filter.areaName}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onChanged(const ListingFilter()),
                  child: const Text('Xóa bộ lọc'),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

class ListingFilterSheet extends StatefulWidget {
  const ListingFilterSheet({super.key, required this.initial, this.areas});
  final ListingFilter initial;
  final AreaRemoteDataSource? areas;
  @override
  State<ListingFilterSheet> createState() => _ListingFilterSheetState();
}

class _ListingFilterSheetState extends State<ListingFilterSheet> {
  late final _areas = widget.areas ?? AreaRemoteDataSourceImpl(ApiClient());
  final _form = GlobalKey<FormState>();
  late final _minPrice = TextEditingController(
    text: _number(widget.initial.minPrice),
  );
  late final _maxPrice = TextEditingController(
    text: _number(widget.initial.maxPrice),
  );
  late final _minArea = TextEditingController(
    text: _number(widget.initial.minArea),
  );
  late final _maxArea = TextEditingController(
    text: _number(widget.initial.maxArea),
  );
  late String? _type = widget.initial.listingType;
  late String _sort = widget.initial.sort;
  late int? _areaId = widget.initial.areaId;
  late String? _areaName = widget.initial.areaName;
  List<Ward> _wards = [];
  bool _loading = true;
  String? _areaError, _error;
  String _number(double? n) => n == null
      ? ''
      : n == n.roundToDouble()
      ? n.toInt().toString()
      : n.toString();
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_minPrice, _maxPrice, _minArea, _maxArea]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _areaError = null;
    });
    try {
      final provinces = await _areas.getProvinces();
      final hcm = provinces.where((p) => p.code == 'SG');
      final wards = hcm.isEmpty
          ? <Ward>[]
          : await _areas.getWardsByProvince(hcm.first.id);
      if (mounted) setState(() => _wards = wards);
    } catch (e) {
      if (mounted) {
        setState(() => _areaError = ListingRepository.errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chooseArea() async {
    final ward = await showModalBottomSheet<Ward>(
      context: context,
      isScrollControlled: true,
      builder: (_) => WardSearchSheet(wards: _wards, selectedId: _areaId),
    );
    if (ward != null && mounted) {
      setState(() {
        _areaId = ward.id;
        _areaName = ward.name;
      });
    }
  }

  double? _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));
  Widget _input(
    String label,
    TextEditingController controller, {
    bool price = false,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(decimal: !price),
    inputFormatters: [
      price
          ? FilteringTextInputFormatter.digitsOnly
          : FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
    ],
    decoration: InputDecoration(
      labelText: label,
      hintText: price ? 'VD: 3000000' : 'VD: 25,5',
    ),
    validator: (value) =>
        value!.trim().isEmpty ||
            _parse(controller) != null && _parse(controller)!.isFinite
        ? null
        : 'Nhập số hợp lệ.',
  );
  void _apply() {
    if (!_form.currentState!.validate()) return;
    final filter = ListingFilter(
      query: widget.initial.query,
      areaId: _areaId,
      areaName: _areaName,
      listingType: _type,
      minPrice: _parse(_minPrice),
      maxPrice: _parse(_maxPrice),
      minArea: _parse(_minArea),
      maxArea: _parse(_maxArea),
      sort: _sort,
    );
    if (filter.validationError != null) {
      setState(() => _error = filter.validationError);
      return;
    }
    Navigator.pop(context, filter);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Lọc tin cho thuê',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, const ListingFilter()),
                    child: const Text('Đặt lại'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const Text('Khu vực TP.HCM sau sáp nhập'),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_areaName ?? 'Tất cả phường / xã / đặc khu'),
                      trailing: _areaId == null
                          ? const Icon(Symbols.expand_more)
                          : IconButton(
                              tooltip: 'Bỏ chọn khu vực',
                              onPressed: () => setState(() {
                                _areaId = null;
                                _areaName = null;
                              }),
                              icon: const Icon(Symbols.close),
                            ),
                      onTap: _loading || _wards.isEmpty ? null : _chooseArea,
                    ),
                    if (_loading) const LinearProgressIndicator(),
                    if (_areaError != null) ...[
                      Text(_areaError!),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Tải lại khu vực'),
                      ),
                    ],
                    if (!_loading && _wards.isEmpty && _areaError == null)
                      const Text('Chưa có dữ liệu khu vực mới.'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _type ?? '',
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Loại nhà'),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Tất cả')),
                        DropdownMenuItem(
                          value: 'WHOLE_HOUSE',
                          child: Text('Nhà nguyên căn'),
                        ),
                        DropdownMenuItem(
                          value: 'BOARDING_ROOM',
                          child: Text('Phòng trọ'),
                        ),
                        DropdownMenuItem(
                          value: 'APARTMENT',
                          child: Text('Căn hộ'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _type = v == '' ? null : v),
                    ),
                    const SizedBox(height: 20),
                    const Text('Giá thuê (VNĐ/tháng)'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _input('Giá từ', _minPrice, price: true),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _input('Giá đến', _maxPrice, price: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Diện tích (m²)'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _input('Diện tích từ', _minArea)),
                        const SizedBox(width: 12),
                        Expanded(child: _input('Diện tích đến', _maxArea)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _sort,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Sắp xếp'),
                      items: const [
                        DropdownMenuItem(
                          value: 'newest',
                          child: Text('Mới nhất'),
                        ),
                        DropdownMenuItem(
                          value: 'priceAsc',
                          child: Text('Giá thấp đến cao'),
                        ),
                        DropdownMenuItem(
                          value: 'priceDesc',
                          child: Text('Giá cao đến thấp'),
                        ),
                        DropdownMenuItem(
                          value: 'areaDesc',
                          child: Text('Diện tích lớn nhất'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _sort = v!),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Áp dụng'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
