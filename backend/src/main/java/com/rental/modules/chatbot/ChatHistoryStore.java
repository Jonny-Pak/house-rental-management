package com.rental.modules.chatbot;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public class ChatHistoryStore {
    private final JdbcTemplate jdbc;

    public ChatHistoryStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public record Row(long id, String requestJson, String replyJson, String createdAt) {}

    public void save(Long userId, String request, String reply) {
        jdbc.update("INSERT INTO chatbot_history(user_id, request_json, reply_json) VALUES (?, ?, ?)", userId, request, reply);
    }

    public List<Row> find(Long userId, long beforeId) {
        return jdbc.query("SELECT id, request_json, reply_json, created_at FROM chatbot_history WHERE user_id = ? AND id < ? ORDER BY id DESC LIMIT 31",
            (row, index) -> new Row(row.getLong("id"), row.getString("request_json"), row.getString("reply_json"), row.getTimestamp("created_at").toInstant().toString()), userId, beforeId);
    }

    public void clear(Long userId) {
        jdbc.update("DELETE FROM chatbot_history WHERE user_id = ?", userId);
    }
}
