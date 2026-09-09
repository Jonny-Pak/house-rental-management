package com.rental.modules.property.repository;

import com.rental.modules.property.domain.entity.Property;
import com.rental.modules.user.domain.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PropertyRepository extends JpaRepository<Property, Long> {
    List<Property> findByLandlord(User landlord);
}
