-- 1. Thêm Thành phố Hồ Chí Minh (id = 1)
INSERT INTO administrative_areas (area_id, area_name, area_type, code) VALUES (1, 'Thành phố Hồ Chí Minh', 'PROVINCE', 'SG');

-- 2. Thêm Quận/Huyện tiêu biểu thuộc TP.HCM (parent_id = 1)
INSERT INTO administrative_areas (area_id, area_name, area_type, code, parent_id) VALUES 
(2, 'Quận 1', 'DISTRICT', 'Q1', 1),
(3, 'Quận 7', 'DISTRICT', 'Q7', 1),
(4, 'Thành phố Thủ Đức', 'DISTRICT', 'TD', 1),
(5, 'Quận Bình Thạnh', 'DISTRICT', 'BT', 1);

-- 3. Thêm Phường/Xã thuộc Quận 1 (parent_id = 2)
INSERT INTO administrative_areas (area_id, area_name, area_type, code, parent_id) VALUES 
(6, 'Phường Bến Nghé', 'WARD', 'BN', 2),
(7, 'Phường Bến Thành', 'WARD', 'BTH', 2),
(8, 'Phường Đa Kao', 'WARD', 'DK', 2);

SELECT setval('administrative_areas_area_id_seq', 8);
