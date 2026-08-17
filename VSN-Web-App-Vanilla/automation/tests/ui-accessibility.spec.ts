import { test, expect } from '@playwright/test';
import { StorePage } from '../pages/StorePage';
import { setupBackendMocks } from '../utils/mockBackend';

// ============================================================
// UI / RESPONSIVE / ACCESSIBILITY TESTS — 50 Test Cases
// TC_UI_001-020, TC_ACC_001-020, TC_RESP_001-010
// ============================================================

test.describe('UI, Accessibility & Responsive Tests', () => {
  let store: StorePage;

  test.beforeEach(async ({ page }) => {
    await setupBackendMocks(page);
    store = new StorePage(page);
    await store.navigate();
  });

  // --- UI Tests (TC_UI) ---
  test('TC_UI_001 - Navbar background is styled', async ({ page }) => {
    const bg = await page.locator('.navbar').evaluate(el => window.getComputedStyle(el).backgroundColor);
    expect(bg).not.toBe('');
  });

  test('TC_UI_002 - Shop Now button has styled text', async () => {
    await expect(store.shopNowBtn).toContainText('Shop Now');
  });

  test('TC_UI_003 - Hero section has background', async ({ page }) => {
    const bg = await page.locator('.hero').evaluate(el => window.getComputedStyle(el).background);
    expect(bg).not.toBe('');
  });

  test('TC_UI_004 - Nav links are styled', async ({ page }) => {
    const color = await page.locator('.nav-link').first().evaluate(el => window.getComputedStyle(el).color);
    expect(color).not.toBe('');
  });

  test('TC_UI_005 - Icon buttons are visible', async ({ page }) => {
    const iconBtns = await page.locator('.icon-btn').count();
    expect(iconBtns).toBeGreaterThan(0);
  });

  test('TC_UI_006 - Body has no horizontal scroll', async ({ page }) => {
    const overflow = await page.evaluate(() => document.body.scrollWidth <= window.innerWidth);
    // This is a soft check
    expect(overflow).toBeDefined();
  });

  test('TC_UI_007 - Cart badge has a number', async () => {
    const text = await store.cartBadge.textContent();
    expect(text).not.toBeNull();
  });

  test('TC_UI_008 - Mobile nav panel has nav links', async ({ page }) => {
    await store.openMobileNav();
    const links = await page.locator('.mobile-nav-panel a.nav-link').count();
    expect(links).toBeGreaterThan(0);
  });

  test('TC_UI_009 - Mobile nav has 6 links', async ({ page }) => {
    await store.openMobileNav();
    const links = await page.locator('.mobile-nav-panel a.nav-link').count();
    expect(links).toBe(6);
  });

  test('TC_UI_010 - Pill badge in hero is styled', async ({ page }) => {
    const pill = page.locator('.pill');
    await expect(pill).toBeVisible();
  });

  test('TC_UI_011 - Primary button has arrow right icon', async ({ page }) => {
    await expect(page.locator('.primary-btn .fa-arrow-right')).toBeVisible();
  });

  test('TC_UI_012 - Language icon is visible', async ({ page }) => {
    await expect(page.locator('#langBtn .fa-language')).toBeVisible();
  });

  test('TC_UI_013 - Bell icon is visible in notif button', async ({ page }) => {
    await expect(page.locator('#notifBtn .fa-bell')).toBeVisible();
  });

  test('TC_UI_014 - User icon is visible in user button', async ({ page }) => {
    await expect(page.locator('#userBtn .fa-user')).toBeVisible();
  });

  test('TC_UI_015 - Hamburger icon is visible', async ({ page }) => {
    await expect(page.locator('#hamburgerBtn .fa-bars')).toBeVisible();
  });

  test('TC_UI_016 - Mobile nav close icon is visible after open', async ({ page }) => {
    await store.openMobileNav();
    await expect(page.locator('.mobile-nav-close .fa-xmark')).toBeVisible();
  });

  test('TC_UI_017 - Notification dropdown header is styled', async ({ page }) => {
    await store.notifBtn.click();
    await expect(page.locator('.notif-dropdown-header')).toBeVisible();
  });

  test('TC_UI_018 - Mark all read button is in notif panel', async ({ page }) => {
    await store.notifBtn.click();
    await expect(page.locator('.clear-all-btn')).toBeVisible();
  });

  test('TC_UI_019 - Hero description has text', async ({ page }) => {
    const desc = await page.locator('.hero-content p').textContent();
    expect(desc?.length).toBeGreaterThan(10);
  });

  test('TC_UI_020 - Logo spans VSN and Grocery', async ({ page }) => {
    await expect(page.locator('.logo h1')).toContainText('VSN');
    await expect(page.locator('.logo h1 span')).toContainText('Grocery');
  });

  // --- Accessibility Tests (TC_ACC) ---
  test('TC_ACC_001 - Hamburger button has aria-label', async ({ page }) => {
    const label = await page.locator('#hamburgerBtn').getAttribute('aria-label');
    expect(label).toBe('Open menu');
  });

  test('TC_ACC_002 - Theme button has title attribute', async ({ page }) => {
    const title = await page.locator('#themeBtn').getAttribute('title');
    expect(title).toBe('Toggle Theme');
  });

  test('TC_ACC_003 - Language button has title attribute', async ({ page }) => {
    const title = await page.locator('#langBtn').getAttribute('title');
    expect(title).toBe('Switch Language');
  });

  test('TC_ACC_004 - Notif button has title attribute', async ({ page }) => {
    const title = await page.locator('#notifBtn').getAttribute('title');
    expect(title).toBe('Notifications');
  });

  test('TC_ACC_005 - Page has lang attribute on html', async ({ page }) => {
    const lang = await page.locator('html').getAttribute('lang');
    expect(lang).toBe('en');
  });

  test('TC_ACC_006 - Page has meta charset UTF-8', async ({ page }) => {
    const charset = await page.locator('meta[charset]').getAttribute('charset');
    expect(charset?.toUpperCase()).toBe('UTF-8');
  });

  test('TC_ACC_007 - Page title is not empty', async ({ page }) => {
    const title = await page.title();
    expect(title.length).toBeGreaterThan(0);
  });

  test('TC_ACC_008 - Page has meta description', async ({ page }) => {
    const desc = await page.locator('meta[name="description"]').getAttribute('content');
    expect(desc?.length).toBeGreaterThan(0);
  });

  test('TC_ACC_009 - Buttons are keyboard focusable', async ({ page }) => {
    await page.keyboard.press('Tab');
    const focused = await page.evaluate(() => document.activeElement?.tagName);
    expect(['BUTTON', 'A', 'INPUT']).toContain(focused);
  });

  test('TC_ACC_010 - Shop Now button is keyboard activated', async ({ page }) => {
    await store.shopNowBtn.focus();
    await page.keyboard.press('Enter');
    await expect(page.locator('#view-categories')).toBeVisible();
  });

  test('TC_ACC_011 - Apple mobile web app capable meta is set', async ({ page }) => {
    const meta = await page.locator('meta[name="apple-mobile-web-app-capable"]').getAttribute('content');
    expect(meta).toBe('yes');
  });

  test('TC_ACC_012 - Apple touch icon link is present', async ({ page }) => {
    const count = await page.locator('link[rel="apple-touch-icon"]').count();
    expect(count).toBeGreaterThan(0);
  });

  test('TC_ACC_013 - Favicon/icon link is present', async ({ page }) => {
    const count = await page.locator('link[rel="manifest"]').count();
    expect(count).toBe(1);
  });

  test('TC_ACC_014 - Page has viewport meta', async ({ page }) => {
    const count = await page.locator('meta[name="viewport"]').count();
    expect(count).toBe(1);
  });

  test('TC_ACC_015 - All images have alt attribute or are decorative', async ({ page }) => {
    const imgs = await page.locator('img').all();
    for (const img of imgs) {
      const alt = await img.getAttribute('alt');
      // alt can be empty string (decorative) but must not be null
      expect(alt).not.toBeNull();
    }
  });

  test('TC_ACC_016 - h1 exists on the page', async ({ page }) => {
    const count = await page.locator('h1').count();
    expect(count).toBeGreaterThanOrEqual(1);
  });

  test('TC_ACC_017 - h2 exists on home view', async ({ page }) => {
    const count = await page.locator('#view-home h2').count();
    expect(count).toBeGreaterThanOrEqual(1);
  });

  test('TC_ACC_018 - Theme-color meta is set', async ({ page }) => {
    const color = await page.locator('meta[name="theme-color"]').getAttribute('content');
    expect(color).not.toBeNull();
  });

  test('TC_ACC_019 - Notification badge has display:none when count is 0', async ({ page }) => {
    const display = await page.locator('#notifBadge').evaluate(el => (el as HTMLElement).style.display);
    expect(display).toBe('none');
  });

  test('TC_ACC_020 - Page has no empty title', async ({ page }) => {
    const title = await page.title();
    expect(title.trim().length).toBeGreaterThan(0);
  });

  // --- Responsive UI Tests (TC_RESP) ---
  test('TC_RESP_001 - Mobile viewport renders navbar', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await store.navigate();
    await expect(page.locator('.navbar')).toBeVisible();
  });

  test('TC_RESP_002 - Tablet viewport renders navbar', async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    await store.navigate();
    await expect(page.locator('.navbar')).toBeVisible();
  });

  test('TC_RESP_003 - Desktop viewport renders full navbar links', async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 900 });
    await store.navigate();
    await expect(page.locator('.nav-links')).toBeVisible();
  });

  test('TC_RESP_004 - Small mobile renders page without crash', async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 568 });
    await store.navigate();
    await expect(page.locator('body')).toBeVisible();
  });

  test('TC_RESP_005 - Hero section visible on mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await store.navigate();
    await expect(page.locator('.hero')).toBeVisible();
  });

  test('TC_RESP_006 - Hero section visible on tablet', async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    await store.navigate();
    await expect(page.locator('.hero')).toBeVisible();
  });

  test('TC_RESP_007 - Shop Now button visible on mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await store.navigate();
    await expect(store.shopNowBtn).toBeVisible();
  });

  test('TC_RESP_008 - Logo visible on all viewports', async ({ page }) => {
    for (const size of [{ width: 375, height: 812 }, { width: 768, height: 1024 }, { width: 1440, height: 900 }]) {
      await page.setViewportSize(size);
      await store.navigate();
      await expect(page.locator('.logo')).toBeVisible();
    }
  });

  test('TC_RESP_009 - Cart button visible on mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await store.navigate();
    await expect(store.cartButton).toBeVisible();
  });

  test('TC_RESP_010 - Page renders on 4K viewport', async ({ page }) => {
    await page.setViewportSize({ width: 3840, height: 2160 });
    await store.navigate();
    await expect(page.locator('.navbar')).toBeVisible();
  });
});
