from django.contrib import admin
from .models import User, Transaction, CategoryAmount

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ['username', 'email', 'balance', 'income', 'expense']
    search_fields = ['username', 'email']
    readonly_fields = ['date_joined', 'last_login']

@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ['user', 'type', 'category', 'amount', 'timestamp']
    list_filter = ['type', 'category', 'timestamp']
    search_fields = ['name', 'description', 'user__username']
    date_hierarchy = 'timestamp'

@admin.register(CategoryAmount)
class CategoryAmountAdmin(admin.ModelAdmin):
    list_display = ['user', 'category', 'type', 'amount']
    list_filter = ['type', 'category']
    search_fields = ['user__username']