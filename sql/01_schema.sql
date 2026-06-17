-- ============================================================
-- 01_schema.sql
-- Project: Immunization Compliance Analytics Dashboard
-- Author: Aly Drame, MD, MPH, MBA
-- Note: All data are synthetic — generated for portfolio use only
-- ============================================================

CREATE TABLE IF NOT EXISTS providers (
    provider_id         TEXT    PRIMARY KEY,
    vfc_pin             TEXT    NOT NULL,
    provider_type       TEXT    NOT NULL,
    jurisdiction_id     TEXT    NOT NULL,
    urban_rural         TEXT    NOT NULL,
    practice_size       TEXT    NOT NULL,
    enrollment_year     INTEGER NOT NULL,
    months_enrolled     INTEGER NOT NULL,
    active_flag         TEXT    NOT NULL DEFAULT 'Y',
    unenrolled_flag     TEXT    NOT NULL DEFAULT 'N',
    CHECK (active_flag      IN ('Y','N')),
    CHECK (unenrolled_flag  IN ('Y','N')),
    CHECK (months_enrolled  BETWEEN 1 AND 72),
    CHECK (enrollment_year  BETWEEN 2018 AND 2024)
);

CREATE TABLE IF NOT EXISTS visits (
    visit_id                    TEXT    PRIMARY KEY,
    provider_id                 TEXT    NOT NULL,
    visit_date                  TEXT    NOT NULL,
    visit_year                  INTEGER NOT NULL,
    visit_quarter               INTEGER NOT NULL,
    compliant_flag              TEXT,
    domain_storage              TEXT,
    domain_temperature          TEXT,
    domain_documentation        TEXT,
    domain_inventory            TEXT,
    domain_patient_eligibility  TEXT,
    corrective_action_issued    TEXT,
    corrective_action_type      TEXT,
    helpdesk_tickets            INTEGER NOT NULL DEFAULT 0,
    visit_type                  TEXT    NOT NULL,
    staff_conducting            TEXT    NOT NULL,
    FOREIGN KEY (provider_id) REFERENCES providers(provider_id),
    CHECK (compliant_flag            IN ('Y','N') OR compliant_flag IS NULL),
    CHECK (domain_storage            IN ('Y','N') OR domain_storage IS NULL),
    CHECK (domain_temperature        IN ('Y','N') OR domain_temperature IS NULL),
    CHECK (domain_documentation      IN ('Y','N') OR domain_documentation IS NULL),
    CHECK (domain_inventory          IN ('Y','N') OR domain_inventory IS NULL),
    CHECK (domain_patient_eligibility IN ('Y','N')
           OR domain_patient_eligibility IS NULL),
    CHECK (corrective_action_issued  IN ('Y','N')
           OR corrective_action_issued IS NULL),
    CHECK (helpdesk_tickets >= 0),
    CHECK (visit_quarter BETWEEN 1 AND 4)
);

CREATE TABLE IF NOT EXISTS unenrollments (
    unenrollment_id         TEXT    PRIMARY KEY,
    provider_id             TEXT    NOT NULL,
    unenrollment_date       TEXT    NOT NULL,
    months_to_unenrollment  INTEGER NOT NULL,
    unenrollment_reason     TEXT,
    initiated_by            TEXT    NOT NULL,
    FOREIGN KEY (provider_id) REFERENCES providers(provider_id),
    CHECK (months_to_unenrollment > 0)
);
