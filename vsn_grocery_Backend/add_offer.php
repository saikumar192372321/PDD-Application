<?php
// Backend/add_offer.php
include 'db_config.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!$data || !isset($data['id']) || !isset($data['title'])) {
    sendResponse("error", "Invalid offer payload");
}

$id = trim($data['id']);
$title = trim($data['title']);
$description = isset($data['description']) ? trim($data['description']) : "";
$minOrderValue = (double)$data['minOrderValue'];
$discountPercentage = isset($data['discountPercentage']) && $data['discountPercentage'] !== '' ? (double)$data['discountPercentage'] : null;
$discountAmount = isset($data['discountAmount']) && $data['discountAmount'] !== '' ? (double)$data['discountAmount'] : null;

$stmt = $conn->prepare("REPLACE INTO offers (id, title, description, min_order_value, discount_percentage, discount_amount) VALUES (?, ?, ?, ?, ?, ?)");
if ($stmt) {
    $stmt->bind_param("sssddd", $id, $title, $description, $minOrderValue, $discountPercentage, $discountAmount);
    if ($stmt->execute()) {
        sendResponse("success", "Bulk offer #$id activated in the marketplace");
    } else {
        sendResponse("error", "Activation failure: " . $stmt->error);
    }
    $stmt->close();
} else {
    sendResponse("error", "Failed to prepare offer query: " . $conn->error);
}
?>
