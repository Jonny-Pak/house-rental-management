import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'create_listing_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Area calculation utility (spherical excess / Shoelace on Web Mercator)
// ─────────────────────────────────────────────────────────────────────────────

/// Converts decimal degrees to radians.
double _toRad(double deg) => deg * math.pi / 180.0;

/// Projects WGS84 longitude to Web Mercator X (metres).
double _mercatorX(double lng) => 6378137.0 * _toRad(lng);

/// Projects WGS84 latitude to Web Mercator Y (metres).
/// Uses the standard Mercator formula: R * ln(tan(π/4 + φ/2)).
double _mercatorY(double lat) =>
    6378137.0 * math.log(math.tan(math.pi / 4 + _toRad(lat) / 2));

/// Calculates the signed area (in m²) of a polygon defined by [points]
/// using the **Shoelace formula on a Web Mercator projection**.
///
/// Accuracy is excellent for property-scale polygons (< 1 km²) which is
/// exactly the use-case here. For continent-scale you would use spherical
/// excess instead.
///
/// Returns the **absolute** area (always non-negative).
double calculatePolygonArea(List<LatLng> points) {
  if (points.length < 3) return 0.0;

  // Project all points to Mercator (x, y) in metres.
  final xs = points.map((p) => _mercatorX(p.longitude)).toList();
  final ys = points.map((p) => _mercatorY(p.latitude)).toList();

  final n = xs.length;
  double area = 0.0;

  // Shoelace (Gauss) formula: A = ½ |Σ(xᵢ·yᵢ₊₁ − xᵢ₊₁·yᵢ)|
  for (int i = 0; i < n; i++) {
    final j = (i + 1) % n;
    area += xs[i] * ys[j];
    area -= xs[j] * ys[i];
  }

  return (area.abs() / 2.0);
}

/// Computes the geographic centroid of a polygon (average of vertices).
/// Simple centroid — accurate enough for a pin placement.
LatLng _centroid(List<LatLng> points) {
  final lat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
  final lng = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
  return LatLng(lat, lng);
}

// ─────────────────────────────────────────────────────────────────────────────
// Cubit
// ─────────────────────────────────────────────────────────────────────────────

class CreateListingCubit extends Cubit<CreateListingState> {
  CreateListingCubit() : super(const CreateListingState());

  // ── Step 1 helpers ─────────────────────────────────────────────────────────

  void updatePropertyType(String type) =>
      emit(state.copyWith(propertyType: type));

  // ── Step 2 – Map / Polygon helpers ─────────────────────────────────────────

  /// Appends [point] to the polygon vertex list and recalculates area.
  void addPolygonPoint(LatLng point) {
    final updated = [...state.polygonPoints, point];
    final area = calculatePolygonArea(updated);

    // Update centroid lat/lng when we have a valid polygon.
    LatLng? center;
    if (updated.length >= 3) center = _centroid(updated);

    emit(state.copyWith(
      polygonPoints: updated,
      calculatedArea: area,
      latitude: center?.latitude ?? (updated.isNotEmpty ? updated.last.latitude : null),
      longitude: center?.longitude ?? (updated.isNotEmpty ? updated.last.longitude : null),
    ));
  }

  /// Removes the last added polygon point and recalculates area.
  void undoLastPoint() {
    if (state.polygonPoints.isEmpty) return;
    final updated = state.polygonPoints.sublist(0, state.polygonPoints.length - 1);
    final area = calculatePolygonArea(updated);
    LatLng? center;
    if (updated.length >= 3) center = _centroid(updated);

    emit(state.copyWith(
      polygonPoints: updated,
      calculatedArea: area,
      latitude: center?.latitude,
      longitude: center?.longitude,
    ));
  }

  /// Clears all polygon points and resets the area to zero.
  void clearPolygon() {
    emit(state.copyWith(
      polygonPoints: const [],
      calculatedArea: 0.0,
    ));
  }

  /// Updates the human-readable address string.
  void updateAddress(String address) => emit(state.copyWith(address: address));

  /// Updates the pinned location on the map (e.g. from dragging)
  void updatePinnedLocation(LatLng location) {
    emit(state.copyWith(
      pinnedLocation: location,
      latitude: location.latitude,
      longitude: location.longitude,
    ));
  }

  /// Geocode the current address string to get a LatLng pin.
  Future<void> searchAddress() async {
    final query = state.address.trim();
    if (query.isEmpty) return;

    emit(state.copyWith(isSearching: true));
    try {
      final geocoding = Geocoding();
      final locations = await geocoding.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final pin = LatLng(loc.latitude, loc.longitude);
        emit(state.copyWith(
          pinnedLocation: pin,
          latitude: loc.latitude,
          longitude: loc.longitude,
          isSearching: false,
        ));
      } else {
        emit(state.copyWith(isSearching: false));
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      emit(state.copyWith(isSearching: false));
    }
  }

  /// Use the device's GPS to get current location and pin it.
  Future<void> useCurrentLocation() async {
    emit(state.copyWith(isSearching: true));
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(state.copyWith(isSearching: false));
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        emit(state.copyWith(isSearching: false));
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final pin = LatLng(position.latitude, position.longitude);

      // Reverse geocode to get address
      String addressStr = '';
      try {
        final geocoding = Geocoding();
        final placemarks = await geocoding.placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if (p.street != null && p.street!.isNotEmpty) p.street!,
            if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
            if (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty) p.subAdministrativeArea!,
            if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) p.administrativeArea!,
          ];
          addressStr = parts.join(', ');
        }
      } catch (_) {
        // Reverse geocoding failed, that's fine, just don't set address
      }

      emit(state.copyWith(
        pinnedLocation: pin,
        latitude: position.latitude,
        longitude: position.longitude,
        address: addressStr.isNotEmpty ? addressStr : state.address,
        isSearching: false,
      ));
    } catch (e) {
      debugPrint('Geolocator error: $e');
      emit(state.copyWith(isSearching: false));
    }
  }

  // ── Step 3 – House detail helpers ──────────────────────────────────────────

  void updateHouseType(String? type) =>
      type == null ? emit(state.copyWith(clearHouseType: true)) : emit(state.copyWith(houseType: type));

  void updateBedrooms(int? count) => emit(state.copyWith(bedrooms: count));
  void updateBathrooms(int? count) => emit(state.copyWith(bathrooms: count));
  void updateTotalFloors(int? count) => emit(state.copyWith(totalFloors: count));

  void updateDoorDirection(String? dir) =>
      dir == null ? emit(state.copyWith(clearDoorDirection: true)) : emit(state.copyWith(doorDirection: dir));

  void updateLegalDocuments(String? doc) =>
      doc == null ? emit(state.copyWith(clearLegalDocuments: true)) : emit(state.copyWith(legalDocuments: doc));

  void updateFurnitureStatus(String? status) =>
      emit(state.copyWith(furnitureStatus: status));

  // ── Step 4 – Pricing helpers ───────────────────────────────────────────────

  void updateRentPrice(double? price) => emit(state.copyWith(rentPrice: price));
  void updateDepositAmount(double? amount) => emit(state.copyWith(depositAmount: amount));
  void updatePosterType(String? type) => emit(state.copyWith(posterType: type));

  // ── Step 5 – General info helpers ─────────────────────────────────────────

  void updateTitle(String title) => emit(state.copyWith(title: title));
  void updateDescription(String description) =>
      emit(state.copyWith(description: description));

  // ── Image helpers ──────────────────────────────────────────────────────────

  void addImages(List<String> paths) {
    emit(state.copyWith(imagePaths: [...state.imagePaths, ...paths]));
  }

  void removeImage(int index) {
    final updated = List<String>.from(state.imagePaths)..removeAt(index);
    emit(state.copyWith(imagePaths: updated));
  }

  // ── Full reset ─────────────────────────────────────────────────────────────

  /// Resets the entire draft back to initial state (e.g., after successful submission).
  void reset() => emit(const CreateListingState());
}
