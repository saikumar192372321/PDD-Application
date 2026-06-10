# VSN Home - PHP Security Fixes

## Critical Issues Found and How to Fix Them

### 1. SQL Injection Vulnerabilities
**Problem**: Direct SQL queries are susceptible to injection attacks.

**Current Pattern (VULNERABLE)**:
```php
"SELECT * FROM products WHERE name = '" . $_POST['name'] . "'"
```

**Fix**: Use prepared statements with parameterized queries:
```php
$stmt = $conn->prepare("SELECT * FROM products WHERE name = ?");
$stmt->bind_param("s", $_POST['name']);
$stmt->execute();
$result = $stmt->get_result();
```

**Files to Update**:
- `add_product.php`
- `delete_product.php`
- `get_products.php`
- `place_order.php`
- `get_orders.php`
- `login.php`
- `register.php`
- All other PHP files with database queries

### 2. Hardcoded Database Credentials
**Problem**: Credentials are visible in `config.php` source

**Fix**:
1. Create a `.env` file (NOT in version control)
2. Use `.gitignore` to exclude it
3. Load environment variables:
```php
$host = getenv('DB_HOST') ?: 'localhost';
$user = getenv('DB_USER') ?: 'root';
$password = getenv('DB_PASS') ?: '';
$database = getenv('DB_NAME') ?: 'vsn_grocery';
```

### 3. Missing Input Validation
**Problem**: No validation before processing user data

**Fix**: Add validation function:
```php
<?php
function validateInput($data, $type = 'string') {
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data);
    
    switch($type) {
        case 'email':
            return filter_var($data, FILTER_VALIDATE_EMAIL) ? $data : false;
        case 'phone':
            return preg_match('/^[0-9]{10}$/', $data) ? $data : false;
        case 'number':
            return is_numeric($data) ? $data : false;
        default:
            return !empty($data) ? $data : false;
    }
}

function validateGSTIN($gstin) {
    return preg_match('/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/', $gstin);
}
?>
```

### 4. No Password Hashing
**Problem**: Passwords stored in plain text

**Current Pattern (VULNERABLE)**:
```php
$password = $_POST['password']; // Plain text in database!
```

**Fix**: Always hash passwords:
```php
$hashedPassword = password_hash($_POST['password'], PASSWORD_BCRYPT);
// When checking password:
if (password_verify($userInput, $hashedStoredHash)) {
    // Password matches
}
```

### 5. Missing HTTPS/Data Encryption
**Problem**: User data transmitted over HTTP (unencrypted)

**Fix**:
1. Update `APIConfig.swift`:
   Change: `http://localhost/vsn_grocery/`
   To: `https://yourdomain.com/vsn_grocery/`

2. In PHP, force HTTPS:
```php
<?php
if (empty($_SERVER['HTTPS']) || $_SERVER['HTTPS'] === 'off') {
    header('Location: https://' . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI']);
    exit();
}
?>
```

### 6. No CORS Protection
**Problem**: API accessible from any domain

**Fix**: Add CORS headers in config.php:
```php
<?php
header('Access-Control-Allow-Origin: https://yourdomain.com');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Max-Age: 86400'); // 24 hours

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
?>
```

### 7. Debug Code in Production
**Problem**: Error details exposed to users

**Current Pattern (VULNERABLE)**:
```php
if (!$result) {
    die("Error: " . $conn->error); // Shows SQL structure!
}
```

**Fix**:
```php
<?php
if (!$result) {
    error_log("Database error: " . $conn->error); // Log internally
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Internal server error']);
    exit();
}
?>
```

### 8. No Rate Limiting
**Problem**: API can be brute-forced

**Fix**: Add rate limiting to `config.php`:
```php
<?php
function checkRateLimit($identifier, $maxAttempts = 5, $timeWindow = 60) {
    $file = sys_get_temp_dir() . '/ratelimit_' . md5($identifier) . '.txt';
    
    if (file_exists($file)) {
        $data = file_get_contents($file);
        list($attempts, $firstAttempt) = explode(':', $data);
        
        if (time() - $firstAttempt < $timeWindow) {
            if ($attempts >= $maxAttempts) {
                http_response_code(429);
                exit('Too many requests');
            }
            file_put_contents($file, ($attempts + 1) . ':' . $firstAttempt);
        } else {
            file_put_contents($file, '1:' . time());
        }
    } else {
        file_put_contents($file, '1:' . time());
    }
}

checkRateLimit($_SERVER['REMOTE_ADDR']);
?>
```

### 9. No Session Security
**Problem**: Session IDs could be hijacked

**Fix**: Set secure session options:
```php
<?php
ini_set('session.cookie_secure', 1);      // HTTPS only
ini_set('session.cookie_httponly', 1);    // No JavaScript access
ini_set('session.cookie_samesite', 'Lax');// CSRF protection
session_start();
?>
```

### 10. Missing API Response Validation
**Problem**: No check for valid admin/user before operations

**Fix**: Add authentication check:
```php
<?php
function checkAdminAuth() {
    if (!isset($_SESSION['is_admin']) || !$_SESSION['is_admin']) {
        http_response_code(403);
        echo json_encode(['status' => 'error', 'message' => 'Unauthorized']);
        exit();
    }
}

function checkUserAuth() {
    if (!isset($_SESSION['user_id'])) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Not authenticated']);
        exit();
    }
}
?>
```

## Implementation Priority

1. **URGENT**: SQL injection fixes (affects all queries)
2. **URGENT**: Password hashing (user security)
3. **HIGH**: HTTPS/CORS (prevent man-in-the-middle attacks)
4. **HIGH**: Input validation (prevent exploits)
5. **MEDIUM: Rate limiting & session security
6. **MEDIUM**: Remove debug code
7. **LOW**: Environment variables (keep credentials safe)

## Testing Before Deployment

```bash
# Check SQL injection vulnerability
curl -X POST http://localhost/vsn_grocery/login.php \
  -d "email=admin@test.com' OR '1'='1&password=anything"

# Check HTTPS enforcement
curl -H "Host: yourdomain.com" http://yourdomain.com/vsn_grocery/

# Check headers are present
curl -I https://yourdomain.com/vsn_grocery/test.php
# Should see: 
# - X-Content-Type-Options: nosniff
# - Cache-Control: no-store
# - Strict-Transport-Security (HSTS)
```

## Summary

After these fixes, your app will be:
✅ Protected against SQL injection
✅ Using secure password storage
✅ Encrypting data in transit (HTTPS)
✅ Validating all user inputs
✅ Protecting against rate limiting attacks
✅ Preventing cross-site attacks
✅ Hiding debug information from users
