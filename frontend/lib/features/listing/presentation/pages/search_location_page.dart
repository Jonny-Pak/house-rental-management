import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../map/presentation/widgets/rental_map_tiles.dart';

class SearchLocation {
  const SearchLocation(this.point, this.name);
  final LatLng point;
  final String name;
}

class SearchLocationService {
  Future<LatLng> search(String address) async {
    final locations = await Geocoding().locationFromAddress(address);
    if (locations.isEmpty) {
      throw Exception('Không tìm thấy địa chỉ. Hãy chạm bản đồ để chọn.');
    }
    return LatLng(locations.first.latitude, locations.first.longitude);
  }

  Future<LatLng> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Hãy bật dịch vụ vị trí hoặc chạm bản đồ để chọn.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Chưa được cấp quyền vị trí. Bạn vẫn có thể chạm bản đồ để chọn.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LatLng(position.latitude, position.longitude);
  }
}

class SearchLocationPage extends StatefulWidget {
  const SearchLocationPage({super.key, this.initial, this.service});
  final SearchLocation? initial;
  final SearchLocationService? service;
  @override
  State<SearchLocationPage> createState() => _SearchLocationPageState();
}

class _SearchLocationPageState extends State<SearchLocationPage> {
  final _map = MapController();
  final _address = TextEditingController();
  late final _service = widget.service ?? SearchLocationService();
  late SearchLocation? _selected = widget.initial;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _map.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _locate(bool gps) async {
    if (_busy || !gps && _address.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    final query = _address.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final point = gps
          ? await _service.current()
          : await _service.search(query);
      if (!mounted) return;
      if (!point.latitude.isFinite ||
          !point.longitude.isFinite ||
          point.latitude.abs() > 90 ||
          point.longitude.abs() > 180) {
        throw Exception('Vị trí không hợp lệ. Vui lòng chọn lại.');
      }
      setState(
        () =>
            _selected = SearchLocation(point, gps ? 'Vị trí hiện tại' : query),
      );
      _map.move(point, 15);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = 'Không lấy được vị trí. Kiểm tra địa chỉ, GPS và quyền truy cập; hoặc chạm bản đồ để chọn.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chọn tâm tìm kiếm')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _address,
                  enabled: !_busy,
                  onSubmitted: (_) => _locate(false),
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ hoặc địa điểm',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Tìm địa chỉ',
                onPressed: _busy ? null : () => _locate(false),
                icon: const Icon(Icons.search),
              ),
              IconButton(
                tooltip: 'Vị trí hiện tại',
                onPressed: _busy ? null : () => _locate(true),
                icon: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter:
                  _selected?.point ?? const LatLng(10.7769, 106.7009),
              initialZoom: 13,
              onTap: _busy
                  ? null
                  : (_, point) => setState(() {
                      _selected = SearchLocation(
                        point,
                        'Điểm đã chọn trên bản đồ',
                      );
                      _error = null;
                    }),
            ),
            children: [
              const RentalMapTiles(),
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected!.point,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 42,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _selected?.name ??
                      'Chạm bản đồ, tìm địa chỉ hoặc dùng vị trí hiện tại.',
                ),
                if (_selected != null)
                  Text(
                    '${_selected!.point.latitude.toStringAsFixed(5)}, ${_selected!.point.longitude.toStringAsFixed(5)}',
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _selected == null || _busy
                      ? null
                      : () => Navigator.pop(context, _selected),
                  child: const Text('Dùng vị trí này'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
