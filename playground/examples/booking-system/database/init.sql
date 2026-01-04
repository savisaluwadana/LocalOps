CREATE TABLE resources (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE slots (
    id SERIAL PRIMARY KEY,
    resource_id INTEGER REFERENCES resources(id),
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    capacity INTEGER DEFAULT 1,
    booked_count INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(resource_id, date, start_time)
);

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE bookings (
    id SERIAL PRIMARY KEY,
    booking_ref VARCHAR(20) UNIQUE NOT NULL,
    slot_id INTEGER REFERENCES slots(id),
    customer_id INTEGER REFERENCES customers(id),
    status VARCHAR(20) DEFAULT 'confirmed',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cancelled_at TIMESTAMP
);

CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER REFERENCES bookings(id),
    type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    scheduled_at TIMESTAMP,
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_slots_date ON slots(date);
CREATE INDEX idx_slots_available ON slots(is_available);
CREATE INDEX idx_bookings_customer ON bookings(customer_id);
CREATE INDEX idx_bookings_status ON bookings(status);

-- Sample data
INSERT INTO resources (name, type) VALUES
('Room A', 'meeting_room'),
('Room B', 'meeting_room'),
('Dr. Smith', 'doctor'),
('Stylist Jane', 'hair_stylist');

INSERT INTO slots (resource_id, date, start_time, end_time, capacity) VALUES
(1, CURRENT_DATE + 1, '09:00', '10:00', 1),
(1, CURRENT_DATE + 1, '10:00', '11:00', 1),
(1, CURRENT_DATE + 1, '11:00', '12:00', 1),
(2, CURRENT_DATE + 1, '09:00', '10:00', 1),
(3, CURRENT_DATE + 1, '09:00', '09:30', 1),
(3, CURRENT_DATE + 1, '09:30', '10:00', 1);
