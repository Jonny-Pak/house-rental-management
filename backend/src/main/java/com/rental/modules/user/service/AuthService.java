package com.rental.modules.user.service;

import com.rental.core.security.JwtService;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.UserStatus;
import com.rental.modules.user.dto.request.LoginRequest;
import com.rental.modules.user.dto.request.RegisterRequest;
import com.rental.modules.user.dto.request.VerifyOtpRequest;
import com.rental.modules.user.dto.response.AuthResponse;
import com.rental.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final OtpService otpService;
    private final EmailService emailService;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    // ── Register ─────────────────────────────────────────────────────────────

    public String register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email already exists: " + request.getEmail());
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

        return "Registration successful. Please check your email for the OTP verification code.";
    }

    // ── Verify OTP ───────────────────────────────────────────────────────────

    public String verifyOtp(VerifyOtpRequest request) {
        boolean valid = otpService.validateOtp(request.getEmail(), request.getOtp());
        if (!valid) {
            throw new IllegalArgumentException("Invalid or expired OTP.");
        }

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + request.getEmail()));

        user.setIsVerified(true);
        userRepository.save(user);

        return "Account verified successfully. You can now log in.";
    }

    // ── Login ────────────────────────────────────────────────────────────────

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + request.getEmail()));

        if (!Boolean.TRUE.equals(user.getIsVerified())) {
            throw new IllegalStateException("Account not verified. Please verify your email with the OTP code.");
        }

        // Authenticate credentials via Spring Security (throws on bad credentials)
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
}
