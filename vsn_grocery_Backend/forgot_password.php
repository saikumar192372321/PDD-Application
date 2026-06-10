<?php
// ============================================================
// forgot_password.php — VSN Home Password Reset (Email Verify)
// Method: POST | Content-Type: application/json
// Body: { "email": "..." }
// Returns success if email is registered, allowing direct reset
// ============================================================
require_once "db_config.php";

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse("error", "Method not allowed. Use POST.", null, 405);
}

$data = json_decode(file_get_contents("php://input"), true);

if (empty($data['email'])) {
    sendResponse("error", "Email is required.", null, 400);
}

$email = strtolower(trim($data['email']));

try {
    // Check if user exists in users table
    $stmt = $pdo->prepare("SELECT id, name FROM users WHERE email = :email");
    $stmt->execute([':email' => $email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        sendResponse("error", "No account found with this email address.", null, 404);
    }

    // User exists — allow direct password reset via reset_password.php
    // For security, optionally generate a temporary token (simplified here)
    sendResponse("success", "Email verified. You can now reset your password.", [
        "email" => $email,
        "name"  => $user['name']
    ]);

} catch (PDOException $e) {
    error_log("VSN forgot_password error: " . $e->getMessage());
    sendResponse("error", "An error occurred. Please try again.", null, 500);
}
?>
