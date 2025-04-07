import 'package:flutter/material.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/theme_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';
import 'package:aia_wallet/providers/transaction_provider.dart';
import '../models/category.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _categoryController = TextEditingController();
  String _selectedType = 'expense';
  List<Map<String, dynamic>> _allCategories = [];
  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _incomeCategories = [];
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _animation;

  static const List<String> _defaultCategoryNames = [
    'food', 'transport', 'housing', 'utilities', 'entertainment', 'healthcare', 'education', 'shopping', 'other_expense',
    'salary', 'gift', 'interest', 'other_income',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final customCategories = transactionProvider.categories;

      final defaultCategories = _defaultCategoryNames.map((name) => {
        'id': null,
        'name': name,
        'type': ['salary', 'gift', 'interest', 'other_income'].contains(name) ? 'income' : 'expense',
      }).toList();

      _allCategories = [];
      final seenNames = <String>{};

      for (var category in defaultCategories) {
        seenNames.add(category['name']!);
        _allCategories.add(category);
      }

      for (var category in customCategories) {
        final categoryMap = {
          'id': category.id,
          'name': category.name,
          'type': category.type,
        };
        if (!seenNames.contains(category.name)) {
          _allCategories.add(categoryMap);
          seenNames.add(category.name);
        }
      }

      setState(() {
        _expenseCategories = _allCategories.where((cat) => cat['type'] == 'expense').toList();
        _incomeCategories = _allCategories.where((cat) => cat['type'] == 'income').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.categoriesLoadFailed(e.toString());
        _allCategories = _defaultCategoryNames.map((name) => {
          'id': null,
          'name': name,
          'type': ['salary', 'gift', 'interest', 'other_income'].contains(name) ? 'income' : 'expense',
        }).toList();
        _expenseCategories = _allCategories.where((cat) => cat['type'] == 'expense').toList();
        _incomeCategories = _allCategories.where((cat) => cat['type'] == 'income').toList();
        _isLoading = false;
      });
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.categoriesLoadFailed(e.toString()),
        isError: true,
      );
    }
  }

  Future<void> _addCategories() async {
    final input = _categoryController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.categoryNameRequired;
      });
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.categoryNameRequired,
        isError: true,
      );
      return;
    }

    // Split input by commas and trim each category name
    final categoryNames = input.split(',').map((name) => name.trim()).where((name) => name.isNotEmpty).toList();

    if (categoryNames.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.categoryNameRequired;
      });
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.categoryNameRequired,
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      for (var name in categoryNames) {
        await transactionProvider.addCategory(name: name, type: _selectedType);
      }
      await _fetchCategories(); // Refresh categories
      _categoryController.clear();
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.categoryAdded(categoryNames.length > 1 ? '${categoryNames.length} categories' : categoryNames.first),
      );
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.categoryAddFailed(e.toString());
      });
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.categoryAddFailed(e.toString()),
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    if (category['id'] == null) {
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.cannotDeleteDefault(category['name']),
        isError: true,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text(AppLocalizations.of(context)!.deleteCategory),
        content: Text(AppLocalizations.of(context)!.deleteCategoryConfirm(category['name'])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.deleteCategory(category['id']);
      await _fetchCategories(); // Refresh the category list
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.categoryDeleted,
      );
      Navigator.pop(context, {'categoryDeleted': true}); // Return result to SettingsScreen
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.categoryDeleteFailed(e.toString());
      });
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.categoryDeleteFailed(e.toString()),
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getCategoryColor(String category) {
    const categoryColors = {
      'food': Color(0xFFEF5350),
      'transport': Color(0xFF42A5F5),
      'housing': Color(0xFFAB47BC),
      'utilities': Color(0xFF26C6DA),
      'entertainment': Color(0xFFFFCA28),
      'healthcare': Color(0xFF4CAF50),
      'education': Color(0xFFFF8A65),
      'shopping': Color(0xFFD4E157),
      'other_expense': Color(0xFF90A4AE),
      'salary': Color(0xFF66BB6A),
      'gift': Color(0xFFF06292),
      'interest': Color(0xFF29B6F6),
      'other_income': Color(0xFF78909C),
    };

    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final categoryLower = category.toLowerCase();

    // Check if the category is a default category
    if (categoryColors.containsKey(categoryLower)) {
      return categoryColors[categoryLower]!;
    }

    // For custom categories, use the color from TransactionProvider
    return transactionProvider.customCategoryColors[categoryLower] ?? Colors.grey.withOpacity(0.8);
  }

  Color _getTypeColor(String type) {
    const typeColors = {'expense': Color(0xFFEF5350), 'income': Color(0xFF4CAF50)};
    return typeColors[type] ?? Colors.grey.withOpacity(0.8);
  }

  String _getCategoryDisplayName(Map<String, dynamic> category) {
    if (_defaultCategoryNames.contains(category['name'])) {
      return AppLocalizations.of(context)!.getCategoryName(category['name']);
    }
    return category['name'].toString().replaceAll('_', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final logoPath = themeProvider.getLogoPath(context);
    List<Map<String, dynamic>> _categories = _selectedType == 'expense' ? _expenseCategories : _incomeCategories;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkSurface]
                : [AppColors.lightBackground, AppColors.lightSurface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          logoPath,
                          height: 40,
                          width: 40,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'MON',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              TextSpan(
                                text: 'ey',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.normal,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.categories,
                  style: AppTextStyles.heading(context).copyWith(fontSize: 18),
                ),
              ),
            ),
            Divider(
              color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
              thickness: 1,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = 'expense';
                          });
                          _animationController.forward(from: 0);
                        },
                        child: Container(
                          width: 90,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: _selectedType == 'expense'
                                ? _getTypeColor('expense').withOpacity(0.8 + 0.2 * _animation.value)
                                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                size: 18,
                                color: _selectedType == 'expense'
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.expense,
                                style: TextStyle(
                                  color: _selectedType == 'expense'
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = 'income';
                          });
                          _animationController.forward(from: 0);
                        },
                        child: Container(
                          width: 90,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: _selectedType == 'income'
                                ? _getTypeColor('income').withOpacity(0.8 + 0.2 * _animation.value)
                                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                size: 18,
                                color: _selectedType == 'income'
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.incomeFilter,
                                style: TextStyle(
                                  color: _selectedType == 'income'
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _categoryController,
                      decoration: AppInputStyles.textField(context).copyWith(
                        labelText: AppLocalizations.of(context)!.newCategory,
                        prefixIcon: const Icon(Icons.category, size: 24),
                        hintText: 'e.g., travel, bills, bonus', // Hint for multiple categories
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addCategories(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addCategories,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.add, size: 24),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.body(context).copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isCustom = category['id'] != null;
                  return ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category['name']),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(_getCategoryDisplayName(category)),
                    trailing: isCustom
                        ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCategory(category),
                    )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}