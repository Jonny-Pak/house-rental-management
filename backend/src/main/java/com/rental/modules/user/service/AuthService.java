package com.rental.modules.user.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken.Payload;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.rental.core.security.JwtService;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.domain.enums.UserStatus;
import com.rental.modules.user.dto.request.GoogleLoginRequest;
import com.rental.modules.user.dto.request.LoginRequest;
import com.rental.modules.user.dto.request.RegisterRequest;
import com.rental.modules.user.dto.request.VerifyOtpRequest;
import com.rental.modules.user.dto.response.AuthResponse;
import com.rental.modules.user.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.Optional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final OtpService otpService;
    private final EmailService emailService;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, OtpService otpService, EmailService emailService, AuthenticationManager authenticationManager, JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.otpService = otpService;
        this.emailService = emailService;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
    }

    @Value("${app.google.client-id}")
    private String googleClientId;

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

        return "Tài khoản đã xác thực thành công. Vui lòng đăng nhập.";
    }

    public AuthResponse login(LoginRequest request) {
        java.util.Optional<User> userResult = userRepository.findByEmail(request.getEmail());
        if (userResult.isEmpty()) {
            throw new IllegalArgumentException("NgÆ°á»i dÃ¹ng khÃ´ng tá»“n táº¡i vá»›i email: " + request.getEmail());
        }
        User user = userResult.get();

        if (!Boolean.TRUE.equals(user.getIsVerified())) {
            throw new IllegalStateException("TÃ i khoáº£n chÆ°a Ä‘Æ°á»£c xÃ¡c minh. Vui lÃ²ng xÃ¡c minh email cá»§a báº¡n báº±ng mÃ£ OTP.");
        }

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        return createAuthResponse(user);
    }

    public AuthResponse googleLogin(GoogleLoginRequest request) {

        GoogleIdToken idToken = verifyGoogleToken(request.getIdToken());
        User user = findOrCreateGoogleUser(idToken.getPayload());
        return createAuthResponse(user);
    }

    private GoogleIdToken verifyGoogleToken(String token) {
        GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(
                new NetHttpTransport(), GsonFactory.getDefaultInstance())
                .setAudience(Collections.singletonList(googleClientId))
                .build();

        GoogleIdToken idToken;
        try {
            idToken = verifier.verify(token);
        } catch (Exception e) {
            throw new IllegalArgumentException("Tháº¥t báº¡i khi xÃ¡c minh Google ID Token: " + e.getMessage());
        }

        if (idToken == null) {
            throw new IllegalArgumentException("Token Google ID khÃ´ng há»£p lá»‡ hoáº·c Ä‘Ã£ háº¿t háº¡n. Vui lÃ²ng thá»­ láº¡i.");
        }

        return idToken;
    }

    private User findOrCreateGoogleUser(Payload payload) {
        String email      = payload.getEmail();
        String name       = (String) payload.get("name");
        String googleId   = payload.getSubject();
        String avatarUrl  = (String) payload.get("picture");

        Optional<User> existingUser = userRepository.findByEmail(email);
        User user;

        if (existingUser.isPresent()) {

            user = existingUser.get();
            if (user.getGoogleId() == null) {
                user.setGoogleId(googleId);
            }
            if (user.getAvatarUrl() == null) {
                user.setAvatarUrl(avatarUrl);
            }
            user.setIsVerified(true);
            userRepository.save(user);
        } else {

            user = new User();
            user.setEmail(email);
            user.setFullName(name);
            user.setGoogleId(googleId);
            user.setAvatarUrl(avatarUrl);
            user.setPasswordHash(null);
            user.setRole(Role.USER);
            user.setStatus(UserStatus.ACTIVE);
            user.setIsVerified(true);
            userRepository.save(user);
        }

        return user;
    }

    private AuthResponse createAuthResponse(User user) {
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
