UPDATE notifications SET is_read = FALSE WHERE is_read IS NULL;
ALTER TABLE notifications ALTER COLUMN is_read SET NOT NULL;
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC, notification_id DESC);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id) WHERE is_read = FALSE;
