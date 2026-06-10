<?php
// delete_account.php
// Deletes a user account from the database by email.
// Expected JSON body: { "email": "user@example.com" }

include 'db_config.php';

// ── Read Input ───────────────────────────────────────────────────────────────
$input = json_decode(file_get_contents("php://input"), true);
$email = isset($input['email']) ? trim($input['email']) : "";

if (empty($email)) {
    sendResponse("error", "Email is required");
}

// ── Delete User ──────────────────────────────────────────────────────────────
$stmt = $conn->prepare("DELETE FROM users WHERE email = ?");
if ($stmt) {
    $stmt->bind_param("s", $email);
    $stmt->execute();
    if ($stmt->affected_rows > 0) {
        sendResponse("success", "Account deleted successfully");
    } else {
        sendResponse("error", "Account not found");
    }
    $stmt->close();
} else {
    sendResponse("error", "Failed to prepare query: " . $conn->error);
}
?>
