export interface OrderItem {
    item_id: string;
    quantity: number;
}

export interface CreateOrderBody {
    shipping_address: string;
    recipient_name: string;
    items: OrderItem[];
}
