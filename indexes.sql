CREATE INDEX IF NOT EXISTS idx_orders_registration_id ON orders (registration_id);
CREATE INDEX IF NOT EXISTS idx_order_payment_types_order_id ON order_payment_types (order_id);
CREATE INDEX IF NOT EXISTS idx_machines_city_id ON machines (city_id);
CREATE INDEX IF NOT EXISTS idx_machines_client_id ON machines (client_id);
CREATE INDEX IF NOT EXISTS idx_clients_city_id ON clients (city_id);
