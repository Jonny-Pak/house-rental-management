package com.rental.modules.user.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public class VerifyOtpRequest {

    @Email(message = "Email không hợp lệ")
    @NotBlank(message = "Email không được để trống")
    private String email;

    @NotBlank(message = "OTP không được để trống")
    private String otp;

    public VerifyOtpRequest() {}
    public VerifyOtpRequest(String email, String otp) {
        this.email = email;
        this.otp = otp;
    }
    public String getEmail() { return email; }    public void setEmail(String email) { this.email = email; }
    public String getOtp() { return otp; }    public void setOtp(String otp) { this.otp = otp; }

}
