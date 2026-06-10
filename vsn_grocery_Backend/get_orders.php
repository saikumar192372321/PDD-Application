<?php
// Backend/get_orders.php
include 'db_config.php';

$isAdmin = isset($_GET['isAdmin']) && $_GET['isAdmin'] == 'true';
$userEmail = isset($_GET['userEmail']) ? trim($_GET['userEmail']) : null;

$sql = "SELECT id, DATE_FORMAT(date, '%Y-%m-%dT%H:%i:%sZ') as date, items, total, status, payment_status, payment_method, address, user_email, custom_delivery_date, requires_gst, business_name, gst_number, discount_amount, delivery_charge, applied_offer_title, coins_earned FROM orders";

if (!$isAdmin && $userEmail) {
    $sql .= " WHERE user_email = ?";
    $stmt = $conn->prepare($sql . " ORDER BY date DESC");
    $stmt->bind_param("s", $userEmail);
    $stmt->execute();
    $result = $stmt->get_result();
} else {
    $result = $conn->query($sql . " ORDER BY date DESC");
}

$orders = [];

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $orders[] = [
            "id" => $row["id"],
            "date" => $row["date"],
            "items" => json_decode($row["items"], true),
            "total" => (double)$row["total"],
            "status" => $row["status"],
            "paymentStatus" => $row["payment_status"],
            "paymentMethod" => $row["payment_method"],
            "address" => $row["address"],
            "userEmail" => $row["user_email"],
            "customDeliveryDate" => $row["custom_delivery_date"] ? str_replace(" ", "T", $row["custom_delivery_date"]) . "Z" : null,
            "requiresGSTBill" => (bool)$row["requires_gst"],
            "businessName" => $row["business_name"],
            "gstNumber" => $row["gst_number"],
            "discountAmount" => (double)$row["discount_amount"],
            "deliveryCharge" => (double)$row["delivery_charge"],
            "appliedOfferTitle" => $row["applied_offer_title"],
            "coinsEarned" => (int)$row["coins_earned"]
        ];
    }
}

sendResponse("success", "Orders synchronization complete", $orders);
?>
