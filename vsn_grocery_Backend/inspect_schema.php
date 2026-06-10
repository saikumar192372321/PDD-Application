<?php
include 'db_config.php';

$tables = ['users', 'orders'];
$schema = [];

foreach ($tables as $table) {
    $res = $conn->query("DESCRIBE $table");
    $columns = [];
    while ($row = $res->fetch_assoc()) {
        $columns[] = $row;
    }
    $schema[$table] = $columns;
}

echo json_encode($schema, JSON_PRETTY_PRINT);
?>
