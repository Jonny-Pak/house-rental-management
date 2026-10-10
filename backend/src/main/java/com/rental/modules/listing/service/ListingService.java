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

    public ListingResponse createListing(Long ownerId, CreateListingRequest request) {
        User owner = userRepository.findById(ownerId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        AdministrativeArea area = areaRepository.findById(request.getAreaId())
                .orElseThrow(() -> new RuntimeException("Area not found"));

        Point location = geometryFactory.createPoint(new Coordinate(request.getLongitude(), request.getLatitude()));

        Listing listing = new Listing();
        listing.setOwner(owner);
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
        listing.setApprovalStatus("PENDING");
        listing.setRentalStatus("AVAILABLE");
        listing.setIsVip(false);
        listing.setViewCount(0);
        listing.setCreatedAt(LocalDateTime.now());

        Listing savedListing = listingRepository.save(listing);
        return toListingResponse(savedListing);
    }

    private ListingResponse toListingResponse(Listing listing) {
        ListingResponse response = new ListingResponse();
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
