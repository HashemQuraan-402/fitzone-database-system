-- FitZone Gym Management System
-- Run this file first. It recreates the public project tables.

BEGIN;

DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS trainers CASCADE;
DROP TABLE IF EXISTS members CASCADE;

CREATE TABLE members (
    member_id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    member_name        VARCHAR(100) NOT NULL,
    gender             VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    birth_date         DATE,
    email              VARCHAR(150) NOT NULL UNIQUE,
    phone              VARCHAR(20),
    join_date          DATE NOT NULL DEFAULT CURRENT_DATE,
    status             VARCHAR(10) NOT NULL DEFAULT 'active'
                       CHECK (status IN ('active', 'inactive')),
    country            VARCHAR(50),
    city               VARCHAR(50),
    street             VARCHAR(100),
    loyalty_points     INTEGER NOT NULL DEFAULT 0 CHECK (loyalty_points >= 0),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE trainers (
    trainer_id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trainer_name       VARCHAR(100) NOT NULL,
    gender             VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    email              VARCHAR(150) NOT NULL UNIQUE,
    phone              VARCHAR(20),
    hire_date          DATE NOT NULL,
    specialization     VARCHAR(100),
    salary             NUMERIC(10, 2) CHECK (salary >= 0),
    experience_years   INTEGER NOT NULL DEFAULT 0 CHECK (experience_years >= 0),
    is_active          BOOLEAN NOT NULL DEFAULT TRUE,
    mentor_id          INTEGER REFERENCES trainers(trainer_id) ON DELETE SET NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (mentor_id IS NULL OR mentor_id <> trainer_id)
);

CREATE TABLE categories (
    category_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name      VARCHAR(100) NOT NULL UNIQUE,
    description        TEXT,
    is_active          BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE classes (
    class_id           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    class_name         VARCHAR(100) NOT NULL,
    description        TEXT,
    duration_minutes   INTEGER NOT NULL CHECK (duration_minutes > 0),
    max_capacity       INTEGER NOT NULL CHECK (max_capacity > 0),
    equipment_required BOOLEAN NOT NULL DEFAULT FALSE,
    class_level        VARCHAR(20) NOT NULL
                       CHECK (class_level IN ('beginner', 'intermediate', 'advanced')),
    price              NUMERIC(8, 2) NOT NULL DEFAULT 0 CHECK (price >= 0),
    category_id        INTEGER NOT NULL REFERENCES categories(category_id) ON DELETE RESTRICT,
    UNIQUE (class_name, category_id)
);

CREATE TABLE sessions (
    session_id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    starts_at          TIMESTAMPTZ NOT NULL,
    ends_at            TIMESTAMPTZ NOT NULL,
    room               VARCHAR(30) NOT NULL,
    status             VARCHAR(20) NOT NULL DEFAULT 'scheduled'
                       CHECK (status IN ('scheduled', 'completed', 'cancelled')),
    notes              TEXT,
    class_id           INTEGER NOT NULL REFERENCES classes(class_id) ON DELETE CASCADE,
    trainer_id         INTEGER REFERENCES trainers(trainer_id) ON DELETE SET NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (ends_at > starts_at),
    UNIQUE (room, starts_at)
);

CREATE TABLE bookings (
    booking_id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booked_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    attendance_status  VARCHAR(20) NOT NULL DEFAULT 'booked'
                       CHECK (attendance_status IN ('booked', 'attended', 'cancelled', 'no show')),
    payment_status     VARCHAR(20) NOT NULL DEFAULT 'pending'
                       CHECK (payment_status IN ('pending', 'paid', 'refunded')),
    payment_amount     NUMERIC(8, 2) CHECK (payment_amount >= 0),
    rating             INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment_on_session TEXT,
    member_id          INTEGER NOT NULL REFERENCES members(member_id) ON DELETE CASCADE,
    session_id         INTEGER NOT NULL REFERENCES sessions(session_id) ON DELETE CASCADE,
    UNIQUE (member_id, session_id)
);

CREATE TABLE audit_logs (
    audit_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name         TEXT NOT NULL,
    operation          TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id          TEXT,
    changed_by         TEXT NOT NULL DEFAULT CURRENT_USER,
    changed_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    old_values         JSONB,
    new_values         JSONB
);

CREATE INDEX idx_members_status ON members(status);
CREATE INDEX idx_sessions_class_start ON sessions(class_id, starts_at);
CREATE INDEX idx_sessions_trainer_start ON sessions(trainer_id, starts_at);
CREATE INDEX idx_bookings_session_status ON bookings(session_id, attendance_status);
CREATE INDEX idx_bookings_member ON bookings(member_id);
CREATE INDEX idx_audit_logs_table_time ON audit_logs(table_name, changed_at DESC);

COMMIT;

