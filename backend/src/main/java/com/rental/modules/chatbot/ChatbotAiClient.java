package com.rental.modules.chatbot;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.validation.Validator;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;

@Component
public class ChatbotAiClient {
    private final String baseUrl;
    private final String token;
    private final Validator validator;
    private final ObjectMapper json;
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();

    public ChatbotAiClient(@Value("${app.chatbot.url:http://127.0.0.1:8001}") String baseUrl,
                           @Value("${app.chatbot.service-token:}") String token, Validator validator, ObjectMapper json) {
        this.baseUrl = baseUrl;
        this.token = token;
        this.validator = validator;
        this.json = json.copy().enable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);
    }

    public SearchPlan analyze(ChatRequest request, List<String> amenityNames) {
        if (token.isBlank()) throw unavailable("Chưa cấu hình kết nối dịch vụ AI.");
        var body = new LinkedHashMap<String, Object>();
        body.put("message", request.message());
        body.put("context", request.context());
        body.put("locationName", request.locationName());
        body.put("amenityNames", amenityNames);
        try {
            var httpRequest = HttpRequest.newBuilder(URI.create(baseUrl + "/analyze"))
                .timeout(Duration.ofSeconds(32)).header("Content-Type", "application/json")
                .header("X-Service-Token", token).POST(HttpRequest.BodyPublishers.ofString(json.writeValueAsString(body))).build();
            var response = http.send(httpRequest, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 429) {
                throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "AI đang giới hạn lượt dùng. Vui lòng thử lại sau.");
            }
            if (response.statusCode() == 504) throw new ResponseStatusException(HttpStatus.GATEWAY_TIMEOUT, "AI phản hồi chậm. Vui lòng thử lại.");
            if (response.statusCode() != 200) throw unavailable("Dịch vụ tìm nhà chưa sẵn sàng. Kiểm tra ai-service và huấn luyện mô hình nội bộ bằng python train.py.");
            if (response.body().length() > 20000) throw unavailable("Phản hồi AI không hợp lệ. Vui lòng thử lại.");
            SearchPlan plan = json.readValue(response.body(), SearchPlan.class);
            if (plan == null || !validator.validate(plan).isEmpty()) throw unavailable("AI trả điều kiện không hợp lệ. Hãy viết lại yêu cầu.");
            return plan;
        } catch (ResponseStatusException exception) {
            throw exception;
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw unavailable("Yêu cầu AI bị gián đoạn. Vui lòng thử lại.");
        } catch (Exception exception) {
            throw unavailable("Chưa kết nối được dịch vụ AI hoặc phản hồi không hợp lệ. Vui lòng thử lại.");
        }
    }

    private ResponseStatusException unavailable(String message) {
        return new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, message);
    }
}
