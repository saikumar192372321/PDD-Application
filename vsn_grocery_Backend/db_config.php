<?php
// ============================================================
// db_config.php — VSN Home Unified DB Configuration
// Supports: MySQLi + PDO | CORS | JSON Headers
// ============================================================

error_reporting(0);             // Suppress ALL PHP warnings/notices — prevent JSON corruption
ini_set('display_errors', 0);  // Never output errors to response
ini_set('display_startup_errors', 0);
ob_start();                     // Buffer output — ensures clean JSON even if warnings slip through

// --- CORS Headers ---
// Whitelist of allowed origins (e.g., local development and production web app)
$allowed_origins = [
    "http://localhost",
    "http://localhost:5500",
    "http://localhost:5501",
    "http://127.0.0.1",
    "http://127.0.0.1:5500",
    "http://localhost:3000",
    "http://localhost:8080",
    "https://vsnhome.com"
];

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
$is_local_origin = false;
if ($origin) {
    $parsed_url = parse_url($origin);
    $host = $parsed_url['host'] ?? '';
    // Check if localhost, 127.0.0.1, *.local, or private IP ranges (192.168.x.x, 172.16-31.x.x, 10.x.x.x)
    if (
        $host === 'localhost' || 
        $host === '127.0.0.1' || 
        substr($host, -6) === '.local' ||
        preg_match('/^(192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|10\.)/', $host)
    ) {
        $is_local_origin = true;
    }
}

if (in_array($origin, $allowed_origins) || $is_local_origin) {
    header("Access-Control-Allow-Origin: " . $origin);
} else {
    // Fallback/Default secure header (avoiding wildcard * wildcard check)
    header("Access-Control-Allow-Origin: https://vsnhome.com");
}

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Max-Age: 86400");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// --- Load Environment Variables ---
// In production, set these in .env or server environment
$env = [];
if (file_exists(__DIR__ . '/.env')) {
    $lines = file(__DIR__ . '/.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos($line, '#') === 0) continue; // Skip comments
        if (strpos($line, '=') === false) continue;
        [$key, $value] = explode('=', $line, 2);
        $env[trim($key)] = trim($value);
    }
}

// --- Database Configuration ---
// Use environment variables; fallback to defaults for development only
define('DB_HOST', $env['DB_HOST'] ?? $_ENV['DB_HOST'] ?? '127.0.0.1');
define('DB_PORT', (int)($env['DB_PORT'] ?? $_ENV['DB_PORT'] ?? 3307)); // XAMPP default=3307 | Production MySQL=3306
define('DB_USER', $env['DB_USER'] ?? $_ENV['DB_USER'] ?? 'root');
define('DB_PASS', $env['DB_PASS'] ?? $_ENV['DB_PASS'] ?? '');
define('DB_NAME', $env['DB_NAME'] ?? $_ENV['DB_NAME'] ?? 'vsn_grocery');

// ─── 1. MySQLi Connection ────────────────────────────────────
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT);

if ($conn->connect_error) {
    http_response_code(503);
    // Log the error securely — never expose to client in production
    error_log("VSN DB Connect Error: " . $conn->connect_error);
    echo json_encode([
        "status"  => "error",
        "message" => "Database connection failed. Please try again later."
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
    ob_clean(); // Discard any accidental output before our JSON
    http_response_code($httpCode);
    $res = [
        "status"  => $status,
        "message" => $message,
    ];
    if ($data !== null) {
        $res["data"] = $data;
    }
    echo json_encode($res, JSON_UNESCAPED_UNICODE);
    exit();
}

// ─── Helper: Safe Input Sanitizer ────────────────────────────
function sanitize(mysqli $conn, string $val): string {
    return $conn->real_escape_string(trim($val));
}
?>
