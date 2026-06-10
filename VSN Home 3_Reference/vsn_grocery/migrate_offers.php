<?php
require_once "config.php";
try {
    $conn->exec("ALTER TABLE bulk_offers ADD COLUMN offer_uuid VARCHAR(50) UNIQUE AFTER id");
    echo "Success: offer_uuid added to bulk_offers";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
?>
