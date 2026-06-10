<?php
// Backend/add_product.php
require_once 'db_config.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!$data) {
    sendResponse("error", "Invalid input data", null, 400);
}

// ─── Extract Fields ──────────────────────────────────────────
$id              = $data['id'] ?? '';
$name            = $data['name'] ?? '';
$localized_names = json_encode($data['localizedNames'] ?? []);
$retail_price    = (float)($data['retailPrice'] ?? 0);
$wholesale_price = (float)($data['wholesalePrice'] ?? 0);
$cost_price      = (float)($data['costPrice'] ?? 0);
$image           = $data['image'] ?? '';
$details         = json_encode($data['details'] ?? []);
$min_order_qty   = (int)($data['minOrderQty'] ?? 1);
$is_trending     = !empty($data['isTrending']) ? 1 : 0;
$stock_status    = $data['stockStatus'] ?? 'In Stock';
$coin_offer      = isset($data['coinOffer']) ? json_encode($data['coinOffer']) : null;

if (empty($id) || empty($name)) {
    sendResponse("error", "Product ID and name are required", null, 400);
}

// ─── Execute REPLACE INTO with Prepared Statement ─────────────
$stmt = $conn->prepare("
    REPLACE INTO products (
        id, name, localized_names, retail_price, wholesale_price, 
        cost_price, image, details, min_order_qty, is_trending, 
        stock_status, coin_offer
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
");

$stmt->bind_param(
    "sssdddssiiss",
    $id, $name, $localized_names, $retail_price, $wholesale_price,
    $cost_price, $image, $details, $min_order_qty, $is_trending,
    $stock_status, $coin_offer
);

if ($stmt->execute()) {
    sendResponse("success", "Product integrated into catalog successfully");
} else {
    sendResponse("error", "Database error: " . $stmt->error, null, 500);
}

$stmt->close();
$conn->close();
?>

