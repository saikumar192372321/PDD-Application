<?php
// Backend/support.php
error_reporting(0);
include 'db_config.php';

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $data = json_decode(file_get_contents("php://input"), true);
    if ($data) {
        foreach($data as $key => $value) {
            $trimmedVal = trim($value);
            // If it's a sensitive key and the value is empty, skip updating it to avoid overwriting with empty string
            $sensitive_keys = ['admin_master_key', 'razorpay_secret', 'smtp_pass'];
            if (in_array($key, $sensitive_keys) && empty($trimmedVal)) {
                continue;
            }
            
            $safeKey = $conn->real_escape_string($key);
            $safeVal = $conn->real_escape_string($value);
            $dbKey = (in_array($key, ['email', 'whatsapp', 'delivery_note'])) ? "support_$key" : $safeKey;
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
        "delivery_note" => ""
    ];
    // Sensitive keys that must NEVER be returned in the public GET response
    $blocked_keys = ['admin_master_key', 'razorpay_secret', 'smtp_host', 'smtp_port', 'smtp_user', 'smtp_pass'];
    while($row = $res->fetch_assoc()) {
        if (in_array($row['key'], $blocked_keys)) continue;
        $cleanKey = str_replace('support_', '', $row['key']);
        $settings[$cleanKey] = $row['value'];
    }
    echo json_encode((object)$settings);
}
