ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE items_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- profiles: users can only CRUD their own profile
CREATE POLICY "users can crud own profile"
  ON profiles
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- items
CREATE POLICY "authenticated users can crud items"
  ON items
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- items_history: read only for authenticated users
-- write access is handled exclusively by the trigger
-- users should never be able to tamper with the log directly
CREATE POLICY "authenticated users can view items history"
  ON items_history FOR SELECT
  TO authenticated
  USING (true);

-- orders: users can only CR their own orders
-- user_id is locked to auth.uid() on both read and write
-- prevents users from seeing or creating orders for other users
CREATE POLICY "users can select own orders"
  ON orders FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "users can insert own orders"
  ON orders FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- order_items: users can only access order items belonging to their own orders
CREATE POLICY "users can view own order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders
        WHERE id = order_items.order_id
        AND user_id = auth.uid()
    )
  );

CREATE POLICY "users can insert own order items"
  ON order_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE id = order_items.order_id
      AND user_id = auth.uid()
    )
  );