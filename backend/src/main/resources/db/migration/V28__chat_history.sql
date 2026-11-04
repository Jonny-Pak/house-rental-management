CREATE TABLE chatbot_history (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    request_json TEXT NOT NULL,
    reply_json TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chatbot_history_user_id ON chatbot_history(user_id, id DESC);
