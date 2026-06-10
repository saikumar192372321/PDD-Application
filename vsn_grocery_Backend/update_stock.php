<?php
// Backend/update_stock.php
include 'db_config.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!$data || !isset($data['id']) || !isset($data['stockStatus'])) {
    sendResponse("error", "Missing operational parameters");
}

$id = trim($data['id']);
$status = trim($data['stockStatus']);

$stmt = $conn->prepare("UPDATE products SET stock_status = ? WHERE id = ?");
if ($stmt) {
    $stmt->bind_param("ss", $status, $id);
    if ($stmt->execute()) {
        sendResponse("success", "Inventory status updated in real-time");
    } else {
        sendResponse("error", "Database update failed: " . $stmt->error);
    }
    $stmt->close();
} else {
    sendResponse("error", "Failed to prepare update query: " . $conn->error);
}
?>
