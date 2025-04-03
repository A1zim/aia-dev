# serializers.py
from rest_framework import serializers
from .models import User, Transaction, CategoryAmount, UserCurrency, UserCategory

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'password', 'is_verified', 'nickname']
        extra_kwargs = {
            'password': {'write_only': True},
            'id': {'read_only': True},
            'is_verified': {'read_only': True},
            'nickname': {'required': False},
        }

class UserCurrencySerializer(serializers.ModelSerializer):
    class Meta:
        model = UserCurrency
        fields = ['currency']
        read_only_fields = ['user']

    def validate_currency(self, value):
        currency = value.upper()
        if len(currency) != 3:
            raise serializers.ValidationError("Currency code must be a 3-letter code (e.g., USD).")
        if currency == 'KGS':
            raise serializers.ValidationError("KGS is included by default and cannot be added explicitly.")
        return currency

class UserCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = UserCategory
        fields = ['id', 'name', 'type']
        read_only_fields = ['user']

    def validate_name(self, value):
        user = self.context['request'].user
        if UserCategory.objects.filter(user=user, name=value).exists():
            raise serializers.ValidationError("This category name already exists for the user.")
        if len(value) > 20:
            raise serializers.ValidationError("Category name must be 20 characters or fewer.")
        return value

class TransactionSerializer(serializers.ModelSerializer):
    username = serializers.SerializerMethodField()
    category = serializers.SerializerMethodField()

    class Meta:
        model = Transaction
        fields = ['id', 'user', 'type', 'default_category', 'custom_category', 'category', 'amount', 'description', 
                  'timestamp', 'username', 'original_currency', 'original_amount']
        read_only_fields = ['id', 'user', 'username', 'category']

    def get_username(self, obj):
        return obj.user.username

    def get_category(self, obj):
        return obj.get_category()

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Amount must be greater than zero")
        return value

    def validate(self, data):
        default_category = data.get('default_category')
        custom_category = data.get('custom_category')
        
        if not default_category and not custom_category:
            raise serializers.ValidationError("Either default_category or custom_category must be provided.")
        if default_category and custom_category:
            raise serializers.ValidationError("Only one of default_category or custom_category can be set.")

        trans_type = data.get('type')
        if custom_category:
            if custom_category.type != trans_type:
                raise serializers.ValidationError("Custom category type must match transaction type.")
            if custom_category.user != self.context['request'].user:
                raise serializers.ValidationError("You can only use your own custom categories.")
        elif default_category:
            income_categories = ['salary', 'gift', 'interest', 'other_income']
            expense_categories = ['food', 'transport', 'housing', 'utilities', 'entertainment', 
                                 'healthcare', 'education', 'shopping', 'other_expense']
            if trans_type == 'income' and default_category not in income_categories:
                raise serializers.ValidationError({"default_category": f"Invalid category for income. Choose from: {', '.join(income_categories)}"})
            if trans_type == 'expense' and default_category not in expense_categories:
                raise serializers.ValidationError({"default_category": f"Invalid category for expense. Choose from: {', '.join(expense_categories)}"})

        return data

class CategoryAmountSerializer(serializers.ModelSerializer):
    class Meta:
        model = CategoryAmount
        fields = ['id', 'user', 'category', 'type', 'amount']
        read_only_fields = ['id', 'user']