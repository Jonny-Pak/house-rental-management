package com.rental.modules.user.service;

import org.springframework.stereotype.Service;

import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class OtpService {

    private final ConcurrentHashMap<String, String> otpStore = new ConcurrentHashMap<>();
    private final Random random = new Random();

    /**
     * Generates a 6-digit OTP, stores it mapped to the email, and returns it.
     */
    public String generateAndStoreOtp(String email) {
        String otp = String.format("%06d", random.nextInt(1_000_000));
        otpStore.put(email, otp);
        return otp;
    }

    /**
     * Validates the OTP for the given email.
     * Removes it from the store on success.
     */
    public boolean validateOtp(String email, String otp) {
        String stored = otpStore.get(email);
        if (stored != null && stored.equals(otp)) {
            otpStore.remove(email);
            return true;
        }
        return false;
    }
}
