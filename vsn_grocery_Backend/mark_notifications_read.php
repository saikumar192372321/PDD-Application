<?php
// mark_notifications_read.php
// Marks all notifications for a given user as read.
// Expected JSON body: { "userEmail": "user@example.com" }

include 'db_config.php';

$input = json_decode(file_get_contents("php://input"), true);
$userEmail = isset($input['userEmail']) ? trim($input['userEmail']) : "";

if (empty($userEmail)) {
    sendResponse("error", "userEmail is required.");
}

// Mark notifications addressed to "all" or specifically to this user as read
$stmt = $conn->prepare("UPDATE notifications SET isRead = 1 WHERE userEmail = 'all' OR userEmail = ?");
if ($stmt) {
    $stmt->bind_param("s", $userEmail);
    if ($stmt->execute()) {
        sendResponse("success", "All notifications marked as read.");
    } else {
        sendResponse("error", "Update failed: " . $stmt->error);
    }
    $stmt->close();
} else {
    sendResponse("error", "Failed to prepare update query: " . $conn->error);
}
?>
