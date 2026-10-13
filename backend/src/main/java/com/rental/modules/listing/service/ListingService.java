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
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class ListingService {

    private final ListingRepository listingRepository;
    private final UserRepository userRepository;
    private final AdministrativeAreaRepository areaRepository;

    public ListingService(ListingRepository listingRepository, UserRepository userRepository, AdministrativeAreaRepository areaRepository) {
        this.listingRepository = listingRepository;
        this.userRepository = userRepository;
        this.areaRepository = areaRepository;
    }


    /**
     * GeometryFactory vÃ¡Â»â€ºi SRID=4326 (WGS84 - hÃ¡Â»â€¡ tÃ¡Â»Âa Ã„â€˜Ã¡Â»â„¢ GPS chuÃ¡ÂºÂ©n quÃ¡Â»â€˜c tÃ¡ÂºÂ¿).
     * PhÃ¡ÂºÂ£i khÃ¡Â»â€ºp vÃ¡Â»â€ºi kiÃ¡Â»Æ’u cÃ¡Â»â„¢t trong DB: geometry(Point, 4326).
     */
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    /**
     * TÃƒÂ¬m kiÃ¡ÂºÂ¿m Listing nÃ¡ÂºÂ±m trong vÃƒÂ¹ng nhÃƒÂ¬n thÃ¡ÂºÂ¥y trÃƒÂªn bÃ¡ÂºÂ£n Ã„â€˜Ã¡Â»â€œ (bounding box).
     *
     * @param minLat VÃ„Â© Ã„â€˜Ã¡Â»â„¢ nhÃ¡Â»Â nhÃ¡ÂºÂ¥t (gÃƒÂ³c dÃ†Â°Ã¡Â»â€ºi-trÃƒÂ¡i)
     * @param minLng Kinh Ã„â€˜Ã¡Â»â„¢ nhÃ¡Â»Â nhÃ¡ÂºÂ¥t (gÃƒÂ³c dÃ†Â°Ã¡Â»â€ºi-trÃƒÂ¡i)
     * @param maxLat VÃ„Â© Ã„â€˜Ã¡Â»â„¢ lÃ¡Â»â€ºn nhÃ¡ÂºÂ¥t (gÃƒÂ³c trÃƒÂªn-phÃ¡ÂºÂ£i)
     * @param maxLng Kinh Ã„â€˜Ã¡Â»â„¢ lÃ¡Â»â€ºn nhÃ¡ÂºÂ¥t (gÃƒÂ³c trÃƒÂªn-phÃ¡ÂºÂ£i)
     */
    public List<MapListingResponse> searchListingsInBoundingBox(
            double minLat, double minLng, double maxLat, double maxLng) {

        if (!Double.isFinite(minLat) || !Double.isFinite(maxLat) || !Double.isFinite(minLng) || !Double.isFinite(maxLng)
                || minLat >= maxLat || minLng >= maxLng || minLat < -90 || maxLat > 90 || minLng < -180 || maxLng > 180) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Vùng bản đồ không hợp lệ.");
        }

        // TÃ¡ÂºÂ¡o Polygon Ã„â€˜Ã¡ÂºÂ¡i diÃ¡Â»â€¡n cho vÃƒÂ¹ng bÃ¡ÂºÂ£n Ã„â€˜Ã¡Â»â€œ Ã„â€˜ang hiÃ¡Â»Æ’n thÃ¡Â»â€¹.
        // ThÃ¡Â»Â© tÃ¡Â»Â± Coordinate trong JTS lÃƒÂ  (longitude, latitude) tÃ¡Â»Â©c lÃƒÂ  (X, Y).
        // Polygon phÃ¡ÂºÂ£i khÃƒÂ©p kÃƒÂ­n: Ã„â€˜iÃ¡Â»Æ’m Ã„â€˜Ã¡ÂºÂ§u vÃƒÂ  cuÃ¡Â»â€˜i PHÃ¡ÂºÂ¢I giÃ¡Â»â€˜ng nhau.
        Coordinate[] coordinates = new Coordinate[]{
                new Coordinate(minLng, minLat), // DÃ†Â°Ã¡Â»â€ºi-TrÃƒÂ¡i
                new Coordinate(minLng, maxLat), // TrÃƒÂªn-TrÃƒÂ¡i
                new Coordinate(maxLng, maxLat), // TrÃƒÂªn-PhÃ¡ÂºÂ£i
                new Coordinate(maxLng, minLat), // DÃ†Â°Ã¡Â»â€ºi-PhÃ¡ÂºÂ£i
                new Coordinate(minLng, minLat)  // KhÃƒÂ©p kÃƒÂ­n vÃ¡Â»Â Ã„â€˜iÃ¡Â»Æ’m ban Ã„â€˜Ã¡ÂºÂ§u
        };

        Polygon bbox = geometryFactory.createPolygon(coordinates);

        List<Listing> listings = listingRepository.findListingsWithinBoundingBox(bbox);

        return listings.stream()
                .filter(l -> l.getLocation() != null)
                .map(this::toMapListingResponse)
                .collect(Collectors.toList());
    }

    public List<ListingResponse> getApprovedListings() {
        return listingRepository.findByApprovalStatusAndRentalStatusOrderByCreatedAtDesc("APPROVED", "AVAILABLE")
                .stream()
                .map(this::toListingResponse)
                .collect(Collectors.toList());
    }

    public ListingResponse getPublicListing(Long id) {
        Listing listing = listingRepository.findById(id).orElseThrow(() ->
                new ResponseStatusException(HttpStatus.NOT_FOUND, "Tin đăng không còn khả dụng."));
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
        User owner = userRepository.findById(ownerId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        Listing listing = new Listing();
        listing.setOwner(owner);
        applyRequest(listing, request);
        listing.setApprovalStatus("PENDING");
        listing.setRentalStatus("AVAILABLE");
        listing.setCreatedAt(LocalDateTime.now());
        return toListingResponse(listingRepository.save(listing));
    }

    public List<ListingResponse> getMyListings(Long ownerId) {
        return listingRepository.findByOwner_UserIdAndRentalStatusNotOrderByCreatedAtDesc(ownerId, "DELETED")
                .stream().map(this::toListingResponse).toList();
    }

    @Transactional
    public ListingResponse updateListing(Long id, Long ownerId, CreateListingRequest request) {
        Listing listing = ownedListing(id, ownerId);
        applyRequest(listing, request);
        listing.setApprovalStatus("PENDING");
        listing.setApprovedBy(null);
        listing.setRejectionReason(null);
        listing.setUpdatedAt(LocalDateTime.now());
        return toListingResponse(listingRepository.save(listing));
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

    private Listing ownedListing(Long id, Long ownerId) {
        Listing listing = listingRepository.findLockedById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Listing not found"));
        if (!listing.getOwner().getUserId().equals(ownerId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn chỉ được quản lý tin của mình.");
        }
        if ("DELETED".equals(listing.getRentalStatus())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Listing not found");
        }
        return listing;
    }

    private void applyRequest(Listing listing, CreateListingRequest request) {
        AdministrativeArea area = areaRepository.findById(request.getAreaId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Khu vực không hợp lệ."));
        if (!List.of("WARD", "COMMUNE", "SPECIAL").contains(area.getAreaType())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Vui lòng chọn phường/xã/đặc khu.");
        }
        Point location = geometryFactory.createPoint(new Coordinate(request.getLongitude(), request.getLatitude()));
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
        listing.replaceImages(request.getImageUrls());
    }

    private ListingResponse toListingResponse(Listing listing) {
        ListingResponse response = new ListingResponse();
        response.setRejectionReason(listing.getRejectionReason());
        List<String> images = listing.getImages().stream().map(ListingImage::getImageUrl).toList();
        response.setImageUrls(images);
        response.setImageUrl(images.isEmpty() ? null : images.get(0));
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
        response.setIsVip(listing.getIsVip());
        response.setViewCount(listing.getViewCount());
        response.setCreatedAt(listing.getCreatedAt());
        response.setHouseType(listing.getHouseType());
        response.setBedrooms(listing.getBedrooms());
        response.setBathrooms(listing.getBathrooms());
        response.setTotalFloors(listing.getTotalFloors());
        response.setDoorDirection(listing.getDoorDirection());
        response.setLegalDocuments(listing.getLegalDocuments());
        response.setFurnitureStatus(listing.getFurnitureStatus());
        response.setDepositAmount(listing.getDepositAmount());
        response.setPosterType(listing.getPosterType());
        return response;
    }
}
