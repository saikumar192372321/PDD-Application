import fs from 'fs';
import { fileURLToPath } from 'url';
import path from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const inputPath = path.join(__dirname, 'input.json');
const config = JSON.parse(fs.readFileSync(inputPath, 'utf8'));

const BASE_URL = config.baseUrl;
const ADMIN = config.admin;
const USER = config.user;

const ENDPOINTS = [
    { path: '/get_products.php', method: 'GET', auth: 'public' },
    { path: '/get_offers.php', method: 'GET', auth: 'public' },
    { path: '/get_orders.php', method: 'GET', auth: 'user' },
    { path: '/get_notifications.php', method: 'GET', auth: 'user' },
    { path: '/get_profile.php', method: 'GET', auth: 'user' },
    { path: '/get_referral_stats.php', method: 'GET', auth: 'user' },
    { path: '/get_support.php', method: 'GET', auth: 'public' },
    { path: '/get_users.php', method: 'GET', auth: 'admin' },
    { path: '/admin_analytics.php', method: 'GET', auth: 'admin' },

    { path: '/login.php', method: 'POST', auth: 'public' },
    { path: '/admin_login.php', method: 'POST', auth: 'public' },
    { path: '/register.php', method: 'POST', auth: 'public' },
    { path: '/forgot_password.php', method: 'POST', auth: 'public' },
    { path: '/reset_password.php', method: 'POST', auth: 'public' },
    { path: '/verify_otp.php', method: 'POST', auth: 'public' },
    { path: '/delete_account.php', method: 'POST', auth: 'user' },
    { path: '/update_profile.php', method: 'POST', auth: 'user' },

    { path: '/place_order.php', method: 'POST', auth: 'user' },
    { path: '/razorpay_order.php', method: 'POST', auth: 'user' },
    { path: '/update_order_status.php', method: 'POST', auth: 'admin' },

    { path: '/add_product.php', method: 'POST', auth: 'admin' },
    { path: '/update_stock.php', method: 'POST', auth: 'admin' },
    { path: '/delete_product.php', method: 'POST', auth: 'admin' },
    { path: '/add_offer.php', method: 'POST', auth: 'admin' },
    { path: '/delete_offer.php', method: 'POST', auth: 'admin' },
    { path: '/add_admin.php', method: 'POST', auth: 'admin' },

    { path: '/send_notification.php', method: 'POST', auth: 'admin' },
    { path: '/mark_notifications_read.php', method: 'POST', auth: 'user' },
    { path: '/delete_notification.php', method: 'POST', auth: 'user' }
];

let report = [];

async function makeRequest(endpoint, method, body = null, query = '') {
    const start = Date.now();
    try {
        const res = await fetch(`${BASE_URL}${endpoint}${query}`, {
            method,
            headers: { 'Content-Type': 'application/json' },
            body: body ? JSON.stringify(body) : undefined,
            signal: AbortSignal.timeout(5000)
        });
        const time = Date.now() - start;
        const text = await res.text();
        return { status: res.status, time, text };
    } catch (e) {
        return { status: 0, time: Date.now() - start, text: e.message };
    }
}

async function runDast() {
    console.log(`Starting DAST scan on ${BASE_URL}...`);

    for (const ep of ENDPOINTS) {
        if (ep.auth === 'public') continue; // Skip public endpoints for Auth bypass

        // 1. AuthN Bypass Test (No Auth provided)
        console.log(`[AuthN Bypass] Testing ${ep.method} ${ep.path}...`);
        let res = await makeRequest(ep.path, ep.method, ep.method === 'POST' ? {} : null);
        
        let finding = false;
        let note = "Properly blocked";
        let severity = "Low";

        if (res.status === 200) {
            // Check if it's a false positive 200 (like API returning {"status":"error"})
            try {
                let json = JSON.parse(res.text);
                if (json.status === 'success' || !json.status) {
                    finding = true;
                    severity = "Critical";
                    note = "AuthN Bypass: Endpoint returned 200 OK success without any credentials.";
                } else {
                    note = "Returned 200 but payload indicates error: " + json.message;
                }
            } catch(e) {
                finding = true;
                severity = "Critical";
                note = "AuthN Bypass: Endpoint returned 200 OK text without credentials.";
            }
        }

        report.push({
            endpoint: ep.path,
            method: ep.method,
            role: "none",
            status: res.status,
            expected_status: 401,
            finding,
            severity,
            response_time_ms: res.time,
            test_category: "AuthN Bypass",
            note,
            timestamp: new Date().toISOString()
        });

        // 2. AuthZ / PrivEsc (Test admin endpoints with user credentials)
        if (ep.auth === 'admin') {
            console.log(`[AuthZ PrivEsc] Testing ${ep.method} ${ep.path} as User...`);
            let userQuery = ep.method === 'GET' ? `?userEmail=${USER.email}` : '';
            let userBody = ep.method === 'POST' ? { email: USER.email, userEmail: USER.email } : null;

            res = await makeRequest(ep.path, ep.method, userBody, userQuery);

            let privFinding = false;
            let privNote = "Properly blocked";
            if (res.status === 200) {
                try {
                    let json = JSON.parse(res.text);
                    if (json.status === 'success' || !json.status) {
                        privFinding = true;
                        privNote = "AuthZ Bypass: Admin endpoint allowed access to standard user!";
                    }
                } catch(e) {
                    privFinding = true;
                    privNote = "AuthZ Bypass: Admin endpoint returned 200 OK text to standard user!";
                }
            }

            report.push({
                endpoint: ep.path,
                method: ep.method,
                role: "user",
                status: res.status,
                expected_status: 403,
                finding: privFinding,
                severity: "High",
                response_time_ms: res.time,
                test_category: "AuthZ PrivEsc",
                note: privNote,
                timestamp: new Date().toISOString()
            });
        }
        
        // 6. SQL Injection Probes
        console.log(`[SQLi Probe] Testing ${ep.method} ${ep.path}...`);
        let sqliPayload = "' OR '1'='1";
        let sqliQuery = ep.method === 'GET' ? `?userEmail=${sqliPayload}&id=${sqliPayload}` : '';
        let sqliBody = ep.method === 'POST' ? { email: sqliPayload, password: sqliPayload, id: sqliPayload } : null;
        
        res = await makeRequest(ep.path, ep.method, sqliBody, sqliQuery);
        let sqliFinding = false;
        let sqliNote = "No anomaly detected";
        if (res.status === 500 || res.text.includes('SQL syntax') || res.text.includes('mysql_fetch_array')) {
            sqliFinding = true;
            sqliNote = "SQLi Detection: Database error returned!";
        } else if (res.status === 200) {
             try {
                let json = JSON.parse(res.text);
                if (json.status === 'success' && ep.path === '/login.php') {
                    sqliFinding = true;
                    sqliNote = "SQLi Detection: Login bypass successful via SQL injection payload!";
                }
            } catch(e) {}
        }

        report.push({
            endpoint: ep.path,
            method: ep.method,
            role: "none",
            status: res.status,
            expected_status: 400,
            finding: sqliFinding,
            severity: "Critical",
            response_time_ms: res.time,
            test_category: "Injection Probe",
            note: sqliNote,
            timestamp: new Date().toISOString()
        });
    }

    fs.writeFileSync(path.join(__dirname, 'report.json'), JSON.stringify(report, null, 2));

    let findingsCount = report.filter(r => r.finding).length;
    console.log('\n=======================================');
    console.log('DAST SCAN SUMMARY');
    console.log('=======================================');
    console.log(`Endpoints Discovered: ${ENDPOINTS.length}`);
    console.log(`Tests Executed: ${report.length}`);
    console.log(`Total Findings: ${findingsCount}`);
    
    console.log('\n--- TOP ISSUES ---');
    report.filter(r => r.finding).forEach(r => {
        console.log(`[${r.severity}] ${r.test_category} on ${r.method} ${r.endpoint}`);
        console.log(`   └> ${r.note}`);
    });
}

runDast();
