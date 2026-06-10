CREATE DATABASE IF NOT EXISTS vsn_grocery;
USE vsn_grocery;

-- Products Table
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_uuid VARCHAR(50) UNIQUE,
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(100),
    category ENUM('Staples', 'Oil & Ghee', 'Snacks', 'Cleaning', 'Dairy') DEFAULT 'Staples',
    retail_price DECIMAL(10, 2) NOT NULL,
    wholesale_price DECIMAL(10, 2) NOT NULL,
    cost_price DECIMAL(10, 2) NOT NULL,
    image_url VARCHAR(255),
    net_quantity VARCHAR(50),
    description TEXT,
    min_order_qty INT DEFAULT 1,
    stock_status ENUM('In Stock', 'Low Stock', 'Out of Stock') DEFAULT 'In Stock',
    is_trending BOOLEAN DEFAULT FALSE,
    rating DECIMAL(2, 1) DEFAULT 0.0,
    review_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Regional Names Table (Localization)
CREATE TABLE IF NOT EXISTS product_translations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    language VARCHAR(20), -- 'hindi', 'telugu', 'kannada', 'tamil'
    translated_name VARCHAR(255),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- Bulk Offers Table
CREATE TABLE IF NOT EXISTS bulk_offers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    offer_uuid VARCHAR(50) UNIQUE,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    min_order_value DECIMAL(10, 2),
    discount_percentage DECIMAL(5, 2),
    discount_amount DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders Table
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_uuid VARCHAR(50) UNIQUE,
    user_email VARCHAR(100),
    total_amount DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) DEFAULT 0.0,
    applied_offer_title VARCHAR(100),
    address TEXT,
    status ENUM('Pending', 'Processing', 'Out for Delivery', 'Delivered', 'Cancelled') DEFAULT 'Pending',
    custom_delivery_date DATE,
    requires_gst BOOLEAN DEFAULT FALSE,
    business_name VARCHAR(255),
    gst_number VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order Items Table
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    notification_uuid VARCHAR(50) UNIQUE,
    user_email VARCHAR(100),
    title VARCHAR(255) NOT NULL,
    message TEXT,
    type ENUM('Offer', 'Order Update', 'General') DEFAULT 'General',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Mock Data for Products
INSERT INTO products (name, brand, category, retail_price, wholesale_price, cost_price, image_url, net_quantity, description, min_order_qty, stock_status, is_trending)
VALUES 
('Basmati Rice – Premium (25 Kg Bag)', 'India Gate', 'Staples', 3200, 2850, 2400, 'rice', '25 Kg', 'Premium long-grain basmati rice for bulk use.', 1, 'In Stock', TRUE),
('Sunflower Oil (15 L Tin)', 'Fortune', 'Oil & Ghee', 2400, 2100, 1850, 'oil_tin', '15 L', 'Refined sunflower oil, cholesterol free.', 1, 'In Stock', TRUE),
('Toor Dal (30 Kg Bag)', 'Tata Sampann', 'Staples', 4500, 4100, 3600, 'dal', '30 Kg', 'Unpolished organic Toor Dal.', 1, 'In Stock', FALSE),
('Sugar (50 Kg Sack)', 'Madhur', 'Staples', 2200, 1950, 1700, 'sugar', '50 Kg', 'Fine grain sulphur-free sugar.', 2, 'In Stock', TRUE);

-- Mock Users (admin123 / user123)
INSERT INTO users (email, password, is_admin)
VALUES 
('admin@vsn.com', 'admin123', 1),
('user@vsn.com', 'user123', 0);
