-- Manual smoke tests. Run after all four numbered setup scripts.
-- The transaction is rolled back, so this file leaves the sample data unchanged.

BEGIN;

DO $$
DECLARE
    v_name TEXT;
    v_seats_before INTEGER;
    v_seats_after INTEGER;
BEGIN
    v_name := get_member_full_name(1);
    IF v_name IS NULL THEN
        RAISE EXCEPTION 'get_member_full_name failed';
    END IF;

    v_seats_before := get_available_seats(4);
    CALL add_new_booking(3, 4);
    v_seats_after := get_available_seats(4);

    IF v_seats_after <> v_seats_before - 1 THEN
        RAISE EXCEPTION 'add_new_booking did not reduce available seats';
    END IF;

    CALL update_member_status(3, 'active');
    IF (SELECT status FROM members WHERE member_id = 3) <> 'active' THEN
        RAISE EXCEPTION 'update_member_status failed';
    END IF;
END
$$;

-- A rating on a non-attended booking must be rejected.
DO $$
BEGIN
    BEGIN
        UPDATE bookings SET rating = 5 WHERE booking_id = 1;
        RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'rating validation did not fire';
    EXCEPTION
        WHEN SQLSTATE 'P0001' THEN
            RAISE NOTICE 'PASS: invalid rating was rejected';
    END;
END
$$;

-- An existing rating must not be rewritten.
DO $$
BEGIN
    BEGIN
        UPDATE bookings SET rating = 1 WHERE booking_id = 3;
        RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'rating rewrite protection did not fire';
    EXCEPTION
        WHEN SQLSTATE 'P0001' THEN
            RAISE NOTICE 'PASS: rating rewrite was rejected';
    END;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM audit_logs WHERE table_name IN ('members', 'bookings')) THEN
        RAISE EXCEPTION 'audit trigger did not create a row';
    END IF;
END
$$;

ROLLBACK;

