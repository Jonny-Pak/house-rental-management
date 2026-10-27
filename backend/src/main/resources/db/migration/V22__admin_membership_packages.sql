ALTER TABLE membership_packages ADD COLUMN active BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE membership_packages ADD COLUMN version BIGINT NOT NULL DEFAULT 0;
CREATE UNIQUE INDEX idx_membership_package_name_unique ON membership_packages(lower(package_name));
ALTER TABLE user_subscriptions ADD COLUMN package_name_snapshot VARCHAR(20);
UPDATE user_subscriptions s SET package_name_snapshot = p.package_name FROM membership_packages p WHERE s.package_id = p.package_id;
ALTER TABLE user_subscriptions ALTER COLUMN remaining_standard_quota TYPE INTEGER;
ALTER TABLE user_subscriptions ALTER COLUMN remaining_vip_quota TYPE INTEGER;
ALTER TABLE user_subscriptions ALTER COLUMN remaining_refresh_quota TYPE INTEGER;
ALTER TABLE payment_transactions ADD COLUMN package_id SMALLINT REFERENCES membership_packages(package_id);
ALTER TABLE payment_transactions ADD COLUMN package_name_snapshot VARCHAR(20);
ALTER TABLE payment_transactions ADD COLUMN standard_quota_snapshot SMALLINT;
ALTER TABLE payment_transactions ADD COLUMN vip_quota_snapshot SMALLINT;
ALTER TABLE payment_transactions ADD COLUMN refresh_quota_snapshot SMALLINT;
UPDATE payment_transactions t SET package_id=p.package_id, package_name_snapshot=p.package_name,
    standard_quota_snapshot=p.standard_post_quota, vip_quota_snapshot=p.vip_post_quota, refresh_quota_snapshot=p.refresh_quota
FROM membership_packages p WHERE split_part(t.vnpay_transaction_ref, '_', 1) = p.package_id::text;
CREATE INDEX idx_payments_package_id ON payment_transactions(package_id);
