-- One-time recovery for the local database's missing legacy migration source.
-- Run only after taking a database backup. No application rows are modified.
BEGIN;
DO $$
DECLARE
    column_signature text;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.flyway_schema_history
        WHERE version = '7' AND script = 'V7__create_user_favorites.sql'
          AND checksum = -1427746094 AND success = true
    ) THEN
        RAISE EXCEPTION 'Expected legacy V7 history not found; recovery aborted';
    END IF;

    SELECT string_agg(column_name || ':' || data_type || ':' || is_nullable, ',' ORDER BY ordinal_position)
    INTO column_signature
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'user_favorites';

    IF column_signature IS DISTINCT FROM 'id:bigint:NO,user_id:bigint:NO,listing_id:bigint:NO,created_at:timestamp without time zone:YES' THEN
        RAISE EXCEPTION 'Legacy user_favorites columns differ; recovery aborted';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_favorites'::regclass
                   AND contype = 'u' AND pg_get_constraintdef(oid) = 'UNIQUE (user_id, listing_id)')
       OR NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_favorites'::regclass
                      AND contype = 'f' AND pg_get_constraintdef(oid) = 'FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE')
       OR NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_favorites'::regclass
                      AND contype = 'f' AND pg_get_constraintdef(oid) = 'FOREIGN KEY (listing_id) REFERENCES listings(listing_id) ON DELETE CASCADE') THEN
        RAISE EXCEPTION 'Legacy user_favorites constraints differ; recovery aborted';
    END IF;

    UPDATE public.flyway_schema_history SET checksum = -602544506
    WHERE version = '7' AND script = 'V7__create_user_favorites.sql'
      AND checksum = -1427746094 AND success = true;
END $$;
COMMIT;
