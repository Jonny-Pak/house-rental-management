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

    public String register(RegisterRequest request) {
        if (request.getRole() == Role.ADMIN) {
            throw new IllegalArgumentException("Không thể tự đăng ký tài khoản Admin.");
        }
        Optional<User> existing = userRepository.findByEmail(request.getEmail());
        if (existing.isPresent()) {
            User user = existing.get();
            if (Boolean.TRUE.equals(user.getIsVerified())) {
                throw new IllegalArgumentException("Email đã được sử dụng.");
            }
            if (user.getPasswordHash() == null || !passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
                throw new IllegalArgumentException("Email đã được đăng ký. Hãy dùng mật khẩu ban đầu để nhận lại mã.");
            }
            return resendOtp(request.getEmail());
        }

        User user = new User();
        user.setFullName(request.getFullName());
        user.setEmail(request.getEmail());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setPhoneNumber(request.getPhoneNumber());
        user.setRole(request.getRole());
        user.setStatus(UserStatus.ACTIVE);
        user.setIsVerified(false);
        userRepository.save(user);
        sendVerificationCode(request.getEmail());
        return "Đã gửi mã xác thực. Vui lòng kiểm tra email và thư mục Spam.";
    }

    public String resendOtp(String email) {
        User user = findUnverifiedUser(email);
        sendVerificationCode(user.getEmail());
        return "Đã gửi lại mã xác thực. Vui lòng kiểm tra email và thư mục Spam.";
    }

    private User findUnverifiedUser(String email) {
        Optional<User> result = userRepository.findByEmail(email);
        if (result.isEmpty()) throw new IllegalArgumentException("Không tìm thấy tài khoản.");
        User user = result.get();
        if (Boolean.TRUE.equals(user.getIsVerified())) {
            throw new IllegalArgumentException("Tài khoản đã xác thực. Vui lòng đăng nhập.");
        }
        return user;
    }

    private void sendVerificationCode(String email) {
        String otp = otpService.generateAndStoreOtp(email);
        try {
            emailService.sendOtpEmail(email, otp);
        } catch (RuntimeException exception) {
            otpService.discardOtp(email);
            throw exception;
        }
    }

    @Transactional
    public String verifyOtp(VerifyOtpRequest request) {
        boolean valid = otpService.validateOtp(request.getEmail(), request.getOtp());
        if (!valid) {
            throw new IllegalArgumentException("Mã xác thực không hợp lệ hoặc đã hết hạn.");
        }

        java.util.Optional<User> userResult = userRepository.findByEmail(request.getEmail());
        if (userResult.isEmpty()) {
            throw new IllegalArgumentException("User not found with email: " + request.getEmail());
        }
        User user = userResult.get();

        user.setIsVerified(true);
        userRepository.save(user);
        defaultMembership.assignIfMissing(user.getUserId());

        return "Tài khoản đã xác thực thành công. Vui lòng đăng nhập.";
    }

    public AuthResponse login(LoginRequest request) {
        java.util.Optional<User> userResult = userRepository.findByEmail(request.getEmail());
        if (userResult.isEmpty()) {
            throw new IllegalArgumentException("Người dùng không tồn tại với email: " + request.getEmail());
        }
        User user = userResult.get();

        if (!Boolean.TRUE.equals(user.getIsVerified())) {
            throw new IllegalStateException("Tài khoản chưa xác thực email. Vui lòng hoàn tất mã OTP của bước đăng ký.");
        }

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        return createAuthResponse(user);
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
