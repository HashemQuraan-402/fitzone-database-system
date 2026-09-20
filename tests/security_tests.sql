\set ON_ERROR_STOP on

BEGIN;

DO $security_checks$
DECLARE
    protected_routine_count integer;
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname IN ('fitzone_readonly', 'fitzone_manager')
          AND (rolsuper OR rolcreaterole OR rolcreatedb OR rolreplication OR rolbypassrls)
    ) THEN
        RAISE EXCEPTION 'Application roles must not have administrative privileges.';
    END IF;

    IF has_table_privilege('fitzone_readonly', 'public.members', 'SELECT') IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'fitzone_readonly must be able to read members.';
    END IF;

    IF has_table_privilege('fitzone_readonly', 'public.audit_logs', 'SELECT') THEN
        RAISE EXCEPTION 'fitzone_readonly must not be able to read audit logs.';
    END IF;

    IF has_table_privilege('fitzone_readonly', 'public.members', 'UPDATE') THEN
        RAISE EXCEPTION 'fitzone_readonly must not be able to update members.';
    END IF;

    IF has_table_privilege('fitzone_manager', 'public.audit_logs', 'SELECT') IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'fitzone_manager must be able to read audit logs.';
    END IF;

    IF has_table_privilege('fitzone_manager', 'public.bookings', 'INSERT') THEN
        RAISE EXCEPTION 'fitzone_manager must not insert bookings directly.';
    END IF;

    IF has_table_privilege('fitzone_manager', 'public.audit_logs', 'UPDATE') THEN
        RAISE EXCEPTION 'fitzone_manager must not modify audit logs.';
    END IF;

    IF has_function_privilege(
        'fitzone_manager',
        'public.add_new_booking(integer,integer)',
        'EXECUTE'
    ) IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'fitzone_manager must be able to execute add_new_booking.';
    END IF;

    IF has_function_privilege(
        'fitzone_manager',
        'public.update_member_status(integer,character varying)',
        'EXECUTE'
    ) IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'fitzone_manager must be able to execute update_member_status.';
    END IF;

    SELECT count(*)
    INTO protected_routine_count
    FROM pg_proc AS procedure_definition
    JOIN pg_namespace AS schema_definition
      ON schema_definition.oid = procedure_definition.pronamespace
    WHERE schema_definition.nspname = 'public'
      AND procedure_definition.proname IN (
          'add_new_booking',
          'update_member_status',
          'sync_member_loyalty',
          'write_audit_log'
      )
      AND procedure_definition.prosecdef
      AND 'search_path=pg_catalog, public' = ANY (procedure_definition.proconfig);

    IF protected_routine_count <> 4 THEN
        RAISE EXCEPTION 'Protected routines must use SECURITY DEFINER and a fixed search_path.';
    END IF;

    RAISE NOTICE 'PASS: catalog security checks passed';
END
$security_checks$;

SET LOCAL ROLE fitzone_readonly;
SELECT count(*) AS readonly_visible_members FROM public.members;

DO $readonly_checks$
BEGIN
    BEGIN
        PERFORM 1 FROM public.audit_logs LIMIT 1;
        RAISE EXCEPTION 'fitzone_readonly unexpectedly read audit logs.';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS: read-only role cannot read audit logs';
    END;

    BEGIN
        UPDATE public.members SET status = status WHERE false;
        RAISE EXCEPTION 'fitzone_readonly unexpectedly updated members.';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS: read-only role cannot update members';
    END;
END
$readonly_checks$;

RESET ROLE;
SET LOCAL ROLE fitzone_manager;
SELECT count(*) AS manager_visible_audit_rows FROM public.audit_logs;

DO $manager_checks$
BEGIN
    BEGIN
        INSERT INTO public.bookings DEFAULT VALUES;
        RAISE EXCEPTION 'fitzone_manager unexpectedly inserted a booking directly.';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS: manager cannot insert bookings directly';
    END;

    BEGIN
        UPDATE public.audit_logs SET changed_by = changed_by WHERE false;
        RAISE EXCEPTION 'fitzone_manager unexpectedly modified audit logs.';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS: manager cannot modify audit logs';
    END;
END
$manager_checks$;

RESET ROLE;
ROLLBACK;
