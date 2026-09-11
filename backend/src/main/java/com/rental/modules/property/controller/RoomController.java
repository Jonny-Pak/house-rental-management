package com.rental.modules.property.controller;

import com.rental.modules.property.dto.request.RoomRequest;
import com.rental.modules.property.dto.response.RoomResponse;
import com.rental.modules.property.service.RoomService;
import com.rental.modules.user.dto.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/v1/properties/{propertyId}/rooms")
@RequiredArgsConstructor
public class RoomController {

    private final RoomService roomService;

    @PostMapping
    public ResponseEntity<ApiResponse<RoomResponse>> addRoom(
            Principal principal,
            @PathVariable Long propertyId,
            @Valid @RequestBody RoomRequest request) {
        
        RoomResponse response = roomService.addRoom(principal.getName(), propertyId, request);
        return ResponseEntity.ok(ApiResponse.success("Thêm phòng thành công", response));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<RoomResponse>>> getRoomsByProperty(@PathVariable Long propertyId) {
        List<RoomResponse> rooms = roomService.getRoomsByProperty(propertyId);
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách phòng thành công", rooms));
    }
}
