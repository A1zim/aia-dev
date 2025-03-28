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
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    income = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    expense = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    is_verified = models.BooleanField(default=False)
    nickname = models.CharField(max_length=150, blank=True, null=True)
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
            self.expires_at = timezone.now() + timezone.timedelta(minutes=15)  # Code expires in 15 minutes
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

# Automatically add default currencies for a new user
@receiver(post_save, sender=User)
def create_default_currencies(sender, instance, created, **kwargs):
    if created:
        default_currencies = ['USD', 'EUR', 'RUB', 'CNY']
        for currency in default_currencies:
            UserCurrency.objects.create(user=instance, currency=currency)

class Transaction(models.Model):
    TRANSACTION_TYPES = (
        ('income', 'Income'),
        ('expense', 'Expense'),
    )
    TYPE_CHOICES = TRANSACTION_TYPES  # Add this as a temporary workaround
    
    CATEGORY_CHOICES = (
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
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    amount = models.DecimalField(max_digits=12, decimal_places=2)  # Amount in KGS
    description = models.TextField(blank=True, null=True)
    timestamp = models.DateTimeField(default=timezone.now)
    original_currency = models.CharField(max_length=3, blank=True, null=True)  # e.g., EUR, USD
    original_amount = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)  # Amount in original currency
    
    def __str__(self):
        return f"{self.type.title()} - {self.category} (${self.amount})"
    
    class Meta:
        ordering = ['-timestamp']
        
class CategoryAmount(models.Model):
    """Track total amounts by category"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='category_amounts')
    category = models.CharField(max_length=20)
    type = models.CharField(max_length=10)
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    
    class Meta:
        unique_together = ['user', 'category', 'type']
        
    def __str__(self):
        return f"{self.user.username} - {self.category} ({self.type}): ${self.amount}"