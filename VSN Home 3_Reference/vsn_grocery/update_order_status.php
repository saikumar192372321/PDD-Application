<?php
// Backend/update_order_status.php
include 'db_config.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!$data || !isset($data['id'])) {
    sendResponse("error", "Missing order parameters");
}

$id = $conn->real_escape_string($data['id']);
$status = $conn->real_escape_string($data['status']);
$paymentStatus = $conn->real_escape_string($data['paymentStatus']);
$customDeliveryDate = isset($data['customDeliveryDate']) ? $conn->real_escape_string($data['customDeliveryDate']) : null;

// Convert ISO8601 to MySQL format if custom date provided
if ($customDeliveryDate) {
    $customDeliveryDate = str_replace("T", " ", substr($customDeliveryDate, 0, 19));
}

$sql = "UPDATE orders SET status = '$status', payment_status = '$paymentStatus'";
if ($customDeliveryDate) {
    $sql .= ", custom_delivery_date = '$customDeliveryDate'";
}
$sql .= " WHERE id = '$id'";

if ($conn->query($sql)) {
    sendResponse("success", "Order status refreshed in logistics system");
} else {
    sendResponse("error", "Order update failed: " . $conn->error);
}
?>
