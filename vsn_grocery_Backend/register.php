<?php
// ============================================================
// register.php — VSN Home New User Registration
// Method: POST | Content-Type: application/json
// Body: { name, email, password, phone, address, [business_name,
//         gstin, upi_id, profile_image, referral_code] }
// ============================================================
require_once 'db_config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse("error", "Method not allowed. Use POST.", null, 405);
}

$input_raw = file_get_contents("php://input");
$input = json_decode($input_raw, true);

// Debug logging removed for security

// ─── Required Fields ─────────────────────────────────────────
$name     = trim($input['name'] ?? '');
$email    = strtolower(trim($input['email'] ?? ''));
$password = $input['password'] ?? '';
$phone    = trim($input['phone'] ?? '');
$address  = trim($input['address'] ?? '');

if (empty($name) || empty($email) || empty($password) || empty($phone)) {
    sendResponse("error", "Name, email, password, and phone are required.", null, 400);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    sendResponse("error", "Invalid email format.", null, 400);
}

if (strlen($password) < 6) {
    sendResponse("error", "Password must be at least 6 characters.", null, 400);
}

// ─── Optional Fields ─────────────────────────────────────────
$business_name       = trim($input['business_name'] ?? 'N/A');
$gstin               = trim($input['gstin'] ?? 'N/A');
$upi_id              = trim($input['upi_id'] ?? '') ?: null;
$profile_image       = $input['profile_image'] ?? null;
$referral_code_input = trim($input['referral_code'] ?? '') ?: null;

// ─── Duplicate Email Check ────────────────────────────────────
$check = $conn->prepare("SELECT id FROM users WHERE email = ? LIMIT 1");
$check->bind_param("s", $email);
$check->execute();
$check->store_result();
if ($check->num_rows > 0) {
    sendResponse("error", "This email is already registered. Please log in.", null, 409);
}
$check->close();

// ─── Generate Unique Referral Code ───────────────────────────
$new_referral_code = "VSN" . strtoupper(substr(md5($email . time()), 0, 5));

// ─── Referral Logic ──────────────────────────────────────────
$referrer_email = null;
$initial_coins  = 0;

if ($referral_code_input) {
    $refStmt = $conn->prepare("SELECT email FROM users WHERE referral_code = ? LIMIT 1");
    $refStmt->bind_param("s", $referral_code_input);
    $refStmt->execute();
    $refRes = $refStmt->get_result();
    if ($refRes->num_rows > 0) {
        $referrer_email = $refRes->fetch_assoc()['email'];
        $rewardRow = $conn->query("SELECT value FROM settings WHERE `key` = 'referral_reward_coins' LIMIT 1");
        $rewardAmount = ($rewardRow && $rewardRow->num_rows > 0)
            ? (int)$rewardRow->fetch_assoc()['value']
            : 50;
        $initial_coins = $rewardAmount;
    }
    $refStmt->close();
}

// ─── Hash Password & Insert User ─────────────────────────────
$hashedPassword = password_hash($password, PASSWORD_BCRYPT);

$stmt = $conn->prepare(
    "INSERT INTO users (name, email, password, phone, address, business_name, gstin,
     upi_id, profile_image, referral_code, referred_by, coins)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
);
$stmt->bind_param(
    "sssssssssssi",
    $name, $email, $hashedPassword, $phone, $address,
    $business_name, $gstin, $upi_id, $profile_image,
    $new_referral_code, $referrer_email, $initial_coins
);

if ($stmt->execute()) {
    // Reward the referrer using prepared statements (prevent SQL injection)
    if ($referrer_email && isset($rewardAmount)) {
        $rewardStmt = $conn->prepare("UPDATE users SET coins = coins + ? WHERE email = ?");
        $rewardStmt->bind_param("is", $rewardAmount, $referrer_email);
        $rewardStmt->execute();
        $rewardStmt->close();

        $refInsert = $conn->prepare(
            "INSERT INTO referrals (referrer_email, referee_email, reward_amount)
             VALUES (?, ?, ?)"
        );
        $refInsert->bind_param("ssi", $referrer_email, $email, $rewardAmount);
        $refInsert->execute();
        $refInsert->close();
    }
    sendResponse("success", "Registration successful! Welcome to VSN Home.", [
        "referral_code" => $new_referral_code,
        "coins"         => $initial_coins
    ]);
} else {
    sendResponse("error", "Registration failed: " . $stmt->error, null, 500);
}

$stmt->close();
$conn->close();
?>
