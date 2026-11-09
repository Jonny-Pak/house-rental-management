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
        jdbc.update("INSERT INTO lich_su_tro_chuyen(ma_nguoi_dung, yeu_cau_hoi_thoai_json, phan_hoi_hoi_thoai_json) VALUES (?, ?, ?)", userId, request, reply);
    }

    public List<Row> find(Long userId, long beforeId) {
        return jdbc.query("SELECT ma_ban_ghi, yeu_cau_hoi_thoai_json, phan_hoi_hoi_thoai_json, thoi_diem_tao FROM lich_su_tro_chuyen WHERE ma_nguoi_dung = ? AND ma_ban_ghi < ? ORDER BY ma_ban_ghi DESC LIMIT 31",
            (row, index) -> new Row(row.getLong("ma_ban_ghi"), row.getString("yeu_cau_hoi_thoai_json"), row.getString("phan_hoi_hoi_thoai_json"), row.getTimestamp("thoi_diem_tao").toInstant().toString()), userId, beforeId);
    }

    public void clear(Long userId) {
        jdbc.update("DELETE FROM lich_su_tro_chuyen WHERE ma_nguoi_dung = ?", userId);
    }
}
