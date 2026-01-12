#!/bin/bash
set -euo pipefail

# Seed script for ecommerce_database (PostgreSQL).
# Follows project convention:
# - reads connection string from db_connection.txt
# - executes SQL one statement at a time via psql -c
#
# This script is designed to be idempotent (safe to run multiple times).

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

# Admin role
run_sql "INSERT INTO roles (name, description) VALUES ('admin','Platform administrator with full access') ON CONFLICT (name) DO NOTHING;"

# Admin user (default credentials for bootstrap/dev; change in production)
# Email: admin@example.com
# Password: Admin123!
# Uses pgcrypto crypt() with bcrypt salts.
run_sql "INSERT INTO users (email, password_hash, full_name, is_active) VALUES ('admin@example.com', crypt('Admin123!', gen_salt('bf')), 'Admin User', TRUE) ON CONFLICT (email) DO NOTHING;"

# Assign admin role
run_sql "INSERT INTO user_roles (user_id, role_id) SELECT u.id, r.id FROM users u JOIN roles r ON r.name='admin' WHERE u.email='admin@example.com' ON CONFLICT DO NOTHING;"

# Categories
run_sql "INSERT INTO categories (name, slug, description) VALUES ('Electronics','electronics','Devices, gadgets, and accessories') ON CONFLICT (slug) DO NOTHING;"
run_sql "INSERT INTO categories (name, slug, description) VALUES ('Apparel','apparel','Clothing and accessories') ON CONFLICT (slug) DO NOTHING;"
run_sql "INSERT INTO categories (name, slug, description) VALUES ('Home & Kitchen','home-kitchen','Home essentials and kitchenware') ON CONFLICT (slug) DO NOTHING;"

# Products
run_sql "INSERT INTO products (sku, name, slug, description, price_cents, currency, is_active) VALUES ('SKU-USB-C-01','USB-C Fast Charger 30W','usb-c-fast-charger-30w','Compact 30W USB-C PD charger for phones and tablets.',1999,'USD',TRUE) ON CONFLICT (sku) DO NOTHING;"
run_sql "INSERT INTO products (sku, name, slug, description, price_cents, currency, is_active) VALUES ('SKU-TEE-01','Classic Cotton T-Shirt','classic-cotton-tshirt','Soft 100% cotton tee with a modern fit.',2499,'USD',TRUE) ON CONFLICT (sku) DO NOTHING;"
run_sql "INSERT INTO products (sku, name, slug, description, price_cents, currency, is_active) VALUES ('SKU-PAN-01','Nonstick Frying Pan 10in','nonstick-frying-pan-10in','Durable 10-inch nonstick pan suitable for everyday cooking.',3499,'USD',TRUE) ON CONFLICT (sku) DO NOTHING;"

# Product-Category links
run_sql "INSERT INTO product_categories (product_id, category_id) SELECT p.id, c.id FROM products p JOIN categories c ON c.slug='electronics' WHERE p.sku='SKU-USB-C-01' ON CONFLICT DO NOTHING;"
run_sql "INSERT INTO product_categories (product_id, category_id) SELECT p.id, c.id FROM products p JOIN categories c ON c.slug='apparel' WHERE p.sku='SKU-TEE-01' ON CONFLICT DO NOTHING;"
run_sql "INSERT INTO product_categories (product_id, category_id) SELECT p.id, c.id FROM products p JOIN categories c ON c.slug='home-kitchen' WHERE p.sku='SKU-PAN-01' ON CONFLICT DO NOTHING;"

echo "Seed completed successfully."
