<?php
// Backend/update_db_v3_referral.php
// Run this file in your browser to update your database schema for the Referral System.

include 'db_config.php';

header('Content-Type: text/html');
echo "<html><body style='font-family: sans-serif; padding: 20px;'>";
echo "<h1>Referral System Database Update</h1>";

$queries = [
    // 1. Add coins column to users if not exists
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS coins INT DEFAULT 0",
    
    // 2. Add referral_code column to users if not exists
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_code VARCHAR(10) DEFAULT NULL",
    
    // 3. Add referred_by column to users if not exists (stores email of referrer)
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS referred_by VARCHAR(255) DEFAULT NULL",
    
    // 4. Add unique index to referral_code
    "ALTER TABLE users ADD UNIQUE INDEX IF NOT EXISTS (referral_code)",
    
    // 5. Create referrals tracking table
    "CREATE TABLE IF NOT EXISTS referrals (
        id INT AUTO_INCREMENT PRIMARY KEY,
        referrer_email VARCHAR(255) NOT NULL,
        referee_email VARCHAR(255) NOT NULL,
        reward_amount INT DEFAULT 50,
        status VARCHAR(50) DEFAULT 'completed',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY unique_referral (referee_email)
    )",
    
    // 6. Create settings entries if they don't exist
    "INSERT IGNORE INTO settings (`key`, `value`) VALUES ('referral_reward_coins', '50')",
    "INSERT IGNORE INTO settings (`key`, `value`) VALUES ('delivery_charge', '0')",
    "INSERT IGNORE INTO settings (`key`, `value`) VALUES ('free_delivery_threshold', '5000')",
    "INSERT IGNORE INTO settings (`key`, `value`) VALUES ('delivery_note', '')",
    "ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_charge DECIMAL(10, 2) DEFAULT 0.0"
];

foreach ($queries as $sql) {
    if ($conn->query($sql)) {
        echo "<p style='color:green;'>✅ SUCCESS: <code>$sql</code></p>";
    } else {
        echo "<p style='color:red;'>❌ ERROR: <code>$sql</code> - " . $conn->error . "</p>";
    }
}

// 7. Generate referral codes for existing users who don't have one
$res = $conn->query("SELECT email FROM users WHERE referral_code IS NULL");
if ($res && $res->num_rows > 0) {
    echo "<h2>Generating Referral Codes for existing users...</h2>";
    while ($user = $res->fetch_assoc()) {
        $email = $user['email'];
        // Generate a simple code: VSN + first 3 of name + random
        $code = "VSN" . strtoupper(substr(md5($email), 0, 5));
        $updateSql = "UPDATE users SET referral_code = '$code' WHERE email = '$email'";
        if ($conn->query($updateSql)) {
            echo "<p>Generated code <b>$code</b> for $email</p>";
        }
    }
}

echo "<hr><p><b>Database update complete.</b> Your app is now ready for the Referral System!</p>";
echo "</body></html>";
?>
