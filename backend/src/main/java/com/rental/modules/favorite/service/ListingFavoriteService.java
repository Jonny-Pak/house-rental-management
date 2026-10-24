package com.rental.modules.favorite.service;

import com.rental.modules.listing.service.ListingService;
import com.rental.modules.listing.dto.response.ListingResponse;
import com.rental.modules.listing.repository.ListingRepository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import java.util.List;
import java.util.ArrayList;

@Service
@Transactional(readOnly = true)
public class ListingFavoriteService {
    private final JdbcTemplate jdbc;
    private final ListingService listings;
    private final ListingRepository repository;
    public ListingFavoriteService(JdbcTemplate jdbc, ListingService listings, ListingRepository repository) {
        this.jdbc = jdbc; this.listings = listings; this.repository = repository;
    }
    public boolean isSaved(Long userId, Long listingId) {
        return Boolean.TRUE.equals(jdbc.queryForObject(
                "SELECT EXISTS(SELECT 1 FROM user_favorites WHERE user_id=? AND listing_id=?)",
                Boolean.class, userId, listingId));
    }
    @Transactional
    public void save(Long userId, Long listingId) {
        java.util.Optional<com.rental.modules.listing.domain.entity.Listing> listingResult = repository.findLockedById(listingId);
        if (listingResult.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Tin đăng không còn khả dụng.");
        }
        com.rental.modules.listing.domain.entity.Listing listing = listingResult.get();
        if (!"APPROVED".equals(listing.getApprovalStatus()) || !"AVAILABLE".equals(listing.getRentalStatus())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Tin đăng không còn khả dụng.");
        }
        jdbc.update("INSERT INTO user_favorites(user_id, listing_id) VALUES (?, ?) ON CONFLICT (user_id, listing_id) DO NOTHING",
                userId, listingId);
    }
    @Transactional
    public void remove(Long userId, Long listingId) {
        jdbc.update("DELETE FROM user_favorites WHERE user_id=? AND listing_id=?", userId, listingId);
    }
    public List<ListingResponse> getSaved(Long userId) {
        List<Long> listingIds = jdbc.queryForList(
                "SELECT f.listing_id FROM user_favorites f JOIN listings l ON l.listing_id=f.listing_id "
                + "WHERE f.user_id=? AND l.approval_status='APPROVED' AND l.rental_status='AVAILABLE' ORDER BY f.created_at DESC, f.id DESC",
                Long.class, userId);
        List<ListingResponse> result = new ArrayList<>();
        for (Long listingId : listingIds) {
            result.add(listings.getPublicListing(listingId));
        }
        return result;
    }
}
