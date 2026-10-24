package com.rental.modules.admin.service;

import com.rental.modules.admin.dto.request.AdminUpdateUserRequest;
import com.rental.modules.admin.dto.response.AdminUserResponse;
import com.rental.modules.notification.service.NotificationService;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.*;
import com.rental.modules.user.repository.UserRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;

@Service
@Transactional
public class AdminUserService {
    private final UserRepository users;
    private final NotificationService notifications;

    public AdminUserService(UserRepository users, NotificationService notifications) {
        this.users = users;
        this.notifications = notifications;
    }

    public record UserPage(List<AdminUserResponse> items, long total, int page, int totalPages) {}

    @Transactional(readOnly = true)
    public UserPage search(String query, Role role, UserStatus status, Boolean verified, int page) {
        if (page < 0 || page > 10000 || query.length() > 100) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Bộ lọc hoặc trang không hợp lệ.");
        }
        var rows = users.searchForAdmin(query.trim(), role, status, verified,
            PageRequest.of(page, 20, Sort.by(Sort.Direction.DESC, "createdAt", "userId")));
        return new UserPage(rows.map(AdminUserResponse::from).getContent(), rows.getTotalElements(), page, rows.getTotalPages());
    }

    @Transactional(readOnly = true)
    public AdminUserResponse detail(Long id) {
        return AdminUserResponse.from(users.findById(id).orElseThrow(() ->
            new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy người dùng.")));
    }

    public AdminUserResponse update(Long id, Long adminId, AdminUpdateUserRequest request) {
        User user = editableUser(id, adminId);
        if (request.role() == Role.ADMIN) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Chỉ được chọn vai trò Member.");
        }
        String phone = request.phoneNumber();
        if (phone != null && phone.isBlank()) phone = null;
        if (phone != null) {
            var existing = users.findByPhoneNumber(phone);
            if (existing.isPresent() && !existing.get().getUserId().equals(id)) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Số điện thoại đã được sử dụng.");
            }
        }
        user.setFullName(request.fullName().trim());
        user.setPhoneNumber(phone);
        user.setRole(request.role());
        try {
            users.saveAndFlush(user);
        } catch (DataIntegrityViolationException ex) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Số điện thoại đã được sử dụng.");
        }
        notifications.send(id, "SYSTEM", "Thông tin tài khoản đã cập nhật",
            "Admin đã cập nhật thông tin tài khoản của bạn. Vui lòng kiểm tra lại hồ sơ.", null, null);
        return AdminUserResponse.from(user);
    }

    public AdminUserResponse changeStatus(Long id, Long adminId, UserStatus status) {
        User user = editableUser(id, adminId);
        if (user.getStatus() == status) return AdminUserResponse.from(user);
        user.setStatus(status);
        users.saveAndFlush(user);
        String title = status == UserStatus.LOCKED ? "Tài khoản đã bị khóa" : "Tài khoản đã được mở khóa";
        notifications.send(id, "SYSTEM", title, title + " bởi Admin. Liên hệ hỗ trợ nếu cần trợ giúp.", null, null);
        return AdminUserResponse.from(user);
    }

    private User editableUser(Long id, Long adminId) {
        User user = users.findForAdminUpdate(id).orElseThrow(() ->
            new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy người dùng."));
        if (id.equals(adminId) || user.getRole() == Role.ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Tài khoản Admin chỉ được xem tại trang này.");
        }
        return user;
    }
}
