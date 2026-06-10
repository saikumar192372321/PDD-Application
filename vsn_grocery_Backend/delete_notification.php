<?php
// delete_notification.php
// Deletes a notification by its ID.
// Expected JSON body: { "id": "uuid-string" }

include 'db_config.php';

$input = json_decode(file_get_contents("php://input"), true);
$id = isset($input['id']) ? trim($input['id']) : "";

if (empty($id)) {
    sendResponse("error", "Notification ID is required.");
}

$stmt = $conn->prepare("DELETE FROM notifications WHERE id = ?");
if ($stmt) {
    $stmt->bind_param("s", $id);
    if ($stmt->execute()) {
        sendResponse("success", "Notification deleted");
    } else {
        sendResponse("error", "Delete failed: " . $stmt->error);
    }
    $stmt->close();
} else {
    sendResponse("error", "Failed to prepare query: " . $conn->error);
}
?>
