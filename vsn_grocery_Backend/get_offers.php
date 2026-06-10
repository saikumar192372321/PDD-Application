<?php
// Backend/get_offers.php
include 'db_config.php';

$sql = "SELECT * FROM offers ORDER BY min_order_value ASC";
$result = $conn->query($sql);
$offers = [];

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $offers[] = [
            "id" => $row["id"],
            "title" => $row["title"],
            "description" => $row["description"],
            "minOrderValue" => (double)$row["min_order_value"],
            "discountPercentage" => $row["discount_percentage"] !== null ? (double)$row["discount_percentage"] : null,
            "discountAmount" => $row["discount_amount"] !== null ? (double)$row["discount_amount"] : null
        ];
    }
}

sendResponse("success", "Active offers fetched", $offers);
?>
