"""
API Documentation for the Expense Tracker API

This module contains documentation strings and metadata about the API endpoints.
These can be used for generating OpenAPI/Swagger documentation.

To enable Swagger documentation:
1. Install drf-yasg: pip install drf-yasg
2. Add 'drf_yasg' to INSTALLED_APPS in settings.py
3. Add the following to your main urls.py:

    from rest_framework import permissions
    from drf_yasg.views import get_schema_view
    from drf_yasg import openapi

    schema_view = get_schema_view(
        openapi.Info(
            title="Expense Tracker API",
            default_version='v1',
            description="API for tracking personal finances and expenses",
            contact=openapi.Contact(email="your-email@example.com"),
            license=openapi.License(name="MIT License"),
        ),
        public=True,
        permission_classes=(permissions.AllowAny,),
    )

    urlpatterns = [
        # ... your other URL patterns ...
        path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
        path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    ]
"""

# API Endpoint Descriptions
ENDPOINT_DOCS = {
    "add_transaction": """
    Add a new transaction and update user balances.
    
    Request Body:
    {
        "type": "income" or "expense",
        "name": "Transaction name",
        "amount": "12.34",
        "category": "One of the valid categories"
    }
    
    Response:
    HTTP 201 - Transaction created successfully
    HTTP 400 - Invalid input parameters
    HTTP 401 - User not authenticated
    """,
    
    "transaction_list": """
    List all transactions with pagination and filtering.
    
    Query Parameters:
    - type: Filter by transaction type (income/expense)
    - category: Filter by category
    - date_from, date_to: Filter by date range (YYYY-MM-DD)
    - min_amount, max_amount: Filter by amount range
    - sort_by: Field to sort by (timestamp, -timestamp, amount, -amount, name, -name)
    - page: Page number for pagination
    - page_size: Number of items per page
    - include_summary: Set to 'true' to include summary data
    
    Response:
    HTTP 200 - List of transactions with pagination metadata
    HTTP 401 - User not authenticated
    """,
    
    # Add more endpoint documentation as needed
}
