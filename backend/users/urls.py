from django.urls import path
from .views import (
    RegisterView, UserListCreate, UserDetail, AddTransaction, GetTransactionsByCategory,
    ClearHistory, ResetFinances, FinancialSummary, GetCategories, ExpenseDiagramByPercent,
    IncomeDiagramByPercent, TransactionListView, TransactionDetailView, ReportView, 
    UserCurrencyViewSet, VerifyEmailView, ChangePasswordView
)
# Import Simple JWT views for token authentication
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
    TokenVerifyView,
)

urlpatterns = [
    # Authentication endpoints
    path('auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/token/verify/', TokenVerifyView.as_view(), name='token_verify'),
    
    # User and transaction endpoints
    path('register/', RegisterView.as_view(), name='register'),
    path('verify-email/', VerifyEmailView.as_view(), name='verify-email'),  # Add this
    path('users/', UserListCreate.as_view(), name='user-list'),
    path('users/me/', UserDetail.as_view(), name='user-detail'),
    path('users/me/change-password/', ChangePasswordView.as_view(), name='change_password'),
    path('transactions/add/', AddTransaction.as_view(), name='add-transaction'),
    path('transactions/by-category/<str:category>/<str:trans_type>/', GetTransactionsByCategory.as_view(), name='transactions-by-category'),
    path('transactions/clear/', ClearHistory.as_view(), name='clear-history'),
    path('finances/reset/', ResetFinances.as_view(), name='reset-finances'),
    path('finances/summary/', FinancialSummary.as_view(), name='financial-summary'),
    path('categories/', GetCategories.as_view(), name='get-categories'),
    path('diagram/expense/', ExpenseDiagramByPercent.as_view(), name='expense-diagram'),
    path('diagram/income/', IncomeDiagramByPercent.as_view(), name='income-diagram'),
    path('transactions/', TransactionListView.as_view(), name='transaction-list'),
    path('transactions/<int:transaction_id>/', TransactionDetailView.as_view(), name='transaction-detail'),
    path('reports/', ReportView.as_view(), name='report'),
    path('currencies/', UserCurrencyViewSet.as_view(), name='currency-list-create'),
    path('currencies/<str:currency>/', UserCurrencyViewSet.as_view(), name='currency-delete'),
]