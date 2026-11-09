package com.rental.modules.chatbot;

import com.rental.core.security.CustomUserDetails;
import jakarta.validation.Valid;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/chatbot")
public class ChatbotController {
    private final ChatHistoryService history;

    public ChatbotController(ChatHistoryService history) {
        this.history = history;
    }

    @PostMapping("/messages")
    public ResponseEntity<ChatReply> send(@AuthenticationPrincipal CustomUserDetails user, @Valid @RequestBody ChatRequest request) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
            .body(history.send(user.getUser().getUserId(), request));
    }

    @GetMapping("/history")
    public ResponseEntity<ChatHistoryService.Page> history(@AuthenticationPrincipal CustomUserDetails user, @RequestParam(required = false) Long beforeId) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(history.history(user.getUser().getUserId(), beforeId));
    }

    @DeleteMapping("/history")
    public ResponseEntity<Void> clear(@AuthenticationPrincipal CustomUserDetails user) {
        history.clear(user.getUser().getUserId());
        return ResponseEntity.noContent().cacheControl(CacheControl.noStore()).build();
    }
}
