import { test, expect } from '@playwright/test';

test.describe('Smoke Tests for CI/CD', () => {

  test('TC_SMOKE_001 - Verify VSN Grocery Store page loads correctly', async ({ page }) => {
    await page.goto('/index.html');
    await expect(page).toHaveTitle(/VSN Grocery/);
    const storeTitle = page.locator('.store-title');
    await expect(storeTitle).toBeVisible({ timeout: 5000 });
  });

  test('TC_SMOKE_002 - Verify Store Navigation Bar is present', async ({ page }) => {
    await page.goto('/index.html');
    const navbar = page.locator('nav.store-nav');
    await expect(navbar).toBeVisible({ timeout: 5000 });
  });

  test('TC_SMOKE_003 - Verify Admin Login page loads correctly', async ({ page }) => {
    await page.goto('/admin.html');
    await expect(page).toHaveTitle(/VSN Admin/);
    const emailInput = page.locator('#adminEmail');
    await expect(emailInput).toBeVisible({ timeout: 5000 });
  });

  test('TC_SMOKE_004 - Verify Admin Login button is present', async ({ page }) => {
    await page.goto('/admin.html');
    const loginBtn = page.locator('#loginBtn');
    await expect(loginBtn).toBeVisible({ timeout: 5000 });
    await expect(loginBtn).toHaveText(/Login/);
  });

});
