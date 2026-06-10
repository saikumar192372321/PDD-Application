<?php
// Backend/get_referral_stats.php
error_reporting(0);
include 'db_config.php';

$email = isset($_GET['email']) ? $conn->real_escape_string($_GET['email']) : "";

if (empty($email)) {
    sendResponse("error", "Email is required");
}

// 1. Get user total coins and referral code
$userSql = "SELECT coins, referral_code FROM users WHERE email = '$email'";
$userRes = $conn->query($userSql);

if (!$userRes || $userRes->num_rows == 0) {
    sendResponse("error", "User not found");
}

$user = $userRes->fetch_assoc();

// 2. Count total referrals
$refCountSql = "SELECT COUNT(*) as total FROM referrals WHERE referrer_email = '$email'";
$refCountRes = $conn->query($refCountSql);
$totalReferrals = ($refCountRes) ? intval($refCountRes->fetch_assoc()['total']) : 0;

// 3. Get total earned from referrals
$earnedSql = "SELECT SUM(reward_amount) as total FROM referrals WHERE referrer_email = '$email'";
$earnedRes = $conn->query($earnedSql);
$totalEarned = ($earnedRes) ? intval($earnedRes->fetch_assoc()['total']) : 0;

// 4. Get recent referrals list
$listSql = "SELECT r.referee_email, u.name, r.reward_amount, r.created_at 
            FROM referrals r 
            JOIN users u ON r.referee_email = u.email 
            WHERE r.referrer_email = '$email' 
            ORDER BY r.created_at DESC LIMIT 10";
$listRes = $conn->query($listSql);
$recentReferrals = [];
while ($row = $listRes->fetch_assoc()) {
    $recentReferrals[] = $row;
}

sendResponse("success", "Referral statistics retrieved", [
    "referral_code" => $user['referral_code'],
    "total_coins" => (int)$user['coins'],
    "total_referrals" => $totalReferrals,
    "total_earned" => $totalEarned,
    "recent_referrals" => $recentReferrals
]);
?>
