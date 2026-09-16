package com.rental.modules.favorite.repository;

import com.rental.modules.favorite.domain.entity.FavoriteProperty;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FavoritePropertyRepository extends JpaRepository<FavoriteProperty, Long> {

    boolean existsByUser_UserIdAndProperty_Id(Long userId, Long propertyId);

    void deleteByUser_UserIdAndProperty_Id(Long userId, Long propertyId);

    List<FavoriteProperty> findByUser_UserId(Long userId);
}
