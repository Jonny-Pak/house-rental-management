package com.rental.modules.admin.service;

import com.rental.modules.admin.dto.request.AdminAreaRequest;
import com.rental.modules.admin.dto.response.AdminAreaResponse;
import com.rental.modules.area.domain.entity.AdministrativeArea;
import com.rental.modules.area.repository.AdministrativeAreaRepository;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Objects;

@Service
@Transactional
public class AdminAreaService {
    private final AdministrativeAreaRepository areas;
    private final JdbcTemplate jdbc;
    private static final List<String> TYPES = List.of("PROVINCE", "DISTRICT", "WARD", "COMMUNE", "SPECIAL");
    private static final String SELECT = """
        SELECT a.area_id, a.area_name, a.area_type, a.code, a.parent_id, p.area_name AS parent_name, a.is_active,
          (SELECT count(*) FROM administrative_areas c WHERE c.parent_id=a.area_id) AS children,
          (SELECT count(*) FROM listings l WHERE l.area_id=a.area_id) AS listing_count,
          (SELECT count(*) FROM properties r WHERE r.province_id=a.area_id OR r.district_id=a.area_id OR r.ward_id=a.area_id) AS property_count
        FROM administrative_areas a LEFT JOIN administrative_areas p ON p.area_id=a.parent_id
        """;
    private static final RowMapper<AdminAreaResponse> ROW = (rs, index) -> new AdminAreaResponse(
        rs.getLong("area_id"), rs.getString("area_name"), rs.getString("area_type"), rs.getString("code"),
        rs.getObject("parent_id", Long.class), rs.getString("parent_name"), rs.getBoolean("is_active"),
        rs.getLong("children"), rs.getLong("listing_count"), rs.getLong("property_count"));

    public AdminAreaService(AdministrativeAreaRepository areas, JdbcTemplate jdbc) {
        this.areas = areas;
        this.jdbc = jdbc;
    }

    public record AreaPage(List<AdminAreaResponse> items, long total, int page, int totalPages) {}

    @Transactional(readOnly = true)
    public AreaPage search(String query, String type, Long parentId, Boolean active, int page) {
        if (query.length() > 100 || page < 0 || page > 10000 || (type != null && !TYPES.contains(type))
                || (parentId != null && parentId < 1)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Bộ lọc khu vực không hợp lệ.");
        }
        String where = " WHERE (position(lower(?) in lower(a.area_name)) > 0 OR position(lower(?) in lower(coalesce(a.code,''))) > 0)";
        List<Object> parameters = new ArrayList<>();
        parameters.add(query.trim()); parameters.add(query.trim());
        if (type != null) { where += " AND a.area_type=?"; parameters.add(type); }
        if (parentId != null) { where += " AND a.parent_id=?"; parameters.add(parentId); }
        if (active != null) { where += " AND a.is_active=?"; parameters.add(active); }
        long total = jdbc.queryForObject("SELECT count(*) FROM administrative_areas a" + where, Long.class, parameters.toArray());
        parameters.add(20); parameters.add(page * 20);
        var rows = jdbc.query(SELECT + where + " ORDER BY a.area_name, a.area_id LIMIT ? OFFSET ?", ROW, parameters.toArray());
        return new AreaPage(rows, total, page, (int) ((total + 19) / 20));
    }

    @Transactional(readOnly = true)
    public List<AdminAreaResponse> parents() {
        return jdbc.query(SELECT + " WHERE a.area_type IN ('PROVINCE','DISTRICT') ORDER BY a.area_type, a.area_name, a.area_id", ROW);
    }

    @Transactional(readOnly = true)
    public AdminAreaResponse detail(Long id) {
        var rows = jdbc.query(SELECT + " WHERE a.area_id=?", ROW, id);
        if (rows.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy khu vực.");
        return rows.get(0);
    }

    public AdminAreaResponse create(AdminAreaRequest request) {
        lockAreas();
        if ("DISTRICT".equals(request.type())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Không tạo mới quận/huyện. Hãy chọn tỉnh/thành hoặc phường/xã/đặc khu.");
        }
        var area = new AdministrativeArea();
        apply(area, request);
        areas.saveAndFlush(area);
        return detail(area.getAreaId());
    }

    public AdminAreaResponse update(Long id, AdminAreaRequest request) {
        lockAreas();
        var area = find(id);
        var current = detail(id);
        boolean hierarchyChanged = !Objects.equals(area.getAreaType(), request.type())
            || !Objects.equals(current.parentId(), request.parentId());
        if (hierarchyChanged && (current.children() > 0 || current.listingCount() > 0 || current.propertyCount() > 0)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Khu vực đã có đơn vị con, tin đăng hoặc khu trọ. Không thể đổi cấp hoặc đơn vị trực thuộc.");
        }
        if ("DISTRICT".equals(request.type()) && !"DISTRICT".equals(area.getAreaType())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Không chuyển khu vực thành quận/huyện cũ.");
        }
        apply(area, request);
        areas.saveAndFlush(area);
        return detail(id);
    }

    public AdminAreaResponse changeStatus(Long id, boolean active) {
        lockAreas();
        var area = find(id);
        if (active && area.getParent() != null && !area.getParent().isAvailable()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Hãy kích hoạt đơn vị cấp trên trước.");
        }
        if (!active && jdbc.queryForObject("SELECT count(*) FROM administrative_areas WHERE parent_id=? AND is_active=true", Long.class, id) > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Hãy ngừng sử dụng các đơn vị con trước.");
        }
        area.setActive(active);
        areas.saveAndFlush(area);
        return detail(id);
    }

    public void delete(Long id) {
        lockAreas();
        var area = find(id);
        var usage = detail(id);
        if (usage.children() > 0 || usage.listingCount() > 0 || usage.propertyCount() > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Khu vực đang được sử dụng. Hãy ngừng sử dụng thay vì xóa.");
        }
        try {
            areas.delete(area);
            areas.flush();
        } catch (org.springframework.dao.DataIntegrityViolationException ex) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Khu vực vừa được sử dụng. Hãy tải lại danh sách.");
        }
    }

    private void apply(AdministrativeArea area, AdminAreaRequest request) {
        String name = request.name().trim().replaceAll("\\s+", " ");
        String code = request.code().trim().toUpperCase(Locale.ROOT);
        AdministrativeArea parent = null;
        if ("PROVINCE".equals(request.type())) {
            if (request.parentId() != null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Tỉnh/thành không có đơn vị cấp trên.");
        } else {
            if (request.parentId() == null || Objects.equals(area.getAreaId(), request.parentId())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Đơn vị cấp trên không hợp lệ.");
            }
            parent = find(request.parentId());
            boolean valid = "PROVINCE".equals(parent.getAreaType())
                || ("WARD".equals(request.type()) && "DISTRICT".equals(parent.getAreaType()));
            if (!valid || (area.isActive() && !parent.isAvailable())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Đơn vị cấp trên không phù hợp hoặc đã ngừng sử dụng.");
            }
        }
        long id = area.getAreaId() == null ? -1 : area.getAreaId();
        long duplicateCode = jdbc.queryForObject("SELECT count(*) FROM administrative_areas WHERE lower(trim(code))=lower(?) AND area_id<>?", Long.class, code, id);
        long duplicateName = jdbc.queryForObject("SELECT count(*) FROM administrative_areas WHERE lower(trim(area_name))=lower(?) AND coalesce(parent_id,0)=? AND area_id<>?", Long.class, name, request.parentId() == null ? 0 : request.parentId(), id);
        if (duplicateCode > 0 || duplicateName > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Mã khu vực hoặc tên trong cùng đơn vị cấp trên đã tồn tại.");
        }
        area.setAreaName(name); area.setCode(code); area.setAreaType(request.type()); area.setParent(parent);
    }

    private AdministrativeArea find(Long id) {
        return areas.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy khu vực."));
    }

    private void lockAreas() {
        jdbc.execute("LOCK TABLE administrative_areas IN SHARE ROW EXCLUSIVE MODE");
    }
}
