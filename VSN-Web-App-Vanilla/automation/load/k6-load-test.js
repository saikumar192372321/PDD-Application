/**
 * VSN Grocery — k6 Load Testing Script
 * Baseline / Stress / Spike / Endurance Tests
 * Run: k6 run automation/load/k6-load-test.js
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

// ─── Custom Metrics ─────────────────────────────────────
const errorRate = new Rate('error_rate');
const indexLoadTime = new Trend('index_load_time');
const adminLoadTime = new Trend('admin_load_time');
const requestCount = new Counter('total_requests');

// ─── Configuration ───────────────────────────────────────
const BASE_URL = __ENV.BASE_URL || 'https://saikumar192372321.github.io/PDD-Application';

export const options = {
  scenarios: {
    // --- Baseline: 100 users, 1 minute ---
    baseline_load: {
      executor: 'constant-vus',
      vus: 100,
      duration: '1m',
      tags: { scenario: 'baseline' },
    },
    // --- Stress: Ramp up to 500 users ---
    stress_test: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 100 },
        { duration: '1m', target: 200 },
        { duration: '1m', target: 500 },
        { duration: '30s', target: 0 },
      ],
      startTime: '2m',
      tags: { scenario: 'stress' },
    },
    // --- Spike: 50 → 500 suddenly ---
    spike_test: {
      executor: 'ramping-vus',
      startVUs: 50,
      stages: [
        { duration: '10s', target: 500 },
        { duration: '30s', target: 500 },
        { duration: '10s', target: 50 },
      ],
      startTime: '5m',
      tags: { scenario: 'spike' },
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<3000', 'p(99)<5000'],
    http_req_failed: ['rate<0.05'],
    error_rate: ['rate<0.05'],
  },
};

export default function () {
  // ─── Test 1: Load index.html ──────────────────────────
  const indexRes = http.get(`${BASE_URL}/VSN-Web-App-Vanilla/index.html`, {
    tags: { name: 'store_page' },
  });
  indexLoadTime.add(indexRes.timings.duration);
  requestCount.add(1);

  const indexOk = check(indexRes, {
    'index.html status 200': r => r.status === 200,
    'index.html has body': r => r.body && r.body.length > 0,
    'index.html loads < 3s': r => r.timings.duration < 3000,
    'index.html contains VSN': r => r.body && r.body.includes('VSN'),
  });
  errorRate.add(!indexOk);

  sleep(0.5);

  // ─── Test 2: Load admin.html ──────────────────────────
  const adminRes = http.get(`${BASE_URL}/VSN-Web-App-Vanilla/admin.html`, {
    tags: { name: 'admin_page' },
  });
  adminLoadTime.add(adminRes.timings.duration);
  requestCount.add(1);

  check(adminRes, {
    'admin.html status 200': r => r.status === 200,
    'admin.html has login form': r => r.body && r.body.includes('adminEmail'),
    'admin.html loads < 3s': r => r.timings.duration < 3000,
  });

  sleep(0.3);

  // ─── Test 3: Load static assets ──────────────────────
  const cssRes = http.get(`${BASE_URL}/VSN-Web-App-Vanilla/css/style.css`, {
    tags: { name: 'css_asset' },
  });
  requestCount.add(1);
  check(cssRes, {
    'style.css status 200 or 304': r => r.status === 200 || r.status === 304,
  });

  sleep(0.2);

  // ─── Test 4: Load manifest.json ──────────────────────
  const manifestRes = http.get(`${BASE_URL}/VSN-Web-App-Vanilla/manifest.json`, {
    tags: { name: 'manifest' },
  });
  requestCount.add(1);
  check(manifestRes, {
    'manifest.json loaded': r => r.status === 200 || r.status === 304,
  });

  sleep(Math.random() * 0.5);
}

export function handleSummary(data) {
  const summary = {
    execution_date: new Date().toISOString(),
    base_url: BASE_URL,
    metrics: {
      total_requests: data.metrics.total_requests?.values?.count || 0,
      requests_per_second: (data.metrics.http_reqs?.values?.rate || 0).toFixed(2),
      avg_response_time_ms: (data.metrics.http_req_duration?.values?.avg || 0).toFixed(2),
      min_response_time_ms: (data.metrics.http_req_duration?.values?.min || 0).toFixed(2),
      max_response_time_ms: (data.metrics.http_req_duration?.values?.max || 0).toFixed(2),
      p95_response_time_ms: (data.metrics.http_req_duration?.values?.['p(95)'] || 0).toFixed(2),
      p99_response_time_ms: (data.metrics.http_req_duration?.values?.['p(99)'] || 0).toFixed(2),
      error_rate_pct: ((data.metrics.http_req_failed?.values?.rate || 0) * 100).toFixed(2),
    },
    thresholds_passed: Object.values(data.metrics).every(m => !m.thresholds || Object.values(m.thresholds).every(t => t.ok)),
  };

  return {
    'test-results/load/k6-summary.json': JSON.stringify(summary, null, 2),
    stdout: `
╔══════════════════════════════════════════════════════╗
║        VSN Grocery — k6 Load Test Summary            ║
╠══════════════════════════════════════════════════════╣
║  Total Requests   : ${String(summary.metrics.total_requests).padEnd(30)}║
║  Requests/sec     : ${String(summary.metrics.requests_per_second + ' req/s').padEnd(30)}║
║  Avg Response     : ${String(summary.metrics.avg_response_time_ms + ' ms').padEnd(30)}║
║  Min Response     : ${String(summary.metrics.min_response_time_ms + ' ms').padEnd(30)}║
║  Max Response     : ${String(summary.metrics.max_response_time_ms + ' ms').padEnd(30)}║
║  P95 Response     : ${String(summary.metrics.p95_response_time_ms + ' ms').padEnd(30)}║
║  P99 Response     : ${String(summary.metrics.p99_response_time_ms + ' ms').padEnd(30)}║
║  Error Rate       : ${String(summary.metrics.error_rate_pct + '%').padEnd(30)}║
║  Thresholds       : ${summary.thresholds_passed ? '✅ ALL PASSED'.padEnd(30) : '❌ SOME FAILED'.padEnd(30)}║
╚══════════════════════════════════════════════════════╝
`,
  };
}
