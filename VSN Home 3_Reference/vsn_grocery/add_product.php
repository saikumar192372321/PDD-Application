<?php
// Backend/add_product.php
include 'db_config.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!$data) {
    sendResponse("error", "Invalid input data");
}

$id = $conn->real_escape_string($data['id']);
$name = $conn->real_escape_string($data['name']);
$localized_names = $conn->real_escape_string(json_encode($data['localizedNames']));
$retail_price = $data['retailPrice'];
$wholesale_price = $data['wholesalePrice'];
$cost_price = $data['costPrice'];
$image = $conn->real_escape_string($data['image']);
$details = $conn->real_escape_string(json_encode($data['details']));
$min_order_qty = $data['minOrderQty'];
$is_trending = $data['isTrending'] ? 1 : 0;
$stock_status = $conn->real_escape_string($data['stockStatus']);
$coin_offer = isset($data['coinOffer']) ? $conn->real_escape_string(json_encode($data['coinOffer'])) : "NULL";

$sql = "REPLACE INTO products (id, name, localized_names, retail_price, wholesale_price, cost_price, image, details, min_order_qty, is_trending, stock_status, coin_offer) 
        VALUES ('$id', '$name', '$localized_names', $retail_price, $wholesale_price, $cost_price, '$image', '$details', $min_order_qty, $is_trending, '$stock_status', " . ($coin_offer == "NULL" ? "NULL" : "'$coin_offer'") . ")";

if ($conn->query($sql)) {
    sendResponse("success", "Product integrated into catalog successfully");
} else {
    sendResponse("error", "Database error: " . $conn->error);
}
?>
