import { Page, Locator } from '@playwright/test';

export class AdminPage {
  readonly page: Page;
  readonly dashboardHeader: Locator;
  readonly logoutButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.dashboardHeader = page.locator('h1', { hasText: 'Dashboard' });
    this.logoutButton = page.locator('button', { hasText: 'Logout' });
  }

  async isDashboardVisible(): Promise<boolean> {
    return await this.dashboardHeader.isVisible();
  }

  async logout() {
    await this.logoutButton.click();
  }
}
