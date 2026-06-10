<?php
// Backend/delete_offer.php
include 'db_config.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!$data || !isset($data['id'])) {
    sendResponse("error", "Offer identifier missing");
}

$id = $conn->real_escape_string($data['id']);

$sql = "DELETE FROM offers WHERE id = '$id'";

if ($conn->query($sql)) {
    sendResponse("success", "Bulk offer deactivated and removed from system");
} else {
    sendResponse("error", "Deactivation failed: " . $conn->error);
}
?>
