<?php
// ============================================================
// place_order.php — VSN Home Place Order
// Method: POST | Content-Type: application/json
// ============================================================
require_once 'db_config.php';
require_once 'vsn_mailer.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse("error", "Method not allowed. Use POST.", null, 405);
}

$data = json_decode(file_get_contents("php://input"), true);

if (!$data || !isset($data['id'], $data['items'], $data['total'], $data['userEmail'])) {
    sendResponse("error", "Invalid order payload. Required: id, items, total, userEmail.", null, 400);
}

// ─── Extract Fields ──────────────────────────────────────────
$id              = $data['id'] ?? '';
$items_json      = json_encode($data['items'] ?? []);
$total           = (float)($data['total'] ?? 0);
$status          = $data['status'] ?? 'Pending';
$payment_method  = $data['paymentMethod'] ?? 'Cash on Delivery';
$payment_status  = $data['paymentStatus'] ?? 'Pending';
$address         = $data['address'] ?? '';
$user_email      = strtolower(trim($data['userEmail'] ?? ''));
$requires_gst    = !empty($data['requiresGSTBill']) ? 1 : 0;
$business_name   = !empty($data['businessName'])   ? trim($data['businessName'])   : null;
$gst_number      = !empty($data['gstNumber'])       ? trim($data['gstNumber'])      : null;
$offer_title     = !empty($data['appliedOfferTitle']) ? trim($data['appliedOfferTitle']) : null;
$coins_earned    = (int)($data['coinsEarned'] ?? 0);
$discount_amount = (float)($data['discountAmount'] ?? 0);
$delivery_charge = (float)($data['deliveryCharge'] ?? 0);

// ─── Insert Order with Prepared Statement ─────────────────────
$stmt = $conn->prepare("
    INSERT INTO orders (
        id, date, items, total, status, payment_status, payment_method, 
        address, user_email, discount_amount, delivery_charge, 
        applied_offer_title, coins_earned, requires_gst, business_name, gst_number
    ) VALUES (?, NOW(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
");

$stmt->bind_param(
    "ssdsssssddsiiss",
    $id, $items_json, $total, $status, $payment_status, $payment_method,
    $address, $user_email, $discount_amount, $delivery_charge,
    $offer_title, $coins_earned, $requires_gst, $business_name, $gst_number
);

if (!$stmt->execute()) {
    sendResponse("error", "Order failed: " . $stmt->error, null, 500);
}
$stmt->close();


// ─── Credit Coins to User ─────────────────────────────────────
if ($coins_earned > 0) {
    $coinsStmt = $conn->prepare("UPDATE users SET coins = coins + ? WHERE email = ?");
    $coinsStmt->bind_param("is", $coins_earned, $user_email);
    $coinsStmt->execute();
    $coinsStmt->close();
}

// ─── Send Confirmation Email ──────────────────────────────────
$subject    = "✅ Order Confirmed: #$id";
$items_html = "<ul style='margin:0;padding-left:20px'>";
foreach ($data['items'] as $item) {
    $p           = $item['product'];
    $pName       = htmlspecialchars($p['name'] ?? 'Product');
    $pPrice      = number_format((float)($p['wholesalePrice'] ?? 0), 2);
    $qty         = (int)($item['quantity'] ?? 1);
    $lineTotal   = number_format($qty * (float)($p['wholesalePrice'] ?? 0), 2);
    $items_html .= "<li><b>$pName</b> × $qty  — ₹$lineTotal</li>";
}
$items_html .= "</ul>";

$email_body = "
<div style='font-family:sans-serif;max-width:600px;margin:auto;border:1px solid #e0e0e0;border-radius:8px;overflow:hidden'>
  <div style='background:#0a72d4;padding:24px;text-align:center'>
    <h1 style='color:#fff;margin:0;font-size:22px'>VSN Home</h1>
    <p style='color:#d0e8ff;margin:4px 0 0'>Order Confirmed 🎉</p>
  </div>
  <div style='padding:24px'>
    <p>Hi there,</p>
    <p>Your order <b>#$id</b> has been received and is being processed.</p>
    <hr style='border:none;border-top:1px solid #eee;margin:16px 0'>
    <h3 style='margin:0 0 8px'>Items Ordered</h3>
    $items_html
    <hr style='border:none;border-top:1px solid #eee;margin:16px 0'>
    <table style='width:100%;font-size:14px'>
      <tr><td>Subtotal</td><td align='right'>₹" . number_format($total + $discount_amount - $delivery_charge, 2) . "</td></tr>
      " . ($discount_amount > 0 ? "<tr><td>Discount</td><td align='right' style='color:green'>-₹" . number_format($discount_amount, 2) . "</td></tr>" : "") . "
      <tr><td>Delivery</td><td align='right'>₹" . number_format($delivery_charge, 2) . "</td></tr>
      <tr><td><b>Total</b></td><td align='right'><b>₹" . number_format($total, 2) . "</b></td></tr>
    </table>
    <p style='margin-top:12px'><b>Payment:</b> $payment_method</p>
    <p><b>Delivery Address:</b> $address</p>
    " . ($coins_earned > 0 ? "<p style='color:#0a72d4'>🪙 You earned <b>$coins_earned coins</b> on this order!</p>" : "") . "
    <hr style='border:none;border-top:1px solid #eee;margin:16px 0'>
    <p style='color:#666;font-size:13px'>We'll notify you when your order is out for delivery.<br>— VSN Home Team</p>
  </div>
</div>";

vsn_send_email($user_email, $subject, $email_body);

sendResponse("success", "Order #$id placed successfully. Confirmation email sent.");
?>
