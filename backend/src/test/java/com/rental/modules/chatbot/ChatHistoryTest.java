package com.rental.modules.chatbot;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rental.modules.listing.dto.response.ListingResponse;
import com.rental.modules.listing.service.ListingService;
import org.junit.jupiter.api.Test;
import java.util.ArrayList;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ChatHistoryTest {
    ChatbotService chatbot = mock(ChatbotService.class);
    ChatHistoryStore store = mock(ChatHistoryStore.class);
    ListingService listings = mock(ListingService.class);
    ObjectMapper json = new ObjectMapper();
    ChatHistoryService history = new ChatHistoryService(chatbot, store, listings, json);

    @Test void savesOnlyCompletedExchangesUnderAuthenticatedAccount() throws Exception {
        var request = new ChatRequest("Tìm phòng", null, 10.78, 106.7, "Điểm đã chọn");
        var reply = new ChatReply("Tìm thấy 0 tin", ChatFilters.empty(), List.of(), List.of(), 0, false);
        when(chatbot.reply(7L, request)).thenReturn(reply);
        assertEquals(reply, history.send(7L, request));
        verify(store).save(7L, json.writeValueAsString(request), json.writeValueAsString(reply));
        reset(store);
        when(chatbot.reply(7L, request)).thenThrow(new IllegalStateException("AI unavailable"));
        assertThrows(IllegalStateException.class, () -> history.send(7L, request));
        verifyNoInteractions(store);
    }

    @Test void returnsChronologicalPagesAndRefreshesOnlyStillPublicCards() throws Exception {
        var request = new ChatRequest("Tìm phòng", null, null, null, null);
        var old = new ListingResponse(); old.setId(11L); old.setTitle("Nội dung cũ");
        var hidden = new ListingResponse(); hidden.setId(12L);
        var current = new ListingResponse(); current.setId(11L); current.setTitle("Nội dung hiện tại");
        current.setApprovalStatus("APPROVED"); current.setRentalStatus("AVAILABLE");
        var reply = new ChatReply("Tìm thấy 2 tin", ChatFilters.empty(), List.of(), List.of(old, hidden), 2, false);
        var rows = new ArrayList<ChatHistoryStore.Row>();
        for (long id = 31; id >= 1; id--) rows.add(new ChatHistoryStore.Row(id, json.writeValueAsString(request), json.writeValueAsString(reply), "2026-11-04T01:00:00Z"));
        when(store.find(7L, Long.MAX_VALUE)).thenReturn(rows);
        when(listings.getApprovedListings()).thenReturn(List.of(current, hidden));
        var page = history.history(7L, null);
        assertTrue(page.hasMore());
        assertEquals(30, page.items().size());
        assertEquals(2L, page.items().getFirst().id());
        assertEquals(31L, page.items().getLast().id());
        assertEquals(List.of(current), page.items().getLast().reply().listings());
        assertEquals("Nội dung hiện tại", page.items().getLast().reply().listings().getFirst().getTitle());
        history.history(7L, 2L);
        verify(store).find(7L, 2L);
        history.clear(7L);
        verify(store).clear(7L);
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> history.history(7L, -1L));
    }
}
