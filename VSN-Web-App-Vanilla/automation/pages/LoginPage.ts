import { Page, Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly loginBtn: Locator;
  readonly loginErr: Locator;
  readonly backToStoreLink: Locator;
  readonly loginScreen: Locator;
  readonly adminPanel: Locator;
  readonly adminEmailDisplay: Locator;
  readonly logoutBtn: Locator;

  // Sidebar tabs
  readonly dashboardTab: Locator;
  readonly ordersTab: Locator;
  readonly productsTab: Locator;
  readonly usersTab: Locator;
  readonly notificationsTab: Locator;
  readonly settingsTab: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput = page.locator('#adminEmail');
    this.passwordInput = page.locator('#adminPassword');
    this.loginBtn = page.locator('#loginBtn');
    this.loginErr = page.locator('#loginErr');
    this.backToStoreLink = page.locator('a.back-link');
    this.loginScreen = page.locator('#loginScreen');
    this.adminPanel = page.locator('#adminPanel');
    this.adminEmailDisplay = page.locator('#adminEmailDisplay');
    this.logoutBtn = page.locator('.sidebar-footer button');
    this.dashboardTab = page.locator('a.nav-item').filter({ hasText: 'Dashboard' });
    this.ordersTab = page.locator('a.nav-item').filter({ hasText: 'Orders' });
    this.productsTab = page.locator('a.nav-item').filter({ hasText: 'Products' });
    this.usersTab = page.locator('a.nav-item').filter({ hasText: 'Users' });
    this.notificationsTab = page.locator('a.nav-item').filter({ hasText: 'Notifications' });
    this.settingsTab = page.locator('a.nav-item').filter({ hasText: 'Settings' });
  }

  async navigate() {
    await this.page.goto('/admin.html');
    await this.page.waitForLoadState('networkidle');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.loginBtn.click();
  }

  async isLoggedIn(): Promise<boolean> {
    return await this.adminPanel.isVisible();
  }

  async isErrorVisible(): Promise<boolean> {
    return await this.loginErr.isVisible();
  }

  async logout() {
    await this.logoutBtn.click();
  }
}
