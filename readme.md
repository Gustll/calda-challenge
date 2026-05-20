# Calda Challenge — Supabase E-Commerce

A Supabase backend for a simple e-commerce application built as part of the Calda development challenge.

## Features

- User profiles linked to Supabase Auth
- Item catalogue with name, price and stock management
- Orders with multiple order items, shipping address and recipient name
- Automatic stock decrement on order creation
- Automatic change tracking on items catalogue via triggers
- Row Level Security on all tables
- Order aggregation view
- Edge function for order creation
- CRON job for archiving orders older than 1 week

---

## Database Schema

[View DB Diagram](https://dbdiagram.io/d/6a0d5dbd697f99c167bca094)

### Tables
- `profiles` — user metadata linked to auth.users
- `items` — product catalogue
- `items_history` — audit log for item changes (trigger driven)
- `orders` — order metadata
- `order_items` — junction table linking orders to items
- `archived_orders` — stores totals of archived orders

---

## Local Setup

### Requirements
- Docker
- Supabase CLI

### Steps

```bash
# clone the repo
git clone https://github.com/gustll/calda-challenge
cd calda-challenge

# start supabase (runs migrations + seed automatically)
supabase start
```

Studio will be available at `http://localhost:54333`

---

## Seed Data

The challenge did not specify a user registration flow so test users are created via `seed.sql` which runs automatically on `supabase start`.

Seed also includes 5 items, 3 orders with at least 2 order items each and 1 old order for CRON job testing.

---

## API

### 1. Login
```bash
curl -X POST 'http://localhost:54331/auth/v1/token?grant_type=password' \
  -H "apikey: <YOUR_ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "d4rk.spark99+1@gmail.com",
    "password": "password123"
  }'
```
Copy the `access_token` from the response.

### 2. Create Order
```bash
curl -X POST 'http://localhost:54331/functions/v1/create-order' \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "shipping_address": "Podutiska cesta 140, Ljubljana",
    "recipient_name": "Janez Novak",
    "items": [
      { "item_id": "<ITEM_UUID>", "quantity": 2 },
      { "item_id": "<ITEM_UUID>", "quantity": 1 }
    ]
  }'
```
Get item UUIDs from Studio -> Table Editor -> items.

---

## CRON Job

The CRON job runs daily at midnight and:
1. Stores the sum of order totals older than 1 week into `archived_orders`
2. Deletes those orders

### Testing the CRON job
Go to **Studio -> Integrations -> CRON Jobs -> archive-old-orders** and trigger it manually.

---

## Future Improvements

- User registration endpoint
- Order status management (pending, confirmed, cancelled, delivered)
- Audit log table for all API activity
- Admin role with elevated permissions
- Stock protection via RLS (prevent direct stock manipulation)