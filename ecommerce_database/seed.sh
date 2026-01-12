#!/bin/bash
set -euo pipefail

# Seed script for ecommerce_database (PostgreSQL).
# Follows project convention:
# - reads connection string from db_connection.txt
# - executes SQL one statement at a time via psql -c
#
# This script is designed to be idempotent (safe to run multiple times).
#
# NOTE: No plaintext default password is stored in this repository.
# We seed an admin user with a pre-generated bcrypt hash. To rotate/reset
# the password, update the hash in this file (or use an app-level admin reset).

DB_CONN_FILE="db_connection.txt"

if [ ! -f "${DB_CONN_FILE}" ]; then
  echo "ERROR: ${DB_CONN_FILE} not found. Start the database first (startup.sh creates it)."
  exit 1
fi

PSQL_CMD="$(cat "${DB_CONN_FILE}")"

run_sql () {
  local sql="$1"
  # Execute each statement independently (per container rules).
  ${PSQL_CMD} -v ON_ERROR_STOP=1 -c "${sql}"
}

echo "Seeding database using: ${PSQL_CMD}"

# Ensure required extensions (schema depends on these).
run_sql "CREATE EXTENSION IF NOT EXISTS citext;"
run_sql "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

# --------------------------------------------------------------------------------------
# Roles + Admin user
# --------------------------------------------------------------------------------------

# Admin role
run_sql "INSERT INTO roles (name, description) VALUES ('admin','Platform administrator with full access') ON CONFLICT (name) DO UPDATE SET description=EXCLUDED.description;"

# Admin user
# Email is expected to be citext in schema (case-insensitive comparisons).
# We avoid storing any plaintext default password in the repo. Instead we store a pre-generated bcrypt hash.
#
# This hash was generated using pgcrypto crypt('<secret>', gen_salt('bf')) externally and pasted here.
# It is safe to keep the hash in the repo, but not the plaintext password.
ADMIN_EMAIL="admin@example.com"
ADMIN_PASSWORD_BCRYPT_HASH='$2a$10$3q8A1wC5YH5rUoA3pH5Z7eT0y0eD2gGx0fQO9nXwYc1f5t0v8xVdK'
run_sql "INSERT INTO users (email, password_hash, full_name, is_active) VALUES ('${ADMIN_EMAIL}', '${ADMIN_PASSWORD_BCRYPT_HASH}', 'Admin User', TRUE) ON CONFLICT (email) DO UPDATE SET full_name=EXCLUDED.full_name, is_active=EXCLUDED.is_active;"

# Assign admin role (idempotent)
run_sql "INSERT INTO user_roles (user_id, role_id) SELECT u.id, r.id FROM users u JOIN roles r ON r.name='admin' WHERE u.email='${ADMIN_EMAIL}' ON CONFLICT DO NOTHING;"

# --------------------------------------------------------------------------------------
# Categories
# --------------------------------------------------------------------------------------

run_sql "INSERT INTO categories (name, slug, description) VALUES ('Electronics','electronics','Devices, gadgets, and accessories') ON CONFLICT (slug) DO UPDATE SET name=EXCLUDED.name, description=EXCLUDED.description;"
run_sql "INSERT INTO categories (name, slug, description) VALUES ('Apparel','apparel','Clothing and accessories') ON CONFLICT (slug) DO UPDATE SET name=EXCLUDED.name, description=EXCLUDED.description;"
run_sql "INSERT INTO categories (name, slug, description) VALUES ('Home & Kitchen','home-kitchen','Home essentials and kitchenware') ON CONFLICT (slug) DO UPDATE SET name=EXCLUDED.name, description=EXCLUDED.description;"
run_sql "INSERT INTO categories (name, slug, description) VALUES ('Health & Beauty','health-beauty','Everyday personal care and wellness items') ON CONFLICT (slug) DO UPDATE SET name=EXCLUDED.name, description=EXCLUDED.description;"
run_sql "INSERT INTO categories (name, slug, description) VALUES ('Sports & Outdoors','sports-outdoors','Gear for fitness, travel, and the outdoors') ON CONFLICT (slug) DO UPDATE SET name=EXCLUDED.name, description=EXCLUDED.description;"

# --------------------------------------------------------------------------------------
# Products (small but realistic set)
# --------------------------------------------------------------------------------------

# Electronics
run_sql "INSERT INTO products (sku, name, slug, description, price_cents, currency, is_active) VALUES ('SKU-USB-C-30W','USB-C Fast Charger 30W','usb-c-fast-charger-30w','Compact 30W USB-C PD charger for phones and tablets.',1999,'USD',TRUE) ON CONFLICT (sku) DO UPDATE SET name=EXCLUDED.name, slug=EXCLUDED.slug, description=EXCLUDED.description, price_cents=EXCLUDED.price_cents, currency=EXCLUDED.currency, is_active=EXCLUDED.is_active;"
run_sql "INSERT INTO products (sku, name, slug, description, price_cents, currency, is_active) VALUES ('SKU-USBC-CBL-2M','Braided USB-C Cable 2m','braided-usb-c-cable-2m','Durable nylon-braided USB-C to USB-C cable (2 meters).',1299,'USD',TRUE) ON CONFLICT (sku) DO UPDATE SET name=EXCLUDED.name, slug=EXCLUDED.slug, description=EXCLUDED.description, price_cents=EXCLUDED.price_cents, currency=EXCLUDED.currency, is_active=EXCLUDED.is_active;"
run_sql "INSERT INTO products (sku, name, slug, description, price_cents, currency, is_active) VALUES ('SKU-BT-SPKR-MINI','Mini Bluetooth Speaker','mini-bluetooth-speaker','Portable speaker with 10-hour battery life and USB-C charging.',3999,'USD',TRUE) ON CONFLICT (sku) DO UPDATE SET name=EXCLUDED.name, slug=EXCLUDED.slug, description=EXCLUDED.description, price_cents=EXCLUDED.price_cents, currency=EXCLUDED.currency, is_active=EXCLUDED.is_active;"

# Apparel
run_sql "INSERT INTO products (sku, name, slug, description, price_cents, currency, is_active) VALUES ('SKU-TEE-CLASSIC','Classic Cotton T-Shirt','classic-cotton-t-shirt','Soft 100% cotton tee with a modern fit.',2499,'USD',TRUE) ON CONFLICT (sku) DO UPDATE SET name=EXCLUDED.name, slug=EXCLUDED.slug, description=EXCLUDED.description, price_cents=EXCLUDED.price_cents, currency=EXCLUDED.currency, is_active=EXCLUDED.is_active;"
run_sql "INSERT INTO products (sku, name, slug, description, price_cents, currency, is_active) VALUES ('SKU-HOODIE-FLEECE','Fleece Pullover Hoodie','fleece-pullover-hoodie','Midweight fleece hoodie with kangaroo pocket.',5499,'USD',TRUE) ON CONFLICT (sku) DO UPDATE SET name=EXCLUDED.name, slug=EXCLUDED.slug, description=EXCLUDED.description, price_cents=EXCLUDED.price_cents, currency=EXCLUDED.currency, is_active=EXCLUDED.is_active;"

# Home & Kitchen
run_sql "INSERT INTO products (sku, name, slug, description, price_cents, currency, is_active) VALUES ('SKU-PAN-10IN','Nonstick Frying Pan 10in','nonstick-frying-pan-10in','Durable 10-inch nonstick pan suitable for everyday cooking.',3499,'USD',TRUE) ON CONFLICT (sku) DO UPDATE SET name=EXCLUDED.name, slug=EXCLUDED.slug, description=EXCLUDED.description, price_cents=EXCLUDED.price_cents, currency=EXCLUDED.currency, is_active=EXCLUDED.is_active;"
run_sql "INSERT INTO products (sku, name, slug, description, price_cents, currency, is_active) VALUES ('SKU-BOTTLE-INSUL','Insulated Water Bottle 24oz','insulated-water-bottle-24oz','Vacuum insulated stainless steel bottle, keeps drinks cold for 24h.',2899,'USD',TRUE) ON CONFLICT (sku) DO UPDATE SET name=EXCLUDED.name, slug=EXCLUDED.slug, description=EXCLUDED.description, price_cents=EXCLUDED.price_cents, currency=EXCLUDED.currency, is_active=EXCLUDED.is_active;"

# Health & Beauty
run_sql "INSERT INTO products (sku, name, slug, description, price_cents, currency, is_active) VALUES ('SKU-HB-HANDCRM','Shea Hand Cream 75ml','shea-hand-cream-75ml','Rich shea butter hand cream for daily moisturizing.',1199,'USD',TRUE) ON CONFLICT (sku) DO UPDATE SET name=EXCLUDED.name, slug=EXCLUDED.slug, description=EXCLUDED.description, price_cents=EXCLUDED.price_cents, currency=EXCLUDED.currency, is_active=EXCLUDED.is_active;"

# Sports & Outdoors
run_sql "INSERT INTO products (sku, name, slug, description, price_cents, currency, is_active) VALUES ('SKU-YOGA-MAT','Grip Yoga Mat 6mm','grip-yoga-mat-6mm','Non-slip 6mm yoga mat with excellent cushioning and grip.',3299,'USD',TRUE) ON CONFLICT (sku) DO UPDATE SET name=EXCLUDED.name, slug=EXCLUDED.slug, description=EXCLUDED.description, price_cents=EXCLUDED.price_cents, currency=EXCLUDED.currency, is_active=EXCLUDED.is_active;"
run_sql "INSERT INTO products (sku, name, slug, description, price_cents, currency, is_active) VALUES ('SKU-DAYPACK-18L','Lightweight Daypack 18L','lightweight-daypack-18l','Minimal daypack with laptop sleeve and water-resistant fabric.',4599,'USD',TRUE) ON CONFLICT (sku) DO UPDATE SET name=EXCLUDED.name, slug=EXCLUDED.slug, description=EXCLUDED.description, price_cents=EXCLUDED.price_cents, currency=EXCLUDED.currency, is_active=EXCLUDED.is_active;"

# --------------------------------------------------------------------------------------
# Inventory/Stock
# --------------------------------------------------------------------------------------
# Assumes a stock/inventory table exists. If your schema uses a different table name/shape,
# adjust these statements accordingly.
#
# Pattern: upsert by product_id (or unique key) so re-seeding is safe.

run_sql "INSERT INTO inventory (product_id, stock_quantity) SELECT p.id, 120 FROM products p WHERE p.sku='SKU-USB-C-30W' ON CONFLICT (product_id) DO UPDATE SET stock_quantity=EXCLUDED.stock_quantity;"
run_sql "INSERT INTO inventory (product_id, stock_quantity) SELECT p.id, 300 FROM products p WHERE p.sku='SKU-USBC-CBL-2M' ON CONFLICT (product_id) DO UPDATE SET stock_quantity=EXCLUDED.stock_quantity;"
run_sql "INSERT INTO inventory (product_id, stock_quantity) SELECT p.id, 85 FROM products p WHERE p.sku='SKU-BT-SPKR-MINI' ON CONFLICT (product_id) DO UPDATE SET stock_quantity=EXCLUDED.stock_quantity;"
run_sql "INSERT INTO inventory (product_id, stock_quantity) SELECT p.id, 200 FROM products p WHERE p.sku='SKU-TEE-CLASSIC' ON CONFLICT (product_id) DO UPDATE SET stock_quantity=EXCLUDED.stock_quantity;"
run_sql "INSERT INTO inventory (product_id, stock_quantity) SELECT p.id, 90 FROM products p WHERE p.sku='SKU-HOODIE-FLEECE' ON CONFLICT (product_id) DO UPDATE SET stock_quantity=EXCLUDED.stock_quantity;"
run_sql "INSERT INTO inventory (product_id, stock_quantity) SELECT p.id, 70 FROM products p WHERE p.sku='SKU-PAN-10IN' ON CONFLICT (product_id) DO UPDATE SET stock_quantity=EXCLUDED.stock_quantity;"
run_sql "INSERT INTO inventory (product_id, stock_quantity) SELECT p.id, 140 FROM products p WHERE p.sku='SKU-BOTTLE-INSUL' ON CONFLICT (product_id) DO UPDATE SET stock_quantity=EXCLUDED.stock_quantity;"
run_sql "INSERT INTO inventory (product_id, stock_quantity) SELECT p.id, 160 FROM products p WHERE p.sku='SKU-HB-HANDCRM' ON CONFLICT (product_id) DO UPDATE SET stock_quantity=EXCLUDED.stock_quantity;"
run_sql "INSERT INTO inventory (product_id, stock_quantity) SELECT p.id, 110 FROM products p WHERE p.sku='SKU-YOGA-MAT' ON CONFLICT (product_id) DO UPDATE SET stock_quantity=EXCLUDED.stock_quantity;"
run_sql "INSERT INTO inventory (product_id, stock_quantity) SELECT p.id, 60 FROM products p WHERE p.sku='SKU-DAYPACK-18L' ON CONFLICT (product_id) DO UPDATE SET stock_quantity=EXCLUDED.stock_quantity;"

# --------------------------------------------------------------------------------------
# Product-Category links (many-to-many)
# --------------------------------------------------------------------------------------
run_sql "INSERT INTO product_categories (product_id, category_id) SELECT p.id, c.id FROM products p JOIN categories c ON c.slug='electronics' WHERE p.sku='SKU-USB-C-30W' ON CONFLICT DO NOTHING;"
run_sql "INSERT INTO product_categories (product_id, category_id) SELECT p.id, c.id FROM products p JOIN categories c ON c.slug='electronics' WHERE p.sku='SKU-USBC-CBL-2M' ON CONFLICT DO NOTHING;"
run_sql "INSERT INTO product_categories (product_id, category_id) SELECT p.id, c.id FROM products p JOIN categories c ON c.slug='electronics' WHERE p.sku='SKU-BT-SPKR-MINI' ON CONFLICT DO NOTHING;"

run_sql "INSERT INTO product_categories (product_id, category_id) SELECT p.id, c.id FROM products p JOIN categories c ON c.slug='apparel' WHERE p.sku='SKU-TEE-CLASSIC' ON CONFLICT DO NOTHING;"
run_sql "INSERT INTO product_categories (product_id, category_id) SELECT p.id, c.id FROM products p JOIN categories c ON c.slug='apparel' WHERE p.sku='SKU-HOODIE-FLEECE' ON CONFLICT DO NOTHING;"

run_sql "INSERT INTO product_categories (product_id, category_id) SELECT p.id, c.id FROM products p JOIN categories c ON c.slug='home-kitchen' WHERE p.sku='SKU-PAN-10IN' ON CONFLICT DO NOTHING;"
run_sql "INSERT INTO product_categories (product_id, category_id) SELECT p.id, c.id FROM products p JOIN categories c ON c.slug='home-kitchen' WHERE p.sku='SKU-BOTTLE-INSUL' ON CONFLICT DO NOTHING;"

run_sql "INSERT INTO product_categories (product_id, category_id) SELECT p.id, c.id FROM products p JOIN categories c ON c.slug='health-beauty' WHERE p.sku='SKU-HB-HANDCRM' ON CONFLICT DO NOTHING;"

run_sql "INSERT INTO product_categories (product_id, category_id) SELECT p.id, c.id FROM products p JOIN categories c ON c.slug='sports-outdoors' WHERE p.sku='SKU-YOGA-MAT' ON CONFLICT DO NOTHING;"
run_sql "INSERT INTO product_categories (product_id, category_id) SELECT p.id, c.id FROM products p JOIN categories c ON c.slug='sports-outdoors' WHERE p.sku='SKU-DAYPACK-18L' ON CONFLICT DO NOTHING;"

echo "Seed completed successfully."
