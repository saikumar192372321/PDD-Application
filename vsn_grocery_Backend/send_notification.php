<?php
// send_notification.php
// Receives a broadcast notification from Admin and stores it for all users.
// Expected JSON body: { "id": "uuid", "title": "...", "message": "...", "type": "general|offer|order", "userEmail": "all", "date": "2024-01-01 12:00:00", "isRead": false }

include 'db_config.php';

// ── Read Input ────────────────────────────────────────────────────────────────
$input = json_decode(file_get_contents("php://input"), true);

$id         = isset($input['id'])         ? trim($input['id'])         : bin2hex(random_bytes(16));
$title      = isset($input['title'])      ? trim($input['title'])      : "";
$message    = isset($input['message'])    ? trim($input['message'])    : "";
$type       = isset($input['type'])       ? trim($input['type'])       : "general";
$userEmail  = isset($input['userEmail'])  ? trim($input['userEmail'])  : "all";
$date       = isset($input['date'])       ? trim($input['date'])       : date("Y-m-d H:i:s");

if (empty($title) || empty($message)) {
    sendResponse("error", "Title and message are required.");
}

// ── Insert Notification ───────────────────────────────────────────────────────
$stmt = $conn->prepare("INSERT INTO notifications (id, title, message, type, userEmail, isRead, date) VALUES (?, ?, ?, ?, ?, 0, ?)");
if ($stmt) {
    $stmt->bind_param("ssssss", $id, $title, $message, $type, $userEmail, $date);
    if ($stmt->execute()) {
        sendResponse("success", "Notification broadcast successful");
    } else {
        sendResponse("error", "Insert failed: " . $stmt->error);
    }
    $stmt->close();
} else {
    sendResponse("error", "Failed to prepare query: " . $conn->error);
}
?>
