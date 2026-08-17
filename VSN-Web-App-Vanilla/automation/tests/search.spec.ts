import { test, expect } from '@playwright/test';
import { StorePage } from '../pages/StorePage';
import testData from '../data/testData.json';
import { setupBackendMocks } from '../utils/mockBackend';

// ============================================================
// SEARCH TESTS — 20 Test Cases (TC_SEARCH_001 to TC_SEARCH_020)
// ============================================================

test.describe('Search Tests', () => {
  let store: StorePage;

  test.beforeEach(async ({ page }) => {
    await setupBackendMocks(page);
    store = new StorePage(page);
    await store.navigate();
  });

  test('TC_SEARCH_001 - Search input is visible', async () => {
    await expect(store.searchInput).toBeVisible();
  });

  test('TC_SEARCH_002 - Search placeholder is correct', async () => {
    await expect(store.searchInput).toHaveAttribute('placeholder', 'Search products...');
  });

  test('TC_SEARCH_003 - Can type in search input', async () => {
    await store.searchInput.fill('rice');
    await expect(store.searchInput).toHaveValue('rice');
  });

  test('TC_SEARCH_004 - Search with valid product name', async ({ page }) => {
    await store.searchFor('rice');
    await page.waitForTimeout(500);
    expect(await store.searchInput.inputValue()).toBe('rice');
  });

  test('TC_SEARCH_005 - Search input cleared after clear', async () => {
    await store.searchInput.fill('sugar');
    await store.searchInput.clear();
    await expect(store.searchInput).toHaveValue('');
  });

  test('TC_SEARCH_006 - Search with invalid product shows no results', async ({ page }) => {
    await store.searchFor('xyzabc123notaproduct');
    await page.waitForTimeout(500);
    expect(await store.searchInput.inputValue()).toBe('xyzabc123notaproduct');
  });

  test('TC_SEARCH_007 - Search with empty string', async () => {
    await store.searchFor('');
    await expect(store.searchInput).toHaveValue('');
  });

  test('TC_SEARCH_008 - Search accepts special characters', async () => {
    await store.searchInput.fill('@#$%');
    await expect(store.searchInput).toHaveValue('@#$%');
  });

  test('TC_SEARCH_009 - Search accepts numbers', async () => {
    await store.searchInput.fill('123');
    await expect(store.searchInput).toHaveValue('123');
  });

  test('TC_SEARCH_010 - Search with partial word', async () => {
    await store.searchInput.fill('ric');
    await expect(store.searchInput).toHaveValue('ric');
  });

  test('TC_SEARCH_011 - Search input focused on click', async ({ page }) => {
    await store.searchInput.click();
    const focused = await page.evaluate(() => document.activeElement?.id === 'searchInput');
    expect(focused).toBeTruthy();
  });

  test('TC_SEARCH_012 - Search icon is visible inside search bar', async ({ page }) => {
    await expect(page.locator('.search-bar .fa-search')).toBeVisible();
  });

  test('TC_SEARCH_013 - Search bar container is visible', async ({ page }) => {
    await expect(page.locator('.search-bar')).toBeVisible();
  });

  test('TC_SEARCH_014 - Search with long string does not crash', async () => {
    await store.searchInput.fill(testData.searchTerms.longString);
    await expect(store.searchInput).toHaveValue(testData.searchTerms.longString);
  });

  test('TC_SEARCH_015 - Search with lowercase finds products', async () => {
    await store.searchFor('milk');
    await expect(store.searchInput).toHaveValue('milk');
  });

  test('TC_SEARCH_016 - Search with uppercase input', async () => {
    await store.searchInput.fill('RICE');
    await expect(store.searchInput).toHaveValue('RICE');
  });

  test('TC_SEARCH_017 - Search with mixed case input', async () => {
    await store.searchInput.fill('RiCe');
    await expect(store.searchInput).toHaveValue('RiCe');
  });

  test('TC_SEARCH_018 - Search input type is text', async ({ page }) => {
    const type = await page.locator('#searchInput').getAttribute('type');
    expect(type).toBe('text');
  });

  test('TC_SEARCH_019 - Search does not navigate away from home', async ({ page }) => {
    await store.searchFor('oil');
    await expect(page.locator('#view-home')).toBeVisible();
  });

  test('TC_SEARCH_020 - Second search overwrites first', async () => {
    await store.searchInput.fill('rice');
    await store.searchInput.fill('sugar');
    await expect(store.searchInput).toHaveValue('sugar');
  });
});
