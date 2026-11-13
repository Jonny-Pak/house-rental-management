package com.rental.modules.user;

import com.rental.core.exception.GlobalExceptionHandler;
import com.rental.core.security.CustomUserDetailsService;
import com.rental.core.security.JwtAuthenticationFilter;
import com.rental.core.security.JwtService;
import com.rental.core.security.SecurityConfig;
import com.rental.modules.user.controller.AuthController;
import com.rental.modules.user.dto.request.RegisterRequest;
import com.rental.modules.user.dto.request.VerifyOtpRequest;
import com.rental.modules.user.service.AuthService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, GlobalExceptionHandler.class})
class AuthControllerTest {

    @Autowired
    private MockMvc mvc;

    @MockBean
    private AuthService authService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService userDetailsService;

    @Test
    void registerVerifyAndResendArePublicAndReturnExpectedStatuses() throws Exception {
        when(authService.register(any(RegisterRequest.class)))
                .thenReturn("Đã gửi mã xác thực. Vui lòng kiểm tra email và thư mục Spam.");
        when(authService.resendOtp("tenant@example.com"))
                .thenReturn("Đã gửi lại mã xác thực. Vui lòng kiểm tra email và thư mục Spam.");
        when(authService.verifyOtp(any(VerifyOtpRequest.class)))
                .thenReturn("Tài khoản đã xác thực thành công. Vui lòng đăng nhập.");

        mvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Nguyen Van A","email":"tenant@example.com","password":"password123","phoneNumber":"0912345678","role":"MEMBER"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Đã gửi mã xác thực. Vui lòng kiểm tra email và thư mục Spam."));

        mvc.perform(post("/api/v1/auth/resend-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"tenant@example.com"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        mvc.perform(post("/api/v1/auth/verify-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"tenant@example.com","otp":"123456"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void registerValidationErrorsReturnFieldMapAndPropagateRateLimitAndSmtpErrors() throws Exception {
        mvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"","email":"bad","password":"123","role":"MEMBER"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.data.email").exists())
                .andExpect(jsonPath("$.data.password").exists())
                .andExpect(jsonPath("$.data.fullName").exists());
        verifyNoInteractions(authService);

        when(authService.resendOtp("tenant@example.com"))
                .thenThrow(new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS,
                        "Vui lòng chờ 60 giây trước khi gửi lại mã."));
        mvc.perform(post("/api/v1/auth/resend-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"tenant@example.com"}
                                """))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.message").value("Vui lòng chờ 60 giây trước khi gửi lại mã."));

        when(authService.register(any(RegisterRequest.class)))
                .thenThrow(new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                        "Chưa gửi được email xác thực. Vui lòng thử lại sau."));
        mvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Nguyen Van A","email":"tenant@example.com","password":"password123","phoneNumber":"0912345678","role":"MEMBER"}
                                """))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.message").value("Chưa gửi được email xác thực. Vui lòng thử lại sau."));
    }
}
