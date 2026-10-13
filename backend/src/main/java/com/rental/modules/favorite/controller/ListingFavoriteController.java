package com.rental.modules.favorite.controller;

import com.rental.core.security.CustomUserDetails;
import com.rental.modules.favorite.service.ListingFavoriteService;
import com.rental.modules.listing.dto.response.ListingResponse;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/listings")
public class ListingFavoriteController {
    private final ListingFavoriteService favorites;
    public ListingFavoriteController(ListingFavoriteService favorites) { this.favorites = favorites; }
    @GetMapping("/favorites/me")
    public List<ListingResponse> getSaved(@AuthenticationPrincipal CustomUserDetails user) {
        return favorites.getSaved(user.getUser().getUserId());
    }
    @GetMapping("/{id}/favorite")
    public Map<String, Boolean> isSaved(@PathVariable Long id, @AuthenticationPrincipal CustomUserDetails user) {
        return Map.of("isFavorite", favorites.isSaved(user.getUser().getUserId(), id));
    }
    @PutMapping("/{id}/favorite")
    public Map<String, Boolean> save(@PathVariable Long id, @AuthenticationPrincipal CustomUserDetails user) {
        favorites.save(user.getUser().getUserId(), id);
        return Map.of("isFavorite", true);
    }
    @DeleteMapping("/{id}/favorite")
    public Map<String, Boolean> remove(@PathVariable Long id, @AuthenticationPrincipal CustomUserDetails user) {
        favorites.remove(user.getUser().getUserId(), id);
        return Map.of("isFavorite", false);
    }
}
