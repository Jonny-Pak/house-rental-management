CREATE TABLE user_preference_interests (
    preference_id BIGINT NOT NULL REFERENCES user_preferences(preference_id) ON DELETE CASCADE,
    interest_code VARCHAR(32) NOT NULL,
    PRIMARY KEY (preference_id, interest_code),
    CONSTRAINT valid_personal_interest CHECK (interest_code IN (
        'CAT_LOVER', 'DOG_LOVER', 'PLANTS', 'QUIET', 'TIDY', 'STUDY', 'EARLY_BIRD', 'NIGHT_OWL', 'NON_SMOKER', 'SOCIABLE', 'MUSIC', 'MOVIES', 'READING', 'GAMING', 'COOKING', 'SPORTS', 'TRAVEL', 'COFFEE'
    ))
);
