from rest_framework import serializers
from .models import User, Transaction, CategoryAmount, UserCurrency

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'password']
        extra_kwargs = {
            'password': {'write_only': True},
            'id': {'read_only': True}
        }

class UserCurrencySerializer(serializers.ModelSerializer):
    class Meta:
        model = UserCurrency
        fields = ['currency']
        read_only_fields = ['user']

    def validate_currency(self, value):
        """Ensure the currency code is a valid 3-letter code and not KGS (since KGS is default)."""
        currency = value.upper()
        if len(currency) != 3:
            raise serializers.ValidationError("Currency code must be a 3-letter code (e.g., USD).")
        if currency == 'KGS':
            raise serializers.ValidationError("KGS is included by default and cannot be added explicitly.")
        return currency

class TransactionSerializer(serializers.ModelSerializer):
    username = serializers.SerializerMethodField()

    class Meta:
        model = Transaction
        fields = [
            'id', 'user', 'type', 'category', 'amount', 'description',
            'timestamp', 'username', 'original_currency', 'original_amount'
        ]
        read_only_fields = ['id', 'user', 'timestamp', 'username']

    def get_username(self, obj):
        return obj.user.username

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Amount must be greater than zero")
        return value

    def validate_original_currency(self, value):
        """Validate that the original_currency is one of the user's available currencies."""
        if not value:
            return value  # Allow null/empty values
        user = self.context['request'].user
        available_currencies = list(UserCurrency.objects.filter(user=user).values_list('currency', flat=True))
        available_currencies.append('KGS')  # KGS is always available
        if value not in available_currencies:
            raise serializers.ValidationError(
                f"Invalid original currency. Choose from: {', '.join(available_currencies)}"
            )
        return value

    def validate(self, data):
        transaction_type = data.get('type')
        category = data.get('category')

        income_categories = ['salary', 'gift', 'interest', 'other_income']
        expense_categories = [
            'food', 'transport', 'housing', 'utilities',
            'entertainment', 'healthcare', 'education',
            'shopping', 'other_expense'
        ]

        if transaction_type == 'income' and category not in income_categories:
            raise serializers.ValidationError({
                "category": f"Invalid category for income. Choose from: {', '.join(income_categories)}"
            })

        if transaction_type == 'expense' and category not in expense_categories:
            raise serializers.ValidationError({
                "category": f"Invalid category for expense. Choose from: {', '.join(expense_categories)}"
            })

        return data

class CategoryAmountSerializer(serializers.ModelSerializer):
    class Meta:
        model = CategoryAmount
        fields = ['id', 'user', 'category', 'type', 'amount']
        read_only_fields = ['id', 'user']