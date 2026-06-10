// ============================================================
// admin.js — VSN Admin Panel Logic
// ============================================================

// ─── Backend URL Configuration ────────────────────────────────
// To deploy: Change VSN_BACKEND_URL to your production backend URL.
// Leave as null to use auto-detection below.
const VSN_BACKEND_URL = 'http://localhost/vsn_grocery';

function detectBackendURL() {
    if (VSN_BACKEND_URL) return VSN_BACKEND_URL;
    
    if (location.protocol === 'file:') {
        return 'http://localhost/vsn_grocery';
    }
    
    const DEV_PORTS = [3000, 4000, 5500, 5173, 8080, 8081];
    if (DEV_PORTS.includes(parseInt(location.port))) {
        return `http://${location.hostname}:8080/vsn_grocery`;
    }
    
    return `${location.protocol}//${location.hostname}/vsn_grocery`;
}

const BASE = detectBackendURL();

let adminSession = JSON.parse(localStorage.getItem('vsn_admin') || 'null');

async function api(endpoint, method = 'GET', body = null) {
    const opts = { method, headers: { 'Content-Type': 'application/json' } };
    if (body) opts.body = JSON.stringify(body);
    try {
        const r = await fetch(BASE + endpoint, opts);
        return await r.json();
    } catch (e) { return { status: 'error', message: 'Network error — is XAMPP running?' }; }
}

// ─── Boot ──────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    if (adminSession) {
        showPanel();
    }
});

// ─── Auth ──────────────────────────────────────────────────
async function handleAdminLogin(e) {
    e.preventDefault();
    const email    = document.getElementById('adminEmail').value.trim();
    const password = document.getElementById('adminPassword').value;
    const btn      = document.getElementById('loginBtn');
    const err      = document.getElementById('loginErr');
    err.style.display = 'none';
    btn.innerHTML  = '<i class="fa-solid fa-spinner fa-spin"></i> Verifying...';
    btn.disabled   = true;

    // Try admin_login.php first, fallback to login.php with is_admin check
    let res = await api('/admin_login.php', 'POST', { email, password });
    if (res.status !== 'success') {
        res = await api('/login.php', 'POST', { email, password });
        if (res.status === 'success' && !res.data?.is_admin) {
            res = { status: 'error', message: 'Access Denied: Not an admin account.' };
        }
    }

    if (res.status === 'success') {
        adminSession = { email: res.data?.email || res.data?.user?.email || email };
        localStorage.setItem('vsn_admin', JSON.stringify(adminSession));
        showPanel();
    } else {
        err.innerText     = res.message || 'Login failed';
        err.style.display = 'block';
    }
    btn.innerHTML = '<i class="fa-solid fa-right-to-bracket"></i> Login';
    btn.disabled  = false;
}

function showPanel() {
    document.getElementById('loginScreen').style.display = 'none';
    document.getElementById('adminPanel').style.display  = 'flex';
    document.getElementById('adminEmailDisplay').innerText = adminSession?.email || '';
    loadAnalytics('weekly');
    loadOrders();
    loadProducts();
    loadUsers();
    // Check backend connection
    checkBackendStatus();
}

function adminLogout() {
    localStorage.removeItem('vsn_admin');
    adminSession = null;
    document.getElementById('adminPanel').style.display  = 'none';
    document.getElementById('loginScreen').style.display = 'flex';
}

// ─── Backend Status Check ─────────────────────────────────
async function checkBackendStatus() {
    const pill = document.getElementById('backendStatusPill');
    if (!pill) return;
    pill.className = 'backend-status-pill checking';
    pill.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> Checking connection...';
    
    try {
        const res = await api('/get_products.php');
        if (res && res.status === 'success') {
            const count = res.data?.length ?? 0;
            pill.className = 'backend-status-pill ok';
            pill.innerHTML = `<i class="fa-solid fa-circle-check"></i> ✅ Backend Connected — ${count} products`;
        } else {
            pill.className = 'backend-status-pill error';
            pill.innerHTML = `<i class="fa-solid fa-circle-xmark"></i> ⚠️ Backend Issue: ${res.message || 'Unknown error'}`;
        }
    } catch(e) {
        pill.className = 'backend-status-pill error';
        pill.innerHTML = `<i class="fa-solid fa-circle-xmark"></i> ❌ Cannot connect — check XAMPP`;
    }
}

// ─── Mobile Sidebar ────────────────────────────────────────
function toggleAdminSidebar() {
    const sidebar = document.getElementById('adminSidebar');
    const overlay = document.getElementById('sidebarOverlay');
    if (sidebar) sidebar.classList.toggle('open');
    if (overlay) overlay.classList.toggle('visible');
}


// ─── Tab Navigation ────────────────────────────────────────
function showTab(name, el) {
    document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active-tab'));
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active-tab');
    if (el) el.classList.add('active');
    
    if (name === 'settings') {
        loadConfigHubSettings();
    }
}

// ─── Dashboard / Analytics ─────────────────────────────────
async function loadAnalytics(period, btn) {
    if (btn) {
        document.querySelectorAll('.period-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
    }
    const res = await api('/admin_analytics.php?period=' + period);
    if (res.status !== 'success') return;
    const { kpi, revenue, products, statuses } = res.data;

    // KPIs
    document.getElementById('kpiGrid').innerHTML = `
        <div class="kpi-card">
            <div class="kpi-icon" style="background:#dbeafe;color:#2563eb"><i class="fa-solid fa-box"></i></div>
            <div class="kpi-val">${kpi.totalOrders}</div>
            <div class="kpi-label">Total Orders</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-icon" style="background:#d1fae5;color:#059669"><i class="fa-solid fa-indian-rupee-sign"></i></div>
            <div class="kpi-val">₹${Number(kpi.totalRevenue).toLocaleString('en-IN', {maximumFractionDigits:0})}</div>
            <div class="kpi-label">Total Revenue</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-icon" style="background:#fef3c7;color:#d97706"><i class="fa-solid fa-users"></i></div>
            <div class="kpi-val">${kpi.uniqueCustomers}</div>
            <div class="kpi-label">Total Users</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-icon" style="background:#ede9fe;color:#7c3aed"><i class="fa-solid fa-coins"></i></div>
            <div class="kpi-val">${kpi.totalCoins}</div>
            <div class="kpi-label">Coins Issued</div>
        </div>`;

    // Revenue bar chart
    renderBarChart('revenueChart', revenue, '₹');
    // Top products bar chart
    renderBarChart('productsChart', products, ' units');
    // Status donut-style list
    const total = statuses.reduce((s, r) => s + r.value, 0);
    const statusColors = { Pending:'#f59e0b', Processing:'#3b82f6', Shipped:'#8b5cf6', Delivered:'#10b981', Cancelled:'#ef4444' };
    document.getElementById('statusChart').innerHTML = statuses.map(s => `
        <div class="status-row">
            <span class="status-dot" style="background:${statusColors[s.label]||'#6b7280'}"></span>
            <span class="status-label-name">${s.label}</span>
            <div class="status-bar-wrap">
                <div class="status-bar-fill" style="width:${total ? Math.round(s.value/total*100) : 0}%;background:${statusColors[s.label]||'#6b7280'}"></div>
            </div>
            <span class="status-count">${s.value}</span>
        </div>`).join('');
}

function renderBarChart(containerId, data, suffix = '') {
    if (!data || !data.length) {
        document.getElementById(containerId).innerHTML = '<p style="color:#9ca3af;text-align:center;padding:2rem">No data</p>';
        return;
    }
    const max = Math.max(...data.map(d => d.value));
    document.getElementById(containerId).innerHTML = `
        <div class="bars-wrap">
            ${data.map(d => `
            <div class="bar-item">
                <div class="bar-fill" style="height:${max ? Math.round(d.value/max*100) : 0}%" title="${d.label}: ${d.value}${suffix}"></div>
                <span class="bar-label">${d.label}</span>
            </div>`).join('')}
        </div>`;
}

// ─── Orders ────────────────────────────────────────────────
async function loadOrders() {
    const res = await api('/get_orders.php?isAdmin=true');
    const orders = (res.status === 'success' && res.data) ? res.data : [];
    const statusColors = { Pending:'#f59e0b', Processing:'#3b82f6', Shipped:'#8b5cf6', Delivered:'#10b981', Cancelled:'#ef4444' };
    document.getElementById('ordersTableBody').innerHTML = orders.length ? orders.map(o => {
        const date = new Date(o.date).toLocaleDateString('en-IN', {day:'numeric',month:'short',year:'numeric'});
        const color = statusColors[o.status] || '#6b7280';
        return `<tr>
            <td><code>${o.id.slice(0,16)}...</code></td>
            <td>${o.userEmail}</td>
            <td><b>₹${parseFloat(o.total).toFixed(2)}</b></td>
            <td>${o.paymentMethod}</td>
            <td><span class="status-badge" style="background:${color}20;color:${color}">${o.status}</span></td>
            <td>${date}</td>
            <td>
                <button class="mini-btn" onclick='showOrderDetail(${JSON.stringify(o)})'>View</button>
                <button class="mini-btn" style="background:#3b82f620;color:#3b82f6" onclick='openStatusModal(${JSON.stringify(o)})'>Update</button>
            </td>
        </tr>`;
    }).join('') : '<tr><td colspan="7" class="loading-row">No orders found.</td></tr>';
}

let _currentStatusOrderId = null;
function openStatusModal(o) {
    _currentStatusOrderId = o.id;
    document.getElementById('statusOrderIdLabel').innerText = o.id.slice(0, 20) + '...';
    document.getElementById('statusSelect').value = o.status;
    document.getElementById('paymentStatusSelect').value = o.paymentStatus || 'Pending';
    document.getElementById('statusModal').style.display = 'flex';
}

async function saveOrderStatus() {
    if (!_currentStatusOrderId) return;
    const btn = document.getElementById('saveStatusBtn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>';
    const res = await api('/update_order_status.php', 'POST', {
        id: _currentStatusOrderId,
        status: document.getElementById('statusSelect').value,
        paymentStatus: document.getElementById('paymentStatusSelect').value
    });
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-check"></i> Save';
    if (res.status === 'success') {
        document.getElementById('statusModal').style.display = 'none';
        adminToast('Order status updated! ✅');
        loadOrders();
    } else {
        adminToast(res.message || 'Update failed.', 'error');
    }
}

function showOrderDetail(o) {
    const items = Array.isArray(o.items) ? o.items : [];
    document.getElementById('orderModalContent').innerHTML = `
        <div class="detail-grid">
            <div class="detail-row"><b>Order ID</b><span>${o.id}</span></div>
            <div class="detail-row"><b>Customer</b><span>${o.userEmail}</span></div>
            <div class="detail-row"><b>Address</b><span>${o.address}</span></div>
            <div class="detail-row"><b>Payment</b><span>${o.paymentMethod} — ${o.paymentStatus}</span></div>
            <div class="detail-row"><b>Status</b><span>${o.status}</span></div>
        </div>
        <h4 style="margin:1.5rem 0 0.75rem">Items</h4>
        <table class="data-table">
            <thead><tr><th>Product</th><th>Qty</th><th>Price</th><th>Line Total</th></tr></thead>
            <tbody>
                ${items.map(it => {
                    const p = it.product || {};
                    return `<tr>
                        <td>${p.name||'—'}</td>
                        <td>${it.quantity}</td>
                        <td>₹${p.wholesalePrice||0}</td>
                        <td><b>₹${((p.wholesalePrice||0)*it.quantity).toFixed(2)}</b></td>
                    </tr>`;
                }).join('')}
            </tbody>
        </table>
        <div class="order-total-row">
            <button class="mini-btn" style="background:var(--card);display:flex;align-items:center;gap:0.4rem;font-weight:700;margin-right:auto;" onclick='downloadInvoicePDF(${JSON.stringify(o).replace(/'/g, "&#39;").replace(/"/g, "&quot;")})'><i class="fa-solid fa-file-pdf" style="color:#ef4444;font-size:1.05rem;"></i> Print Invoice</button>
            ${o.discountAmount > 0 ? `<span>Discount: -₹${o.discountAmount}</span>` : ''}
            ${o.deliveryCharge > 0 ? `<span>Delivery: ₹${o.deliveryCharge}</span>` : ''}
            <b>Total: ₹${parseFloat(o.total).toFixed(2)}</b>
        </div>`;
    document.getElementById('orderModal').style.display = 'flex';
}

// ─── Products ──────────────────────────────────────────────
let adminProducts = [];
async function loadProducts() {
    const res = await api('/get_products.php');
    adminProducts = (res.status === 'success' && res.data) ? res.data : [];
    const prods = adminProducts;
    document.getElementById('productsTableBody').innerHTML = prods.length ? prods.map(p => {
        const cat = p.details?.category || '—';
        const stockColor = p.stockStatus === 'In Stock' ? '#10b981' : p.stockStatus === 'Low Stock' ? '#f59e0b' : '#ef4444';
        return `<tr>
            <td><b>${p.name}</b></td>
            <td>${cat}</td>
            <td>₹${p.retailPrice}</td>
            <td>₹${p.wholesalePrice}</td>
            <td><span class="status-badge" style="background:${stockColor}20;color:${stockColor}">${p.stockStatus}</span></td>
            <td>${p.isTrending ? '<i class="fa-solid fa-fire" style="color:#f59e0b"></i> Yes' : 'No'}</td>
            <td><button class="mini-btn danger" onclick="deleteProduct('${p.id}')">Delete</button></td>
        </tr>`;
    }).join('') : '<tr><td colspan="7" class="loading-row">No products found.</td></tr>';
}

function previewProductImage(url) {
    const box    = document.getElementById('imgPreviewBox');
    const imgEl  = document.getElementById('imgPreviewEl');
    const status = document.getElementById('imgPreviewStatus');
    const trimmed = url.trim();
    if (!trimmed) {
        box.style.display = 'none';
        imgEl.src = '';
        return;
    }
    box.style.display = 'block';
    status.innerHTML  = '<span style="color:#6b7280">⏳ Loading preview...</span>';
    imgEl.style.opacity = '0.5';
    imgEl.src = trimmed;
}

function openProductModal() {
    // Reset all form fields
    ['pName','pCategory','pRetail','pWholesale','pImage'].forEach(id => document.getElementById(id).value = '');
    document.getElementById('pMinQty').value = '1';
    document.getElementById('pStock').value = 'In Stock';
    document.getElementById('pTrending').checked = false;
    document.getElementById('productErr').style.display = 'none';
    // Reset image preview
    document.getElementById('imgPreviewBox').style.display = 'none';
    document.getElementById('imgPreviewEl').src = '';
    document.getElementById('imgPreviewStatus').innerHTML = '';
    document.getElementById('productModal').style.display = 'flex';
}

async function submitProduct() {
    const name      = document.getElementById('pName').value.trim();
    const category  = document.getElementById('pCategory').value.trim();
    const retail    = parseFloat(document.getElementById('pRetail').value);
    const wholesale = parseFloat(document.getElementById('pWholesale').value);
    const minQty    = parseInt(document.getElementById('pMinQty').value) || 1;
    const stock     = document.getElementById('pStock').value;
    const image     = document.getElementById('pImage').value.trim();
    const trending  = document.getElementById('pTrending').checked;
    const errEl     = document.getElementById('productErr');
    const btn       = document.querySelector('#productModal .action-btn');

    if (!name || !category || !retail || !wholesale) {
        errEl.innerText = 'Name, Category, Retail and Wholesale prices are required.';
        errEl.style.display = 'block';
        return;
    }

    // Loading state
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Saving...';
    errEl.style.display = 'none';

    const product = {
        id: `prod-${Date.now()}`,
        name, retailPrice: retail, wholesalePrice: wholesale,
        image: image || '',
        details: { category },
        minOrderQty: minQty,
        stockStatus: stock,
        isTrending: trending
    };

    const res = await api('/add_product.php', 'POST', product);

    // Restore button
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-plus"></i> Add Product';

    if (res.status === 'success') {
        document.getElementById('productModal').style.display = 'none';
        adminToast('Product added successfully! 🎉');
        loadProducts();
    } else {
        errEl.innerText = res.message || 'Failed to add product.';
        errEl.style.display = 'block';
    }
}

async function deleteProduct(id) {
    if (!confirm('Delete this product?')) return;
    const res = await api('/delete_product.php', 'POST', { id });
    if (res.status === 'success') { adminToast('Product deleted.'); loadProducts(); }
    else adminToast(res.message || 'Failed to delete.', 'error');
}

// ─── Users ─────────────────────────────────────────────────
async function loadUsers() {
    const res = await api('/get_users.php');
    const users = (res.status === 'success' && res.data) ? res.data : [];
    document.getElementById('usersTableBody').innerHTML = users.length ? users.map(u => {
        const joined = u.created_at ? new Date(u.created_at).toLocaleDateString('en-IN') : '—';
        return `<tr>
            <td><b>${u.name || '—'}</b></td>
            <td>${u.email}</td>
            <td>${u.phone || '—'}</td>
            <td>${u.business_name || '—'}</td>
            <td><span style="color:#7c3aed;font-weight:700">🪙 ${u.coins || 0}</span></td>
            <td>${joined}</td>
        </tr>`;
    }).join('') : '<tr><td colspan="6" class="loading-row">No users found.</td></tr>';
}

// ─── Notifications ─────────────────────────────────────────
async function sendNotification() {
    const title   = document.getElementById('notifTitle').value.trim();
    const message = document.getElementById('notifMessage').value.trim();
    const type    = document.getElementById('notifType').value;
    const email   = document.getElementById('notifEmail').value.trim() || 'all';
    const res_el  = document.getElementById('notifResult');

    if (!title || !message) { res_el.innerText = '⚠️ Title and Message are required.'; res_el.style.color = '#ef4444'; return; }

    const res = await api('/send_notification.php', 'POST', {
        id: `notif-${Date.now()}`, title, message, type, userEmail: email, date: new Date().toISOString()
    });

    res_el.innerText = res.status === 'success' ? '✅ Notification sent successfully!' : '❌ ' + res.message;
    res_el.style.color = res.status === 'success' ? '#10b981' : '#ef4444';
    if (res.status === 'success') {
        document.getElementById('notifTitle').value = '';
        document.getElementById('notifMessage').value = '';
        document.getElementById('notifEmail').value = '';
    }
}

// ─── Toast ─────────────────────────────────────────────────
function adminToast(msg, type = 'success') {
    const t = document.getElementById('adminToast');
    if (!t) return;
    t.innerText = msg;
    t.className = `admin-toast show ${type}`;
    clearTimeout(t._t);
    t._t = setTimeout(() => t.classList.remove('show'), 3500);
}

// ─── Config Hub Settings ───────────────────────────────────
async function loadConfigHubSettings() {
    const res = await api('/support.php');
    if (res) {
        document.getElementById('cfgSupportEmail').value = res.email || '';
        document.getElementById('cfgSupportWhatsapp').value = res.whatsapp || '';
        document.getElementById('cfgDeliveryCharge').value = res.delivery_charge || '0';
        document.getElementById('cfgMinOrderValue').value = res.min_order_value || '1000';
        document.getElementById('cfgFreeThreshold').value = res.free_delivery_threshold || '5000';
        document.getElementById('cfgDeliveryRadius').value = res.delivery_radius || '25';
        document.getElementById('cfgHubLat').value = res.hub_latitude || '21.1458';
        document.getElementById('cfgHubLng').value = res.hub_longitude || '79.0882';
        document.getElementById('cfgUpiId').value = res.upi_id || 'vsnwholesale@upi';
        document.getElementById('cfgReferralReward').value = res.referral_reward_coins || '50';
        document.getElementById('cfgDeliveryNote').value = res.delivery_note || '';
        document.getElementById('cfgRazorpayKey').value = res.razorpay_key || '';
        document.getElementById('cfgRazorpaySecret').value = '';
        document.getElementById('cfgMasterKey').value = '';
    }
}

async function handleSaveSettings(e) {
    e.preventDefault();
    const btn = document.getElementById('saveSettingsBtn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Saving...';

    const payload = {
        email: document.getElementById('cfgSupportEmail').value.trim(),
        whatsapp: document.getElementById('cfgSupportWhatsapp').value.trim(),
        delivery_charge: document.getElementById('cfgDeliveryCharge').value,
        min_order_value: document.getElementById('cfgMinOrderValue').value,
        free_delivery_threshold: document.getElementById('cfgFreeThreshold').value,
        delivery_radius: document.getElementById('cfgDeliveryRadius').value,
        hub_latitude: document.getElementById('cfgHubLat').value,
        hub_longitude: document.getElementById('cfgHubLng').value,
        upi_id: document.getElementById('cfgUpiId').value.trim(),
        referral_reward_coins: document.getElementById('cfgReferralReward').value,
        delivery_note: document.getElementById('cfgDeliveryNote').value.trim(),
        razorpay_key: document.getElementById('cfgRazorpayKey').value.trim(),
        razorpay_secret: document.getElementById('cfgRazorpaySecret').value.trim(),
        admin_master_key: document.getElementById('cfgMasterKey').value
    };

    const res = await api('/support.php', 'POST', payload);
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save Settings';

    if (res.status === 'success') {
        adminToast('Logistics & settings saved successfully! ✅');
        document.getElementById('cfgMasterKey').value = '';
        document.getElementById('cfgRazorpaySecret').value = '';
    } else {
        adminToast(res.message || 'Save failed. Verify Master Key.', 'error');
    }
}

// ─── Admin Onboarding ─────────────────────────────────────
async function handleEnrollAdmin(e) {
    e.preventDefault();
    const email = document.getElementById('enrollEmail').value.trim();
    const password = document.getElementById('enrollPassword').value;
    const upi_id = document.getElementById('enrollUpi').value.trim();
    const btn = document.getElementById('enrollAdminBtn');

    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Onboarding...';

    const res = await api('/add_admin.php', 'POST', { email, password, upi_id });
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-user-plus"></i> Enroll Admin';

    if (res.status === 'success') {
        adminToast('Admin account onboarded! 🔒');
        document.getElementById('enrollEmail').value = '';
        document.getElementById('enrollPassword').value = '';
        document.getElementById('enrollUpi').value = '';
    } else {
        adminToast(res.message || 'Onboarding failed.', 'error');
    }
}

// ─── Export Orders to CSV ──────────────────────────────────
async function exportOrdersToCSV() {
    adminToast('Exporting orders...');
    const res = await api('/get_orders.php?isAdmin=true');
    const orders = (res.status === 'success' && res.data) ? res.data : [];
    if (!orders.length) {
        adminToast('No orders found to export.', 'error');
        return;
    }

    let csvContent = "data:text/csv;charset=utf-8,";
    csvContent += "Order ID,Date,User Email,Total (INR),Status,Payment Status,Payment Method,Requires GST,Business Name,GSTIN\n";

    orders.forEach(o => {
        const row = [
            `"${o.id}"`,
            `"${o.date}"`,
            `"${o.userEmail}"`,
            o.total,
            `"${o.status}"`,
            `"${o.paymentStatus || 'Pending'}"`,
            `"${o.paymentMethod}"`,
            o.requiresGSTBill ? 'Yes' : 'No',
            `"${o.businessName || ''}"`,
            `"${o.gstNumber || ''}"`
        ];
        csvContent += row.join(",") + "\n";
    });

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `VSN_Orders_Export_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    adminToast('CSV exported and downloaded! 📊');
}

// ─── Create Manual Order ───────────────────────────────────
let manualOrderOffers = [];

async function openCreateOrderModal() {
    document.getElementById('moCustomerEmail').value = '';
    document.getElementById('moAddress').value = '';
    document.getElementById('moPaymentMethod').selectedIndex = 0;
    document.getElementById('moError').style.display = 'none';
    
    // Clear items row
    const container = document.getElementById('moItemsContainer');
    container.innerHTML = '';
    
    // Load offers
    const offerRes = await api('/get_offers.php');
    manualOrderOffers = (offerRes.status === 'success' && offerRes.data) ? offerRes.data : [];
    
    const offerSelect = document.getElementById('moOfferSelect');
    offerSelect.innerHTML = '<option value="">No Discount</option>';
    manualOrderOffers.forEach(o => {
        const desc = o.discountPercentage ? `${o.discountPercentage * 100}% off` : `₹${o.discountAmount} flat off`;
        offerSelect.innerHTML += `<option value="${o.id}">${o.title} (${desc} - Min Order: ₹${o.minOrderValue})</option>`;
    });

    // Make sure adminProducts is loaded
    if (!adminProducts.length) {
        await loadProducts();
    }

    // Add first item row
    addManualOrderItemRow();
    
    document.getElementById('createOrderModal').style.display = 'flex';
}

function addManualOrderItemRow(prodId = '', qty = 1) {
    const container = document.getElementById('moItemsContainer');
    const rowIndex = container.children.length;
    
    const row = document.createElement('div');
    row.className = 'manual-item-row';
    row.style = 'display:flex;gap:0.75rem;align-items:center;margin-bottom:0.4rem;';
    
    let productOptions = '<option value="" disabled selected>Select product...</option>';
    adminProducts.forEach(p => {
        productOptions += `<option value="${p.id}" data-price="${p.wholesalePrice}">${p.name} (₹${p.wholesalePrice}/ea - Min Qty: ${p.minOrderQty || 1})</option>`;
    });

    row.innerHTML = `
        <select class="form-input mo-item-select" style="flex:2;margin-bottom:0;" onchange="handleManualProductChange(this)" required>
            ${productOptions}
        </select>
        <input type="number" class="form-input mo-item-qty" value="${qty}" min="1" style="flex:1;width:80px;margin-bottom:0;" oninput="recalculateManualOrderTotal()" required>
        <button type="button" class="mini-btn danger" style="padding:0.7rem;line-height:1;" onclick="removeManualOrderItemRow(this)"><i class="fa-solid fa-trash"></i></button>
    `;
    
    container.appendChild(row);
    if (prodId) {
        const select = row.querySelector('.mo-item-select');
        select.value = prodId;
        handleManualProductChange(select);
    }
    recalculateManualOrderTotal();
}

function removeManualOrderItemRow(btn) {
    const container = document.getElementById('moItemsContainer');
    if (container.children.length > 1) {
        btn.parentElement.remove();
        recalculateManualOrderTotal();
    } else {
        adminToast('An order must contain at least one item.', 'error');
    }
}

function handleManualProductChange(select) {
    const row = select.parentElement;
    const selectedOption = select.options[select.selectedIndex];
    const productId = select.value;
    
    if (productId) {
        const product = adminProducts.find(p => p.id === productId);
        const qtyInput = row.querySelector('.mo-item-qty');
        if (product) {
            qtyInput.min = product.minOrderQty || 1;
            qtyInput.value = Math.max(product.minOrderQty || 1, parseInt(qtyInput.value) || 1);
        }
    }
    recalculateManualOrderTotal();
}

function recalculateManualOrderTotal() {
    let subtotal = 0;
    const container = document.getElementById('moItemsContainer');
    if (!container) return;

    const rows = container.getElementsByClassName('manual-item-row');
    
    for (let row of rows) {
        const select = row.querySelector('.mo-item-select');
        const qtyInput = row.querySelector('.mo-item-qty');
        const productId = select.value;
        const qty = parseInt(qtyInput.value) || 0;
        
        if (productId) {
            const product = adminProducts.find(p => p.id === productId);
            if (product) {
                subtotal += (product.wholesalePrice || 0) * qty;
            }
        }
    }

    // Apply offer discount
    let discount = 0;
    let appliedOfferTitle = null;
    const offerSelect = document.getElementById('moOfferSelect');
    const selectedOfferId = offerSelect.value;
    
    if (selectedOfferId) {
        const offer = manualOrderOffers.find(o => o.id == selectedOfferId);
        if (offer && subtotal >= offer.minOrderValue) {
            appliedOfferTitle = offer.title;
            if (offer.discountAmount) {
                discount = parseFloat(offer.discountAmount);
            } else if (offer.discountPercentage) {
                discount = subtotal * (parseFloat(offer.discountPercentage) / 100);
            }
        } else if (offer) {
            // Offer selected but threshold not met, show warning border or log
            offerSelect.style.borderColor = '#ef4444';
        }
    }
    
    if (!selectedOfferId || (selectedOfferId && subtotal >= manualOrderOffers.find(o => o.id == selectedOfferId)?.minOrderValue)) {
        offerSelect.style.borderColor = '';
    }

    // Delivery charge from logistics
    let delivery = subtotal > 0 && subtotal < (parseFloat(logistics.freeThreshold) || 5000) ? (parseFloat(logistics.deliveryCharge) || 50) : 0;
    if (subtotal === 0) delivery = 0;
    
    const finalTotal = Math.max(0, subtotal - discount + delivery);
    
    document.getElementById('moSubtotalLabel').innerText = `₹${subtotal.toFixed(2)}`;
    document.getElementById('moDiscountLabel').innerText = `-₹${discount.toFixed(2)}`;
    document.getElementById('moDeliveryLabel').innerText = delivery === 0 ? 'Free' : `₹${delivery.toFixed(2)}`;
    document.getElementById('moTotalLabel').innerText = `₹${finalTotal.toFixed(2)}`;
    
    return { subtotal, discount, delivery, finalTotal, appliedOfferTitle };
}

async function handleCreateManualOrder(e) {
    e.preventDefault();
    
    const email = document.getElementById('moCustomerEmail').value.trim();
    const address = document.getElementById('moAddress').value.trim();
    const paymentMethod = document.getElementById('moPaymentMethod').value;
    const errEl = document.getElementById('moError');
    const btn = document.getElementById('createOrderSubmitBtn');
    
    errEl.style.display = 'none';
    
    const container = document.getElementById('moItemsContainer');
    const rows = container.getElementsByClassName('manual-item-row');
    const items = [];
    
    for (let row of rows) {
        const select = row.querySelector('.mo-item-select');
        const qtyInput = row.querySelector('.mo-item-qty');
        const productId = select.value;
        const qty = parseInt(qtyInput.value) || 0;
        
        if (!productId) {
            errEl.innerText = 'Please select a product for all rows.';
            errEl.style.display = 'block';
            return;
        }
        
        const product = adminProducts.find(p => p.id === productId);
        if (product) {
            items.push({
                product: product,
                quantity: qty
            });
        }
    }
    
    if (items.length === 0) {
        errEl.innerText = 'Order must contain at least one product.';
        errEl.style.display = 'block';
        return;
    }
    
    const pricing = recalculateManualOrderTotal();
    
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Placing Order...';
    
    const order = {
        id: `ORD-MAN-${Date.now()}`,
        date: new Date().toISOString(),
        items: items,
        total: pricing.finalTotal,
        status: 'Pending',
        paymentStatus: 'Pending',
        paymentMethod: paymentMethod,
        address: address,
        userEmail: email,
        discountAmount: pricing.discount,
        deliveryCharge: pricing.delivery,
        appliedOfferTitle: pricing.appliedOfferTitle,
        coinsEarned: 0,
        coinsUsed: 0,
        coinDiscount: 0,
        requiresGSTBill: false
    };
    
    const res = await api('/place_order.php', 'POST', order);
    
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-circle-check"></i> Place Manual Order';
    
    if (res.status === 'success') {
        document.getElementById('createOrderModal').style.display = 'none';
        adminToast('Manual wholesale order placed! 📦');
        loadOrders();
    } else {
        errEl.innerText = res.message || 'Failed to place manual order.';
        errEl.style.display = 'block';
    }
}

// ─── PDF Invoice Builder ──────────────────────────────────
function downloadInvoicePDF(o) {
    const items = Array.isArray(o.items) ? o.items : [];
    const date = new Date(o.date).toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' });
    const subtotal = items.reduce((s, it) => s + (it.product?.wholesalePrice || 0) * it.quantity, 0);
    const invoiceNo = o.id.replace('ORD-', 'INV-');
    
    const invoiceHtml = `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Invoice - ${o.id}</title>
        <style>
            body { font-family: 'Inter', system-ui, -apple-system, sans-serif; color: #1e293b; padding: 40px; margin: 0; line-height: 1.5; background: #fff; }
            .invoice-box { max-width: 800px; margin: auto; border: 1px solid #e2e8f0; border-radius: 12px; padding: 40px; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.02); }
            .header-row { display: flex; justify-content: space-between; border-bottom: 2px solid #3b82f6; padding-bottom: 20px; margin-bottom: 30px; }
            .logo { font-size: 24px; font-weight: 800; color: #1e293b; }
            .logo span { color: #3b82f6; }
            .title-right { text-align: right; }
            .title-right h1 { font-size: 28px; margin: 0; color: #3b82f6; font-weight: 800; letter-spacing: -0.5px; }
            .meta-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 30px; margin-bottom: 40px; font-size: 14px; }
            .meta-col h3 { font-size: 12px; text-transform: uppercase; color: #64748b; margin-bottom: 8px; letter-spacing: 0.5px; }
            .meta-col p { margin: 0 0 4px; font-weight: 500; }
            .meta-col p strong { color: #0f172a; }
            table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
            th { background: #f8fafc; padding: 12px 16px; font-size: 11px; text-transform: uppercase; font-weight: 700; color: #475569; border-bottom: 1px solid #e2e8f0; text-align: left; }
            td { padding: 16px; border-bottom: 1px solid #f1f5f9; font-size: 14px; }
            .text-right { text-align: right; }
            .totals-box { display: flex; flex-direction: column; align-items: flex-end; font-size: 14px; gap: 8px; margin-top: 20px; }
            .totals-row { display: flex; justify-content: space-between; width: 260px; padding: 4px 0; }
            .totals-row.final { font-size: 18px; font-weight: 800; border-top: 2px solid #e2e8f0; padding-top: 12px; margin-top: 8px; color: #0f172a; }
            .gst-stamp { display: inline-block; border: 1.5px solid #10b981; color: #10b981; font-weight: 700; font-size: 11px; text-transform: uppercase; padding: 3px 8px; border-radius: 4px; margin-top: 6px; letter-spacing: 0.5px; }
            .footer { border-top: 1px solid #e2e8f0; margin-top: 50px; padding-top: 20px; font-size: 12px; color: #64748b; text-align: center; }
            @media print {
                body { padding: 0; }
                .invoice-box { border: none; box-shadow: none; padding: 0; }
                .no-print { display: none; }
            }
        </style>
    </head>
    <body>
        <div style="max-width: 800px; margin: 0 auto 15px auto; display: flex; justify-content: flex-end;" class="no-print">
            <button onclick="window.print()" style="background:#3b82f6;color:white;border:none;padding:10px 20px;border-radius:8px;font-weight:700;font-family:inherit;font-size:14px;cursor:pointer;display:flex;align-items:center;gap:6px;"><svg style="width:16px;height:16px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-3a2 2 0 00-2-2H9a2 2 0 00-2 2v3a2 2 0 002 2zm5-12V7a3 3 0 116 0v4m-6 0h6"></path></svg> Print Invoice</button>
        </div>
        <div class="invoice-box">
            <div class="header-row">
                <div class="logo">
                    VSN <span>Wholesale</span>
                </div>
                <div class="title-right">
                    <h1>TAX INVOICE</h1>
                    <span style="font-size:12px;color:#64748b">Bill No: ${invoiceNo}</span>
                </div>
            </div>
            
            <div class="meta-grid">
                <div class="meta-col">
                    <h3>Seller Details</h3>
                    <p><strong>V.S.N. Wholesale Goods Hub</strong></p>
                    <p>Vijayawada Central Wholesale Market</p>
                    <p>Andhra Pradesh, India</p>
                    <p>Email: billing@vsnhome.in | WA: +91 90592 70899</p>
                </div>
                <div class="meta-col" style="text-align: right;">
                    <h3>Invoice Meta</h3>
                    <p>Date: <strong>${date}</strong></p>
                    <p>Payment Mode: <strong>${o.paymentMethod}</strong></p>
                    <p>Payment Status: <strong style="color: ${o.paymentStatus === 'Paid' ? '#10b981' : '#ef4444'}">${o.paymentStatus || 'Pending'}</strong></p>
                </div>
            </div>

            <div class="meta-grid" style="border-top:1px dashed #e2e8f0;padding-top:20px;">
                <div class="meta-col">
                    <h3>Billing & Shipping Destination</h3>
                    <p><strong>Customer Email:</strong> ${o.userEmail}</p>
                    <p><strong>Delivery Address:</strong> ${o.address}</p>
                </div>
                <div class="meta-col" style="text-align: right;">
                    <h3>B2B Registry Info</h3>
                    ${o.requiresGSTBill ? `
                        <p>Business Name: <strong>${o.businessName}</strong></p>
                        <p>GSTIN: <strong>${o.gstNumber}</strong></p>
                        <span class="gst-stamp">GST Invoice Generated</span>
                    ` : '<p style="color:#64748b;font-style:italic">Standard Wholesale Invoice</p>'}
                </div>
            </div>

            <table>
                <thead>
                    <tr>
                        <th>Item Description</th>
                        <th class="text-right">Unit Price</th>
                        <th class="text-right">Qty Ordered</th>
                        <th class="text-right">Net Subtotal</th>
                    </tr>
                </thead>
                <tbody>
                    ${items.map(it => {
                        const p = it.product || {};
                        return `
                        <tr>
                            <td><strong>${p.name || 'General Product'}</strong></td>
                            <td class="text-right">₹${parseFloat(p.wholesalePrice || 0).toFixed(2)}</td>
                            <td class="text-right">${it.quantity}</td>
                            <td class="text-right">₹${((p.wholesalePrice || 0) * it.quantity).toFixed(2)}</td>
                        </tr>`;
                    }).join('')}
                </tbody>
            </table>

            <div class="totals-box">
                <div class="totals-row">
                    <span>Items Subtotal:</span>
                    <span>₹${subtotal.toFixed(2)}</span>
                </div>
                ${o.discountAmount > 0 ? `
                <div class="totals-row" style="color:#ef4444;">
                    <span>Offer Discount:</span>
                    <span>-₹${parseFloat(o.discountAmount).toFixed(2)}</span>
                </div>
                ` : ''}
                <div class="totals-row">
                    <span>Logistics Charge:</span>
                    <span>${o.deliveryCharge > 0 ? `₹${parseFloat(o.deliveryCharge).toFixed(2)}` : 'Free'}</span>
                </div>
                <div class="totals-row final">
                    <span>Receivable Total:</span>
                    <span>₹${parseFloat(o.total).toFixed(2)}</span>
                </div>
            </div>
            
            <div class="footer">
                <p>Thank you for choosing VSN Wholesale as your growth partner.</p>
                <p>This is a computer-generated invoice and requires no physical signature.</p>
            </div>
        </div>
    </body>
    </html>`;

    const printWin = window.open('', '_blank');
    printWin.document.write(invoiceHtml);
    printWin.document.close();
}

// Register Service Worker for offline PWA capabilities
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('./sw.js')
            .then(reg => console.log('Service Worker registered successfully with scope:', reg.scope))
            .catch(err => console.error('Service Worker registration failed:', err));
    });
}


