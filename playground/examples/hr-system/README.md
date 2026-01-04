# HR Management System

Complete HR platform for employee management.

## Features

- **Employee Directory** - Profiles, departments, org chart
- **Attendance** - Check-in/out, timesheets
- **Leave Management** - Requests, approvals, balance
- **Payroll** - Salary processing, tax calculations
- **Recruitment** - Job postings, applicant tracking
- **Performance** - Reviews, goals, feedback
- **Documents** - Contracts, policies

## Quick Start

```bash
docker compose up -d

# Portal: http://localhost:3000
# API: http://localhost:8000
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/employees` | List employees |
| `POST /api/attendance/checkin` | Clock in |
| `POST /api/leave/request` | Submit leave |
| `GET /api/payroll/:month` | Get payroll |
