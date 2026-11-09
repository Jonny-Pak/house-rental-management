package com.rental.modules.admin.service;

import com.rental.modules.admin.dto.request.AdminCreateUserRequest;
import com.rental.modules.admin.dto.response.AdminUserResponse;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.*;
import com.rental.modules.user.repository.UserRepository;
import com.rental.modules.user.service.EmailService;
import com.rental.modules.user.service.OtpService;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.nio.charset.StandardCharsets;
import java.util.Locale;

@Service
public class AdminCreateUserService {
    private final UserRepository users;
    private final PasswordEncoder passwords;
    private final OtpService otp;
    private final EmailService email;

    public AdminCreateUserService(UserRepository users, PasswordEncoder passwords, OtpService otp, EmailService email) {
        this.users = users;
        this.passwords = passwords;
        this.otp = otp;
        this.email = email;
    }

    @Transactional
    public AdminUserResponse create(AdminCreateUserRequest request) {
        if (request.role() == Role.ADMIN) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Chỉ được tạo tài khoản Member.");
        }
        if (request.password().getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mật khẩu quá dài, vui lòng nhập ngắn hơn.");
        }
        String address = request.email().trim().toLowerCase(Locale.ROOT);
        if (users.existsByEmailIgnoreCase(address)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email đã được sử dụng.");
        }
        String phone = request.phoneNumber();
        if (phone != null && phone.isBlank()) phone = null;
        if (phone != null && users.findByPhoneNumber(phone).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Số điện thoại đã được sử dụng.");
        }
        User user = new User();
        user.setFullName(request.fullName().trim());
        user.setEmail(address);
        user.setPhoneNumber(phone);
        user.setPasswordHash(passwords.encode(request.password()));
        user.setRole(request.role());
        user.setStatus(UserStatus.ACTIVE);
        user.setIsVerified(false);
        try {
            users.saveAndFlush(user);
        } catch (DataIntegrityViolationException ex) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email hoặc số điện thoại đã được sử dụng.");
        }
        String code = otp.generateAndStoreOtp(address);
        try {
            email.sendOtpEmail(address, code);
        } catch (RuntimeException ex) {
            otp.discardOtp(address);
            throw ex;
        }
        return AdminUserResponse.from(user);
    }
}
