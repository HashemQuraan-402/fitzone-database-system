-- Optional administration example. Run as a PostgreSQL administrator in psql.
-- Passwords are prompted for at runtime and are never stored in this repository.

\prompt 'Password for fitzone_readonly: ' readonly_password
\prompt 'Password for fitzone_manager: ' manager_password

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

ALTER ROLE fitzone_readonly PASSWORD :'readonly_password';
ALTER ROLE fitzone_manager PASSWORD :'manager_password';

GRANT CONNECT ON DATABASE fitzone_db TO fitzone_readonly, fitzone_manager;
GRANT USAGE ON SCHEMA public TO fitzone_readonly, fitzone_manager;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO fitzone_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO fitzone_readonly;

GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO fitzone_manager;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO fitzone_manager;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE ON TABLES TO fitzone_manager;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO fitzone_manager;

-- Protect member identity data from manager updates while retaining read access.
REVOKE UPDATE ON members FROM fitzone_manager;

