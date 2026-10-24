UPDATE membership_packages
SET package_name = 'Gói PLUS'
WHERE LOWER(TRIM(package_name)) IN ('gói tiêu chuẩn', 'tiêu chuẩn');

UPDATE membership_packages
SET package_name = 'Gói PRO'
WHERE LOWER(TRIM(package_name)) IN ('gói vip', 'vip');
