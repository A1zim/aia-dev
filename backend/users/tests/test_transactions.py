from decimal import Decimal
from django.test import TestCase
from django.urls import reverse
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework import status
from users.models import Transaction, CategoryAmount

class TransactionAPITestCase(TestCase):
    def setUp(self):
        # Create test user
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        # Create test transactions
        Transaction.objects.create(
            user=self.user,
            type='income',
            category='salary',
            amount=Decimal('1000.00'),
            name='Monthly Salary'
        )
        
        Transaction.objects.create(
            user=self.user,
            type='expense',
            category='food',
            amount=Decimal('50.00'),
            name='Groceries'
        )
        
        # Set up API client
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)
        
    def test_get_transactions_list(self):
        """Test retrieving a list of transactions"""
        url = reverse('transaction-list')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 2)
        
    def test_create_transaction(self):
        """Test creating a new transaction"""
        url = reverse('add-transaction')
        data = {
            'type': 'expense',
            'category': 'entertainment',
            'amount': '75.50',
            'name': 'Movie tickets'
        }
        
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Transaction.objects.count(), 3)
        
        # Verify balance was updated correctly
        self.user.refresh_from_db()
        self.assertEqual(self.user.balance, Decimal('874.50'))  # 1000 - 50 - 75.50
        
        # Verify category amount was updated
        category_amount = CategoryAmount.objects.get(
            user=self.user,
            category='entertainment',
            type='expense'
        )
        
        self.assertEqual(category_amount.amount, Decimal('75.50'))
