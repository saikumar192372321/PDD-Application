import { test, expect } from '@playwright/test';
import { StorePage } from '../pages/StorePage';
import testData from '../data/testData.json';
import { setupBackendMocks } from '../utils/mockBackend';

// ============================================================
// NAVIGATION TESTS — 30 Test Cases (TC_NAV_001 to TC_NAV_030)
// ============================================================

test.describe('Navigation Tests', () => {
  let store: StorePage;

  test.beforeEach(async ({ page }) => {
    await setupBackendMocks(page);
    store = new StorePage(page);
    await store.navigate();
  });

  test('TC_NAV_001 - Page loads successfully', async ({ page }) => {
    await expect(page).toHaveTitle(/VSN Grocery/);
  });

  test('TC_NAV_002 - Navbar is visible', async ({ page }) => {
    await expect(page.locator('.navbar')).toBeVisible();
  });

  test('TC_NAV_003 - Logo is visible in navbar', async ({ page }) => {
    await expect(page.locator('.logo h1')).toBeVisible();
  });

  test('TC_NAV_004 - Home nav link is active by default', async ({ page }) => {
    await expect(page.locator('a.nav-link.active[data-view="home"]')).toBeVisible();
  });

  test('TC_NAV_005 - Home view is visible by default', async ({ page }) => {
    await expect(page.locator('#view-home')).toHaveClass(/active-view/);
  });

  test('TC_NAV_006 - Navigate to Categories view', async ({ page }) => {
    await store.clickNavLink('categories');
    await expect(page.locator('#view-categories')).toBeVisible();
  });

  test('TC_NAV_007 - Navigate to Offers view', async ({ page }) => {
    await store.clickNavLink('offers');
    await expect(page.locator('#view-offers')).toBeVisible();
  });

  test('TC_NAV_008 - Navigate to Orders view', async ({ page }) => {
    await store.clickNavLink('orders');
    await expect(page.locator('#view-orders')).toBeVisible();
  });

  test('TC_NAV_009 - Navigate to AI Chatbot view', async ({ page }) => {
    await store.clickNavLink('chatbot');
    await expect(page.locator('#view-chatbot')).toBeVisible();
  });

  test('TC_NAV_010 - Navigate to Analytics view', async ({ page }) => {
    await store.clickNavLink('analytics');
    await expect(page.locator('#view-analytics')).toBeVisible();
  });

  test('TC_NAV_011 - Navigate back to Home from Categories', async ({ page }) => {
    await store.clickNavLink('categories');
    await store.clickNavLink('home');
    await expect(page.locator('#view-home')).toHaveClass(/active-view/);
  });

  test('TC_NAV_012 - Hamburger button is visible', async () => {
    await expect(store.hamburgerBtn).toBeVisible();
  });

  test('TC_NAV_013 - Mobile nav opens on hamburger click', async ({ page }) => {
    await store.openMobileNav();
    await expect(page.locator('#mobileNav')).toBeVisible();
  });

  test('TC_NAV_014 - Mobile nav closes on close button click', async ({ page }) => {
    await store.openMobileNav();
    await page.locator('.mobile-nav-close').click();
    await expect(page.locator('#mobileNav')).not.toHaveClass(/open/);
  });

  test('TC_NAV_015 - Cart button is visible in navbar', async () => {
    await expect(store.cartButton).toBeVisible();
  });

  test('TC_NAV_016 - Cart badge shows 0 initially', async () => {
    const count = await store.getCartCount();
    expect(count).toBe(0);
  });

  test('TC_NAV_017 - Notification bell button is visible', async () => {
    await expect(store.notifBtn).toBeVisible();
  });

  test('TC_NAV_018 - Theme toggle button is visible', async () => {
    await expect(store.themeBtn).toBeVisible();
  });

  test('TC_NAV_019 - User profile button is visible', async () => {
    await expect(store.userBtn).toBeVisible();
  });

  test('TC_NAV_020 - Theme toggle changes theme', async ({ page }) => {
    const bodyBefore = await page.locator('body').getAttribute('class');
    await store.toggleTheme();
    const bodyAfter = await page.locator('body').getAttribute('class');
    expect(bodyBefore).not.toBe(bodyAfter);
  });

  test('TC_NAV_021 - Search bar is visible in navbar', async () => {
    await expect(store.searchInput).toBeVisible();
  });

  test('TC_NAV_022 - Logo click navigates to home', async ({ page }) => {
    await store.clickNavLink('categories');
    await page.locator('.logo').click();
    await expect(page.locator('#view-home')).toHaveClass(/active-view/);
  });

  test('TC_NAV_023 - Categories nav link is visible', async () => {
    await expect(store.categoriesNavLink).toBeVisible();
  });

  test('TC_NAV_024 - Offers nav link is visible', async () => {
    await expect(store.offersNavLink).toBeVisible();
  });

  test('TC_NAV_025 - Orders nav link is visible', async () => {
    await expect(store.ordersNavLink).toBeVisible();
  });

  test('TC_NAV_026 - Chatbot nav link is visible', async () => {
    await expect(store.chatbotNavLink).toBeVisible();
  });

  test('TC_NAV_027 - Analytics nav link is visible', async () => {
    await expect(store.analyticsNavLink).toBeVisible();
  });

  test('TC_NAV_028 - Notification dropdown hidden by default', async ({ page }) => {
    await expect(page.locator('#notifDropdown')).not.toBeVisible();
  });

  test('TC_NAV_029 - Notification dropdown toggles on bell click', async ({ page }) => {
    await store.notifBtn.click();
    await expect(page.locator('#notifDropdown')).toBeVisible();
  });

  test('TC_NAV_030 - Nav links count is 6', async ({ page }) => {
    const count = await page.locator('.nav-links a.nav-link').count();
    expect(count).toBe(6);
  });
});
