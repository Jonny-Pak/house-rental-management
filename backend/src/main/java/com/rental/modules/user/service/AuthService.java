package com.rental.modules.user.service;

import com.rental.core.security.JwtService;
import com.rental.modules.subscription.service.DefaultMembershipService;
import org.springframework.transaction.annotation.Transactional;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.domain.enums.UserStatus;
import com.rental.modules.user.dto.request.LoginRequest;
import com.rental.modules.user.dto.request.RegisterRequest;
import com.rental.modules.user.dto.request.VerifyOtpRequest;
import com.rental.modules.user.dto.response.AuthResponse;
import com.rental.modules.user.repository.UserRepository;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Locale;
import java.util.Optional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final OtpService otpService;
    private final EmailService emailService;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final DefaultMembershipService defaultMembership;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, OtpService otpService, EmailService emailService, AuthenticationManager authenticationManager, JwtService jwtService, DefaultMembershipService defaultMembership) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.otpService = otpService;
        this.emailService = emailService;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
        this.defaultMembership = defaultMembership;
    }

    @Transactional
    public String register(RegisterRequest request) {
        if (request.getRole() == Role.ADMIN) {
            throw new IllegalArgumentException("Không thể tự đăng ký tài khoản Admin.");
        }
        String email = normalizeEmail(request.getEmail());
        Optional<User> existing = findUserByEmail(email);
        if (existing.isPresent()) {
            User user = existing.get();
            if (Boolean.TRUE.equals(user.getIsVerified())) {
                throw new IllegalArgumentException("Email đã được sử dụng.");
            }
            if (user.getPasswordHash() == null || !passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
                throw new IllegalArgumentException("Email đã được đăng ký. Hãy dùng mật khẩu ban đầu để nhận lại mã.");
            }
            return resendOtp(user.getEmail());
        }

        String phoneNumber = normalizePhoneNumber(request.getPhoneNumber());
        if (phoneNumber != null && userRepository.findByPhoneNumber(phoneNumber).isPresent()) {
            throw new IllegalArgumentException("Số điện thoại đã được sử dụng.");
        }

        User user = new User();
        user.setFullName(request.getFullName().trim());
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setPhoneNumber(phoneNumber);
        user.setRole(request.getRole());
        user.setStatus(UserStatus.ACTIVE);
        user.setIsVerified(false);
        userRepository.save(user);
        sendVerificationCode(email);
        return "Đã gửi mã xác thực. Vui lòng kiểm tra email và thư mục Spam.";
    }

    public String resendOtp(String email) {
        User user = findUnverifiedUser(normalizeEmail(email));
        sendVerificationCode(user.getEmail());
        return "Đã gửi lại mã xác thực. Vui lòng kiểm tra email và thư mục Spam.";
    }

    private User findUnverifiedUser(String email) {
        Optional<User> result = findUserByEmail(email);
        if (result.isEmpty()) throw new IllegalArgumentException("Không tìm thấy tài khoản.");
        User user = result.get();
        if (Boolean.TRUE.equals(user.getIsVerified())) {
            throw new IllegalArgumentException("Tài khoản đã xác thực. Vui lòng đăng nhập.");
        }
        return user;
    }

    private void sendVerificationCode(String email) {
        String normalizedEmail = normalizeEmail(email);
        String otp = otpService.generateAndStoreOtp(normalizedEmail);
        try {
            emailService.sendOtpEmail(normalizedEmail, otp);
        } catch (RuntimeException exception) {
            otpService.discardOtp(normalizedEmail);
            throw exception;
        }
    }

    @Transactional
    public String verifyOtp(VerifyOtpRequest request) {
        String email = normalizeEmail(request.getEmail());
        String otp = request.getOtp() == null ? "" : request.getOtp().trim();
        boolean valid = otpService.validateOtp(email, otp);
        if (!valid) {
            throw new IllegalArgumentException("Mã xác thực không hợp lệ, đã hết hạn hoặc đã nhập sai 5 lần.");
        }

        java.util.Optional<User> userResult = findUserByEmail(email);
        if (userResult.isEmpty()) {
            throw new IllegalArgumentException("User not found with email: " + email);
        }
        User user = userResult.get();

        user.setIsVerified(true);
        userRepository.save(user);
        defaultMembership.assignIfMissing(user.getUserId());

        return "Tài khoản đã xác thực thành công. Vui lòng đăng nhập.";
    }

    public AuthResponse login(LoginRequest request) {
        String email = normalizeEmail(request.getEmail());
        java.util.Optional<User> userResult = findUserByEmail(email);
        if (userResult.isEmpty()) {
            throw new IllegalArgumentException("Người dùng không tồn tại với email: " + email);
        }
        User user = userResult.get();

        if (!Boolean.TRUE.equals(user.getIsVerified())) {
            throw new IllegalStateException("Tài khoản chưa xác thực email. Vui lòng hoàn tất mã OTP của bước đăng ký.");
        }

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(user.getEmail(), request.getPassword())
        );

        return createAuthResponse(user);
    }

    private Optional<User> findUserByEmail(String normalizedEmail) {
        return userRepository.findByEmail(normalizedEmail)
                .or(() -> userRepository.findByEmailIgnoreCase(normalizedEmail));
    }

    private String normalizeEmail(String email) {
        return email == null ? "" : email.trim().toLowerCase(Locale.ROOT);
    }

    private String normalizePhoneNumber(String phoneNumber) {
        if (phoneNumber == null) return null;
        String trimmed = phoneNumber.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private AuthResponse createAuthResponse(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new IllegalStateException("Tài khoản đã bị khóa. Vui lòng liên hệ hỗ trợ.");
        }
        defaultMembership.assignIfMissing(user.getUserId());
        String accessToken  = jwtService.generateAccessToken(user);
        String refreshToken = jwtService.generateRefreshToken(user);

        AuthResponse response = new AuthResponse();
        response.setAccessToken(accessToken);
        response.setRefreshToken(refreshToken);
        response.setUserId(user.getUserId());
        response.setRole(user.getRole().name());
        return response;
    }

}
