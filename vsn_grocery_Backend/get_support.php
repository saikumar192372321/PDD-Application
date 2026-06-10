<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$file = 'support_settings.json';
if(file_exists($file)) {
    echo file_get_contents($file);
} else {
    echo json_encode(["email" => "support@vsn-home.in", "whatsapp" => "+91 9059270899"]);
}
?>
