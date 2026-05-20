-- Atomic order creation: inserts order + order_items in one transaction.
-- If any item insert fails (e.g. insufficient stock), the order row is rolled back too.
CREATE OR REPLACE FUNCTION create_order(
  p_shipping_address text,
  p_recipient_name text,
  p_items jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_order_id uuid;
  v_total numeric;
BEGIN
  INSERT INTO orders (user_id, shipping_address, recipient_name)
  VALUES (auth.uid(), p_shipping_address, p_recipient_name)
  RETURNING id INTO v_order_id;

  INSERT INTO order_items (order_id, item_id, quantity)
  SELECT
    v_order_id,
    (item->>'item_id')::uuid,
    (item->>'quantity')::int
  FROM jsonb_array_elements(p_items) AS item;

  SELECT get_other_orders_total(v_order_id) INTO v_total;

  RETURN jsonb_build_object(
    'order_id', v_order_id,
    'other_orders_total', v_total
  );
END;
$$;

GRANT EXECUTE ON FUNCTION create_order(text, text, jsonb) TO authenticated;
