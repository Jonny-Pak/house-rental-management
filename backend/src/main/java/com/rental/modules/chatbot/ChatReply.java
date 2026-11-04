package com.rental.modules.chatbot;

import com.rental.modules.listing.dto.response.ListingResponse;
import java.util.List;

public record ChatReply(String message, ChatFilters filters, List<String> conditions,
                        List<ListingResponse> listings, int total, boolean locationRequired, boolean clearLocation) {
    public ChatReply(String message, ChatFilters filters, List<String> conditions,
                     List<ListingResponse> listings, int total, boolean locationRequired) {
        this(message, filters, conditions, listings, total, locationRequired, false);
    }
}
