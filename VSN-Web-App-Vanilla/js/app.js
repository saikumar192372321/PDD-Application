// ============================================================
// app.js — VSN Grocery Web App — Full Frontend Logic
// ============================================================

// ─── State ───────────────────────────────────────────────────
let allProducts = [];
let allOffers   = [];
let cart        = [];
let session     = JSON.parse(localStorage.getItem('vsn_session') || 'null');
let logistics   = { deliveryCharge: 50, freeThreshold: 5000, minOrderValue: 1000 };
let selectedOffer = null;
let activeProfileTab = 'account';


// ─── Boot ─────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', async () => {
    // Theme initialization
    const savedTheme = localStorage.getItem('vsn_theme') || 'light';
    if (savedTheme === 'dark') {
        document.body.classList.add('dark-theme');
        const themeIcon = document.querySelector('#themeBtn i');
        if (themeIcon) themeIcon.className = 'fa-solid fa-sun';
    }

    updateAuthUI();
    await Promise.all([loadProducts(), loadOffers(), loadLogistics()]);
    renderHomeProducts();
    renderCategories();
    renderCategoryProducts('All');
    renderOffersView();
    setupSearch();
    loadChatHistory();
    if (session) updateAnalytics();
    
    // Notifications init
    loadNotifications();
    setInterval(loadNotifications, 30000); // refresh every 30s
    
    // Check language selection
    const savedLang = localStorage.getItem('vsn_language');
    if (!savedLang) {
        // Show language selection modal on first boot
        setTimeout(() => openModal('languageModal'), 800);
    } else {
        selectAppLanguage(savedLang, false);
    }
    
    // Calendar initialization
    renderB2BCalendar();
    
    // Auto-close notifications dropdown when clicking outside
    document.addEventListener('click', (e) => {
        const dropdown = document.getElementById('notifDropdown');
        const notifBtn = document.getElementById('notifBtn');
        if (dropdown && dropdown.classList.contains('show') && !dropdown.contains(e.target) && !notifBtn.contains(e.target)) {
            dropdown.classList.remove('show');
        }
    });
});

// Theme toggle logic
function toggleTheme() {
    const isDark = document.body.classList.toggle('dark-theme');
    localStorage.setItem('vsn_theme', isDark ? 'dark' : 'light');
    const themeIcon = document.querySelector('#themeBtn i');
    if (themeIcon) {
        themeIcon.className = isDark ? 'fa-solid fa-sun' : 'fa-solid fa-moon';
    }
}

// ─── Unified Auth Modal ───────────────────────────────────────
function switchAuthTab(tab) {
    // Hide all panels
    document.querySelectorAll('.auth-panel').forEach(p => p.classList.remove('active-auth-panel'));
    // Reset tab buttons (only Login/Register tabs exist in tab bar)
    document.querySelectorAll('.auth-tab').forEach(t => t.classList.remove('active'));
    
    const titleMap  = { login: 'Welcome Back', register: 'Create Account', forgot: 'Reset Password' };
    const subMap    = { login: 'Sign in to your VSN account', register: 'Join VSN Grocery today', forgot: 'Recover access to your account' };
    
    const titleEl = document.getElementById('authModalTitle');
    const subEl   = document.getElementById('authModalSub');
    if (titleEl) titleEl.innerText = titleMap[tab] || 'VSN Account';
    if (subEl)   subEl.innerText   = subMap[tab]   || '';
    
    // Show correct panel
    const panel = document.getElementById('authPanel' + tab.charAt(0).toUpperCase() + tab.slice(1));
    if (panel) panel.classList.add('active-auth-panel');
    
    // Highlight active tab (only for login/register)
    const tabBtn = document.getElementById('tab' + tab.charAt(0).toUpperCase() + tab.slice(1));
    if (tabBtn) tabBtn.classList.add('active');
    
    // Toggle visibility of tab bar (hide for forgot panel)
    const tabBar = document.getElementById('authTabs');
    if (tabBar) tabBar.style.display = (tab === 'forgot') ? 'none' : 'flex';
    
    // Reset forgot password forms
    if (tab === 'forgot') {
        const s1 = document.getElementById('forgotStep1Form');
        const s2 = document.getElementById('forgotStep2Form');
        const forgotTitle = document.getElementById('forgotTitle');
        const forgotSub   = document.getElementById('forgotSubtitle');
        if (s1) s1.style.display = 'block';
        if (s2) s2.style.display = 'none';
        if (forgotTitle) forgotTitle.innerText = 'Reset Password';
        if (forgotSub) forgotSub.innerText = 'Enter your registered email to reset your password.';
    }
}

function toggleAuthPassword(inputId, btn) {
    const input = document.getElementById(inputId);
    if (!input) return;
    const isHidden = input.type === 'password';
    input.type = isHidden ? 'text' : 'password';
    const icon = btn.querySelector('i');
    if (icon) icon.className = isHidden ? 'fa-solid fa-eye-slash' : 'fa-solid fa-eye';
}

// ─── Navigation ───────────────────────────────────────────────
function navigate(viewId) {
    document.querySelectorAll('.view-container').forEach(el => el.classList.remove('active-view'));
    document.querySelectorAll('.nav-link').forEach(el => el.classList.remove('active'));

    const link = document.querySelector(`.nav-link[data-view="${viewId}"]`);
    if (link) link.classList.add('active');

    const view = document.getElementById(`view-${viewId}`);
    if (view) view.classList.add('active-view');
    window.scrollTo({ top: 0, behavior: 'smooth' });

    if (viewId === 'cart')      renderCart();
    if (viewId === 'profile')   renderProfile();
    if (viewId === 'orders')    renderOrders();
    if (viewId === 'analytics') updateAnalytics();
}

// ─── Mobile Nav ────────────────────────────────────────────────
function openMobileNav()  { document.getElementById('mobileNav').classList.add('open'); }
function closeMobileNav() { document.getElementById('mobileNav').classList.remove('open'); }

// ─── Floating Chat Toggle ──────────────────────────────────────
function toggleFloatingChat() {
    const fc   = document.getElementById('floatingChatbot');
    const icon = document.getElementById('chatToggleIcon');
    const isExpanded = fc.classList.toggle('expanded');
    if (icon) icon.className = isExpanded ? 'fa-solid fa-chevron-down' : 'fa-solid fa-chevron-up';
}


async function loadProducts() {
    const res = await API.getProducts();
    allProducts = (res.status === 'success' && res.data) ? res.data : [];
}

async function loadOffers() {
    const res = await API.getOffers();
    allOffers = (res.status === 'success' && res.data) ? res.data : [];
}

async function loadLogistics() {
    const res = await API.getSupport();
    if (res) {
        logistics.deliveryCharge  = parseFloat(res.delivery_charge  || 50);
        logistics.freeThreshold   = parseFloat(res.free_delivery_threshold || 5000);
        logistics.minOrderValue   = parseFloat(res.min_order_value  || 1000);
    }
}

// ─── Search ───────────────────────────────────────────────────
function setupSearch() {
    const input = document.getElementById('searchInput');
    input.addEventListener('input', () => {
        const q = input.value.toLowerCase().trim();
        if (!q) { renderCategoryProducts('All'); navigate('categories'); return; }
        const filtered = allProducts.filter(p => p.name.toLowerCase().includes(q));
        navigate('categories');
        document.getElementById('categoryTitle').innerText = `Results for "${input.value}"`;
        renderProductGrid('categoryProductContainer', filtered);
    });
}

// ─── Product Card ─────────────────────────────────────────────
function productImg(prod) {
    const fallback = "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=500&q=80";
    const raw = (prod.image || '').trim();
    if (!raw) return fallback;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return API_CONFIG.BASE_URL + '/' + raw;
}

function renderProductCard(prod) {
    const img      = productImg(prod);
    const price    = prod.wholesalePrice || prod.retailPrice || 0;
    const origPrice = prod.retailPrice || 0;
    const cat      = prod.details?.category || 'General';
    const hasSale  = origPrice > price;
    const badge    = hasSale ? `<div class="discount-badge">SALE</div>` : (prod.isTrending ? `<div class="discount-badge" style="background:#f59e0b">🔥 TRENDING</div>` : '');
    const origHtml = hasSale ? `<span class="original-price">₹${origPrice}</span>` : '';
    const stock    = prod.stockStatus;
    const outOfStock = stock === 'Out of Stock';

    // JSON string safe for onclick payload attributes
    const safeProdJson = JSON.stringify(prod).replace(/'/g, "&#39;").replace(/"/g, "&quot;");

    const localizedName = getLocalizedName(prod);

    return `
    <div class="product-card ${outOfStock ? 'out-of-stock' : ''}">
        ${badge}
        <div class="product-img-container" onclick="showProductDetails('${safeProdJson}')" style="position:relative;">
            <img src="${img}" alt="${localizedName}" loading="lazy" style="width:100%;height:100%;object-fit:cover;transition:opacity 0.3s;"
                 onload="this.style.opacity=1;"
                 onerror="this.style.display='none';var fb=this.nextElementSibling;if(fb&&fb.classList.contains('img-fallback'))fb.style.display='flex';">
            <div class="img-fallback" style="display:none;position:absolute;inset:0;flex-direction:column;align-items:center;justify-content:center;background:linear-gradient(135deg,#f0f9ff,#e0f2fe);gap:4px;">
                <span style="font-size:2.2rem;">🥦</span>
                <span style="font-size:0.65rem;color:#64748b;font-weight:600;">No Image</span>
            </div>
            ${outOfStock ? '<div class="oos-overlay">Out of Stock</div>' : ''}
        </div>
        <div class="product-info">
            <div class="product-category">${cat}</div>
            <div class="product-title" title="${localizedName}" onclick="showProductDetails('${safeProdJson}')">${localizedName}</div>
            <div class="product-price-row">
                <div>
                    <span class="price">₹${price}</span>
                    ${origHtml}
                </div>
                <button class="add-to-cart-btn" onclick='addToCart(${JSON.stringify(prod).replace(/'/g,"&#39;")})' 
                        ${outOfStock ? 'disabled title="Out of Stock"' : ''}>
                    <i class="fa-solid fa-plus"></i>
                </button>
            </div>
        </div>
    </div>`;
}

function showProductDetails(prodDataEscaped) {
    try {
        // Decode the escaped HTML JSON entity string back to a valid object
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = prodDataEscaped;
        const prod = JSON.parse(tempDiv.textContent);
        
        const img = productImg(prod);
        const price = prod.wholesalePrice || prod.retailPrice || 0;
        const origPrice = prod.retailPrice || 0;
        const cat = prod.details?.category || 'General';
        const hasSale = origPrice > price;
        const stock = prod.stockStatus;
        const outOfStock = stock === 'Out of Stock';

        const detailImg = document.getElementById('detailImg');
        const detailFallback = document.getElementById('detailImgFallback');
        // Reset state before loading new image
        detailImg.style.display = 'block';
        detailImg.style.opacity = '0.4';
        if (detailFallback) detailFallback.style.display = 'none';
        const localizedName = getLocalizedName(prod);
        detailImg.src = img;
        document.getElementById('detailCategory').innerText = cat;
        document.getElementById('detailName').innerText = localizedName;
        document.getElementById('detailDesc').innerText = prod.details?.description || `Premium quality organic ${localizedName} sourced fresh from trusted farms. High wholesale order value savings apply natively.`;
        document.getElementById('detailWholesale').innerText = `₹${price}`;
        document.getElementById('detailRetail').innerText = hasSale ? `₹${origPrice}` : '';
        document.getElementById('detailMinQty').innerText = `${prod.minOrderQty || 1} units`;
        
        const stockEl = document.getElementById('detailStock');
        stockEl.innerText = stock;
        stockEl.style.color = stock === 'In Stock' ? 'var(--accent-color)' : stock === 'Low Stock' ? '#f59e0b' : '#ef4444';

        const addBtn = document.getElementById('detailAddBtn');
        addBtn.disabled = outOfStock;
        addBtn.innerHTML = outOfStock ? 'Out of Stock' : '<i class="fa-solid fa-cart-plus"></i> Add to Cart';
        addBtn.onclick = () => {
            addToCart(prod);
            closeModal('productDetailModal');
        };

        openModal('productDetailModal');
    } catch(e) {
        console.error("Quick View details failed to open:", e);
    }
}

function renderProductGrid(containerId, products) {
    const el = document.getElementById(containerId);
    if (!el) return;
    if (!products || products.length === 0) {
        el.innerHTML = '<p class="empty-msg">No products found.</p>';
        return;
    }
    el.innerHTML = products.map(renderProductCard).join('');
}

// ─── Home ─────────────────────────────────────────────────────
function renderHomeProducts() {
    const trending = allProducts.filter(p => p.isTrending);
    renderProductGrid('homeProductContainer', trending.length ? trending.slice(0, 8) : allProducts.slice(0, 8));
}

// ─── Categories ───────────────────────────────────────────────
function renderCategories() {
    const container = document.getElementById('allCategoriesContainer');
    // Filter out any category literally named 'All' from DB to avoid duplicates
    const dbCats = [...new Set(allProducts.map(p => p.details?.category).filter(c => c && c !== 'All'))];
    const cats = ['All', ...dbCats];
    container.innerHTML = cats.map(cat => `
        <div class="category-card ${cat === 'All' ? 'active-cat' : ''}" onclick="filterCategory(this, '${cat}')">
            <div class="cat-icon"><i class="fa-solid ${getCatIcon(cat)}"></i></div>
            <h4>${cat}</h4>
        </div>`).join('');
}

function getCatIcon(cat) {
    const icons = { All:'border-all', Vegetables:'carrot', Fruits:'apple-whole', Dairy:'bottle-water', Staples:'wheat-awn', Snacks:'cookie', Beverages:'mug-saucer', Meat:'drumstick-bite', Bakery:'bread-slice', Oils:'flask' };
    return icons[cat] || 'tag';
}

function filterCategory(el, category) {
    document.querySelectorAll('.category-card').forEach(c => c.classList.remove('active-cat'));
    el.classList.add('active-cat');
    renderCategoryProducts(category);
}

function renderCategoryProducts(category) {
    document.getElementById('categoryTitle').innerText = category === 'All' ? 'All Products' : category;
    const filtered = category === 'All' ? allProducts : allProducts.filter(p => p.details?.category === category);
    renderProductGrid('categoryProductContainer', filtered);
}

// ─── Offers ───────────────────────────────────────────────────
function renderOffersView() {
    const container = document.getElementById('offersListContainer');
    if (!container) return;

    // Products on sale
    const saleProducts = allProducts.filter(p => p.wholesalePrice && p.wholesalePrice < p.retailPrice);

    container.innerHTML = `
        <div class="offers-grid">
            ${allOffers.map(o => `
            <div class="offer-chip-big">
                <div class="offer-icon"><i class="fa-solid fa-tag"></i></div>
                <div>
                    <h4>${o.title}</h4>
                    <p>${o.description}</p>
                    <span class="offer-min">Min Order: ₹${o.minOrderValue}</span>
                </div>
            </div>`).join('') || '<p class="empty-msg">No special offers right now.</p>'}
        </div>
        <div class="section-header" style="margin-top:3rem"><h3>Sale Products</h3></div>
        <div class="product-grid">${saleProducts.map(renderProductCard).join('') || '<p class="empty-msg">No sale products.</p>'}</div>
    `;
}

// ─── Cart ─────────────────────────────────────────────────────
function addToCart(prod) {
    const price  = prod.wholesalePrice || prod.retailPrice || 0;
    const minQty = prod.minOrderQty || 1;
    const existing = cart.find(i => i.id == prod.id);
    if (existing) {
        existing.qty++;
    } else {
        cart.push({ ...prod, price, qty: minQty });
    }
    updateCartBadge();
    showToast(`${prod.name} added to cart!`);
}

function removeFromCart(id) {
    cart = cart.filter(i => i.id != id);
    updateCartBadge();
    renderCart();
}

function changeQty(id, delta) {
    const item = cart.find(i => i.id == id);
    if (!item) return;
    const minQty = item.minOrderQty || 1;
    item.qty = Math.max(minQty, item.qty + delta);
    updateCartBadge();
    renderCart();
}

function updateCartBadge() {
    document.getElementById('cartBadge').innerText = cart.reduce((s, i) => s + i.qty, 0);
}

function getCartSubtotal()   { return cart.reduce((s, i) => s + i.price * i.qty, 0); }
function getCartSavings()    { return cart.reduce((s, i) => s + Math.max(0,(i.retailPrice||i.price) - i.price) * i.qty, 0); }
function getDeliveryCharge() { return getCartSubtotal() >= logistics.freeThreshold ? 0 : logistics.deliveryCharge; }

function getOfferDiscount() {
    if (!selectedOffer) return 0;
    const sub = getCartSubtotal();
    if (sub < selectedOffer.minOrderValue) return 0;
    if (selectedOffer.discountAmount) return selectedOffer.discountAmount;
    if (selectedOffer.discountPercentage) return sub * (selectedOffer.discountPercentage / 100);
    return 0;
}

function getCartTotal() {
    return Math.max(0, getCartSubtotal() - getOfferDiscount() + getDeliveryCharge());
}

function renderCart() {
    const container   = document.getElementById('cartItemsContainer');
    const summary     = document.getElementById('cartSummary');
    const addrSection = document.getElementById('addressSection');
    const offersSection = document.getElementById('cartOffersSection');

    if (cart.length === 0) {
        container.innerHTML = `
            <div class="empty-cart">
                <i class="fa-solid fa-cart-shopping" style="font-size:3rem;color:var(--primary-light-color);margin-bottom:1rem;"></i>
                <h4>Your cart is empty</h4>
                <p>Browse our catalog and add products.</p>
                <button class="primary-btn" style="margin-top:1.5rem" onclick="navigate('categories')">Browse Products</button>
            </div>`;
        summary.style.display = 'none';
        addrSection.style.display = 'none';
        offersSection.style.display = 'none';
        return;
    }

    container.innerHTML = cart.map(item => {
        const img    = productImg(item);
        const minQty = item.minOrderQty || 1;
        const canDec = item.qty > minQty;
        const localizedName = getLocalizedName(item);
        return `
        <div class="cart-item">
            <div style="position:relative;width:64px;height:64px;flex-shrink:0;border-radius:10px;overflow:hidden;background:linear-gradient(135deg,#f0f9ff,#e0f2fe);">
                <img src="${img}" alt="${localizedName}"
                     style="width:100%;height:100%;object-fit:cover;"
                     onerror="this.style.display='none';this.nextElementSibling.style.display='flex';">
                <div style="display:none;position:absolute;inset:0;align-items:center;justify-content:center;font-size:1.6rem;">🥦</div>
            </div>
            <div class="cart-item-info">
                <h4>${localizedName}</h4>
                <p class="price-each">₹${item.price} each</p>
                <p class="min-order">Min Order: ${minQty}</p>
            </div>
            <div class="cart-item-controls">
                <div class="qty-control-group">
                    <button class="qty-btn" onclick="changeQty('${item.id}', -1)" ${!canDec ? 'disabled' : ''}><i class="fa-solid fa-minus"></i></button>
                    <span class="qty-val">${item.qty}</span>
                    <button class="qty-btn" onclick="changeQty('${item.id}', 1)"><i class="fa-solid fa-plus"></i></button>
                </div>
                <div class="item-total-price">₹${item.price * item.qty}</div>
                <button class="remove-btn" onclick="removeFromCart('${item.id}')"><i class="fa-solid fa-trash"></i></button>
            </div>
        </div>`;
    }).join('');

    // Offers section in cart
    offersSection.style.display = 'block';
    const offersHtml = allOffers.length ? allOffers.map(o => {
        const sub     = getCartSubtotal();
        const active  = sub >= o.minOrderValue;
        const picked  = selectedOffer?.id == o.id;
        return `
        <div class="offer-chip-cart ${picked ? 'picked' : ''} ${!active ? 'inactive' : ''}"
             onclick="${active ? `selectOffer(${o.id})` : ''}">
            <i class="fa-solid ${picked ? 'fa-check-circle' : 'fa-tag'}"></i>
            <div>
                <b>${o.title}</b>
                <span>${o.description}</span>
                ${!active ? `<span class="offer-need">Add ₹${Math.ceil(o.minOrderValue - sub)} more</span>` : ''}
            </div>
        </div>`;
    }).join('') : '<p class="empty-msg">No offers available.</p>';
    document.getElementById('cartOffersList').innerHTML = offersHtml;

    addrSection.style.display = 'block';
    summary.style.display = 'block';

    const sub      = getCartSubtotal();
    const savings  = getCartSavings();
    const offerDisc = getOfferDiscount();
    const delivery = getDeliveryCharge();
    const total    = getCartTotal();
    const minMet   = sub >= logistics.minOrderValue;

    document.getElementById('summarySubtotal').innerText  = `₹${sub.toFixed(2)}`;
    document.getElementById('summarySavings').innerText   = `₹${savings.toFixed(2)}`;
    document.getElementById('summaryOfferDisc').innerText = offerDisc > 0 ? `-₹${offerDisc.toFixed(2)}` : '—';
    document.getElementById('summaryDelivery').innerText  = delivery === 0 ? 'Free 🎉' : `₹${delivery.toFixed(2)}`;
    document.getElementById('cartTotal').innerText        = `₹${total.toFixed(2)}`;

    const checkoutBtn = document.getElementById('checkoutBtn');
    if (!minMet) {
        checkoutBtn.disabled = true;
        checkoutBtn.innerText = `Min Order ₹${logistics.minOrderValue} (Add ₹${Math.ceil(logistics.minOrderValue - sub)} more)`;
    } else {
        checkoutBtn.disabled = false;
        checkoutBtn.innerText = `Place Order — ₹${total.toFixed(2)}`;
    }
}

function selectOffer(id) {
    const offer = allOffers.find(o => o.id == id);
    selectedOffer = (selectedOffer?.id == id) ? null : offer;
    renderCart();
}

// ─── Checkout ─────────────────────────────────────────────────
async function processCheckout() {
    if (!session) { openModal('loginModal'); return; }

    const shop    = document.getElementById('shopName').value.trim();
    const street  = document.getElementById('addressStreet').value.trim();
    const city    = document.getElementById('addressCity').value.trim();
    const pincode = document.getElementById('addressPincode').value.trim();
    const payment = document.getElementById('paymentMethod').value;

    if (!shop || !street || !city || !pincode) {
        showToast('Please fill in your complete delivery address.', 'error');
        document.getElementById('addressSection').scrollIntoView({ behavior: 'smooth' });
        return;
    }

    // GST billing values
    const requiresGST   = document.getElementById('requiresGST').checked;
    const gstBusiness   = document.getElementById('gstBusinessName').value.trim();
    const gstNumber     = document.getElementById('gstNumberInput').value.trim();

    if (requiresGST && (!gstBusiness || !gstNumber)) {
        showToast('Please provide your Business Name and GST Number.', 'error');
        document.getElementById('gstFields').scrollIntoView({ behavior: 'smooth' });
        return;
    }

    const address = `${shop}, ${street}, ${city} - ${pincode}`;

    const order = {
        id:            `ORD-${Date.now()}`,
        date:          new Date().toISOString(),
        items:         cart.map(i => ({ product: i, quantity: i.qty })),
        total:         getCartTotal(),
        status:        'Pending',
        paymentStatus: 'Pending',
        paymentMethod: payment,
        address:       address,
        userEmail:     session.email,
        discountAmount:  getOfferDiscount(),
        deliveryCharge:  getDeliveryCharge(),
        appliedOfferTitle: selectedOffer?.title || null,
        coinsEarned:   0,
        coinsUsed:     0,
        coinDiscount:  0,
        requiresGSTBill: requiresGST,
        businessName:  requiresGST ? gstBusiness : null,
        gstNumber:     requiresGST ? gstNumber : null
    };

    document.getElementById('checkoutBtn').disabled = true;
    document.getElementById('checkoutBtn').innerText = 'Placing Order...';

    if (payment.startsWith('Razorpay')) {
        const payBtn = document.getElementById('rzpPayBtn');
        if (payBtn) {
            payBtn.disabled = false;
            payBtn.innerHTML = '<i class="fa-solid fa-lock"></i> OPEN SECURE GATEWAY';
        }
        openRzpModal(order);
        document.getElementById('checkoutBtn').disabled = false;
        document.getElementById('checkoutBtn').innerText = `Place Order — ₹${order.total.toFixed(2)}`;
        return;
    }

    const res = await API.placeOrder(order);

    if (res.status === 'success') {
        cart          = [];
        selectedOffer = null;
        updateCartBadge();
        renderCart();
        showToast('Order placed successfully! 🎉');
        navigate('orders');
        renderOrders();
    } else {
        showToast(res.message || 'Order failed. Try again.', 'error');
        document.getElementById('checkoutBtn').disabled = false;
        document.getElementById('checkoutBtn').innerText = 'Place Order';
    }
}

// ─── Orders ───────────────────────────────────────────────────
async function renderOrders() {
    if (!session) {
        document.getElementById('ordersContainer').innerHTML =
            `<div class="empty-cart"><p>Please login to view your orders.</p><button class="primary-btn" style="margin-top:1rem" onclick="openModal('loginModal')">Login</button></div>`;
        return;
    }

    document.getElementById('ordersContainer').innerHTML = '<div class="loading-spinner"><i class="fa-solid fa-spinner fa-spin"></i> Loading orders...</div>';

    const res = await API.getOrders(session.email);
    const orders = (res.status === 'success' && res.data) ? res.data : [];

    if (!orders.length) {
        document.getElementById('ordersContainer').innerHTML = '<div class="empty-cart"><h4>No orders yet</h4><p>Start shopping to see your orders here.</p></div>';
        return;
    }

    const statusColors = { Pending: '#f59e0b', Processing: '#3b82f6', Shipped: '#8b5cf6', Delivered: '#10b981', Cancelled: '#ef4444' };

    document.getElementById('ordersContainer').innerHTML = orders.map(o => {
        const items = Array.isArray(o.items) ? o.items : [];
        const color = statusColors[o.status] || '#6b7280';
        const date  = new Date(o.date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
        const canCancel = o.status === 'Pending';
        return `
        <div class="order-card">
            <div class="order-header">
                <div>
                    <p class="order-id">#${o.id}</p>
                    <p class="order-date">${date}</p>
                </div>
                <div style="display:flex;align-items:center;gap:0.75rem;">
                    ${canCancel ? `<button class="qty-btn" style="color:var(--text-muted);border-color:#ef4444;color:#ef4444;font-size:0.75rem;padding:0.25rem 0.6rem;height:auto;width:auto;" onclick="requestCancelOrder('${o.id}')">Cancel Order</button>` : ''}
                    <span class="order-status" style="background:${color}20;color:${color}">${o.status}</span>
                </div>
            </div>
            <div class="order-items-list">
                ${items.map(it => `<span>${it.product?.name || 'Product'} × ${it.quantity}</span>`).join('')}
            </div>
            <div class="order-footer">
                <span class="order-payment">${o.paymentMethod}</span>
                <span class="order-total">₹${parseFloat(o.total).toFixed(2)}</span>
            </div>
        </div>`;
    }).join('');
}

async function requestCancelOrder(orderId) {
    if (!confirm('Are you sure you want to cancel this order?')) return;
    const res = await API.cancelOrder(orderId);
    if (res.status === 'success') {
        showToast('Order cancelled successfully.');
        renderOrders();
    } else {
        showToast(res.message || 'Failed to cancel order.', 'error');
    }
}

// ─── Profile & Embedded Admin ─────────────────────────────────
async function renderProfile() {
    const container = document.getElementById('profileContainer');
    const section = document.getElementById('profileSection');
    
    // ── Not logged in ──
    if (!session) {
        if (section) section.style.maxWidth = '520px';
        container.innerHTML = `
            <div class="auth-card" style="padding:3rem 2rem;">
                <div style="width:90px;height:90px;background:linear-gradient(135deg,var(--primary-color),#7c3aed);border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto 1.5rem;box-shadow:0 8px 24px rgba(37,99,235,0.25);">
                    <i class="fa-solid fa-user" style="font-size:2.5rem;color:#fff;"></i>
                </div>
                <h3 style="font-size:1.6rem;margin-bottom:0.5rem;">Welcome to VSN Grocery</h3>
                <p style="color:var(--text-muted);margin:0.5rem 0 2rem;font-size:0.95rem;">Login or create your account to manage orders, track deliveries, and earn coins.</p>
                <button class="primary-btn" style="width:100%;justify-content:center;padding:0.9rem;font-size:1rem;margin-bottom:0.85rem;border-radius:12px;" onclick="openModal('loginModal')">
                    <i class="fa-solid fa-right-to-bracket"></i> Login to My Account
                </button>
                <button class="outline-btn" style="width:100%;justify-content:center;padding:0.9rem;font-size:1rem;border-radius:12px;" onclick="openModal('registerModal')">
                    <i class="fa-solid fa-user-plus"></i> Create New Account
                </button>
                <p style="margin-top:1.5rem;font-size:0.8rem;color:var(--text-muted);">By joining, you get exclusive wholesale pricing, order tracking, and a referral bonus!</p>
            </div>`;
        return;
    }

    container.innerHTML = '<div class="loading-spinner" style="padding:4rem;"><i class="fa-solid fa-spinner fa-spin"></i> Loading your profile...</div>';
    
    // Fetch profile & orders
    const res = await API.getProfile(session.email);
    const user = res.status === 'success' ? res.data : session;
    
    if (res.status === 'success') {
        session.is_admin = user.is_admin;
        localStorage.setItem('vsn_session', JSON.stringify(session));
    }
    
    const orderRes = await API.getOrders(user.email);
    const orders = orderRes.status === 'success' ? orderRes.data : [];
    const totalOrders = orders.length;
    const totalSpent = orders.reduce((sum, o) => sum + parseFloat(o.total || 0), 0);

    // Profile completion score
    const fields = [user.name, user.phone, user.address, user.business_name, user.gstin, user.upi_id];
    const filled = fields.filter(f => f && String(f).trim()).length;
    const completionPct = Math.round((filled / fields.length) * 100);
    const completionColor = completionPct < 40 ? '#ef4444' : completionPct < 80 ? '#f59e0b' : '#10b981';

    // Avatar initials
    const nameParts = (user.name || 'User').split(' ');
    const initials = nameParts.map(p => p[0]).join('').substring(0, 2).toUpperCase();

    if (section) section.style.maxWidth = '720px';

    // Tab bar
    const tabsHtml = `
        <div class="profile-tabs" style="margin-bottom:1.5rem;">
            <button class="profile-tab-btn ${activeProfileTab === 'account' ? 'active' : ''}" onclick="switchProfileTab('account')">
                <i class="fa-solid fa-user"></i> Profile
            </button>
            <button class="profile-tab-btn ${activeProfileTab === 'orders' ? 'active' : ''}" onclick="switchProfileTab('orders')">
                <i class="fa-solid fa-box-open"></i> My Orders
                ${totalOrders > 0 ? `<span style="background:var(--primary-color);color:#fff;font-size:0.65rem;font-weight:800;padding:1px 6px;border-radius:50px;margin-left:4px;">${totalOrders}</span>` : ''}
            </button>
        </div>`;

    // Profile completion tips
    const missingTips = [];
    if (!user.phone) missingTips.push('Add your phone number');
    if (!user.address) missingTips.push('Add a delivery address');
    if (!user.business_name) missingTips.push('Add your business name');

    container.innerHTML = `
        <!-- ── Hero Header ── -->
        <div class="profile-hero-card">
            <div class="profile-avatar-ring">
                <div class="profile-avatar-circle" style="width:88px;height:88px;font-size:2rem;">${initials}</div>
            </div>
            <div class="profile-hero-info">
                <div style="display:flex;align-items:center;gap:0.75rem;flex-wrap:wrap;">
                    <h3 style="font-size:1.5rem;font-weight:800;color:var(--text-main);margin:0;">${user.name || 'Your Name'}</h3>
                    <span class="profile-header-badge ${user.is_admin ? 'admin-badge' : 'user-badge'}">
                        <i class="fa-solid ${user.is_admin ? 'fa-shield-halved' : 'fa-star'}"></i>
                        ${user.is_admin ? 'Administrator' : 'Premium Member'}
                    </span>
                </div>
                <p style="color:var(--text-muted);font-size:0.9rem;margin:0.3rem 0;">${user.email}</p>
                ${user.phone ? `<p style="color:var(--text-muted);font-size:0.85rem;margin:0;"><i class="fa-solid fa-phone" style="color:var(--primary-color);margin-right:4px;"></i>${user.phone}</p>` : ''}
                
                <!-- Profile Completion Bar -->
                <div style="margin-top:0.85rem;">
                    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:4px;">
                        <span style="font-size:0.72rem;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:0.05em;">Profile Completion</span>
                        <span style="font-size:0.75rem;font-weight:800;color:${completionColor};">${completionPct}%</span>
                    </div>
                    <div style="height:6px;background:var(--bg-main);border-radius:50px;overflow:hidden;border:1px solid var(--border-color);">
                        <div style="height:100%;width:${completionPct}%;background:${completionColor};border-radius:50px;transition:width 1s ease;"></div>
                    </div>
                    ${missingTips.length > 0 && completionPct < 100 ? `<p style="font-size:0.72rem;color:var(--text-muted);margin-top:4px;"><i class="fa-solid fa-circle-info" style="color:#f59e0b;margin-right:3px;"></i>Complete your profile: ${missingTips[0]}${missingTips.length > 1 ? ` and ${missingTips.length - 1} more` : ''}</p>` : ''}
                </div>
            </div>
            <button class="outline-btn" style="height:auto;padding:0.55rem 0.9rem;font-size:0.8rem;align-self:flex-start;" onclick="logout()">
                <i class="fa-solid fa-right-from-bracket"></i> Logout
            </button>
        </div>

        <!-- ── Quick Stats ── -->
        <div class="profile-stats-row" style="margin-bottom:1.5rem;">
            <div class="profile-stat-card">
                <div class="stat-icon" style="color:var(--primary-color)"><i class="fa-solid fa-cart-shopping"></i></div>
                <span class="stat-val">${totalOrders}</span>
                <span class="stat-label">Total Orders</span>
            </div>
            <div class="profile-stat-card">
                <div class="stat-icon" style="color:#10b981"><i class="fa-solid fa-indian-rupee-sign"></i></div>
                <span class="stat-val">₹${totalSpent.toFixed(0)}</span>
                <span class="stat-label">Total Spent</span>
            </div>
            <div class="profile-stat-card">
                <div class="stat-icon" style="color:#f59e0b"><i class="fa-solid fa-coins"></i></div>
                <span class="stat-val">🪙 ${user.coins || 0}</span>
                <span class="stat-label">Wallet Coins</span>
            </div>
        </div>

        <!-- ── Tab Navigation ── -->
        ${tabsHtml}

        <!-- ── TAB 1: ACCOUNT ── -->
        <div id="ptab-account" class="profile-tab-content ${activeProfileTab === 'account' ? 'active-ptab' : ''}">

            <!-- Setup Guide (shown if profile incomplete) -->
            ${completionPct < 100 ? `
            <div style="background:linear-gradient(135deg,rgba(37,99,235,0.06),rgba(124,58,237,0.04));border:1px dashed var(--primary-color);border-radius:14px;padding:1.25rem 1.5rem;margin-bottom:1.25rem;display:flex;gap:1rem;align-items:flex-start;">
                <i class="fa-solid fa-circle-exclamation" style="color:#f59e0b;font-size:1.3rem;margin-top:2px;flex-shrink:0;"></i>
                <div>
                    <p style="font-size:0.9rem;font-weight:700;color:var(--text-main);margin:0 0 0.3rem;">Complete your profile to unlock all features</p>
                    <p style="font-size:0.8rem;color:var(--text-muted);margin:0;">Missing: ${missingTips.join(' • ') || 'All good!'}</p>
                </div>
                <button class="primary-btn" style="height:auto;padding:0.45rem 0.9rem;font-size:0.78rem;white-space:nowrap;margin-left:auto;" onclick="toggleProfileEdit(true)">
                    <i class="fa-solid fa-pen"></i> Complete Now
                </button>
            </div>` : `
            <div style="background:rgba(16,185,129,0.06);border:1px solid rgba(16,185,129,0.2);border-radius:14px;padding:1rem 1.5rem;margin-bottom:1.25rem;display:flex;gap:0.75rem;align-items:center;">
                <i class="fa-solid fa-circle-check" style="color:#10b981;font-size:1.2rem;"></i>
                <p style="font-size:0.85rem;font-weight:700;color:#10b981;margin:0;">Your profile is 100% complete!</p>
            </div>`}

            <!-- Account Info View -->
            <div id="profileDetailsView" class="profile-section">
                <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:1rem;">
                    <h4 style="margin:0;"><i class="fa-solid fa-id-card" style="color:var(--primary-color);margin-right:6px;"></i>Account Information</h4>
                    <button class="outline-btn" style="height:auto;padding:0.4rem 0.8rem;font-size:0.78rem;" onclick="toggleProfileEdit(true)">
                        <i class="fa-solid fa-pen-to-square"></i> Edit
                    </button>
                </div>
                <div class="detail-row"><span>Full Name</span><span>${user.name || '<em style="color:var(--text-muted)">Not set</em>'}</span></div>
                <div class="detail-row"><span>Phone Number</span><span>${user.phone || '<em style="color:#f59e0b;font-size:0.82rem;">⚠ Add phone number</em>'}</span></div>
                <div class="detail-row"><span>Email Address</span><span>${user.email}</span></div>
                <div class="detail-row"><span>Delivery Address</span><span>${user.address || '<em style="color:#f59e0b;font-size:0.82rem;">⚠ Add address</em>'}</span></div>
                <div class="detail-row"><span>Business Name</span><span>${user.business_name || '<em style="color:var(--text-muted)">Not set</em>'}</span></div>
                <div class="detail-row"><span>GSTIN</span><span>${user.gstin || '<em style="color:var(--text-muted)">Not set</em>'}</span></div>
                <div class="detail-row"><span>UPI ID</span><span>${user.upi_id || '<em style="color:var(--text-muted)">Not set</em>'}</span></div>
                <div class="detail-row" style="border-bottom:none;">
                    <span>Referral Code</span>
                    <span style="display:flex;align-items:center;gap:0.35rem;">
                        <code style="background:var(--bg-main);padding:2px 8px;border-radius:6px;font-weight:700;font-size:0.88rem;border:1px solid var(--border-color);">${user.referral_code || '—'}</code>
                        ${user.referral_code ? `<button class="qty-btn" style="height:26px;width:26px;padding:0;font-size:0.75rem;" onclick="copyReferralCode('${user.referral_code}', this)" title="Copy Code"><i class="fa-regular fa-copy"></i></button>` : ''}
                    </span>
                </div>
            </div>

            <!-- Account Info Edit Form -->
            <div id="profileDetailsEdit" class="profile-section" style="display:none;">
                <div style="display:flex;align-items:center;gap:0.75rem;margin-bottom:1.25rem;">
                    <i class="fa-solid fa-pen-to-square" style="color:var(--primary-color);font-size:1.1rem;"></i>
                    <h4 style="margin:0;">Edit Your Profile</h4>
                </div>
                <form id="editProfileForm" onsubmit="saveProfileDetails(event, '${user.email}')">
                    <div class="edit-form-group">
                        <label>Full Name *</label>
                        <input type="text" id="editName" class="edit-form-input" value="${user.name || ''}" placeholder="e.g. Ramesh Kumar" required>
                    </div>
                    <div class="edit-form-row">
                        <div class="edit-form-group">
                            <label>Phone Number *</label>
                            <input type="tel" id="editPhone" class="edit-form-input" value="${user.phone || ''}" placeholder="e.g. 9876543210" required>
                        </div>
                        <div class="edit-form-group">
                            <label>UPI ID <span style="color:var(--text-muted);font-weight:400;text-transform:none;">(for refunds)</span></label>
                            <input type="text" id="editUpi" class="edit-form-input" value="${user.upi_id || ''}" placeholder="e.g. name@upi">
                        </div>
                    </div>
                    <div class="edit-form-row">
                        <div class="edit-form-group">
                            <label>Business / Shop Name</label>
                            <input type="text" id="editBusiness" class="edit-form-input" value="${user.business_name || ''}" placeholder="e.g. Ramesh Traders">
                        </div>
                        <div class="edit-form-group">
                            <label>GSTIN <span style="color:var(--text-muted);font-weight:400;text-transform:none;">(for GST invoice)</span></label>
                            <input type="text" id="editGstin" class="edit-form-input" value="${user.gstin || ''}" placeholder="e.g. 22AAAAA1111A1Z1">
                        </div>
                    </div>
                    <div class="edit-form-group">
                        <label>Full Delivery Address *</label>
                        <textarea id="editAddress" class="edit-form-input" rows="3" placeholder="Street, Area, City, Pincode" required>${user.address || ''}</textarea>
                    </div>
                    <div class="profile-actions">
                        <button type="submit" id="saveProfileBtn" class="primary-btn">
                            <i class="fa-solid fa-check"></i> Save Changes
                        </button>
                        <button type="button" class="outline-btn" onclick="toggleProfileEdit(false)">
                            <i class="fa-solid fa-xmark"></i> Cancel
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- ── TAB 2: MY ORDERS ── -->
        <div id="ptab-orders" class="profile-tab-content ${activeProfileTab === 'orders' ? 'active-ptab' : ''}">
            <div class="profile-section">
                <h4><i class="fa-solid fa-box-open" style="color:var(--primary-color);"></i> Order History</h4>
                <div id="profileOrdersList"></div>
            </div>
        </div>

        <!-- ── Admin Access Portal (always visible at bottom) ── -->
        <div class="profile-section admin-portal-card" style="margin-top:2.5rem; padding:1.75rem; border:1px dashed var(--border-color); text-align:center; background:linear-gradient(180deg, var(--card-bg), rgba(245,158,11,0.02)); border-radius:var(--radius-lg); position:relative; overflow:hidden;">
            <div style="position:absolute; top:0; left:0; right:0; height:3px; background:#f59e0b;"></div>
            <div style="display:flex; flex-direction:column; align-items:center; gap:0.5rem;">
                <div style="width:48px; height:48px; background:rgba(245, 158, 11, 0.1); border-radius:50%; display:flex; align-items:center; justify-content:center; margin-bottom:0.25rem;">
                    <i class="fa-solid fa-shield-halved" style="color:#f59e0b; font-size:1.25rem;"></i>
                </div>
                <h4 style="margin:0; font-size:1.1rem; font-weight:800; color:var(--text-main);">Store Administration Portal</h4>
                <p style="font-size:0.82rem; color:var(--text-muted); margin:0 0 1.25rem; max-width:440px; line-height:1.45;">
                    ${user.is_admin ? 'You are recognized as a store administrator. Click below to open the dashboard.' : 'Are you a store manager or administrator? Access the backend portal to manage orders, products, and configurations.'}
                </p>
                <a href="admin.html" class="primary-btn" style="background:#f59e0b; color:#fff; border-color:#d97706; padding:0.65rem 1.75rem; font-size:0.85rem; font-weight:700; border-radius:10px; text-decoration:none; display:inline-flex; align-items:center; gap:0.5rem; transition:all 0.2s ease; box-shadow:0 4px 12px rgba(245,158,11,0.15);" onmouseover="this.style.transform='translateY(-1px)'; this.style.boxShadow='0 6px 16px rgba(245,158,11,0.25)';" onmouseout="this.style.transform='none'; this.style.boxShadow='0 4px 12px rgba(245,158,11,0.15)';">
                    <i class="fa-solid fa-right-to-bracket"></i> ${user.is_admin ? 'Go to Admin Panel' : 'Admin Login'}
                </a>
            </div>
        </div>
    `;

    if (activeProfileTab === 'orders') {
        renderProfileOrders(orders);
    }
}




// ─── Profile Tab Switcher & Helpers ───────────────────────────
async function loadAndRenderProfileOrders() {
    const container = document.getElementById('profileOrdersList');
    if (!container) return;
    container.innerHTML = '<div class="loading-spinner" style="padding:2rem;"><i class="fa-solid fa-spinner fa-spin"></i> Loading orders...</div>';
    const orderRes = await API.getOrders(session.email);
    const orders = orderRes.status === 'success' ? orderRes.data : [];
    renderProfileOrders(orders);
}

function switchProfileTab(tabName) {
    activeProfileTab = tabName;
    
    // 1. Update active button state
    document.querySelectorAll('.profile-tab-btn').forEach(btn => {
        btn.classList.remove('active');
        if (btn.getAttribute('onclick') && btn.getAttribute('onclick').includes(`'${tabName}'`)) {
            btn.classList.add('active');
        }
    });

    // 2. Update visible tab content
    document.querySelectorAll('.profile-tab-content').forEach(content => {
        content.classList.remove('active-ptab');
    });
    const targetContent = document.getElementById(`ptab-${tabName}`);
    if (targetContent) targetContent.classList.add('active-ptab');

    // 3. Render content if orders tab
    if (tabName === 'orders') {
        loadAndRenderProfileOrders();
    }
}


function toggleProfileEdit(show) {
    document.getElementById('profileDetailsView').style.display = show ? 'none' : 'block';
    document.getElementById('profileDetailsEdit').style.display = show ? 'block' : 'none';
}

async function saveProfileDetails(e, email) {
    e.preventDefault();
    const btn = document.getElementById('saveProfileBtn');
    const originalText = btn.innerHTML;
    
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Saving...';
    
    const profileData = {
        email: email,
        name: document.getElementById('editName').value.trim(),
        phone: document.getElementById('editPhone').value.trim(),
        upi_id: document.getElementById('editUpi').value.trim(),
        business_name: document.getElementById('editBusiness').value.trim(),
        gstin: document.getElementById('editGstin').value.trim(),
        address: document.getElementById('editAddress').value.trim()
    };
    
    const res = await API.updateProfile(profileData);
    
    btn.disabled = false;
    btn.innerHTML = originalText;
    
    if (res.status === 'success') {
        showToast('Profile updated successfully! 🎉');
        // Update user session details in memory
        session.name = profileData.name;
        session.phone = profileData.phone;
        session.address = profileData.address;
        session.business_name = profileData.business_name;
        session.gstin = profileData.gstin;
        session.upi_id = profileData.upi_id;
        localStorage.setItem('vsn_session', JSON.stringify(session));
        
        renderProfile();
    } else {
        showToast(res.message || 'Failed to update profile.', 'error');
    }
}

function renderProfileOrders(orders) {
    const container = document.getElementById('profileOrdersList');
    if (!orders.length) {
        container.innerHTML = '<div class="empty-cart"><h4>No orders yet</h4><p>Your orders will appear here.</p></div>';
        return;
    }
    
    const statusColors = { Pending: '#f59e0b', Processing: '#3b82f6', Shipped: '#8b5cf6', Delivered: '#10b981', Cancelled: '#ef4444' };
    
    container.innerHTML = orders.map(o => {
        const items = Array.isArray(o.items) ? o.items : [];
        const color = statusColors[o.status] || '#6b7280';
        const date  = new Date(o.date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
        const canCancel = o.status === 'Pending';
        return `
        <div class="order-card">
            <div class="order-header">
                <div>
                    <p class="order-id">#${o.id}</p>
                    <p class="order-date">${date}</p>
                </div>
                <div style="display:flex;align-items:center;gap:0.75rem;">
                    ${canCancel ? `<button class="qty-btn" style="color:var(--text-muted);border-color:#ef4444;color:#ef4444;font-size:0.75rem;padding:0.25rem 0.6rem;height:auto;width:auto;" onclick="requestCancelOrderProfile('${o.id}')">Cancel Order</button>` : ''}
                    <span class="order-status" style="background:${color}20;color:${color}">${o.status}</span>
                </div>
            </div>
            <div class="order-items-list">
                ${items.map(it => `<span>${it.product?.name || 'Product'} × ${it.quantity}</span>`).join('')}
            </div>
            <div class="order-footer">
                <span class="order-payment">${o.paymentMethod}</span>
                <span class="order-total">₹${parseFloat(o.total).toFixed(2)}</span>
            </div>
        </div>`;
    }).join('');
}

async function requestCancelOrderProfile(orderId) {
    if (!confirm('Are you sure you want to cancel this order?')) return;
    const res = await API.cancelOrder(orderId);
    if (res.status === 'success') {
        showToast('Order cancelled successfully.');
        renderProfile();
    } else {
        showToast(res.message || 'Failed to cancel order.', 'error');
    }
}

// ─── Embedded Admin Functions ─────────────────────────────────
async function loadEmbeddedAnalytics(period, btn) {
    if (btn) {
        document.querySelectorAll('.admin-period-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
    }
    
    const res = await API.getAdminAnalytics(period);
    if (res.status !== 'success') {
        document.getElementById('embKpis').innerHTML = `<p style="color:#ef4444;padding:1rem;">Failed to load analytics: ${res.message}</p>`;
        return;
    }
    
    const { kpi, revenue, products, statuses } = res.data;
    
    // Render KPIs
    document.getElementById('embKpis').innerHTML = `
        <div class="admin-kpi-card">
            <div class="admin-kpi-icon" style="background:#dbeafe;color:#2563eb"><i class="fa-solid fa-box"></i></div>
            <div>
                <div class="kpi-val">${kpi.totalOrders}</div>
                <div class="kpi-label">Total Orders</div>
            </div>
        </div>
        <div class="admin-kpi-card">
            <div class="admin-kpi-icon" style="background:#d1fae5;color:#059669"><i class="fa-solid fa-indian-rupee-sign"></i></div>
            <div>
                <div class="kpi-val">₹${Number(kpi.totalRevenue).toLocaleString('en-IN', {maximumFractionDigits:0})}</div>
                <div class="kpi-label">Total Revenue</div>
            </div>
        </div>
        <div class="admin-kpi-card">
            <div class="admin-kpi-icon" style="background:#fef3c7;color:#d97706"><i class="fa-solid fa-users"></i></div>
            <div>
                <div class="kpi-val">${kpi.uniqueCustomers}</div>
                <div class="kpi-label">Total Users</div>
            </div>
        </div>
        <div class="admin-kpi-card">
            <div class="admin-kpi-icon" style="background:#ede9fe;color:#7c3aed"><i class="fa-solid fa-coins"></i></div>
            <div>
                <div class="kpi-val">${kpi.totalCoins}</div>
                <div class="kpi-label">Coins Issued</div>
            </div>
        </div>`;
        
    // Render charts
    renderEmbeddedBarChart('embRevenueChart', revenue, '₹');
    renderEmbeddedBarChart('embProductsChart', products, ' units');
    
    const total = statuses.reduce((s, r) => s + r.value, 0);
    const statusColors = { Pending:'#f59e0b', Processing:'#3b82f6', Shipped:'#8b5cf6', Delivered:'#10b981', Cancelled:'#ef4444' };
    
    document.getElementById('embStatusChart').innerHTML = statuses.map(s => `
        <div class="adm-status-row">
            <span class="adm-status-dot" style="background:${statusColors[s.label]||'#6b7280'}"></span>
            <span class="adm-status-name">${s.label}</span>
            <div class="adm-status-bar-wrap">
                <div class="adm-status-bar-fill" style="width:${total ? Math.round(s.value/total*100) : 0}%;background:${statusColors[s.label]||'#6b7280'}"></div>
            </div>
            <span class="adm-status-count">${s.value}</span>
        </div>`).join('');
}

function renderEmbeddedBarChart(containerId, data, suffix = '') {
    const el = document.getElementById(containerId);
    if (!data || !data.length) {
        el.innerHTML = '<p style="color:var(--text-muted);text-align:center;padding:2rem;width:100%;">No data</p>';
        return;
    }
    const max = Math.max(...data.map(d => d.value));
    el.innerHTML = data.map(d => `
        <div class="adm-bar-item">
            <div class="adm-bar-fill" style="height:${max ? Math.round(d.value/max*100) : 0}%" title="${d.label}: ${d.value}${suffix}"></div>
            <span class="adm-bar-label">${d.label}</span>
        </div>`).join('');
}

// ─── Embedded Orders ──────────────────────────────────────────
async function loadEmbeddedOrders() {
    const res = await API.getAdminOrders();
    const orders = (res.status === 'success' && res.data) ? res.data : [];
    const statusColors = { Pending:'#f59e0b', Processing:'#3b82f6', Shipped:'#8b5cf6', Delivered:'#10b981', Cancelled:'#ef4444' };
    
    document.getElementById('embOrdersTableBody').innerHTML = orders.length ? orders.map(o => {
        const date = new Date(o.date).toLocaleDateString('en-IN', {day:'numeric',month:'short',year:'numeric'});
        const color = statusColors[o.status] || '#6b7280';
        return `<tr>
            <td><code>${o.id.slice(0,12)}...</code></td>
            <td>${o.userEmail}</td>
            <td><b>₹${parseFloat(o.total).toFixed(2)}</b></td>
            <td>${o.paymentMethod}</td>
            <td><span class="status-badge" style="background:${color}20;color:${color}">${o.status}</span></td>
            <td>${date}</td>
            <td>
                <button class="mini-btn primary" onclick='showOrderDetail(${JSON.stringify(o)})'>View</button>
                <button class="mini-btn" style="background:var(--primary-light-color);color:var(--primary-color)" onclick='openStatusModal(${JSON.stringify(o)})'>Update</button>
            </td>
        </tr>`;
    }).join('') : '<tr><td colspan="7" style="text-align:center;padding:2rem;">No orders found.</td></tr>';
}

let _currentStatusOrderId = null;

function openStatusModal(o) {
    _currentStatusOrderId = o.id;
    document.getElementById('statusOrderIdLabel').innerText = o.id.slice(0, 20) + '...';
    document.getElementById('statusSelect').value = o.status;
    document.getElementById('paymentStatusSelect').value = o.paymentStatus || 'Pending';
    openModal('statusModal');
}

async function saveOrderStatus() {
    if (!_currentStatusOrderId) return;
    const btn = document.getElementById('saveStatusBtn');
    const originalText = btn.innerHTML;
    
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Saving...';
    
    const res = await API.updateOrderStatus({
        id: _currentStatusOrderId,
        status: document.getElementById('statusSelect').value,
        paymentStatus: document.getElementById('paymentStatusSelect').value
    });
    
    btn.disabled = false;
    btn.innerHTML = originalText;
    
    if (res.status === 'success') {
        closeModal('statusModal');
        showToast('Order status updated! ✅');
        loadEmbeddedOrders();
    } else {
        showToast(res.message || 'Update failed.', 'error');
    }
}

function showOrderDetail(o) {
    const items = Array.isArray(o.items) ? o.items : [];
    document.getElementById('orderModalContent').innerHTML = `
        <div class="detail-row"><span>Order ID</span><span>${o.id}</span></div>
        <div class="detail-row"><span>Customer</span><span>${o.userEmail}</span></div>
        <div class="detail-row"><span>Address</span><span>${o.address}</span></div>
        <div class="detail-row"><span>Payment</span><span>${o.paymentMethod} — ${o.paymentStatus}</span></div>
        <div class="detail-row"><span>Status</span><span>${o.status}</span></div>
        
        <h4 style="margin:1.5rem 0 0.75rem;font-size:0.95rem;font-weight:700">Items</h4>
        <div class="admin-table-wrap" style="margin-bottom:1rem">
            <table class="admin-table" style="font-size:0.75rem;">
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
        </div>
        <div style="display:flex;flex-direction:column;align-items:flex-end;gap:0.25rem;font-size:0.85rem;">
            ${o.discountAmount > 0 ? `<span style="color:#ef4444;">Discount: -₹${o.discountAmount}</span>` : ''}
            ${o.deliveryCharge > 0 ? `<span>Delivery: ₹${o.deliveryCharge}</span>` : ''}
            <b style="font-size:1rem;color:var(--primary-color);">Total: ₹${parseFloat(o.total).toFixed(2)}</b>
        </div>`;
    openModal('orderModal');
}

// ─── Embedded Products ────────────────────────────────────────
async function loadEmbeddedProducts() {
    const res = await API.getProducts();
    const prods = (res.status === 'success' && res.data) ? res.data : [];
    
    document.getElementById('embProductsTableBody').innerHTML = prods.length ? prods.map(p => {
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
    }).join('') : '<tr><td colspan="7" style="text-align:center;padding:2rem;">No products found.</td></tr>';
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
    status.innerHTML  = '<span style="color:var(--text-muted)">⏳ Loading preview...</span>';
    imgEl.style.opacity = '0.5';
    imgEl.src = trimmed;
}

function openProductModal() {
    ['pName','pCategory','pRetail','pWholesale','pImage'].forEach(id => document.getElementById(id).value = '');
    document.getElementById('pMinQty').value = '1';
    document.getElementById('pStock').value = 'In Stock';
    document.getElementById('pTrending').checked = false;
    document.getElementById('productErr').style.display = 'none';
    document.getElementById('imgPreviewBox').style.display = 'none';
    document.getElementById('imgPreviewEl').src = '';
    document.getElementById('imgPreviewStatus').innerHTML = '';
    openModal('productModal');
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
    const btn       = document.querySelector('#productModal .primary-btn');

    if (!name || !category || !retail || !wholesale) {
        errEl.innerText = 'Name, Category, Retail and Wholesale prices are required.';
        errEl.style.display = 'block';
        return;
    }

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

    const res = await API.addProduct(product);

    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-plus"></i> Add Product';

    if (res.status === 'success') {
        closeModal('productModal');
        showToast('Product added successfully! 🎉');
        loadEmbeddedProducts();
    } else {
        errEl.innerText = res.message || 'Failed to add product.';
        errEl.style.display = 'block';
    }
}

async function deleteProduct(id) {
    if (!confirm('Are you sure you want to delete this product?')) return;
    const res = await API.deleteProduct(id);
    if (res.status === 'success') {
        showToast('Product deleted successfully.');
        loadEmbeddedProducts();
    } else {
        showToast(res.message || 'Failed to delete product.', 'error');
    }
}

// ─── Embedded Users ───────────────────────────────────────────
async function loadEmbeddedUsers() {
    const res = await API.getUsers();
    const users = (res.status === 'success' && res.data) ? res.data : [];
    
    document.getElementById('embUsersTableBody').innerHTML = users.length ? users.map(u => {
        const joined = u.created_at ? new Date(u.created_at).toLocaleDateString('en-IN') : '—';
        return `<tr>
            <td><b>${u.name || '—'}</b></td>
            <td>${u.email}</td>
            <td>${u.phone || '—'}</td>
            <td>${u.business_name || '—'}</td>
            <td><span style="color:#7c3aed;font-weight:700">🪙 ${u.coins || 0}</span></td>
            <td>${joined}</td>
        </tr>`;
    }).join('') : '<tr><td colspan="6" style="text-align:center;padding:2rem;">No users found.</td></tr>';
}

// ─── Send Notification Alert ──────────────────────────────────
async function sendBroadcastAlert(e) {
    e.preventDefault();
    const title   = document.getElementById('notifTitle').value.trim();
    const message = document.getElementById('notifMessage').value.trim();
    const type    = document.getElementById('notifType').value;
    const email   = document.getElementById('notifEmail').value.trim() || 'all';
    const res_el  = document.getElementById('notifResult');
    const btn     = document.getElementById('sendNotifBtn');
    
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Sending...';
    if (res_el) res_el.innerText = '';
    
    const res = await API.sendNotification({
        id: `notif-${Date.now()}`,
        title,
        message,
        type,
        userEmail: email,
        date: new Date().toISOString()
    });
    
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-paper-plane"></i> Send Notification';
    
    if (res.status === 'success') {
        if (res_el) {
            res_el.innerText = '✅ Notification sent successfully!';
            res_el.style.color = '#10b981';
        }
        document.getElementById('notifTitle').value = '';
        document.getElementById('notifMessage').value = '';
        document.getElementById('notifEmail').value = 'all';
    } else {
        if (res_el) {
            res_el.innerText = '❌ ' + (res.message || 'Failed to send');
            res_el.style.color = '#ef4444';
        }
    }
}


// ─── Auth ─────────────────────────────────────────────────────
function updateAuthUI() {
    const userBtn = document.getElementById('userBtn');
    if (session) {
        userBtn.innerHTML = `<i class="fa-solid fa-user"></i>`;
        userBtn.title = session.name || session.email;
    } else {
        userBtn.innerHTML = `<i class="fa-solid fa-right-to-bracket"></i>`;
        userBtn.title = 'Login';
    }
}

async function handleLogin(e) {
    e.preventDefault();
    const email    = document.getElementById('loginEmail').value.trim();
    const password = document.getElementById('loginPassword').value;
    const btn      = document.getElementById('loginBtn');
    const errorEl  = document.getElementById('loginError');

    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Logging in...';
    if (errorEl) errorEl.style.display = 'none';

    const res = await API.login(email, password);
    if (res.status === 'success') {
        session = res.data;
        localStorage.setItem('vsn_session', JSON.stringify(session));
        closeModal('loginModal');
        updateAuthUI();
        showToast(`Welcome back, ${session.name || session.email}! 👋`);
        // Auto-refresh analytics/profile if already on those views
        const profileView = document.getElementById('view-profile');
        if (profileView && profileView.classList.contains('active-view')) renderProfile();
    } else {
        if (errorEl) { errorEl.innerText = res.message || 'Invalid credentials. Please try again.'; errorEl.style.display = 'block'; }
    }
    btn.disabled  = false;
    btn.innerHTML = '<i class="fa-solid fa-right-to-bracket"></i> Login';
}

async function handleRegister(e) {
    e.preventDefault();
    const name     = document.getElementById('regName').value.trim();
    const email    = document.getElementById('regEmail').value.trim();
    const phone    = document.getElementById('regPhone').value.trim();
    const password = document.getElementById('regPassword').value;
    const refCode  = document.getElementById('regReferral').value.trim();
    const btn      = document.getElementById('registerBtn');
    const errorEl  = document.getElementById('regError');

    btn.disabled  = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Creating account...';
    if (errorEl) errorEl.style.display = 'none';

    const res = await API.register({ name, email, phone, password, referral_code: refCode || null });
    if (res.status === 'success') {
        showToast('🎉 Account created! Please login now.');
        // Switch to login tab and prefill email
        switchAuthTab('login');
        const loginEmailEl = document.getElementById('loginEmail');
        if (loginEmailEl) loginEmailEl.value = email;
        // Clear register form
        ['regName','regEmail','regPhone','regPassword','regReferral'].forEach(id => {
            const el = document.getElementById(id); if(el) el.value = '';
        });
    } else {
        if (errorEl) { errorEl.innerText = res.message || 'Registration failed. Please try again.'; errorEl.style.display = 'block'; }
    }
    btn.disabled  = false;
    btn.innerHTML = '<i class="fa-solid fa-user-plus"></i> Create Account';
}

function logout() {
    session = null;
    localStorage.removeItem('vsn_session');
    updateAuthUI();
    navigate('home');
    showToast('Logged out successfully.');
}

// ─── Razorpay Payment Session Integration ──────────────────────
let activeCheckoutOrder = null;

function openRzpModal(order) {
    activeCheckoutOrder = order;
    
    // Reset all screens
    document.getElementById('rzpMainScreen').style.display = 'flex';
    document.getElementById('rzpFormScreen').style.display = 'none';
    document.getElementById('rzpOtpScreen').style.display = 'none';
    document.getElementById('rzpSimulatedScreen').style.display = 'none';
    
    // Set amounts
    const amountStr = `₹${order.total.toFixed(2)}`;
    document.getElementById('rzpAmountDisplay').innerText = amountStr;
    document.getElementById('rzpFormAmount').innerText = amountStr;
    
    // Set prefill contact
    document.getElementById('rzpPrefillContact').innerText = order.userEmail || 'guest@vsn.com';
    
    // Clear inputs
    document.getElementById('rzpCardNo').value = '';
    document.getElementById('rzpCardExpiry').value = '';
    document.getElementById('rzpCardCvv').value = '';
    document.getElementById('rzpCardHolder').value = '';
    document.getElementById('rzpUpiId').value = '';
    document.getElementById('rzpOtpInput').value = '';
    document.getElementById('rzpOtpError').style.display = 'none';
    document.getElementById('rzpOtpLoading').style.display = 'none';
    
    // Switch to card tab by default
    switchRzpTab('card');

    const isTest = order.paymentMethod === 'Razorpay (Test Mode)';
    document.getElementById('rzpSimulateBtn').style.display = isTest ? 'block' : 'none';
    
    openModal('razorpayModal');
}

function switchRzpTab(tabName) {
    // Remove active class from all tabs
    document.querySelectorAll('.rzp-tab-btn').forEach(btn => {
        btn.classList.remove('active');
        btn.style.background = 'transparent';
        btn.style.color = 'var(--text-muted)';
        btn.style.boxShadow = 'none';
    });
    
    // Hide all tab content
    document.querySelectorAll('.rzp-tab-content').forEach(content => {
        content.style.display = 'none';
    });
    
    // Find active tab and style it
    const activeBtn = Array.from(document.querySelectorAll('.rzp-tab-btn')).find(btn => btn.getAttribute('onclick').includes(tabName));
    if (activeBtn) {
        activeBtn.classList.add('active');
        activeBtn.style.background = 'white';
        activeBtn.style.color = '#1a4cc1';
        activeBtn.style.boxShadow = 'var(--shadow-sm)';
    }
    
    // Show active content
    const activeContent = document.getElementById(`rzpTabContent_${tabName}`);
    if (activeContent) {
        activeContent.style.display = 'flex';
    }
}

function formatCardNumber(input) {
    let value = input.value.replace(/\D/g, '');
    let formatted = '';
    for (let i = 0; i < value.length; i++) {
        if (i > 0 && i % 4 === 0) formatted += ' ';
        formatted += value[i];
    }
    input.value = formatted;
}

function formatExpiry(input) {
    let value = input.value.replace(/\D/g, '');
    if (value.length > 2) {
        input.value = value.substring(0, 2) + '/' + value.substring(2, 4);
    } else {
        input.value = value;
    }
}

function showRzpFormScreen() {
    document.getElementById('rzpMainScreen').style.display = 'none';
    document.getElementById('rzpOtpScreen').style.display = 'none';
    document.getElementById('rzpFormScreen').style.display = 'flex';
}

function goBackToRzpMain() {
    document.getElementById('rzpFormScreen').style.display = 'none';
    document.getElementById('rzpMainScreen').style.display = 'flex';
}

function goBackToRzpForm() {
    document.getElementById('rzpOtpScreen').style.display = 'none';
    document.getElementById('rzpFormScreen').style.display = 'flex';
}

function submitMockPayment() {
    // Validate current tab content
    const activeTab = document.querySelector('.rzp-tab-btn.active');
    const tabName = activeTab ? activeTab.getAttribute('onclick').match(/'([^']+)'/)[1] : 'card';
    
    if (tabName === 'card') {
        const cardNo = document.getElementById('rzpCardNo').value.trim();
        const expiry = document.getElementById('rzpCardExpiry').value.trim();
        const cvv = document.getElementById('rzpCardCvv').value.trim();
        const name = document.getElementById('rzpCardHolder').value.trim();
        
        if (cardNo.replace(/\s/g, '').length < 16) {
            showToast('Please enter a valid 16-digit card number', 'error');
            return;
        }
        if (expiry.length < 5) {
            showToast('Please enter expiry date (MM/YY)', 'error');
            return;
        }
        if (cvv.length < 3) {
            showToast('Please enter a 3-digit CVV number', 'error');
            return;
        }
        if (!name) {
            showToast('Please enter cardholder name', 'error');
            return;
        }
    } else if (tabName === 'upi') {
        const upiId = document.getElementById('rzpUpiId').value.trim();
        if (!upiId || !upiId.includes('@')) {
            showToast('Please enter a valid UPI ID (e.g. success@razorpay)', 'error');
            return;
        }
    }
    
    // Validation pass -> proceed to OTP screen
    document.getElementById('rzpFormScreen').style.display = 'none';
    document.getElementById('rzpOtpScreen').style.display = 'flex';
    document.getElementById('rzpOtpInput').value = '';
    document.getElementById('rzpOtpError').style.display = 'none';
    document.getElementById('rzpOtpLoading').style.display = 'none';
    document.getElementById('rzpVerifyOtpBtn').disabled = false;
}

function verifyMockOtp() {
    const otp = document.getElementById('rzpOtpInput').value.trim();
    const errorEl = document.getElementById('rzpOtpError');
    const loadingEl = document.getElementById('rzpOtpLoading');
    const verifyBtn = document.getElementById('rzpVerifyOtpBtn');
    
    if (otp.length < 6) {
        errorEl.innerText = "Please enter a 6-digit OTP code.";
        errorEl.style.display = 'block';
        return;
    }
    
    errorEl.style.display = 'none';
    loadingEl.style.display = 'flex';
    verifyBtn.disabled = true;
    
    setTimeout(() => {
        if (otp === '123456') {
            const payId = "PAY_MOCK_" + Math.floor(Math.random() * 900000 + 100000);
            completeRzpCheckout(payId);
        } else {
            loadingEl.style.display = 'none';
            verifyBtn.disabled = false;
            errorEl.innerText = "Invalid OTP! Try entering 123456.";
            errorEl.style.display = 'block';
        }
    }, 1500);
}

async function initiateRzpCheckout() {
    if (!activeCheckoutOrder) return;
    
    const payBtn = document.getElementById('rzpPayBtn');
    payBtn.disabled = true;
    payBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Initializing Session...';
    
    // Check if user specifically requested Test Mode
    if (activeCheckoutOrder.paymentMethod === 'Razorpay (Test Mode)') {
        setTimeout(() => {
            payBtn.disabled = false;
            payBtn.innerHTML = '<i class="fa-solid fa-lock"></i> OPEN SECURE GATEWAY';
            showRzpFormScreen();
        }, 600);
        return;
    }
    
    try {
        // Create order in backend via proxy
        const res = await apiCall('/razorpay_order.php', 'POST', { amount: activeCheckoutOrder.total });
        
        if (res.status === 'success' && res.data && res.data.order_id) {
            // Check if Razorpay JS SDK is loaded
            if (typeof Razorpay !== 'undefined') {
                const options = {
                    key: res.data.key_id,
                    amount: res.data.amount,
                    currency: "INR",
                    name: "VSN HOME",
                    description: "B2B Order Payment",
                    order_id: res.data.order_id,
                    prefill: {
                        email: activeCheckoutOrder.userEmail
                    },
                    theme: {
                        color: "#1a4cc1"
                    },
                    handler: function (response) {
                        completeRzpCheckout(response.razorpay_payment_id);
                    },
                    modal: {
                        ondismiss: function() {
                            showToast('Payment window closed.', 'warning');
                            payBtn.disabled = false;
                            payBtn.innerHTML = '<i class="fa-solid fa-lock"></i> OPEN SECURE GATEWAY';
                        }
                    }
                };
                const rzp = new Razorpay(options);
                rzp.open();
            } else {
                // Razorpay SDK offline - trigger local mock/dummy gateway instead of simulator success directly
                showToast('Razorpay SDK offline. Loading dummy payment form...', 'warning');
                setTimeout(() => {
                    payBtn.disabled = false;
                    payBtn.innerHTML = '<i class="fa-solid fa-lock"></i> OPEN SECURE GATEWAY';
                    showRzpFormScreen();
                }, 1000);
            }
        } else {
            // Backend failed to initialize Razorpay (bad credentials or offline). Fall back to custom dummy checkout!
            showToast('Real gateway initialization failed. Redirecting to dummy secure gateway...', 'warning');
            setTimeout(() => {
                payBtn.disabled = false;
                payBtn.innerHTML = '<i class="fa-solid fa-lock"></i> OPEN SECURE GATEWAY';
                showRzpFormScreen();
            }, 1200);
        }
    } catch (e) {
        console.error(e);
        // Network error - Fall back to custom dummy checkout!
        showToast('Connection failed. Opening dummy secure gateway...', 'warning');
        setTimeout(() => {
            payBtn.disabled = false;
            payBtn.innerHTML = '<i class="fa-solid fa-lock"></i> OPEN SECURE GATEWAY';
            showRzpFormScreen();
        }, 1200);
    }
}

function simulateRzpSuccess(realOrderId = null) {
    if (!activeCheckoutOrder) return;
    const payId = "PAY_MOCK_" + Math.floor(Math.random() * 900000 + 100000);
    completeRzpCheckout(payId);
}

async function completeRzpCheckout(paymentId) {
    if (!activeCheckoutOrder) return;
    
    // Show loading/verifying state in modal status screen
    showRzpStatusScreen(true, 'Verifying payment status...');
    
    activeCheckoutOrder.paymentStatus = 'Paid';
    // Append payment reference ID to address or track in notes
    activeCheckoutOrder.address += ` | Payment ID: ${paymentId}`;
    
    const res = await API.placeOrder(activeCheckoutOrder);
    
    if (res.status === 'success') {
        cart = [];
        selectedOffer = null;
        updateCartBadge();
        renderCart();
        showToast('Order placed successfully! 🎉');
        navigate('orders');
        renderOrders();
        
        // Final success status
        showRzpStatusScreen(true, `Order verified successfully. Payment ID: ${paymentId}`);
    } else {
        showToast(res.message || 'Failed to verify order on backend.', 'error');
        showRzpStatusScreen(false, `Order verification failed: ${res.message}`);
    }
}

function showRzpStatusScreen(success, message) {
    document.getElementById('rzpMainScreen').style.display = 'none';
    document.getElementById('rzpFormScreen').style.display = 'none';
    document.getElementById('rzpOtpScreen').style.display = 'none';
    document.getElementById('rzpSimulatedScreen').style.display = 'flex';
    
    const iconWrap = document.getElementById('rzpStatusIconWrap');
    const icon = document.getElementById('rzpStatusIcon');
    const title = document.getElementById('rzpStatusTitle');
    const desc = document.getElementById('rzpStatusDesc');
    
    if (success) {
        iconWrap.style.background = '#10b981';
        iconWrap.classList.add('rzp-glow-active');
        icon.className = 'fa-solid fa-check';
        title.innerText = 'PAYMENT SUCCESSFUL';
        title.style.color = '#10b981';
    } else {
        iconWrap.style.background = '#ef4444';
        iconWrap.classList.remove('rzp-glow-active');
        icon.className = 'fa-solid fa-xmark';
        title.innerText = 'PAYMENT FAILED';
        title.style.color = '#ef4444';
    }
    desc.innerText = message;
}

// ─── Modals ───────────────────────────────────────────────────
function openModal(id) {
    // Route registerModal and forgotModal to unified loginModal
    if (id === 'registerModal') {
        openModal('loginModal');
        switchAuthTab('register');
        return;
    }
    if (id === 'forgotModal') {
        openModal('loginModal');
        switchAuthTab('forgot');
        return;
    }
    const el = document.getElementById(id);
    if (el) el.classList.add('open');
    // Reset to login tab when opening main auth modal
    if (id === 'loginModal') switchAuthTab('login');
}
function closeModal(id) {
    // Route to actual loginModal if one of the old aliases
    if (id === 'registerModal' || id === 'forgotModal') id = 'loginModal';
    const el = document.getElementById(id);
    if (el) el.classList.remove('open');
    // Clear errors
    ['loginError','regError','forgotEmailError','forgotResetError'].forEach(e => {
        const errEl = document.getElementById(e);
        if (errEl) { errEl.innerText = ''; errEl.style.display = 'none'; }
    });
}
document.addEventListener('keydown', e => { if (e.key === 'Escape') document.querySelectorAll('.modal.open').forEach(m => m.classList.remove('open')); });

// ─── Toast ────────────────────────────────────────────────────
function showToast(msg, type = 'success') {
    const toast = document.getElementById('toast');
    toast.innerText = msg;
    toast.className = `toast show ${type}`;
    clearTimeout(toast._t);
    toast._t = setTimeout(() => toast.classList.remove('show'), 3500);
}

// ─── Chatbot Enhanced Logic ───────────────────────────────────
let recognition = null;
if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    recognition = new SpeechRecognition();
    recognition.continuous = false;
    recognition.interimResults = false;
    recognition.lang = 'en-IN';
}

function toggleVoice(source) {
    if (!recognition) {
        showToast("Speech recognition not supported in this browser.", "error");
        return;
    }

    const btn = document.getElementById(`voiceBtn${source}`);
    const input = document.getElementById(`chatInput${source}`);

    if (btn.classList.contains('recording')) {
        recognition.stop();
        btn.classList.remove('recording');
    } else {
        recognition.start();
        btn.classList.add('recording');
        showToast("Listening...", "success");

        recognition.onresult = (event) => {
            const transcript = event.results[0][0].transcript;
            input.value = transcript;
            btn.classList.remove('recording');
            sendMessage(source);
        };

        recognition.onerror = () => {
            btn.classList.remove('recording');
            showToast("Voice error. Try again.", "error");
        };

        recognition.onend = () => { btn.classList.remove('recording'); };
    }
}

function loadChatHistory() {
    const history = JSON.parse(localStorage.getItem('vsn_chat_history') || '[]');
    history.forEach(msg => {
        addChatMessage('Floating', msg.text, msg.type, false);
    });
}

function saveChatMessage(text, type) {
    const history = JSON.parse(localStorage.getItem('vsn_chat_history') || '[]');
    history.push({ text, type, time: new Date().toISOString() });
    if (history.length > 50) history.shift(); // Keep last 50
    localStorage.setItem('vsn_chat_history', JSON.stringify(history));
}


function sendChatSuggestion(source, queryText) {
    const input = document.getElementById(`chatInput${source}`);
    if (input) {
        input.value = queryText;
        sendMessage(source);
    }
}

async function sendMessage(source) {
    const input = document.getElementById(`chatInput${source}`);
    const text = input.value.trim();
    if (!text) return;

    // Add user message
    addChatMessage(source, text, 'user');
    saveChatMessage(text, 'user');
    input.value = '';

    // Show typing indicator
    const typingMsg = addChatMessage(source, "AI is thinking...", 'bot typing');
    
    setTimeout(() => {
        if (typingMsg) typingMsg.remove();
        const response = getBotResponse(text);
        addChatMessage(source, response, 'bot');
        saveChatMessage(response, 'bot');
    }, 1200);
}

function addChatMessage(source, text, type, save = true) {
    const containers = [
        document.getElementById('chatMessagesFloating'),
        document.getElementById('chatMessagesPage')
    ];
    
    let lastMsg = null;
    containers.forEach(container => {
        if (!container) return;
        const msgDiv = document.createElement('div');
        msgDiv.className = `message ${type}`;
        msgDiv.innerHTML = `<div class="msg-bubble">${text}</div>`;
        container.appendChild(msgDiv);
        container.scrollTop = container.scrollHeight;
        lastMsg = msgDiv;
    });
    return lastMsg;
}

function getBotResponse(input) {
    const q = input.toLowerCase().trim();

    // 1. Greetings (check first to avoid false matches)
    if (/^(hi|hello|hey|greetings|namaste)[!?.]*$/.test(q)) {
        return `Hello! I'm the VSN Smart Assistant. I can help you find products among our ${allProducts.length} items, check delivery, or track orders. Try asking: "What is the price of sugar?"`;
    }

    // 2. AI Product Price Lookup
    if (q.includes('price') || q.includes('cost') || q.includes('rate') || q.includes('how much')) {
        const keyword = q.replace(/price|cost|rate|how much|of|the|is|what/gi,'').trim();
        if (keyword.length > 1) {
            const found = allProducts.find(p => p.name.toLowerCase().includes(keyword));
            if (found) {
                const price = found.wholesalePrice || found.retailPrice;
                return `The wholesale price for <b>${found.name}</b> is <b>₹${price}</b>. Currently: <b>${found.stockStatus}</b>. Want me to add it to your cart?`;
            }
        }
        return `I can check prices for you! Try: "What is the price of rice?" or "Cost of sugar"`;
    }

    // 3. Hindi/Regional
    if (q.includes('kya') || q.includes('hai') || q.includes('kaise')) {
        return "जी हाँ! मैं आपको उत्पादों की थोक कीमतें बता सकता हूँ। जैसे: 'चावल की कीमत क्या है?'";
    }

    // 4. Delivery
    if (q.includes('delivery') || q.includes('ship') || q.includes('charge') || q.includes('free')) {
        return `Standard delivery is ₹${logistics.deliveryCharge}, but FREE for orders over ₹${logistics.freeThreshold}! 🎉`;
    }

    // 5. Offers & Discounts
    if (q.includes('offer') || q.includes('discount') || q.includes('deal') || q.includes('coupon')) {
        if (allOffers.length > 0) return `We have ${allOffers.length} active offer(s)! Top deal: <b>"${allOffers[0].title}"</b> — ${allOffers[0].description}`;
        return "Our wholesale prices are already discounted by 10-20% vs retail!";
    }

    // 6. Orders
    if (q.includes('order') || q.includes('track') || q.includes('status')) {
        if (session) return `You can track your orders in the <b>My Orders</b> tab. Login is confirmed for: ${session.email}`;
        return "Please login to view and track your orders.";
    }

    // 7. Products list
    if (q.includes('product') || q.includes('item') || q.includes('stock') || q.includes('available')) {
        return `We have <b>${allProducts.length} products</b> available across multiple categories. Go to <b>Categories</b> to browse them all!`;
    }

    // 8. Generic product search
    if (q.length > 2) {
        const found = allProducts.find(p => p.name.toLowerCase().includes(q));
        if (found) {
            const price = found.wholesalePrice || found.retailPrice;
            return `Found: <b>${found.name}</b> at ₹${price} (${found.stockStatus}). Want to add it to cart?`;
        }
    }

    return "I'm here to help! Ask me about product prices, delivery charges, offers, or your orders. 😊";
}

// ─── Analytics Logic ──────────────────────────────────────────
async function updateAnalytics() {
    if (!session) return;
    const res    = await API.getOrders(session.email);
    const orders = (res.status === 'success' && res.data) ? res.data : [];

    const totalSpent   = orders.reduce((s, o) => s + parseFloat(o.total || 0), 0);
    const totalOrders  = orders.length;
    const totalSavings = totalSpent * 0.15;

    document.getElementById('totalSpent').innerText       = totalSpent.toFixed(2);
    document.getElementById('totalOrdersCount').innerText = totalOrders;
    document.getElementById('totalSavings').innerText     = totalSavings.toFixed(2);

    // Dynamic bar chart from real order data
    const chartEl = document.getElementById('userPurchaseChart');
    if (chartEl) {
        if (orders.length === 0) {
            chartEl.innerHTML = '<p style="color:var(--text-muted);margin:auto">No orders yet</p>';
        } else {
            const last6 = orders.slice(-6);
            const maxVal = Math.max(...last6.map(o => parseFloat(o.total || 0)));
            chartEl.innerHTML = last6.map(o => {
                const h = maxVal > 0 ? Math.round((parseFloat(o.total) / maxVal) * 90) : 10;
                const d = new Date(o.date).toLocaleDateString('en-IN', { day:'numeric', month:'short' });
                return `<div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:6px;justify-content:flex-end">
                    <span style="font-size:0.6rem;color:var(--text-muted)">₹${parseFloat(o.total).toFixed(0)}</span>
                    <div style="height:${h}%;width:100%;background:linear-gradient(to top,var(--primary-color),var(--primary-light));border-radius:4px 4px 0 0;transition:height 0.5s"></div>
                    <span style="font-size:0.6rem;color:var(--text-muted)">${d}</span>
                </div>`;
            }).join('');
        }
    }

    const profileRes = await API.getProfile(session.email);
    if (profileRes.status === 'success') {
        document.getElementById('totalCoins').innerText = profileRes.data.coins || 0;
    }
}

// Add Enter key listeners for chat inputs
document.addEventListener('DOMContentLoaded', () => {
    ['Floating', 'Page'].forEach(id => {
        const el = document.getElementById(`chatInput${id}`);
        if (el) el.addEventListener('keypress', e => { if (e.key === 'Enter') sendMessage(id); });
    });
});

// ─── Clipboard Copy ───────────────────────────────────────────
function copyReferralCode(code, btnEl) {
    navigator.clipboard.writeText(code).then(() => {
        const origHTML = btnEl.innerHTML;
        btnEl.innerHTML = '<i class="fa-solid fa-check" style="color:#10b981"></i>';
        showToast('Referral code copied to clipboard!');
        setTimeout(() => { btnEl.innerHTML = origHTML; }, 1500);
    }).catch(err => {
        console.error('Copy failed:', err);
    });
}

// ─── GST Field Visibility Toggle ──────────────────────────────
function toggleGSTFields() {
    const isChecked = document.getElementById('requiresGST').checked;
    document.getElementById('gstFields').style.display = isChecked ? 'grid' : 'none';
}

// ─── Notifications Controller ───────────────────────────────
function toggleNotifDropdown() {
    const dropdown = document.getElementById('notifDropdown');
    dropdown.classList.toggle('show');
    if (dropdown.classList.contains('show') && session) {
        // Automatically mark as read when opened
        markAllNotifsRead();
    }
}

async function loadNotifications() {
    const email = session ? session.email : 'guest';
    const res = await API.getNotifications(email);
    const badge = document.getElementById('notifBadge');
    const container = document.getElementById('notifList');
    
    if (res.status === 'success' && res.data) {
        const notifs = res.data;
        const unreadCount = notifs.filter(n => !n.isRead).length;
        
        if (unreadCount > 0) {
            badge.innerText = unreadCount;
            badge.style.display = 'inline-flex';
        } else {
            badge.style.display = 'none';
        }
        
        if (notifs.length === 0) {
            container.innerHTML = '<p class="empty-msg" style="padding:1.5rem;text-align:center;color:var(--text-muted)">No notifications yet.</p>';
            return;
        }
        
        container.innerHTML = notifs.map(n => {
            const time = new Date(n.date).toLocaleDateString('en-IN', { hour: '2-digit', minute: '2-digit' });
            return `
            <div class="notif-item ${!n.isRead ? 'unread' : ''}">
                <div class="notif-item-header">
                    <span class="notif-item-title">${n.title}</span>
                    <span class="notif-item-time">${time}</span>
                </div>
                <div class="notif-item-body">${n.message}</div>
            </div>`;
        }).join('');
    } else {
        container.innerHTML = '<p class="empty-msg" style="padding:1.5rem;text-align:center;color:var(--text-muted)">No notifications yet.</p>';
        badge.style.display = 'none';
    }
}

async function markAllNotifsRead() {
    if (!session) return;
    const res = await API.markNotificationsRead(session.email);
    if (res.status === 'success') {
        document.getElementById('notifBadge').style.display = 'none';
        // reload notifications to clear styles
        const notifItems = document.querySelectorAll('.notif-item');
        notifItems.forEach(el => el.classList.remove('unread'));
    }
}

// ─── PWA & Localization & Custom Widgets ─────────────────────────
// Register Service Worker for offline PWA capabilities
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('./sw.js')
            .then(reg => console.log('Service Worker registered successfully with scope:', reg.scope))
            .catch(err => console.error('Service Worker registration failed:', err));
    });
}

// PWA Install Prompt handling
let deferredPrompt = null;
window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredPrompt = e;
    const installBanner = document.getElementById('pwaInstallBanner');
    if (installBanner) {
        installBanner.style.display = 'flex';
    }
});

document.addEventListener('DOMContentLoaded', () => {
    const installBtn = document.getElementById('pwaInstallBtn');
    if (installBtn) {
        installBtn.addEventListener('click', async () => {
            if (!deferredPrompt) return;
            deferredPrompt.prompt();
            const { outcome } = await deferredPrompt.userChoice;
            console.log(`User response to the install prompt: ${outcome}`);
            deferredPrompt = null;
            dismissPwaBanner();
        });
    }
});

function dismissPwaBanner() {
    const installBanner = document.getElementById('pwaInstallBanner');
    if (installBanner) installBanner.style.display = 'none';
}

// FAB Speed Dial Toggle
function toggleFabMenu() {
    const fabMenu = document.getElementById('utilityFabMenu');
    const icon = document.getElementById('fabMainIcon');
    if (!fabMenu) return;
    
    const isExpanded = fabMenu.classList.toggle('expanded');
    if (icon) {
        icon.className = isExpanded ? 'fa-solid fa-xmark' : 'fa-solid fa-ellipsis-vertical';
    }
}

// Business Calculator State
let calcInput = '0';
let calcOp = null;
let calcStored = null;
let calcNewNumber = false;

function updateCalcScreen() {
    const screen = document.getElementById('calcScreen');
    if (screen) screen.innerText = calcInput;
}

function clearCalc() {
    calcInput = '0';
    calcOp = null;
    calcStored = null;
    calcNewNumber = false;
    updateCalcScreen();
}

function backspaceCalc() {
    if (calcInput.length > 1) {
        calcInput = calcInput.slice(0, -1);
    } else {
        calcInput = '0';
    }
    updateCalcScreen();
}

function inputCalcNum(num) {
    if (calcInput === '0' || calcNewNumber) {
        calcInput = num;
        calcNewNumber = false;
    } else {
        calcInput += num;
    }
    updateCalcScreen();
}

function inputCalcOp(op) {
    calcStored = parseFloat(calcInput);
    calcOp = op;
    calcNewNumber = true;
}

function evalCalc() {
    if (!calcOp || calcStored === null) return;
    const currentVal = parseFloat(calcInput);
    let result = 0;
    
    switch (calcOp) {
        case '+': result = calcStored + currentVal; break;
        case '-': result = calcStored - currentVal; break;
        case '*': result = calcStored * currentVal; break;
        case '/': result = currentVal !== 0 ? calcStored / currentVal : 0; break;
        case '%': result = (calcStored * currentVal) / 100; break;
        default: return;
    }
    
    calcInput = Number.isInteger(result) ? result.toString() : result.toFixed(2);
    calcOp = null;
    calcStored = null;
    calcNewNumber = true;
    updateCalcScreen();
}

// B2B Calendar Logistics Data & Logic
let selectedCalendarDate = new Date();
const calendarB2BEvents = {
    // Mondays and Thursdays: Restock
    restockDays: [1, 4],
    // Tuesdays and Fridays: Flash Sale
    flashDays: [2, 5],
    // Wednesdays / Saturday: Audits
    auditDays: [3, 6]
};

function renderB2BCalendar() {
    const grid = document.getElementById('calendarGrid');
    if (!grid) return;
    
    const year = 2026;
    const month = 4; // May (0-indexed)
    
    const firstDayIndex = new Date(year, month, 1).getDay(); // Friday = 5
    const totalDays = 31;
    
    let html = '';
    
    const weekDays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    weekDays.forEach(day => {
        html += `<div class="calendar-day-header">${day}</div>`;
    });
    
    for (let i = 0; i < firstDayIndex; i++) {
        html += `<div class="calendar-day-cell other-month"></div>`;
    }
    
    for (let day = 1; day <= totalDays; day++) {
        const dateObj = new Date(year, month, day);
        const dayOfWeek = dateObj.getDay();
        const isSelected = dateObj.toDateString() === selectedCalendarDate.toDateString();
        
        let dotsHtml = '<div class="calendar-dot-indicators">';
        if (calendarB2BEvents.restockDays.includes(dayOfWeek)) {
            dotsHtml += '<span class="calendar-dot delivery" title="Restock Scheduled"></span>';
        }
        if (calendarB2BEvents.flashDays.includes(dayOfWeek)) {
            dotsHtml += '<span class="calendar-dot offer" title="Flash Sale"></span>';
        }
        if (day % 10 === 6 || (dayOfWeek === 6 && day % 2 === 0)) {
            dotsHtml += '<span class="calendar-dot business" title="Inventory Audit"></span>';
        }
        dotsHtml += '</div>';
        
        html += `
            <div class="calendar-day-cell ${isSelected ? 'active-day' : ''}" 
                 onclick="selectCalendarDate(${day})">
                ${day}
                ${dotsHtml}
            </div>
        `;
    }
    
    grid.innerHTML = html;
    updateCalendarEventsList();
}

function selectCalendarDate(day) {
    selectedCalendarDate = new Date(2026, 4, day); // May 2026
    renderB2BCalendar();
}

function updateCalendarEventsList() {
    const container = document.getElementById('calendarEventsList');
    if (!container) return;
    
    const dayOfWeek = selectedCalendarDate.getDay();
    const dayOfMonth = selectedCalendarDate.getDate();
    const events = [];
    
    if (calendarB2BEvents.restockDays.includes(dayOfWeek)) {
        events.push({
            title: "Bulk Restock Scheduled",
            time: "09:00 AM",
            type: "delivery",
            desc: "Vijayawada logistics grain & staple restock trucks arrival."
        });
    }
    if (calendarB2BEvents.flashDays.includes(dayOfWeek)) {
        events.push({
            title: "Flash Sale: Rice & Grains",
            time: "11:30 AM",
            type: "offer",
            desc: "10% additional discount on bulk purchases of fine rice."
        });
    }
    if (dayOfMonth % 10 === 6 || (dayOfWeek === 6 && dayOfMonth % 2 === 0)) {
        events.push({
            title: "Inventory Audit & Stock Check",
            time: "04:00 PM",
            type: "business",
            desc: "Audit of cold store and staple goods catalog counts."
        });
    }
    
    if (events.length === 0) {
        container.innerHTML = `
            <p style="font-size:0.8rem;color:var(--text-muted);text-align:center;padding:1rem;">
                No events scheduled for this business day.
            </p>
        `;
        return;
    }
    
    container.innerHTML = events.map(e => `
        <div class="cal-event-card">
            <div class="cal-event-icon-wrap ${e.type}">
                <i class="fa-solid ${e.type === 'delivery' ? 'fa-shipping-fast' : (e.type === 'offer' ? 'fa-tags' : 'fa-briefcase')}"></i>
            </div>
            <div style="flex:1;">
                <div style="font-weight:700;font-size:0.85rem;color:var(--text-main);">${e.title}</div>
                <div style="font-size:0.75rem;color:var(--text-muted);">${e.time} — ${e.desc}</div>
            </div>
        </div>
    `).join('');
}

// Location Map Picker Logic
let lockedCoordinates = { lat: 21.1458, lng: 79.0882 };

function handleMapPickerClick(event) {
    const mapContainer = event.currentTarget;
    const rect = mapContainer.getBoundingClientRect();
    const clickX = event.clientX - rect.left;
    const clickY = event.clientY - rect.top;
    
    const percentX = (clickX / rect.width) * 100;
    const percentY = (clickY / rect.height) * 100;
    
    const marker = document.getElementById('mapUserMarker');
    if (marker) {
        marker.style.left = `${percentX}%`;
        marker.style.top = `${percentY}%`;
        marker.style.display = 'block';
    }
    
    const latOffset = (50 - percentY) * 0.0008;
    const lngOffset = (percentX - 50) * 0.0008;
    
    const baseLat = parseFloat(logistics.latitude || 21.1458);
    const baseLng = parseFloat(logistics.longitude || 79.0882);
    
    lockedCoordinates.lat = (baseLat + latOffset).toFixed(6);
    lockedCoordinates.lng = (baseLng + lngOffset).toFixed(6);
    
    const label = document.getElementById('mapCoordsLabel');
    if (label) {
        label.innerText = `Lat: ${lockedCoordinates.lat}, Lng: ${lockedCoordinates.lng}`;
    }
}

function lockMapCoordinates() {
    const targetStatus = document.getElementById('coordLockStatus');
    if (targetStatus) {
        targetStatus.innerHTML = `<i class="fa-solid fa-circle-check" style="color:var(--accent-color)"></i> Lat: ${lockedCoordinates.lat}, Lng: ${lockedCoordinates.lng}`;
    }
    
    const streetAddr = document.getElementById('addressStreet');
    if (streetAddr) {
        let val = streetAddr.value.split(' (Coords:')[0];
        streetAddr.value = `${val} (Coords: ${lockedCoordinates.lat}, ${lockedCoordinates.lng})`;
    }
    
    showToast(`Locked delivery coordinates!`);
    closeModal('mapPickerModal');
}

function autoDetectAddress() {
    if (navigator.geolocation) {
        const statusEl = document.getElementById('coordLockStatus');
        if (statusEl) statusEl.innerText = "Detecting geolocation...";
        
        navigator.geolocation.getCurrentPosition(
            (position) => {
                lockedCoordinates.lat = position.coords.latitude.toFixed(6);
                lockedCoordinates.lng = position.coords.longitude.toFixed(6);
                
                if (statusEl) {
                    statusEl.innerHTML = `<i class="fa-solid fa-circle-check" style="color:var(--accent-color)"></i> Lat: ${lockedCoordinates.lat}, Lng: ${lockedCoordinates.lng}`;
                }
                
                const streetAddr = document.getElementById('addressStreet');
                if (streetAddr) {
                    let val = streetAddr.value.split(' (Coords:')[0];
                    streetAddr.value = `${val} (Coords: ${lockedCoordinates.lat}, ${lockedCoordinates.lng})`;
                }
                
                showToast("Location detected successfully!");
            },
            (error) => {
                console.error(error);
                showToast("Permission denied or location unavailable. Mocking location...", "warning");
                lockedCoordinates.lat = "21.154238";
                lockedCoordinates.lng = "79.088214";
                if (statusEl) {
                    statusEl.innerHTML = `<i class="fa-solid fa-circle-check" style="color:var(--accent-color)"></i> Lat: ${lockedCoordinates.lat}, Lng: ${lockedCoordinates.lng} (Simulated)`;
                }
            }
        );
    } else {
        showToast("Geolocation not supported by this browser.", "error");
    }
}

const AppText = {
    english: {
        hello: "HELLO",
        vsn_home: "V.S.N. HOME",
        hub_location: "Vijayawada Hub",
        profile_title: "Profile",
        my_business: "My Business",
        business_wallet: "Business Wallet",
        loyalty_coins: "Loyalty Coins",
        my_orders: "My Orders",
        my_addresses: "My Addresses",
        settings: "Settings",
        fav_language: "Language",
        support: "Support",
        call_manager: "Call Manager",
        chat_whatsapp: "Chat on WhatsApp",
        logout: "Logout",
        tab_wholesale: "Wholesale",
        tab_deals: "Bulk Deals",
        tab_cart: "Cart",
        tab_insights: "Insights",
        tab_stock: "Stock",
        tab_orders: "Orders",
        tab_partners: "Partners",
        tab_alerts: "Alerts",
        cat_staples: "Staples",
        cat_oil: "Oil & Ghee",
        cat_snacks: "Snacks",
        cat_cleaning: "Cleaning",
        cat_dairy: "Dairy",
        search_placeholder: "Search items...",
        live_trends: "LIVE TRENDS",
        all_category: "All",
        trending_now: "Trending Now",
        all_items: "All Items",
        out_of_stock_only: "Out of Stock Only",
        price_low_high: "Price: Low to High",
        price_high_low: "Price: High to Low",
        reset_filters: "Reset Filters",
        add_to_cart: "Add to Cart",
        sign_in: "Sign In",
        sign_up: "Sign Up",
        order_inventory: "Order Inventory",
        clear_all: "Clear All",
        checkout: "Proceed to Checkout",
        order_placed: "Order Placed",
        use_coins: "Use Loyalty Coins",
        coins_available: "You have {coins} coins available",
        worth: "Worth",
        product_details: "Product Details",
        min_order_qty: "Min. Order Qty",
        category: "Category",
        net_quantity: "Net Quantity",
        save_label: "SAVE",
        no_image: "No Image",
        off_label: "OFF",
        out_of_stock: "Out of Stock",
        error_network: "Network error. Please check your connection.",
        error_invalid_input: "Invalid input. Please check your data."
    },
    hindi: {
        hello: "नमस्ते",
        vsn_home: "वी.एस.एन. होम",
        hub_location: "विजयवाड़ा हब",
        profile_title: "प्रोफ़ाइल",
        my_business: "मेरा व्यवसाय",
        business_wallet: "व्यवसाय वॉलेट",
        loyalty_coins: "लॉयल्टी सिक्के",
        my_orders: "मेरे आदेश",
        my_addresses: "मेरे पते",
        settings: "सेटिंग्स",
        fav_language: "भाषा",
        support: "सहायता",
        call_manager: "मैनेजर को कॉल करें",
        chat_whatsapp: "व्हाट्सएप पर चैट करें",
        logout: "लॉगआउट",
        tab_wholesale: "थोक",
        tab_deals: "बल्क डील्स",
        tab_cart: "कार्ट",
        tab_insights: "इनसाइट्स",
        tab_stock: "स्टॉक",
        tab_orders: "आदेश",
        tab_partners: "साझेदार",
        tab_alerts: "अलर्ट",
        cat_staples: "स्टेपल्स",
        cat_oil: "तेल और घी",
        cat_snacks: "स्नैक्स",
        cat_cleaning: "सफाई",
        cat_dairy: "डेयरी",
        search_placeholder: "सामान खोजें...",
        live_trends: "लाइव ट्रेंड्स",
        all_category: "सब",
        trending_now: "अभी ट्रेंडिंग",
        all_items: "सभी सामान",
        out_of_stock_only: "केवल स्टॉक से बाहर",
        price_low_high: "कीमत: कम से अधिक",
        price_high_low: "कीमत: अधिक से कम",
        reset_filters: "फ़िल्टर रीसेट करें",
        add_to_cart: "कार्ट में जोड़ें",
        sign_in: "साइन इन करें",
        sign_up: "साइन अप करें",
        order_inventory: "ऑर्डर इन्वेंटरी",
        clear_all: "सभी हटाएं",
        checkout: "चेकआउट के लिए आगे बढ़ें",
        order_placed: "ऑर्डर प्राप्त",
        use_coins: "लॉयल्टी सिक्कों का उपयोग करें",
        coins_available: "आपके पास {coins} सिक्के उपलब्ध हैं",
        worth: "कीमत",
        product_details: "उत्पाद विवरण",
        min_order_qty: "न्यूनतम मात्रा",
        category: "श्रेणी",
        net_quantity: "शुद्ध मात्रा",
        save_label: "बचत",
        no_image: "कोई छवि नहीं",
        off_label: "छूट",
        out_of_stock: "स्टॉक से बाहर",
        error_network: "नेटवर्क त्रुटि। कृपया अपना कनेक्शन जांचें।",
        error_invalid_input: "अमान्य इनपुट। कृपया अपना डेटा जांचें।"
    },
    telugu: {
        hello: "నమస్కారం",
        vsn_home: "వి.ఎస్.ఎన్. హోమ్",
        hub_location: "విజయవాడ హబ్",
        profile_title: "ప్రొఫైల్",
        my_business: "నా వ్యాపారం",
        business_wallet: "వ్యాపార వాలెట్",
        loyalty_coins: "లాయల్టీ నాణాలు",
        my_orders: "నా ఆర్డర్లు",
        my_addresses: "నా చిరునామాలు",
        settings: "సెట్టింగులు",
        fav_language: "భాష",
        support: "మద్దతు",
        call_manager: "మేనేజర్‌కి కాల్ చేయండి",
        chat_whatsapp: "వాట్సాప్‌లో చాట్ చేయండి",
        logout: "లాగ్ అవుట్",
        tab_wholesale: "టోకు",
        tab_deals: "బల్క్ డీల్స్",
        tab_cart: "కార్ట్",
        tab_insights: "అంతర్దృష్టులు",
        tab_stock: "స్టాక్",
        tab_orders: "ఆర్డర్లు",
        tab_partners: "భాగస్వాములు",
        tab_alerts: "హెచ్చరికలు",
        cat_staples: "స్టేపుల్స్",
        cat_oil: "నూనె & నెయ్యి",
        cat_snacks: "స్నాక్స్",
        cat_cleaning: "శుభ్రపరచడం",
        cat_dairy: "పాడి",
        search_placeholder: "వస్తువుల కోసం వెతకండి...",
        live_trends: "లైవ్ ట్రెండ్స్",
        all_category: "అన్నీ",
        trending_now: "ప్రస్తుతం ట్రెండింగ్‌",
        all_items: "అన్ని వస్తువులు",
        out_of_stock_only: "స్టాక్ లేనివి మాత్రమే",
        price_low_high: "ధర: తక్కువ నుండి ఎక్కువ",
        price_high_low: "ధర: ఎక్కువ నుండి తక్కువ",
        reset_filters: "ఫిల్టర్లను రీసెట్ చేయండి",
        add_to_cart: "కార్టకు జోడించు",
        sign_in: "సైన్ ఇన్",
        sign_up: "సైన్ అప్",
        order_inventory: "ఆర్డర్ ఇన్‌వెంటరీ",
        clear_all: "అన్నీ క్లియర్ చేయండి",
        checkout: "చెక్‌అవుట్‌కు వెళ్లండి",
        order_placed: "ఆర్డర్ ఆర్డర్ చేయబడింది",
        use_coins: "లాయల్టీ నాణేలను ఉపయోగించండి",
        coins_available: "మీ దగ్గర {coins} నాణేలు అందుబాటులో ఉన్నాయి",
        worth: "విలువ",
        product_details: "ఉత్పత్తి వివరాలు",
        min_order_qty: "కనిష్ట ఆర్డర్ పరిమాణం",
        category: "వర్గం",
        net_quantity: "నికర పరిమాణం",
        save_label: "పొదుపు",
        no_image: "చిత్రం లేదు",
        off_label: "తగ్గింపు",
        out_of_stock: "స్టాక్‌లో లేనిది",
        error_network: "నెట్‌వర్క్ ఎర్రర్. మీ కనెక్షన్ తనిఖీ చేయండి.",
        error_invalid_input: "చెల్లని ఇన్‌పుట్. దయచేసి మీ డేటా తనిఖీ చేయండి."
    },
    tamil: {
        hello: "வணக்கம்",
        vsn_home: "வி.எஸ்.என். ஹோம்",
        hub_location: "விஜயவாடா ஹப்",
        profile_title: "சுயவிவரம்",
        my_business: "எனது தொழில்",
        business_wallet: "தொழில் பணப்பை",
        loyalty_coins: "விசுவாச நாணயங்கள்",
        my_orders: "எனது ஆர்டர்கள்",
        my_addresses: "எனது முகவரிகள்",
        settings: "அமைப்புகள்",
        fav_language: "மொழி",
        support: "ஆதரவு",
        call_manager: "மேலாளரை அழைக்கவும்",
        chat_whatsapp: "வாட்ஸ்அப்பில் அரட்டையடிக்கவும்",
        logout: "வெளியேறு",
        tab_wholesale: "மொத்த விற்பனை",
        tab_deals: "மொத்த ஒப்பந்தங்கள்",
        tab_cart: "கூடை",
        tab_insights: "நுண்ணறிவு",
        tab_stock: "சரக்கு",
        tab_orders: "ஆர்டர்கள்",
        tab_partners: "பங்காளிகள்",
        tab_alerts: "எச்சரிக்கைகள்",
        cat_staples: "ஸ்டேபிள்ஸ்",
        cat_oil: "எண்ணெய் & நெய்",
        cat_snacks: "தின்பண்டங்கள்",
        cat_cleaning: "சுத்தம்",
        cat_dairy: "பால் பொருட்கள்",
        search_placeholder: "பொருட்களைத் தேடுங்கள்...",
        live_trends: "நேரடி போக்குகள்",
        all_category: "அனைத்தும்",
        trending_now: "இப்போது டிரெண்டிங்",
        all_items: "அனைத்து பொருட்கள்",
        out_of_stock_only: "கையிருப்பில் இல்லாதவை மட்டும்",
        price_low_high: "விலை: குறைந்ததிலிருந்து அதிகமானது",
        price_high_low: "விலை: அதிகபட்சத்திலிருந்து குறைந்தது",
        reset_filters: "வடிகட்டிகளை மீட்டமைக்கவும்",
        add_to_cart: "கூடைக்கு சேர்க்கவும்",
        sign_in: "உள்நுழைக",
        sign_up: "பதிவு செய்க",
        order_inventory: "ஆர்டர் சரக்கு",
        clear_all: "அனைத்தையும் அழிக்கவும்",
        checkout: "பரிவர்த்தனைக்கு செல்லவும்",
        order_placed: "ஆர்டர் வைக்கப்பட்டது",
        use_coins: "விசுவாச நாணயங்களைப் பயன்படுத்துங்கள்",
        coins_available: "உங்களிடம் {coins} நாணயங்கள் உள்ளன",
        worth: "மதிப்பு",
        product_details: "பொருளின் விபரம்",
        min_order_qty: "குறைந்தபட்ச ஆர்டர் அளவு",
        category: "பிரிவு",
        net_quantity: "நிகர அளவு",
        save_label: "சேமிப்பு",
        no_image: "படம் இல்லை",
        off_label: "தள்ளுபடி",
        out_of_stock: "பங்கிலிருந்து வெளியே",
        error_network: "நெட்வொர்க் பிழை. உங்கள் இணைப்பை சரிபார்க்கவும்.",
        error_invalid_input: "செல்லுபடியாகாத உள்ளீடு. உங்கள் தரவை சரிபார்க்கவும்."
    }
};

function selectAppLanguage(lang, reload = true) {
    if (!AppText[lang]) lang = 'english';
    localStorage.setItem('vsn_language', lang);
    
    // Style active lang card in language modal
    document.querySelectorAll('.lang-card').forEach(c => c.classList.remove('active'));
    const activeCard = document.getElementById(`lang_${lang}`);
    if (activeCard) activeCard.classList.add('active');
    
    // Translate standard navigation links
    const navLinks = document.querySelectorAll('.nav-links a, .mobile-links a');
    navLinks.forEach(link => {
        const view = link.getAttribute('data-view');
        if (view === 'home') link.childNodes[0].nodeValue = AppText[lang].tab_wholesale;
        if (view === 'categories') link.childNodes[0].nodeValue = AppText[lang].category;
        if (view === 'offers') link.childNodes[0].nodeValue = AppText[lang].tab_deals;
        if (view === 'orders') link.childNodes[0].nodeValue = AppText[lang].my_orders;
        if (view === 'chatbot') link.childNodes[0].nodeValue = AppText[lang].support;
        if (view === 'analytics') link.childNodes[0].nodeValue = AppText[lang].tab_insights;
    });

    // Logo text
    const logoEl = document.querySelector('.logo h1');
    if (logoEl) {
        logoEl.innerHTML = `VSN <span>${lang === 'english' ? 'Grocery' : (lang === 'hindi' ? 'ग्रोसरी' : (lang === 'telugu' ? 'గ్రోసరీ' : 'மளிகை'))}</span>`;
    }
    
    // Search input
    const searchInput = document.getElementById('searchInput');
    if (searchInput) searchInput.placeholder = AppText[lang].search_placeholder;
    const chatInputPage = document.getElementById('chatInputPage');
    if (chatInputPage) chatInputPage.placeholder = AppText[lang].search_placeholder;
    
    // Quick translation tags
    const categoryTitle = document.getElementById('categoryTitle');
    if (categoryTitle && (categoryTitle.innerText === 'All Products' || categoryTitle.innerText === 'सभी सामान' || categoryTitle.innerText === 'అన్ని వస్తువులు' || categoryTitle.innerText === 'அனைத்து பொருட்கள்' || categoryTitle.innerText === 'All')) {
        categoryTitle.innerText = AppText[lang].all_items;
    }
    
    if (reload) {
        renderHomeProducts();
        renderCategories();
        const activeCat = document.querySelector('.category-card.active-cat h4');
        renderCategoryProducts(activeCat ? activeCat.innerText : 'All');
        renderOffersView();
        renderCart();
        renderProfile();
    }
}

function getLocalizedName(prod) {
    const lang = localStorage.getItem('vsn_language') || 'english';
    if (!prod.localizedNames) return prod.name;
    const keyMap = {
        english: ['English', 'english'],
        hindi: ['Hindi', 'Hindi (हिन्दी)', 'hindi'],
        telugu: ['Telugu', 'Telugu (తెలుగు)', 'telugu'],
        tamil: ['Tamil', 'Tamil (தமிழ்)', 'tamil']
    };
    const possibleKeys = keyMap[lang] || [lang];
    for (const key of possibleKeys) {
        if (prod.localizedNames[key]) {
            return prod.localizedNames[key];
        }
    }
    return prod.name;
}

// ─── Forgot Password recovery flow handlers ───────────────────
let forgotUserEmail = '';

async function handleForgotEmail(e) {
    e.preventDefault();
    const email = document.getElementById('forgotEmail').value.trim();
    const errorEl = document.getElementById('forgotEmailError');
    const btn = document.getElementById('forgotEmailBtn');
    
    if (!email) {
        errorEl.innerText = 'Please enter your email';
        errorEl.style.display = 'block';
        return;
    }
    
    errorEl.style.display = 'none';
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Verifying...';
    
    const res = await API.forgotPassword(email);
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-paper-plane"></i> Verify Email';
    
    if (res.status === 'success') {
        forgotUserEmail = email;
        const titleEl = document.getElementById('forgotTitle');
        const subEl   = document.getElementById('forgotSubtitle');
        if (titleEl) titleEl.innerText = 'Create New Password';
        if (subEl) subEl.innerText = 'Email verified! Now set your new password.';
        document.getElementById('forgotStep1Form').style.display = 'none';
        document.getElementById('forgotStep2Form').style.display = 'block';
    } else {
        errorEl.innerText = res.message || 'Email not found. Please check and try again.';
        errorEl.style.display = 'block';
    }
}

async function handleForgotReset(e) {
    e.preventDefault();
    const newPass  = document.getElementById('forgotNewPassword').value;
    const confPass = document.getElementById('forgotConfirmPassword').value;
    const errorEl  = document.getElementById('forgotResetError');
    const btn      = document.getElementById('forgotResetBtn');
    
    if (!newPass || !confPass) {
        errorEl.innerText = 'All fields are required'; errorEl.style.display = 'block'; return;
    }
    if (newPass !== confPass) {
        errorEl.innerText = 'Passwords do not match'; errorEl.style.display = 'block'; return;
    }
    if (newPass.length < 6) {
        errorEl.innerText = 'Password must be at least 6 characters'; errorEl.style.display = 'block'; return;
    }
    
    errorEl.style.display = 'none';
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Updating...';
    
    const res = await API.resetPassword(forgotUserEmail, newPass);
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-key"></i> Update Password';
    
    if (res.status === 'success') {
        showToast('Password updated successfully! 🎉 Please login with your new password.');
        // Clear forms and switch to login tab
        ['forgotEmail','forgotNewPassword','forgotConfirmPassword'].forEach(id => {
            const el = document.getElementById(id); if(el) el.value = '';
        });
        forgotUserEmail = '';
        switchAuthTab('login');
    } else {
        errorEl.innerText = res.message || 'Failed to update password.';
        errorEl.style.display = 'block';
    }
}



