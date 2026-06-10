<?php
// Backend/delete_product.php
require_once 'db_config.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!$data || !isset($data['id'])) {
    sendResponse("error", "Target identifier not found", null, 400);
}

$id = $data['id'];

$stmt = $conn->prepare("DELETE FROM products WHERE id = ?");
$stmt->bind_param("s", $id);

if ($stmt->execute()) {
    sendResponse("success", "Product successfully removed from global catalog");
} else {
    sendResponse("error", "Removal failed: " . $stmt->error, null, 500);
}

$stmt->close();
$conn->close();
?>

