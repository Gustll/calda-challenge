CREATE OR REPLACE VIEW orders_view
WITH (security_invoker = true) AS
SELECT
  o.id AS order_id,
  o.user_id,
  o.recipient_name,
  o.shipping_address,
  o.created_at,
  o.updated_at,
  p.name AS user_name,
  p.surname AS user_surname,
  json_agg(
    json_build_object(
      'item_id', i.id,
      'name', i.name,
      'price', i.price,
      'quantity', oi.quantity
    )
  ) AS items
FROM orders o
JOIN profiles p ON p.id = o.user_id
JOIN order_items oi ON oi.order_id = o.id
JOIN items i ON i.id = oi.item_id
GROUP BY
  o.id,
  o.user_id,
  o.recipient_name,
  o.shipping_address,
  o.created_at,
  o.updated_at,
  p.name,
  p.surname;