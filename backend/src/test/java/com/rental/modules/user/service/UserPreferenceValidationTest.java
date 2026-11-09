package com.rental.modules.user.service;

import com.rental.modules.user.dto.request.UserPreferenceDto;
import jakarta.validation.Validation;
import org.junit.jupiter.api.Test;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

class UserPreferenceValidationTest {
    @Test void interestsAcceptKnownCodesAndAllowClearing() {
        try (var factory = Validation.buildDefaultValidatorFactory()) {
            var validator = factory.getValidator();
            var request = new UserPreferenceDto();
            request.setInterests(List.of("CAT_LOVER", "QUIET", "MUSIC", "MOVIES", "TIDY"));
            assertTrue(validator.validate(request).isEmpty());
            request.setInterests(List.of());
            assertTrue(validator.validate(request).isEmpty());
            request.setInterests(List.of("UNKNOWN"));
            assertFalse(validator.validate(request).isEmpty());
            request.setInterests(List.of("CAT_LOVER", "QUIET", "MUSIC", "MOVIES", "TIDY", "STUDY"));
            assertFalse(validator.validate(request).isEmpty());
        }
    }
}
