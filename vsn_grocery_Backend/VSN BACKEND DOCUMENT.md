# VSN Grocery Store - Backend Documentation

## 🏗 Overview
The VSN Grocery Store backend is a PHP-based REST API that uses a MySQL database to manage products, users, orders, and notifications. It is designed to work seamlessly with the SwiftUI frontend.

## 📂 Project Structure
- **/db/schema.sql**: Complete database schema and mock data.
- **config.php**: Database connection configuration (PDO).
- **login.php**: User and Admin authentication.
- **register.php**: User registration.
- **get_products.php**: Fetch product list with multi-language support.
- **get_offers.php**: Fetch active bulk deals.
- **place_order.php**: Process and store new customer orders.
- **get_orders.php**: Retrieve order history for users and administrators.
- **update_stock.php**: Admin endpoint to update product availability.
- **add_product.php**: Admin endpoint to add new products.
- **update_order_status.php**: Admin endpoint to process orders and set delivery dates.
- **get_notifications.php**: Fetch real-time alerts and offers.

---

## 💾 Database Schema

### 1. `products`
Stores all wholesale product information including prices, categories, and stock status.
- **Stock Status**: `In Stock`, `Low Stock`, `Out of Stock`.

### 2. `product_translations`
Handles multi-language support (Hindi, Telugu, Kannada, etc.) for product names.

### 3. `orders` & `order_items`
Manages customer purchases, GST billing details, and specific item quantities.

### 4. `users`
Stores user credentials and profile details.
- **Fields**: `email`, `password`, `full_name`, `phone`, `address`, `is_admin`.

### 5. `notifications`
Supports role-based alerts for bulk offers and order updates.
- **Status Tracking**: Tracks `is_read` status per user.

---

## 🚀 Integration Details

### Base URL
`http://localhost/vsn%20grocery%20store/`

### How to Sync:
1.  **Swift Models**: All models in `Shared/Models.swift` now conform to `Codable`.
2.  **ProductStore.swift**: The central data store now uses `URLSession` to fetch fresh data from the backend.
3.  **Authentication**: `LoginView` and `SignUpView` are connected to the live MySQL database via PHP.
4.  **Order Flow**: `CartView` submits the final order object as JSON to `place_order.php`.

---

## ✨ Key Features
- **Multi-language Support**: Product names are stored in 4+ languages and served via `product_translations`. 
- **Stock Management**: Admin-controlled stock statuses (In Stock, Low Stock, Out of Stock) reflected in real-time.
- **Transaction Security**: Order placement uses PDO transactions to ensure atomicity for both orders and items.
- **Admin Dashboard**: Real-time sales data, profit calculations, and inventory alerts.
- **Notification System**: Role-based notifications for system alerts or special offers.

## 📡 API Responses
All endpoints return a standardized JSON structure:
```json
{
  "status": "success",
  "data": { ... }
}
```
Or in case of failure:
```json
{
  "status": "error",
  "message": "Error description here"
}
```

---

## 🛠 Setup Instructions
1.  Start your **XAMPP/WAMP** server.
2.  Open **phpMyAdmin** and create a database named `vsn_grocery`.
3.  Import the `/db/schema.sql` file into the database.
4.  Copy the backend folder to your `htdocs` directory.
5.  Base URL: `http://localhost/vsn%20grocery%20store/`
6.  The Swift frontend is pre-configured to look for this exact path on `localhost`.

---

## 🔐 Admin Access
- **Email**: `admin@vsn.com`
- **Password**: `admin123`
- (Login via the standard Login screen; it redirects based on the `is_admin` flag in the `users` table.)
