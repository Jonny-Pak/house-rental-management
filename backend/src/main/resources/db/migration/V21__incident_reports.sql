CREATE TABLE incident_reports (
    id BIGSERIAL PRIMARY KEY,
    reporter_id BIGINT NOT NULL REFERENCES users(user_id),
    request_key VARCHAR(80) NOT NULL,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(20) NOT NULL CHECK (category IN ('ACCOUNT','LISTING','CONTRACT','PAYMENT','TECHNICAL','OTHER')),
    description VARCHAR(5000) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','IN_PROGRESS','RESOLVED','REJECTED')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version BIGINT NOT NULL DEFAULT 0,
    UNIQUE (reporter_id, request_key)
);
CREATE TABLE incident_updates (
    id BIGSERIAL PRIMARY KEY,
    incident_id BIGINT NOT NULL REFERENCES incident_reports(id),
    actor_id BIGINT NOT NULL REFERENCES users(user_id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('OPEN','IN_PROGRESS','RESOLVED','REJECTED')),
    message VARCHAR(2000) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_incidents_reporter_created ON incident_reports(reporter_id, created_at DESC);
CREATE INDEX idx_incidents_status_updated ON incident_reports(status, updated_at DESC, id DESC);
CREATE INDEX idx_incident_updates_report ON incident_updates(incident_id, created_at, id);
ALTER TABLE notifications ADD COLUMN incident_id BIGINT REFERENCES incident_reports(id);
