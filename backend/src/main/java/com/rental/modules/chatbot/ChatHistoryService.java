package com.rental.modules.chatbot;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.rental.modules.listing.dto.response.ListingResponse;
import com.rental.modules.listing.service.ListingService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ChatHistoryService {
    private final ChatbotService chatbot;
    private final ChatHistoryStore store;
    private final ListingService listings;
    private final ObjectMapper json;

    public ChatHistoryService(ChatbotService chatbot, ChatHistoryStore store, ListingService listings, ObjectMapper json) {
        this.chatbot = chatbot;
        this.store = store;
        this.listings = listings;
        this.json = json;
    }

    public record Item(long id, String message, ChatReply reply, Double latitude, Double longitude, String locationName, String createdAt) {}
    public record Page(List<Item> items, boolean hasMore) {}

    public ChatReply send(Long userId, ChatRequest request) {
        ChatReply reply = chatbot.reply(userId, request);
        try {
            store.save(userId, json.writeValueAsString(request), json.writeValueAsString(reply));
        } catch (JsonProcessingException exception) {
            throw failed();
        }
        return reply;
    }

    public Page history(Long userId, Long beforeId) {
        if (beforeId != null && beforeId < 1) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mốc lịch sử không hợp lệ.");
        var rows = store.find(userId, beforeId == null ? Long.MAX_VALUE : beforeId);
        boolean hasMore = rows.size() > 30;
        rows = new ArrayList<>(rows.subList(0, Math.min(30, rows.size())));
        Collections.reverse(rows);
        Map<Long, ListingResponse> publicListings = new HashMap<>();
        if (!rows.isEmpty()) {
            for (var listing : listings.getApprovedListings()) {
                if ("APPROVED".equals(listing.getApprovalStatus()) && "AVAILABLE".equals(listing.getRentalStatus())) {
                    publicListings.put(listing.getId(), listing);
                }
            }
        }
        List<Item> result = new ArrayList<>();
        for (var row : rows) {
            try {
                ChatRequest request = json.readValue(row.requestJson(), ChatRequest.class);
                ChatReply stored = json.readValue(row.replyJson(), ChatReply.class);
                List<ListingResponse> current = new ArrayList<>();
                for (var old : stored.listings()) {
                    if (publicListings.containsKey(old.getId())) current.add(publicListings.get(old.getId()));
                }
                var reply = new ChatReply(stored.message(), stored.filters(), stored.conditions(), current,
                    stored.total(), stored.locationRequired(), stored.clearLocation());
                result.add(new Item(row.id(), request.message(), reply, request.latitude(), request.longitude(), request.locationName(), row.createdAt()));
            } catch (JsonProcessingException exception) {
                throw failed();
            }
        }
        return new Page(result, hasMore);
    }

    public void clear(Long userId) {
        store.clear(userId);
    }

    private ResponseStatusException failed() {
        return new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Chưa xử lý được lịch sử trò chuyện. Vui lòng thử lại.");
    }
}
