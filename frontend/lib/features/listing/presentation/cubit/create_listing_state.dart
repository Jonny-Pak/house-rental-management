import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Status of the overall create-listing form.
enum CreateListingStatus { draft, submitting, success, error }

/// Holds all draft data across all steps of the multi-step listing form.
class CreateListingState extends Equatable {
  // ── Step 1: Listing Type ────────────────────────────────────────────────────
  /// 'WHOLE_HOUSE' or 'BOARDING_ROOM'
  final String propertyType;

  // ── Step 2: Location (Map) ───────────────────────────────────────────────────
  /// Ordered list of points the user tapped to define the property polygon.
  final List<LatLng> polygonPoints;

  /// Area calculated from [polygonPoints] in square metres (0 if < 3 points).
  final double calculatedArea;

  /// Human-readable address string entered or geocoded by the user.
  final String address;

  /// The pinned location from geocoding or GPS. User can drag to adjust.
  final LatLng? pinnedLocation;

  /// Whether a geocoding search is currently in progress.
  final bool isSearching;

  /// GPS latitude of the polygon centroid (or first point as fallback).
  final double? latitude;

  /// GPS longitude of the polygon centroid (or first point as fallback).
  final double? longitude;

  // ── Step 3: House Details ─────────────────────────────────────────────────
  /// MAT_PHO | NGO_HEM | BIET_THU | LIEN_KE
  final String? houseType;
  final int? bedrooms;
  final int? bathrooms;
  final int? totalFloors;
  /// NORTH | SOUTH | EAST | WEST | NORTHEAST | NORTHWEST | SOUTHEAST | SOUTHWEST
  final String? doorDirection;
  /// PINK_BOOK | RED_BOOK | SALE_CONTRACT | NONE
  final String? legalDocuments;
  /// FULL | BASIC | EMPTY
  final String? furnitureStatus;

  // ── Step 4: Pricing ──────────────────────────────────────────────────────────
  final double? rentPrice;
  final double? depositAmount;
  /// CA_NHAN | MOI_GIOI
  final String? posterType;

  // ── Step 5: General Info & Images ───────────────────────────────────────────
  final String title;
  final String description;
  final List<String> imagePaths;

  // ── Submission status ─────────────────────────────────────────────────────────
  final CreateListingStatus status;
  final String? errorMessage;

  const CreateListingState({
    this.propertyType = 'WHOLE_HOUSE',
    this.polygonPoints = const [],
    this.calculatedArea = 0.0,
    this.address = '',
    this.pinnedLocation,
    this.isSearching = false,
    this.latitude,
    this.longitude,
    this.houseType,
    this.bedrooms,
    this.bathrooms,
    this.totalFloors,
    this.doorDirection,
    this.legalDocuments,
    this.furnitureStatus,
    this.rentPrice,
    this.depositAmount,
    this.posterType,
    this.title = '',
    this.description = '',
    this.imagePaths = const [],
    this.status = CreateListingStatus.draft,
    this.errorMessage,
  });

  CreateListingState copyWith({
    String? propertyType,
    List<LatLng>? polygonPoints,
    double? calculatedArea,
    String? address,
    LatLng? pinnedLocation,
    bool? isSearching,
    double? latitude,
    double? longitude,
    String? houseType,
    int? bedrooms,
    int? bathrooms,
    int? totalFloors,
    String? doorDirection,
    String? legalDocuments,
    String? furnitureStatus,
    double? rentPrice,
    double? depositAmount,
    String? posterType,
    String? title,
    String? description,
    List<String>? imagePaths,
    CreateListingStatus? status,
    String? errorMessage,
    // Sentinel flags to explicitly set nullable fields to null
    bool clearHouseType = false,
    bool clearDoorDirection = false,
    bool clearLegalDocuments = false,
    bool clearFurnitureStatus = false,
    bool clearPinnedLocation = false,
    bool clearError = false,
  }) {
    return CreateListingState(
      propertyType: propertyType ?? this.propertyType,
      polygonPoints: polygonPoints ?? this.polygonPoints,
      calculatedArea: calculatedArea ?? this.calculatedArea,
      address: address ?? this.address,
      pinnedLocation: clearPinnedLocation ? null : (pinnedLocation ?? this.pinnedLocation),
      isSearching: isSearching ?? this.isSearching,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      houseType: clearHouseType ? null : (houseType ?? this.houseType),
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      totalFloors: totalFloors ?? this.totalFloors,
      doorDirection: clearDoorDirection ? null : (doorDirection ?? this.doorDirection),
      legalDocuments: clearLegalDocuments ? null : (legalDocuments ?? this.legalDocuments),
      furnitureStatus: furnitureStatus ?? this.furnitureStatus,
      rentPrice: rentPrice ?? this.rentPrice,
      depositAmount: depositAmount ?? this.depositAmount,
      posterType: posterType ?? this.posterType,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePaths: imagePaths ?? this.imagePaths,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// True when the polygon has enough points to draw a closed shape.
  bool get hasPolygon => polygonPoints.length >= 3;

  @override
  List<Object?> get props => [
        propertyType,
        polygonPoints,
        calculatedArea,
        address,
        pinnedLocation,
        isSearching,
        latitude,
        longitude,
        houseType,
        bedrooms,
        bathrooms,
        totalFloors,
        doorDirection,
        legalDocuments,
        furnitureStatus,
        rentPrice,
        depositAmount,
        posterType,
        title,
        description,
        imagePaths,
        status,
        errorMessage,
      ];
}

