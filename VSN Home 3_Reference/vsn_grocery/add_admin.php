<?php
// Backend/add_admin.php
error_reporting(0);
include 'db_config.php';

// Ensure no previous output
if (ob_get_length()) ob_clean();

$data = json_decode(file_get_contents("php://input"), true);

if (!$data || !isset($data['email']) || !isset($data['password'])) {
    sendResponse("error", "Missing enrollment credentials");
}

$email    = $conn->real_escape_string($data['email']);
$rawPass  = $data['password']; // Never escape before hashing
$upi_id   = !empty($data['upi_id']) ? "'" . $conn->real_escape_string($data['upi_id']) . "'" : "NULL";

// Hash password securely before storage
$hashedPassword = password_hash($rawPass, PASSWORD_DEFAULT);
$safePassword   = $conn->real_escape_string($hashedPassword);

// Construct SQL with explicit NULL handling for upi_id
$sql = "INSERT INTO admins (email, password, upi_id) VALUES ('$email', '$safePassword', $upi_id) 
        ON DUPLICATE KEY UPDATE password = '$safePassword', upi_id = $upi_id";

if ($conn->query($sql)) {
    sendResponse("success", "Admin #$email enrolled successfully");
} else {
    sendResponse("error", "Database Error: " . $conn->error);
}
