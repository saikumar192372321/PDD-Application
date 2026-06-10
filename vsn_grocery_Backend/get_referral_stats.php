<?php
// Backend/get_referral_stats.php
include 'db_config.php';

$email = isset($_GET['email']) ? trim($_GET['email']) : "";

if (empty($email)) {
    sendResponse("error", "Email is required");
}

// 1. Get user total coins and referral code
$stmt = $conn->prepare("SELECT coins, referral_code FROM users WHERE email = ?");
if (!$stmt) {
    sendResponse("error", "Database query preparation failed: " . $conn->error);
}
$stmt->bind_param("s", $email);
$stmt->execute();
$userRes = $stmt->get_result();

if (!$userRes || $userRes->num_rows == 0) {
    $stmt->close();
    sendResponse("error", "User not found");
}

$user = $userRes->fetch_assoc();
$stmt->close();

// 2. Count total referrals
$totalReferrals = 0;
$stmt2 = $conn->prepare("SELECT COUNT(*) as total FROM referrals WHERE referrer_email = ?");
if ($stmt2) {
    $stmt2->bind_param("s", $email);
    $stmt2->execute();
    $res2 = $stmt2->get_result();
    if ($res2 && $row = $res2->fetch_assoc()) {
        $totalReferrals = intval($row['total']);
    }
    $stmt2->close();
}

// 3. Get total earned from referrals
$totalEarned = 0;
$stmt3 = $conn->prepare("SELECT SUM(reward_amount) as total FROM referrals WHERE referrer_email = ?");
if ($stmt3) {
    $stmt3->bind_param("s", $email);
    $stmt3->execute();
    $res3 = $stmt3->get_result();
    if ($res3 && $row = $res3->fetch_assoc()) {
        $totalEarned = intval($row['total']);
    }
    $stmt3->close();
}

// 4. Get recent referrals list
$recentReferrals = [];
$stmt4 = $conn->prepare("SELECT r.referee_email, u.name, r.reward_amount, DATE_FORMAT(r.created_at, '%Y-%m-%dT%H:%i:%sZ') as created_at 
            FROM referrals r 
            JOIN users u ON r.referee_email = u.email 
            WHERE r.referrer_email = ? 
            ORDER BY r.created_at DESC LIMIT 10");
if ($stmt4) {
    $stmt4->bind_param("s", $email);
    $stmt4->execute();
    $res4 = $stmt4->get_result();
    while ($row = $res4->fetch_assoc()) {
        $recentReferrals[] = [
            "referee_email" => $row["referee_email"],
            "name" => $row["name"],
            "reward_amount" => intval($row["reward_amount"]),
            "created_at" => $row["created_at"]
        ];
    }
    $stmt4->close();
}

sendResponse("success", "Referral statistics retrieved", [
    "referral_code" => $user['referral_code'],
    "total_coins" => (int)$user['coins'],
    "total_referrals" => $totalReferrals,
    "total_earned" => $totalEarned,
    "recent_referrals" => $recentReferrals
]);
?>
