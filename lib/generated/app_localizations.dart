import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Map of localized strings for each language
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Existing strings
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
      'confirmLogout': 'Logout',
      'currencyChanged': 'Currency changed to {currency}',
      'currencyChangeFailed': 'Failed to update currency: {error}',
      // New strings for AddTransactionScreen
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
    },
    'ky': {
      // Existing strings
      'appTitle': 'Жеке Финансы',
      'settingsTitle': 'Жөндөөлөр',
      'darkMode': 'Караңгы Режим',
      'darkModeEnabled': 'Иштетилген',
      'darkModeDisabled': 'Өчүрүлгөн',
      'selectCurrency': 'Валюта Тандоо',
      'selectLanguage': 'Тил Тандоо',
      'logout': 'Чыгуу',
      'logoutConfirm': 'Чыгууну каалайсызбы?',
      'cancel': 'Жокко чыгаруу',
      'confirmLogout': 'Чыгуу',
      'currencyChanged': 'Валюта {currency} болуп өзгөртүлдү',
      'currencyChangeFailed': 'Валютаны өзгөртүү ишке ашкан жок: {error}',
      // New strings for AddTransactionScreen
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
    },
    'ru': {
      // Existing strings
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
      'confirmLogout': 'Выйти',
      'currencyChanged': 'Валюта изменена на {currency}',
      'currencyChangeFailed': 'Не удалось обновить валюту: {error}',
      // New strings for AddTransactionScreen
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
    },
  };

  // Existing getters
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
  String get confirmLogout => _localizedValues[locale.languageCode]!['confirmLogout']!;
  String currencyChanged(String currency) =>
      _localizedValues[locale.languageCode]!['currencyChanged']!.replaceAll('{currency}', currency);
  String currencyChangeFailed(String error) =>
      _localizedValues[locale.languageCode]!['currencyChangeFailed']!.replaceAll('{error}', error);

  // New getters for AddTransactionScreen
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