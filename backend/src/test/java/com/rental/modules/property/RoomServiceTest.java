package com.rental.modules.property;
import com.rental.modules.property.domain.entity.Property;
import com.rental.modules.property.domain.entity.Room;
import com.rental.modules.property.repository.PropertyRepository;
import com.rental.modules.property.repository.RoomRepository;
import com.rental.modules.property.service.RoomService;
import com.rental.modules.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class RoomServiceTest {
    @Test void roomListKeepsOrderAndResponseFields() {
        var rooms = mock(RoomRepository.class);
        var properties = mock(PropertyRepository.class);
        var service = new RoomService(rooms, properties, mock(UserRepository.class));
        Property property = new Property(); property.setId(5L);
        Room first = new Room(); first.setId(1L); first.setProperty(property); first.setName("Phòng 1");
        first.setPrice(new BigDecimal("3000000")); first.setArea(25.0); first.setMaxCapacity(2);
        Room second = new Room(); second.setId(2L); second.setProperty(property); second.setName("Phòng 2");
        when(properties.existsById(5L)).thenReturn(true);
        when(rooms.findByPropertyId(5L)).thenReturn(List.of(first, second));
        var result = service.getRoomsByProperty(5L);
        assertEquals(2, result.size()); assertEquals(1L, result.get(0).getId());
        assertEquals(5L, result.get(0).getPropertyId()); assertEquals(25.0, result.get(0).getArea());
        assertEquals(first.getPrice(), result.get(0).getPrice()); assertEquals(2, result.get(0).getMaxCapacity());
        assertEquals("Phòng 2", result.get(1).getName());
    }
}
