<?php
error_reporting(0);
include 'db_config.php';

$sql = "SELECT id, name, email, phone, address, business_name, gstin, upi_id, created_at, profile_image, coins, referral_code, referred_by FROM users ORDER BY created_at DESC";
$result = $conn->query($sql);
$users = [];

if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $users[] = $row;
    }
}

sendResponse("success", "Users fetched successfully", $users);
