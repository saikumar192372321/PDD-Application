# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: smoke.spec.ts >> Smoke Tests for CI/CD >> TC_SMOKE_001 - Verify VSN Grocery Store page loads correctly
- Location: automation/tests/smoke.spec.ts:5:7

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator: locator('.store-title')
Expected: visible
Timeout: 5000ms
Error: element(s) not found

Call log:
  - Expect "toBeVisible" with timeout 5000ms
  - waiting for locator('.store-title')

```

```yaml
- navigation:
  - heading "VSN Grocery" [level=1]
  - link "Home":
    - /url: "#"
  - link "Categories":
    - /url: "#"
  - link "Offers":
    - /url: "#"
  - link "My Orders":
    - /url: "#"
  - link "AI Assistant":
    - /url: "#"
  - link "Analytics":
    - /url: "#"
  - text: 
  - textbox "Search products..."
  - button " 0"
  - button ""
  - button ""
  - button ""
  - button ""
- banner:
  - text:  Fastest Delivery
  - heading "Fresh Groceries, Delivered to Your Door." [level=2]
  - paragraph: Experience the finest quality products selected just for you. Wholesale pricing for all.
  - button "Shop Now "
  - text: 
  - heading "100% Organic" [level=4]
  - paragraph: Fresh from farms
  - img "Fresh Vegetables"
- heading "Trending Products" [level=3]
- link "View All →":
  - /url: "#"
- paragraph: No products found.
- contentinfo:
  - heading "VSN Grocery" [level=1]
  - paragraph: Delivering premium quality fresh groceries directly to your door at wholesale pricing.
  - link "":
    - /url: "#"
  - link "":
    - /url: "#"
  - link "":
    - /url: "#"
  - heading "Quick Links" [level=4]
  - list:
    - listitem:
      - link "Home":
        - /url: "#"
    - listitem:
      - link "Shop Categories":
        - /url: "#"
    - listitem:
      - link "Latest Offers":
        - /url: "#"
    - listitem:
      - link "Your Cart":
        - /url: "#"
  - heading "Customer Support" [level=4]
  - list:
    - listitem:
      - link "Track Order":
        - /url: "#"
    - listitem:
      - link "Return Policy":
        - /url: "#"
    - listitem:
      - link "FAQs":
        - /url: "#"
    - listitem:
      - link "Contact Us":
        - /url: "#"
  - heading "Contact Info" [level=4]
  - list:
    - listitem:  123 Wholesale Market, Mumbai
    - listitem:  +91 98765 43210
    - listitem:  support@vsngrocery.com
  - text: © 2026 VSN Grocery. All Rights Reserved.
- text:  AI Assistant  Hi! Need help with your wholesale order?
- button "Price of Sugar"
- button "Offers"
- button "Delivery Rules"
- button ""
- textbox "Type a message..."
- button ""
- button ""
- button ""
- button ""
- button ""
- heading "Choose Language" [level=3]
- paragraph: अपनी भाषा चुनें | మీ భాషను ఎంచుకోండి | உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்
- button "🇬🇧 English"
- button "🇮🇳 हिन्दी (Hindi)"
- button "🇮🇳 తెలుగు (Telugu)"
- button "🇮🇳 தமிழ் (Tamil)"
- button "Confirm Selection"
```

# Test source

```ts
  1  | import { test, expect } from '@playwright/test';
  2  | 
  3  | test.describe('Smoke Tests for CI/CD', () => {
  4  | 
  5  |   test('TC_SMOKE_001 - Verify VSN Grocery Store page loads correctly', async ({ page }) => {
  6  |     await page.goto('/index.html');
  7  |     await expect(page).toHaveTitle(/VSN Grocery/);
  8  |     const storeTitle = page.locator('.store-title');
> 9  |     await expect(storeTitle).toBeVisible({ timeout: 5000 });
     |                              ^ Error: expect(locator).toBeVisible() failed
  10 |   });
  11 | 
  12 |   test('TC_SMOKE_002 - Verify Store Navigation Bar is present', async ({ page }) => {
  13 |     await page.goto('/index.html');
  14 |     const navbar = page.locator('nav.store-nav');
  15 |     await expect(navbar).toBeVisible({ timeout: 5000 });
  16 |   });
  17 | 
  18 |   test('TC_SMOKE_003 - Verify Admin Login page loads correctly', async ({ page }) => {
  19 |     await page.goto('/admin.html');
  20 |     await expect(page).toHaveTitle(/VSN Admin/);
  21 |     const emailInput = page.locator('#adminEmail');
  22 |     await expect(emailInput).toBeVisible({ timeout: 5000 });
  23 |   });
  24 | 
  25 |   test('TC_SMOKE_004 - Verify Admin Login button is present', async ({ page }) => {
  26 |     await page.goto('/admin.html');
  27 |     const loginBtn = page.locator('#loginBtn');
  28 |     await expect(loginBtn).toBeVisible({ timeout: 5000 });
  29 |     await expect(loginBtn).toHaveText(/Login/);
  30 |   });
  31 | 
  32 | });
  33 | 
```