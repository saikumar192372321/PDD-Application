import { Page } from '@playwright/test';

export async function setupBackendMocks(page: Page) {
  await page.route('**/*.php*', async (route) => {
    const url = route.request().url();
    
    // Auth Mocks
    if (url.includes('admin_login.php') || url.includes('login.php')) {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ 
          status: 'success', 
          data: { is_admin: true, name: 'Admin User', email: 'admin@vsnhome.com' } 
        })
      });
    }
    // Analytics & KPIs
    else if (url.includes('admin_analytics.php')) {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          status: 'success',
          data: {
            sales: 12500,
            orders: 145,
            users: 89,
            products: 320,
            recentOrders: [],
            topProducts: []
          }
        })
      });
    }
    // Products
    else if (url.includes('get_products.php')) {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          status: 'success',
          data: [
            { id: 1, name: 'Premium Rice', price: 45, category: 'Grains', stock: 100 },
            { id: 2, name: 'Sugar', price: 20, category: 'Groceries', stock: 50 }
          ]
        })
      });
    }
    // Users
    else if (url.includes('get_users.php')) {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          status: 'success',
          data: [
            { id: 1, name: 'Test User', email: 'test@user.com' }
          ]
        })
      });
    }
    // Orders
    else if (url.includes('get_orders.php')) {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          status: 'success',
          data: [
            { id: 101, user: 'John', total: 500, status: 'Pending' }
          ]
        })
      });
    }
    // Support/Notifications
    else if (url.includes('support.php') || url.includes('send_notification.php')) {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ status: 'success', message: 'Success' })
      });
    }
    // Default fallback for any other PHP file
    else {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ status: 'success', data: [] })
      });
    }
  });
}
