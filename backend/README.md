# Expense Tracker API

Backend REST API for the Expense Tracker application built with Django REST Framework.

## Features

- User authentication with JWT
- Transaction management (income/expense)
- Category-based transaction organization
- Financial summaries and statistics
- Data visualization endpoints for charts

## Getting Started

### Prerequisites

- Python 3.8+
- pip (Python package manager)

### Installation

1. Clone the repository
2. Create a virtual environment:
   ```
   python -m venv venv
   ```
3. Activate the virtual environment:
   - Windows: `venv\Scripts\activate`
   - macOS/Linux: `source venv/bin/activate`
4. Install dependencies:
   ```
   pip install -r requirements.txt
   ```
5. Run migrations:
   ```
   python manage.py migrate
   ```
6. Create a superuser:
   ```
   python manage.py createsuperuser
   ```
7. Start the development server:
   ```
   python manage.py runserver
   ```

## API Endpoints

### Authentication
- `POST /api/auth/token/` - Obtain JWT token
- `POST /api/auth/token/refresh/` - Refresh JWT token
- `POST /api/auth/token/verify/` - Verify JWT token

### Users
- `GET /api/users/` - List users
- `POST /api/users/` - Create user
- `GET /api/users/{id}/` - Retrieve user
- `PUT /api/users/{id}/` - Update user
- `DELETE /api/users/{id}/` - Delete user

### Transactions
- `GET /api/transactions/` - List transactions (with filtering)
- `POST /api/transactions/add/` - Add transaction
- `GET /api/categories/{category}/type/{type}/` - Get transactions by category and type
- `POST /api/transactions/clear/` - Clear all transactions

### Finance Management
- `POST /api/finances/reset/` - Reset finances
- `GET /api/finances/summary/` - Get financial summary
- `GET /api/categories/` - Get transaction categories

### Data Visualization
- `GET /api/diagrams/expense-percent/` - Get expense percentages for charts
- `GET /api/diagrams/income-percent/` - Get income percentages for charts

## Integration with Flutter

This API is designed to work seamlessly with the Expense Tracker Flutter application. All endpoints return data in a consistent format:

```json
{
  "success": true,
  "message": "Success message",
  "data": { ... }
}
```

Error responses follow a similar structure:

```json
{
  "success": false,
  "message": "Error message",
  "data": { ... } // optional error details
}
```
