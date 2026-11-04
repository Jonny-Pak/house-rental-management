package com.rental.modules.chatbot;

import com.rental.modules.listing.dto.response.ListingResponse;
import com.rental.modules.listing.service.ListingService;
import org.springframework.stereotype.Service;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

@Service
public class ChatbotSearch {
    private final ListingService listings;

    public ChatbotSearch(ListingService listings) {
        this.listings = listings;
    }

    public List<ListingResponse> find(ChatFilters filters, Double latitude, Double longitude) {
        List<ListingResponse> source;
        if (filters.radiusKm() != null) source = listings.findNearby(latitude, longitude, filters.radiusKm());
        else source = listings.getApprovedListings();
        var result = new ArrayList<ListingResponse>();
        for (var item : source) {
            if (matches(item, filters)) result.add(item);
        }
        if ("PRICE_ASC".equals(filters.sort())) result.sort(Comparator.comparing(ListingResponse::getRentPrice));
        if ("AREA_DESC".equals(filters.sort())) result.sort(Comparator.comparing(ListingResponse::getAreaSqm).reversed());
        return result;
    }

    public boolean matches(ListingResponse item, ChatFilters f) {
        if (!"APPROVED".equals(item.getApprovalStatus()) || !"AVAILABLE".equals(item.getRentalStatus())) return false;
        if (f.listingType() != null && !f.listingType().equals(item.getListingType())) return false;
        if (f.minPrice() != null && (item.getRentPrice() == null || item.getRentPrice().compareTo(f.minPrice()) < 0)) return false;
        if (f.maxPrice() != null && (item.getRentPrice() == null || item.getRentPrice().compareTo(f.maxPrice()) > 0)) return false;
        if (f.minArea() != null && (item.getAreaSqm() == null || item.getAreaSqm().compareTo(f.minArea()) < 0)) return false;
        if (f.maxArea() != null && (item.getAreaSqm() == null || item.getAreaSqm().compareTo(f.maxArea()) > 0)) return false;
        if (f.bedrooms() != null && (item.getBedrooms() == null || item.getBedrooms() < f.bedrooms())) return false;
        if (f.allowPets() != null && !f.allowPets().equals(item.getAllowPets())) return false;
        if (f.allowSmoking() != null && !f.allowSmoking().equals(item.getAllowSmoking())) return false;
        if (f.genderPreference() != null && !"ANY".equals(f.genderPreference()) && !f.genderPreference().equals(item.getGenderPreference()) && !"ANY".equals(item.getGenderPreference())) return false;
        String address = key(item.getTitle()) + " " + key(item.getAddress());
        if (f.radiusKm() == null && f.locationText() != null && !address.contains(key(f.locationText()))) return false;
        for (String requested : f.amenities()) {
            boolean found = false;
            for (var amenity : item.getAmenities()) {
                if (key(amenity.name()).contains(key(requested))) found = true;
            }
            if (!found) return false;
        }
        String details = address + " " + key(item.getDescription()) + " " + key(item.getRoommateRequirements());
        for (String keyword : f.keywords()) {
            if (!details.contains(key(keyword))) return false;
        }
        return true;
    }

    public static String key(String text) {
        if (text == null) return "";
        return Normalizer.normalize(text.toLowerCase(Locale.ROOT), Normalizer.Form.NFD)
            .replaceAll("\\p{M}", "").replace('đ', 'd').replaceAll("[^a-z0-9 ]", "").replaceAll("\\s+", " ").trim();
    }
}
