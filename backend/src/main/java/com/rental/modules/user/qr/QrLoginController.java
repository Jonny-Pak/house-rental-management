package com.rental.modules.user.qr;

import com.rental.core.dto.ApiResponse;
import com.rental.core.security.CustomUserDetails;
import com.rental.modules.user.dto.response.AuthResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
public class QrLoginController {
    private final QrLoginService service;

    public QrLoginController(QrLoginService service) { this.service = service; }

    public record BrowserRequest(@NotNull @Pattern(regexp = "[A-Za-z0-9_-]{43}") String browserSecret) {}
    public record ScanRequest(@NotNull @Pattern(regexp = "[A-Za-z0-9_-]{43}") String scanToken) {}
    public record DecisionRequest(@NotNull @Pattern(regexp = "[A-Za-z0-9_-]{43}") String scanToken, @NotNull Boolean approve) {}

    @PostMapping("/api/v1/auth/qr/start")
    public ResponseEntity<QrLoginService.Started> start(HttpServletRequest request) {
        return noCache(service.start(request.getHeader("Origin"), request.getHeader("User-Agent"), request.getRemoteAddr()));
    }

    @PostMapping("/api/v1/auth/qr/{id}/status")
    public ResponseEntity<QrLoginService.Status> status(@PathVariable String id, @Valid @RequestBody BrowserRequest body) {
        return noCache(service.status(id, body.browserSecret()));
    }

    @PostMapping("/api/v1/auth/qr/{id}/cancel")
    public ResponseEntity<Void> cancel(@PathVariable String id, @Valid @RequestBody BrowserRequest body) {
        service.cancel(id, body.browserSecret());
        return noCache(null);
    }

    @PostMapping("/api/v1/auth/qr/{id}/consume")
    public ResponseEntity<ApiResponse<AuthResponse>> consume(@PathVariable String id, @Valid @RequestBody BrowserRequest body) {
        return noCache(ApiResponse.success("Đăng nhập QR thành công.", service.consume(id, body.browserSecret())));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/api/v1/admin/qr-login/{id}/preview")
    public ResponseEntity<QrLoginService.Preview> preview(@PathVariable String id,
            @Valid @RequestBody ScanRequest body, @AuthenticationPrincipal CustomUserDetails user) {
        return noCache(service.preview(id, body.scanToken(), user.getUser().getUserId()));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/api/v1/admin/qr-login/{id}/decision")
    public ResponseEntity<Void> decide(@PathVariable String id, @Valid @RequestBody DecisionRequest body,
            @AuthenticationPrincipal CustomUserDetails user) {
        service.decide(id, body.scanToken(), user.getUser().getUserId(), body.approve());
        return noCache(null);
    }

    private <T> ResponseEntity<T> noCache(T body) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(body);
    }
}
