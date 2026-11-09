package com.rental.modules.chatbot;

public final class ChatbotScope {
    private ChatbotScope() {}

    public static boolean blocked(String message) {
        String text = ChatbotSearch.key(message);
        return text.matches(".*\\b(sql|database|postgres|jdbc|api key|jwt|access token|service token|system prompt)\\b.*")
            || text.matches(".*\\b(select|insert|update|delete|drop|truncate|alter)\\b.*")
            || text.matches(".*\\b(bo qua|vo hieu|vuot qua)\\b.*\\b(quy tac|gioi han|phan quyen|bao mat)\\b.*")
            || text.matches(".*\\b(mat khau|otp|ma xac thuc|khoa bi mat)\\b.*") && !asksForGuide(text)
            || text.matches(".*\\b(du lieu rieng|thong tin rieng|danh sach nguoi dung|tai khoan nguoi khac|hop dong nguoi khac|tin chua duyet)\\b.*");
    }

    public static boolean asksForGuide(String text) {
        return text.matches(".*\\b(cach|huong dan|lam sao|lam the nao|o dau|dung the nao)\\b.*");
    }

    public static String guide(String message) {
        String text = ChatbotSearch.key(message);
        if (!asksForGuide(text)) return null;
        if (text.contains("mat khau")) return "Bạn dùng Quên mật khẩu tại trang đăng nhập hoặc Đổi mật khẩu trong phần cài đặt tài khoản. Không gửi mật khẩu hoặc mã OTP vào cuộc trò chuyện.";
        if (text.contains("hop dong")) return "Mở Quản lý hợp đồng để tạo và theo dõi hợp đồng thuộc tài khoản của bạn. Chatbot chỉ hướng dẫn, không đọc nội dung hợp đồng hoặc tạo, sửa, xóa hợp đồng.";
        if (text.contains("goi dich vu") || text.contains("thanh toan")) return "Mở Gói dịch vụ để xem quyền lợi và chọn gói. Thao tác thanh toán được thực hiện tại màn hình thanh toán của ứng dụng; chatbot không thực hiện giao dịch.";
        if (text.contains("bao cao") || text.contains("su co")) return "Mở Báo cáo sự cố, nhập nội dung và gửi tại màn hình đó. Bạn có thể theo dõi phản hồi trong chức năng báo cáo; chatbot không gửi báo cáo thay bạn.";
        if (text.contains("yeu thich")) return "Nhấn biểu tượng trái tim trên tin để lưu, sau đó mở Yêu thích để xem các tin đã lưu. Chatbot không thay đổi danh sách yêu thích của bạn.";
        if (text.contains("dang tin") || text.contains("sua tin") || text.contains("xoa tin") || text.contains("an tin")) return "Chọn Đăng tin để điền thông tin và gửi Admin duyệt. Mở Quản lý tin đăng để sửa, ẩn, đánh dấu đã cho thuê hoặc xóa tin của bạn. Chatbot không thao tác thay bạn.";
        if (text.contains("ban do") || text.contains("ban kinh")) return "Mở Bản đồ, chọn điểm tìm kiếm và bán kính. Trong chatbot, hãy nhập nhu cầu rồi dùng Chọn vị trí tìm quanh đây. Khoảng cách là đường chim bay.";
        if (text.contains("ho so") || text.contains("so thich")) return "Mở Hồ sơ người dùng để xem tài khoản, gói dịch vụ và chọn tối đa 5 sở thích. Mọi thay đổi cần thực hiện tại màn hình tương ứng.";
        return null;
    }

    public static boolean requestsChange(String message) {
        String text = ChatbotSearch.key(message);
        return text.matches(".*\\b(tao|them|sua|xoa|cap nhat|duyet|tu choi|an|gia han|huy)\\b.*\\b(tin dang|bai dang|hop dong|tai khoan|nguoi dung|du lieu|goi dich vu)\\b.*")
            || text.matches(".*\\b(dang tin|sua tin|xoa tin|an tin|thanh toan|chuyen tien|mua goi|doi mat khau|gui thong bao|gui bao cao)\\b.*");
    }

    public static boolean searchRelated(String message) {
        String text = ChatbotSearch.key(message);
        return text.matches(".*\\b(nha|phong|tro|o ghep|nguyen can|gia|trieu|ngan sach|re hon|dien tich|m2|km|ban kinh|vi tri|chon diem|tien ich|may lanh|dieu hoa|wifi|ban cong|nuoi|thu cung|hut thuoc|khu vuc|dieu kien|bo loc|bat dau|tim lai|reset|tieu chi|ngu canh|yeu cau|doi sang|thay khu vuc|moi nhat)\\b.*");
    }
}
