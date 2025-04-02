import random
import string
from decimal import Decimal
from django.core.mail import send_mail
from django.conf import settings
from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.db.models import Sum
from datetime import datetime

from .models import User, Transaction, CategoryAmount, UserCurrency, VerificationCode
from .serializers import UserSerializer, TransactionSerializer, CategoryAmountSerializer, UserCurrencySerializer
from .utils import api_response
from .pagination import StandardResultsSetPagination

# Import generics for list and detail views
from rest_framework import generics
from rest_framework.permissions import AllowAny
from django.db.models import Q
from django.contrib.auth.hashers import check_password
from django.contrib.auth import authenticate, login
from rest_framework_simplejwt.tokens import RefreshToken
import traceback

class RegisterView(APIView):
    """Register a new user and send a verification email"""
    permission_classes = [AllowAny]

    def post(self, request):
        try:
            serializer = UserSerializer(data=request.data)
            if serializer.is_valid():
                username = serializer.validated_data['username']
                email = serializer.validated_data['email']

                # Check if username or email already exists
                if User.objects.filter(username__iexact=username).exists():
                    return Response(
                        {"error": "Username already exists"},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                if User.objects.filter(email__iexact=email).exists():
                    return Response(
                        {"error": "Email already exists"},
                        status=status.HTTP_400_BAD_REQUEST
                    )

                # Create user with is_active=False and is_verified=False
                user = User.objects.create_user(
                    username=username,
                    password=serializer.validated_data['password'],
                    email=email,
                    is_active=False,  # User can't log in until verified
                    is_verified=False
                )

                # Create and save verification code
                verification_code = VerificationCode(user=user)
                verification_code.save()

                # Send verification email
                subject = "Verify Your Email Address"
                message = (
                    f"Hi {username},\n\n"
                    f"Please use the following 6-digit code to verify your email:\n\n"
                    f"{verification_code.code}\n\n"
                    f"This code expires in 15 minutes.\n\n"
                    f"Regards,\nYour App Team"
                )
                send_mail(
                    subject,
                    message,
                    settings.DEFAULT_FROM_EMAIL,
                    [email],
                    fail_silently=False,
                )

                return Response(
                    {"id": user.id, "username": user.username, "message": "Verification code sent to your email"},
                    status=status.HTTP_201_CREATED
                )
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            print(f"Error in RegisterView: {str(e)}")
            return Response(
                {"error": f"Internal server error: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class VerifyEmailView(APIView):
    """Verify user's email with the 6-digit code"""
    permission_classes = [AllowAny]

    def post(self, request):
        try:
            email = request.data.get('email')
            code = request.data.get('code')

            if not email or not code:
                return Response(
                    {"error": "Email and code are required"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            user = User.objects.filter(email=email).first()
            if not user:
                return Response(
                    {"error": "User with this email does not exist"},
                    status=status.HTTP_404_NOT_FOUND
                )

            verification_code = VerificationCode.objects.filter(user=user).first()
            if not verification_code:
                return Response(
                    {"error": "No verification code found for this user"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            if verification_code.is_expired():
                verification_code.delete()
                return Response(
                    {"error": "Verification code has expired. Please register again."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            if verification_code.code != code:
                return Response(
                    {"error": "Invalid verification code"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Activate the user
            user.is_verified = True
            user.is_active = True
            user.save()
            verification_code.delete()  # Clean up the code after verification

            return Response(
                {"message": "Email verified successfully"},
                status=status.HTTP_200_OK
            )
        except Exception as e:
            print(f"Error in VerifyEmailView: {str(e)}")
            return Response(
                {"error": f"Internal server error: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        email = request.data.get('email')
        if not email:
            return Response(
                {"error": "Email is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response(
                {"error": "User with this email does not exist"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Generate a 6-digit code
        code = ''.join(random.choices(string.digits, k=6))
        user.temporary_code = code  # Assuming you add a `temporary_code` field to your User model
        user.save()

        # Send email
        send_mail(
            subject='Your Temporary Password',
            message=f'Here is your password: {code}. Don’t forget to change it!',
            from_email='azimiwenbaev@gmail.com',
            recipient_list=[email],
            fail_silently=False,
        )

        return Response(
            {"message": "A 6-digit code has been sent to your email"},
            status=status.HTTP_200_OK
        )

class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')

        if not username:
            return Response(
                {"error": "username_required", "message": "Username is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        if not password:
            return Response(
                {"error": "password_required", "message": "Password is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if user exists first
        try:
            user = User.objects.get(username__iexact=username)
        except User.DoesNotExist:
            return Response(
                {"error": "user_not_found", "message": "Username does not exist"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Try to authenticate with the password
        user = authenticate(request, username=username, password=password)
        if user is None:
            # If authentication fails, check temporary code
            user = User.objects.get(username__iexact=username)  # Already confirmed exists
            if user.temporary_code and user.temporary_code == password:
                user.set_password(password)
                user.temporary_code = None
                user.save()
                refresh = RefreshToken.for_user(user)
                return Response(
                    {
                        "message": "Login successful with temporary code. Password updated.",
                        "access": str(refresh.access_token),
                        "refresh": str(refresh),
                    },
                    status=status.HTTP_200_OK
                )
            return Response(
                {"error": "password_incorrect", "message": "Password is incorrect"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Successful login with password
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "message": "Login successful",
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            },
            status=status.HTTP_200_OK
        )

class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            old_password = request.data.get('old_password')
            new_password = request.data.get('new_password')

            if not old_password:
                return Response(
                    {"error": "old_password_required", "message": "Old password is required"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            if not new_password:
                return Response(
                    {"error": "new_password_required", "message": "New password is required"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            user = request.user
            if not check_password(old_password, user.password):
                return Response(
                    {"error": "invalid_old_password", "message": "Old password is incorrect"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            user.set_password(new_password)
            user.save()

            return Response(
                {"message": "Password changed successfully"},
                status=status.HTTP_200_OK
            )
        except Exception as e:
            return Response(
                {"error": "server_error", "message": f"Internal server error: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class UserListCreate(generics.ListCreateAPIView):
    """List and create users - restricted to the authenticated user only"""
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Only return the authenticated user's data
        print(f"Fetching user list for user: {self.request.user.username}")
        queryset = User.objects.filter(id=self.request.user.id)
        print(f"User list for {self.request.user.username}: {list(queryset.values('id', 'username'))}")
        return queryset

    def perform_create(self, serializer):
        # Disable creation through this endpoint
        raise Response(
            {"error": "Use the /api/register/ endpoint to create a new user"},
            status=status.HTTP_403_FORBIDDEN
        )


class UserDetail(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, or delete the authenticated user's instance"""
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        # Only allow access to the authenticated user's own data
        user = self.request.user
        print(f"Fetching user detail for user: {user.username}")
        return user
    
    def retrieve(self, request, *args, **kwargs):
        """Этот метод вызывается при GET запросе, чтобы вернуть данные пользователя"""
        print("Retrieve method called")
        return super().retrieve(request, *args, **kwargs)

    # Метод для обработки PUT/PATCH запроса, чтобы обновить данные пользователя
    def update(self, request, *args, **kwargs):
        """Этот метод вызывается при PUT/PATCH запросе, чтобы обновить данные пользователя"""
        print("Update method called")
        return super().update(request, *args, **kwargs)

    # Метод для обработки DELETE запроса, чтобы удалить пользователя
    def destroy(self, request, *args, **kwargs):
        """Этот метод вызывается при DELETE запросе, чтобы удалить данные пользователя"""
        print("Destroy method called")
        return super().destroy(request, *args, **kwargs)
    
class UserCurrencyViewSet(APIView):
    """Manage user-specific currencies"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """List all currencies for the authenticated user"""
        try:
            print(f"Fetching currencies for user: {request.user.username}")
            currencies = UserCurrency.objects.filter(user=request.user).values_list('currency', flat=True)
            # Ensure KGS is always included
            currency_list = list(currencies)
            if 'KGS' not in currency_list:
                currency_list.insert(0, 'KGS')
            print(f"Returning currencies for user {request.user.username}: {currency_list}")
            return Response(currency_list, status=status.HTTP_200_OK)
        except Exception as e:
            print(f"Error in UserCurrencyViewSet.get: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def post(self, request):
        """Add a new currency for the authenticated user"""
        try:
            print(f"Adding currency for user: {request.user.username}")
            serializer = UserCurrencySerializer(data=request.data, context={'request': request})
            if serializer.is_valid():
                currency = serializer.validated_data['currency']
                # Create the UserCurrency instance
                UserCurrency.objects.create(user=request.user, currency=currency)
                print(f"Currency {currency} added for user {request.user.username}")
                return Response(
                    {'message': f'Currency {currency} added successfully'},
                    status=status.HTTP_201_CREATED
                )
            print(f"Validation errors: {serializer.errors}")
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            print(f"Error in UserCurrencyViewSet.post: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def delete(self, request, currency):
        """Delete a currency for the authenticated user"""
        try:
            currency = currency.upper()
            print(f"Deleting currency {currency} for user: {request.user.username}")
            # Prevent deleting KGS
            if currency == 'KGS':
                print("Attempted to delete KGS, which is not allowed")
                return Response(
                    {'error': 'Cannot delete KGS'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            # Check if the currency exists
            try:
                user_currency = UserCurrency.objects.get(user=request.user, currency=currency)
                user_currency.delete()
                print(f"Currency {currency} deleted for user {request.user.username}")
                return Response(status=status.HTTP_204_NO_CONTENT)
            except UserCurrency.DoesNotExist:
                print(f"Currency {currency} not found for user {request.user.username}")
                return Response(
                    {'error': f'Currency {currency} not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
        except Exception as e:
            print(f"Error in UserCurrencyViewSet.delete: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class AddTransaction(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        print(f"Adding transaction for user: {request.user.username}")
        print(f"Request data: {request.data}")
        serializer = TransactionSerializer(data=request.data, context={'request': request})

        if serializer.is_valid():
            try:
                with transaction.atomic():
                    category = serializer.validated_data['category']
                    amount = Decimal(str(serializer.validated_data['amount']))
                    trans_type = serializer.validated_data['type']

                    print(f"Validated data: {serializer.validated_data}")

                    serializer.validated_data['user'] = request.user
                    transaction_obj = serializer.save()
                    print(f"Transaction saved: {transaction_obj.id}")

                    user = request.user
                    category_amount, created = CategoryAmount.objects.get_or_create(
                        user=user,
                        category=category,
                        type=trans_type,
                        defaults={'amount': Decimal('0.00')}
                    )
                    print(f"CategoryAmount {'created' if created else 'retrieved'}: {category_amount.id}")

                    if trans_type == 'income':
                        user.income += amount
                        user.balance += amount
                    else:  # expense
                        user.expense += amount
                        user.balance -= amount

                    category_amount.amount += amount
                    user.save()
                    print(f"User updated: income={user.income}, expense={user.expense}, balance={user.balance}")
                    category_amount.save()
                    print(f"CategoryAmount updated: {category_amount.amount}")

                print(f"Transaction added for user {user.username}: {serializer.data}")
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            except Exception as e:
                print(f"Error adding transaction: {str(e)}")
                print(traceback.format_exc())
                return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        else:
            print(f"Validation errors: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class TransactionDetailView(APIView):
    """Update or delete a specific transaction"""
    permission_classes = [IsAuthenticated]

    def put(self, request, transaction_id):
        print(f"Updating transaction {transaction_id} for user: {request.user.username}")
        transaction_obj = get_object_or_404(Transaction, id=transaction_id, user=request.user)
        
        # Log the incoming request data to verify the timestamp
        print(f"Request data: {request.data}")

        serializer = TransactionSerializer(
            transaction_obj,
            data=request.data,
            partial=True,
            context={'request': request}
        )

        if serializer.is_valid():
            with transaction.atomic():
                old_amount = transaction_obj.amount
                old_type = transaction_obj.type
                old_category = transaction_obj.category

                # Ensure timestamp is a date
                if 'timestamp' in serializer.validated_data:
                    timestamp = serializer.validated_data['timestamp']
                    if isinstance(timestamp, datetime):
                        serializer.validated_data['timestamp'] = timestamp.date()

                # Update the transaction
                serializer.save()

                # Adjust user balances and category amounts
                user = request.user
                new_amount = Decimal(str(serializer.validated_data['amount']))
                new_type = serializer.validated_data['type']
                new_category = serializer.validated_data['category']

                # Revert the old transaction's effect
                if old_type == 'income':
                    user.income -= old_amount
                    user.balance -= old_amount
                else:  # expense
                    user.expense -= old_amount
                    user.balance += old_amount

                # Apply the new transaction's effect
                if new_type == 'income':
                    user.income += new_amount
                    user.balance += new_amount
                else:  # expense
                    user.expense += new_amount
                    user.balance -= new_amount

                # Update CategoryAmount
                if old_category != new_category or old_type != new_type:
                    old_category_amount = CategoryAmount.objects.get(
                        user=user, category=old_category, type=old_type
                    )
                    old_category_amount.amount -= old_amount
                    if old_category_amount.amount <= 0:
                        old_category_amount.delete()
                    else:
                        old_category_amount.save()

                    new_category_amount, created = CategoryAmount.objects.get_or_create(
                        user=user, category=new_category, type=new_type, defaults={'amount': 0}
                    )
                    new_category_amount.amount += new_amount
                    new_category_amount.save()
                else:
                    category_amount = CategoryAmount.objects.get(
                        user=user, category=new_category, type=new_type
                    )
                    category_amount.amount = category_amount.amount - old_amount + new_amount
                    category_amount.save()

                user.save()

            print(f"Transaction {transaction_id} updated for user {user.username}: {serializer.data}")
            return Response(serializer.data, status=status.HTTP_200_OK)
        print(f"Validation errors: {serializer.errors}")
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, transaction_id):
        """Delete a transaction"""
        try:
            print(f"Deleting transaction {transaction_id} for user: {request.user.username}")
            transaction_obj = get_object_or_404(Transaction, id=transaction_id, user=request.user)
            with transaction.atomic():
                # Revert the transaction's effect on user balances
                user = request.user
                amount = transaction_obj.amount
                trans_type = transaction_obj.type
                category = transaction_obj.category

                if trans_type == 'income':
                    user.income -= amount
                    user.balance -= amount
                else:  # expense
                    user.expense -= amount
                    user.balance += amount

                # Update CategoryAmount
                category_amount = CategoryAmount.objects.get(user=user, category=category, type=trans_type)
                category_amount.amount -= amount
                if category_amount.amount <= 0:
                    category_amount.delete()
                else:
                    category_amount.save()

                user.save()
                transaction_obj.delete()

            print(f"Transaction {transaction_id} deleted for user: {user.username}")
            return Response(status=status.HTTP_204_NO_CONTENT)
        except Exception as e:
            print(f"Error in TransactionDetailView.delete: {str(e)}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class GetTransactionsByCategory(APIView):
    """Get transactions by category and type"""
    permission_classes = [IsAuthenticated]

    def get(self, request, category, trans_type):
        try:
            user = request.user
            print(f"Fetching transactions by category for user: {user.username}, category: {category}, type: {trans_type}")

            type_choices = [choice[0] for choice in Transaction._meta.get_field('type').choices]
            if trans_type not in type_choices:
                return Response(
                    {'error': f'Invalid transaction type. Choose from: {type_choices}'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            category_choices = [choice[0] for choice in Transaction._meta.get_field('category').choices]
            if category not in category_choices:
                return Response(
                    {'error': f'Invalid category. Choose from: {category_choices}'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            try:
                category_amount = CategoryAmount.objects.get(
                    user=user, type=trans_type, category=category
                )
                response_data = {
                    'category': category,
                    'type': trans_type,
                    'amount': float(category_amount.amount)
                }
            except CategoryAmount.DoesNotExist:
                response_data = {
                    'category': category,
                    'type': trans_type,
                    'amount': 0
                }

            print(f"Returning transactions by category for user {user.username}: {response_data}")
            return Response(response_data)

        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ClearHistory(APIView):
    """Clear all transaction history and financial data for a user"""
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def delete(self, request):
        try:
            user = request.user
            password = request.data.get('password')
            if not password:
                return Response(
                    {'error': 'Password is required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Verify the password
            if not user.check_password(password):
                return Response(
                    {'error': 'Invalid password'},
                    status=status.HTTP_401_UNAUTHORIZED
                )

            print(f"Clearing all financial data for user: {user.username}")
            
            # Clear transactions and category amounts
            Transaction.objects.filter(user=user).delete()
            CategoryAmount.objects.filter(user=user).delete()
            
            # Reset user's financial fields
            user.balance = 0
            user.income = 0
            user.expense = 0
            user.save()
            
            print(f"All financial data cleared for user: {user.username}")
            return Response(status=status.HTTP_204_NO_CONTENT)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ResetFinances(APIView):  # Changed from ApiView to APIView
    """Reset all financial data for a user"""
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        try:
            user = request.user
            print(f"Resetting finances for user: {user.username}")
            user.balance = 0
            user.income = 0
            user.expense = 0
            user.save()

            CategoryAmount.objects.filter(user=user).delete()
            Transaction.objects.filter(user=user).delete()

            print(f"Finances reset for user: {user.username}")
            return Response({'message': 'Financial data reset successfully'})
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class FinancialSummary(APIView):  # Changed from ApiView to APIView
    """Get a comprehensive summary of user's finances"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            user = request.user
            print(f"Fetching financial summary for user: {user.username}")
            categories = CategoryAmount.objects.filter(user=user)

            income_by_category = {
                cat.category: float(cat.amount)
                for cat in categories.filter(type='income')
            }

            expense_by_category = {
                cat.category: float(cat.amount)
                for cat in categories.filter(type='expense')
            }

            recent_transactions = TransactionSerializer(
                Transaction.objects.filter(user=user).order_by('-timestamp')[:5],
                many=True
            ).data

            summary = {
                "balance": float(user.balance),
                "total_income": float(user.income),
                "total_expense": float(user.expense),
                "income_by_category": income_by_category,
                "expense_by_category": expense_by_category,
                "recent_transactions": recent_transactions
            }

            print(f"Returning financial summary for user {user.username}: {summary}")
            return Response(summary)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class GetCategories(APIView):
    """Get available transaction categories"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        categories = [choice[0] for choice in Transaction._meta.get_field('category').choices]
        print(f"Returning categories for user {request.user.username}: {categories}")
        return Response(categories)


class DiagramByPercent(APIView):  # Changed from ApiView to APIView
    """Base class for percentage-based diagrams"""
    permission_classes = [IsAuthenticated]

    def get_percentages(self, user, trans_type):
        total = user.income if trans_type == 'income' else user.expense
        categories = CategoryAmount.objects.filter(user=user, type=trans_type)

        if total == 0:
            return {cat.category: 0 for cat in categories}

        percent_diagram = {}
        for cat in categories:
            percent_diagram[cat.category] = round((cat.amount / total) * 100, 2)

        return percent_diagram


class ExpenseDiagramByPercent(DiagramByPercent):
    """Get expense breakdown by percentage"""
    def get(self, request):
        try:
            user = request.user
            print(f"Fetching expense diagram for user: {user.username}")
            percentages = self.get_percentages(user, 'expense')
            print(f"Returning expense diagram for user {user.username}: {percentages}")
            return Response(percentages)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class IncomeDiagramByPercent(DiagramByPercent):
    """Get income data by category as percentages for pie charts"""
    def get(self, request):
        try:
            user = request.user
            print(f"Fetching income diagram for user: {user.username}")
            user_incomes = CategoryAmount.objects.filter(
                user=user,
                type='income'
            )

            total_income = sum(income.amount for income in user_incomes)

            if total_income == 0:
                response_data = {
                    'message': 'No income data available',
                    'data': []
                }
                print(f"Returning income diagram for user {user.username}: {response_data}")
                return Response(response_data)

            income_data = []
            for income in user_incomes:
                percentage = (income.amount / total_income) * 100
                income_data.append({
                    'category': income.category,
                    'amount': float(income.amount),
                    'percentage': round(float(percentage), 2)
                })

            income_data.sort(key=lambda x: x['percentage'], reverse=True)

            response_data = {
                'total': float(total_income),
                'data': income_data
            }
            print(f"Returning income diagram for user {user.username}: {response_data}")
            return Response(response_data)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TransactionListView(generics.ListAPIView):
    """List all transactions with pagination and filtering support"""
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        """
        Return filtered queryset of transactions
        Supports filtering by:
        - type (income/expense)
        - category
        - date_from, date_to
        - min_amount, max_amount
        """
        print(f"Fetching transactions for user: {self.request.user.username}")
        queryset = Transaction.objects.filter(user=self.request.user)

        queryset = self._filter_by_transaction_type(queryset)
        queryset = self._filter_by_category(queryset)
        queryset = self._filter_by_date_range(queryset)
        queryset = self._filter_by_amount_range(queryset)

        sort_by = self.request.query_params.get('sort_by', '-timestamp')
        if sort_by not in ['timestamp', '-timestamp', 'amount', '-amount', 'name', '-name']:
            sort_by = '-timestamp'

        return queryset.order_by(sort_by)

    def _filter_by_transaction_type(self, queryset):
        """Filter transactions by type (income/expense)"""
        trans_type = self.request.query_params.get('type')
        if trans_type and trans_type in dict(Transaction.TYPE_CHOICES):
            return queryset.filter(type=trans_type)
        return queryset

    def _filter_by_category(self, queryset):
        """Filter transactions by category"""
        category = self.request.query_params.get('category')
        if category and category in dict(Transaction.CATEGORY_CHOICES):
            return queryset.filter(category=category)
        return queryset

    def _filter_by_date_range(self, queryset):
        """Filter transactions by date range"""
        date_from = self.request.query_params.get('date_from')
        if date_from:
            try:
                date_from = datetime.strptime(date_from, '%Y-%m-%d').date()
                queryset = queryset.filter(timestamp__date__gte=date_from)
            except ValueError:
                pass

        date_to = self.request.query_params.get('date_to')
        if date_to:
            try:
                date_to = datetime.strptime(date_to, '%Y-%m-%d').date()
                queryset = queryset.filter(timestamp__date__lte=date_to)
            except ValueError:
                pass

        return queryset

    def _filter_by_amount_range(self, queryset):
        """Filter transactions by amount range"""
        from decimal import Decimal, InvalidOperation

        min_amount = self.request.query_params.get('min_amount')
        if min_amount:
            try:
                queryset = queryset.filter(amount__gte=Decimal(min_amount))
            except (ValueError, InvalidOperation):
                pass

        max_amount = self.request.query_params.get('max_amount')
        if max_amount:
            try:
                queryset = queryset.filter(amount__lte=Decimal(max_amount))
            except (ValueError, InvalidOperation):
                pass

        return queryset

    def list(self, request, *args, **kwargs):
        """Override list method to add metadata for Flutter consumption"""
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)

        if page is not None:
            serializer = self.get_serializer(page, many=True)
            response = self.get_paginated_response(serializer.data)

            include_summary = request.query_params.get('include_summary') == 'true'
            if include_summary:
                total_income = Transaction.objects.filter(
                    user=request.user, type='income'
                ).aggregate(Sum('amount'))['amount__sum'] or 0

                total_expense = Transaction.objects.filter(
                    user=request.user, type='expense'
                ).aggregate(Sum('amount'))['amount__sum'] or 0

                response.data['summary'] = {
                    'total_income': float(total_income),
                    'total_expense': float(total_expense),
                    'balance': float(total_income - total_expense)
                }

            print(f"Returning transactions for user {request.user.username}: {response.data}")
            return response

        serializer = self.get_serializer(queryset, many=True)
        print(f"Returning transactions for user {request.user.username}: {serializer.data}")
        return Response(serializer.data)


class TransactionDetailView(APIView):  # Changed from ApiView to APIView
    """Update or delete a specific transaction"""
    permission_classes = [IsAuthenticated]

    def put(self, request, transaction_id):
        """Update a transaction"""
        try:
            print(f"Updating transaction {transaction_id} for user: {request.user.username}")
            transaction_obj = get_object_or_404(Transaction, id=transaction_id, user=request.user)
            serializer = TransactionSerializer(transaction_obj, data=request.data, partial=True)

            if serializer.is_valid():
                with transaction.atomic():
                    old_amount = transaction_obj.amount
                    old_type = transaction_obj.type
                    old_category = transaction_obj.category

                    # Update the transaction
                    serializer.save()

                    # Adjust user balances and category amounts
                    user = request.user
                    new_amount = Decimal(str(serializer.validated_data['amount']))
                    new_type = serializer.validated_data['type']
                    new_category = serializer.validated_data['category']

                    # Revert the old transaction's effect
                    if old_type == 'income':
                        user.income -= old_amount
                        user.balance -= old_amount
                    else:  # expense
                        user.expense -= old_amount
                        user.balance += old_amount

                    # Apply the new transaction's effect
                    if new_type == 'income':
                        user.income += new_amount
                        user.balance += new_amount
                    else:  # expense
                        user.expense += new_amount
                        user.balance -= new_amount

                    # Update CategoryAmount
                    if old_category != new_category or old_type != new_type:
                        # Revert old category amount
                        old_category_amount = CategoryAmount.objects.get(
                            user=user, category=old_category, type=old_type
                        )
                        old_category_amount.amount -= old_amount
                        if old_category_amount.amount <= 0:
                            old_category_amount.delete()
                        else:
                            old_category_amount.save()

                        # Update or create new category amount
                        new_category_amount, created = CategoryAmount.objects.get_or_create(
                            user=user, category=new_category, type=new_type, defaults={'amount': 0}
                        )
                        new_category_amount.amount += new_amount
                        new_category_amount.save()
                    else:
                        # Same category and type, just update the amount
                        category_amount = CategoryAmount.objects.get(
                            user=user, category=new_category, type=new_type
                        )
                        category_amount.amount = category_amount.amount - old_amount + new_amount
                        category_amount.save()

                    user.save()

                print(f"Transaction {transaction_id} updated for user {user.username}: {serializer.data}")
                return Response(serializer.data, status=status.HTTP_200_OK)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def delete(self, request, transaction_id):
        """Delete a transaction"""
        try:
            print(f"Deleting transaction {transaction_id} for user: {request.user.username}")
            transaction_obj = get_object_or_404(Transaction, id=transaction_id, user=request.user)
            with transaction.atomic():
                # Revert the transaction's effect on user balances
                user = request.user
                amount = transaction_obj.amount
                trans_type = transaction_obj.type
                category = transaction_obj.category

                if trans_type == 'income':
                    user.income -= amount
                    user.balance -= amount
                else:  # expense
                    user.expense -= amount
                    user.balance += amount

                # Update CategoryAmount
                category_amount = CategoryAmount.objects.get(user=user, category=category, type=trans_type)
                category_amount.amount -= amount
                if category_amount.amount <= 0:
                    category_amount.delete()
                else:
                    category_amount.save()

                user.save()
                transaction_obj.delete()

            print(f"Transaction {transaction_id} deleted for user: {user.username}")
            return Response(status=status.HTTP_204_NO_CONTENT)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class ReportView(APIView):
    """Generate financial reports based on filters"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            print(f"Fetching report for user: {request.user.username}")
            queryset = Transaction.objects.filter(user=request.user)
            print(f"Initial queryset count: {queryset.count()}")

            # Get TYPE_CHOICES and CATEGORY_CHOICES from the model fields
            type_choices = [choice[0] for choice in Transaction._meta.get_field('type').choices]
            category_choices = [choice[0] for choice in Transaction._meta.get_field('category').choices]

            # Apply filters similar to TransactionListView
            date_from = request.query_params.get('date_from')
            if date_from:
                print(f"Applying date_from filter: {date_from}")
                try:
                    date_from = datetime.strptime(date_from, '%Y-%m-%d').date()
                    queryset = queryset.filter(timestamp__date__gte=date_from)
                    print(f"After date_from filter, queryset count: {queryset.count()}")
                except ValueError as e:
                    print(f"Invalid date_from format: {e}")
                    return Response({'error': 'Invalid date_from format. Use YYYY-MM-DD.'}, status=status.HTTP_400_BAD_REQUEST)

            date_to = request.query_params.get('date_to')
            if date_to:
                print(f"Applying date_to filter: {date_to}")
                try:
                    date_to = datetime.strptime(date_to, '%Y-%m-%d').date()
                    queryset = queryset.filter(timestamp__date__lte=date_to)
                    print(f"After date_to filter, queryset count: {queryset.count()}")
                except ValueError as e:
                    print(f"Invalid date_to format: {e}")
                    return Response({'error': 'Invalid date_to format. Use YYYY-MM-DD.'}, status=status.HTTP_400_BAD_REQUEST)

            trans_type = request.query_params.get('type')
            if trans_type:
                if trans_type not in type_choices:
                    print(f"Invalid transaction type: {trans_type}")
                    return Response(
                        {'error': f'Invalid transaction type. Choose from: {type_choices}'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                print(f"Applying type filter: {trans_type}")
                queryset = queryset.filter(type=trans_type)
                print(f"After type filter, queryset count: {queryset.count()}")
            else:
                print("No type filter applied")

            category = request.query_params.get('category')
            if category:
                print(f"Applying category filter: {category}")
                categories = category.split(',')
                invalid_categories = [cat for cat in categories if cat not in category_choices]
                if invalid_categories:
                    print(f"Invalid categories: {invalid_categories}")
                    return Response(
                        {'error': f'Invalid categories: {invalid_categories}. Choose from: {category_choices}'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                queryset = queryset.filter(category__in=categories)
                print(f"After category filter, queryset count: {queryset.count()}")

            # Calculate totals
            print("Calculating totals...")
            total_income = queryset.filter(type='income').aggregate(Sum('amount'))['amount__sum'] or 0
            total_expense = queryset.filter(type='expense').aggregate(Sum('amount'))['amount__sum'] or 0
            print(f"Total income: {total_income}, Total expense: {total_expense}")

            # Group by category
            print("Grouping by category...")
            income_by_category = {}
            expense_by_category = {}
            for cat in category_choices:
                income_amount = queryset.filter(type='income', category=cat).aggregate(Sum('amount'))['amount__sum'] or 0
                expense_amount = queryset.filter(type='expense', category=cat).aggregate(Sum('amount'))['amount__sum'] or 0
                if income_amount > 0:
                    income_by_category[cat] = float(income_amount)
                if expense_amount > 0:
                    expense_by_category[cat] = float(expense_amount)
            print(f"Income by category: {income_by_category}")
            print(f"Expense by category: {expense_by_category}")

            # Serialize transactions
            print("Serializing transactions...")
            transactions = TransactionSerializer(queryset, many=True).data
            print(f"Serialized transactions: {transactions}")

            report = {
                'total_income': float(total_income),
                'total_expense': float(total_expense),
                'income_by_category': income_by_category,
                'expense_by_category': expense_by_category,
                'transactions': transactions
            }
            print(f"Returning report for user {request.user.username}: {report}")
            return Response(report)
        except Exception as e:
            print(f"Error in ReportView: {str(e)}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)