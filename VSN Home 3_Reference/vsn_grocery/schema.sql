-- ============================================================
-- VSN Home — Complete MySQL Schema
-- Run in phpMyAdmin or terminal:
--   mysql -u root -p < vsn_home_schema.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS vsn_grocery
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE vsn_grocery;

-- ─── 1. Users ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(255)  NOT NULL,
    email         VARCHAR(255)  UNIQUE NOT NULL,
    password      VARCHAR(255)  NOT NULL,                 -- bcrypt hashed
    phone         VARCHAR(20),
    address       TEXT,
    business_name VARCHAR(255)  DEFAULT 'N/A',
    gstin         VARCHAR(50)   DEFAULT 'N/A',
    upi_id        VARCHAR(255)  DEFAULT NULL,
    profile_image LONGTEXT      DEFAULT NULL,             -- Base64 or URL
    coins         INT           DEFAULT 0,
    referral_code VARCHAR(10)   UNIQUE,
    referred_by   VARCHAR(255)  DEFAULT NULL,
    created_at    DATETIME      DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── 2. Admins ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admins (
    email    VARCHAR(255) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,                       -- plain or hashed
    upi_id   VARCHAR(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Default admin (password: sai1@141)
INSERT IGNORE INTO admins (email, password) VALUES ('sai1@vsn.com', 'sai1@141');

-- ─── 3. Products ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
    id              VARCHAR(255) PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    localized_names TEXT,                                 -- JSON {"English":"...","Hindi":"..."}
    retail_price    DECIMAL(10,2) DEFAULT 0.00,
    wholesale_price DECIMAL(10,2) DEFAULT 0.00,
    cost_price      DECIMAL(10,2) DEFAULT 0.00,
    image           LONGTEXT,                             -- Base64 or URL
    details         TEXT,                                 -- JSON {category, brand, netQuantity, description}
    min_order_qty   INT          DEFAULT 1,
    is_trending     BOOLEAN      DEFAULT FALSE,
    stock_status    VARCHAR(50)  DEFAULT 'In Stock',
    coin_offer      TEXT         DEFAULT NULL             -- JSON {thresholdQuantity, rewardCoins, description}
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── 4. Orders ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
    id                  VARCHAR(255) PRIMARY KEY,
    date                DATETIME     DEFAULT CURRENT_TIMESTAMP,
    items               LONGTEXT,                         -- JSON array of CartItems
    total               DECIMAL(10,2),
    status              VARCHAR(50)  DEFAULT 'Pending',
    payment_status      VARCHAR(50)  DEFAULT 'Pending',
    payment_method      VARCHAR(100) DEFAULT 'Cash on Delivery',
    address             TEXT,
    user_email          VARCHAR(255),
    custom_delivery_date DATETIME    DEFAULT NULL,
    requires_gst        BOOLEAN      DEFAULT FALSE,
    business_name       VARCHAR(255) DEFAULT NULL,
    gst_number          VARCHAR(50)  DEFAULT NULL,
    discount_amount     DECIMAL(10,2) DEFAULT 0.00,
    delivery_charge     DECIMAL(10,2) DEFAULT 0.00,
    applied_offer_title VARCHAR(255) DEFAULT NULL,
    coins_earned        INT          DEFAULT 0,
    INDEX idx_user_email (user_email),
    INDEX idx_status     (status),
    INDEX idx_date       (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── 5. Offers ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS offers (
    id                  VARCHAR(255) PRIMARY KEY,
    title               VARCHAR(255) NOT NULL,
    description         TEXT,
    min_order_value     DECIMAL(10,2) DEFAULT 0.00,
    discount_percentage DECIMAL(5,4)  DEFAULT NULL,
    discount_amount     DECIMAL(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── 6. Notifications ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
    id         VARCHAR(255) PRIMARY KEY,
    title      VARCHAR(255),
    message    TEXT,
    date       DATETIME     DEFAULT CURRENT_TIMESTAMP,
    isRead     BOOLEAN      DEFAULT FALSE,
    type       VARCHAR(50)  DEFAULT 'General',
    userEmail  VARCHAR(255) DEFAULT 'all',
    INDEX idx_user (userEmail)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── 7. Referrals ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS referrals (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    referrer_email VARCHAR(255) NOT NULL,
    referee_email  VARCHAR(255) NOT NULL,
    reward_amount  INT          DEFAULT 50,
    status         VARCHAR(50)  DEFAULT 'completed',
    created_at     DATETIME     DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_referral (referee_email),
    INDEX idx_referrer (referrer_email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── 8. Settings ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS settings (
    `key`   VARCHAR(255) PRIMARY KEY,
    `value` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO settings (`key`, `value`) VALUES
    ('support_email',         'support@vsnhome.com'),
    ('support_whatsapp',      '919876543210'),
    ('delivery_radius',       '25'),
    ('hub_latitude',          '21.1458'),
    ('hub_longitude',         '79.0882'),
    ('admin_master_key',      'sai@141'),
    ('upi_id',                'vsnwholesale@upi'),
    ('referral_reward_coins', '50'),
    ('delivery_charge',       '0'),
    ('smtp_host',             'smtp.gmail.com'),
    ('smtp_port',             '587'),
    ('smtp_user',             ''),
    ('smtp_pass',             ''),
    ('smtp_from_name',        'VSN Home');
