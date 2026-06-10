<?php
// Backend/razorpay_order.php
include 'db_config.php';

// Fetch Razorpay Keys from Settings Table
$res = $conn->query("SELECT value FROM settings WHERE `key` = 'razorpay_key' AND value IS NOT NULL AND value != ''");
$keyId = ($res && $res->num_rows > 0) ? $res->fetch_assoc()['value'] : "rzp_test_Shak5FKtyKOOyF";

$resSecret = $conn->query("SELECT value FROM settings WHERE `key` = 'razorpay_secret' AND value IS NOT NULL AND value != ''");
$keySecret = ($resSecret && $resSecret->num_rows > 0) ? $resSecret->fetch_assoc()['value'] : "4P2f0CL4YL2jXhAKhXpWxCHi";

$data = json_decode(file_get_contents("php://input"), true);

if (!$data || !isset($data['amount'])) {
    sendResponse("error", "Invalid request payload");
}

$amount = (int)($data['amount'] * 100); // Amount in paise
$receipt = "rcpt_" . substr(md5(time()), 0, 10);
$currency = "INR";

// Create Razorpay Order via CURL
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, "https://api.razorpay.com/v1/orders");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
    'amount' => $amount,
    'currency' => $currency,
    'receipt' => $receipt,
    'payment_capture' => 1
]));
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_USERPWD, $keyId . ":" . $keySecret);

$headers = array();
$headers[] = 'Content-Type: application/json';
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

$result = curl_exec($ch);
if (curl_errno($ch)) {
    sendResponse("error", "Curl error: " . curl_error($ch));
}
curl_close($ch);

$orderData = json_decode($result, true);

if (isset($orderData['id'])) {
    sendResponse("success", "Razorpay order created", [
        "order_id" => $orderData['id'],
        "amount" => $amount,
        "key_id" => $keyId
    ]);
} else {
    $errorMsg = "Razorpay API Error: " . ($orderData['error']['description'] ?? "Check your Keys");
    if (isset($orderData['error']['code'])) {
        $errorMsg .= " (Code: " . $orderData['error']['code'] . ")";
    }
    sendResponse("error", $errorMsg);
}
?>
