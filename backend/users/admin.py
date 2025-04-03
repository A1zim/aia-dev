# users/admin.py
from django.contrib import admin
from .models import User, VerificationCode, UserCurrency, UserCategory, Transaction, CategoryAmount

@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ('user', 'type', 'get_category', 'amount', 'timestamp')  # Use get_category method
    list_filter = ('type', 'default_category', 'custom_category__name')     # Update filters
    search_fields = ('user__username', 'description', 'default_category', 'custom_category__name')
    ordering = ('-timestamp',)

    def get_category(self, obj):
        """Display the effective category in the admin list view"""
        return obj.get_category()
    get_category.short_description = 'Category'  # Column header in admin

# Register other models as needed
@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('username', 'email', 'is_verified', 'balance', 'income', 'expense')
    list_filter = ('is_verified',)
    search_fields = ('username', 'email')

@admin.register(VerificationCode)
class VerificationCodeAdmin(admin.ModelAdmin):
    list_display = ('user', 'code', 'created_at', 'expires_at')
    search_fields = ('user__username',)

@admin.register(UserCurrency)
class UserCurrencyAdmin(admin.ModelAdmin):
    list_display = ('user', 'currency')
    search_fields = ('user__username', 'currency')

@admin.register(UserCategory)
class UserCategoryAdmin(admin.ModelAdmin):
    list_display = ('user', 'name', 'type')
    list_filter = ('type',)
    search_fields = ('user__username', 'name')

@admin.register(CategoryAmount)
class CategoryAmountAdmin(admin.ModelAdmin):
    list_display = ('user', 'category', 'type', 'amount')
    list_filter = ('type',)
    search_fields = ('user__username', 'category')