ALTER TABLE payment_transactions ADD COLUMN vnpay_response_code VARCHAR(2);
CREATE INDEX idx_payment_user_date ON payment_transactions (user_id, transaction_date DESC);
