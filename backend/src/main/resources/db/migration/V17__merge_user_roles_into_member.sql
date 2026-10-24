ALTER TABLE users DROP CONSTRAINT users_role_check;

UPDATE users SET role = 'MEMBER' WHERE role IN ('USER', 'OWNER');

ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('MEMBER', 'ADMIN'));
