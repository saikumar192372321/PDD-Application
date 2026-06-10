<?php
// delete_account.php
// Deletes a user account from the database by email.
// Expected JSON body: { "email": "user@example.com" }

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ── DB Config ────────────────────────────────────────────────────────────────
include 'db_config.php';

// ── Read Input ───────────────────────────────────────────────────────────────
$input = json_decode(file_get_contents("php://input"), true);
$email = isset($input['email']) ? trim($input['email']) : "";

if (empty($email)) {
    echo json_encode(["status" => "error", "message" => "Email is required"]);
    $conn->close();
    exit;
}

// ── Delete User ──────────────────────────────────────────────────────────────
$stmt = $conn->prepare("DELETE FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();

if ($stmt->affected_rows > 0) {
    echo json_encode(["status" => "success", "message" => "Account deleted successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Account not found"]);
}

$stmt->close();
$conn->close();
?>
