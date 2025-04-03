import 'package:flutter/material.dart';
import 'package:aia_wallet/services/api_service.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:aia_wallet/widgets/drawer.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/theme_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _categoryController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
      // Fetch custom categories from API
      final List<Map<String, dynamic>> customCategories = await _apiService.getCustomCategories();

      // Define default categories with type assignment
      final defaultCategories = _defaultCategoryNames.map((name) => {
        'id': null, // Null ID for default categories
        'name': name,
        'type': ['salary', 'gift', 'interest', 'other_income'].contains(name) ? 'income' : 'expense',
      }).toList();

      // Combine categories, ensuring no duplicates by name
      _allCategories = [];
      final seenNames = <String>{};

      // Add default categories first
      for (var category in defaultCategories) {
        seenNames.add(category['name']!);
        _allCategories.add(category);
      }

      // Add custom categories, skipping any that match default names
      for (var category in customCategories) {
        if (!seenNames.contains(category['name'])) {
          _allCategories.add(category);
          seenNames.add(category['name']);
        }
      }

      // Update expense and income lists
      setState(() {
        _expenseCategories = _allCategories.where((cat) => cat['type'] == 'expense').toList();
        _incomeCategories = _allCategories.where((cat) => cat['type'] == 'income').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.categoriesLoadFailed(e.toString());
        // Fallback to default categories only
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

  Future<void> _addCategory() async {
    final name = _categoryController.text.trim();
    if (name.isEmpty) {
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
      final newCategory = await _apiService.addCustomCategory(name, _selectedType);
      await _fetchCategories(); // Refresh categories to avoid manual insertion
      _categoryController.clear();
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.categoryAdded(newCategory['name']),
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
      await _apiService.deleteCustomCategory(category['id']);
      await _fetchCategories(); // Refresh categories after deletion
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.categoryDeleted,
      );
      Navigator.pop(context, {'categoryDeleted': true}); // Return result to HomeScreen
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
    return categoryColors[category] ?? Colors.grey.withOpacity(0.8);
  }

  Color _getTypeColor(String type) {
    const typeColors = {'expense': Color(0xFFEF5350), 'income': Color(0xFF4CAF50)};
    return typeColors[type] ?? Colors.grey.withOpacity(0.8);
  }

  String _getCategoryDisplayName(Map<String, dynamic> category) {
    if (_defaultCategoryNames.contains(category['name'])) {
      return AppLocalizations.of(context)!.getCategoryName(category['name']);
    }
    return category['name'];
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
      key: _scaffoldKey,
      drawer: CustomDrawer(currentRoute: '/categories', parentContext: context),
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
            // Custom Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: Icon(
                        Icons.menu,
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
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addCategory(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addCategory,
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