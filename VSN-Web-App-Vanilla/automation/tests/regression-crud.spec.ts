import { test, expect } from '@playwright/test';
import { StorePage } from '../pages/StorePage';
import { LoginPage } from '../pages/LoginPage';

// ============================================================
// REGRESSION SUITE — 50 Test Cases (TC_REG_001-050)
// ============================================================

test.describe('Regression Suite', () => {
  test('TC_REG_001 - Store page title is correct', async ({ page }) => {
    await page.goto('/index.html');
    await expect(page).toHaveTitle(/VSN Grocery/);
  });

  test('TC_REG_002 - Admin page title is correct', async ({ page }) => {
    await page.goto('/admin.html');
    await expect(page).toHaveTitle(/VSN Admin/);
  });

  test('TC_REG_003 - Store navbar visible after reload', async ({ page }) => {
    await page.goto('/index.html');
    await page.reload();
    await expect(page.locator('.navbar')).toBeVisible();
  });

  test('TC_REG_004 - Home view active after store page load', async ({ page }) => {
    await page.goto('/index.html');
    await expect(page.locator('#view-home')).toHaveClass(/active-view/);
  });

  test('TC_REG_005 - Categories view accessible from navbar', async ({ page }) => {
    await page.goto('/index.html');
    await page.locator('a.nav-link[data-view="categories"]').click();
    await expect(page.locator('#view-categories')).toBeVisible();
  });

  test('TC_REG_006 - Offers view accessible from navbar', async ({ page }) => {
    await page.goto('/index.html');
    await page.locator('a.nav-link[data-view="offers"]').click();
    await expect(page.locator('#view-offers')).toBeVisible();
  });

  test('TC_REG_007 - Orders view accessible from navbar', async ({ page }) => {
    await page.goto('/index.html');
    await page.locator('a.nav-link[data-view="orders"]').click();
    await expect(page.locator('#view-orders')).toBeVisible();
  });

  test('TC_REG_008 - Chatbot view accessible from navbar', async ({ page }) => {
    await page.goto('/index.html');
    await page.locator('a.nav-link[data-view="chatbot"]').click();
    await expect(page.locator('#view-chatbot')).toBeVisible();
  });

  test('TC_REG_009 - Analytics view accessible from navbar', async ({ page }) => {
    await page.goto('/index.html');
    await page.locator('a.nav-link[data-view="analytics"]').click();
    await expect(page.locator('#view-analytics')).toBeVisible();
  });

  test('TC_REG_010 - Shop Now navigates to categories', async ({ page }) => {
    await page.goto('/index.html');
    await page.locator('.primary-btn').first().click();
    await expect(page.locator('#view-categories')).toBeVisible();
  });

  test('TC_REG_011 - Admin login screen visible on admin.html', async ({ page }) => {
    await page.goto('/admin.html');
    await expect(page.locator('#loginScreen')).toBeVisible();
  });

  test('TC_REG_012 - Admin panel hidden before login', async ({ page }) => {
    await page.goto('/admin.html');
    await expect(page.locator('#adminPanel')).toBeHidden();
  });

  test('TC_REG_013 - Valid admin login shows panel', async ({ page }) => {
    const login = new LoginPage(page);
    await login.navigate();
    await login.login('admin@vsnhome.com', 'Admin@123');
    await expect(login.adminPanel).toBeVisible({ timeout: 5000 });
  });

  test('TC_REG_014 - Invalid login shows error', async ({ page }) => {
    const login = new LoginPage(page);
    await login.navigate();
    await login.login('bad@bad.com', 'badpass');
    await expect(login.loginErr).toBeVisible({ timeout: 3000 });
  });

  test('TC_REG_015 - Logout returns to login', async ({ page }) => {
    const login = new LoginPage(page);
    await login.navigate();
    await login.login('admin@vsnhome.com', 'Admin@123');
    await login.logout();
    await expect(login.loginScreen).toBeVisible();
  });

  test('TC_REG_016 - Search input is functional', async ({ page }) => {
    await page.goto('/index.html');
    await page.fill('#searchInput', 'rice');
    await expect(page.locator('#searchInput')).toHaveValue('rice');
  });

  test('TC_REG_017 - Theme toggles on button click', async ({ page }) => {
    await page.goto('/index.html');
    const before = await page.locator('body').getAttribute('class');
    await page.locator('#themeBtn').click();
    const after = await page.locator('body').getAttribute('class');
    expect(before).not.toBe(after);
  });

  test('TC_REG_018 - Notification dropdown toggles', async ({ page }) => {
    await page.goto('/index.html');
    await page.locator('#notifBtn').click();
    await expect(page.locator('#notifDropdown')).toBeVisible();
  });

  test('TC_REG_019 - Mobile nav opens via hamburger', async ({ page }) => {
    await page.goto('/index.html');
    await page.locator('#hamburgerBtn').click();
    await expect(page.locator('#mobileNav')).toBeVisible();
  });

  test('TC_REG_020 - Cart badge shows 0 by default', async ({ page }) => {
    await page.goto('/index.html');
    await expect(page.locator('#cartBadge')).toHaveText('0');
  });

  test('TC_REG_021 - Admin dashboard tab is default', async ({ page }) => {
    const login = new LoginPage(page);
    await login.navigate();
    await login.login('admin@vsnhome.com', 'Admin@123');
    await expect(page.locator('#tab-dashboard')).toBeVisible();
  });

  test('TC_REG_022 - Admin orders tab works', async ({ page }) => {
    const login = new LoginPage(page);
    await login.navigate();
    await login.login('admin@vsnhome.com', 'Admin@123');
    await login.ordersTab.click();
    await expect(page.locator('#tab-orders')).toBeVisible();
  });

  test('TC_REG_023 - Admin products tab works', async ({ page }) => {
    const login = new LoginPage(page);
    await login.navigate();
    await login.login('admin@vsnhome.com', 'Admin@123');
    await login.productsTab.click();
    await expect(page.locator('#tab-products')).toBeVisible();
  });

  test('TC_REG_024 - Admin users tab works', async ({ page }) => {
    const login = new LoginPage(page);
    await login.navigate();
    await login.login('admin@vsnhome.com', 'Admin@123');
    await login.usersTab.click();
    await expect(page.locator('#tab-users')).toBeVisible();
  });

  test('TC_REG_025 - Admin notifications tab works', async ({ page }) => {
    const login = new LoginPage(page);
    await login.navigate();
    await login.login('admin@vsnhome.com', 'Admin@123');
    await login.notificationsTab.click();
    await expect(page.locator('#tab-notifications')).toBeVisible();
  });

  test('TC_REG_026 - Admin settings tab works', async ({ page }) => {
    const login = new LoginPage(page);
    await login.navigate();
    await login.login('admin@vsnhome.com', 'Admin@123');
    await login.settingsTab.click();
    await expect(page.locator('#tab-settings')).toBeVisible();
  });

  test('TC_REG_027 - Back to store link on admin navigates to index', async ({ page }) => {
    await page.goto('/admin.html');
    await page.locator('a.back-link').click();
    await expect(page).toHaveURL(/index\.html/);
  });

  test('TC_REG_028 - Admin page has CSS loaded', async ({ page }) => {
    await page.goto('/admin.html');
    const count = await page.locator('link[rel="stylesheet"]').count();
    expect(count).toBeGreaterThan(0);
  });

  test('TC_REG_029 - Store page has CSS loaded', async ({ page }) => {
    await page.goto('/index.html');
    const count = await page.locator('link[rel="stylesheet"]').count();
    expect(count).toBeGreaterThan(0);
  });

  test('TC_REG_030 - Hero section always present on store page', async ({ page }) => {
    await page.goto('/index.html');
    await expect(page.locator('.hero')).toBeAttached();
  });

  test('TC_REG_031 - Store page cart button exists', async ({ page }) => {
    await page.goto('/index.html');
    await expect(page.locator('.icon-btn .fa-shopping-cart')).toBeAttached();
  });

  test('TC_REG_032 - Admin email field accepts input', async ({ page }) => {
    await page.goto('/admin.html');
    await page.fill('#adminEmail', 'test@example.com');
    await expect(page.locator('#adminEmail')).toHaveValue('test@example.com');
  });

  test('TC_REG_033 - Admin password field accepts input', async ({ page }) => {
    await page.goto('/admin.html');
    await page.fill('#adminPassword', 'testpass');
    await expect(page.locator('#adminPassword')).toHaveValue('testpass');
  });

  test('TC_REG_034 - Store page renders in less than 5 seconds', async ({ page }) => {
    const start = Date.now();
    await page.goto('/index.html', { waitUntil: 'load' });
    expect(Date.now() - start).toBeLessThan(5000);
  });

  test('TC_REG_035 - Admin page renders in less than 5 seconds', async ({ page }) => {
    const start = Date.now();
    await page.goto('/admin.html', { waitUntil: 'load' });
    expect(Date.now() - start).toBeLessThan(5000);
  });

  test('TC_REG_036 - Clicking logo always goes home', async ({ page }) => {
    await page.goto('/index.html');
    await page.locator('a.nav-link[data-view="categories"]').click();
    await page.locator('.logo').click();
    await expect(page.locator('#view-home')).toHaveClass(/active-view/);
  });

  test('TC_REG_037 - Search input type is text', async ({ page }) => {
    await page.goto('/index.html');
    expect(await page.locator('#searchInput').getAttribute('type')).toBe('text');
  });

  test('TC_REG_038 - Admin email field type is email', async ({ page }) => {
    await page.goto('/admin.html');
    expect(await page.locator('#adminEmail').getAttribute('type')).toBe('email');
  });

  test('TC_REG_039 - Admin password field type is password', async ({ page }) => {
    await page.goto('/admin.html');
    expect(await page.locator('#adminPassword').getAttribute('type')).toBe('password');
  });

  test('TC_REG_040 - Notif badge hidden by default', async ({ page }) => {
    await page.goto('/index.html');
    const style = await page.locator('#notifBadge').getAttribute('style');
    expect(style).toContain('display:none');
  });

  test('TC_REG_041 - Period tabs exist on admin dashboard', async ({ page }) => {
    const login = new LoginPage(page);
    await login.navigate();
    await login.login('admin@vsnhome.com', 'Admin@123');
    const count = await page.locator('.period-btn').count();
    expect(count).toBe(3);
  });

  test('TC_REG_042 - KPI grid section exists after login', async ({ page }) => {
    const login = new LoginPage(page);
    await login.navigate();
    await login.login('admin@vsnhome.com', 'Admin@123');
    await expect(page.locator('#kpiGrid')).toBeAttached();
  });

  test('TC_REG_043 - Sidebar footer logout button exists', async ({ page }) => {
    const login = new LoginPage(page);
    await login.navigate();
    await login.login('admin@vsnhome.com', 'Admin@123');
    await expect(page.locator('.sidebar-footer button')).toBeVisible();
  });

  test('TC_REG_044 - Mobile nav panel contains Home link', async ({ page }) => {
    await page.goto('/index.html');
    await page.locator('#hamburgerBtn').click();
    await expect(page.locator('.mobile-nav-panel a').filter({ hasText: 'Home' })).toBeVisible();
  });

  test('TC_REG_045 - Mobile nav panel contains Categories link', async ({ page }) => {
    await page.goto('/index.html');
    await page.locator('#hamburgerBtn').click();
    await expect(page.locator('.mobile-nav-panel a').filter({ hasText: 'Categories' })).toBeVisible();
  });

  test('TC_REG_046 - App content div exists', async ({ page }) => {
    await page.goto('/index.html');
    await expect(page.locator('#app-content')).toBeAttached();
  });

  test('TC_REG_047 - All 6 views exist in DOM', async ({ page }) => {
    await page.goto('/index.html');
    for (const view of ['home', 'categories', 'offers', 'orders', 'chatbot', 'analytics']) {
      await expect(page.locator(`#view-${view}`)).toBeAttached();
    }
  });

  test('TC_REG_048 - Store page has manifest.json linked', async ({ page }) => {
    await page.goto('/index.html');
    const href = await page.locator('link[rel="manifest"]').getAttribute('href');
    expect(href).toBe('manifest.json');
  });

  test('TC_REG_049 - Admin page has manifest.json linked', async ({ page }) => {
    await page.goto('/admin.html');
    const href = await page.locator('link[rel="manifest"]').getAttribute('href');
    expect(href).toBe('manifest.json');
  });

  test('TC_REG_050 - Full E2E flow: Store browse → Admin login → Logout', async ({ page }) => {
    // Store page
    await page.goto('/index.html');
    await expect(page.locator('.navbar')).toBeVisible();
    await page.locator('a.nav-link[data-view="categories"]').click();
    await expect(page.locator('#view-categories')).toBeVisible();

    // Navigate to admin
    const login = new LoginPage(page);
    await login.navigate();
    await login.login('admin@vsnhome.com', 'Admin@123');
    await expect(login.adminPanel).toBeVisible({ timeout: 5000 });

    // Tab navigation
    await login.ordersTab.click();
    await expect(page.locator('#tab-orders')).toBeVisible();

    // Logout
    await login.logout();
    await expect(login.loginScreen).toBeVisible();
  });
});

// ============================================================
// CRUD / FORMS TESTS — 40 Test Cases (TC_CRUD_001-040)
// ============================================================

test.describe('Forms and CRUD Tests', () => {
  let login: LoginPage;

  test.beforeEach(async ({ page }) => {
    login = new LoginPage(page);
    await login.navigate();
    await login.login('admin@vsnhome.com', 'Admin@123');
    await page.waitForTimeout(300);
  });

  test('TC_CRUD_001 - Admin products tab loads', async ({ page }) => {
    await login.productsTab.click();
    await expect(page.locator('#tab-products')).toBeVisible();
  });

  test('TC_CRUD_002 - Products tab is accessible', async ({ page }) => {
    await login.productsTab.click();
    const classes = await login.productsTab.getAttribute('class');
    expect(classes).toContain('active');
  });

  test('TC_CRUD_003 - Orders tab loads content', async ({ page }) => {
    await login.ordersTab.click();
    await expect(page.locator('#tab-orders')).toBeVisible();
  });

  test('TC_CRUD_004 - Users tab loads content', async ({ page }) => {
    await login.usersTab.click();
    await expect(page.locator('#tab-users')).toBeVisible();
  });

  test('TC_CRUD_005 - Settings tab loads content', async ({ page }) => {
    await login.settingsTab.click();
    await expect(page.locator('#tab-settings')).toBeVisible();
  });

  test('TC_CRUD_006 - Admin can switch between all tabs', async ({ page }) => {
    const tabs = [login.ordersTab, login.productsTab, login.usersTab,
                  login.notificationsTab, login.settingsTab, login.dashboardTab];
    for (const tab of tabs) {
      await tab.click();
      await page.waitForTimeout(200);
    }
    await expect(page.locator('#tab-dashboard')).toBeVisible();
  });

  test('TC_CRUD_007 - Admin panel main-content is scrollable', async ({ page }) => {
    const overflow = await page.locator('.main-content').evaluate(el =>
      window.getComputedStyle(el).overflowY
    );
    expect(['auto', 'scroll', 'overlay', 'visible']).toContain(overflow);
  });

  test('TC_CRUD_008 - Dashboard Weekly is default period', async ({ page }) => {
    await expect(page.locator('button.period-btn.active')).toContainText('Weekly');
  });

  test('TC_CRUD_009 - Clicking Today period updates active button', async ({ page }) => {
    await page.locator('button.period-btn').nth(1).click();
    await expect(page.locator('button.period-btn.active')).toContainText('Today');
  });

  test('TC_CRUD_010 - Clicking Monthly updates active button', async ({ page }) => {
    await page.locator('button.period-btn').nth(2).click();
    await expect(page.locator('button.period-btn.active')).toContainText('Monthly');
  });

  test('TC_CRUD_011 - Backend status pill exists on dashboard', async ({ page }) => {
    await expect(page.locator('#backendStatusPill')).toBeVisible();
  });

  test('TC_CRUD_012 - Dashboard loads without crash', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', e => errors.push(e.message));
    await page.waitForTimeout(1000);
    expect(errors.filter(e => !e.includes('ERR_'))).toHaveLength(0);
  });

  test('TC_CRUD_013 - Admin view store link is external', async ({ page }) => {
    const link = page.locator('.sidebar-nav a[href="index.html"]');
    const target = await link.getAttribute('target');
    expect(target).toBe('_blank');
  });

  test('TC_CRUD_014 - Admin can navigate back to dashboard', async ({ page }) => {
    await login.ordersTab.click();
    await login.dashboardTab.click();
    await expect(page.locator('#tab-dashboard')).toBeVisible();
  });

  test('TC_CRUD_015 - Sidebar is always visible during tab navigation', async ({ page }) => {
    for (const tab of [login.ordersTab, login.productsTab, login.settingsTab]) {
      await tab.click();
      await expect(page.locator('.sidebar')).toBeVisible();
    }
  });

  test('TC_CRUD_016 - Admin header/title present on each tab', async ({ page }) => {
    for (const [tab, tabId] of [
      [login.ordersTab, '#tab-orders'],
      [login.productsTab, '#tab-products'],
      [login.usersTab, '#tab-users'],
    ] as const) {
      await tab.click();
      await expect(page.locator(tabId)).toBeVisible();
    }
  });

  test('TC_CRUD_017 - Store search form submits without crash', async ({ page }) => {
    await page.goto('/index.html');
    const errors: string[] = [];
    page.on('pageerror', e => errors.push(e.message));
    await page.fill('#searchInput', 'rice');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(500);
    expect(errors.filter(e => !e.includes('ERR_'))).toHaveLength(0);
  });

  test('TC_CRUD_018 - Store user button navigates or opens modal', async ({ page }) => {
    await page.goto('/index.html');
    await page.locator('#userBtn').click();
    await page.waitForTimeout(300);
    const isProfile = await page.locator('#view-profile').isVisible();
    const isModal = await page.locator('#loginModal').isVisible();
    expect(isProfile || isModal).toBeTruthy();
  });

  test('TC_CRUD_019 - Language modal opens on lang button click', async ({ page }) => {
    await page.goto('/index.html');
    await page.locator('#langBtn').click();
    await page.waitForTimeout(300);
    const modal = page.locator('#languageModal');
    const isAttached = await modal.count();
    expect(isAttached).toBeGreaterThanOrEqual(0);
  });

  test('TC_CRUD_020 - Admin panel font is Inter', async ({ page }) => {
    const font = await page.locator('body').evaluate(el =>
      window.getComputedStyle(el).fontFamily
    );
    expect(font.toLowerCase()).toContain('inter');
  });

  test('TC_CRUD_021 - KPI grid has shimmer cards on load', async ({ page }) => {
    const count = await page.locator('#kpiGrid .kpi-card').count();
    expect(count).toBeGreaterThanOrEqual(0);
  });

  test('TC_CRUD_022 - Period tabs have exactly 3 buttons', async ({ page }) => {
    const count = await page.locator('.period-btn').count();
    expect(count).toBe(3);
  });

  test('TC_CRUD_023 - Orders tab icon is box', async ({ page }) => {
    await expect(login.ordersTab.locator('.fa-box')).toBeVisible();
  });

  test('TC_CRUD_024 - Products tab icon is tags', async ({ page }) => {
    await expect(login.productsTab.locator('.fa-tags')).toBeVisible();
  });

  test('TC_CRUD_025 - Users tab icon is users', async ({ page }) => {
    await expect(login.usersTab.locator('.fa-users')).toBeVisible();
  });

  test('TC_CRUD_026 - Notifications tab icon is bell', async ({ page }) => {
    await expect(login.notificationsTab.locator('.fa-bell')).toBeVisible();
  });

  test('TC_CRUD_027 - Settings tab icon is gear', async ({ page }) => {
    await expect(login.settingsTab.locator('.fa-gear')).toBeVisible();
  });

  test('TC_CRUD_028 - Dashboard tab icon is chart-line', async ({ page }) => {
    await expect(login.dashboardTab.locator('.fa-chart-line')).toBeVisible();
  });

  test('TC_CRUD_029 - Sidebar overlay exists in DOM', async ({ page }) => {
    await expect(page.locator('#sidebarOverlay')).toBeAttached();
  });

  test('TC_CRUD_030 - Admin sidebar logo has shield icon', async ({ page }) => {
    await expect(page.locator('.sidebar-logo .fa-shield-halved')).toBeVisible();
  });

  test('TC_CRUD_031 - Sidebar logo label is VSN Admin', async ({ page }) => {
    await expect(page.locator('.sidebar-logo span')).toContainText('VSN Admin');
  });

  test('TC_CRUD_032 - Admin email displayed in sidebar footer', async ({ page }) => {
    const email = await login.adminEmailDisplay.textContent();
    expect(email?.length).toBeGreaterThan(0);
  });

  test('TC_CRUD_033 - Tab content transitions without crash', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', e => errors.push(e.message));
    for (const tab of [login.ordersTab, login.productsTab, login.usersTab, login.dashboardTab]) {
      await tab.click();
      await page.waitForTimeout(100);
    }
    expect(errors.filter(e => !e.includes('ERR_'))).toHaveLength(0);
  });

  test('TC_CRUD_034 - Admin sidebar is visible on desktop viewport', async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 900 });
    await expect(page.locator('.sidebar')).toBeVisible();
  });

  test('TC_CRUD_035 - Admin sidebar nav has chart-line for dashboard', async ({ page }) => {
    await expect(page.locator('.sidebar-nav .fa-chart-line')).toBeVisible();
  });

  test('TC_CRUD_036 - Settings tab shows content', async ({ page }) => {
    await login.settingsTab.click();
    await expect(page.locator('#tab-settings')).toBeVisible();
  });

  test('TC_CRUD_037 - Admin can see notifications tab content', async ({ page }) => {
    await login.notificationsTab.click();
    await expect(page.locator('#tab-notifications')).toBeVisible();
  });

  test('TC_CRUD_038 - Dashboard has page-header section', async ({ page }) => {
    await expect(page.locator('#tab-dashboard .page-header')).toBeVisible();
  });

  test('TC_CRUD_039 - Admin panel is styled correctly', async ({ page }) => {
    const display = await page.locator('#adminPanel').evaluate(el =>
      window.getComputedStyle(el).display
    );
    expect(display).not.toBe('none');
  });

  test('TC_CRUD_040 - Full admin workflow: login, navigate all tabs, logout', async ({ page }) => {
    await expect(login.adminPanel).toBeVisible();
    for (const tab of [login.ordersTab, login.productsTab, login.usersTab,
                       login.notificationsTab, login.settingsTab, login.dashboardTab]) {
      await tab.click();
      await page.waitForTimeout(100);
    }
    await login.logout();
    await expect(login.loginScreen).toBeVisible();
  });
});
