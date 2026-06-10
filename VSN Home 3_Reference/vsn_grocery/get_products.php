<?php
// ============================================================
// get_products.php — VSN Home Product List
// Method: GET
// Optional Query Params: ?category=Staples  ?trending=1
// ============================================================
require_once 'db_config.php';

$category = isset($_GET['category']) ? sanitize($conn, $_GET['category']) : null;
$trending = isset($_GET['trending']) && $_GET['trending'] == '1';

$sql = "SELECT * FROM products";
$conditions = [];

if ($category && $category !== 'All') {
    $conditions[] = "JSON_UNQUOTE(JSON_EXTRACT(details, '$.category')) = '$category'";
}
if ($trending) {
    $conditions[] = "is_trending = 1";
}
if (!empty($conditions)) {
    $sql .= " WHERE " . implode(" AND ", $conditions);
}
$sql .= " ORDER BY is_trending DESC, name ASC";

$result   = $conn->query($sql);
$products = [];

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $details       = json_decode($row['details'] ?? '{}', true);
        $coinOffer     = json_decode($row['coin_offer'] ?? 'null', true);
        $localizedNames = json_decode($row['localized_names'] ?? 'null', true);

        $products[] = [
            "id"             => $row['id'],
            "name"           => $row['name'],
            "localizedNames" => $localizedNames,
            "retailPrice"    => (float)$row['retail_price'],
            "wholesalePrice" => (float)$row['wholesale_price'],
            "costPrice"      => (float)($row['cost_price'] ?? 0),
            "image"          => $row['image'] ?? "",
            "details"        => $details,
            "minOrderQty"    => (int)($row['min_order_qty'] ?? 1),
            "isTrending"     => (bool)$row['is_trending'],
            "stockStatus"    => $row['stock_status'] ?? "In Stock",
            "coinOffer"      => $coinOffer,
            "rating"         => 0.0,
            "reviewCount"    => 0,
        ];
    }
}

sendResponse("success", count($products) . " product(s) fetched.", $products);
?>
