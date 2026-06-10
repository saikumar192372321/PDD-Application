<?php
// verify_otp.php - Verify the emailed code
header("Content-Type: application/json");
require_once "db_config.php";

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['email']) || !isset($data['otp'])) {
    sendResponse("error", "Email and OTP required");
}

$email = $data['email'];
$otp   = $data['otp'];

try {
    $stmt = $pdo->prepare("SELECT otp, otp_expiry FROM users WHERE email = :email");
    $stmt->execute([':email' => $email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        sendResponse("error", "User not found");
    }

    if ($user['otp'] !== $otp) {
        sendResponse("error", "Invalid verification code");
    }

    if (strtotime($user['otp_expiry']) < time()) {
        sendResponse("error", "Code has expired");
    }

    sendResponse("success", "OTP verified successfully");

} catch (PDOException $e) {
    sendResponse("error", $e->getMessage());
}
?>
