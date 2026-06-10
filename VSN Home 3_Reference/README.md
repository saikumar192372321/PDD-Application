# VSN Home - Project Structure

## 📁 Folder Organization

### **Admin/** 
Admin-side functionality and views (modular structure)
- `AdminLoginView.swift` - Admin authentication screen
- `AdminTabView.swift` - Main admin navigation with tabs
- `AdminDashboardView.swift` - Business insights, P&L analytics, charts
- `AdminOrdersView.swift` - Order list management
- `AdminOrderDetailView.swift` - Order details with delivery date control
- `ProductListView.swift` - Product inventory management
- `AddProductView.swift` - Add new products form

### **User/**
User-side functionality and views (modular structure)
- `GroceryAppView.swift` - Main user app container with tab navigation
- `HomeView.swift` - Product catalog and filtering
- `ProductCard.swift` - Product grid item component
- `ProductDetailsView.swift` - Detailed product information
- `CartView.swift` - Shopping cart and checkout flow
- `OffersView.swift` - Bulk deals and promotions
- `ProfileView.swift` - Shop profile, addresses, and order history
- `OrderTrackingView.swift` - Real-time order status and timeline

### **Shared/**
Components and data managed by both Admin and User sides
- `Models.swift` - Unified data structures (Order, Product, etc.)
- `ProductStore.swift` - Centralized product inventory management
- `LoginView.swift` - Main login screen (handles both user and admin login)
- `SignUpView.swift` - User registration
- `ForgotPasswordView.swift` - Password recovery
- `SplashScreenView.swift` - App launch screen

### **Root Files**
- `VSN_HomeApp.swift` - App entry point
- `Assets.xcassets/` - Images and app assets

## 🔐 Admin Access
- **Username**: `sai@141`
- **Password**: `sai@141`

## 🎯 Key Features

### Admin Side:
- Business Dashboard with P&L analytics
- Product Management (Add/Edit/Delete)
- Order Management with delivery tracking
- Custom delivery date setting based on location

### User Side:
- Wholesale product browsing
- Bulk order cart
- Order tracking with delivery estimates
- Business profile management
- Loyalty coins system
