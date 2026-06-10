// ============================================================
// api.js — VSN Grocery Web App API Layer
// ============================================================

// ─── Backend URL Configuration ────────────────────────────────
// To deploy: Change VSN_BACKEND_URL to your production backend URL.
// Example: const VSN_BACKEND_URL = 'https://yourdomain.com/vsn_grocery';
// Leave as null to use auto-detection below.
const VSN_BACKEND_URL = 'http://localhost/vsn_grocery';

// Auto-detect backend URL based on environment
function detectBackendURL() {
    if (VSN_BACKEND_URL) return VSN_BACKEND_URL;
    
    // If served from file:// protocol (e.g., direct HTML open) — use localhost
    if (location.protocol === 'file:') {
        return 'http://localhost/vsn_grocery';
    }
    
    // Development proxy ports (Node/Python dev servers)
    const DEV_PORTS = [3000, 4000, 5500, 5173, 8080, 8081];
    if (DEV_PORTS.includes(parseInt(location.port))) {
        return `http://${location.hostname}:8080/vsn_grocery`;
    }
    
    // Production: same domain as the web app
    return `${location.protocol}//${location.hostname}/vsn_grocery`;
}

const API_CONFIG = {
    BASE_URL: detectBackendURL()
};

// ─── Core Fetch Wrapper ───────────────────────────────────────
async function apiCall(endpoint, method = 'GET', body = null) {
    const opts = {
        method,
        headers: { 'Content-Type': 'application/json' }
    };
    if (body) opts.body = JSON.stringify(body);
    try {
        const res = await fetch(API_CONFIG.BASE_URL + endpoint, opts);
        if (!res.ok) {
            const text = await res.text();
            // Try to parse as JSON even for error responses
            try {
                const json = JSON.parse(text);
                return json;
            } catch(_) {
                return { status: 'error', message: `Server error ${res.status}: ${text.slice(0,120)}` };
            }
        }
        return await res.json();
    } catch (e) {
        console.error('API Error:', endpoint, e);
        const isNetworkErr = e instanceof TypeError && e.message.includes('fetch');
        return {
            status: 'error',
            message: isNetworkErr
                ? '❌ Cannot reach server. Make sure XAMPP is running and the backend is configured correctly.'
                : `Error: ${e.message}`
        };
    }
}

// ─── Connection Test ──────────────────────────────────────────
async function testBackendConnection() {
    try {
        const res = await fetch(API_CONFIG.BASE_URL + '/get_products.php', {
            method: 'GET',
            headers: { 'Content-Type': 'application/json' }
        });
        if (res.ok) {
            const json = await res.json();
            return { ok: true, message: `✅ Backend connected. Products: ${json.data?.length ?? 0}`, data: json };
        }
        return { ok: false, message: `⚠️ Server responded with status ${res.status}` };
    } catch (e) {
        return { ok: false, message: `❌ Cannot connect: ${e.message}. Check XAMPP / server is running.` };
    }
}

// ─── API Endpoints ────────────────────────────────────────────
const API = {
    // Public
    getProducts: (category = null, trending = false) => {
        let url = '/get_products.php';
        const params = [];
        if (category && category !== 'All') params.push(`category=${encodeURIComponent(category)}`);
        if (trending) params.push('trending=1');
        if (params.length) url += '?' + params.join('&');
        return apiCall(url);
    },
    getOffers:  () => apiCall('/get_offers.php'),
    getSupport: () => apiCall('/support.php'),

    // Auth
    login:         (email, password)  => apiCall('/login.php', 'POST', { email, password }),
    register:      (data)             => apiCall('/register.php', 'POST', data),
    forgotPassword:(email)            => apiCall('/forgot_password.php', 'POST', { email }),
    resetPassword: (email, password)  => apiCall('/reset_password.php', 'POST', { email, password }),

    // User
    getOrders:            (email)       => apiCall(`/get_orders.php?isAdmin=false&userEmail=${encodeURIComponent(email)}`),
    getProfile:           (email)       => apiCall(`/get_profile.php?email=${encodeURIComponent(email)}`),
    placeOrder:           (order)       => apiCall('/place_order.php', 'POST', order),
    getNotifications:     (email)       => apiCall(`/get_notifications.php?userEmail=${encodeURIComponent(email)}`),
    markNotificationsRead:(email)       => apiCall('/mark_notifications_read.php', 'POST', { userEmail: email }),
    cancelOrder:          (orderId)     => apiCall('/update_order_status.php', 'POST', { id: orderId, status: 'Cancelled' }),
    updateProfile:        (profileData) => apiCall('/update_profile.php', 'POST', profileData),
    deleteUserAccount:    (email)       => apiCall('/delete_account.php', 'POST', { email }),

    // Admin
    getAdminAnalytics:   (period)      => apiCall(`/admin_analytics.php?period=${period}`),
    getAdminOrders:      ()            => apiCall('/get_orders.php?isAdmin=true'),
    updateOrderStatus:   (data)        => apiCall('/update_order_status.php', 'POST', data),
    addProduct:          (product)     => apiCall('/add_product.php', 'POST', product),
    deleteProduct:       (id)          => apiCall('/delete_product.php', 'POST', { id }),
    getUsers:            ()            => apiCall('/get_users.php'),
    sendNotification:    (notif)       => apiCall('/send_notification.php', 'POST', notif),
    deleteNotification:  (id)          => apiCall('/delete_notification.php', 'POST', { id }),
    addOffer:            (offer)       => apiCall('/add_offer.php', 'POST', offer),
    deleteOffer:         (id)          => apiCall('/delete_offer.php', 'POST', { id }),
    updateProductStock:  (id, status)  => apiCall('/update_stock.php', 'POST', { id, stockStatus: status }),
    updateSupportSettings:(settings)   => apiCall('/support.php', 'POST', settings),
    addAdmin:            (adminData)   => apiCall('/add_admin.php', 'POST', adminData),
};
