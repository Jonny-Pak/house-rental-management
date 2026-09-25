package com.rental.modules.listing.service;

import com.rental.modules.listing.dto.response.MapListingResponse;
import com.rental.modules.listing.entity.Listing;
import com.rental.modules.listing.repository.ListingRepository;
import lombok.RequiredArgsConstructor;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ListingService {

    private final ListingRepository listingRepository;

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
}
