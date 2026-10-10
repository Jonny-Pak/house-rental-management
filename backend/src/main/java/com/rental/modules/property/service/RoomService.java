package com.rental.modules.property.service;

import com.rental.modules.property.domain.entity.Property;
import com.rental.modules.property.domain.entity.Room;
import com.rental.modules.property.dto.request.RoomRequest;
import com.rental.modules.property.dto.response.RoomResponse;
import com.rental.modules.property.repository.PropertyRepository;
import com.rental.modules.property.repository.RoomRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.repository.UserRepository;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class RoomService {

    private final RoomRepository roomRepository;
    private final PropertyRepository propertyRepository;
    private final UserRepository userRepository;

    public RoomService(RoomRepository roomRepository, PropertyRepository propertyRepository, UserRepository userRepository) {
        this.roomRepository = roomRepository;
        this.propertyRepository = propertyRepository;
        this.userRepository = userRepository;
    }


    @Transactional
    public RoomResponse addRoom(String email, Long propertyId, RoomRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("KhÃ´ng tÃ¬m tháº¥y ngÆ°á»i dÃ¹ng vá»›i email: " + email));

        Property property = propertyRepository.findById(propertyId)
                .orElseThrow(() -> new RuntimeException("KhÃ´ng tÃ¬m tháº¥y khu trá» vá»›i ID: " + propertyId));

        if (!property.getLandlord().getUserId().equals(user.getUserId())) {
            throw new AccessDeniedException("Báº¡n khÃ´ng cÃ³ quyá»n thÃªm phÃ²ng vÃ o khu trá» nÃ y");
        }

        Room room = new Room();
        room.setProperty(property);
        room.setName(request.getName());
        room.setArea(request.getArea());
        room.setPrice(request.getPrice());
        room.setMaxCapacity(request.getMaxCapacity());

        Room savedRoom = roomRepository.save(room);
        return mapToResponse(savedRoom);
    }

    @Transactional(readOnly = true)
    public List<RoomResponse> getRoomsByProperty(Long propertyId) {
        // verify property exists first
        if (!propertyRepository.existsById(propertyId)) {
            throw new RuntimeException("KhÃ´ng tÃ¬m tháº¥y khu trá» vá»›i ID: " + propertyId);
        }

        return roomRepository.findByPropertyId(propertyId).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    private RoomResponse mapToResponse(Room room) {
        RoomResponse response = new RoomResponse();
        response.setId(room.getId());
        response.setPropertyId(room.getProperty().getId());
        response.setName(room.getName());
        response.setArea(room.getArea());
        response.setPrice(room.getPrice());
        response.setMaxCapacity(room.getMaxCapacity());
        response.setStatus(room.getStatus());
        return response;
    }
}
