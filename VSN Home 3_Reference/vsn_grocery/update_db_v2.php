<?php
// Backend/update_db_v2.php
// Run this file in your browser to update your database schema for the new UPI ID columns.

include 'db_config.php';

echo "<h1>Database Update Utility</h1>";

$queries = [
    "ALTER TABLE admins ADD COLUMN IF NOT EXISTS upi_id VARCHAR(255) DEFAULT NULL",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS upi_id VARCHAR(255) DEFAULT NULL",
    "INSERT IGNORE INTO settings (`key`, `value`) VALUES ('upi_id', 'vsnwholesale@upi')"
];

foreach ($queries as $sql) {
    if ($conn->query($sql)) {
        echo "<p style='color:green;'>SUCCESS: Executed query: <code>$sql</code></p>";
    } else {
        echo "<p style='color:red;'>ERROR: Failed query: <code>$sql</code> - " . $conn->error . "</p>";
    }
}

echo "<hr><p>Database update complete. Try enrolling a new admin again in the app.</p>";
?>
