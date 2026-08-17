import { Page, Locator } from '@playwright/test';

export class StorePage {
  readonly page: Page;
  readonly searchInput: Locator;
  readonly cartBadge: Locator;
  readonly cartButton: Locator;
  readonly notifBtn: Locator;
  readonly notifBadge: Locator;
  readonly themeBtn: Locator;
  readonly userBtn: Locator;
  readonly hamburgerBtn: Locator;
  readonly homeNavLink: Locator;
  readonly categoriesNavLink: Locator;
  readonly offersNavLink: Locator;
  readonly ordersNavLink: Locator;
  readonly chatbotNavLink: Locator;
  readonly analyticsNavLink: Locator;
  readonly heroTitle: Locator;
  readonly shopNowBtn: Locator;
  readonly mobileNav: Locator;
  readonly mobileNavClose: Locator;
  readonly loginModal: Locator;
  readonly viewHome: Locator;
  readonly viewCategories: Locator;
  readonly viewOffers: Locator;
  readonly viewOrders: Locator;
  readonly viewCart: Locator;
  readonly viewProfile: Locator;
  readonly viewAnalytics: Locator;
  readonly viewChatbot: Locator;

  constructor(page: Page) {
    this.page = page;
    this.searchInput = page.locator('#searchInput');
    this.cartBadge = page.locator('#cartBadge');
    this.cartButton = page.locator('button.icon-btn').filter({ has: page.locator('.fa-shopping-cart') });
    this.notifBtn = page.locator('#notifBtn');
    this.notifBadge = page.locator('#notifBadge');
    this.themeBtn = page.locator('#themeBtn');
    this.userBtn = page.locator('#userBtn');
    this.hamburgerBtn = page.locator('#hamburgerBtn');
    this.homeNavLink = page.locator('a.nav-link[data-view="home"]');
    this.categoriesNavLink = page.locator('a.nav-link[data-view="categories"]');
    this.offersNavLink = page.locator('a.nav-link[data-view="offers"]');
    this.ordersNavLink = page.locator('a.nav-link[data-view="orders"]');
    this.chatbotNavLink = page.locator('a.nav-link[data-view="chatbot"]');
    this.analyticsNavLink = page.locator('a.nav-link[data-view="analytics"]');
    this.heroTitle = page.locator('.hero-content h2');
    this.shopNowBtn = page.locator('.primary-btn').first();
    this.mobileNav = page.locator('#mobileNav');
    this.mobileNavClose = page.locator('.mobile-nav-close');
    this.loginModal = page.locator('#loginModal');
    this.viewHome = page.locator('#view-home');
    this.viewCategories = page.locator('#view-categories');
    this.viewOffers = page.locator('#view-offers');
    this.viewOrders = page.locator('#view-orders');
    this.viewCart = page.locator('#view-cart');
    this.viewProfile = page.locator('#view-profile');
    this.viewAnalytics = page.locator('#view-analytics');
    this.viewChatbot = page.locator('#view-chatbot');
  }

  async navigate() {
    await this.page.goto('/index.html');
    await this.page.waitForLoadState('networkidle');
  }

  async searchFor(term: string) {
    await this.searchInput.fill(term);
    await this.page.keyboard.press('Enter');
  }

  async clickNavLink(view: 'home' | 'categories' | 'offers' | 'orders' | 'chatbot' | 'analytics') {
    await this.page.locator(`a.nav-link[data-view="${view}"]`).click();
  }

  async getCartCount(): Promise<number> {
    const text = await this.cartBadge.textContent();
    return parseInt(text || '0', 10);
  }

  async toggleTheme() {
    await this.themeBtn.click();
  }

  async openMobileNav() {
    await this.hamburgerBtn.click();
  }
}
