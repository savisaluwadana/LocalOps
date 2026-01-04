-- HR System Schema

CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    manager_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    employee_id VARCHAR(20) UNIQUE,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    department_id INTEGER REFERENCES departments(id),
    position VARCHAR(100),
    salary DECIMAL(12, 2),
    hire_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE attendance (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    check_in TIMESTAMP NOT NULL,
    check_out TIMESTAMP,
    hours_worked DECIMAL(4, 2) GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (check_out - check_in)) / 3600
    ) STORED
);

CREATE TABLE leave_requests (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    leave_type VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    approved_by INTEGER REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payroll (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    month VARCHAR(7) NOT NULL,
    basic_salary DECIMAL(12, 2),
    allowances DECIMAL(12, 2) DEFAULT 0,
    deductions DECIMAL(12, 2) DEFAULT 0,
    net_salary DECIMAL(12, 2),
    paid_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample data
INSERT INTO departments (name) VALUES ('Engineering'), ('HR'), ('Sales'), ('Marketing');

INSERT INTO employees (employee_id, name, email, department_id, position, salary, hire_date) VALUES
('EMP001', 'John Smith', 'john@company.com', 1, 'Senior Developer', 85000, '2022-01-15'),
('EMP002', 'Jane Doe', 'jane@company.com', 2, 'HR Manager', 75000, '2021-06-01'),
('EMP003', 'Bob Wilson', 'bob@company.com', 3, 'Sales Rep', 65000, '2023-03-10');

CREATE INDEX idx_attendance_employee ON attendance(employee_id);
CREATE INDEX idx_leave_employee ON leave_requests(employee_id);
CREATE INDEX idx_payroll_month ON payroll(month);
