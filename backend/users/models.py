# models.py
import string
from django.db import models
from django.contrib.auth.models import AbstractUser
from django.core.validators import MinValueValidator
from django.utils import timezone
from decimal import Decimal
from django.db.models.signals import post_save
from django.dispatch import receiver
import random

class User(AbstractUser):
    """Extended user model with financial tracking and verification capabilities"""
    username = models.CharField(
        max_length=18,
        unique=True,
        help_text='Required. 18 characters or fewer. Letters, digits and @/./+/-/_ only.',
        error_messages={
            'unique': "A user with that username already exists.",
        },
    )
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    income = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    expense = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    is_verified = models.BooleanField(default=False)
    nickname = models.CharField(max_length=18, blank=True, null=True)
    temporary_code = models.CharField(max_length=6, null=True, blank=True)

    groups = models.ManyToManyField(
        'auth.Group',
        related_name='custom_user_groups',
        blank=True,
        help_text='The groups this user belongs to.',
        verbose_name='groups',
    )
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        related_name='custom_user_permissions',
        blank=True,
        help_text='Specific permissions for this user.',
        verbose_name='user permissions',
    )

    def __str__(self):
        return self.username

class VerificationCode(models.Model):
    """Model to store email verification codes"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='verification_code')
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(default=timezone.now)
    expires_at = models.DateTimeField()

    def save(self, *args, **kwargs):
        if not self.code:
            self.code = ''.join(random.choices(string.digits, k=6))
        if not self.expires_at:
            self.expires_at = timezone.now() + timezone.timedelta(minutes=15)
        super().save(*args, **kwargs)

    def is_expired(self):
        return timezone.now() > self.expires_at

    def __str__(self):
        return f"{self.user.username} - {self.code}"

class UserCurrency(models.Model):
    """Model to store currencies selected by each user"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='currencies')
    currency = models.CharField(max_length=3)  # e.g., KGS, USD, EUR

    class Meta:
        unique_together = ['user', 'currency']

    def __str__(self):
        return f"{self.user.username} - {self.currency}"

@receiver(post_save, sender=User)
def create_default_currencies(sender, instance, created, **kwargs):
    if created:
        default_currencies = ['USD', 'EUR', 'RUB', 'CNY']
        for currency in default_currencies:
            UserCurrency.objects.create(user=instance, currency=currency)

class UserCategory(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='custom_categories')
    name = models.CharField(max_length=20, unique=True, blank=True, null=True)
    type = models.CharField(
        max_length=10,
        choices=(('income', 'Income'), ('expense', 'Expense')),
        default='expense'
    )

    class Meta:
        unique_together = ['user', 'name']

    def __str__(self):
        return f"{self.user.username} - {self.name} ({self.type})"

class Transaction(models.Model):
    TRANSACTION_TYPES = (
        ('income', 'Income'),
        ('expense', 'Expense'),
    )
    DEFAULT_CATEGORY_CHOICES = (
        ('salary', 'Salary'),
        ('gift', 'Gift'),
        ('interest', 'Interest'),
        ('other_income', 'Other Income'),
        ('food', 'Food'),
        ('transport', 'Transport'),
        ('housing', 'Housing'),
        ('utilities', 'Utilities'),
        ('entertainment', 'Entertainment'),
        ('healthcare', 'Healthcare'),
        ('education', 'Education'),
        ('shopping', 'Shopping'),
        ('other_expense', 'Other Expense'),
    )
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='transactions')
    type = models.CharField(max_length=10, choices=TRANSACTION_TYPES)
    default_category = models.CharField(max_length=20, choices=DEFAULT_CATEGORY_CHOICES, null=True, blank=True)
    custom_category = models.ForeignKey(UserCategory, on_delete=models.SET_NULL, null=True, blank=True, related_name='transactions')
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    description = models.TextField(blank=True, null=True)
    timestamp = models.DateTimeField()
    original_currency = models.CharField(max_length=3, blank=True, null=True)
    original_amount = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)

    def get_category(self):
        if self.custom_category:
            return self.custom_category.name
        return self.default_category if self.default_category else 'Uncategorized'

    def __str__(self):
        category = self.get_category()
        return f"{self.type.title()} - {category} (${self.amount})"

    class Meta:
        ordering = ['-timestamp']

class CategoryAmount(models.Model):
    """Track total amounts by category (both default and custom)"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='category_amounts')
    category = models.CharField(max_length=20)  # Stores the category name (default or custom)
    type = models.CharField(max_length=10)
    amount = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))

    class Meta:
        unique_together = ['user', 'category', 'type']

    def __str__(self):
        return f"{self.user.username} - {self.category} ({self.type}): ${self.amount}"