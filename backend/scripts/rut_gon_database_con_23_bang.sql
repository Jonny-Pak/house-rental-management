BEGIN;
SET LOCAL lock_timeout = '5s';

DO $$
DECLARE
    ten_bang TEXT;
    co_du_lieu BOOLEAN;
    luoc_do TEXT := current_schema();
    cac_bang TEXT[] := ARRAY[
        'noi_that_cua_tin_dang', 'danh_muc_noi_that',
        'noi_dung_he_thong_cu', 'phien_dang_nhap_qr_cu',
        'theo_doi_tin_dang', 'tin_nhan_lien_he'
    ];
BEGIN
    IF to_regclass(format('%I.nguoi_dung', luoc_do)) IS NULL
        OR to_regclass(format('%I.tin_cho_thue', luoc_do)) IS NULL THEN
        RAISE EXCEPTION 'Can database ten tieng Viet truoc khi rut gon.';
    END IF;

    FOREACH ten_bang IN ARRAY cac_bang LOOP
        IF to_regclass(format('%I.%I', luoc_do, ten_bang)) IS NOT NULL THEN
            EXECUTE format('LOCK TABLE %I.%I IN ACCESS EXCLUSIVE MODE', luoc_do, ten_bang);
            EXECUTE format('SELECT EXISTS (SELECT 1 FROM %I.%I)', luoc_do, ten_bang) INTO co_du_lieu;
            IF co_du_lieu THEN
                RAISE EXCEPTION 'Bang % co du lieu. Dung de lap phuong an chuyen du lieu.', ten_bang;
            END IF;
        END IF;
    END LOOP;

    FOREACH ten_bang IN ARRAY cac_bang LOOP
        EXECUTE format('DROP TABLE IF EXISTS %I.%I RESTRICT', luoc_do, ten_bang);
    END LOOP;
END $$;

COMMIT;
