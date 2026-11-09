package com.rental.modules.chatbot;

import com.rental.modules.amenity.service.AmenityService;
import com.rental.modules.listing.dto.response.ListingResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import java.math.BigDecimal;
import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class ChatbotService {
    private final ChatbotAiClient ai;
    private final ChatbotSearch search;
    private final AmenityService amenities;
    private final Map<Long, List<Long>> requests = new HashMap<>();

    public ChatbotService(ChatbotAiClient ai, ChatbotSearch search, AmenityService amenities) {
        this.ai = ai;
        this.search = search;
        this.amenities = amenities;
    }

    public ChatReply reply(Long userId, ChatRequest request) {
        validate(request.context());
        if ((request.latitude() == null) != (request.longitude() == null)
            || request.latitude() != null && (!Double.isFinite(request.latitude()) || !Double.isFinite(request.longitude()))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Chọn lại vị trí tìm kiếm.");
        }
        limitRequests(userId);
        if (ChatbotScope.blocked(request.message())) {
            return result("Mình chỉ hỗ trợ các chức năng của ứng dụng và tìm tin công khai. Mình không cung cấp dữ liệu riêng tư hoặc thực hiện lệnh truy cập, thêm, sửa, xóa dữ liệu.", request.context(), List.of(), 0, false);
        }
        String guide = ChatbotScope.guide(request.message());
        if (guide != null) return result(guide, request.context(), List.of(), 0, false);
        if (ChatbotScope.requestsChange(request.message())) {
            return result("Mình không thực hiện thao tác thay đổi dữ liệu hoặc giao dịch. Bạn hãy thao tác tại chức năng tương ứng trong ứng dụng; có thể hỏi mình cách sử dụng chức năng đó.", request.context(), List.of(), 0, false);
        }
        if (!ChatbotScope.searchRelated(request.message())) {
            return result("Mình chỉ hướng dẫn sử dụng các chức năng trong hệ thống và hỗ trợ tìm nhà, phòng trọ, ở ghép từ tin công khai. Bạn muốn tìm nhà hoặc cần hướng dẫn chức năng nào?", request.context(), List.of(), 0, false);
        }
        List<String> names = new ArrayList<>();
        for (var item : amenities.activeItems()) {
            if (names.size() < 200) names.add(item.name());
        }
        SearchPlan plan = ai.analyze(request, names);
        if ("RESET".equals(plan.action())) {
            return new ChatReply("Đã xóa điều kiện và vị trí tìm kiếm. Bạn muốn tìm nhà hoặc phòng như thế nào?",
                ChatFilters.empty(), List.of(), List.of(), 0, false, true);
        }
        if (!"SEARCH".equals(plan.action())) {
            String message = "HELP".equals(plan.action())
                ? "Mình giúp tìm nhà, phòng trọ và người ở ghép từ tin đã duyệt, còn trống. Bạn hãy cho biết loại nhà, giá thuê hoặc khu vực. Ví dụ: Phòng trọ dưới 4 triệu ở Thủ Đức."
                : "Mình chỉ hỗ trợ tìm nhà, phòng trọ và ở ghép. Bạn có thể dùng các chức năng khác trong ứng dụng để đăng tin, quản lý hợp đồng hoặc thanh toán.";
            return result(message, request.context(), List.of(), 0, false);
        }
        ChatFilters filters = plan.filters();
        validate(filters);
        if ("DETAILS".equals(plan.clarification())) {
            return result("Bạn cho mình biết rõ hơn loại nhà, mức giá hoặc điều kiện muốn thay đổi nhé. Mình sẽ giữ các điều kiện hiện có.", filters, List.of(), 0, false);
        }
        boolean changedPlace = filters.locationText() != null
            && !ChatbotSearch.key(filters.locationText()).equals(ChatbotSearch.key(request.context().locationText()));
        if (filters.radiusKm() != null && (request.latitude() == null || changedPlace)) {
            return result("Hãy chọn điểm quanh " + (filters.locationText() == null ? "vị trí bạn muốn tìm" : filters.locationText())
                + " bằng nút Chọn vị trí. Mình sẽ tìm trong bán kính " + filters.radiusKm() + " km từ điểm bạn xác nhận, không tự đoán vị trí.", filters, List.of(), 0, true);
        }
        List<ListingResponse> matched = search.find(filters, request.latitude(), request.longitude());
        int count = matched.size();
        List<ListingResponse> shown = matched.subList(0, Math.min(5, count));
        String message = count == 0
            ? "Chưa có tin đã duyệt, còn trống khớp đầy đủ điều kiện. Bạn có thể tăng mức giá, mở rộng bán kính hoặc bỏ bớt tiện ích. Mình chưa tự thay đổi điều kiện của bạn."
            : "Tìm thấy " + count + " tin phù hợp. Hiển thị " + shown.size() + " tin. Chạm tin để xem chi tiết hoặc mở bản đồ kết quả. Khoảng cách theo bán kính là đường chim bay.";
        return result(message, filters, shown, count, false);
    }

    public void validate(ChatFilters filters) {
        for (String text : filters.amenities()) {
            if (ChatbotSearch.key(text).isEmpty()) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Tên tiện ích không hợp lệ.");
        }
        for (String text : filters.keywords()) {
            if (ChatbotSearch.key(text).isEmpty()) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Từ khóa không hợp lệ.");
        }
        if (filters.minPrice() != null && filters.maxPrice() != null && filters.minPrice().compareTo(filters.maxPrice()) > 0
            || filters.minArea() != null && filters.maxArea() != null && filters.minArea().compareTo(filters.maxArea()) > 0
            || filters.radiusKm() != null && !Double.isFinite(filters.radiusKm())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Khoảng giá, diện tích hoặc bán kính không hợp lệ.");
        }
    }

    private synchronized void limitRequests(Long userId) {
        long now = System.currentTimeMillis();
        var iterator = requests.entrySet().iterator();
        while (iterator.hasNext()) {
            var entry = iterator.next();
            entry.getValue().removeIf(time -> time < now - 60000);
            if (entry.getValue().isEmpty()) iterator.remove();
        }
        List<Long> times = requests.computeIfAbsent(userId, id -> new ArrayList<>());
        if (times.size() >= 12) throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Bạn đã gửi nhiều câu hỏi. Vui lòng chờ một phút rồi thử lại.");
        times.add(now);
    }

    private ChatReply result(String message, ChatFilters filters, List<ListingResponse> listings, int total, boolean locationRequired) {
        return new ChatReply(message, filters, conditions(filters), listings, total, locationRequired);
    }

    private List<String> conditions(ChatFilters f) {
        List<String> values = new ArrayList<>();
        if (f.listingType() != null) values.add(switch (f.listingType()) {
            case "WHOLE_HOUSE" -> "Nhà nguyên căn";
            case "BOARDING_ROOM" -> "Phòng trọ";
            default -> "Ở ghép";
        });
        if (f.locationText() != null && !f.locationText().isBlank()) values.add(f.locationText());
        if (f.minPrice() != null) values.add("Từ " + money(f.minPrice()) + " đ/tháng");
        if (f.maxPrice() != null) values.add("Đến " + money(f.maxPrice()) + " đ/tháng");
        if (f.minArea() != null) values.add("Từ " + f.minArea() + " m²");
        if (f.maxArea() != null) values.add("Đến " + f.maxArea() + " m²");
        if (f.bedrooms() != null) values.add("Ít nhất " + f.bedrooms() + " phòng ngủ");
        if (f.allowPets() != null) values.add(f.allowPets() ? "Cho nuôi thú cưng" : "Không nuôi thú cưng");
        if (f.allowSmoking() != null) values.add(f.allowSmoking() ? "Cho hút thuốc" : "Không hút thuốc");
        if (f.genderPreference() != null) values.add("Giới tính: " + switch (f.genderPreference()) { case "MALE" -> "Nam"; case "FEMALE" -> "Nữ"; default -> "Không yêu cầu"; });
        values.addAll(f.amenities()); values.addAll(f.keywords());
        if (f.radiusKm() != null) values.add("Bán kính " + f.radiusKm() + " km");
        if ("PRICE_ASC".equals(f.sort())) values.add("Giá thấp trước");
        if ("AREA_DESC".equals(f.sort())) values.add("Diện tích lớn trước");
        return values;
    }

    private String money(BigDecimal value) {
        return NumberFormat.getIntegerInstance(Locale.forLanguageTag("vi-VN")).format(value);
    }
}
