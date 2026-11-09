package com.rental.modules.content.controller;

import com.rental.core.dto.ApiResponse;
import com.rental.modules.content.dto.PublishedContentResponse;
import com.rental.modules.content.service.SystemContentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/content")
public class ContentController {
    private final SystemContentService service;
    public ContentController(SystemContentService service) { this.service = service; }

    @GetMapping("/{slug}")
    public ResponseEntity<ApiResponse<PublishedContentResponse>> get(@PathVariable String slug) {
        return ResponseEntity.ok().header("Cache-Control", "no-store")
            .body(ApiResponse.success("Nội dung đã xuất bản.", service.published(slug)));
    }
}
