<?php
// get_notifications.php
// Fetches notifications for a given user email OR all broadcast notifications.
// Query: ?userEmail=user@example.com   => returns notifications for that user + "all" broadcasts
// Query: ?userEmail=all                 => returns all notifications (admin view)

include 'db_config.php';

// ── Get User Email ─────────────────────────────────────────────────────────────
$userEmail = isset($_GET['userEmail']) ? trim($_GET['userEmail']) : "guest";

// ── Query ─────────────────────────────────────────────────────────────────────
if ($userEmail === "all") {
    // Admin view: return everything
    $result = $conn->query("SELECT id, title, message, type, userEmail, isRead, DATE_FORMAT(date, '%Y-%m-%dT%H:%i:%sZ') as date FROM notifications ORDER BY date DESC LIMIT 100");
} else {
    // User view: return notifications addressed to "all" OR specifically to this user
    $stmt = $conn->prepare("SELECT id, title, message, type, userEmail, isRead, DATE_FORMAT(date, '%Y-%m-%dT%H:%i:%sZ') as date FROM notifications WHERE userEmail = 'all' OR userEmail = ? ORDER BY date DESC LIMIT 100");
    if ($stmt) {
        $stmt->bind_param("s", $userEmail);
        $stmt->execute();
        $result = $stmt->get_result();
    } else {
        sendResponse("error", "Failed to prepare query: " . $conn->error);
    }
}

$notifications = [];
if ($result) {
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
}

if (isset($stmt)) {
    $stmt->close();
}

sendResponse("success", "Notifications retrieved successfully", $notifications);
?>
