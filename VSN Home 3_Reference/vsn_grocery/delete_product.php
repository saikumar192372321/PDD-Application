<?php
// Backend/delete_product.php
include 'db_config.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!$data || !isset($data['id'])) {
    sendResponse("error", "Target identifier not found");
}

$id = $conn->real_escape_string($data['id']);

$sql = "DELETE FROM products WHERE id = '$id'";

if ($conn->query($sql)) {
    sendResponse("success", "Product successfully removed from global catalog");
} else {
    sendResponse("error", "Removal failed: " . $conn->error);
}
?>
