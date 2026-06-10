<?php
// delete_notification.php
// Deletes a notification by its ID.
// Expected JSON body: { "id": "uuid-string" }

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

include 'db_config.php';

$input = json_decode(file_get_contents("php://input"), true);
$id = isset($input['id']) ? trim($input['id']) : "";

if (empty($id)) {
    echo json_encode(["status" => "error", "message" => "Notification ID is required."]);
    $conn->close();
    exit;
}

$stmt = $conn->prepare("DELETE FROM notifications WHERE id = ?");
$stmt->bind_param("s", $id);

if ($stmt->execute()) {
    sendResponse("success", "Notification deleted");
} else {
    sendResponse("error", "Delete failed: " . $conn->error);
}

$stmt->close();
$conn->close();
?>
