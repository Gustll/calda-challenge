-- generic function to auto update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- attach updated_at trigger to all relevant tables
CREATE TRIGGER set_updated_at_profiles
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_items
  BEFORE UPDATE ON items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_orders
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_order_items
  BEFORE UPDATE ON order_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- log all changes on items table to items_history
-- fires on INSERT, UPDATE and DELETE
-- on DELETE we log OLD (the row before deletion)
-- on INSERT/UPDATE we log NEW (the row after change)
CREATE OR REPLACE FUNCTION log_items_history()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    INSERT INTO items_history (item_id, operation, payload)
    VALUES (OLD.id, TG_OP, to_jsonb(OLD));
    RETURN OLD;
  ELSE
    INSERT INTO items_history (item_id, operation, payload)
    VALUES (NEW.id, TG_OP, to_jsonb(NEW));
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- attach to items table
-- AFTER so the history reflects the final committed state
CREATE TRIGGER log_items_changes
  AFTER INSERT OR UPDATE OR DELETE ON items
  FOR EACH ROW EXECUTE FUNCTION log_items_history();

-- decrement stock when an order item is inserted
-- checks stock is sufficient before decrementing
-- raises exception if insufficient stock
CREATE OR REPLACE FUNCTION decrement_stock()
RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT stock FROM items WHERE id = NEW.item_id) < NEW.quantity THEN
    RAISE EXCEPTION 'insufficient stock for item %', NEW.item_id;
  END IF;

  UPDATE items
  SET stock = stock - NEW.quantity
  WHERE id = NEW.item_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- attach to order_items
-- BEFORE so we can cancel the insert if stock is insufficient
CREATE TRIGGER check_and_decrement_stock
  BEFORE INSERT ON order_items
  FOR EACH ROW EXECUTE FUNCTION decrement_stock();

-- automatically create a profile when a new auth user signs up
CREATE OR REPLACE FUNCTION create_profile_on_signup()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.raw_user_meta_data->>'given_name' IS NULL OR 
     NEW.raw_user_meta_data->>'family_name' IS NULL THEN
    RAISE EXCEPTION 'name and surname are required';
  END IF;

  INSERT INTO profiles (id, name, surname)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'given_name',
    NEW.raw_user_meta_data->>'family_name'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- attach to auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_profile_on_signup();

CREATE OR REPLACE FUNCTION get_other_orders_total(current_order_id uuid)
RETURNS numeric AS $$
  SELECT COALESCE(SUM(oi.quantity * i.price), 0)
  FROM order_items oi
  JOIN items i ON i.id = oi.item_id
  WHERE oi.order_id != current_order_id;
$$ LANGUAGE sql SECURITY DEFINER;