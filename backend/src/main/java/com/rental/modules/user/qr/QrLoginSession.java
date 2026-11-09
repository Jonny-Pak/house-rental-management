package com.rental.modules.user.qr;

import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "phien_dang_nhap_qr_quan_tri")
public class QrLoginSession {
    @Column(name = "ma_ban_ghi")
    @Id private String id;
    @Column(name = "bam_bi_mat_trinh_duyet", nullable = false) private String browserSecretHash;
    @Column(name = "bam_bi_mat_quet_qr", nullable = false) private String scanSecretHash;
    @Column(name = "ma_xac_thuc", nullable = false) private String verificationCode;
    @Column(name = "ten_trinh_duyet", nullable = false) private String browserName;
    @Column(name = "dia_chi_trang_web", nullable = false) private String website;
    @Column(name = "bam_bang_chung_ben_yeu_cau", nullable = false) private String requesterHash;
    @Column(name = "trang_thai", nullable = false) private String status = "PENDING";
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "ma_quan_tri_vien") private User admin;
    @Column(name = "phien_ban_mat_khau") private Integer passwordVersion;
    @Column(name = "thoi_diem_tao", nullable = false) private Instant createdAt;
    @Column(name = "thoi_diem_het_han", nullable = false) private Instant expiresAt;

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
