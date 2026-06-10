<?php
// Backend/update_order_status.php
include 'db_config.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!$data || !isset($data['id'])) {
    sendResponse("error", "Missing order ID", null, 400);
}

$id = $data['id'];

// Whitelist allowed status values
$allowedStatuses        = ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];
$allowedPaymentStatuses = ['Pending', 'Paid', 'Failed', 'Refunded'];

$setClauses = [];
$bindTypes  = '';
$bindValues = [];

if (isset($data['status'])) {
    if (!in_array($data['status'], $allowedStatuses)) {
        sendResponse("error", "Invalid status value", null, 400);
    }
    $setClauses[] = "status = ?";
    $bindTypes   .= "s";
    $bindValues[] = $data['status'];
}

if (isset($data['paymentStatus'])) {
    if (!in_array($data['paymentStatus'], $allowedPaymentStatuses)) {
        sendResponse("error", "Invalid payment status value", null, 400);
    }
    $setClauses[] = "payment_status = ?";
    $bindTypes   .= "s";
    $bindValues[] = $data['paymentStatus'];
}

if (isset($data['customDeliveryDate'])) {
    $date = str_replace("T", " ", substr($data['customDeliveryDate'], 0, 19));
    $setClauses[] = "custom_delivery_date = ?";
    $bindTypes   .= "s";
    $bindValues[] = $date;
}

if (empty($setClauses)) {
    sendResponse("error", "No parameters to update", null, 400);
}

// Append the WHERE clause binding
$bindTypes   .= "s";
$bindValues[] = $id;

$sql  = "UPDATE orders SET " . implode(", ", $setClauses) . " WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param($bindTypes, ...$bindValues);

if ($stmt->execute()) {
    if ($stmt->affected_rows === 0) {
        sendResponse("error", "Order not found or no changes made", null, 404);
    }
    sendResponse("success", "Order updated successfully");
} else {
    sendResponse("error", "Order update failed: " . $stmt->error, null, 500);
}

$stmt->close();
$conn->close();
?>
