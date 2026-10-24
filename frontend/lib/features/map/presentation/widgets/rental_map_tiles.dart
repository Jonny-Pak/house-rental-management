import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared basemap configuration for browsing and choosing a listing location.
class RentalMapTiles extends StatefulWidget {
  const RentalMapTiles({super.key});

  static const primaryUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
  );
  static const fallbackUrl = String.fromEnvironment(
    'MAP_TILE_FALLBACK_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  @override
  State<RentalMapTiles> createState() => _RentalMapTilesState();
}

class _RentalMapTilesState extends State<RentalMapTiles> {
  int _attempt = 0;
  bool _failed = false;
  bool _hasLoadedTile = false;
  bool _errorUpdateScheduled = false;
  late NetworkTileProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = NetworkTileProvider();
  }

  void _reportFailure() {
    if (!mounted || _hasLoadedTile || _failed || _errorUpdateScheduled) return;
    _errorUpdateScheduled = true;
    final attempt = _attempt;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _errorUpdateScheduled = false;
      if (mounted && attempt == _attempt && !_hasLoadedTile) {
        setState(() => _failed = true);
      }
    });
  }

  Widget _tileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    if (tile.loadFinishedAt != null && !tile.loadError) {
      _hasLoadedTile = true;
      if (_failed && !_errorUpdateScheduled) {
        _errorUpdateScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _errorUpdateScheduled = false;
          if (mounted) setState(() => _failed = false);
        });
      }
    }
    return tileWidget;
  }

  void _retry() {
    setState(() {
      _attempt++;
      _failed = false;
      _hasLoadedTile = false;
      _errorUpdateScheduled = false;
      // TileLayer disposes the previous provider when its key changes.
      _provider = NetworkTileProvider();
    });
  }

  @override
  Widget build(BuildContext context) {
    final attempt = _attempt;
    return Stack(
      fit: StackFit.expand,
      children: [
        TileLayer(
          key: ValueKey(attempt),
          urlTemplate: RentalMapTiles.primaryUrl,
          fallbackUrl: RentalMapTiles.fallbackUrl,
          tileProvider: _provider,
          userAgentPackageName: 'com.example.frontend',
          maxNativeZoom: 19,
          evictErrorTileStrategy:
              EvictErrorTileStrategy.notVisibleRespectMargin,
          tileBuilder: _tileBuilder,
          errorTileCallback: (_, _, _) {
            if (attempt == _attempt) _reportFailure();
          },
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: SafeArea(
            top: false,
            child: Material(
              color: const Color(0xE6FFFFFF),
              child: InkWell(
                onTap: () => launchUrl(
                  Uri.parse('https://www.openstreetmap.org/copyright'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const SizedBox(
                  width: 190,
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(
                      '© OpenStreetMap contributors',
                      style: TextStyle(fontSize: 10, color: Color(0xFF573B28)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_failed)
          Positioned(
            bottom: 100,
            left: 12,
            right: 12,
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                child: Row(
                  children: [
                    const Icon(Symbols.wifi_off, color: Colors.deepOrange),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Không tải được bản đồ. Kiểm tra kết nối mạng và thử lại.',
                      ),
                    ),
                    TextButton(onPressed: _retry, child: const Text('Thử lại')),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
