-- PL/pgSQL functions, procedures, and triggers.
BEGIN;

DROP FUNCTION IF EXISTS get_member_full_name(INTEGER);

CREATE OR REPLACE FUNCTION get_member_full_name(p_member_id INTEGER)
RETURNS TEXT
LANGUAGE sql
STABLE
SET search_path = pg_catalog, public
AS $$
    SELECT member_name FROM members WHERE member_id = p_member_id;
$$;

CREATE OR REPLACE FUNCTION get_member_by_email(p_email TEXT)
RETURNS SETOF members
LANGUAGE sql
STABLE
SET search_path = pg_catalog, public
AS $$
    SELECT * FROM members WHERE LOWER(email) = LOWER(p_email);
$$;

CREATE OR REPLACE FUNCTION get_average_rating_by_trainer(p_trainer_id INTEGER)
RETURNS NUMERIC
LANGUAGE sql
STABLE
SET search_path = pg_catalog, public
AS $$
    SELECT ROUND(AVG(b.rating), 2)
    FROM bookings b
    JOIN sessions s ON s.session_id = b.session_id
    WHERE s.trainer_id = p_trainer_id AND b.rating IS NOT NULL;
$$;

CREATE OR REPLACE FUNCTION calculate_loyalty_points(p_member_id INTEGER)
RETURNS INTEGER
LANGUAGE sql
STABLE
SET search_path = pg_catalog, public
AS $$
    SELECT (COUNT(*) FILTER (WHERE rating = 5) * 10)::INTEGER
    FROM bookings
    WHERE member_id = p_member_id;
$$;

CREATE OR REPLACE FUNCTION get_available_seats(p_session_id INTEGER)
RETURNS INTEGER
LANGUAGE sql
STABLE
SET search_path = pg_catalog, public
AS $$
    SELECT (c.max_capacity
           - COUNT(b.booking_id) FILTER (WHERE b.attendance_status <> 'cancelled'))::INTEGER
    FROM sessions s
    JOIN classes c ON c.class_id = s.class_id
    LEFT JOIN bookings b ON b.session_id = s.session_id
    WHERE s.session_id = p_session_id
    GROUP BY c.max_capacity;
$$;

CREATE OR REPLACE PROCEDURE add_new_booking(
    p_member_id INTEGER,
    p_session_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_status sessions.status%TYPE;
    v_seats INTEGER;
BEGIN
    SELECT status INTO STRICT v_status
    FROM sessions
    WHERE session_id = p_session_id
    FOR UPDATE;

    IF v_status <> 'scheduled' THEN
        RAISE EXCEPTION 'Only scheduled sessions can be booked';
    END IF;

    v_seats := get_available_seats(p_session_id);
    IF v_seats IS NULL OR v_seats <= 0 THEN
        RAISE EXCEPTION 'The session has no available seats';
    END IF;

    INSERT INTO bookings (member_id, session_id)
    VALUES (p_member_id, p_session_id);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE EXCEPTION 'Session % does not exist', p_session_id;
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Member % does not exist', p_member_id;
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Member % already booked session %', p_member_id, p_session_id;
END;
$$;

CREATE OR REPLACE PROCEDURE update_member_status(
    p_member_id INTEGER,
    p_new_status VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF p_new_status NOT IN ('active', 'inactive') THEN
        RAISE EXCEPTION 'Status must be active or inactive';
    END IF;

    UPDATE members SET status = p_new_status WHERE member_id = p_member_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Member % does not exist', p_member_id;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION validate_booking_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF NEW.rating IS NOT NULL AND NEW.attendance_status <> 'attended' THEN
        RAISE EXCEPTION 'A rating is allowed only after attendance';
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION prevent_rating_rewrite()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF OLD.rating IS NOT NULL AND NEW.rating IS DISTINCT FROM OLD.rating THEN
        RAISE EXCEPTION 'A submitted rating cannot be changed';
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION sync_member_loyalty()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_member_id INTEGER := COALESCE(NEW.member_id, OLD.member_id);
BEGIN
    UPDATE members
    SET loyalty_points = calculate_loyalty_points(v_member_id)
    WHERE member_id = v_member_id;
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION write_audit_log()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_record JSONB := COALESCE(TO_JSONB(NEW), TO_JSONB(OLD));
BEGIN
    INSERT INTO audit_logs (table_name, operation, record_id, changed_by, old_values, new_values)
    VALUES (
        TG_TABLE_NAME,
        TG_OP,
        COALESCE(v_record ->> 'member_id', v_record ->> 'booking_id'),
        SESSION_USER,
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN TO_JSONB(OLD) END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN TO_JSONB(NEW) END
    );
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_booking_rating ON bookings;
CREATE TRIGGER trg_validate_booking_rating
BEFORE INSERT OR UPDATE OF rating, attendance_status ON bookings
FOR EACH ROW EXECUTE FUNCTION validate_booking_rating();

DROP TRIGGER IF EXISTS trg_prevent_rating_rewrite ON bookings;
CREATE TRIGGER trg_prevent_rating_rewrite
BEFORE UPDATE OF rating ON bookings
FOR EACH ROW EXECUTE FUNCTION prevent_rating_rewrite();

DROP TRIGGER IF EXISTS trg_sync_member_loyalty ON bookings;
CREATE TRIGGER trg_sync_member_loyalty
AFTER INSERT OR UPDATE OF rating OR DELETE ON bookings
FOR EACH ROW EXECUTE FUNCTION sync_member_loyalty();

DROP TRIGGER IF EXISTS trg_audit_members ON members;
CREATE TRIGGER trg_audit_members
AFTER INSERT OR UPDATE OR DELETE ON members
FOR EACH ROW EXECUTE FUNCTION write_audit_log();

DROP TRIGGER IF EXISTS trg_audit_bookings ON bookings;
CREATE TRIGGER trg_audit_bookings
AFTER INSERT OR UPDATE OR DELETE ON bookings
FOR EACH ROW EXECUTE FUNCTION write_audit_log();

-- Synchronize points for the sample data loaded before these triggers existed.
UPDATE members
SET loyalty_points = calculate_loyalty_points(member_id);


-- Sensitive write routines are available only to explicitly granted roles.
REVOKE EXECUTE ON PROCEDURE public.add_new_booking(INTEGER, INTEGER) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE public.update_member_status(INTEGER, VARCHAR) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.sync_member_loyalty() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.write_audit_log() FROM PUBLIC;

COMMIT;
