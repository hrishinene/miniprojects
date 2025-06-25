-- add a default root user
INSERT INTO users (username, password_hash, email, is_active, created_at, updated_at)
VALUES ('root', '$2b$10$IH2C10KXI/7Yd.IM5nDi3uavc0V7O/K14b5Bne35WbMqHL8bpTvDu', 'root@creditOS',true, NOW(), NOW());