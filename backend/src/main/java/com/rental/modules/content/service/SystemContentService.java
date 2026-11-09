package com.rental.modules.content.service;

import com.rental.modules.content.domain.entity.SystemContent;
import com.rental.modules.content.dto.*;
import com.rental.modules.content.repository.SystemContentRepository;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

@Service
@Transactional
public class SystemContentService {
    private final SystemContentRepository contents;

    public SystemContentService(SystemContentRepository contents) {
        this.contents = contents;
    }

    @Transactional(readOnly = true)
    public List<AdminContentResponse> list() {
        List<AdminContentResponse> result = new ArrayList<>();
        List<SystemContent> rows = contents.findAll(Sort.by("slug"));
        for (SystemContent content : rows) {
            result.add(AdminContentResponse.from(content));
        }
        return result;
    }

    @Transactional(readOnly = true)
    public AdminContentResponse detail(String slug) {
        SystemContent content = findContent(slug);
        return AdminContentResponse.from(content);
    }

    @Transactional(readOnly = true)
    public PublishedContentResponse published(String slug) {
        SystemContent content = findContent(slug);
        if (!content.isPublished()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Nội dung hiện chưa được công bố hoặc không tồn tại.");
        }
        return new PublishedContentResponse(content.getSlug(), content.getPublishedTitle(),
            content.getPublishedBody(), content.getPublishedAt());
    }

    public AdminContentResponse saveDraft(String slug, ContentRequest request) {
        SystemContent content = findContentForUpdate(slug, request.version());
        content.setTitle(request.title().trim());
        content.setBody(ContentHtml.clean(request.body()));
        contents.saveAndFlush(content);
        return AdminContentResponse.from(content);
    }

    public AdminContentResponse publish(String slug, ContentRequest request) {
        SystemContent content = findContentForUpdate(slug, request.version());
        content.setTitle(request.title().trim());
        content.setBody(ContentHtml.clean(request.body()));
        content.setPublishedTitle(content.getTitle());
        content.setPublishedBody(content.getBody());
        content.setPublished(true);
        content.setPublishedAt(LocalDateTime.now());
        contents.saveAndFlush(content);
        return AdminContentResponse.from(content);
    }

    public AdminContentResponse unpublish(String slug, Long version) {
        SystemContent content = findContentForUpdate(slug, version);
        content.setPublished(false);
        contents.saveAndFlush(content);
        return AdminContentResponse.from(content);
    }

    private SystemContent findContent(String slug) {
        Optional<SystemContent> result = contents.findById(slug);
        if (result.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Nội dung hiện chưa được công bố hoặc không tồn tại.");
        }
        return result.get();
    }

    private SystemContent findContentForUpdate(String slug, Long version) {
        Optional<SystemContent> result = contents.findForUpdate(slug);
        if (result.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Nội dung hiện chưa được công bố hoặc không tồn tại.");
        }
        SystemContent content = result.get();
        if (!Objects.equals(content.getVersion(), version)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Nội dung đã được Admin khác thay đổi. Hãy tải lại trước khi lưu.");
        }
        return content;
    }
}
