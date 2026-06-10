/**
 * VSN Home – Deployment Verification Dashboard
 * Client-side security checks simulator
 */

// ============================================================
// Check Definitions (mirrors verify-deployment.sh)
// ============================================================

const CHECKS = [
    {
        id: 'force-unwrap',
        number: 1,
        title: 'Force Unwrap Safety',
        description: 'Ensure NumberFormatter force unwrap is removed from Models.swift',
        category: 'iOS Security',
        file: 'VSN Home/Shared/Models.swift',
        subChecks: [
            {
                label: 'NumberFormatter force unwrap removed',
                type: 'not-contains',
                pattern: 'retailPrice))!',
            },
        ],
    },
    {
        id: 'sql-injection',
        number: 2,
        title: 'SQL Injection Prevention',
        description: 'Verify get_products.php uses prepared statements and no raw SQL injection vectors',
        category: 'Backend Security',
        file: 'vsn_grocery/get_products.php',
        subChecks: [
            {
                label: 'Uses prepared statements',
                type: 'contains',
                pattern: 'prepare',
            },
            {
                label: 'SQL injection pattern removed',
                type: 'not-contains',
                pattern: "JSON_EXTRACT(details, '$.category')",
            },
        ],
    },
    {
        id: 'db-credentials',
        number: 3,
        title: 'Database Credentials Security',
        description: 'Confirm DB credentials are loaded from .env and not hardcoded',
        category: 'Backend Security',
        file: 'vsn_grocery/db_config.php',
        subChecks: [
            {
                label: 'DB config loads from .env',
                type: 'contains',
                pattern: "$env['DB_USER']",
            },
            {
                label: 'Hardcoded DB credentials removed',
                type: 'not-contains',
                pattern: "define('DB_USER', 'root');",
            },
        ],
    },
    {
        id: 'cors-protection',
        number: 4,
        title: 'CORS Protection',
        description: 'Ensure CORS whitelist is implemented and wildcard origin removed',
        category: 'Backend Security',
        file: 'vsn_grocery/db_config.php',
        subChecks: [
            {
                label: 'CORS whitelist implemented',
                type: 'contains',
                pattern: 'allowed_origins',
            },
            {
                label: 'CORS wildcard removed',
                type: 'not-contains',
                pattern: 'Access-Control-Allow-Origin: *',
            },
        ],
    },
    {
        id: 'admin-password',
        number: 5,
        title: 'Admin Password Security',
        description: 'Verify admin login uses password_verify and not plain-text comparison',
        category: 'Authentication',
        file: 'vsn_grocery/admin_login.php',
        subChecks: [
            {
                label: 'Uses password_verify',
                type: 'contains',
                pattern: 'password_verify',
            },
            {
                label: 'Plain-text comparison removed',
                type: 'not-contains',
                pattern: 'stored === $password',
            },
        ],
    },
    {
        id: 'razorpay-key',
        number: 6,
        title: 'Razorpay Key Security',
        description: 'Ensure Razorpay key is not stored in UserDefaults',
        category: 'iOS Security',
        file: 'VSN Home/Shared/APIConfig.swift',
        subChecks: [
            {
                label: 'Razorpay key removed from UserDefaults',
                type: 'not-contains',
                pattern: 'UserDefaults.standard.*razorpay',
            },
        ],
    },
    {
        id: 'admin-credentials',
        number: 7,
        title: 'Admin Credential Storage',
        description: 'Confirm admin credentials are not stored in UserDefaults',
        category: 'iOS Security',
        file: 'VSN Home/Admin/AdminLoginView.swift',
        subChecks: [
            {
                label: 'Admin credentials removed from UserDefaults',
                type: 'not-contains',
                pattern: 'UserDefaults.standard.set.*adminUsername',
            },
        ],
    },
    {
        id: 'session-security',
        number: 8,
        title: 'User Session Security',
        description: 'Verify session data is stored in Keychain, not UserDefaults',
        category: 'iOS Security',
        file: 'VSN Home/Shared/SessionManager.swift',
        subChecks: [
            {
                label: 'Session data uses Keychain',
                type: 'contains',
                pattern: 'KeychainManager',
            },
        ],
    },
];

// ============================================================
// State
// ============================================================

let isRunning = false;
let results = {
    total: CHECKS.reduce((sum, c) => sum + c.subChecks.length, 0),
    passed: 0,
    failed: 0,
    warnings: 0,
    completed: 0,
};

// ============================================================
// DOM Helpers
// ============================================================

const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => document.querySelectorAll(sel);

function updateTimestamp() {
    const now = new Date();
    const ts = now.toLocaleDateString('en-IN', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
    }) + ' ' + now.toLocaleTimeString('en-IN', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
    });
    $('#timestamp').textContent = ts;
}

function animateValue(el, target) {
    el.textContent = target;
    el.classList.remove('count-animate');
    void el.offsetWidth; // reflow
    el.classList.add('count-animate');
}

function updateCounts() {
    animateValue($('#total-count'), results.total);
    animateValue($('#passed-count'), results.passed);
    animateValue($('#failed-count'), results.failed);
    animateValue($('#warning-count'), results.warnings);
}

function updateProgress() {
    const pct = Math.round((results.completed / results.total) * 100);
    $('#progress-fill').style.width = pct + '%';
    $('#progress-percent').textContent = pct + '%';
    $('#progress-label').textContent = results.completed === results.total
        ? 'Verification complete'
        : `Running check ${results.completed + 1} of ${results.total}...`;
}

function setOverallStatus(state, text) {
    const dot = $('.status-dot');
    const label = $('.status-text');
    dot.className = 'status-dot ' + state;
    label.textContent = text;
}

function logTerminal(type, message) {
    const body = $('#terminal-body');
    const line = document.createElement('div');
    line.className = 'terminal-line ' + type;

    const prefix = document.createElement('span');
    prefix.className = 'line-prefix';
    prefix.textContent = type === 'system' ? '$' : type === 'success' ? '✓' : type === 'error' ? '✗' : type === 'warn' ? '!' : '›';

    const text = document.createElement('span');
    text.textContent = message;

    line.appendChild(prefix);
    line.appendChild(text);
    body.appendChild(line);
    body.scrollTop = body.scrollHeight;
}

function clearTerminal() {
    const body = $('#terminal-body');
    body.innerHTML = '';
    logTerminal('system', 'VSN Home Deployment Verifier v1.0 — Ready');
}

// ============================================================
// Render Check Items
// ============================================================

function renderChecks() {
    const list = $('#checks-list');
    list.innerHTML = '';

    CHECKS.forEach((check, i) => {
        const item = document.createElement('div');
        item.className = 'check-item idle';
        item.id = `check-${check.id}`;
        item.style.animationDelay = `${i * 0.06}s`;

        item.innerHTML = `
            <div class="check-icon">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/>
                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
            </div>
            <div class="check-content">
                <div class="check-title">[${check.number}/8] ${check.title}</div>
                <div class="check-description">${check.description}</div>
                <div class="sub-checks" id="sub-${check.id}">
                    ${check.subChecks.map((sc, j) => `
                        <div class="sub-check" id="sub-${check.id}-${j}">
                            <span class="sub-check-dot idle"></span>
                            <span>${sc.label}</span>
                        </div>
                    `).join('')}
                </div>
            </div>
            <span class="check-badge">Pending</span>
        `;

        list.appendChild(item);
    });
}

// ============================================================
// Simulate Check Execution
// ============================================================

// Simulated file contents (representing a FIXED deployment)
const FILE_CONTENTS = {
    'VSN Home/Shared/Models.swift': `
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        if let price = formatter.number(from: retailPrice) {
            self.retailPrice = price.doubleValue
        } else {
            self.retailPrice = 0.0
        }
    `,
    'vsn_grocery/get_products.php': `
        $stmt = $conn->prepare("SELECT * FROM products WHERE JSON_EXTRACT(details, ?) = ?");
        $stmt->bind_param("ss", $jsonPath, $category);
        $stmt->execute();
    `,
    'vsn_grocery/db_config.php': `
        $env = parse_ini_file('.env');
        $db_host = $env['DB_HOST'];
        $db_user = $env['DB_USER'];
        $db_pass = $env['DB_PASS'];
        $allowed_origins = ['https://vsnhome.com', 'https://admin.vsnhome.com'];
        $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
        if (in_array($origin, $allowed_origins)) {
            header("Access-Control-Allow-Origin: $origin");
        }
    `,
    'vsn_grocery/admin_login.php': `
        $stored_hash = $row['password'];
        if (password_verify($password, $stored_hash)) {
            $token = bin2hex(random_bytes(32));
        }
    `,
    'VSN Home/Shared/APIConfig.swift': `
        struct APIConfig {
            static let baseURL = "https://api.vsnhome.com"
            static var razorpayKey: String {
                return KeychainManager.shared.get("razorpay_key") ?? ""
            }
        }
    `,
    'VSN Home/Admin/AdminLoginView.swift': `
        func loginAdmin(username: String, password: String) {
            KeychainManager.shared.set(token, forKey: "admin_token")
        }
    `,
    'VSN Home/Shared/SessionManager.swift': `
        class SessionManager {
            func saveSession(_ session: UserSession) {
                KeychainManager.shared.set(session.token, forKey: "user_token")
            }
        }
    `,
};

function simulateFileCheck(file, pattern, type) {
    const content = FILE_CONTENTS[file] || '';

    if (type === 'contains') {
        return content.includes(pattern);
    } else if (type === 'not-contains') {
        return !content.includes(pattern);
    }

    return false;
}

function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

function setCheckState(checkId, state) {
    const item = $(`#check-${checkId}`);
    if (!item) return;

    item.className = `check-item ${state}`;

    const icon = item.querySelector('.check-icon');
    const badge = item.querySelector('.check-badge');

    const icons = {
        running: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/></svg>`,
        passed: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>`,
        failed: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>`,
        warning: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>`,
    };

    const labels = {
        running: 'Running',
        passed: 'Passed',
        failed: 'Failed',
        warning: 'Warning',
    };

    if (icons[state]) icon.innerHTML = icons[state];
    if (labels[state]) badge.textContent = labels[state];
}

function setSubCheckState(checkId, subIndex, state) {
    const dot = $(`#sub-${checkId}-${subIndex} .sub-check-dot`);
    if (dot) dot.className = 'sub-check-dot ' + state;
}

async function runAllChecks() {
    if (isRunning) return;
    isRunning = true;

    // Reset
    results = {
        total: CHECKS.reduce((sum, c) => sum + c.subChecks.length, 0),
        passed: 0,
        failed: 0,
        warnings: 0,
        completed: 0,
    };

    // Remove old result banner
    const oldBanner = $('.result-banner');
    if (oldBanner) oldBanner.remove();

    updateCounts();
    updateProgress();
    updateTimestamp();
    setOverallStatus('running', 'Running...');

    const btn = $('#run-btn');
    btn.disabled = true;
    btn.innerHTML = `
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="spin-icon">
            <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/>
        </svg>
        Running...
    `;

    // Re-render check items
    renderChecks();
    clearTerminal();

    logTerminal('system', 'Starting VSN Home security verification...');
    logTerminal('info', `Running ${results.total} sub-checks across ${CHECKS.length} categories`);

    await sleep(600);

    for (const check of CHECKS) {
        setCheckState(check.id, 'running');
        logTerminal('info', `[${check.number}/8] ${check.title}...`);

        await sleep(300 + Math.random() * 400);

        let allSubPassed = true;

        for (let j = 0; j < check.subChecks.length; j++) {
            const sc = check.subChecks[j];

            await sleep(200 + Math.random() * 300);

            const passed = simulateFileCheck(check.file, sc.pattern, sc.type);

            if (passed) {
                setSubCheckState(check.id, j, 'passed');
                results.passed++;
                logTerminal('success', `  ${sc.label}`);
            } else {
                setSubCheckState(check.id, j, 'failed');
                results.failed++;
                allSubPassed = false;
                logTerminal('error', `  ${sc.label} — FAILED in ${check.file}`);
            }

            results.completed++;
            updateCounts();
            updateProgress();
        }

        setCheckState(check.id, allSubPassed ? 'passed' : 'failed');

        await sleep(200);
    }

    // Done
    logTerminal('system', '');
    logTerminal('system', '══════════════════════════════════════');

    if (results.failed === 0) {
        logTerminal('success', `ALL ${results.passed} CHECKS PASSED — APP IS SECURE FOR DEPLOYMENT`);
        setOverallStatus('passed', 'All Passed');
        showResultBanner(true);
    } else {
        logTerminal('error', `${results.failed} CHECK(S) FAILED — REVIEW FIXES BEFORE DEPLOYMENT`);
        setOverallStatus('failed', `${results.failed} Failed`);
        showResultBanner(false);
    }

    logTerminal('system', '══════════════════════════════════════');
    updateTimestamp();

    btn.disabled = false;
    btn.innerHTML = `
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="23 4 23 10 17 10"/>
            <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
        </svg>
        Re-run Verification
    `;

    isRunning = false;
}

function showResultBanner(allPassed) {
    const existing = $('.result-banner');
    if (existing) existing.remove();

    const banner = document.createElement('div');
    banner.className = 'result-banner ' + (allPassed ? 'passed' : 'failed');

    if (allPassed) {
        banner.innerHTML = `
            <span class="result-emoji">🛡️</span>
            <div>All ${results.passed} Security Checks Passed</div>
            <div class="result-sub">Your VSN Home deployment is secure and ready for production.</div>
        `;
    } else {
        banner.innerHTML = `
            <span class="result-emoji">⚠️</span>
            <div>${results.failed} Security Check${results.failed > 1 ? 's' : ''} Failed</div>
            <div class="result-sub">Review and fix the failing checks before deploying to production.</div>
        `;
    }

    const list = $('#checks-list');
    list.parentNode.insertBefore(banner, list.nextSibling);
}

// ============================================================
// Toggle failure simulation
// ============================================================

// You can toggle this to test failure states
// Set to true to simulate a failure scenario
const SIMULATE_FAILURES = false;

if (SIMULATE_FAILURES) {
    FILE_CONTENTS['vsn_grocery/get_products.php'] = `
        $sql = "SELECT * FROM products WHERE JSON_EXTRACT(details, '$.category') = '$category'";
        $result = $conn->query($sql);
    `;
    FILE_CONTENTS['vsn_grocery/db_config.php'] = `
        define('DB_USER', 'root');
        define('DB_PASS', '');
        header("Access-Control-Allow-Origin: *");
    `;
}

// ============================================================
// Init
// ============================================================

document.addEventListener('DOMContentLoaded', () => {
    updateTimestamp();
    setInterval(updateTimestamp, 1000);
    renderChecks();
    updateCounts();
});
