-- Migration: Add plan fields to products table
-- Date: 2025-11-03

-- Thêm các cột mới cho thông tin gói thanh toán
ALTER TABLE products
ADD COLUMN plan_type ENUM('FREE', 'BASIC', 'PREMIUM') DEFAULT 'FREE' COMMENT 'Loại gói đăng tin',
ADD COLUMN plan_price DECIMAL(15, 2) DEFAULT 0 COMMENT 'Giá gói đã chọn',
ADD COLUMN plan_duration_days INT DEFAULT NULL COMMENT 'Số ngày hiển thị tin đăng',
ADD COLUMN plan_features JSON DEFAULT NULL COMMENT 'Các tính năng của gói';

-- Cập nhật dữ liệu cũ: tất cả sản phẩm hiện có đặt là FREE
UPDATE products 
SET plan_type = 'FREE', 
    plan_price = 0,
    plan_duration_days = 7
WHERE plan_type IS NULL;

-- Index để tăng hiệu suất query theo plan_type
CREATE INDEX idx_products_plan_type ON products(plan_type);
CREATE INDEX idx_products_is_paid ON products(is_paid);
