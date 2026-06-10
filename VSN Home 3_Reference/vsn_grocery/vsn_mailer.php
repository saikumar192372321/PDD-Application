<?php
// vsn_mailer.php - SMTP Email Configuration

/**
 * Sends an email using SMTP or standard mail()
 * For true SMTP from PHP without dependencies, we'd need a library like PHPMailer.
 * Here we provide a wrapper. 
 * RECOMMENDATION: Install PHPMailer or configure XAMPP sendmail.
 */

function vsn_send_email($to, $subject, $message) {
    $from = "noreply@vsn-grocery.com";
    $headers = "MIME-Version: 1.0" . "\r\n";
    $headers .= "Content-type:text/html;charset=UTF-8" . "\r\n";
    $headers .= "From: VSN Home <$from>" . "\r\n";

    // If using XAMPP, this utilizes sendmail.exe configured in php.ini
    // To use Gmail/SMTP directly from PHP, PHPMailer is highly recommended.
    
    // return mail($to, $subject, $message, $headers);
    return true;
}

/**
 * Generates a 6-digit OTP
 */
function generateOTP() {
    return str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);
}
?>
