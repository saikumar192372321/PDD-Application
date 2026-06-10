<?php
// mark_notifications_read.php
// Marks all notifications for a given user as read.
// Expected JSON body: { "userEmail": "user@example.com" }

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$host = "localhost";
$db   = "vsn_grocery";
$user = "root";
$pass = "";

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    echo json_encode(["status" => "error", "message" => "DB connection failed."]);
    exit;
}

$input = json_decode(file_get_contents("php://input"), true);
$userEmail = isset($input['userEmail']) ? trim($input['userEmail']) : "";

if (empty($userEmail)) {
    echo json_encode(["status" => "error", "message" => "userEmail is required."]);
    $conn->close();
    exit;
}

// Mark notifications addressed to "all" or specifically to this user as read
$stmt = $conn->prepare("UPDATE notifications SET is_read = 1 WHERE user_email = 'all' OR user_email = ?");
$stmt->bind_param("s", $userEmail);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "All notifications marked as read."]);
} else {
    echo json_encode(["status" => "error", "message" => "Update failed: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>
