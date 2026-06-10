<?php
// reset_password.php - Update user password securely
header("Content-Type: application/json");
require_once "db_config.php";

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['email']) || !isset($data['password'])) {
    sendResponse("error", "Email and new password required");
}

$email = $data['email'];
$password = $data['password'];

try {
    // 1. Check if user exists
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = :email");
    $stmt->execute([':email' => $email]);
    if (!$stmt->fetch()) {
        sendResponse("error", "Account not found");
    }

    // 2. Hash password
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

    // 3. Perform the update and CLEAR the OTP
    $stmt = $pdo->prepare("UPDATE users SET password = :password, otp = NULL, otp_expiry = NULL WHERE email = :email");
    $stmt->execute([
        ':password' => $hashedPassword,
        ':email' => $email
    ]);

    sendResponse("success", "Password updated successfully");

} catch (PDOException $e) {
    sendResponse("error", $e->getMessage());
}
?>
