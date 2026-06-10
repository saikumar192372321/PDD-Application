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
    $stmt = $conn->prepare("SELECT email, full_name as name, phone, address, is_admin FROM users WHERE email = :email");
    $stmt->execute([':email' => $userEmail]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        $user['is_admin'] = (bool)$user['is_admin'];
        echo json_encode(["status" => "success", "data" => $user]);
    } else {
        echo json_encode(["status" => "error", "message" => "User not found"]);
    }

} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
