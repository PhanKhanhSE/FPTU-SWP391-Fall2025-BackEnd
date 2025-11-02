# API Gói Thanh Toán - Payment Plans

## 📌 Tổng quan

Hệ thống hỗ trợ 3 loại gói đăng tin sản phẩm:
- **FREE**: Miễn phí, hiển thị 7 ngày
- **BASIC**: 100,000 VNĐ ($4), ưu tiên hiển thị, 30 ngày
- **PREMIUM**: 300,000 VNĐ ($12), ưu tiên cao + nổi bật + đẩy tin, 90 ngày

---

## 🔗 API Endpoints

### 1. Lấy danh sách các gói thanh toán

**Endpoint:** `GET /api/payments/packages`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Gói Free",
      "type": "FREE",
      "price": 0,
      "price_usd": 0,
      "duration_days": 7,
      "features": {
        "priority": false,
        "highlight": false,
        "boost": false,
        "description": "Đăng tin miễn phí, hiển thị 7 ngày"
      }
    },
    {
      "id": 2,
      "name": "Gói Basic",
      "type": "BASIC",
      "price": 100000,
      "price_usd": 4,
      "duration_days": 30,
      "features": {
        "priority": true,
        "highlight": false,
        "boost": false,
        "description": "Ưu tiên hiển thị, hiển thị 30 ngày"
      }
    },
    {
      "id": 3,
      "name": "Gói Premium",
      "type": "PREMIUM",
      "price": 300000,
      "price_usd": 12,
      "duration_days": 90,
      "features": {
        "priority": true,
        "highlight": true,
        "boost": true,
        "description": "Ưu tiên cao, nổi bật, đẩy tin, hiển thị 90 ngày"
      }
    }
  ]
}
```

---

### 2. Tạo sản phẩm với gói thanh toán

**Endpoint:** `POST /api/products`

**Request Body:**
```json
{
  "title": "Xe máy điện VinFast",
  "category_id": 2,
  "price": 12000000,
  "product_type": "ELECTRIC_BIKE",
  "description": "Xe còn mới 95%",
  "location": "Hà Nội",
  
  // Thông tin gói thanh toán
  "plan_type": "FREE",           // "FREE", "BASIC", hoặc "PREMIUM"
  "plan_price": 0,               // Giá gói (0 cho FREE)
  "plan_duration_days": 7,       // Số ngày hiển thị
  "plan_features": {             // Các tính năng
    "priority": false,
    "highlight": false,
    "boost": false
  }
}
```

**Response:**
```json
{
  "id": 123,
  "title": "Xe máy điện VinFast",
  "is_paid": true,               // true nếu FREE, false nếu BASIC/PREMIUM
  "plan_type": "FREE",
  "plan_price": 0,
  "plan_duration_days": 7,
  "plan_features": { ... },
  "status": "PENDING",
  ...
}
```

---

### 3. Lấy danh sách tất cả sản phẩm (kèm thông tin gói)

**Endpoint:** `GET /api/products`

**Response:**
```json
[
  {
    "id": 1,
    "title": "Xe máy điện",
    "price": 12000000,
    "is_paid": true,
    "plan_type": "PREMIUM",
    "plan_price": 300000,
    "plan_duration_days": 90,
    "plan_features": {
      "priority": true,
      "highlight": true,
      "boost": true,
      "description": "Ưu tiên cao, nổi bật, đẩy tin, hiển thị 90 ngày"
    },
    "status": "APPROVED",
    "created_at": "2025-11-01T10:00:00.000Z",
    "media": [...],
    "category": {...},
    "member": {...}
  },
  ...
]
```

---

### 4. Các endpoint khác có thông tin gói

Tất cả các endpoint sau cũng trả về thông tin gói thanh toán:

- `GET /api/products/category/:cateId` - Sản phẩm theo category
- `GET /api/products/search?name=...` - Tìm kiếm sản phẩm
- `GET /api/products/:id` - Chi tiết sản phẩm
- `GET /api/products/my` - Sản phẩm của user hiện tại
- `PUT /api/products/:id` - Cập nhật sản phẩm
- `PUT /api/products/:id/status` - Cập nhật trạng thái
- `PUT /api/products/:id/moderate` - Duyệt bài (Admin)

---

## 🎯 Luồng thanh toán

### Luồng 1: Gói FREE
```
1. User tạo product với plan_type = "FREE"
2. Hệ thống tự động set is_paid = true
3. Product được tạo và hiển thị ngay (sau khi admin duyệt)
```

### Luồng 2: Gói BASIC/PREMIUM
```
1. User tạo product với plan_type = "BASIC" hoặc "PREMIUM"
2. Hệ thống set is_paid = false
3. User cần thanh toán:
   - POST /api/payments/create với productId
   - Thanh toán qua PayPal
   - Callback /api/payments/success tự động set is_paid = true
4. Product được hiển thị (sau khi admin duyệt)
```

---

## 📊 Database Schema

### Bảng `products` - Các cột mới:

| Column | Type | Description |
|--------|------|-------------|
| `plan_type` | ENUM('FREE', 'BASIC', 'PREMIUM') | Loại gói đã chọn |
| `plan_price` | DECIMAL(15, 2) | Giá gói (VNĐ hoặc USD) |
| `plan_duration_days` | INT | Số ngày hiển thị tin |
| `plan_features` | JSON | Các tính năng của gói |

---

## 🔧 Migration

Chạy migration để thêm các cột mới:

```bash
mysql -u root -p your_database < migrations/add_plan_fields_to_products.sql
```

Hoặc trong MySQL:
```sql
source migrations/add_plan_fields_to_products.sql;
```

---

## 💡 Frontend Integration

### 1. Hiển thị danh sách gói khi tạo sản phẩm

```javascript
// Lấy danh sách gói
const response = await fetch('/api/payments/packages');
const { data: packages } = await response.json();

// Hiển thị gói cho user chọn
packages.forEach(pkg => {
  console.log(`${pkg.name} - ${pkg.price} VNĐ - ${pkg.duration_days} ngày`);
});
```

### 2. Tạo sản phẩm với gói đã chọn

```javascript
const selectedPackage = packages.find(p => p.type === 'BASIC');

const productData = {
  title: "Xe máy điện",
  price: 12000000,
  plan_type: selectedPackage.type,
  plan_price: selectedPackage.price,
  plan_duration_days: selectedPackage.duration_days,
  plan_features: selectedPackage.features,
  // ... các field khác
};

const response = await fetch('/api/products', {
  method: 'POST',
  headers: { 
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify(productData)
});
```

### 3. Hiển thị thông tin gói trong danh sách sản phẩm

```javascript
const response = await fetch('/api/products');
const products = await response.json();

products.forEach(product => {
  console.log(`
    Sản phẩm: ${product.title}
    Gói: ${product.plan_type}
    Giá gói: ${product.plan_price} VNĐ
    Thời hạn: ${product.plan_duration_days} ngày
    Đã thanh toán: ${product.is_paid ? 'Có' : 'Chưa'}
  `);
  
  // Hiển thị badge dựa trên gói
  if (product.plan_type === 'PREMIUM') {
    // Hiển thị badge "PREMIUM" với màu vàng
  } else if (product.plan_type === 'BASIC') {
    // Hiển thị badge "BASIC" với màu xanh
  }
  
  // Sắp xếp ưu tiên nếu có feature priority
  if (product.plan_features?.priority) {
    // Đưa sản phẩm lên đầu danh sách
  }
});
```

---

## 🎨 UI/UX Recommendations

1. **Badge hiển thị gói:**
   - FREE: Không badge hoặc badge xám
   - BASIC: Badge xanh dương
   - PREMIUM: Badge vàng/gold với icon ⭐

2. **Sắp xếp sản phẩm:**
   - PREMIUM: Luôn hiển thị đầu tiên
   - BASIC: Hiển thị ưu tiên sau PREMIUM
   - FREE: Hiển thị sau cùng

3. **Highlight:**
   - PREMIUM: Viền vàng, background nhạt, có icon nổi bật
   - BASIC: Viền xanh nhạt
   - FREE: Không highlight

---

## 📝 Notes

- Gói FREE không cần thanh toán, `is_paid` được set `true` ngay khi tạo
- Gói BASIC/PREMIUM cần thanh toán qua PayPal
- Admin có thể thay đổi gói của sản phẩm bất kỳ (nếu cần thêm endpoint)
- Có thể thêm logic hết hạn dựa trên `created_at` + `plan_duration_days`

---

## 🚀 Future Enhancements

1. **Auto-expire products:** Tự động ẩn sản phẩm khi hết thời hạn
2. **Renewal:** Cho phép gia hạn gói
3. **Upgrade/Downgrade:** Chuyển đổi gói trong khi sản phẩm đang hiển thị
4. **Analytics:** Thống kê hiệu quả của từng gói
5. **Discount codes:** Mã giảm giá cho các gói
