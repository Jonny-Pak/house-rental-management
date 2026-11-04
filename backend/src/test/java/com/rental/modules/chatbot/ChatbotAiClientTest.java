package com.rental.modules.chatbot;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpServer;
import jakarta.validation.Validation;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;
import static org.junit.jupiter.api.Assertions.*;

class ChatbotAiClientTest {
    @Test void sendsOnlySearchContextAndValidatesResponseFromRealHttpBoundary() throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1",0),0);
        AtomicReference<String> output = new AtomicReference<>("{\"action\":\"SEARCH\",\"clarification\":\"NONE\",\"filters\":{\"maxPrice\":4000000}}");
        AtomicReference<String> input = new AtomicReference<>();
        var status = new java.util.concurrent.atomic.AtomicInteger(200);
        server.createContext("/analyze", exchange -> {
            assertEquals("test-service-token",exchange.getRequestHeaders().getFirst("X-Service-Token"));
            input.set(new String(exchange.getRequestBody().readAllBytes(),StandardCharsets.UTF_8));
            byte[] bytes=output.get().getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(status.get(),bytes.length);
            exchange.getResponseBody().write(bytes); exchange.close();
        });
        server.start();
        try(var validation = Validation.buildDefaultValidatorFactory()) {
            var ai = new ChatbotAiClient("http://127.0.0.1:"+server.getAddress().getPort(),"test-service-token",validation.getValidator(),new ObjectMapper());
            var request = new ChatRequest("Tìm phòng",null,10.78,106.7,"Điểm đã chọn");
            assertEquals(4000000,ai.analyze(request,List.of("Máy lạnh")).filters().maxPrice().intValue());
            assertFalse(input.get().contains("latitude")); assertFalse(input.get().contains("longitude"));
            assertFalse(input.get().contains("test-service-token"));
            for(String invalid : List.of("{\"action\":\"SEARCH\",\"clarification\":\"NONE\",\"filters\":{\"maxPrice\":-1}}", "{\"action\":\"DELETE\",\"clarification\":\"NONE\",\"filters\":{}}", "{\"action\":\"SEARCH\",\"clarification\":\"NONE\",\"filters\":{},\"sql\":\"select * from users\"}","null")) {
                output.set(invalid);
                assertThrows(ResponseStatusException.class,()->ai.analyze(request,List.of()));
            }
            status.set(503); output.set("{\"detail\":{\"code\":\"LOCAL_MODEL_NOT_READY\"}}");
            var unavailable = assertThrows(ResponseStatusException.class,()->ai.analyze(request,List.of()));
            assertEquals(503,unavailable.getStatusCode().value());
            assertTrue(unavailable.getReason().contains("train.py"));
            status.set(429);
            assertEquals(429,assertThrows(ResponseStatusException.class,()->ai.analyze(request,List.of())).getStatusCode().value());

        } finally { server.stop(0); }
    }

    @Test void missingServiceTokenDoesNotAttemptNetworkAccess() {
        try(var validation=Validation.buildDefaultValidatorFactory()) {
            var ai = new ChatbotAiClient("http://127.0.0.1:1","",validation.getValidator(),new ObjectMapper());
            assertEquals(503,assertThrows(ResponseStatusException.class,()->ai.analyze(new ChatRequest("Tìm",null,null,null,null),List.of())).getStatusCode().value());
        }
    }
}
