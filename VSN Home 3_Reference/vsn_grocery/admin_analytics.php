<?php
// Backend/admin_analytics.php
// Real-time analytics for admin dashboard
include 'db_config.php';

$period = isset($_GET['period']) ? $_GET['period'] : 'weekly';

// ─── Revenue Over Time ───────────────────────────────────────────────────────
if ($period === 'daily') {
    $groupFormat = '%H:00';
    $dateFilter  = "DATE(date) = CURDATE()";
    $limit       = 24;
} elseif ($period === 'monthly') {
    $groupFormat = '%Y-%m-%d';
    $dateFilter  = "date >= DATE_SUB(NOW(), INTERVAL 30 DAY)";
    $limit       = 30;
} else {
    // weekly (default)
    $groupFormat = '%a';
    $dateFilter  = "date >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
    $limit       = 7;
}

$revenueSQL = "SELECT DATE_FORMAT(date, '$groupFormat') AS label, SUM(total) AS revenue
               FROM orders
               WHERE $dateFilter
               GROUP BY label
               ORDER BY MIN(date) ASC
               LIMIT $limit";

$revenueResult = $conn->query($revenueSQL);
$revenueData   = [];
while ($row = $revenueResult->fetch_assoc()) {
    $revenueData[] = ['label' => $row['label'], 'value' => (double)$row['revenue']];
}

// ─── Top Products by Qty Ordered ─────────────────────────────────────────────
// MariaDB 10.4 doesn't support JSON_TABLE, so we extract and sum via PHP.
$itemsSQL = "SELECT items FROM orders WHERE $dateFilter";
$itemsResult = $conn->query($itemsSQL);
$productData = [];
if ($itemsResult) {
    $productCounts = [];
    while ($row = $itemsResult->fetch_assoc()) {
        $items = json_decode($row['items'], true);
        if (is_array($items)) {
            foreach ($items as $item) {
                $name = isset($item['product']['name']) ? $item['product']['name'] : 'Unknown';
                $qty = isset($item['quantity']) ? (int)$item['quantity'] : 0;
                if (!isset($productCounts[$name])) {
                    $productCounts[$name] = 0;
                }
                $productCounts[$name] += $qty;
            }
        }
    }
    arsort($productCounts);
    $count = 0;
    foreach ($productCounts as $name => $qty) {
        if ($name) {
            $productData[] = ['label' => $name, 'value' => $qty];
            $count++;
            if ($count >= 8) break;
        }
    }
}

// ─── Order Status Distribution ───────────────────────────────────────────────
$statusSQL    = "SELECT status, COUNT(*) AS cnt FROM orders GROUP BY status";
$statusResult = $conn->query($statusSQL);
$statusData   = [];
while ($row = $statusResult->fetch_assoc()) {
    $statusData[] = ['label' => $row['status'], 'value' => (int)$row['cnt']];
}

// ─── Summary KPIs ────────────────────────────────────────────────────────────
$kpiSQL    = "SELECT
    COUNT(*) AS total_orders,
    SUM(total) AS total_revenue,
    SUM(discount_amount) AS total_discounts,
    SUM(coins_earned) AS total_coins,
    COUNT(DISTINCT user_email) AS ordering_customers
FROM orders WHERE $dateFilter";
$kpiResult = $conn->query($kpiSQL);
$kpi       = $kpiResult->fetch_assoc();

// Count total users
$userCountSQL = "SELECT COUNT(*) AS total_users FROM users";
$userCountResult = $conn->query($userCountSQL);
$userCountRow = $userCountResult ? $userCountResult->fetch_assoc() : ['total_users' => 0];

sendResponse("success", "Analytics fetched", [
    "revenue"    => $revenueData,
    "products"   => $productData,
    "statuses"   => $statusData,
    "kpi"        => [
        "totalOrders"      => (int)($kpi['total_orders'] ?? 0),
        "totalRevenue"     => (double)($kpi['total_revenue'] ?? 0),
        "totalDiscounts"   => (double)($kpi['total_discounts'] ?? 0),
        "totalCoins"       => (int)($kpi['total_coins'] ?? 0),
        "uniqueCustomers"  => (int)($userCountRow['total_users'] ?? 0)
    ]
]);
?>
