-- The demo's users. The identity service fills this table from its configuration on start, hashing each password.
USE identity;
CREATE TABLE IF NOT EXISTS users (
    username      VARCHAR(255) PRIMARY KEY,
    password_hash VARCHAR(255) NOT NULL,
    name          VARCHAR(255) NOT NULL,
    title         VARCHAR(255) NOT NULL,
    roles         VARCHAR(255) NOT NULL
);
