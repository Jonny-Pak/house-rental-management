package com.rental.modules.user.qr;

import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "admin_qr_logins")
public class QrLoginSession {
    @Id private String id;
    @Column(name = "browser_secret_hash", nullable = false) private String browserSecretHash;
    @Column(name = "scan_secret_hash", nullable = false) private String scanSecretHash;
    @Column(name = "verification_code", nullable = false) private String verificationCode;
    @Column(name = "browser_name", nullable = false) private String browserName;
    @Column(nullable = false) private String website;
    @Column(name = "requester_hash", nullable = false) private String requesterHash;
    @Column(nullable = false) private String status = "PENDING";
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "admin_id") private User admin;
    @Column(name = "password_version") private Integer passwordVersion;
    @Column(name = "created_at", nullable = false) private Instant createdAt;
    @Column(name = "expires_at", nullable = false) private Instant expiresAt;

    public String getId() { return id; }
    public void setId(String value) { id = value; }
    public String getBrowserSecretHash() { return browserSecretHash; }
    public void setBrowserSecretHash(String value) { browserSecretHash = value; }
    public String getScanSecretHash() { return scanSecretHash; }
    public void setScanSecretHash(String value) { scanSecretHash = value; }
    public String getVerificationCode() { return verificationCode; }
    public void setVerificationCode(String value) { verificationCode = value; }
    public String getBrowserName() { return browserName; }
    public void setBrowserName(String value) { browserName = value; }
    public String getWebsite() { return website; }
    public void setWebsite(String value) { website = value; }
    public String getRequesterHash() { return requesterHash; }
    public void setRequesterHash(String value) { requesterHash = value; }
    public String getStatus() { return status; }
    public void setStatus(String value) { status = value; }
    public User getAdmin() { return admin; }
    public void setAdmin(User value) { admin = value; }
    public Integer getPasswordVersion() { return passwordVersion; }
    public void setPasswordVersion(Integer value) { passwordVersion = value; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant value) { createdAt = value; }
    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant value) { expiresAt = value; }
}
