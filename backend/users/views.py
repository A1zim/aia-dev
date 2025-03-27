from decimal import Decimal
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.db.models import Sum
from datetime import datetime

from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.exceptions import AuthenticationFailed

from .models import User, Transaction, CategoryAmount
from .serializers import UserSerializer, TransactionSerializer, CategoryAmountSerializer
from .utils import api_response
from .pagination import StandardResultsSetPagination

from rest_framework import generics
from rest_framework.permissions import AllowAny
from django.db.models import Q
from django.core.mail import send_mail
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth.tokens import PasswordResetTokenGenerator
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.conf import settings

class TokenGenerator(PasswordResetTokenGenerator):
    def _make_hash_value(self, user, timestamp):
        return str(user.pk) + str(timestamp) + str(user.email_verified)

account_activation_token = TokenGenerator()

class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        try:
            print(f"Received data: {request.data}")
            serializer = UserSerializer(data=request.data)
            if serializer.is_valid():
                username = serializer.validated_data['username']
                if User.objects.filter(username__iexact=username).exists():
                    print(f"Username {username} already exists")
                    return Response(
                        {"error": "Username already exists"},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                print("Creating user...")
                user = User.objects.create_user(
                    username=username,
                    password=serializer.validated_data['password'],
                    email=serializer.validated_data['email'],
                    is_active=True,
                    email_verified=False
                )
                print(f"User created: {user.username}")
                uid = urlsafe_base64_encode(force_bytes(user.pk))
                token = account_activation_token.make_token(user)
                print("Generating verification link...")
                verification_link = f"{settings.FRONTEND_URL}/api/verify-email/{uid}/{token}/"
                print(f"Sending email to {user.email} with link {verification_link}")
                send_mail(
                    subject='Verify Your Email',
                    message=f'Click the link to verify your email: {verification_link}',
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[user.email],
                    fail_silently=False,
                )
                print("Email sent successfully")
                return Response(
                    {"message": "Registration successful. Please check your email to verify your account."},
                    status=status.HTTP_201_CREATED
                )
            print(f"Serializer errors: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            print(f"Error in RegisterView: {str(e)}")
            return Response(
                {"error": f"An unexpected error occurred: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
class VerifyEmailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, uidb64, token):
        try:
            uid = force_str(urlsafe_base64_decode(uidb64))
            user = User.objects.get(pk=uid)
        except (TypeError, ValueError, OverflowError, User.DoesNotExist):
            user = None

        if user is not None and account_activation_token.check_token(user, token):
            if not user.email_verified:
                user.email_verified = True
                user.save()
                return Response(
                    {"message": "Email verified successfully. You can now log in."},
                    status=status.HTTP_200_OK
                )
            return Response(
                {"message": "Email already verified."},
                status=status.HTTP_200_OK
            )
        return Response(
            {"error": "Invalid verification link."},
            status=status.HTTP_400_BAD_REQUEST
        )

class CustomTokenObtainPairView(TokenObtainPairView):
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.user
        if not user.email_verified:
            raise AuthenticationFailed(
                detail="Email not verified. Please verify your email before logging in.",
                code="email_not_verified"
            )
        return super().post(request, *args, **kwargs)
    
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

class AddTransaction(APIView):
    """Add a new transaction and update user balances"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """Process a new transaction and update user balances"""
        print(f"Adding transaction for user: {request.user.username}")
        serializer = TransactionSerializer(data=request.data)

        if serializer.is_valid():
            with transaction.atomic():
                category = serializer.validated_data['category']
                amount = Decimal(str(serializer.validated_data['amount']))
                trans_type = serializer.validated_data['type']

                category_choices = [choice[0] for choice in Transaction._meta.get_field('category').choices]
                if category not in category_choices:
                    return api_response(
                        None,
                        message=f'Invalid category. Choose from: {category_choices}',
                        success=False,
                        status_code=status.HTTP_400_BAD_REQUEST
                    )

                if amount <= 0:
                    return api_response(
                        None,
                        message='Amount must be greater than zero',
                        success=False,
                        status_code=status.HTTP_400_BAD_REQUEST
                    )

                # Explicitly set the user to the authenticated user
                serializer.validated_data['user'] = request.user
                transaction_obj = serializer.save()

                user = request.user
                category_amount, created = CategoryAmount.objects.get_or_create(
                    user=user,
                    category=category,
                    type=trans_type,
                    defaults={'amount': 0}
                )

                if trans_type == 'income':
                    user.income += amount
                    user.balance += amount
                else:  # expense
                    user.expense += amount
                    user.balance -= amount

                category_amount.amount += amount
                user.save()
                category_amount.save()

                print(f"Transaction added for user {user.username}: {serializer.data}")
            return api_response(
                serializer.data,
                message="Transaction added successfully",
                status_code=status.HTTP_201_CREATED
            )

        return api_response(
            serializer.errors,
            message="Invalid transaction data",
            success=False,
            status_code=status.HTTP_400_BAD_REQUEST
        )


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

class ClearHistory(APIView):  # Changed from ApiView to APIView
    """Clear all transaction history for a user"""
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        try:
            user = request.user
            print(f"Clearing transaction history for user: {user.username}")
            Transaction.objects.filter(user=user).delete()
            CategoryAmount.objects.filter(user=user).delete()
            print(f"Transaction history cleared for user: {user.username}")
            return Response({'message': 'Transaction history cleared'})
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