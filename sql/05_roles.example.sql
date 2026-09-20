-- Optional administration example. Run as a PostgreSQL administrator in psql.
-- The \password command hides cleartext passwords from command history and server logs.

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'fitzone_readonly') THEN
        CREATE ROLE fitzone_readonly LOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'fitzone_manager') THEN
        CREATE ROLE fitzone_manager LOGIN;
    END IF;
END
$$;

\if :{?skip_passwords}
    \echo 'Skipping interactive passwords for isolated automated validation.'
\else
    \password fitzone_readonly
    \password fitzone_manager
\endif

-- Allow only explicitly approved roles to connect and use the project schema.
REVOKE CONNECT ON DATABASE fitzone_db FROM PUBLIC;
GRANT CONNECT ON DATABASE fitzone_db TO fitzone_readonly, fitzone_manager;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO fitzone_readonly, fitzone_manager;

-- Remove old grants so rerunning this file produces the same secure result.
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public
FROM fitzone_readonly, fitzone_manager;

REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public
FROM fitzone_readonly, fitzone_manager;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE ALL PRIVILEGES ON TABLES
    FROM fitzone_readonly, fitzone_manager;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE ALL PRIVILEGES ON SEQUENCES
    FROM fitzone_readonly, fitzone_manager;

-- Read-only business data. Audit records remain hidden from the read-only role.
GRANT SELECT ON
    members,
    trainers,
    categories,
    classes,
    sessions,
    bookings
TO fitzone_readonly, fitzone_manager;

-- Manager maintenance permissions.
GRANT INSERT, UPDATE ON
    trainers,
    categories,
    classes,
    sessions
TO fitzone_manager;

GRANT INSERT (
    member_name,
    gender,
    birth_date,
    email,
    phone,
    join_date,
    status,
    country,
    city,
    street
) ON members TO fitzone_manager;

GRANT UPDATE (
    member_name,
    gender,
    birth_date,
    email,
    phone,
    country,
    city,
    street
) ON members TO fitzone_manager;

GRANT UPDATE (
    attendance_status,
    payment_status,
    payment_amount,
    rating,
    comment_on_session
) ON bookings TO fitzone_manager;

GRANT SELECT ON audit_logs TO fitzone_manager;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO fitzone_manager;

-- Bookings and status changes must use the validated procedures.
GRANT EXECUTE ON PROCEDURE public.add_new_booking(INTEGER, INTEGER)
TO fitzone_manager;

GRANT EXECUTE ON PROCEDURE public.update_member_status(INTEGER, VARCHAR)
TO fitzone_manager;
