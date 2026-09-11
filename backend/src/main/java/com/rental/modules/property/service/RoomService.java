package com.rental.modules.property.service;

import com.rental.modules.property.domain.entity.Property;
import com.rental.modules.property.domain.entity.Room;
import com.rental.modules.property.dto.request.RoomRequest;
import com.rental.modules.property.dto.response.RoomResponse;
import com.rental.modules.property.repository.PropertyRepository;
import com.rental.modules.property.repository.RoomRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RoomService {

    private final RoomRepository roomRepository;
    private final PropertyRepository propertyRepository;
    private final UserRepository userRepository;

    @Transactional
    public RoomResponse addRoom(String email, Long propertyId, RoomRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng với email: " + email));

        Property property = propertyRepository.findById(propertyId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy khu trọ với ID: " + propertyId));

        if (!property.getLandlord().getUserId().equals(user.getUserId())) {
            throw new AccessDeniedException("Bạn không có quyền thêm phòng vào khu trọ này");
        }

        Room room = Room.builder()
                .property(property)
                .name(request.getName())
                .area(request.getArea())
                .price(request.getPrice())
                .maxCapacity(request.getMaxCapacity())
                .build();

        Room savedRoom = roomRepository.save(room);
        return mapToResponse(savedRoom);
    }

    @Transactional(readOnly = true)
    public List<RoomResponse> getRoomsByProperty(Long propertyId) {
        // verify property exists first
        if (!propertyRepository.existsById(propertyId)) {
            throw new RuntimeException("Không tìm thấy khu trọ với ID: " + propertyId);
        }

        return roomRepository.findByPropertyId(propertyId).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    private RoomResponse mapToResponse(Room room) {
        return RoomResponse.builder()
                .id(room.getId())
                .propertyId(room.getProperty().getId())
                .name(room.getName())
                .area(room.getArea())
                .price(room.getPrice())
                .maxCapacity(room.getMaxCapacity())
                .status(room.getStatus())
                .build();
    }
}
