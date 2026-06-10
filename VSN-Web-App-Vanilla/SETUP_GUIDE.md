# VSN Grocery Web App — Setup & Deployment Guide

---

## 📋 What This App Does

VSN Grocery is a full-stack web application for wholesale grocery ordering:
- **Customer side** (`index.html`): Browse products, place orders, manage profile
- **Admin panel** (`admin.html`): Manage orders, products, users, analytics
- **Backend**: PHP + MySQL hosted via XAMPP / any PHP web server

---

## 🚀 Local Setup (XAMPP)

### Step 1: Install XAMPP
Download from: https://www.apachefriends.org/

### Step 2: Deploy Backend
Copy the backend folder to XAMPP:
```
C:/xampp/htdocs/vsn_grocery/    ← Windows
/Applications/XAMPP/htdocs/vsn_grocery/  ← Mac
```

Copy all PHP files from `vsn_grocery_Backend/` into that folder.

### Step 3: Create Database
1. Open XAMPP → Start **Apache** and **MySQL**
2. Open phpMyAdmin: http://localhost/phpmyadmin
3. Import the schema:
   - Click "New Database" → name it `vsn_grocery`
   - Click Import → select `vsn_grocery_Backend/schema.sql`
   - Click Go

### Step 4: Configure DB Connection
Edit `vsn_grocery_Backend/.env` (or create from `.env.example`):
```
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASS=
DB_NAME=vsn_grocery
```

> **Note**: Default XAMPP MySQL port is 3306. If you get connection errors, try 3307.

### Step 5: Open the Web App
Open **index.html** in a browser:
- Double-click `index.html` (file:// mode) — works for basic testing
- Or serve from XAMPP: Place `VSN-Web-App/` in `htdocs/vsn_app/` and open http://localhost/vsn_app/

---

## 🔐 Login & Admin — How It Works

### Customer Login
1. Click the 👤 user icon in the top-right navbar
2. The login panel opens with **Login** and **Sign Up** tabs
3. **Login tab**: Enter email + password → click Login
4. **Sign Up tab**: Fill all fields → create account → auto-switches to Login
5. **Forgot Password**: Click "Forgot Password?" → enter email → reset password

### Admin Login
- Go to `admin.html` (separate page)
- Enter **admin email** and **password**
- Default admin: `sai1@vsn.com` / `sai1@141`

> ⚠️ **IMPORTANT**: Change the default admin password after first login!
> Go to Admin Panel → Settings → Add Admin to create a new admin.

### Creating a New Admin
In phpMyAdmin, run:
```sql
INSERT INTO admins (email, password) 
VALUES ('your@email.com', '$2y$10$...');
```
Or use the Admin Panel → Settings → "Add New Admin" form.

---

## 🌐 Production Deployment

### Set Backend URL
In `VSN-Web-App/js/api.js`, change:
```js
const VSN_BACKEND_URL = 'https://yourdomain.com/vsn_grocery';
```

### CORS Configuration
In `vsn_grocery_Backend/db_config.php`, add your domain:
```php
$allowed_origins = [
    "https://yourdomain.com",
    "http://localhost"
];
```

### File Structure on Server
```
/public_html/                ← or /var/www/html/
    vsn_grocery/             ← Backend PHP files here
        .env                 ← Database credentials
    vsn_app/                 ← Web app files here
        index.html
        admin.html
        css/
        js/
        icons/
        manifest.json
        sw.js
```

---

## 🧪 Testing the Backend Connection

In **Admin Panel**, when you log in, the dashboard shows:
- 🟢 **"Backend Connected"** — Everything is working
- 🔴 **"Cannot connect"** — Check XAMPP is running

---

## 📱 PWA (Install as App)

The web app supports Progressive Web App installation:
1. Open in Chrome on Android/iPhone
2. Look for "Add to Home Screen" prompt
3. Or go to browser menu → "Install App"

---

## 🗂️ Key Files

| File | Purpose |
|------|---------|
| `index.html` | Main customer-facing web app |
| `admin.html` | Admin dashboard (separate login) |
| `js/api.js` | Backend URL config & API calls |
| `js/app.js` | All customer frontend logic |
| `js/admin.js` | All admin panel logic |
| `css/style.css` | Customer app styles |
| `css/admin.css` | Admin panel styles |
| `manifest.json` | PWA configuration |
| `sw.js` | Service Worker (offline support) |

---

## 🛡️ Security Checklist Before Production

- [ ] Change default admin password in `admins` table
- [ ] Set strong DB credentials in `.env`
- [ ] Enable HTTPS on your server
- [ ] Update CORS allowed origins in `db_config.php`
- [ ] Set `VSN_BACKEND_URL` in `api.js` to your domain
- [ ] Remove `test.php` and `debug_settings.php` from backend

---

## 📞 Support

For help with deployment or customization, check:
- XAMPP documentation: https://www.apachefriends.org/faq.html
- MySQL setup: https://dev.mysql.com/doc/

---

*VSN Grocery Web App — Built to match the VSN Home iOS application*
