package com.rental.modules.listing.service;

import com.rental.modules.listing.dto.request.CreateListingRequest;
import com.rental.modules.listing.dto.response.ListingResponse;
import com.rental.modules.listing.dto.response.MapListingResponse;
import com.rental.modules.listing.domain.entity.Listing;
import com.rental.modules.listing.repository.ListingRepository;
import com.rental.modules.area.domain.entity.AdministrativeArea;
import com.rental.modules.area.repository.AdministrativeAreaRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.repository.UserRepository;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import com.rental.modules.listing.domain.entity.ListingImage;

import java.time.LocalDateTime;
import java.util.List;
import java.util.ArrayList;

@Service
@Transactional(readOnly = true)
public class ListingService {

    private final com.rental.modules.amenity.service.AmenityService amenities;
    private final ListingRepository listingRepository;
    private final com.rental.modules.subscription.service.SubscriptionBenefitService benefits;
    private final UserRepository userRepository;
    private final AdministrativeAreaRepository areaRepository;
    private final com.rental.modules.contract.repository.ContractRepository contracts;

    private final com.rental.modules.notification.service.NotificationService notifications;

    public ListingService(ListingRepository listingRepository, UserRepository userRepository, AdministrativeAreaRepository areaRepository, com.rental.modules.contract.repository.ContractRepository contracts, com.rental.modules.notification.service.NotificationService notifications, com.rental.modules.amenity.service.AmenityService amenities, com.rental.modules.subscription.service.SubscriptionBenefitService benefits) {
        this.benefits = benefits;
        this.amenities = amenities;
        this.notifications = notifications;
        this.listingRepository = listingRepository;
        this.userRepository = userRepository;
        this.areaRepository = areaRepository;
        this.contracts = contracts;
    }

    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    public List<MapListingResponse> searchListingsInBoundingBox(
            double minLat, double minLng, double maxLat, double maxLng) {

        if (!Double.isFinite(minLat) || !Double.isFinite(maxLat) || !Double.isFinite(minLng) || !Double.isFinite(maxLng)
                || minLat >= maxLat || minLng >= maxLng || minLat < -90 || maxLat > 90 || minLng < -180 || maxLng > 180) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Vùng bản đồ không hợp lệ.");
        }

        Coordinate[] coordinates = new Coordinate[]{
                new Coordinate(minLng, minLat),
                new Coordinate(minLng, maxLat),
                new Coordinate(maxLng, maxLat),
                new Coordinate(maxLng, minLat),
                new Coordinate(minLng, minLat)
        };

        Polygon bbox = geometryFactory.createPolygon(coordinates);

        List<Listing> listings = listingRepository.findListingsWithinBoundingBox(bbox);

        List<MapListingResponse> result = new ArrayList<>();
        for (Listing listing : listings) {
            if (listing.getLocation() != null) {
                result.add(toMapListingResponse(listing));
            }
        }
        return result;
    }

    public List<ListingResponse> getApprovedListings() {
        List<Listing> listings = new ArrayList<>(listingRepository.findByApprovalStatusAndRentalStatusOrderByCreatedAtDesc("APPROVED", "AVAILABLE"));
        listings.sort(this::comparePriority);
        return toListingResponses(listings);
    }

    private int comparePriority(Listing a, Listing b) {
        int vipOrder = Boolean.compare(isVipActive(b), isVipActive(a));
        if (vipOrder != 0) return vipOrder;
        LocalDateTime aTime = a.getRefreshedAt() == null ? a.getCreatedAt() : a.getRefreshedAt();
        LocalDateTime bTime = b.getRefreshedAt() == null ? b.getCreatedAt() : b.getRefreshedAt();
        int timeOrder = bTime.compareTo(aTime);
        return timeOrder != 0 ? timeOrder : b.getId().compareTo(a.getId());
    }

    private boolean isVipActive(Listing listing) {
        return Boolean.TRUE.equals(listing.getIsVip()) && listing.getVipExpiresAt() != null
                && listing.getVipExpiresAt().isAfter(LocalDateTime.now());
    }

    public List<ListingResponse> findNearby(double latitude, double longitude, double radiusKm) {
        if (!Double.isFinite(latitude) || latitude < -90 || latitude > 90
                || !Double.isFinite(longitude) || longitude < -180 || longitude > 180
                || !Double.isFinite(radiusKm) || radiusKm < 0.1 || radiusKm > 50) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Vị trí không hợp lệ hoặc bán kính phải từ 0,1 đến 50 km.");
        }
        return toListingResponses(listingRepository.findNearby(latitude, longitude, radiusKm * 1000));
    }

    public ListingResponse getPublicListing(Long id) {
        java.util.Optional<Listing> listingResult = listingRepository.findById(id);
        if (listingResult.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Tin đăng không còn khả dụng.");
        }
        Listing listing = listingResult.get();
        if (!"APPROVED".equals(listing.getApprovalStatus()) || !"AVAILABLE".equals(listing.getRentalStatus())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Tin đăng không còn khả dụng.");
        }
        ListingResponse response = toListingResponse(listing);
        response.setOwnerName(listing.getOwner().getFullName());
        response.setOwnerPhone(listing.getOwner().getPhoneNumber());
        return response;
    }

    private MapListingResponse toMapListingResponse(Listing listing) {
        MapListingResponse response = new MapListingResponse();
        response.setId(listing.getId());
        response.setTitle(listing.getTitle());
        response.setListingType(listing.getListingType());
        response.setRentPrice(listing.getRentPrice());
        response.setAddress(listing.getAddress());
        if (listing.getLocation() != null) {
            response.setLatitude(listing.getLocation().getY());
            response.setLongitude(listing.getLocation().getX());
        }
        return response;
    }

    @Transactional
    public ListingResponse createListing(Long ownerId, CreateListingRequest request) {
        java.util.Optional<User> ownerResult = userRepository.findById(ownerId);
        if (ownerResult.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found");
        }
        User owner = ownerResult.get();
        Listing listing = new Listing();
        listing.setOwner(owner);
        applyRequest(listing, request);
        benefits.use(ownerId, "STANDARD");
        listing.setApprovalStatus("PENDING");
        listing.setRentalStatus("AVAILABLE");
        listing.setCreatedAt(LocalDateTime.now());
        Listing saved = listingRepository.save(listing);
        notifications.send(ownerId, "LISTING_SUBMITTED", "Đã gửi tin chờ duyệt", saved.getTitle(), saved.getId(), null);
        notifications.notifyAdmins("Có tin mới cần duyệt", saved.getTitle(), saved.getId());
        return toListingResponse(saved);
    }

    public List<ListingResponse> getMyListings(Long ownerId) {
        List<Listing> listings = listingRepository.findByOwner_UserIdAndRentalStatusNotOrderByCreatedAtDesc(ownerId, "DELETED");
        return toListingResponses(listings);
    }

    @Transactional
    public ListingResponse updateListing(Long id, Long ownerId, CreateListingRequest request) {
        Listing listing = ownedListing(id, ownerId);
        applyRequest(listing, request);
        listing.setApprovalStatus("PENDING");
        listing.setApprovedBy(null);
        listing.setRejectionReason(null);
        listing.setUpdatedAt(LocalDateTime.now());
        Listing saved = listingRepository.save(listing);
        notifications.send(ownerId, "LISTING_SUBMITTED", "Tin đã gửi duyệt lại", saved.getTitle(), saved.getId(), null);
        notifications.notifyAdmins("Có tin chỉnh sửa cần duyệt", saved.getTitle(), saved.getId());
        return toListingResponse(saved);
    }

    @Transactional
    public ListingResponse updateRentalStatus(Long id, Long ownerId, String status) {
        if (!List.of("AVAILABLE", "RENTED", "HIDDEN").contains(status)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid rental status");
        }
        Listing listing = ownedListing(id, ownerId);
        listing.setRentalStatus(status);
        listing.setUpdatedAt(LocalDateTime.now());
        return toListingResponse(listingRepository.save(listing));
    }

    @Transactional
    public void deleteListing(Long id, Long ownerId) {
        Listing listing = ownedListing(id, ownerId);
        listing.setRentalStatus("DELETED");
        listing.setUpdatedAt(LocalDateTime.now());
        listingRepository.save(listing);
    }

    @Transactional
    public ListingResponse promoteVip(Long id, Long ownerId) {
        Listing listing = publicOwnedListing(id, ownerId);
        if (isVipActive(listing)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Tin đang có VIP, không trừ thêm lượt.");
        }
        LocalDateTime packageExpiry = benefits.use(ownerId, "VIP");
        LocalDateTime vipExpiry = LocalDateTime.now().plusDays(30);
        if (packageExpiry != null && packageExpiry.isBefore(vipExpiry)) vipExpiry = packageExpiry;
        listing.setIsVip(true);
        listing.setVipExpiresAt(vipExpiry);
        listing.setUpdatedAt(LocalDateTime.now());
        return toListingResponse(listingRepository.save(listing));
    }

    @Transactional
    public ListingResponse refreshListing(Long id, Long ownerId) {
        Listing listing = publicOwnedListing(id, ownerId);
        LocalDateTime now = LocalDateTime.now();
        if (listing.getRefreshedAt() != null && listing.getRefreshedAt().plusHours(24).isAfter(now)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Mỗi tin chỉ được làm mới một lần trong 24 giờ.");
        }
        benefits.use(ownerId, "REFRESH");
        listing.setRefreshedAt(now);
        listing.setUpdatedAt(now);
        return toListingResponse(listingRepository.save(listing));
    }

    private Listing publicOwnedListing(Long id, Long ownerId) {
        Listing listing = ownedListing(id, ownerId);
        if (!"APPROVED".equals(listing.getApprovalStatus()) || !"AVAILABLE".equals(listing.getRentalStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Chỉ áp dụng cho tin đã duyệt và còn trống.");
        }
        return listing;
    }

    private Listing ownedListing(Long id, Long ownerId) {
        java.util.Optional<Listing> listingResult = listingRepository.findLockedById(id);
        if (listingResult.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Listing not found");
        }
        Listing listing = listingResult.get();
        if (!listing.getOwner().getUserId().equals(ownerId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn chỉ được quản lý tin của mình.");
        }
        if ("DELETED".equals(listing.getRentalStatus())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Listing not found");
        }
        if (contracts.existsByListing_IdAndStatusInAndIdNot(id, List.of("ACTIVE"), -1L)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Tin đang có hợp đồng hiệu lực. Hãy quản lý hợp đồng trước khi thay đổi tin.");
        }
        return listing;
    }

    private void applyRequest(Listing listing, CreateListingRequest request) {
        if (!request.isSharedRoomValid()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thông tin ở ghép không hợp lệ hoặc không còn chỗ trống.");
        }
        java.util.Optional<AdministrativeArea> areaResult = areaRepository.findById(request.getAreaId());
        if (areaResult.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Khu vực không hợp lệ.");
        }
        AdministrativeArea area = areaResult.get();
        if (!area.isAvailable()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Khu vực đã ngừng sử dụng. Vui lòng chọn khu vực khác.");
        }
        if (!List.of("WARD", "COMMUNE", "SPECIAL").contains(area.getAreaType())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Vui lòng chọn phường/xã/đặc khu.");
        }
        Point location = geometryFactory.createPoint(new Coordinate(request.getLongitude(), request.getLatitude()));
        if (request.getAmenityIds() != null) {
            var selected = amenities.selectForListing(request.getAmenityIds(), listing.getAmenities());
            listing.getAmenities().clear();
            listing.getAmenities().addAll(selected);
        }
        listing.setArea(area);
        listing.setTitle(request.getTitle());
        listing.setDescription(request.getDescription());
        listing.setListingType(request.getListingType());
        listing.setRentPrice(request.getRentPrice());
        listing.setAreaSqm(request.getAreaSqm());
        listing.setAddress(request.getAddress());
        listing.setLocation(location);
        listing.setHouseType(request.getHouseType());
        listing.setBedrooms(request.getBedrooms());
        listing.setBathrooms(request.getBathrooms());
        listing.setTotalFloors(request.getTotalFloors());
        listing.setDoorDirection(request.getDoorDirection());
        listing.setLegalDocuments(request.getLegalDocuments());
        listing.setFurnitureStatus(request.getFurnitureStatus());
        listing.setDepositAmount(request.getDepositAmount());
        listing.setPosterType(request.getPosterType());
        listing.setCurrentOccupants("SHARED_ROOM".equals(request.getListingType()) ? request.getCurrentOccupants() : null);
        listing.setMaxOccupants("SHARED_ROOM".equals(request.getListingType()) ? request.getMaxOccupants() : null);
        listing.setGenderPreference("SHARED_ROOM".equals(request.getListingType()) ? request.getGenderPreference() : null);
        listing.setAllowPets("SHARED_ROOM".equals(request.getListingType()) ? request.getAllowPets() : null);
        listing.setAllowSmoking("SHARED_ROOM".equals(request.getListingType()) ? request.getAllowSmoking() : null);
        listing.setRoommateRequirements("SHARED_ROOM".equals(request.getListingType()) ? request.getRoommateRequirements() : null);
        listing.replaceImages(request.getImageUrls());
    }

    private List<ListingResponse> toListingResponses(List<Listing> listings) {
        List<ListingResponse> result = new ArrayList<>();
        for (Listing listing : listings) {
            result.add(toListingResponse(listing));
        }
        return result;
    }

    private ListingResponse toListingResponse(Listing listing) {
        ListingResponse response = new ListingResponse();
        response.setRejectionReason(listing.getRejectionReason());
        List<String> images = new ArrayList<>();
        for (ListingImage image : listing.getImages()) {
            images.add(image.getImageUrl());
        }
        response.setImageUrls(images);
        if (!images.isEmpty()) {
            response.setImageUrl(images.get(0));
        }
        response.setId(listing.getId());
        response.setTitle(listing.getTitle());
        response.setDescription(listing.getDescription());
        response.setListingType(listing.getListingType());
        response.setRentPrice(listing.getRentPrice());
        response.setAreaSqm(listing.getAreaSqm());
        response.setAddress(listing.getAddress());
        if (listing.getLocation() != null) {
            response.setLatitude(listing.getLocation().getY());
            response.setLongitude(listing.getLocation().getX());
        }
        if (listing.getOwner() != null) response.setOwnerId(listing.getOwner().getUserId());
        if (listing.getArea() != null) response.setAreaId(listing.getArea().getAreaId());
        response.setApprovalStatus(listing.getApprovalStatus());
        response.setRentalStatus(listing.getRentalStatus());
        response.setIsVip(isVipActive(listing));
        response.setVipExpiresAt(listing.getVipExpiresAt());
        response.setRefreshedAt(listing.getRefreshedAt());
        response.setViewCount(listing.getViewCount());
        response.setCreatedAt(listing.getCreatedAt());
        response.setHouseType(listing.getHouseType());
        response.setBedrooms(listing.getBedrooms());
        response.setBathrooms(listing.getBathrooms());
        response.setTotalFloors(listing.getTotalFloors());
        response.setDoorDirection(listing.getDoorDirection());
        response.setLegalDocuments(listing.getLegalDocuments());
        response.setFurnitureStatus(listing.getFurnitureStatus());
        java.util.List<com.rental.modules.amenity.dto.AmenityResponse> selectedAmenities = new java.util.ArrayList<>();
        for (var item : listing.getAmenities()) selectedAmenities.add(com.rental.modules.amenity.dto.AmenityResponse.from(item, null));
        response.setAmenities(selectedAmenities);
        response.setDepositAmount(listing.getDepositAmount());
        response.setPosterType(listing.getPosterType());
        response.setCurrentOccupants(listing.getCurrentOccupants());
        response.setMaxOccupants(listing.getMaxOccupants());
        response.setGenderPreference(listing.getGenderPreference());
        response.setAllowPets(listing.getAllowPets());
        response.setAllowSmoking(listing.getAllowSmoking());
        response.setRoommateRequirements(listing.getRoommateRequirements());

        return response;
    }
}
