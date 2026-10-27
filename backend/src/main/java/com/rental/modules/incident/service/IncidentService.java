package com.rental.modules.incident.service;

import com.rental.modules.incident.domain.entity.*;
import com.rental.modules.incident.dto.*;
import com.rental.modules.incident.repository.*;
import com.rental.modules.notification.service.NotificationService;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.*;
import com.rental.modules.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.*;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.*;

@Service
@Transactional
public class IncidentService {
    private final IncidentRepository incidents;
    private final IncidentUpdateRepository updates;
    private final UserRepository users;
    private final NotificationService notifications;
    public IncidentService(IncidentRepository incidents, IncidentUpdateRepository updates, UserRepository users, NotificationService notifications) {
        this.incidents = incidents;
        this.updates = updates;
        this.users = users;
        this.notifications = notifications;
    }

    public IncidentResponse create(Long reporterId, CreateIncidentRequest request) {
        Optional<User> found = users.findForAdminUpdate(reporterId);
        if (found.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy tài khoản.");
        User reporter = found.get();
        if (reporter.getStatus() != UserStatus.ACTIVE || !Boolean.TRUE.equals(reporter.getIsVerified())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Tài khoản chưa xác thực hoặc đã bị khóa.");
        }
        Optional<IncidentReport> existing = incidents.findByReporterUserIdAndRequestKey(reporterId, request.requestKey());
        if (existing.isPresent()) {
            IncidentReport saved = existing.get();
            if (!saved.getTitle().equals(request.title().trim()) || !saved.getDescription().equals(request.description().trim()) || !saved.getCategory().equals(request.category())) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Lần gửi này đã tạo báo cáo. Hãy quay lại danh sách để kiểm tra.");
            }
            return response(saved, true);
        }
        LocalDateTime now = LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh"));
        if (incidents.existsByReporterUserIdAndCreatedAtAfter(reporterId, now.minusSeconds(60))) {
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Vui lòng chờ 60 giây giữa các báo cáo mới.");
        }
        IncidentReport report = new IncidentReport();
        report.setReporter(reporter);
        report.setRequestKey(request.requestKey());
        report.setTitle(request.title().trim());
        report.setCategory(request.category());
        report.setDescription(request.description().trim());
        report.setCreatedAt(now);
        report.setUpdatedAt(now);
        incidents.saveAndFlush(report);
        updates.save(new IncidentUpdate(report.getId(), reporter, "OPEN", "Đã gửi báo cáo sự cố.", now));
        notifications.notifyIncidentAdmins(report.getId(), "Có báo cáo sự cố mới", "Báo cáo #" + report.getId() + ": " + report.getTitle());
        return response(report, true);
    }

    @Transactional(readOnly = true)
    public IncidentPage search(Long reporterId, String query, String status, String category, int page) {
        if (query == null) query = "";
        if (query.length() > 100 || page < 0 || page > 10000) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Bộ lọc hoặc trang không hợp lệ.");
        if (status != null && !List.of("OPEN", "IN_PROGRESS", "RESOLVED", "REJECTED").contains(status)) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Trạng thái không hợp lệ.");
        if (category != null && !List.of("ACCOUNT", "LISTING", "CONTRACT", "PAYMENT", "TECHNICAL", "OTHER").contains(category)) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Loại sự cố không hợp lệ.");
        Pageable pageable = PageRequest.of(page, 20, Sort.by(Sort.Direction.DESC, "updatedAt", "id"));
        Page<IncidentReport> result = incidents.search(reporterId, status, category, query.trim(), pageable);
        List<IncidentResponse> items = new ArrayList<>();
        for (IncidentReport report : result) items.add(response(report, false));
        return new IncidentPage(items, result.getTotalElements(), page, result.getTotalPages());
    }

    @Transactional(readOnly = true)
    public IncidentResponse detail(Long id, Long reporterId) {
        Optional<IncidentReport> found = incidents.findById(id);
        if (found.isEmpty() || (reporterId != null && !found.get().getReporter().getUserId().equals(reporterId))) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy báo cáo sự cố.");
        }
        return response(found.get(), true);
    }

    public IncidentResponse update(Long id, Long adminId, UpdateIncidentRequest request) {
        Optional<User> actor = users.findById(adminId);
        if (actor.isEmpty() || actor.get().getRole() != Role.ADMIN || actor.get().getStatus() != UserStatus.ACTIVE || !Boolean.TRUE.equals(actor.get().getIsVerified())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chỉ Admin đang hoạt động được xử lý báo cáo.");
        }
        Optional<IncidentReport> found = incidents.findForUpdate(id);
        if (found.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy báo cáo sự cố.");
        IncidentReport report = found.get();
        if (!report.getVersion().equals(request.version())) throw new ResponseStatusException(HttpStatus.CONFLICT, "Báo cáo đã thay đổi. Hãy tải lại trước khi xử lý.");
        if (!List.of("IN_PROGRESS", "RESOLVED", "REJECTED").contains(request.status())) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Trạng thái xử lý không hợp lệ.");
        boolean closed = report.getStatus().equals("RESOLVED") || report.getStatus().equals("REJECTED");
        if (closed && !request.status().equals(report.getStatus()) && !request.status().equals("IN_PROGRESS")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Cần mở lại báo cáo trước khi đổi kết quả xử lý.");
        }
        LocalDateTime now = LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh"));
        report.setStatus(request.status());
        report.setUpdatedAt(now);
        incidents.saveAndFlush(report);
        updates.save(new IncidentUpdate(id, actor.get(), request.status(), request.message().trim(), now));
        notifications.sendIncident(report.getReporter().getUserId(), "INCIDENT_UPDATED", "Báo cáo #" + id + " đã có phản hồi", request.message().trim(), id);
        return response(report, true);
    }

    private IncidentResponse response(IncidentReport report, boolean includeHistory) {
        List<IncidentResponse.Update> history = new ArrayList<>();
        if (includeHistory) {
            for (IncidentUpdate update : updates.findByIncidentIdOrderByCreatedAtAscIdAsc(report.getId())) {
                history.add(new IncidentResponse.Update(update.getId(), update.getActor().getFullName(), update.getStatus(), update.getMessage(), update.getCreatedAt()));
            }
        }
        User reporter = report.getReporter();
        return new IncidentResponse(report.getId(), report.getTitle(), report.getCategory(), report.getDescription(), report.getStatus(), reporter.getUserId(), reporter.getFullName(), reporter.getEmail(), report.getCreatedAt(), report.getUpdatedAt(), report.getVersion(), history);
    }
}
