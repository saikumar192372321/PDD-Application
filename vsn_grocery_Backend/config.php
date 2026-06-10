<?php
// config.php - Legacy wrapper for db_config.php
require_once "db_config.php";

// Map PDO connection for scripts expecting locally defined $conn as PDO
if (!isset($conn_pdo) && isset($pdo)) {
    $conn = $pdo; 
}
?>
