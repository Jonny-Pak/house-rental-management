package com.rental.modules.user.service;

import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.UserStatus;
import com.rental.modules.user.dto.request.*;
import com.rental.modules.user.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.Optional;

@Service
public class PasswordService {
    private final UserRepository users;
    private final PasswordEncoder encoder;
    private final OtpService codes;
    private final EmailService email;
    public PasswordService(UserRepository users, PasswordEncoder encoder, OtpService codes, EmailService email) {
        this.users = users;
        this.encoder = encoder;
        this.codes = codes;
        this.email = email;
    }

    @Transactional
    public String requestReset(String address) {
        Optional<User> found = users.findForPasswordUpdate(address.trim());
        if (found.isPresent()) {
            User user = found.get();
            if (user.getStatus() == UserStatus.ACTIVE && Boolean.TRUE.equals(user.getIsVerified())) {
                String key = resetKey(user);
                String code = codes.generateAndStoreOtp(key);
                try {
                    email.sendPasswordResetEmail(user.getEmail(), code);
                } catch (RuntimeException error) {
                    codes.discardOtp(key);
                    throw error;
                }
            }
        }
        return "Nếu email thuộc tài khoản đã xác thực và đang hoạt động, mã đặt lại mật khẩu sẽ được gửi. Vui lòng kiểm tra cả thư mục Spam.";
    }

    @Transactional
    public void reset(ResetPasswordRequest request) {
        User user = findActiveUser(request.email());
        if (!codes.validateOtp(resetKey(user), request.otp())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mã không hợp lệ, đã hết hạn hoặc đã nhập sai 5 lần. Hãy yêu cầu mã mới.");
        }
        validateNewPassword(user, request.newPassword());
        updatePassword(user, request.newPassword());
    }

    @Transactional
    public void change(String accountEmail, ChangePasswordRequest request) {
        User user = findActiveUser(accountEmail);
        if (user.getPasswordHash() == null || !encoder.matches(request.currentPassword(), user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mật khẩu hiện tại không đúng. Nếu đăng nhập bằng Google, hãy dùng chức năng Quên mật khẩu để tạo mật khẩu.");
        }
        validateNewPassword(user, request.newPassword());
        codes.discardOtp(resetKey(user));
        updatePassword(user, request.newPassword());
    }

    private User findActiveUser(String address) {
        Optional<User> found = users.findForPasswordUpdate(address.trim());
        if (found.isEmpty() || found.get().getStatus() != UserStatus.ACTIVE || !Boolean.TRUE.equals(found.get().getIsVerified())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Không thể cập nhật mật khẩu cho tài khoản này.");
        }
        return found.get();
    }

    private void validateNewPassword(User user, String password) {
        if (password == null || password.isBlank() || password.length() < 8 || password.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mật khẩu mới cần ít nhất 8 ký tự và tối đa 72 byte UTF-8.");
        }
        if (user.getPasswordHash() != null && encoder.matches(password, user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mật khẩu mới phải khác mật khẩu hiện tại.");
        }
    }

    private void updatePassword(User user, String password) {
        user.setPasswordHash(encoder.encode(password));
        user.setPasswordVersion(user.getPasswordVersion() + 1);
        users.save(user);
    }

    private String resetKey(User user) {
        return "password-reset:" + user.getEmail().toLowerCase(Locale.ROOT) + ":" + user.getPasswordVersion();
    }
}
