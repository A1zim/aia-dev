from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
from django.db import IntegrityError
from django.core.exceptions import ValidationError
from django.http import JsonResponse
from decimal import InvalidOperation

def custom_exception_handler(exc, context):
    """
    Custom exception handler for global use in the API.
    Returns more detailed error responses for common exceptions.
    """
    # Call REST framework's default exception handler first to get the standard error response
    response = exception_handler(exc, context)

    # If response is already handled, return it
    if response is not None:
        return response

    # Handle Django integrity errors (e.g., unique constraint violations)
    if isinstance(exc, IntegrityError):
        data = {
            'error': 'Database integrity error',
            'detail': str(exc)
        }
        return Response(data, status=status.HTTP_400_BAD_REQUEST)

    # Handle Django validation errors
    elif isinstance(exc, ValidationError):
        data = {
            'error': 'Validation error',
            'detail': exc.message_dict if hasattr(exc, 'message_dict') else str(exc)
        }
        return Response(data, status=status.HTTP_400_BAD_REQUEST)

    # If unhandled, return generic 500 error
    return Response(
        {'error': 'An unexpected error occurred'},
        status=status.HTTP_500_INTERNAL_SERVER_ERROR
    )

def api_response(data=None, message="Success", success=True, status_code=status.HTTP_200_OK):
    """
    Standardized API response helper for consistent Flutter responses
    """
    response_data = {
        'success': success,
        'message': message,
    }
    
    if data is not None:
        response_data['data'] = data
        
    return Response(response_data, status=status_code)
