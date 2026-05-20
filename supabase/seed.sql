DO $$
DECLARE
    user1_id uuid := gen_random_uuid();
    user2_id uuid := gen_random_uuid();
    user3_id uuid := gen_random_uuid();

    item1_id uuid := '00000000-0000-0000-0000-000000000000';
    item2_id uuid := '00000000-0000-0000-0000-000000000001';
    item3_id uuid := '00000000-0000-0000-0000-000000000002';
    item4_id uuid := '00000000-0000-0000-0000-000000000003';
    item5_id uuid := '00000000-0000-0000-0000-000000000004';

    order1_id uuid := gen_random_uuid();
    order2_id uuid := gen_random_uuid();
    order3_id uuid := gen_random_uuid();
    order4_id uuid := gen_random_uuid();
BEGIN
    -- users
    INSERT INTO auth.users (
    id, instance_id,
    email, encrypted_password, email_confirmed_at,
    created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    aud, role, is_anonymous,
    confirmation_token, recovery_token, email_change_token_new,
    email_change, email_change_token_current, reauthentication_token
) VALUES
    (
        user1_id, '00000000-0000-0000-0000-000000000000',
        'd4rk.spark99+1@gmail.com', crypt('password123', gen_salt('bf')), now(),
        now(), now(),
        '{"provider": "email", "providers": ["email"]}', '{"given_name": "Gal", "family_name": "Volk"}',
        'authenticated', 'authenticated', false,
        '', '', '', '', '', ''
    ),
    (
        user2_id, '00000000-0000-0000-0000-000000000000',
        'd4rk.spark99+2@gmail.com', crypt('password123', gen_salt('bf')), now(),
        now(), now(),
        '{"provider": "email", "providers": ["email"]}', '{"given_name": "Lara", "family_name": "Novak"}',
        'authenticated', 'authenticated', false,
        '', '', '', '', '', ''
    ),
    (
        user3_id, '00000000-0000-0000-0000-000000000000',
        'd4rk.spark99+3@gmail.com', crypt('password123', gen_salt('bf')), now(),
        now(), now(),
        '{"provider": "email", "providers": ["email"]}', '{"given_name": "Mark", "family_name": "Dolenc"}',
        'authenticated', 'authenticated', false,
        '', '', '', '', '', ''
    );
    -- items
    INSERT INTO items (id, name, price, stock)
    VALUES
        (item1_id, 'Whey Protein 2kg', 49.99, 100),
        (item2_id, 'Creatine Monohydrate 500g', 24.99, 150),
        (item3_id, 'Gymshark Arrival Shorts', 44.99, 75),
        (item4_id, 'Pre Workout 300g', 34.99, 80),
        (item5_id, 'Shaker Bottle 700ml', 12.99, 200);

    -- orders
    INSERT INTO orders (id, user_id, shipping_address, recipient_name)
    VALUES
        (order1_id, user1_id, 'Muscle Ave 123, London', 'Ga; Volk'),
        (order2_id, user2_id, 'Ob sotocju 6', 'Lara Novak'),
        (order3_id, user1_id, 'Trg 1, Ljubljana', 'Mark Dolenc');

    -- old order for cron job testing (older than 1 week)
    INSERT INTO orders (id, user_id, shipping_address, recipient_name, created_at, updated_at)
    VALUES (
        order4_id,
        user1_id,
        'Old Street 111, London',
        'Gal Volk',
        '2026-01-01 00:00:00+00',
        '2026-01-01 00:00:00+00'
    );

    -- order items
    INSERT INTO order_items (order_id, item_id, quantity)
    VALUES
        (order1_id, item1_id, 2),
        (order1_id, item2_id, 1),
        (order2_id, item3_id, 1),
        (order2_id, item4_id, 2),
        (order3_id, item5_id, 3),
        (order3_id, item1_id, 1),
        (order4_id, item1_id, 1),
        (order4_id, item2_id, 2);
END;
$$;