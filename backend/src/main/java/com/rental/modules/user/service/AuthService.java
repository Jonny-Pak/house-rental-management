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
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final OtpService otpService;
    private final EmailService emailService;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    @Value("${app.google.client-id}")
    private String googleClientId;

    // ── Register ─────────────────────────────────────────────────────────────

    public String register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email " + request.getEmail() + "đã được sử dụng. Vui lòng sử dụng email khác.");
        }

        User user = User.builder()
                .fullName(request.getFullName())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .phoneNumber(request.getPhoneNumber())
                .role(request.getRole())
                .status(UserStatus.ACTIVE)
                .isVerified(false)
                .build();

        userRepository.save(user);

        String otp = otpService.generateAndStoreOtp(request.getEmail());
        emailService.sendOtpEmail(request.getEmail(), otp);

        return "Đăng ký thành công. Vui lòng kiểm tra email của bạn để nhận mã xác minh.";
    }

    // ── Verify OTP ───────────────────────────────────────────────────────────

    public String verifyOtp(VerifyOtpRequest request) {
        boolean valid = otpService.validateOtp(request.getEmail(), request.getOtp());
        if (!valid) {
            throw new IllegalArgumentException("Mã xác minh không hợp lệ hoặc đã hết hạn.");
        }

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + request.getEmail()));

        user.setIsVerified(true);
        userRepository.save(user);

        return "Tài khoản đã được xác minh thành công. Bạn có thể đăng nhập ngay bây giờ.";
    }

    // ── Login ────────────────────────────────────────────────────────────────

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Người dùng không tồn tại với email: " + request.getEmail()));

        if (!Boolean.TRUE.equals(user.getIsVerified())) {
            throw new IllegalStateException("Tài khoản chưa được xác minh. Vui lòng xác minh email của bạn bằng mã OTP.");
        }

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        String accessToken  = jwtService.generateAccessToken(user);
        String refreshToken = jwtService.generateRefreshToken(user);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .userId(user.getUserId())
                .role(user.getRole().name())
                .build();
    }

    // ── Google Login ─────────────────────────────────────────────────────────

    public AuthResponse googleLogin(GoogleLoginRequest request) {
        // 1. Verify the Google ID Token
        GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(
                new NetHttpTransport(), GsonFactory.getDefaultInstance())
                .setAudience(Collections.singletonList(googleClientId))
                .build();

        GoogleIdToken idToken;
        try {
            idToken = verifier.verify(request.getIdToken());
        } catch (Exception e) {
            throw new IllegalArgumentException("Thất bại khi xác minh Google ID Token: " + e.getMessage());
        }

        if (idToken == null) {
            throw new IllegalArgumentException("Token Google ID không hợp lệ hoặc đã hết hạn. Vui lòng thử lại.");
        }

        // 2. Extract user info from payload
        Payload payload   = idToken.getPayload();
        String email      = payload.getEmail();
        String name       = (String) payload.get("name");
        String googleId   = payload.getSubject();
        String avatarUrl  = (String) payload.get("picture");

        // 3. Find or create user
        Optional<User> existingUser = userRepository.findByEmail(email);
        User user;

        if (existingUser.isPresent()) {
            // Update googleId and avatarUrl if they are currently null
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
            // Create a brand-new OAuth user
            user = User.builder()
                    .email(email)
                    .fullName(name)
                    .googleId(googleId)
                    .avatarUrl(avatarUrl)
                    .passwordHash(null)
                    .role(Role.USER)
                    .status(UserStatus.ACTIVE)
                    .isVerified(true)
                    .build();
            userRepository.save(user);
        }

        // 4. Generate tokens and return
        String accessToken  = jwtService.generateAccessToken(user);
        String refreshToken = jwtService.generateRefreshToken(user);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .userId(user.getUserId())
                .role(user.getRole().name())
                .build();
    }
}
