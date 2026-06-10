<?php
// ============================================================
// login.php — VSN Home User + Admin Login
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

$email    = strtolower(trim($data['email']));
$password = $data['password'];

// ─── 1. Check Users Table ─────────────────────────────────────
$stmt = $conn->prepare("SELECT * FROM users WHERE email = ? LIMIT 1");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    if (password_verify($password, $user['password'])) {
        sendResponse("success", "Login Successful", [
            "email"         => $user['email'],
            "name"          => $user['name'],
            "phone"         => $user['phone'] ?? "",
            "address"       => $user['address'] ?? "",
            "business_name" => $user['business_name'] ?? "",
            "gstin"         => $user['gstin'] ?? "",
            "upi_id"        => $user['upi_id'] ?? "",
            "profile_image" => $user['profile_image'] ?? "",
            "coins"         => (int)($user['coins'] ?? 0),
            "referral_code" => $user['referral_code'] ?? "",
            "referred_by"   => $user['referred_by'] ?? "",
            "is_admin"      => false
        ]);
    }
}
$stmt->close();

// ─── 2. Fallback: Check Admins Table ─────────────────────────
$stmt2 = $conn->prepare("SELECT * FROM admins WHERE email = ? LIMIT 1");
$stmt2->bind_param("s", $email);
$stmt2->execute();
$adminResult = $stmt2->get_result();

if ($adminResult->num_rows > 0) {
    $admin = $adminResult->fetch_assoc();
    // Support both hashed and plain-text admin passwords
    $pwMatch = password_verify($password, $admin['password'])
             || ($admin['password'] === $password);
    if ($pwMatch) {
        sendResponse("success", "Admin Access Granted", [
            "email"    => $admin['email'],
            "upi_id"   => $admin['upi_id'] ?? "",
            "is_admin" => true
        ]);
    }
}
$stmt2->close();

sendResponse("error", "Invalid email or password. Please try again.", null, 401);
?>
