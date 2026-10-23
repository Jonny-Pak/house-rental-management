ALTER TABLE listings
    ADD COLUMN current_occupants INTEGER,
    ADD COLUMN max_occupants INTEGER,
    ADD COLUMN gender_preference VARCHAR(20),
    ADD COLUMN allow_pets BOOLEAN,
    ADD COLUMN allow_smoking BOOLEAN,
    ADD COLUMN roommate_requirements VARCHAR(500);

UPDATE listings SET current_occupants = 1, max_occupants = 2,
    gender_preference = 'ANY', allow_pets = FALSE, allow_smoking = FALSE
WHERE listing_type = 'SHARED_ROOM';

ALTER TABLE listings ADD CONSTRAINT valid_shared_room_details CHECK (
    listing_type <> 'SHARED_ROOM' OR (
        current_occupants IS NOT NULL AND max_occupants IS NOT NULL
        AND current_occupants >= 0 AND max_occupants <= 20
        AND max_occupants > current_occupants
        AND gender_preference IS NOT NULL AND gender_preference IN ('ANY', 'MALE', 'FEMALE')
    )
);
