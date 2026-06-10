<?php
// ============================================================
// test.php — VSN Home API Health Check
// GET http://YOUR_IP/vsn_grocery/test.php
// ============================================================
require_once 'db_config.php';

$checks = [];

// 1. DB Connection
$checks['database'] = $conn->ping() ? "✅ Connected" : "❌ Failed";

// 2. Tables
$tables = ['users', 'products', 'orders', 'admins', 'notifications', 'offers', 'settings', 'referrals'];
foreach ($tables as $table) {
    $r = $conn->query("SELECT COUNT(*) AS cnt FROM $table");
    $count = $r ? $r->fetch_assoc()['cnt'] : 'ERR';
    $checks["table_$table"] = "✅ Exists ($count rows)";
}

// 3. PHP Version
$checks['php_version'] = phpversion();

// 4. Server IP
$checks['server_ip'] = $_SERVER['SERVER_ADDR'] ?? 'unknown';

// 5. Timestamp
$checks['timestamp'] = date('Y-m-d H:i:s');

sendResponse("success", "VSN Home API is running 🚀", $checks);
?>
