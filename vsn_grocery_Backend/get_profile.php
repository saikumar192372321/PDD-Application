<?php
// get_profile.php - Fetch user profile details
header("Content-Type: application/json");
require_once "config.php";

$userEmail = $_GET['email'] ?? null;

if (!$userEmail) {
    echo json_encode(["status" => "error", "message" => "Email required"]);
    exit;
}

try {
    // 1. Try to find in users
    $stmt = $conn->prepare("SELECT email, name, phone, address, business_name, gstin, upi_id, profile_image, coins, referral_code, referred_by FROM users WHERE email = :email");
    $stmt->execute([':email' => $userEmail]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        $user['is_admin'] = false;
        $user['coins'] = (int)($user['coins'] ?? 0);
        echo json_encode(["status" => "success", "data" => $user]);
        exit;
    }

    // 2. Try to find in admins
    $stmtAdmin = $conn->prepare("SELECT email, upi_id FROM admins WHERE email = :email");
    $stmtAdmin->execute([':email' => $userEmail]);
    $admin = $stmtAdmin->fetch(PDO::FETCH_ASSOC);

    if ($admin) {
        $admin['is_admin'] = true;
        // Provide defaults for admin so profile page doesn't crash on undefined fields
        $admin['name'] = 'Admin User';
        $admin['phone'] = '';
        $admin['address'] = '';
        $admin['business_name'] = 'VSN Admin';
        $admin['gstin'] = 'N/A';
        $admin['coins'] = 0;
        echo json_encode(["status" => "success", "data" => $admin]);
        exit;
    }

    echo json_encode(["status" => "error", "message" => "User not found"]);

} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
