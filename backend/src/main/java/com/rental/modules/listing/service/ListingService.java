package com.rental.modules.listing.service;

import com.rental.modules.listing.dto.request.CreateListingRequest;
import com.rental.modules.listing.dto.response.ListingResponse;
import com.rental.modules.listing.dto.response.MapListingResponse;
import com.rental.modules.listing.entity.Listing;
import com.rental.modules.listing.repository.ListingRepository;
import com.rental.modules.area.domain.entity.AdministrativeArea;
import com.rental.modules.area.repository.AdministrativeAreaRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ListingService {

    private final ListingRepository listingRepository;
    private final UserRepository userRepository;
    private final AdministrativeAreaRepository areaRepository;

    /**
     * GeometryFactory với SRID=4326 (WGS84 - hệ tọa độ GPS chuẩn quốc tế).
     * Phải khớp với kiểu cột trong DB: geometry(Point, 4326).
     */
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    /**
     * Tìm kiếm Listing nằm trong vùng nhìn thấy trên bản đồ (bounding box).
     *
     * @param minLat Vĩ độ nhỏ nhất (góc dưới-trái)
     * @param minLng Kinh độ nhỏ nhất (góc dưới-trái)
     * @param maxLat Vĩ độ lớn nhất (góc trên-phải)
     * @param maxLng Kinh độ lớn nhất (góc trên-phải)
     */
    public List<MapListingResponse> searchListingsInBoundingBox(
            double minLat, double minLng, double maxLat, double maxLng) {

        // Tạo Polygon đại diện cho vùng bản đồ đang hiển thị.
        // Thứ tự Coordinate trong JTS là (longitude, latitude) tức là (X, Y).
        // Polygon phải khép kín: điểm đầu và cuối PHẢI giống nhau.
        Coordinate[] coordinates = new Coordinate[]{
                new Coordinate(minLng, minLat), // Dưới-Trái
                new Coordinate(minLng, maxLat), // Trên-Trái
                new Coordinate(maxLng, maxLat), // Trên-Phải
                new Coordinate(maxLng, minLat), // Dưới-Phải
                new Coordinate(minLng, minLat)  // Khép kín về điểm ban đầu
        };

        Polygon bbox = geometryFactory.createPolygon(coordinates);

        List<Listing> listings = listingRepository.findListingsWithinBoundingBox(bbox);

        return listings.stream()
                .filter(l -> l.getLocation() != null)
                .map(this::toMapListingResponse)
                .collect(Collectors.toList());
    }

    private MapListingResponse toMapListingResponse(Listing listing) {
        return MapListingResponse.builder()
                .id(listing.getId())
                .title(listing.getTitle())
                .listingType(listing.getListingType())
                .rentPrice(listing.getRentPrice())
                .address(listing.getAddress())
                // getY() = Latitude (vĩ độ), getX() = Longitude (kinh độ) - chuẩn JTS
                .latitude(listing.getLocation().getY())
                .longitude(listing.getLocation().getX())
                .build();
    }

    public ListingResponse createListing(Long ownerId, CreateListingRequest request) {
        User owner = userRepository.findById(ownerId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        AdministrativeArea area = areaRepository.findById(request.getAreaId())
                .orElseThrow(() -> new RuntimeException("Area not found"));

        Point location = geometryFactory.createPoint(new Coordinate(request.getLongitude(), request.getLatitude()));

        Listing listing = Listing.builder()
                .owner(owner)
                .area(area)
                .title(request.getTitle())
                .description(request.getDescription())
                .listingType(request.getListingType())
                .rentPrice(request.getRentPrice())
                .areaSqm(request.getAreaSqm())
                .address(request.getAddress())
                .location(location)
                .houseType(request.getHouseType())
                .bedrooms(request.getBedrooms())
                .bathrooms(request.getBathrooms())
                .totalFloors(request.getTotalFloors())
                .doorDirection(request.getDoorDirection())
                .legalDocuments(request.getLegalDocuments())
                .furnitureStatus(request.getFurnitureStatus())
                .depositAmount(request.getDepositAmount())
                .posterType(request.getPosterType())
                .approvalStatus("PENDING")
                .rentalStatus("AVAILABLE")
                .isVip(false)
                .viewCount(0)
                .createdAt(LocalDateTime.now())
                .build();

        Listing savedListing = listingRepository.save(listing);
        return toListingResponse(savedListing);
    }

    private ListingResponse toListingResponse(Listing listing) {
        return ListingResponse.builder()
                .id(listing.getId())
                .title(listing.getTitle())
                .description(listing.getDescription())
                .listingType(listing.getListingType())
                .rentPrice(listing.getRentPrice())
                .areaSqm(listing.getAreaSqm())
                .address(listing.getAddress())
                .latitude(listing.getLocation() != null ? listing.getLocation().getY() : null)
                .longitude(listing.getLocation() != null ? listing.getLocation().getX() : null)
                .ownerId(listing.getOwner().getUserId())
                .areaId(listing.getArea().getAreaId())
                .approvalStatus(listing.getApprovalStatus())
                .rentalStatus(listing.getRentalStatus())
                .isVip(listing.getIsVip())
                .viewCount(listing.getViewCount())
                .createdAt(listing.getCreatedAt())
                .houseType(listing.getHouseType())
                .bedrooms(listing.getBedrooms())
                .bathrooms(listing.getBathrooms())
                .totalFloors(listing.getTotalFloors())
                .doorDirection(listing.getDoorDirection())
                .legalDocuments(listing.getLegalDocuments())
                .furnitureStatus(listing.getFurnitureStatus())
                .depositAmount(listing.getDepositAmount())
                .posterType(listing.getPosterType())
                .build();
    }
}
