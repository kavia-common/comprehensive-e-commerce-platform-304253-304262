# Database schema notes (ecommerce_database)

This container uses PostgreSQL and is initialized via `startup.sh` and seeded via `seed.sh` (idempotent).

## Seeded bootstrap data

### Admin user (seeded)
- Email: `admin@example.com`
- Password: **not stored in plaintext in this repository**.
  - `seed.sh` inserts the admin with a pre-generated bcrypt hash in `users.password_hash`.
  - To change/reset the admin password, update the hash in `seed.sh` (or use an application-level password reset flow when available).

### Catalog data (seeded)
- Several categories (electronics, apparel, home-kitchen, health-beauty, sports-outdoors)
- A small realistic set of products linked to categories
- Inventory/stock quantities are seeded via UPSERT for safe re-runs
