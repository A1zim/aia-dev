import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Personal Finance',
      'settingsTitle': 'Settings',
      'darkMode': 'Dark Mode',
      'darkModeEnabled': 'Enabled',
      'darkModeDisabled': 'Disabled',
      'selectCurrency': 'Select Currency',
      'selectLanguage': 'Select Language',
      'logout': 'Logout',
      'logoutConfirm': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'no':'no',
      'confirmLogout': 'Logout',
      'currencyChanged': 'Currency changed to {currency}',
      'currencyChangeFailed': 'Failed to update currency: {error}',
      'addTransaction': 'Add Transaction',
      'editTransaction': 'Edit Transaction',
      'description': 'Description',
      'descriptionRequired': 'Please enter a description',
      'amount': 'Amount',
      'amountRequired': 'Please enter an amount',
      'amountInvalid': 'Please enter a valid amount',
      'currency': 'Currency',
      'amountInKGS': 'Amount in KGS',
      'type': 'Type',
      'category': 'Category',
      'date': 'Date',
      'add': 'Add',
      'update': 'Update',
      'transactionAdded': 'Transaction added successfully!',
      'transactionUpdated': 'Transaction updated successfully!',
      'networkError': 'Network error: Unable to reach the server. Please check your internet connection.',
      'languageEnglish': 'English',
      'languageKyrgyz': 'Kyrgyz',
      'languageRussian': 'Russian',
      'home': 'Home',
      'profile': 'Profile',
      'errorLoadingUserData': 'Error loading user data',
      'history': 'History',
      'reports': 'Reports',
      'changePassword': 'Change Password',
      'oldPassword': 'Old Password',
      'newPassword': 'New Password',
      'confirm': 'Confirm',
      'yes':'Yes',
      'save': 'Save',
      'enterNewNickname': 'Enter new nickname',
      'notSet': 'Not set',
      'nickname': 'Nickname',
      'username': 'Username',
      'email': 'Email',
      'balance': 'Balance',
      'income': 'Income',
      'expenses': 'Expenses',
      'nicknameUpdated': 'Nickname updated successfully! 🎉',
      'nicknameUpdateFailed': 'Failed to update nickname: {error} 😓',
      'passwordChanged': 'Password changed successfully! 🔒',
      'passwordChangeFailed': 'Failed to change password: {error} 😓',
      'summaryLoadFailed': 'Failed to load summary: {error}',
      'manageCurrencies': 'Manage Currencies',
      'deleteCurrency': 'Delete Currency',
      'delete': 'Delete',
      'retry': 'Retry',
      'searchCurrencyOrCountry': 'Search by Currency or Country (e.g., JPY or Japan)',
      'currencyAdded': '{currency} added successfully',
      'currencyDeleted': '{currency} deleted successfully',
      'cannotDeleteKGS': 'Cannot delete KGS',
      'currencyExists': '{currency} already exists for this user',
      'kgsDefault': 'KGS is included by default and cannot be added',
      'deleteConfirm': 'Are you sure you want to delete {currency}?',
      'currenciesLoadFailed': 'Failed to load currencies: {error}',
      'recents': 'Recents',
      'noTransactions': 'No transactions yet.',
      'transactionsLoadFailed': 'Failed to load transactions: {error}',
      'transactionHistory': 'Transaction History',
      'searchTransactions': 'Search Transactions',
      'noTransactionsFound': 'No transactions found',
      'deleteTransaction': 'Delete Transaction',
      'deleteTransactionConfirm': 'Are you sure you want to delete this transaction?',
      'transactionDeleted': 'Transaction deleted',
      'deleteTransactionFailed': 'Failed to delete transaction: {error}',
      'all': 'All',
      'expense': 'Expense',
      'incomeFilter': 'Income',
      'undo': 'Undo',
      'welcomeBack': 'Welcome!',
      'createAccount': 'Create Account',
      'verifyYourEmail': 'Verify Your Email',
      'login': 'Login',
      'register': 'Register',
      'verify': 'Verify',
      'usernameRequired': 'Please enter a username',
      'usernameTooShort': 'Username must be at least 3 characters',
      'password': 'Password',
      'passwordRequired': 'Please enter a password',
      'passwordTooShort': 'Password must be at least 6 characters',
      'emailRequired': 'Please enter an email',
      'emailInvalid': 'Please enter a valid email',
      'dontHaveAccount': "Don't have an account? Register",
      'alreadyHaveAccount': 'Already have an account? Login',
      'forgotPassword': 'Forgot Password?',
      'forgotPasswordTitle': 'Forgot Password',
      'forgotPasswordPrompt': 'Enter your email to receive a 6-digit code.',
      'sendCode': 'Send Code',
      'loginSuccessful': 'Login successful! 🎉',
      'codeSentToEmail': 'A 6-digit code has been sent to your email. 📧',
      'emailVerified': 'Email verified successfully! Logging you in... 🎉',
      'codeSentForLogin': 'A 6-digit code has been sent to your email. Use it to log in! 📧',
      'backToRegistration': 'Back to Registration',
      'enterCodePrompt': 'Enter the 6-digit code sent to {email}',
      'codeRequired': 'Please enter the full 6-digit code',
      'reportsAndInsights': 'Reports & Insights',
      'total': 'Total',
      'filters': 'Filters',
      'startDate': 'Start Date',
      'endDate': 'End Date',
      'clearFilters': 'Clear Filters',
      'categoryWiseSpending': 'Category-wise Spending',
      'monthlySpendingTrends': 'Monthly Spending Trends',
      'noDataAvailable': 'No data available',
      'unknown': 'Unknown',
      'percentage': 'Percentage',
      'details': 'Details',
      'failedToLoadData': 'Failed to load data: {error}',
      'failedToLoadCategories': 'Failed to load categories: {error}',
      'currencyConversionError': 'Failed to convert currency: {error}',
      // Category translations
      'food': 'Food',
      'transport': 'Transport',
      'housing': 'Housing',
      'utilities': 'Utilities',
      'entertainment': 'Entertainment',
      'healthcare': 'Healthcare',
      'education': 'Education',
      'shopping': 'Shopping',
      'other_expense': 'Other Expense',
      'salary': 'Salary',
      'gift': 'Gift',
      'interest': 'Interest',
      'other_income': 'Other Income',
      "clear": "Clear",
      "clearData": "Clear All Data",
      "clearDataConfirm": "Are you sure you want to clear all your financial data? This action cannot be undone. Please enter your password to confirm.",
      "enterPassword": "Enter Password",
      "dataCleared": "All data has been cleared successfully.",
      "clearDataFailed": "Failed to clear data: %s",
      "usernameTaken" : "Username is available",
      "usernameAvailable": "Username is already taken",
      "codeInvalid": "Invalid code",
      "fillAllFields": "Не правильный код",
      "enterValidCode": "Не правильный код",
      "resetPasswordSent" : "Reset password sent",
      "transactionFailed" : "transactionFailed",
      "today" : "Today",
      "yesterday" : "Yesterday",

    },
    'ky': {
      'appTitle': 'Жеке Финансы',
      'settingsTitle': 'Жөндөөлөр',
      'darkMode': 'Караңгы Режим',
      'darkModeEnabled': 'Иштетилген',
      'darkModeDisabled': 'Өчүрүлгөн',
      'selectCurrency': 'Валюта Тандоо',
      'selectLanguage': 'Тил Тандоо',
      'logout': 'Чыгуу',
      'logoutConfirm': 'Чыгууну каалайсызбы?',
      'cancel': 'Калтыруу',
      'no':'Жок',
      'confirmLogout': 'Чыгуу',
      'currencyChanged': 'Валюта {currency} болуп өзгөртүлдү',
      'currencyChangeFailed': 'Валютаны өзгөртүү ишке ашкан жок: {error}',
      'addTransaction': 'Транзакция Кошуу',
      'editTransaction': 'Транзакцияны Түзөтүү',
      'description': 'Сүрөттөмө',
      'descriptionRequired': 'Сураныч, сүрөттөмө киргизиңиз',
      'amount': 'Сумма',
      'amountRequired': 'Сураныч, сумманы киргизиңиз',
      'amountInvalid': 'Сураныч, жарактуу сумманы киргизиңиз',
      'currency': 'Валюта',
      'amountInKGS': 'KGSдеги Сумма',
      'type': 'Түрү',
      'category': 'Категория',
      'date': 'Дата',
      'add': 'Кошуу',
      'update': 'Жаңыртуу',
      'transactionAdded': 'Транзакция ийгиликтүү кошулду!',
      'transactionUpdated': 'Транзакция ийгиликтүү жаңыртылды!',
      'networkError': 'Тармак катасы: Серверге жетүү мүмкүн эмес. Интернет байланышыңызды текшериңиз.',
      'languageEnglish': 'Англисче',
      'languageKyrgyz': 'Кыргызча',
      'languageRussian': 'Орусча',
      'home': 'Үй',
      'profile': 'Профиль',
      'errorLoadingUserData': 'Колдонуучу маалыматтарын жүктөөдө ката кетти',
      'history': 'Тарых',
      'reports': 'Отчеттор',
      'changePassword': 'Сырсөздү Өзгөртүү',
      'oldPassword': 'Эски Сырсөз',
      'newPassword': 'Жаңы Сырсөз',
      'confirm': 'Ырастоо',
      'yes':'Ооба',
      'save': 'Сактоо',
      'enterNewNickname': 'Жаңы никнейм киргизиңиз',
      'notSet': 'Орнотулган жок',
      'nickname': 'Никнейми',
      'username': 'Колдонуучунун Аты',
      'email': 'Почта',
      'balance': 'Баланс',
      'income': 'Киреше',
      'expenses': 'Чыгашалар',
      'nicknameUpdated': 'Никнейм ийгиликтүү жаңыртылды! 🎉',
      'nicknameUpdateFailed': 'Никнеймди жаңыртуу ишке ашкан жок: {error} 😓',
      'passwordChanged': 'Сырсөз ийгиликтүү өзгөртүлдү! 🔒',
      'passwordChangeFailed': 'Сырсөздү өзгөртүү ишке ашкан жок: {error} 😓',
      'summaryLoadFailed': 'Жыйынтыкты жүктөө ишке ашкан жок: {error}',
      'manageCurrencies': 'Валюталарды Башкаруу',
      'deleteCurrency': 'Валютаны Жок Кылуу',
      'delete': 'Жок кылуу',
      'retry': 'Кайра аракет кылуу',
      'searchCurrencyOrCountry': 'Валюта же Өлкө боюнча Издөө (мисалы, JPY же Япония)',
      'currencyAdded': '{currency} ийгиликтүү кошулду',
      'currencyDeleted': '{currency} ийгиликтүү жок кылынды',
      'cannotDeleteKGS': 'KGS жок кылынбайт',
      'currencyExists': '{currency} бул колдонуучу үчүн мурунтан эле бар',
      'kgsDefault': 'KGS демейки боюнча камтылган жана кошулбайт',
      'deleteConfirm': '{currency} жок кылууну каалайсызбы?',
      'currenciesLoadFailed': 'Валюталарды жүктөө ишке ашкан жок: {error}',
      'recents': 'Жакынкылар',
      'noTransactions': 'Азырынча транзакциялар жок.',
      'transactionsLoadFailed': 'Транзакцияларды жүктөө ишке ашкан жок: {error}',
      'transactionHistory': 'Транзакция Тарыхы',
      'searchTransactions': 'Транзакцияларды Издөө',
      'noTransactionsFound': 'Транзакциялар табылган жок',
      'deleteTransaction': 'Транзакцияны Жок Кылуу',
      'deleteTransactionConfirm': 'Бул транзакцияны жок кылууну каалайсызбы?',
      'transactionDeleted': 'Транзакция жок кылынды',
      'deleteTransactionFailed': 'Транзакцияны жок кылуу ишке ашкан жок: {error}',
      'all': 'Баары',
      'expense': 'Чыгаша',
      'incomeFilter': 'Киреше',
      'undo': 'Жокко чыгаруу',
      'welcomeBack': 'Кош Келдиңиз!',
      'createAccount': 'Каттоо Эсебин Түзүү',
      'verifyYourEmail': 'Электрондук Почтаңызды Ырастаңыз',
      'login': 'Кирүү',
      'register': 'Катталуу',
      'verify': 'Ырастоо',
      'usernameRequired': 'Сураныч, колдонуучунун атын киргизиңиз',
      'usernameTooShort': 'Колдонуучунун аты кеминде 3 символдон турган болушу керек',
      'password': 'Сырсөз',
      'passwordRequired': 'Сураныч, сырсөздү киргизиңиз',
      'passwordTooShort': 'Сырсөз кеминде 6 символдон турган болушу керек',
      'emailRequired': 'Сураныч, электрондук почтаны киргизиңиз',
      'emailInvalid': 'Сураныч, жарактуу электрондук почтаны киргизиңиз',
      'dontHaveAccount': 'Каттоо эсебиңиз жокпу? Катталыңыз',
      'alreadyHaveAccount': 'Каттоо эсебиңиз барбы? Кириңиз',
      'forgotPassword': 'Сырсөздү Унуттуңузбу?',
      'forgotPasswordTitle': 'Сырсөздү Унуттум',
      'forgotPasswordPrompt': '6 орундуу код алуу үчүн электрондук почтаңызды киргизиңиз.',
      'sendCode': 'Код Жөнөтүү',
      'loginSuccessful': 'Кирүү ийгиликтүү болду! 🎉',
      'codeSentToEmail': '6 орундуу код сиздин электрондук почтаңызга жөнөтүлдү. 📧',
      'emailVerified': 'Электрондук почта ийгиликтүү ырасталды! Сизди киргизүүдө... 🎉',
      'codeSentForLogin': '6 орундуу код сиздин электрондук почтаңызга жөнөтүлдү. Аны кирүү үчүн колдонуңуз! 📧',
      'backToRegistration': 'Каттоого Кайтуу',
      'enterCodePrompt': '{email} жөнөтүлгөн 6 орундуу кодду киргизиңиз',
      'codeRequired': 'Сураныч, толук 6 орундуу кодду киргизиңиз',
      'reportsAndInsights': 'Отчеттор жана Аналитика',
      'total': 'Жалпы',
      'filters': 'Фильтрлер',
      'startDate': 'Башталышы',
      'endDate': 'Аягы',
      'clearFilters': 'Фильтрлерди Тазалоо',
      'categoryWiseSpending': 'Категория боюнча Чыгашалар',
      'monthlySpendingTrends': 'Айлык Чыгаша Тренддери',
      'noDataAvailable': 'Маалымат жок',
      'unknown': 'Белгисиз',
      'percentage': 'Пайыз',
      'details': 'Деталдар',
      'failedToLoadData': 'Маалыматты жүктөө ишке ашкан жок: {error}',
      'failedToLoadCategories': 'Категорияларды жүктөө ишке ашкан жок: {error}',
      'currencyConversionError': 'Валютаны конвертациялоо ишке ашкан жок: {error}',
      // Category translations
      'food': 'Тамак-аш',
      'transport': 'Транспорт',
      'housing': 'Турак жай',
      'utilities': 'Коммуналдык кызматтар',
      'entertainment': 'Көңүл ачуу',
      'healthcare': 'Саламаттыкты сактоо',
      'education': 'Билим берүү',
      'shopping': 'Соода',
      'other_expense': 'Башка чыгаша',
      'salary': 'Айлык акы',
      'gift': 'Белек',
      'interest': 'Пайыз',
      'other_income': 'Башка киреше',
      "clear": "Тазалоо",
      "clearData": "Бардык маалыматты тазалоо",
      "clearDataConfirm": "Сиз чын эле бардык финансылык маалыматыңызды тазалоону каалайсызбы? Бул аракетти кайтаруу мүмкүн эмес. Тазалоону ырастоо үчүн сырсөзүңүздү киргизиңиз.",
      "enterPassword": "Сырсөздү киргизиңиз",
      "dataCleared": "Бардык маалымат ийгиликтүү тазаланды.",
      "clearDataFailed": "Маалыматты тазалоо ишке ашкан жок: %s",
      "usernameTaken" : "Бул ысым бош эмес",
      "usernameAvailable": "Бул ысымды колдонсо болот",
      "codeInvalid": "Туура эмес код",
      "fillAllFields": "Не правильный код",
      "enterValidCode": "Не правильный код",
      "resetPasswordSent" : "Reset password sent",
      "transactionFailed" : "transactionFailed",
      "today" : "Today",
      "yesterday" : "Yesterday",

    },
    'ru': {
      'appTitle': 'Личные Финансы',
      'settingsTitle': 'Настройки',
      'darkMode': 'Темный Режим',
      'darkModeEnabled': 'Включен',
      'darkModeDisabled': 'Отключен',
      'selectCurrency': 'Выбрать Валюту',
      'selectLanguage': 'Выбрать Язык',
      'logout': 'Выйти',
      'logoutConfirm': 'Вы уверены, что хотите выйти?',
      'cancel': 'Отмена',
      'no':'нет',
      'confirmLogout': 'Выйти',
      'currencyChanged': 'Валюта изменена на {currency}',
      'currencyChangeFailed': 'Не удалось обновить валюту: {error}',
      'addTransaction': 'Добавить Транзакцию',
      'editTransaction': 'Редактировать Транзакцию',
      'description': 'Описание',
      'descriptionRequired': 'Пожалуйста, введите описание',
      'amount': 'Сумма',
      'amountRequired': 'Пожалуйста, введите сумму',
      'amountInvalid': 'Пожалуйста, введите действительную сумму',
      'currency': 'Валюта',
      'amountInKGS': 'Сумма в KGS',
      'type': 'Тип',
      'category': 'Категория',
      'date': 'Дата',
      'add': 'Добавить',
      'update': 'Обновить',
      'transactionAdded': 'Транзакция успешно добавлена!',
      'transactionUpdated': 'Транзакция успешно обновлена!',
      'networkError': 'Ошибка сети: Не удалось подключиться к серверу. Проверьте ваше интернет-соединение.',
      'languageEnglish': 'Английский',
      'languageKyrgyz': 'Киргизский',
      'languageRussian': 'Русский',
      'home': 'Главная',
      'profile': 'Профиль',
      'errorLoadingUserData': 'Ошибка загрузки данных пользователя',
      'history': 'История',
      'reports': 'Отчёты',
      'changePassword': 'Изменить Пароль',
      'oldPassword': 'Старый Пароль',
      'newPassword': 'Новый Пароль',
      'confirm': 'Подтвердить',
      'yes':'Да',
      'save': 'Сохранить',
      'enterNewNickname': 'Введите новый никнейм',
      'notSet': 'Не установлено',
      'nickname': 'Никнейм',
      'username': 'Имя Пользователя',
      'email': 'Почта',
      'balance': 'Баланс',
      'income': 'Доход',
      'expenses': 'Расходы',
      'nicknameUpdated': 'Никнейм успешно обновлен! 🎉',
      'nicknameUpdateFailed': 'Не удалось обновить никнейм: {error} 😓',
      'passwordChanged': 'Пароль успешно изменен! 🔒',
      'passwordChangeFailed': 'Не удалось изменить пароль: {error} 😓',
      'summaryLoadFailed': 'Не удалось загрузить сводку: {error}',
      'manageCurrencies': 'Управление Валютами',
      'deleteCurrency': 'Удалить Валюту',
      'delete': 'Удалить',
      'retry': 'Повторить',
      'searchCurrencyOrCountry': 'Поиск по валюте или стране (например, JPY или Япония)',
      'currencyAdded': '{currency} успешно добавлена',
      'currencyDeleted': '{currency} успешно удалена',
      'cannotDeleteKGS': 'Нельзя удалить KGS',
      'currencyExists': '{currency} уже существует для этого пользователя',
      'kgsDefault': 'KGS включена по умолчанию и не может быть добавлена',
      'deleteConfirm': 'Вы уверены, что хотите удалить {currency}?',
      'currenciesLoadFailed': 'Не удалось загрузить валюты: {error}',
      'recents': 'Недавние',
      'noTransactions': 'Транзакций пока нет.',
      'transactionsLoadFailed': 'Не удалось загрузить транзакции: {error}',
      'transactionHistory': 'История Транзакций',
      'searchTransactions': 'Поиск Транзакций',
      'noTransactionsFound': 'Транзакции не найдены',
      'deleteTransaction': 'Удалить Транзакцию',
      'deleteTransactionConfirm': 'Вы уверены, что хотите удалить эту транзакцию?',
      'transactionDeleted': 'Транзакция удалена',
      'deleteTransactionFailed': 'Не удалось удалить транзакцию: {error}',
      'all': 'Все',
      'expense': 'Расход',
      'incomeFilter': 'Доход',
      'undo': 'Отменить',
      'welcomeBack': 'Добро пожаловать!',
      'createAccount': 'Создать Аккаунт',
      'verifyYourEmail': 'Подтвердите Вашу Электронную Почту',
      'login': 'Войти',
      'register': 'Зарегистрироваться',
      'verify': 'Подтвердить',
      'usernameRequired': 'Пожалуйста, введите имя пользователя',
      'usernameTooShort': 'Имя пользователя должно содержать не менее 3 символов',
      'password': 'Пароль',
      'passwordRequired': 'Пожалуйста, введите пароль',
      'passwordTooShort': 'Пароль должен содержать не менее 6 символов',
      'emailRequired': 'Пожалуйста, введите электронную почту',
      'emailInvalid': 'Пожалуйста, введите действительную электронную почту',
      'dontHaveAccount': 'Нет аккаунта? Зарегистрируйтесь',
      'alreadyHaveAccount': 'Уже есть аккаунт? Войдите',
      'forgotPassword': 'Забыли Пароль?',
      'forgotPasswordTitle': 'Забыли Пароль',
      'forgotPasswordPrompt': 'Введите вашу электронную почту для получения 6-значного кода.',
      'sendCode': 'Отправить Код',
      'loginSuccessful': 'Вход выполнен успешно! 🎉',
      'codeSentToEmail': '6-значный код отправлен на вашу электронную почту. 📧',
      'emailVerified': 'Электронная почта успешно подтверждена! Выполняется вход... 🎉',
      'codeSentForLogin': '6-значный код отправлен на вашу электронную почту. Используйте его для входа! 📧',
      'backToRegistration': 'Вернуться к Регистрации',
      'enterCodePrompt': 'Введите 6-значный код, отправленный на {email}',
      'codeRequired': 'Пожалуйста, введите полный 6-значный код',
      'reportsAndInsights': 'Отчёты и Аналитика',
      'total': 'Итого',
      'filters': 'Фильтры',
      'startDate': 'Начало',
      'endDate': 'Конец',
      'clearFilters': 'Очистить Фильтры',
      'categoryWiseSpending': 'Расходы по Категориям',
      'monthlySpendingTrends': 'Тренды Месячных Расходов',
      'noDataAvailable': 'Данные отсутствуют',
      'unknown': 'Неизвестно',
      'percentage': 'Процент',
      'details': 'Детали',
      'failedToLoadData': 'Не удалось загрузить данные: {error}',
      'failedToLoadCategories': 'Не удалось загрузить категории: {error}',
      'currencyConversionError': 'Не удалось конвертировать валюту: {error}',
      // Category translations
      'food': 'Еда',
      'transport': 'Транспорт',
      'housing': 'Жилье',
      'utilities': 'Коммунальные услуги',
      'entertainment': 'Развлечения',
      'healthcare': 'Здравоохранение',
      'education': 'Образование',
      'shopping': 'Покупки',
      'other_expense': 'Другие расходы',
      'salary': 'Зарплата',
      'gift': 'Подарок',
      'interest': 'Процент',
      'other_income': 'Другие доходы',
      "clear": "Очистить",
      "clearData": "Очистить все данные",
      "clearDataConfirm": "Вы уверены, что хотите очистить все ваши финансовые данные? Это действие нельзя отменить. Пожалуйста, введите ваш пароль для подтверждения.",
      "enterPassword": "Введите пароль",
      "dataCleared": "Все данные успешно очищены.",
      "clearDataFailed": "Не удалось очистить данные: %s",
      "usernameTaken" : "Имя пользователя не доступно",
      "usernameAvailable": "Имя пользователя доступно",
      "codeInvalid": "Не правильный код",
      "codeInvalid": "Не правильный код",
      "fillAllFields": "Не правильный код",
      "enterValidCode": "Не правильный код",
      "resetPasswordSent" : "Reset password sent",
      "transactionFailed" : "transactionFailed",
      "today" : "Today",
      "yesterday" : "Yesterday",
    },
  };

  // Getters for all static strings
  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get settingsTitle => _localizedValues[locale.languageCode]!['settingsTitle']!;
  String get darkMode => _localizedValues[locale.languageCode]!['darkMode']!;
  String get darkModeEnabled => _localizedValues[locale.languageCode]!['darkModeEnabled']!;
  String get darkModeDisabled => _localizedValues[locale.languageCode]!['darkModeDisabled']!;
  String get selectCurrency => _localizedValues[locale.languageCode]!['selectCurrency']!;
  String get selectLanguage => _localizedValues[locale.languageCode]!['selectLanguage']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get logoutConfirm => _localizedValues[locale.languageCode]!['logoutConfirm']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get no => _localizedValues[locale.languageCode]!['no']!;
  String get confirmLogout => _localizedValues[locale.languageCode]!['confirmLogout']!;
  String currencyChanged(String currency) =>
      _localizedValues[locale.languageCode]!['currencyChanged']!.replaceAll('{currency}', currency);
  String currencyChangeFailed(String error) =>
      _localizedValues[locale.languageCode]!['currencyChangeFailed']!.replaceAll('{error}', error);
  String get addTransaction => _localizedValues[locale.languageCode]!['addTransaction']!;
  String get editTransaction => _localizedValues[locale.languageCode]!['editTransaction']!;
  String get description => _localizedValues[locale.languageCode]!['description']!;
  String get descriptionRequired => _localizedValues[locale.languageCode]!['descriptionRequired']!;
  String get amount => _localizedValues[locale.languageCode]!['amount']!;
  String get amountRequired => _localizedValues[locale.languageCode]!['amountRequired']!;
  String get amountInvalid => _localizedValues[locale.languageCode]!['amountInvalid']!;
  String get currency => _localizedValues[locale.languageCode]!['currency']!;
  String get amountInKGS => _localizedValues[locale.languageCode]!['amountInKGS']!;
  String get type => _localizedValues[locale.languageCode]!['type']!;
  String get category => _localizedValues[locale.languageCode]!['category']!;
  String get date => _localizedValues[locale.languageCode]!['date']!;
  String get add => _localizedValues[locale.languageCode]!['add']!;
  String get update => _localizedValues[locale.languageCode]!['update']!;
  String get transactionAdded => _localizedValues[locale.languageCode]!['transactionAdded']!;
  String get transactionUpdated => _localizedValues[locale.languageCode]!['transactionUpdated']!;
  String get networkError => _localizedValues[locale.languageCode]!['networkError']!;
  String get languageEnglish => _localizedValues[locale.languageCode]!['languageEnglish']!;
  String get languageKyrgyz => _localizedValues[locale.languageCode]!['languageKyrgyz']!;
  String get languageRussian => _localizedValues[locale.languageCode]!['languageRussian']!;
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get errorLoadingUserData => _localizedValues[locale.languageCode]!['errorLoadingUserData']!;
  String get history => _localizedValues[locale.languageCode]!['history']!;
  String get reports => _localizedValues[locale.languageCode]!['reports']!;
  String get changePassword => _localizedValues[locale.languageCode]!['changePassword']!;
  String get oldPassword => _localizedValues[locale.languageCode]!['oldPassword']!;
  String get newPassword => _localizedValues[locale.languageCode]!['newPassword']!;
  String get confirm => _localizedValues[locale.languageCode]!['confirm']!;
  String get yes => _localizedValues[locale.languageCode]!['yes']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get enterNewNickname => _localizedValues[locale.languageCode]!['enterNewNickname']!;
  String get notSet => _localizedValues[locale.languageCode]!['notSet']!;
  String get nickname => _localizedValues[locale.languageCode]!['nickname']!;
  String get username => _localizedValues[locale.languageCode]!['username']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get balance => _localizedValues[locale.languageCode]!['balance']!;
  String get income => _localizedValues[locale.languageCode]!['income']!;
  String get expenses => _localizedValues[locale.languageCode]!['expenses']!;
  String get nicknameUpdated => _localizedValues[locale.languageCode]!['nicknameUpdated']!;
  String nicknameUpdateFailed(String error) =>
      _localizedValues[locale.languageCode]!['nicknameUpdateFailed']!.replaceAll('{error}', error);
  String get passwordChanged => _localizedValues[locale.languageCode]!['passwordChanged']!;
  String passwordChangeFailed(String error) =>
      _localizedValues[locale.languageCode]!['passwordChangeFailed']!.replaceAll('{error}', error);
  String summaryLoadFailed(String error) =>
      _localizedValues[locale.languageCode]!['summaryLoadFailed']!.replaceAll('{error}', error);
  String get manageCurrencies => _localizedValues[locale.languageCode]!['manageCurrencies']!;
  String get deleteCurrency => _localizedValues[locale.languageCode]!['deleteCurrency']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get retry => _localizedValues[locale.languageCode]!['retry']!;
  String get searchCurrencyOrCountry => _localizedValues[locale.languageCode]!['searchCurrencyOrCountry']!;
  String currencyAdded(String currency) =>
      _localizedValues[locale.languageCode]!['currencyAdded']!.replaceAll('{currency}', currency);
  String currencyDeleted(String currency) =>
      _localizedValues[locale.languageCode]!['currencyDeleted']!.replaceAll('{currency}', currency);
  String get cannotDeleteKGS => _localizedValues[locale.languageCode]!['cannotDeleteKGS']!;
  String currencyExists(String currency) =>
      _localizedValues[locale.languageCode]!['currencyExists']!.replaceAll('{currency}', currency);
  String get kgsDefault => _localizedValues[locale.languageCode]!['kgsDefault']!;
  String deleteConfirm(String currency) =>
      _localizedValues[locale.languageCode]!['deleteConfirm']!.replaceAll('{currency}', currency);
  String currenciesLoadFailed(String error) =>
      _localizedValues[locale.languageCode]!['currenciesLoadFailed']!.replaceAll('{error}', error);
  String get recents => _localizedValues[locale.languageCode]!['recents']!;
  String get noTransactions => _localizedValues[locale.languageCode]!['noTransactions']!;
  String transactionsLoadFailed(String error) =>
      _localizedValues[locale.languageCode]!['transactionsLoadFailed']!.replaceAll('{error}', error);
  String get transactionHistory => _localizedValues[locale.languageCode]!['transactionHistory']!;
  String get searchTransactions => _localizedValues[locale.languageCode]!['searchTransactions']!;
  String get noTransactionsFound => _localizedValues[locale.languageCode]!['noTransactionsFound']!;
  String get deleteTransaction => _localizedValues[locale.languageCode]!['deleteTransaction']!;
  String get deleteTransactionConfirm => _localizedValues[locale.languageCode]!['deleteTransactionConfirm']!;
  String get transactionDeleted => _localizedValues[locale.languageCode]!['transactionDeleted']!;
  String deleteTransactionFailed(String error) =>
      _localizedValues[locale.languageCode]!['deleteTransactionFailed']!.replaceAll('{error}', error);
  String get all => _localizedValues[locale.languageCode]!['all']!;
  String get expense => _localizedValues[locale.languageCode]!['expense']!;
  String get incomeFilter => _localizedValues[locale.languageCode]!['incomeFilter']!;
  String get undo => _localizedValues[locale.languageCode]!['undo']!;
  String get welcome => _localizedValues[locale.languageCode]!['welcomeBack']!;
  String get createAccount => _localizedValues[locale.languageCode]!['createAccount']!;
  String get verifyYourEmail => _localizedValues[locale.languageCode]!['verifyYourEmail']!;
  String get login => _localizedValues[locale.languageCode]!['login']!;
  String get register => _localizedValues[locale.languageCode]!['register']!;
  String get verify => _localizedValues[locale.languageCode]!['verify']!;
  String get usernameRequired => _localizedValues[locale.languageCode]!['usernameRequired']!;
  String get usernameTooShort => _localizedValues[locale.languageCode]!['usernameTooShort']!;
  String get password => _localizedValues[locale.languageCode]!['password']!;
  String get passwordRequired => _localizedValues[locale.languageCode]!['passwordRequired']!;
  String get passwordTooShort => _localizedValues[locale.languageCode]!['passwordTooShort']!;
  String get emailRequired => _localizedValues[locale.languageCode]!['emailRequired']!;
  String get emailInvalid => _localizedValues[locale.languageCode]!['emailInvalid']!;
  String get dontHaveAccount => _localizedValues[locale.languageCode]!['dontHaveAccount']!;
  String get alreadyHaveAccount => _localizedValues[locale.languageCode]!['alreadyHaveAccount']!;
  String get forgotPassword => _localizedValues[locale.languageCode]!['forgotPassword']!;
  String get forgotPasswordTitle => _localizedValues[locale.languageCode]!['forgotPasswordTitle']!;
  String get forgotPasswordPrompt => _localizedValues[locale.languageCode]!['forgotPasswordPrompt']!;
  String get sendCode => _localizedValues[locale.languageCode]!['sendCode']!;
  String get loginSuccessful => _localizedValues[locale.languageCode]!['loginSuccessful']!;
  String get codeSentToEmail => _localizedValues[locale.languageCode]!['codeSentToEmail']!;
  String get emailVerified => _localizedValues[locale.languageCode]!['emailVerified']!;
  String get codeSentForLogin => _localizedValues[locale.languageCode]!['codeSentForLogin']!;
  String get backToRegistration => _localizedValues[locale.languageCode]!['backToRegistration']!;
  String enterCodePrompt(String email) =>
      _localizedValues[locale.languageCode]!['enterCodePrompt']!.replaceAll('{email}', email);
  String get codeRequired => _localizedValues[locale.languageCode]!['codeRequired']!;
  String get reportsAndInsights => _localizedValues[locale.languageCode]!['reportsAndInsights']!;
  String get total => _localizedValues[locale.languageCode]!['total']!;
  String get filters => _localizedValues[locale.languageCode]!['filters']!;
  String get startDate => _localizedValues[locale.languageCode]!['startDate']!;
  String get endDate => _localizedValues[locale.languageCode]!['endDate']!;
  String get clearFilters => _localizedValues[locale.languageCode]!['clearFilters']!;
  String get categoryWiseSpending => _localizedValues[locale.languageCode]!['categoryWiseSpending']!;
  String get monthlySpendingTrends => _localizedValues[locale.languageCode]!['monthlySpendingTrends']!;
  String get noDataAvailable => _localizedValues[locale.languageCode]!['noDataAvailable']!;
  String get unknown => _localizedValues[locale.languageCode]!['unknown']!;
  String get percentage => _localizedValues[locale.languageCode]!['percentage']!;
  String get details => _localizedValues[locale.languageCode]!['details']!;
  String failedToLoadData(String error) =>
      _localizedValues[locale.languageCode]!['failedToLoadData']!.replaceAll('{error}', error);
  String failedToLoadCategories(String error) =>
      _localizedValues[locale.languageCode]!['failedToLoadCategories']!.replaceAll('{error}', error);
  String currencyConversionError(String error) =>
      _localizedValues[locale.languageCode]!['currencyConversionError']!.replaceAll('{error}', error);

  // Getters for category translations
  String get food => _localizedValues[locale.languageCode]!['food']!;
  String get transport => _localizedValues[locale.languageCode]!['transport']!;
  String get housing => _localizedValues[locale.languageCode]!['housing']!;
  String get utilities => _localizedValues[locale.languageCode]!['utilities']!;
  String get entertainment => _localizedValues[locale.languageCode]!['entertainment']!;
  String get healthcare => _localizedValues[locale.languageCode]!['healthcare']!;
  String get education => _localizedValues[locale.languageCode]!['education']!;
  String get shopping => _localizedValues[locale.languageCode]!['shopping']!;
  String get otherExpense => _localizedValues[locale.languageCode]!['other_expense']!;
  String get salary => _localizedValues[locale.languageCode]!['salary']!;
  String get gift => _localizedValues[locale.languageCode]!['gift']!;
  String get interest => _localizedValues[locale.languageCode]!['interest']!;
  String get otherIncome => _localizedValues[locale.languageCode]!['other_income']!;
  String get clear => _localizedValues[locale.languageCode]!['clear']!;
  String get clearData => _localizedValues[locale.languageCode]!['clearData']!;
  String get clearDataConfirm => _localizedValues[locale.languageCode]!['clearDataConfirm']!;
  String get enterPassword => _localizedValues[locale.languageCode]!['enterPassword']!;
  String get dataCleared => _localizedValues[locale.languageCode]!['dataCleared']!;
  String get clearDataFailed => _localizedValues[locale.languageCode]!['clearDataFailed']!;
  String get usernameTaken => _localizedValues[locale.languageCode]!['usernameTaken']!;
  String get usernameAvailable => _localizedValues[locale.languageCode]!['usernameAvailable']!;
  String get codeInvalid => _localizedValues[locale.languageCode]!['codeInvalid']!;
  String get fillAllFields => _localizedValues[locale.languageCode]!['fillAllFields']!;
  String get enterValidCode => _localizedValues[locale.languageCode]!['enterValidCode']!;
  String get resetPasswordSent => _localizedValues[locale.languageCode]!['resetPasswordSent']!;
  String get transactionFailed => _localizedValues[locale.languageCode]!['transactionFailed']!;
  String get today => _localizedValues[locale.languageCode]!['today']!;
  String get yesterday => _localizedValues[locale.languageCode]!['yesterday']!;

  // Add this method to your AppLocalizations class
  String translate(String key) {
    // First try to get the translation from the localized values
    if (_localizedValues[locale.languageCode]?.containsKey(key) ?? false) {
      return _localizedValues[locale.languageCode]![key]!;
    }

    // If not found, try the English version as fallback
    if (_localizedValues['en']?.containsKey(key) ?? false) {
      return _localizedValues['en']![key]!;
    }

    // If still not found, return the key itself with a warning
    debugPrint('Translation not found for key: $key');
    return key;
  }



  // Method to get the localized category name dynamically
  String getCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return food;
      case 'transport':
        return transport;
      case 'housing':
        return housing;
      case 'utilities':
        return utilities;
      case 'entertainment':
        return entertainment;
      case 'healthcare':
        return healthcare;
      case 'education':
        return education;
      case 'shopping':
        return shopping;
      case 'other_expense':
        return otherExpense;
      case 'salary':
        return salary;
      case 'gift':
        return gift;
      case 'interest':
        return interest;
      case 'other_income':
        return otherIncome;
      default:
        return unknown;
    }
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ky', 'ru'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}