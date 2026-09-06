package com.rental.modules.user.service;

import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.UserStatus;
import com.rental.modules.user.dto.request.RegisterRequest;
import com.rental.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final OtpService otpService;
    private final EmailService emailService;

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
}
