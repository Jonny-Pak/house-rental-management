CREATE TABLE admin_qr_logins (
    id VARCHAR(36) PRIMARY KEY,
    browser_secret_hash VARCHAR(64) NOT NULL,
    scan_secret_hash VARCHAR(64) NOT NULL,
    verification_code VARCHAR(6) NOT NULL,
    browser_name VARCHAR(80) NOT NULL,
    website VARCHAR(200) NOT NULL,
    requester_hash VARCHAR(64) NOT NULL,
    status VARCHAR(12) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING','SCANNED','APPROVED','REJECTED','CANCELLED','CONSUMED')),
    admin_id BIGINT REFERENCES users(user_id),
    password_version INTEGER,
    created_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX idx_admin_qr_expiry ON admin_qr_logins(expires_at);
CREATE INDEX idx_admin_qr_requester ON admin_qr_logins(requester_hash, created_at);
