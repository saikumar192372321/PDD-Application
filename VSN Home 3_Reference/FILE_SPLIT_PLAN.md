# User Folder - File Split Plan

The original `CartView.swift` (1421 lines) has been split into the following modular files:

## Created Files:

### 1. **GroceryAppView.swift** ✅
- Main app structure with tab navigation
- Handles user vs admin view switching
- Contains mock order data

### 2. **HomeView.swift** (To Create)
- Product browsing interface
- Search and category filtering
- Product grid display
- Lines: ~110

### 3. **ProductCard.swift** (To Create)
- Individual product card component
- Add to cart button
- Price display
- Lines: ~65

### 4. **ProductDetailsView.swift** (To Create)
- Detailed product view
- Full product information
- Add to cart action
- Lines: ~110

### 5. **CartView.swift** (To Replace)
- Shopping cart management
- Delivery address
- Bulk offers
- Checkout logic
- Lines: ~370

### 6. **OffersView.swift** (To Create)
- Bulk deal offers display
- Offer cards
- Lines: ~60

### 7. **ProfileView.swift** (To Create)
- User profile
- Order history
- Address management
- Logout
- Lines: ~200

### 8. **OrderTrackingView.swift** (To Create)
- Order status tracking
- Timeline view
- Delivery estimates
- Lines: ~150

## Shared Files (Already Created):
- **Models.swift** ✅ - All data structures
- **ProductStore.swift** ✅ - Product inventory management

## Total Breakdown:
- Original: 1 file (1421 lines)
- New Structure: 8+ modular files (~150-200 lines each)
