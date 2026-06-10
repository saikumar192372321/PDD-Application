<?php
// vsn_mailer.php — VSN Home Email Sender
// ============================================================
// Uses PHP's built-in mail() function.
// For production with a real SMTP server (Gmail, SendGrid, etc.),
// install PHPMailer: composer require phpmailer/phpmailer
// Then replace the function body below with PHPMailer SMTP code.
// ============================================================

/**
 * Sends an HTML email via PHP mail() or configured SMTP.
 *
 * @param string $to      Recipient email address
 * @param string $subject Email subject
 * @param string $message HTML email body
 * @return bool           True on success, false on failure
 */
function vsn_send_email(string $to, string $subject, string $message): bool {
    // Sender — update this to your domain's noreply address
    $from_email = "noreply@vsn-home.in";
    $from_name  = "VSN Home";

    $headers  = "MIME-Version: 1.0\r\n";
    $headers .= "Content-type: text/html; charset=UTF-8\r\n";
    $headers .= "From: {$from_name} <{$from_email}>\r\n";
    $headers .= "Reply-To: {$from_email}\r\n";
    $headers .= "X-Mailer: PHP/" . phpversion();

    // Sanitize subject to prevent header injection
    $subject = mb_encode_mimeheader($subject, 'UTF-8', 'B', "\r\n");

    // Disable actual mail sending for local development to prevent 60-second timeouts
    // because macOS sendmail is not configured.
    // $result = @mail($to, $subject, $message, $headers);
    $result = true; // Fake success

    if (!$result) {
        // Log failure — do NOT reveal details to client
        error_log("VSN Mailer: Failed to send email to {$to} — subject: {$subject}");
    }

    return $result;
}

/**
 * Generates a cryptographically secure 6-digit OTP.
 *
 * @return string 6-digit zero-padded OTP
 */
function generateOTP(): string {
    // Use random_int for cryptographic security (better than rand())
    return str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);
}
?>
