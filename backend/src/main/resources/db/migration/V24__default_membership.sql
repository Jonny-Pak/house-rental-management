ALTER TABLE membership_packages ADD COLUMN is_default BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO membership_packages (package_name, price, standard_post_quota, vip_post_quota, refresh_quota, description, active, version)
SELECT 'Gói Cơ Bản', 0, 3, 0, 0, 'Gói mặc định cho tài khoản Member.', TRUE, 0
WHERE NOT EXISTS (SELECT 1 FROM membership_packages WHERE price = 0);

UPDATE membership_packages SET is_default = TRUE, active = TRUE
WHERE package_id = (SELECT package_id FROM membership_packages WHERE price = 0 ORDER BY package_id LIMIT 1);

CREATE UNIQUE INDEX idx_membership_default_unique ON membership_packages (is_default) WHERE is_default = TRUE;
ALTER TABLE membership_packages ADD CONSTRAINT ck_default_membership_free_active CHECK (NOT is_default OR (price = 0 AND active = TRUE));
CREATE UNIQUE INDEX idx_user_subscription_unique ON user_subscriptions (user_id);

INSERT INTO user_subscriptions (user_id, package_id, purchased_at, remaining_standard_quota, remaining_vip_quota,
    remaining_refresh_quota, quota_reset_at, status, package_name_snapshot)
SELECT u.user_id, p.package_id, CURRENT_TIMESTAMP, p.standard_post_quota, p.vip_post_quota, p.refresh_quota,
    NULL, 'ACTIVE', p.package_name
FROM users u CROSS JOIN membership_packages p
WHERE p.is_default = TRUE AND u.role = 'MEMBER' AND u.is_verified = TRUE AND u.status = 'ACTIVE'
    AND NOT EXISTS (SELECT 1 FROM user_subscriptions s WHERE s.user_id = u.user_id);
