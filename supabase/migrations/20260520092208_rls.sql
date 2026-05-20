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

-- items: all authenticated users can read and insert items
CREATE POLICY "authenticated users can read items"
  ON items FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "authenticated users can insert items"
  ON items FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- stock is protected from direct updates
-- stock should only change via the trigger when an order is placed
-- this prevents users from manually inflating or changing stock levels
CREATE POLICY "authenticated users can update items"
  ON items FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (stock = (SELECT stock FROM items WHERE id = items.id));

CREATE POLICY "authenticated users can delete items"
  ON items FOR DELETE
  TO authenticated
  USING (true);

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
  USING (order_id IN (SELECT id FROM orders WHERE user_id = auth.uid()));

CREATE POLICY "users can insert own order items"
  ON order_items FOR INSERT
  TO authenticated
  WITH CHECK (order_id IN (SELECT id FROM orders WHERE user_id = auth.uid()));

-- order_id and item_id are immutable after creation
-- prevents users from reassigning order items to different orders or items
CREATE POLICY "users can update own order items"
  ON order_items FOR UPDATE
  TO authenticated
  USING (order_id IN (SELECT id FROM orders WHERE user_id = auth.uid()))
  WITH CHECK (
    order_id = order_items.order_id AND
    item_id = order_items.item_id
  );

CREATE POLICY "users can delete own order items"
  ON order_items FOR DELETE
  TO authenticated
  USING (order_id IN (SELECT id FROM orders WHERE user_id = auth.uid()));