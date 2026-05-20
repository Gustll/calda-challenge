CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule(
    'archive-old-orders',        
    '0 0 * * *',                 
    $$
        -- store sum of totals for orders older than 1 week
        INSERT INTO archived_orders (total)
        SELECT COALESCE(SUM(oi.quantity * i.price), 0)
        FROM orders o
        JOIN order_items oi ON oi.order_id = o.id
        JOIN items i ON i.id = oi.item_id
        WHERE o.created_at < now() - interval '1 week';

        -- delete orders older than 1 week
        DELETE FROM orders
        WHERE created_at < now() - interval '1 week';
    $$
);