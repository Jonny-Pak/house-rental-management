-- Repair legacy seed names whose Vietnamese characters were replaced during import.
-- Match seed identity and only update damaged text, preserving custom area names.
UPDATE administrative_areas AS area
SET area_name = seed.correct_name
FROM (VALUES
    (1::bigint, 'PROVINCE', 'SG', 'Thành phố Hồ Chí Minh'),
    (2::bigint, 'DISTRICT', 'Q1', 'Quận 1'),
    (3::bigint, 'DISTRICT', 'Q7', 'Quận 7'),
    (4::bigint, 'DISTRICT', 'TD', 'Thành phố Thủ Đức'),
    (5::bigint, 'DISTRICT', 'BT', 'Quận Bình Thạnh'),
    (6::bigint, 'WARD', 'BN', 'Phường Bến Nghé'),
    (7::bigint, 'WARD', 'BTH', 'Phường Bến Thành'),
    (8::bigint, 'WARD', 'DK', 'Phường Đa Kao')
) AS seed(area_id, area_type, code, correct_name)
WHERE area.area_id = seed.area_id
  AND area.area_type = seed.area_type
  AND area.code = seed.code
  AND (position('?' IN area.area_name) > 0
       OR position(U&'\FFFD' IN area.area_name) > 0);
