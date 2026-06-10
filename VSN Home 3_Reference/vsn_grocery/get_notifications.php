<?php
// get_notifications.php
// Fetches notifications for a given user email OR all broadcast notifications.
// Query: ?userEmail=user@example.com   => returns notifications for that user + "all" broadcasts
// Query: ?userEmail=all                 => returns all notifications (admin view)

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ── DB Config ─────────────────────────────────────────────────────────────────
$host = "localhost";
$db   = "vsn_grocery";
$user = "root";
$pass = "";

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    echo json_encode(["status" => "error", "message" => "DB connection failed: " . $conn->connect_error]);
    exit;
}

// ── Auto-create table if not exists ──────────────────────────────────────────
$conn->query("
    CREATE TABLE IF NOT EXISTS notifications (
        id VARCHAR(36) PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        type ENUM('general','offer','order') DEFAULT 'general',
        user_email VARCHAR(255) DEFAULT 'all',
        is_read TINYINT(1) DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
");

// ── Get User Email ─────────────────────────────────────────────────────────────
$userEmail = isset($_GET['userEmail']) ? trim($_GET['userEmail']) : "guest";

// ── Query ─────────────────────────────────────────────────────────────────────
if ($userEmail === "all") {
    // Admin view: return everything
    $result = $conn->query("SELECT id, title, message, type, userEmail, isRead, DATE_FORMAT(date, '%Y-%m-%dT%H:%i:%sZ') as date FROM notifications ORDER BY date DESC LIMIT 100");
} else {
    // User view: return notifications addressed to "all" OR specifically to this user
    $stmt = $conn->prepare("SELECT id, title, message, type, userEmail, isRead, DATE_FORMAT(date, '%Y-%m-%dT%H:%i:%sZ') as date FROM notifications WHERE userEmail = 'all' OR userEmail = ? ORDER BY date DESC LIMIT 100");
    $stmt->bind_param("s", $userEmail);
    $stmt->execute();
    $result = $stmt->get_result();
}

$notifications = [];
while ($row = $result->fetch_assoc()) {
    $notifications[] = [
        "id"         => $row["id"],
        "title"      => $row["title"],
        "message"    => $row["message"],
        "type"       => $row["type"],
        "userEmail"  => $row["userEmail"],
        "isRead"     => (bool)$row["isRead"],
        "date"       => $row["date"]
    ];
}

echo json_encode(["status" => "success", "data" => $notifications]);

$conn->close();
?>
