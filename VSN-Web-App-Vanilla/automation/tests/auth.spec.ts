import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';
import testData from '../data/testData.json';

// ============================================================
// AUTHENTICATION TESTS — 40 Test Cases
// TC_AUTH_001 to TC_AUTH_040
// ============================================================

test.describe('Authentication Tests', () => {
  let loginPage: LoginPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    await loginPage.navigate();
  });

  // --- Valid Login ---
  test('TC_AUTH_001 - Valid admin login with correct credentials', async () => {
    await loginPage.login(testData.adminCredentials.valid.email, testData.adminCredentials.valid.password);
    await expect(loginPage.adminPanel).toBeVisible({ timeout: 5000 });
  });

  test('TC_AUTH_002 - Login screen is visible on page load', async () => {
    await expect(loginPage.loginScreen).toBeVisible();
  });

  test('TC_AUTH_003 - Admin panel is hidden before login', async () => {
    await expect(loginPage.adminPanel).toBeHidden();
  });

  test('TC_AUTH_004 - Email input field is present', async () => {
    await expect(loginPage.emailInput).toBeVisible();
  });

  test('TC_AUTH_005 - Password input field is present', async () => {
    await expect(loginPage.passwordInput).toBeVisible();
  });

  test('TC_AUTH_006 - Login button is present and clickable', async () => {
    await expect(loginPage.loginBtn).toBeVisible();
    await expect(loginPage.loginBtn).toBeEnabled();
  });

  test('TC_AUTH_007 - Error message hidden on initial load', async () => {
    await expect(loginPage.loginErr).toBeHidden();
  });

  test('TC_AUTH_008 - Back to Store link is visible', async () => {
    await expect(loginPage.backToStoreLink).toBeVisible();
  });

  test('TC_AUTH_009 - Back to Store link navigates to index.html', async ({ page }) => {
    await loginPage.backToStoreLink.click();
    await expect(page).toHaveURL(/index\.html/);
  });

  test('TC_AUTH_010 - Login with wrong password shows error', async () => {
    await loginPage.login(testData.adminCredentials.invalid[0].email, testData.adminCredentials.invalid[0].password);
    await expect(loginPage.loginErr).toBeVisible({ timeout: 3000 });
  });

  test('TC_AUTH_011 - Login with empty email', async ({ page }) => {
    await loginPage.passwordInput.fill('somepass');
    await loginPage.loginBtn.click();
    const isInvalid = await page.evaluate(() => {
      const el = document.querySelector('#adminEmail') as HTMLInputElement;
      return !el.validity.valid;
    });
    expect(isInvalid).toBeTruthy();
  });

  test('TC_AUTH_012 - Login with empty password', async ({ page }) => {
    await loginPage.emailInput.fill('admin@test.com');
    await loginPage.loginBtn.click();
    const isInvalid = await page.evaluate(() => {
      const el = document.querySelector('#adminPassword') as HTMLInputElement;
      return !el.validity.valid;
    });
    expect(isInvalid).toBeTruthy();
  });

  test('TC_AUTH_013 - Email field accepts valid email format', async () => {
    await loginPage.emailInput.fill('test@example.com');
    await expect(loginPage.emailInput).toHaveValue('test@example.com');
  });

  test('TC_AUTH_014 - Password field masks input', async ({ page }) => {
    const type = await page.locator('#adminPassword').getAttribute('type');
    expect(type).toBe('password');
  });

  test('TC_AUTH_015 - Email field type is email', async ({ page }) => {
    const type = await page.locator('#adminEmail').getAttribute('type');
    expect(type).toBe('email');
  });

  test('TC_AUTH_016 - Login form has required attribute on email', async ({ page }) => {
    const req = await page.locator('#adminEmail').getAttribute('required');
    expect(req).not.toBeNull();
  });

  test('TC_AUTH_017 - Login form has required attribute on password', async ({ page }) => {
    const req = await page.locator('#adminPassword').getAttribute('required');
    expect(req).not.toBeNull();
  });

  test('TC_AUTH_018 - Admin panel shows Dashboard tab after login', async () => {
    await loginPage.login(testData.adminCredentials.valid.email, testData.adminCredentials.valid.password);
    await expect(loginPage.dashboardTab).toBeVisible();
  });

  test('TC_AUTH_019 - Admin panel shows Orders tab after login', async () => {
    await loginPage.login(testData.adminCredentials.valid.email, testData.adminCredentials.valid.password);
    await expect(loginPage.ordersTab).toBeVisible();
  });

  test('TC_AUTH_020 - Admin panel shows Products tab after login', async () => {
    await loginPage.login(testData.adminCredentials.valid.email, testData.adminCredentials.valid.password);
    await expect(loginPage.productsTab).toBeVisible();
  });

  test('TC_AUTH_021 - Admin panel shows Users tab after login', async () => {
    await loginPage.login(testData.adminCredentials.valid.email, testData.adminCredentials.valid.password);
    await expect(loginPage.usersTab).toBeVisible();
  });

  test('TC_AUTH_022 - Admin panel shows Notifications tab after login', async () => {
    await loginPage.login(testData.adminCredentials.valid.email, testData.adminCredentials.valid.password);
    await expect(loginPage.notificationsTab).toBeVisible();
  });

  test('TC_AUTH_023 - Admin panel shows Settings tab after login', async () => {
    await loginPage.login(testData.adminCredentials.valid.email, testData.adminCredentials.valid.password);
    await expect(loginPage.settingsTab).toBeVisible();
  });

  test('TC_AUTH_024 - Logout button is visible after login', async () => {
    await loginPage.login(testData.adminCredentials.valid.email, testData.adminCredentials.valid.password);
    await expect(loginPage.logoutBtn).toBeVisible();
  });

  test('TC_AUTH_025 - Logout returns to login screen', async () => {
    await loginPage.login(testData.adminCredentials.valid.email, testData.adminCredentials.valid.password);
    await loginPage.logout();
    await expect(loginPage.loginScreen).toBeVisible();
  });

  test('TC_AUTH_026 - Admin email is displayed after login', async () => {
    await loginPage.login(testData.adminCredentials.valid.email, testData.adminCredentials.valid.password);
    await expect(loginPage.adminEmailDisplay).not.toBeEmpty();
  });

  test('TC_AUTH_027 - Page title is VSN Admin Panel', async ({ page }) => {
    await expect(page).toHaveTitle(/VSN Admin/);
  });

  test('TC_AUTH_028 - Login logo is visible', async ({ page }) => {
    await expect(page.locator('.login-logo')).toBeVisible();
  });

  test('TC_AUTH_029 - Login card is visible', async ({ page }) => {
    await expect(page.locator('.login-card')).toBeVisible();
  });

  test('TC_AUTH_030 - Form submission via Enter key works', async ({ page }) => {
    await loginPage.emailInput.fill(testData.adminCredentials.valid.email);
    await loginPage.passwordInput.fill(testData.adminCredentials.valid.password);
    await page.keyboard.press('Enter');
    await expect(loginPage.adminPanel).toBeVisible({ timeout: 5000 });
  });

  test('TC_AUTH_031 - Invalid email format rejected by browser', async ({ page }) => {
    await loginPage.emailInput.fill('notanemail');
    await loginPage.passwordInput.fill('somepass');
    await loginPage.loginBtn.click();
    const valid = await page.evaluate(() => (document.querySelector('#adminEmail') as HTMLInputElement).checkValidity());
    expect(valid).toBeFalsy();
  });

  test('TC_AUTH_032 - Login subtitle is visible', async ({ page }) => {
    await expect(page.locator('.login-sub')).toBeVisible();
  });

  test('TC_AUTH_033 - Login screen has shield icon', async ({ page }) => {
    await expect(page.locator('.login-logo .fa-shield-halved')).toBeVisible();
  });

  test('TC_AUTH_034 - Login screen disappears after successful login', async () => {
    await loginPage.login(testData.adminCredentials.valid.email, testData.adminCredentials.valid.password);
    await expect(loginPage.loginScreen).toBeHidden();
  });

  test('TC_AUTH_035 - Dashboard active by default after login', async ({ page }) => {
    await loginPage.login(testData.adminCredentials.valid.email, testData.adminCredentials.valid.password);
    await expect(page.locator('#tab-dashboard')).toBeVisible();
  });

  test('TC_AUTH_036 - Multiple failed logins show persistent error', async () => {
    for (let i = 0; i < 3; i++) {
      await loginPage.login('bad@email.com', 'wrong');
    }
    await expect(loginPage.loginErr).toBeVisible();
  });

  test('TC_AUTH_037 - Credentials cleared on manual clear', async () => {
    await loginPage.emailInput.fill('test@example.com');
    await loginPage.emailInput.clear();
    await expect(loginPage.emailInput).toHaveValue('');
  });

  test('TC_AUTH_038 - Password cleared on manual clear', async () => {
    await loginPage.passwordInput.fill('secret');
    await loginPage.passwordInput.clear();
    await expect(loginPage.passwordInput).toHaveValue('');
  });

  test('TC_AUTH_039 - Admin sidebar logo is visible after login', async ({ page }) => {
    await loginPage.login(testData.adminCredentials.valid.email, testData.adminCredentials.valid.password);
    await expect(page.locator('.sidebar-logo')).toBeVisible();
  });

  test('TC_AUTH_040 - Sidebar nav is visible after login', async ({ page }) => {
    await loginPage.login(testData.adminCredentials.valid.email, testData.adminCredentials.valid.password);
    await expect(page.locator('.sidebar-nav')).toBeVisible();
  });
});
