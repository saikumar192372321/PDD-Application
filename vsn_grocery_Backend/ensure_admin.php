<?php
// Backend/ensure_admin.php
// Run this file in your browser (e.g., http://localhost/Backend/ensure_admin.php) 
// to ensure the admin user exists in your database.

include 'db_config.php';

$email = 'sai1@vsn.com';
$password = 'sai1@141';

$sql = "INSERT INTO admins (email, password) VALUES ('$email', '$password') 
        ON DUPLICATE KEY UPDATE password = '$password'";

if ($conn->query($sql)) {
    echo "<h1>Success</h1>";
    echo "<p>Admin user <b>$email</b> has been ensured in the database.</p>";
    echo "<p>Password is: <b>$password</b></p>";
    echo "<hr>";
    echo "<p>Try logging in again in the app.</p>";
} else {
    echo "<h1>Error</h1>";
    echo "<p>Failed to update database: " . $conn->error . "</p>";
}
?>
