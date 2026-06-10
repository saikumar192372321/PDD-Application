<?php
// Backend/update_stock.php
include 'db_config.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!$data || !isset($data['id'])) {
    sendResponse("error", "Missing operational parameters");
}

$id = $conn->real_escape_string($data['id']);
$status = $conn->real_escape_string($data['stockStatus']);

$sql = "UPDATE products SET stock_status = '$status' WHERE id = '$id'";

if ($conn->query($sql)) {
    sendResponse("success", "Inventory status updated in real-time");
} else {
    sendResponse("error", "Database update failed: " . $conn->error);
}
?>
