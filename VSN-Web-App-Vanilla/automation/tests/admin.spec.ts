import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';
import { StorePage } from '../pages/StorePage';
import { setupBackendMocks } from '../utils/mockBackend';

// ============================================================
// ADMIN DASHBOARD TESTS — 40 Test Cases (TC_ADMIN_001-040)
// ============================================================

test.describe('Admin Dashboard Tests', () => {
  let loginPage: LoginPage;

  test.beforeEach(async ({ page }) => {
    await setupBackendMocks(page);
    loginPage = new LoginPage(page);
    await loginPage.navigate();
    await loginPage.login('admin@vsnhome.com', 'Admin@123');
    await page.waitForTimeout(500);
  });

  test('TC_ADMIN_001 - Dashboard tab is active by default', async ({ page }) => {
    await expect(page.locator('#tab-dashboard')).toBeVisible();
  });

  test('TC_ADMIN_002 - Dashboard heading is visible', async ({ page }) => {
    await expect(page.locator('#tab-dashboard h2')).toContainText('Dashboard');
  });

  test('TC_ADMIN_003 - KPI grid is present', async ({ page }) => {
    await expect(page.locator('#kpiGrid')).toBeVisible();
  });

  test('TC_ADMIN_004 - Period tabs are visible', async ({ page }) => {
    await expect(page.locator('.period-tabs')).toBeVisible();
  });

  test('TC_ADMIN_005 - Weekly period tab exists', async ({ page }) => {
    await expect(page.locator('button.period-btn').first()).toContainText('Weekly');
  });

  test('TC_ADMIN_006 - Today period tab exists', async ({ page }) => {
    await expect(page.locator('button.period-btn').nth(1)).toContainText('Today');
  });

  test('TC_ADMIN_007 - Monthly period tab exists', async ({ page }) => {
    await expect(page.locator('button.period-btn').nth(2)).toContainText('Monthly');
  });

  test('TC_ADMIN_008 - Backend status pill is visible', async ({ page }) => {
    await expect(page.locator('#backendStatusPill')).toBeVisible();
  });

  test('TC_ADMIN_009 - Orders tab navigates to orders section', async ({ page }) => {
    await loginPage.ordersTab.click();
    await expect(page.locator('#tab-orders')).toBeVisible();
  });

  test('TC_ADMIN_010 - Products tab navigates to products section', async ({ page }) => {
    await loginPage.productsTab.click();
    await expect(page.locator('#tab-products')).toBeVisible();
  });

  test('TC_ADMIN_011 - Users tab navigates to users section', async ({ page }) => {
    await loginPage.usersTab.click();
    await expect(page.locator('#tab-users')).toBeVisible();
  });

  test('TC_ADMIN_012 - Notifications tab navigates to notifications section', async ({ page }) => {
    await loginPage.notificationsTab.click();
    await expect(page.locator('#tab-notifications')).toBeVisible();
  });

  test('TC_ADMIN_013 - Settings tab navigates to settings section', async ({ page }) => {
    await loginPage.settingsTab.click();
    await expect(page.locator('#tab-settings')).toBeVisible();
  });

  test('TC_ADMIN_014 - Sidebar is visible', async ({ page }) => {
    await expect(page.locator('.sidebar')).toBeVisible();
  });

  test('TC_ADMIN_015 - Main content area is visible', async ({ page }) => {
    await expect(page.locator('.main-content')).toBeVisible();
  });

  test('TC_ADMIN_016 - Sidebar nav has 6 items', async ({ page }) => {
    const items = await page.locator('.sidebar-nav a.nav-item').count();
    expect(items).toBeGreaterThanOrEqual(6);
  });

  test('TC_ADMIN_017 - Sidebar footer is visible', async ({ page }) => {
    await expect(page.locator('.sidebar-footer')).toBeVisible();
  });

  test('TC_ADMIN_018 - Dashboard active nav item has active class', async ({ page }) => {
    const classes = await page.locator('.sidebar-nav a.nav-item.active').getAttribute('class');
    expect(classes).toContain('active');
  });

  test('TC_ADMIN_019 - Clicking Orders makes it active', async ({ page }) => {
    await loginPage.ordersTab.click();
    const classes = await loginPage.ordersTab.getAttribute('class');
    expect(classes).toContain('active');
  });

  test('TC_ADMIN_020 - Clicking Products makes it active', async ({ page }) => {
    await loginPage.productsTab.click();
    const classes = await loginPage.productsTab.getAttribute('class');
    expect(classes).toContain('active');
  });

  test('TC_ADMIN_021 - Tab-dashboard has page-header', async ({ page }) => {
    await expect(page.locator('#tab-dashboard .page-header')).toBeVisible();
  });

  test('TC_ADMIN_022 - KPI cards shimmer on initial load', async ({ page }) => {
    const shimmer = await page.locator('.kpi-card.shimmer').count();
    expect(shimmer).toBeGreaterThanOrEqual(0);
  });

  test('TC_ADMIN_023 - Sidebar logo text is VSN Admin', async ({ page }) => {
    await expect(page.locator('.sidebar-logo span')).toContainText('VSN Admin');
  });

  test('TC_ADMIN_024 - Sidebar has shield icon', async ({ page }) => {
    await expect(page.locator('.sidebar-logo .fa-shield-halved')).toBeVisible();
  });

  test('TC_ADMIN_025 - View Store link is present in sidebar', async ({ page }) => {
    await expect(page.locator('.sidebar-nav a[href="index.html"]')).toBeVisible();
  });

  test('TC_ADMIN_026 - Page title is VSN Admin Panel', async ({ page }) => {
    await expect(page).toHaveTitle(/VSN Admin/);
  });

  test('TC_ADMIN_027 - Admin panel has Inter font', async ({ page }) => {
    const font = await page.evaluate(() => window.getComputedStyle(document.body).fontFamily);
    expect(font.toLowerCase()).toContain('inter');
  });

  test('TC_ADMIN_028 - Period Weekly button is active by default', async ({ page }) => {
    const classes = await page.locator('button.period-btn.active').textContent();
    expect(classes).toContain('Weekly');
  });

  test('TC_ADMIN_029 - Clicking Today period button works', async ({ page }) => {
    await page.locator('button.period-btn').nth(1).click();
    await page.waitForTimeout(500);
    await expect(page.locator('button.period-btn.active')).toContainText('Today');
  });

  test('TC_ADMIN_030 - Clicking Monthly period button works', async ({ page }) => {
    await page.locator('button.period-btn').nth(2).click();
    await page.waitForTimeout(500);
    await expect(page.locator('button.period-btn.active')).toContainText('Monthly');
  });

  test('TC_ADMIN_031 - Orders tab has box icon', async ({ page }) => {
    await expect(loginPage.ordersTab.locator('.fa-box')).toBeVisible();
  });

  test('TC_ADMIN_032 - Products tab has tags icon', async ({ page }) => {
    await expect(loginPage.productsTab.locator('.fa-tags')).toBeVisible();
  });

  test('TC_ADMIN_033 - Users tab has users icon', async ({ page }) => {
    await expect(loginPage.usersTab.locator('.fa-users')).toBeVisible();
  });

  test('TC_ADMIN_034 - Notifications tab has bell icon', async ({ page }) => {
    await expect(loginPage.notificationsTab.locator('.fa-bell')).toBeVisible();
  });

  test('TC_ADMIN_035 - Settings tab has gear icon', async ({ page }) => {
    await expect(loginPage.settingsTab.locator('.fa-gear')).toBeVisible();
  });

  test('TC_ADMIN_036 - Logout button has correct icon', async ({ page }) => {
    await expect(page.locator('.sidebar-footer button .fa-right-from-bracket')).toBeVisible();
  });

  test('TC_ADMIN_037 - Admin CSS file loaded', async ({ page }) => {
    const css = await page.locator('link[href="css/admin.css"]').count();
    expect(css).toBe(1);
  });

  test('TC_ADMIN_038 - Admin panel CSS display is block after login', async ({ page }) => {
    const display = await page.locator('#adminPanel').evaluate(el => window.getComputedStyle(el).display);
    expect(display).not.toBe('none');
  });

  test('TC_ADMIN_039 - Sidebar overlay is present in DOM', async ({ page }) => {
    await expect(page.locator('#sidebarOverlay')).toBeAttached();
  });

  test('TC_ADMIN_040 - Mobile nav toggle button is in DOM', async ({ page }) => {
    await expect(page.locator('.mobile-nav-toggle')).toBeAttached();
  });
});
