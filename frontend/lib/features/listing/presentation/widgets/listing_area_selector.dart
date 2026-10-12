import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_client.dart';
import '../../../preferences/data/datasources/area_remote_data_source.dart';
import '../../../preferences/data/models/area_models.dart';
import '../../data/repositories/listing_repository.dart';

class ListingAreaSelector extends StatefulWidget {
  const ListingAreaSelector({
    super.key,
    required this.onChanged,
    this.dataSource,
  });
  final ValueChanged<int?> onChanged;
  final AreaRemoteDataSource? dataSource;

  @override
  State<ListingAreaSelector> createState() => _ListingAreaSelectorState();
}

class _ListingAreaSelectorState extends State<ListingAreaSelector> {
  late final AreaRemoteDataSource _areas;
  int _request = 0;
  List<Province> _provinces = [];
  List<Ward> _wards = [];
  int? _province, _ward;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _areas = widget.dataSource ?? AreaRemoteDataSourceImpl(ApiClient());
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _areas.getProvinces();
      if (mounted) {
        setState(() {
          _provinces = result;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = ListingRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectProvince(int? id) async {
    widget.onChanged(null);
    setState(() {
      _province = id;
      _ward = null;
      _wards = [];
    });
    await _reloadAreas();
  }

  Future<void> _reloadAreas() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provinces = await _areas.getProvinces();
      if (!mounted || request != _request) return;
      final province = provinces.any((p) => p.id == _province)
          ? _province
          : null;
      final wards = province == null
          ? <Ward>[]
          : await _areas.getWardsByProvince(province);
      if (!mounted || request != _request) return;
      final ward = wards.any((w) => w.id == _ward) ? _ward : null;
      setState(() {
        _provinces = provinces;
        _wards = wards;
        _province = province;
        _ward = ward;
      });
      widget.onChanged(ward);
    } catch (e) {
      if (mounted && request == _request) {
        setState(() => _error = ListingRepository.errorMessage(e));
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _chooseWard() async {
    final ward = await showModalBottomSheet<Ward>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _WardSearchSheet(wards: _wards, selectedId: _ward),
    );
    if (ward != null && mounted) {
      setState(() => _ward = ward.id);
      widget.onChanged(ward.id);
    }
  }

  Widget _dropdown(
    String label,
    int? value,
    List<DropdownMenuItem<int>> items,
    ValueChanged<int?> action,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        key: ValueKey('$label:$value'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: items,
        onChanged: _loading ? null : action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _dropdown(
        'Tỉnh / thành phố',
        _province,
        _provinces
            .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
            .toList(),
        _selectProvince,
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: _loading || _wards.isEmpty ? null : _chooseWard,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Phường / xã / đặc khu',
              enabled: !_loading && _wards.isNotEmpty,
              suffixIcon: const Icon(Symbols.expand_more),
            ),
            child: Text(
              _ward == null
                  ? 'Chọn phường / xã / đặc khu'
                  : _wards.firstWhere((w) => w.id == _ward).name,
            ),
          ),
        ),
      ),
      if (_loading) const LinearProgressIndicator(),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: _loading ? null : _reloadAreas,
          icon: const Icon(Symbols.refresh, size: 18),
          label: const Text('Tải lại khu vực'),
        ),
      ),
      if (!_loading && _province != null && _wards.isEmpty && _error == null)
        const Text('Chưa có dữ liệu phường/xã mới cho khu vực này.'),
      if (!_loading && _provinces.isEmpty && _error == null)
        const Text('Chưa có dữ liệu khu vực trên máy chủ.'),
      if (_error != null) ...[
        Text(_error!, style: const TextStyle(color: Colors.red)),
        TextButton(onPressed: _reloadAreas, child: const Text('Thử lại')),
      ],
    ],
  );
}

class _WardSearchSheet extends StatefulWidget {
  const _WardSearchSheet({required this.wards, required this.selectedId});
  final List<Ward> wards;
  final int? selectedId;

  @override
  State<_WardSearchSheet> createState() => _WardSearchSheetState();
}

class _WardSearchSheetState extends State<_WardSearchSheet> {
  String _query = '';

  String _searchKey(String text) {
    const groups = [
      'aàáạảãâầấậẩẫăằắặẳẵ',
      'eèéẹẻẽêềếệểễ',
      'iìíịỉĩ',
      'oòóọỏõôồốộổỗơờớợởỡ',
      'uùúụủũưừứựửữ',
      'yỳýỵỷỹ',
      'dđ',
    ];
    var result = text.toLowerCase().trim();
    for (final group in groups) {
      for (final rune in group.runes) {
        result = result.replaceAll(String.fromCharCode(rune), group[0]);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final wards = widget.wards
        .where((w) => _searchKey(w.name).contains(_searchKey(_query)))
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tìm phường / xã / đặc khu',
                    prefixIcon: Icon(Symbols.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              if (wards.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Không tìm thấy khu vực phù hợp.'),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: wards.length,
                  itemBuilder: (context, index) {
                    final ward = wards[index];
                    return ListTile(
                      title: Text(ward.name),
                      selected: ward.id == widget.selectedId,
                      trailing: ward.id == widget.selectedId
                          ? const Icon(Symbols.check)
                          : null,
                      onTap: () => Navigator.pop(context, ward),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
