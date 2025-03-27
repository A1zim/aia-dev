import 'package:flutter/material.dart';

class AppLocalizations {
  // Карта переводов для каждого языка
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'home': 'Home',
      'history': 'History',
      'reports': 'Reports',
      'settings': 'Settings',
      'personalFinance': 'Personal Finance',
      'welcomeBack': 'Welcome Back!',
      'createAccount': 'Create Account',
      'username': 'Username',
      'password': 'Password',
      'emailOptional': 'Email (optional)',
      'pleaseEnterUsername': 'Please enter a username',
      'usernameMinLength': 'Username must be at least 3 characters',
      'pleaseEnterPassword': 'Please enter a password',
      'passwordMinLength': 'Password must be at least 6 characters',
      'pleaseEnterValidEmail': 'Please enter a valid email',
      'login': 'Login',
      'register': 'Register',
      'noAccountRegister': 'Don\'t have an account? Register',
      'haveAccountLogin': 'Already have an account? Login',
      'registeredSuccessfully': 'Registered successfully! Logging you in...',
      'transactionHistory': 'Transaction History',
      'reportsAndInsights': 'Reports and Insights',
      'addTransaction': 'Add Transaction',
      'editTransaction': 'Edit Transaction',
      'logout': 'Logout',
      'confirmLogout': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'undo': 'Undo',
      'edit': 'Edit',
      'delete': 'Delete',
      'deleteTransaction': 'Delete Transaction',
      'confirmDeleteTransaction': 'Are you sure you want to delete this transaction?',
      'transactionActions': 'Transaction Actions',
      'whatToDo': 'What would you like to do?',
      'selectLanguage': 'Select Language',
      'darkMode': 'Dark Mode',
      'enabled': 'Enabled',
      'disabled': 'Disabled',
      'selectCurrency': 'Select Currency',
      'enableFingerprint': 'Enable Fingerprint',
      'languageEnglish': 'English',
      'languageKyrgyz': 'Kyrgyz',
      'languageRussian': 'Russian',
      'currencyUSD': 'USD - US Dollar',
      'currencyEUR': 'EUR - Euro',
      'currencyINR': 'INR - Indian Rupee',
      'description': 'Description',
      'pleaseEnterDescription': 'Please enter a description',
      'amount': 'Amount',
      'pleaseEnterAmount': 'Please enter an amount',
      'pleaseEnterValidAmount': 'Please enter a valid amount',
      'type': 'Type',
      'expense': 'Expense',
      'income': 'Income',
      'category': 'Category',
      'date': 'Date',
      'add': 'Add',
      'update': 'Update',
      'transactionAddedSuccessfully': 'Transaction added successfully',
      'transactionUpdatedSuccessfully': 'Transaction updated successfully',
      'transactionDeleted': 'Transaction deleted',
      'noTransactions': 'No transactions yet',
      'searchTransactions': 'Search Transactions',
      'noTransactionsFound': 'No transactions found',
      'filterTransactions': 'Filter Transactions',
      'filterByType': 'Filter by Type',
      'all': 'All',
      'food': 'Food',
      'transport': 'Transport',
      'housing': 'Housing',
      'utilities': 'Utilities',
      'entertainment': 'Entertainment',
      'healthcare': 'Healthcare',
      'education': 'Education',
      'shopping': 'Shopping',
      'otherExpense': 'Other Expense',
      'salary': 'Salary',
      'gift': 'Gift',
      'interest': 'Interest',
      'otherIncome': 'Other Income',
      'unknown': 'Unknown',
      'balance': 'Balance',
      'total': 'Total',
      'filters': 'Filters',
      'start': 'Start',
      'end': 'End',
      'filterByCategory': 'Filter by Category',
      'categoryWiseSpending': 'Category-wise Spending',
      'monthlySpendingTrends': 'Monthly Spending Trends',
      'noDataForFilters': 'No data available for the selected filters',
      'noDataAvailable': 'No data available', // Новый ключ
      'breakdown': 'Breakdown',
      'amountLabel': 'Amount',
      'totalLabel': 'Total',
      'percentageOfTotal': 'Percentage of Total',
      'jan': 'Jan',
      'feb': 'Feb',
      'mar': 'Mar',
      'apr': 'Apr',
      'may': 'May',
      'jun': 'Jun',
      'jul': 'Jul',
      'aug': 'Aug',
      'sep': 'Sep',
      'oct': 'Oct',
      'nov': 'Nov',
      'dec': 'Dec',
      'january': 'January', // Полные названия месяцев
      'february': 'February',
      'march': 'March',
      'april': 'April',
      'mayFull': 'May', // Полное название для мая совпадает с сокращённым
      'june': 'June',
      'july': 'July',
      'august': 'August',
      'september': 'September',
      'october': 'October',
      'november': 'November',
      'december': 'December',
      'error': 'Error',
      'authenticationFailed': 'Authentication failed',
      'registerFailed': 'Registration failed',
      'loginFailed': 'Login failed',
      'notAuthenticated': 'Not authenticated',
      'sessionExpired': 'Session expired',
      'fetchUserDataFailed': 'Failed to fetch user data',
      'fetchTransactionsFailed': 'Failed to load transactions',
      'addTransactionFailed': 'Failed to add transaction',
      'updateTransactionFailed': 'Failed to update transaction',
      'deleteTransactionFailed': 'Failed to delete transaction',
      'fetchFinancialSummaryFailed': 'Failed to fetch financial summary',
      'fetchReportsFailed': 'Failed to fetch reports',
      'fetchCategoriesFailed': 'Failed to fetch categories',
      'networkError': 'Network error. Please check your connection.',
      'fetchSummaryFailed': 'Failed to load summary',
      'invalidCredentials': 'Invalid username or password',
      'userAlreadyExists': 'User already exists',
      'unknownError': 'An unknown error occurred',
      'defaultNickname': 'User',
      'defaultEmail': 'user@example.com',
      'failedToLoadTransactions': 'Failed to load transactions', // Новый ключ
      'failedToDeleteTransaction': 'Failed to delete transaction', // Новый ключ
      'failedToLoadCategories': 'Failed to load categories', // Новый ключ
      'failedToLoadData': 'Failed to load data', // Новый ключ
    },
    'ky': {
      'home': 'Үй',
      'history': 'Тарых',
      'reports': 'Отчеттор',
      'settings': 'Жөндөөлөр',
      'personalFinance': 'Жеке Финансы',
      'welcomeBack': 'Кош Келиңиз!',
      'createAccount': 'Аккаунт Түзүү',
      'username': 'Колдонуучу Аты',
      'password': 'Сырсөз',
      'emailOptional': 'Email (милдеттүү эмес)',
      'pleaseEnterUsername': 'Колдонуучу атын киргизиңиз',
      'usernameMinLength': 'Колдонуучу аты кеминде 3 символдон турушу керек',
      'pleaseEnterPassword': 'Сырсөздү киргизиңиз',
      'passwordMinLength': 'Сырсөз кеминде 6 символдон турушу керек',
      'pleaseEnterValidEmail': 'Жарактуу email киргизиңиз',
      'login': 'Кирүү',
      'register': 'Катталуу',
      'noAccountRegister': 'Аккаунтуңуз жокпу? Катталыңыз',
      'haveAccountLogin': 'Аккаунтуңуз барбы? Кирүү',
      'registeredSuccessfully': 'Ийгиликтүү катталды! Сизди киргизүүдө...',
      'transactionHistory': 'Транзакция Тарыхы',
      'reportsAndInsights': 'Отчеттор жана Аналитика',
      'addTransaction': 'Транзакцияны Кошуу',
      'editTransaction': 'Транзакцияны Оңдоо',
      'logout': 'Чыгуу',
      'confirmLogout': 'Чыгууну каалайсызбы?',
      'cancel': 'Жокко чыгаруу',
      'confirm': 'Ырастоо',
      'undo': 'Кайтаруу',
      'edit': 'Оңдоо',
      'delete': 'Өчүрүү',
      'deleteTransaction': 'Транзакцияны Өчүрүү',
      'confirmDeleteTransaction': 'Бул транзакцияны өчүрүүнү каалайсызбы?',
      'transactionActions': 'Транзакция Аракеттери',
      'whatToDo': 'Эмне кылгыңыз келет?',
      'selectLanguage': 'Тилди Тандоо',
      'darkMode': 'Караңгы Режим',
      'enabled': 'Иштетилген',
      'disabled': 'Өчүрүлгөн',
      'selectCurrency': 'Валютаны Тандоо',
      'enableFingerprint': 'Манжа Изин Иштетүү',
      'languageEnglish': 'Англисче',
      'languageKyrgyz': 'Кыргызча',
      'languageRussian': 'Орусча',
      'currencyUSD': 'USD - АКШ Доллары',
      'currencyEUR': 'EUR - Евро',
      'currencyINR': 'INR - Индия Рупиясы',
      'description': 'Сүрөттөмө',
      'pleaseEnterDescription': 'Сүрөттөмөнү киргизиңиз',
      'amount': 'Сумма',
      'pleaseEnterAmount': 'Сумманы киргизиңиз',
      'pleaseEnterValidAmount': 'Жарактуу сумманы киргизиңиз',
      'type': 'Түрү',
      'expense': 'Чыгаша',
      'income': 'Киреше',
      'category': 'Категория',
      'date': 'Дата',
      'add': 'Кошуу',
      'update': 'Жаңыртуу',
      'transactionAddedSuccessfully': 'Транзакция ийгиликтүү кошулду',
      'transactionUpdatedSuccessfully': 'Транзакция ийгиликтүү жаңыртылды',
      'transactionDeleted': 'Транзакция өчүрүлдү',
      'noTransactions': 'Азырынча транзакциялар жок',
      'searchTransactions': 'Транзакцияларды Издөө',
      'noTransactionsFound': 'Транзакциялар табылган жок',
      'filterTransactions': 'Транзакцияларды Чыпкалоо',
      'filterByType': 'Түрү боюнча Чыпкалоо',
      'all': 'Баары',
      'food': 'Тамак-аш',
      'transport': 'Транспорт',
      'housing': 'Турак-жай',
      'utilities': 'Коммуналдык кызматтар',
      'entertainment': 'Көңүл ачуу',
      'healthcare': 'Саламаттыкты сактоо',
      'education': 'Билим берүү',
      'shopping': 'Соода',
      'otherExpense': 'Башка Чыгаша',
      'salary': 'Айлык',
      'gift': 'Белек',
      'interest': 'Пайыз',
      'otherIncome': 'Башка Киреше',
      'unknown': 'Белгисиз',
      'balance': 'Баланс',
      'total': 'Жалпы',
      'filters': 'Чыпкалар',
      'start': 'Баштоо',
      'end': 'Аяктоо',
      'filterByCategory': 'Категория боюнча Чыпкалоо',
      'categoryWiseSpending': 'Категориялар боюнча Чыгашалар',
      'monthlySpendingTrends': 'Айлык Чыгаша Тренддери',
      'noDataForFilters': 'Тандалган чыпкалар үчүн маалымат жок',
      'noDataAvailable': 'Маалымат жок', // Новый ключ
      'breakdown': 'Талдоо',
      'amountLabel': 'Сумма',
      'totalLabel': 'Жалпы',
      'percentageOfTotal': 'Жалпынын Пайызы',
      'jan': 'Янв',
      'feb': 'Фев',
      'mar': 'Мар',
      'apr': 'Апр',
      'may': 'Май',
      'jun': 'Июн',
      'jul': 'Июл',
      'aug': 'Авг',
      'sep': 'Сен',
      'oct': 'Окт',
      'nov': 'Ноя',
      'dec': 'Дек',
      'january': 'Январь', // Полные названия месяцев
      'february': 'Февраль',
      'march': 'Март',
      'april': 'Апрель',
      'mayFull': 'Май', // Полное название для мая совпадает с сокращённым
      'june': 'Июнь',
      'july': 'Июль',
      'august': 'Август',
      'september': 'Сентябрь',
      'october': 'Октябрь',
      'november': 'Ноябрь',
      'december': 'Декабрь',
      'error': 'Ката',
      'authenticationFailed': 'Аутентификация ийгиликсиз болду',
      'registerFailed': 'Катталуу ийгиликсиз болду',
      'loginFailed': 'Кирүү ийгиликсиз болду',
      'notAuthenticated': 'Аутентификация болгон жок',
      'sessionExpired': 'Сессиянын мөөнөтү бүттү',
      'fetchUserDataFailed': 'Колдонуучу маалыматын алуу ийгиликсиз болду',
      'fetchTransactionsFailed': 'Транзакцияларды жүктөө мүмкүн болгон жок',
      'addTransactionFailed': 'Транзакцияны кошуу ийгиликсиз болду',
      'updateTransactionFailed': 'Транзакцияны жаңыртуу ийгиликсиз болду',
      'deleteTransactionFailed': 'Транзакцияны өчүрүү ийгиликсиз болду',
      'fetchFinancialSummaryFailed': 'Финансылык жыйындыны алуу ийгиликсиз болду',
      'fetchReportsFailed': 'Отчетторду алуу ийгиликсиз болду',
      'fetchCategoriesFailed': 'Категорияларды алуу ийгиликсиз болду',
      'networkError': 'Тармак катасы. Байланышыңызды текшериңиз.',
      'fetchSummaryFailed': 'Жыйындыны жүктөө мүмкүн болгон жок',
      'invalidCredentials': 'Колдонуучу аты же сырсөз туура эмес',
      'userAlreadyExists': 'Колдонуучу мурунтан эле бар',
      'unknownError': 'Белгисиз ката кетти',
      'defaultNickname': 'Колдонуучу',
      'defaultEmail': 'user@example.com',
      'failedToLoadTransactions': 'Транзакцияларды жүктөө мүмкүн болгон жок', // Новый ключ
      'failedToDeleteTransaction': 'Транзакцияны өчүрүү мүмкүн болгон жок', // Новый ключ
      'failedToLoadCategories': 'Категорияларды жүктөө мүмкүн болгон жок', // Новый ключ
      'failedToLoadData': 'Маалыматты жүктөө мүмкүн болгон жок', // Новый ключ
    },
    'ru': {
      'home': 'Главная',
      'history': 'История',
      'reports': 'Отчеты',
      'settings': 'Настройки',
      'personalFinance': 'Личные Финансы',
      'welcomeBack': 'Добро пожаловать!',
      'createAccount': 'Создать аккаунт',
      'username': 'Имя пользователя',
      'password': 'Пароль',
      'emailOptional': 'Email (опционально)',
      'pleaseEnterUsername': 'Пожалуйста, введите имя пользователя',
      'usernameMinLength': 'Имя пользователя должно содержать минимум 3 символа',
      'pleaseEnterPassword': 'Пожалуйста, введите пароль',
      'passwordMinLength': 'Пароль должен содержать минимум 6 символов',
      'pleaseEnterValidEmail': 'Пожалуйста, введите действительный email',
      'login': 'Войти',
      'register': 'Зарегистрироваться',
      'noAccountRegister': 'Нет аккаунта? Зарегистрируйтесь',
      'haveAccountLogin': 'Уже есть аккаунт? Войдите',
      'registeredSuccessfully': 'Регистрация успешна! Входим в систему...',
      'transactionHistory': 'История Транзакций',
      'reportsAndInsights': 'Отчеты и Аналитика',
      'addTransaction': 'Добавить Транзакцию',
      'editTransaction': 'Редактировать Транзакцию',
      'logout': 'Выйти',
      'confirmLogout': 'Вы уверены, что хотите выйти?',
      'cancel': 'Отмена',
      'confirm': 'Подтвердить',
      'undo': 'Отменить',
      'edit': 'Редактировать',
      'delete': 'Удалить',
      'deleteTransaction': 'Удалить Транзакцию',
      'confirmDeleteTransaction': 'Вы уверены, что хотите удалить эту транзакцию?',
      'transactionActions': 'Действия с Транзакцией',
      'whatToDo': 'Что вы хотите сделать?',
      'selectLanguage': 'Выбрать Язык',
      'darkMode': 'Темный Режим',
      'enabled': 'Включено',
      'disabled': 'Отключено',
      'selectCurrency': 'Выбрать Валюту',
      'enableFingerprint': 'Включить Отпечаток Пальца',
      'languageEnglish': 'Английский',
      'languageKyrgyz': 'Кыргызский',
      'languageRussian': 'Русский',
      'currencyUSD': 'USD - Доллар США',
      'currencyEUR': 'EUR - Евро',
      'currencyINR': 'INR - Индийская Рупия',
      'description': 'Описание',
      'pleaseEnterDescription': 'Пожалуйста, введите описание',
      'amount': 'Сумма',
      'pleaseEnterAmount': 'Пожалуйста, введите сумму',
      'pleaseEnterValidAmount': 'Пожалуйста, введите действительную сумму',
      'type': 'Тип',
      'expense': 'Расход',
      'income': 'Доход',
      'category': 'Категория',
      'date': 'Дата',
      'add': 'Добавить',
      'update': 'Обновить',
      'transactionAddedSuccessfully': 'Транзакция успешно добавлена',
      'transactionUpdatedSuccessfully': 'Транзакция успешно обновлена',
      'transactionDeleted': 'Транзакция удалена',
      'noTransactions': 'Пока нет транзакций',
      'searchTransactions': 'Поиск Транзакций',
      'noTransactionsFound': 'Транзакции не найдены',
      'filterTransactions': 'Фильтровать Транзакции',
      'filterByType': 'Фильтровать по Типу',
      'all': 'Все',
      'food': 'Еда',
      'transport': 'Транспорт',
      'housing': 'Жилье',
      'utilities': 'Коммунальные услуги',
      'entertainment': 'Развлечения',
      'healthcare': 'Здравоохранение',
      'education': 'Образование',
      'shopping': 'Покупки',
      'otherExpense': 'Другие Расходы',
      'salary': 'Зарплата',
      'gift': 'Подарок',
      'interest': 'Процент',
      'otherIncome': 'Другие Доходы',
      'unknown': 'Неизвестно',
      'balance': 'Баланс',
      'total': 'Итого',
      'filters': 'Фильтры',
      'start': 'Начало',
      'end': 'Конец',
      'filterByCategory': 'Фильтровать по Категории',
      'categoryWiseSpending': 'Расходы по Категориям',
      'monthlySpendingTrends': 'Месячные Тренды Расходов',
      'noDataForFilters': 'Нет данных для выбранных фильтров',
      'noDataAvailable': 'Данные отсутствуют', // Новый ключ
      'breakdown': 'Анализ',
      'amountLabel': 'Сумма',
      'totalLabel': 'Итого',
      'percentageOfTotal': 'Процент от Итого',
      'jan': 'Янв',
      'feb': 'Фев',
      'mar': 'Мар',
      'apr': 'Апр',
      'may': 'Май',
      'jun': 'Июн',
      'jul': 'Июл',
      'aug': 'Авг',
      'sep': 'Сен',
      'oct': 'Окт',
      'nov': 'Ноя',
      'dec': 'Дек',
      'january': 'Январь', // Полные названия месяцев
      'february': 'Февраль',
      'march': 'Март',
      'april': 'Апрель',
      'mayFull': 'Май', // Полное название для мая совпадает с сокращённым
      'june': 'Июнь',
      'july': 'Июль',
      'august': 'Август',
      'september': 'Сентябрь',
      'october': 'Октябрь',
      'november': 'Ноябрь',
      'december': 'Декабрь',
      'error': 'Ошибка',
      'authenticationFailed': 'Ошибка аутентификации',
      'registerFailed': 'Ошибка регистрации',
      'loginFailed': 'Ошибка входа',
      'notAuthenticated': 'Не аутентифицирован',
      'sessionExpired': 'Сессия истекла',
      'fetchUserDataFailed': 'Не удалось получить данные пользователя',
      'fetchTransactionsFailed': 'Не удалось загрузить транзакции',
      'addTransactionFailed': 'Не удалось добавить транзакцию',
      'updateTransactionFailed': 'Не удалось обновить транзакцию',
      'deleteTransactionFailed': 'Не удалось удалить транзакцию',
      'fetchFinancialSummaryFailed': 'Не удалось получить финансовую сводку',
      'fetchReportsFailed': 'Не удалось получить отчеты',
      'fetchCategoriesFailed': 'Не удалось получить категории',
      'networkError': 'Ошибка сети. Пожалуйста, проверьте подключение.',
      'fetchSummaryFailed': 'Не удалось загрузить сводку',
      'invalidCredentials': 'Неверное имя пользователя или пароль',
      'userAlreadyExists': 'Пользователь уже существует',
      'unknownError': 'Произошла неизвестная ошибка',
      'defaultNickname': 'Пользователь',
      'defaultEmail': 'user@example.com',
      'failedToLoadTransactions': 'Не удалось загрузить транзакции', // Новый ключ
      'failedToDeleteTransaction': 'Не удалось удалить транзакцию', // Новый ключ
      'failedToLoadCategories': 'Не удалось загрузить категории', // Новый ключ
      'failedToLoadData': 'Не удалось загрузить данные', // Новый ключ
    },
  };

  // Делегат для локализации
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Текущий код языка
  final String _languageCode;

  // Приватный конструктор
  AppLocalizations._(this._languageCode);

  // Метод загрузки локализации
  static Future<AppLocalizations> load(Locale locale) async {
    // Проверяем, поддерживается ли язык, если нет — используем 'en' по умолчанию
    final languageCode = _translations.containsKey(locale.languageCode)
        ? locale.languageCode
        : 'en';
    debugPrint('AppLocalizations: Loading locale for language code: $languageCode');
    return AppLocalizations._(languageCode);
  }

  // Метод для получения экземпляра AppLocalizations из контекста
  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (localizations == null) {
      debugPrint('AppLocalizations: Warning - Localizations not found in context');
      throw Exception('AppLocalizations not found in context');
    }
    return localizations;
  }

  // Метод для получения списка поддерживаемых языков
  static List<String> get supportedLanguages => _translations.keys.toList();

  // Общий метод для получения перевода с обработкой ошибок
  String _getTranslation(String key) {
    final translation = _translations[_languageCode]?[key];
    if (translation == null) {
      debugPrint('AppLocalizations: Translation not found for key "$key" in language "$_languageCode"');
      // Возвращаем ключ как запасной вариант
      return key;
    }
    return translation;
  }

  // Геттеры для доступа к переводам
  String get home => _getTranslation('home');
  String get history => _getTranslation('history');
  String get reports => _getTranslation('reports');
  String get settings => _getTranslation('settings');
  String get personalFinance => _getTranslation('personalFinance');
  String get welcomeBack => _getTranslation('welcomeBack');
  String get createAccount => _getTranslation('createAccount');
  String get username => _getTranslation('username');
  String get password => _getTranslation('password');
  String get emailOptional => _getTranslation('emailOptional');
  String get pleaseEnterUsername => _getTranslation('pleaseEnterUsername');
  String get usernameMinLength => _getTranslation('usernameMinLength');
  String get pleaseEnterPassword => _getTranslation('pleaseEnterPassword');
  String get passwordMinLength => _getTranslation('passwordMinLength');
  String get pleaseEnterValidEmail => _getTranslation('pleaseEnterValidEmail');
  String get login => _getTranslation('login');
  String get register => _getTranslation('register');
  String get noAccountRegister => _getTranslation('noAccountRegister');
  String get haveAccountLogin => _getTranslation('haveAccountLogin');
  String get registeredSuccessfully => _getTranslation('registeredSuccessfully');
  String get transactionHistory => _getTranslation('transactionHistory');
  String get reportsAndInsights => _getTranslation('reportsAndInsights');
  String get addTransaction => _getTranslation('addTransaction');
  String get editTransaction => _getTranslation('editTransaction');
  String get logout => _getTranslation('logout');
  String get confirmLogout => _getTranslation('confirmLogout');
  String get cancel => _getTranslation('cancel');
  String get confirm => _getTranslation('confirm');
  String get undo => _getTranslation('undo');
  String get edit => _getTranslation('edit');
  String get delete => _getTranslation('delete');
  String get deleteTransaction => _getTranslation('deleteTransaction');
  String get confirmDeleteTransaction => _getTranslation('confirmDeleteTransaction');
  String get transactionActions => _getTranslation('transactionActions');
  String get whatToDo => _getTranslation('whatToDo');
  String get selectLanguage => _getTranslation('selectLanguage');
  String get darkMode => _getTranslation('darkMode');
  String get enabled => _getTranslation('enabled');
  String get disabled => _getTranslation('disabled');
  String get selectCurrency => _getTranslation('selectCurrency');
  String get enableFingerprint => _getTranslation('enableFingerprint');
  String get languageEnglish => _getTranslation('languageEnglish');
  String get languageKyrgyz => _getTranslation('languageKyrgyz');
  String get languageRussian => _getTranslation('languageRussian');
  String get currencyUSD => _getTranslation('currencyUSD');
  String get currencyEUR => _getTranslation('currencyEUR');
  String get currencyINR => _getTranslation('currencyINR');
  String get description => _getTranslation('description');
  String get pleaseEnterDescription => _getTranslation('pleaseEnterDescription');
  String get amount => _getTranslation('amount');
  String get pleaseEnterAmount => _getTranslation('pleaseEnterAmount');
  String get pleaseEnterValidAmount => _getTranslation('pleaseEnterValidAmount');
  String get type => _getTranslation('type');
  String get expense => _getTranslation('expense');
  String get income => _getTranslation('income');
  String get category => _getTranslation('category');
  String get date => _getTranslation('date');
  String get add => _getTranslation('add');
  String get update => _getTranslation('update');
  String get transactionAddedSuccessfully => _getTranslation('transactionAddedSuccessfully');
  String get transactionUpdatedSuccessfully => _getTranslation('transactionUpdatedSuccessfully');
  String get transactionDeleted => _getTranslation('transactionDeleted');
  String get noTransactions => _getTranslation('noTransactions');
  String get searchTransactions => _getTranslation('searchTransactions');
  String get noTransactionsFound => _getTranslation('noTransactionsFound');
  String get filterTransactions => _getTranslation('filterTransactions');
  String get filterByType => _getTranslation('filterByType');
  String get all => _getTranslation('all');
  String get food => _getTranslation('food');
  String get transport => _getTranslation('transport');
  String get housing => _getTranslation('housing');
  String get utilities => _getTranslation('utilities');
  String get entertainment => _getTranslation('entertainment');
  String get healthcare => _getTranslation('healthcare');
  String get education => _getTranslation('education');
  String get shopping => _getTranslation('shopping');
  String get otherExpense => _getTranslation('otherExpense');
  String get salary => _getTranslation('salary');
  String get gift => _getTranslation('gift');
  String get interest => _getTranslation('interest');
  String get otherIncome => _getTranslation('otherIncome');
  String get unknown => _getTranslation('unknown');
  String get balance => _getTranslation('balance');
  String get total => _getTranslation('total');
  String get filters => _getTranslation('filters');
  String get start => _getTranslation('start');
  String get end => _getTranslation('end');
  String get filterByCategory => _getTranslation('filterByCategory');
  String get categoryWiseSpending => _getTranslation('categoryWiseSpending');
  String get monthlySpendingTrends => _getTranslation('monthlySpendingTrends');
  String get noDataForFilters => _getTranslation('noDataForFilters');
  String get noDataAvailable => _getTranslation('noDataAvailable'); // Новый геттер
  String get breakdown => _getTranslation('breakdown');
  String get amountLabel => _getTranslation('amountLabel');
  String get totalLabel => _getTranslation('totalLabel');
  String get percentageOfTotal => _getTranslation('percentageOfTotal');
  String get jan => _getTranslation('jan');
  String get feb => _getTranslation('feb');
  String get mar => _getTranslation('mar');
  String get apr => _getTranslation('apr');
  String get may => _getTranslation('may');
  String get jun => _getTranslation('jun');
  String get jul => _getTranslation('jul');
  String get aug => _getTranslation('aug');
  String get sep => _getTranslation('sep');
  String get oct => _getTranslation('oct');
  String get nov => _getTranslation('nov');
  String get dec => _getTranslation('dec');
  String get january => _getTranslation('january'); // Полные названия месяцев
  String get february => _getTranslation('february');
  String get march => _getTranslation('march');
  String get april => _getTranslation('april');
  String get mayFull => _getTranslation('mayFull');
  String get june => _getTranslation('june');
  String get july => _getTranslation('july');
  String get august => _getTranslation('august');
  String get september => _getTranslation('september');
  String get october => _getTranslation('october');
  String get november => _getTranslation('november');
  String get december => _getTranslation('december');
  String get error => _getTranslation('error');
  String get authenticationFailed => _getTranslation('authenticationFailed');
  String get registerFailed => _getTranslation('registerFailed');
  String get loginFailed => _getTranslation('loginFailed');
  String get notAuthenticated => _getTranslation('notAuthenticated');
  String get sessionExpired => _getTranslation('sessionExpired');
  String get fetchUserDataFailed => _getTranslation('fetchUserDataFailed');
  String get fetchTransactionsFailed => _getTranslation('fetchTransactionsFailed');
  String get addTransactionFailed => _getTranslation('addTransactionFailed');
  String get updateTransactionFailed => _getTranslation('updateTransactionFailed');
  String get deleteTransactionFailed => _getTranslation('deleteTransactionFailed');
  String get fetchFinancialSummaryFailed => _getTranslation('fetchFinancialSummaryFailed');
  String get fetchReportsFailed => _getTranslation('fetchReportsFailed');
  String get fetchCategoriesFailed => _getTranslation('fetchCategoriesFailed');
  String get networkError => _getTranslation('networkError');
  String get fetchSummaryFailed => _getTranslation('fetchSummaryFailed');
  String get invalidCredentials => _getTranslation('invalidCredentials');
  String get userAlreadyExists => _getTranslation('userAlreadyExists');
  String get unknownError => _getTranslation('unknownError');
  String get defaultNickname => _getTranslation('defaultNickname');
  String get defaultEmail => _getTranslation('defaultEmail');
  String get failedToLoadTransactions => _getTranslation('failedToLoadTransactions'); // Новый геттер
  String get failedToDeleteTransaction => _getTranslation('failedToDeleteTransaction'); // Новый геттер
  String get failedToLoadCategories => _getTranslation('failedToLoadCategories'); // Новый геттер
  String get failedToLoadData => _getTranslation('failedToLoadData'); // Новый геттер
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ky', 'ru'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}