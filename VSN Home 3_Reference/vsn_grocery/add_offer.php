<?php
// Backend/add_offer.php
include 'db_config.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!$data) {
    sendResponse("error", "Invalid offer payload");
}

$id = $conn->real_escape_string($data['id']);
$title = $conn->real_escape_string($data['title']);
$description = $conn->real_escape_string($data['description']);
$minOrderValue = $data['minOrderValue'];
$discountPercentage = isset($data['discountPercentage']) ? $data['discountPercentage'] : "NULL";
$discountAmount = isset($data['discountAmount']) ? $data['discountAmount'] : "NULL";

$sql = "REPLACE INTO offers (id, title, description, min_order_value, discount_percentage, discount_amount) 
        VALUES ('$id', '$title', '$description', $minOrderValue, $discountPercentage, $discountAmount)";

if ($conn->query($sql)) {
    sendResponse("success", "Bulk offer #$id activated in the marketplace");
} else {
    sendResponse("error", "Activation failure: " . $conn->error);
}
?>
