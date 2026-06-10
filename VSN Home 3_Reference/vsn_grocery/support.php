<?php
// Backend/support.php
error_reporting(0);
include 'db_config.php';

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $data = json_decode(file_get_contents("php://input"), true);
    if ($data) {
        foreach($data as $key => $value) {
            $safeKey = $conn->real_escape_string($key);
            $safeVal = $conn->real_escape_string($value);
            $dbKey = (in_array($key, ['email', 'whatsapp'])) ? "support_$key" : $safeKey;
            $conn->query("REPLACE INTO settings (`key`, `value`) VALUES ('$dbKey', '$safeVal')");
        }
        sendResponse("success", "Business & Logistics settings updated");
    }
} else {
    $res = $conn->query("SELECT * FROM settings");
    $settings = [
        "upi_id" => "vsnwholesale@upi", // Default
        "email" => "",
        "whatsapp" => "",
        "delivery_radius" => "25",
        "delivery_charge" => "0",
        "free_delivery_threshold" => "5000",
        "hub_latitude" => "21.1458",
        "hub_longitude" => "79.0882",
        "admin_master_key" => "sai@141"
    ];
    while($row = $res->fetch_assoc()) {
        $cleanKey = str_replace('support_', '', $row['key']);
        $settings[$cleanKey] = $row['value'];
    }
    echo json_encode((object)$settings);
}
