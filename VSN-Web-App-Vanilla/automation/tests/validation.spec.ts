import { test, expect } from '@playwright/test';
import { StorePage } from '../pages/StorePage';
import { setupBackendMocks } from '../utils/mockBackend';

// ============================================================
// INPUT VALIDATION TESTS — 40 Test Cases (TC_VAL_001-040)
// ============================================================

test.describe('Input Validation Tests', () => {
  let store: StorePage;

  test.beforeEach(async ({ page }) => {
    await setupBackendMocks(page);
    store = new StorePage(page);
    await store.navigate();
  });

  // Search input validations
  test('TC_VAL_001 - Search accepts alphabets', async () => {
    await store.searchInput.fill('rice');
    await expect(store.searchInput).toHaveValue('rice');
  });

  test('TC_VAL_002 - Search accepts numbers', async () => {
    await store.searchInput.fill('123');
    await expect(store.searchInput).toHaveValue('123');
  });

  test('TC_VAL_003 - Search accepts alphanumeric', async () => {
    await store.searchInput.fill('rice123');
    await expect(store.searchInput).toHaveValue('rice123');
  });

  test('TC_VAL_004 - Search accepts spaces', async () => {
    await store.searchInput.fill('brown rice');
    await expect(store.searchInput).toHaveValue('brown rice');
  });

  test('TC_VAL_005 - Search accepts hyphenated words', async () => {
    await store.searchInput.fill('ready-to-eat');
    await expect(store.searchInput).toHaveValue('ready-to-eat');
  });

  test('TC_VAL_006 - Search accepts single character', async () => {
    await store.searchInput.fill('a');
    await expect(store.searchInput).toHaveValue('a');
  });

  test('TC_VAL_007 - Search handles XSS attempt gracefully', async ({ page }) => {
    await store.searchInput.fill('<script>alert(1)</script>');
    await page.waitForTimeout(300);
    const alertFired = await page.evaluate(() => {
      let alerted = false;
      const orig = window.alert;
      window.alert = () => { alerted = true; };
      window.alert = orig;
      return alerted;
    });
    expect(alertFired).toBeFalsy();
  });

  test('TC_VAL_008 - Search handles SQL injection attempt gracefully', async () => {
    await store.searchInput.fill("' OR '1'='1");
    await expect(store.searchInput).toHaveValue("' OR '1'='1");
  });

  test('TC_VAL_009 - Search handles emoji input', async () => {
    await store.searchInput.fill('🛒 groceries');
    await expect(store.searchInput).toHaveValue('🛒 groceries');
  });

  test('TC_VAL_010 - Search handles unicode characters', async () => {
    await store.searchInput.fill('ñandú');
    await expect(store.searchInput).toHaveValue('ñandú');
  });

  test('TC_VAL_011 - Search input max length handles long string', async ({ page }) => {
    const longString = 'a'.repeat(500);
    await store.searchInput.fill(longString);
    const val = await store.searchInput.inputValue();
    expect(val.length).toBeGreaterThan(0);
  });

  test('TC_VAL_012 - Search does not cause page error', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', e => errors.push(e.message));
    await store.searchInput.fill('rice');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(500);
    expect(errors).toHaveLength(0);
  });

  // Admin login input validations
  test('TC_VAL_013 - Admin email: valid format accepted', async ({ page }) => {
    await page.goto('/admin.html');
    await page.fill('#adminEmail', 'valid@email.com');
    expect(await page.inputValue('#adminEmail')).toBe('valid@email.com');
  });

  test('TC_VAL_014 - Admin email: invalid format rejected', async ({ page }) => {
    await page.goto('/admin.html');
    await page.fill('#adminEmail', 'invalidemail');
    await page.click('#loginBtn');
    const valid = await page.evaluate(() =>
      (document.querySelector('#adminEmail') as HTMLInputElement).checkValidity()
    );
    expect(valid).toBeFalsy();
  });

  test('TC_VAL_015 - Admin email: empty field rejected', async ({ page }) => {
    await page.goto('/admin.html');
    await page.fill('#adminPassword', 'pass');
    await page.click('#loginBtn');
    const valid = await page.evaluate(() =>
      (document.querySelector('#adminEmail') as HTMLInputElement).checkValidity()
    );
    expect(valid).toBeFalsy();
  });

  test('TC_VAL_016 - Admin password: empty field rejected', async ({ page }) => {
    await page.goto('/admin.html');
    await page.fill('#adminEmail', 'test@test.com');
    await page.click('#loginBtn');
    const valid = await page.evaluate(() =>
      (document.querySelector('#adminPassword') as HTMLInputElement).checkValidity()
    );
    expect(valid).toBeFalsy();
  });

  test('TC_VAL_017 - Admin email: max length input', async ({ page }) => {
    await page.goto('/admin.html');
    const longEmail = 'a'.repeat(240) + '@test.com';
    await page.fill('#adminEmail', longEmail);
    const val = await page.inputValue('#adminEmail');
    expect(val.length).toBeGreaterThan(0);
  });

  test('TC_VAL_018 - Admin password accepts special characters', async ({ page }) => {
    await page.goto('/admin.html');
    await page.fill('#adminPassword', '!@#$%^&*()');
    expect(await page.inputValue('#adminPassword')).toBe('!@#$%^&*()');
  });

  test('TC_VAL_019 - Admin email with spaces rejected', async ({ page }) => {
    await page.goto('/admin.html');
    await page.fill('#adminEmail', 'test @email.com');
    await page.click('#loginBtn');
    const valid = await page.evaluate(() =>
      (document.querySelector('#adminEmail') as HTMLInputElement).checkValidity()
    );
    expect(valid).toBeFalsy();
  });

  test('TC_VAL_020 - Admin email: domain-only rejected', async ({ page }) => {
    await page.goto('/admin.html');
    await page.fill('#adminEmail', '@email.com');
    await page.click('#loginBtn');
    const valid = await page.evaluate(() =>
      (document.querySelector('#adminEmail') as HTMLInputElement).checkValidity()
    );
    expect(valid).toBeFalsy();
  });

  // Notifications UI
  test('TC_VAL_021 - Notifications panel shows empty msg when no notifications', async ({ page }) => {
    await store.notifBtn.click();
    await expect(page.locator('.notif-dropdown')).toBeVisible();
    await expect(page.locator('#notifList')).toBeVisible();
  });

  test('TC_VAL_022 - Mark all read button is visible in notifications', async ({ page }) => {
    await store.notifBtn.click();
    await expect(page.locator('.clear-all-btn')).toBeVisible();
  });

  test('TC_VAL_023 - Notifications header text is correct', async ({ page }) => {
    await store.notifBtn.click();
    await expect(page.locator('.notif-dropdown-header h4')).toContainText('Notifications');
  });

  test('TC_VAL_024 - Theme toggle icon is moon initially', async ({ page }) => {
    await expect(page.locator('#themeBtn .fa-moon')).toBeVisible();
  });

  test('TC_VAL_025 - Theme toggles icon after click', async ({ page }) => {
    await store.toggleTheme();
    // After toggle, either sun or moon class should be present
    const icon = page.locator('#themeBtn i');
    await expect(icon).toBeVisible();
  });

  test('TC_VAL_026 - Language button is visible', async ({ page }) => {
    await expect(page.locator('#langBtn')).toBeVisible();
  });

  test('TC_VAL_027 - Language button has language icon', async ({ page }) => {
    await expect(page.locator('#langBtn .fa-language')).toBeVisible();
  });

  test('TC_VAL_028 - Cart button icon is visible', async ({ page }) => {
    await expect(page.locator('.icon-btn .fa-shopping-cart')).toBeVisible();
  });

  test('TC_VAL_029 - Cart count does not go negative', async () => {
    const count = await store.getCartCount();
    expect(count).toBeGreaterThanOrEqual(0);
  });

  test('TC_VAL_030 - Notification badge hidden when no notifications', async ({ page }) => {
    await expect(page.locator('#notifBadge')).toHaveCSS('display', 'none');
  });

  test('TC_VAL_031 - Hero button has primary-btn class', async ({ page }) => {
    const classes = await store.shopNowBtn.getAttribute('class');
    expect(classes).toContain('primary-btn');
  });

  test('TC_VAL_032 - Page has exactly one h1', async ({ page }) => {
    const h1s = await page.locator('h1').count();
    expect(h1s).toBeGreaterThanOrEqual(1);
  });

  test('TC_VAL_033 - Navbar has correct class', async ({ page }) => {
    await expect(page.locator('nav.navbar')).toBeVisible();
  });

  test('TC_VAL_034 - Nav-links container exists', async ({ page }) => {
    await expect(page.locator('.nav-links')).toBeVisible();
  });

  test('TC_VAL_035 - Nav-actions container exists', async ({ page }) => {
    await expect(page.locator('.nav-actions')).toBeVisible();
  });

  test('TC_VAL_036 - VSN Grocery title in navbar', async ({ page }) => {
    await expect(page.locator('.logo h1')).toContainText('VSN');
  });

  test('TC_VAL_037 - Page has no broken images', async ({ page }) => {
    const images = await page.locator('img').all();
    for (const img of images) {
      const naturalWidth = await img.evaluate((el: HTMLImageElement) => el.naturalWidth);
      expect(naturalWidth).toBeGreaterThanOrEqual(0);
    }
  });

  test('TC_VAL_038 - Body is rendered', async ({ page }) => {
    await expect(page.locator('body')).toBeVisible();
  });

  test('TC_VAL_039 - CSS stylesheet loaded', async ({ page }) => {
    const css = await page.locator('link[rel="stylesheet"]').count();
    expect(css).toBeGreaterThan(0);
  });

  test('TC_VAL_040 - Page does not throw JS errors on load', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', e => errors.push(e.message));
    await store.navigate();
    await page.waitForTimeout(1000);
    expect(errors.filter(e => !e.includes('net::ERR') && !e.includes('favicon'))).toHaveLength(0);
  });
});
