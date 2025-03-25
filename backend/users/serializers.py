from rest_framework import serializers
from .models import User, Transaction, CategoryAmount

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'password']
        extra_kwargs = {
            'password': {'write_only': True},
            'id': {'read_only': True}
        }

class TransactionSerializer(serializers.ModelSerializer):
    username = serializers.SerializerMethodField()

    class Meta:
        model = Transaction
        fields = ['id', 'user', 'type', 'category', 'amount', 'description', 'timestamp', 'username']
        read_only_fields = ['id', 'user', 'timestamp', 'username']

    def get_username(self, obj):
        return obj.user.username

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Amount must be greater than zero")
        return value

    def validate(self, data):
        transaction_type = data.get('type')
        category = data.get('category')

        income_categories = ['salary', 'gift', 'interest', 'other_income']
        expense_categories = ['food', 'transport', 'housing', 'utilities',
                             'entertainment', 'healthcare', 'education',
                             'shopping', 'other_expense']

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