<?php
// ============================================================
// db_config.php — VSN Home Unified DB Configuration
// Supports: MySQLi + PDO | CORS | JSON Headers
// ============================================================

error_reporting(E_ALL);
ini_set('display_errors', 0); // Errors go to log, not output

// --- CORS Headers ---
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// --- Database Configuration ---
define('DB_HOST', '127.0.0.1');
define('DB_PORT', 3307);
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_NAME', 'vsn_grocery');

// ─── 1. MySQLi Connection ────────────────────────────────────
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT);

if ($conn->connect_error) {
    http_response_code(503);
    echo json_encode([
        "status"  => "error",
        "message" => "Database connection failed. Please try again later.",
        "debug"   => $conn->connect_error  // Remove this line in production
    ]);
    exit();
}

$conn->set_charset("utf8mb4");

// ─── 2. PDO Connection ───────────────────────────────────────
try {
    $dsn = "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME . ";charset=utf8mb4";
    $pdo = new PDO($dsn, DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
} catch (PDOException $e) {
    // PDO failure is non-fatal if MySQLi is working
    // Log silently
    error_log("VSN PDO Error: " . $e->getMessage());
}

// ─── Helper: Standardized JSON Response ──────────────────────
function sendResponse(string $status, string $message, $data = null, int $httpCode = 200): void {
    http_response_code($httpCode);
    $res = [
        "status"  => $status,
        "message" => $message,
    ];
    if ($data !== null) {
        $res["data"] = $data;
    }
    echo json_encode($res, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit();
}

// ─── Helper: Safe Input Sanitizer ────────────────────────────
function sanitize(mysqli $conn, string $val): string {
    return $conn->real_escape_string(trim($val));
}
?>
