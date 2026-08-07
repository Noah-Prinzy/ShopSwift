-- A small electronics catalog makes the prototype useful immediately after migration.
-- UUIDs are fixed so frontend/API testing is repeatable.
--
-- Short notes:
-- - Keep seed data deterministic for end-to-end tests and frontend demo fixtures.
INSERT INTO products (id, name, description, price, category, image_url, stock) VALUES
('10000000-0000-0000-0000-000000000001', 'Nova X1 Smartphone', '6.5-inch OLED smartphone with 128 GB storage and all-day battery life.', 699.00, 'Phones', 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=900&q=80', 18),
('10000000-0000-0000-0000-000000000002', 'AirBeat Wireless Headphones', 'Over-ear wireless headphones with active noise cancellation.', 149.00, 'Audio', 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=900&q=80', 35),
('10000000-0000-0000-0000-000000000003', 'SwiftBook 14', 'Lightweight 14-inch laptop designed for study, coding, and everyday work.', 1099.00, 'Computers', 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&w=900&q=80', 12),
('10000000-0000-0000-0000-000000000004', 'Pulse Smartwatch', 'Fitness-focused smartwatch with notifications, heart-rate tracking, and GPS.', 229.00, 'Wearables', 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=900&q=80', 24),
('10000000-0000-0000-0000-000000000005', 'TypePro Mechanical Keyboard', 'Compact mechanical keyboard with hot-swappable switches and USB-C.', 89.00, 'Accessories', 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=900&q=80', 42),
('10000000-0000-0000-0000-000000000006', 'PocketCharge 20K', '20,000 mAh USB-C power bank with fast charging for phones and tablets.', 59.00, 'Accessories', 'https://images.unsplash.com/photo-1609592424824-0f8f69b7c0e1?auto=format&fit=crop&w=900&q=80', 50);
