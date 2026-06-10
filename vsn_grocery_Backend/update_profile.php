<?php
// ============================================================
// update_profile.php — VSN Home Update User Profile Details
// Method: POST | Content-Type: application/json
// Body: { email, name, phone, address, business_name, gstin, upi_id }
// ============================================================
require_once 'db_config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse("error", "Method not allowed. Use POST.", null, 405);
}

$input = json_decode(file_get_contents("php://input"), true);

$email = strtolower(trim($input['email'] ?? ''));
if (empty($email)) {
    sendResponse("error", "Email is required.", null, 400);
}

// ─── Fields to Update ────────────────────────────────────────
$name          = trim($input['name'] ?? '');
$phone         = trim($input['phone'] ?? '');
$address       = trim($input['address'] ?? '');
$business_name = trim($input['business_name'] ?? 'N/A');
$gstin         = trim($input['gstin'] ?? 'N/A');
$upi_id        = trim($input['upi_id'] ?? '') ?: null;

if (empty($name) || empty($phone)) {
    sendResponse("error", "Name and phone are required.", null, 400);
}

// ─── Update Query ────────────────────────────────────────────
$stmt = $conn->prepare(
    "UPDATE users SET name = ?, phone = ?, address = ?, business_name = ?, gstin = ?, upi_id = ? WHERE email = ?"
);
$stmt->bind_param("sssssss", $name, $phone, $address, $business_name, $gstin, $upi_id, $email);

if ($stmt->execute()) {
    // Return updated details
    sendResponse("success", "Profile updated successfully.", [
        "email"         => $email,
        "name"          => $name,
        "phone"         => $phone,
        "address"       => $address,
        "business_name" => $business_name,
        "gstin"         => $gstin,
        "upi_id"        => $upi_id
    ]);
} else {
    sendResponse("error", "Failed to update profile: " . $conn->error, null, 500);
}
$stmt->close();
?>
