<?php
// ============================================================
// admin_login.php — VSN Home Admin Authentication
// Supports both plain-text AND bcrypt-hashed passwords
// Method: POST | Content-Type: application/json
// Body: { "email": "...", "password": "..." }
// ============================================================
require_once 'db_config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse("error", "Method not allowed. Use POST.", null, 405);
}

$data = json_decode(file_get_contents("php://input"), true);

if (!$data || empty($data['email']) || empty($data['password'])) {
    sendResponse("error", "Email and password are required.", null, 400);
}

$email    = strtolower(sanitize($conn, $data['email']));
$password = $data['password']; // Raw — compare BEFORE any escaping

// Fetch admin by email
$stmt = $conn->prepare("SELECT * FROM admins WHERE email = ? LIMIT 1");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result && $result->num_rows > 0) {
    $admin = $result->fetch_assoc();
    $stored = $admin['password'];

    // ✅ ONLY accept bcrypt-hashed passwords (production standard)
    // Do NOT support plain-text passwords for security
    $isValid = password_verify($password, $stored);

    if ($isValid) {

        sendResponse("success", "Access Granted", [
            "email"  => $admin['email'],
            "upi_id" => $admin['upi_id'] ?? null
        ]);
    }
}

$stmt->close();
sendResponse("error", "Access Denied: Invalid Credentials", null, 401);
?>
