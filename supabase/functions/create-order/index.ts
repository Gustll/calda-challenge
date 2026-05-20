import { createSupabaseClient } from '../_shared/supabaseClient.ts';
import { CreateOrderBody } from '../_shared/types.ts';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
    try {
        if (req.method === 'OPTIONS') {
            return new Response('ok', { headers: corsHeaders });
        }
        if (req.method !== 'POST') {
            return new Response(
                JSON.stringify({ error: 'method not allowed' }),
                { status: 405, headers: { 'Content-Type': 'application/json' } },
            );
        }

        const supabase = createSupabaseClient(req);

        const { error: authError } = await supabase.auth.getUser();
        if (authError) {
            return new Response(
                JSON.stringify({ error: 'unauthorized' }),
                { status: 401, headers: { 'Content-Type': 'application/json' } },
            );
        }

        // TODO - in prod we should validate req body instead of casting
        // probably should use manual type guards
        const { shipping_address, recipient_name, items } = await req
            .json() as CreateOrderBody;

        if (!shipping_address || !recipient_name || !items?.length) {
            return new Response(
                JSON.stringify({ error: 'missing required fields' }),
                { status: 400, headers: { 'Content-Type': 'application/json' } },
            );
        }

        const { data, error } = await supabase.rpc('create_order', {
            p_shipping_address: shipping_address,
            p_recipient_name: recipient_name,
            p_items: items,
        });

        if (error) throw error;

        return new Response(
            JSON.stringify({ success: true, ...data }),
            { status: 201, headers: { 'Content-Type': 'application/json' } },
        );
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'unknown error';
        return new Response(
            JSON.stringify({ error: message }),
            { status: 500, headers: { 'Content-Type': 'application/json' } },
        );
    }
});
