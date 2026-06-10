<?php
include 'db_config.php';
$res = $conn->query("SELECT `key`, LENGTH(value) as len FROM settings");
$out = [];
while($row = $res->fetch_assoc()) {
    $out[] = $row;
}
echo json_encode($out);
?>
