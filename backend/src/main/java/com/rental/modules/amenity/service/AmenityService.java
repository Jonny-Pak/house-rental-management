package com.rental.modules.amenity.service;

import com.rental.modules.amenity.domain.entity.Amenity;
import com.rental.modules.amenity.dto.*;
import com.rental.modules.amenity.repository.AmenityRepository;
import org.springframework.data.domain.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.*;

@Service
@Transactional
public class AmenityService {
    private final AmenityRepository repository;
    public AmenityService(AmenityRepository repository) { this.repository = repository; }
    public record AmenityPage(List<AmenityResponse> items, long total, int page, int totalPages) {}

    @Transactional(readOnly = true)
    public List<AmenityResponse> activeItems() {
        List<AmenityResponse> result = new ArrayList<>();
        for (Amenity item : repository.findByActiveTrueOrderByCategoryAscNameAsc()) result.add(AmenityResponse.from(item, null));
        return result;
    }

    @Transactional(readOnly = true)
    public AmenityPage search(String query, String category, Boolean active, int page) {
        if (query.length() > 100 || page < 0 || page > 10000) throw bad("Bộ lọc không hợp lệ.");
        if (category != null) validateCategory(category);
        Page<Amenity> found = repository.search(query.trim(), category, active, PageRequest.of(page, 20, Sort.by("category", "name", "id")));
        List<AmenityResponse> items = new ArrayList<>();
        for (Amenity item : found) items.add(view(item));
        return new AmenityPage(items, found.getTotalElements(), page, found.getTotalPages());
    }

    public AmenityResponse create(SaveAmenityRequest request) {
        validateCategory(request.category());
        String name = cleanName(request.name());
        if (repository.existsByCategoryAndNameIgnoreCase(request.category(), name)) duplicate();
        Amenity item = new Amenity();
        apply(item, request, name);
        return view(repository.saveAndFlush(item));
    }

    public AmenityResponse update(Long id, SaveAmenityRequest request) {
        Amenity item = find(id, request.version());
        validateCategory(request.category());
        String name = cleanName(request.name());
        if (repository.existsByCategoryAndNameIgnoreCaseAndIdNot(request.category(), name, id)) duplicate();
        if (!item.getCategory().equals(request.category()) && repository.countListings(id) > 0) {
            throw bad("Mục đã được dùng trong tin đăng, không thể đổi nhóm.");
        }
        apply(item, request, name);
        return view(repository.saveAndFlush(item));
    }

    public AmenityResponse changeStatus(Long id, boolean active, Long version) {
        Amenity item = find(id, version);
        item.setActive(active);
        return view(repository.saveAndFlush(item));
    }

    public void delete(Long id, Long version) {
        Amenity item = find(id, version);
        if (repository.countListings(id) > 0) throw new ResponseStatusException(HttpStatus.CONFLICT, "Mục đã được dùng trong tin đăng. Hãy ngừng sử dụng để giữ dữ liệu.");
        repository.delete(item);
        repository.flush();
    }

    public List<Amenity> selectForListing(List<Long> ids, List<Amenity> previous) {
        if (ids.size() > 30 || new HashSet<>(ids).size() != ids.size()) throw bad("Chọn tối đa 30 mục, không chọn trùng.");
        for (Long id : ids) if (id == null || id < 1) throw bad("Nội thất/tiện ích không hợp lệ.");
        if (ids.isEmpty()) return new ArrayList<>();
        List<Amenity> selected = repository.findSelectedForUpdate(ids);
        if (selected.size() != ids.size()) throw bad("Có nội thất/tiện ích không còn tồn tại. Hãy tải lại danh mục.");
        Set<Long> oldIds = new HashSet<>();
        for (Amenity old : previous) oldIds.add(old.getId());
        for (Amenity item : selected) {
            if (!item.isActive() && !oldIds.contains(item.getId())) throw bad("Mục " + item.getName() + " đã ngừng sử dụng.");
        }
        return selected;
    }

    private Amenity find(Long id, Long version) {
        Amenity item = repository.findForUpdate(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy nội thất/tiện ích."));
        if (version == null || !version.equals(item.getVersion())) throw new ResponseStatusException(HttpStatus.CONFLICT, "Danh mục đã thay đổi. Hãy tải lại trước khi thao tác.");
        return item;
    }
    private AmenityResponse view(Amenity item) { return AmenityResponse.from(item, repository.countListings(item.getId())); }
    private String cleanName(String name) {
        if (name == null || name.isBlank() || name.trim().length() > 100) throw bad("Nhập tên từ 1 đến 100 ký tự.");
        return name.trim();
    }
    private void validateCategory(String category) {
        if (!"FURNITURE".equals(category) && !"UTILITY".equals(category)) throw bad("Chọn nhóm Nội thất hoặc Tiện ích.");
    }
    private void apply(Amenity item, SaveAmenityRequest request, String name) {
        item.setName(name); item.setCategory(request.category()); item.setActive(Boolean.TRUE.equals(request.active()));
        item.setDescription(request.description() == null ? "" : request.description().trim());
    }
    private ResponseStatusException bad(String message) { return new ResponseStatusException(HttpStatus.BAD_REQUEST, message); }
    private void duplicate() { throw new ResponseStatusException(HttpStatus.CONFLICT, "Tên đã tồn tại trong nhóm này."); }
}
