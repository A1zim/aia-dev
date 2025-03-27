class CurrencyApiService {
  // Static currency data (as provided)
  static const Map<String, dynamic> _currencyData = {
    "success": true,
    "timestamp": 1743017651,
    "base": "EUR",
    "date": "2025-03-26",
    "rates": {
      "AED": 3.947094,
      "AFN": 77.372992,
      "ALL": 98.408523,
      "AMD": 421.040123,
      "ANG": 1.937799,
      "AOA": 983.279073,
      "ARS": 1151.064945,
      "AUD": 1.709315,
      "AWG": 1.934319,
      "AZN": 1.826286,
      "BAM": 1.948559,
      "BBD": 2.171032,
      "BDT": 130.644527,
      "BGN": 1.953651,
      "BHD": 0.405105,
      "BIF": 3146.492404,
      "BMD": 1.074622,
      "BND": 1.438554,
      "BOB": 7.429427,
      "BRL": 6.165215,
      "BSD": 1.075205,
      "BTC": 1.2461961e-5,
      "BTN": 92.112711,
      "BWP": 14.719303,
      "BYN": 3.518824,
      "BYR": 21062.585766,
      "BZD": 2.159774,
      "CAD": 1.535973,
      "CDF": 3084.690749,
      "CHF": 0.950783,
      "CLF": 0.025875,
      "CLP": 992.950314,
      "CNY": 7.798962,
      "CNH": 7.825514,
      "COP": 4444.506491,
      "CRC": 536.312064,
      "CUC": 1.074622,
      "CUP": 28.477476,
      "CVE": 110.254435,
      "CZK": 24.90964,
      "DJF": 190.981768,
      "DKK": 7.460035,
      "DOP": 68.02561,
      "DZD": 144.217447,
      "EGP": 54.303429,
      "ERN": 16.119326,
      "ETB": 138.787567,
      "EUR": 1,
      "FJD": 2.464723,
      "FKP": 0.830028,
      "GBP": 0.834223,
      "GEL": 2.987674,
      "GGP": 0.830028,
      "GHS": 16.661454,
      "GIP": 0.830028,
      "GMD": 77.340662,
      "GNF": 9296.399282,
      "GTQ": 8.282917,
      "GYD": 225.065188,
      "HKD": 8.356522,
      "HNL": 27.544811,
      "HRK": 7.532989,
      "HTG": 140.981106,
      "HUF": 397.256636,
      "IDR": 17808.663704,
      "ILS": 3.97357,
      "IMP": 0.830028,
      "INR": 92.010481,
      "IQD": 1408.030725,
      "IRR": 45197.364273,
      "ISK": 143.368374,
      "JEP": 0.830028,
      "JMD": 168.484797,
      "JOD": 0.761879,
      "JPY": 161.754214,
      "KES": 139.10115,
      "KGS": 94.235446,
      "KHR": 4304.015692,
      "KMF": 489.444077,
      "KPW": 967.159935,
      "KRW": 1574.836173,
      "KWD": 0.331342,
      "KYD": 0.893602,
      "KZT": 540.596905,
      "LAK": 23294.833492,
      "LBP": 96467.134292,
      "LKR": 318.883949,
      "LRD": 214.880516,
      "LSL": 19.588774,
      "LTL": 3.173078,
      "LVL": 0.650028,
      "LYD": 5.179836,
      "MAD": 10.297216,
      "MDL": 19.314254,
      "MGA": 5020.731167,
      "MKD": 61.131898,
      "MMK": 2256.35389,
      "MNT": 3742.922919,
      "MOP": 8.605558,
      "MRU": 42.247995,
      "MUR": 49.112446,
      "MVR": 16.596982,
      "MWK": 1865.063753,
      "MXN": 21.659624,
      "MYR": 4.766762,
      "MZN": 68.654931,
      "NAD": 19.588774,
      "NGN": 1643.692362,
      "NIO": 39.545232,
      "NOK": 11.359439,
      "NPR": 147.285777,
      "NZD": 1.877954,
      "OMR": 0.413656,
      "PAB": 1.074622,
      "PEN": 3.909985,
      "PGK": 4.381088,
      "PHP": 61.853582,
      "PKR": 301.12628,
      "PLN": 4.14379,
      "PYG": 8578.784932,
      "QAR": 3.911908,
      "RON": 4.949879,
      "RSD": 116.619062,
      "RUB": 90.702344,
      "RWF": 1527.145378,
      "SAR": 4.030231,
      "SBD": 9.132377,
      "SCR": 15.601551,
      "SDG": 645.206806,
      "SEK": 10.81135,
      "SGD": 1.436215,
      "SHP": 0.844484,
      "SLE": 24.481017,
      "SLL": 22534.281379,
      "SOS": 613.355496,
      "SRD": 39.345307,
      "STD": 22242.500009,
      "SVC": 9.403619,
      "SYP": 13972.144218,
      "SZL": 19.588774,
      "THB": 36.359676,
      "TJS": 11.718597,
      "TMT": 3.758786,
      "TND": 3.335329,
      "TOP": 2.58847,
      "TRY": 40.826362,
      "TTD": 7.307335,
      "TWD": 35.526427,
      "TZS": 2842.986007,
      "UAH": 44.765108,
      "UGX": 3939.311015,
      "USD": 1.074622,
      "UYU": 45.280419,
      "UZS": 13931.001983,
      "VES": 73.359506,
      "VND": 27539.699528,
      "VUV": 132.251829,
      "WST": 3.037394,
      "XAF": 652.592103,
      "XAG": 0.032056,
      "XAU": 0.000356,
      "XCD": 2.909986,
      "XDR": 0.809226,
      "XOF": 652.592103,
      "XPF": 119.331742,
      "YER": 264.474067,
      "ZAR": 19.651033,
      "ZMK": 9672.880633,
      "ZMW": 31.008601,
      "ZWL": 346.027756
    }
  };

  // Mapping of currency codes to country names
  static const Map<String, String> _currencyToCountry = {
    "AED": "United Arab Emirates",
    "AFN": "Afghanistan",
    "ALL": "Albania",
    "AMD": "Armenia",
    "ANG": "Netherlands Antilles",
    "AOA": "Angola",
    "ARS": "Argentina",
    "AUD": "Australia",
    "AWG": "Aruba",
    "AZN": "Azerbaijan",
    "BAM": "Bosnia and Herzegovina",
    "BBD": "Barbados",
    "BDT": "Bangladesh",
    "BGN": "Bulgaria",
    "BHD": "Bahrain",
    "BIF": "Burundi",
    "BMD": "Bermuda",
    "BND": "Brunei",
    "BOB": "Bolivia",
    "BRL": "Brazil",
    "BSD": "Bahamas",
    "BTC": "Bitcoin",
    "BTN": "Bhutan",
    "BWP": "Botswana",
    "BYN": "Belarus",
    "BYR": "Belarus (Old)",
    "BZD": "Belize",
    "CAD": "Canada",
    "CDF": "Democratic Republic of the Congo",
    "CHF": "Switzerland",
    "CLF": "Chile (Unit of Account)",
    "CLP": "Chile",
    "CNY": "China",
    "CNH": "China (Offshore)",
    "COP": "Colombia",
    "CRC": "Costa Rica",
    "CUC": "Cuba (Convertible Peso)",
    "CUP": "Cuba",
    "CVE": "Cape Verde",
    "CZK": "Czech Republic",
    "DJF": "Djibouti",
    "DKK": "Denmark",
    "DOP": "Dominican Republic",
    "DZD": "Algeria",
    "EGP": "Egypt",
    "ERN": "Eritrea",
    "ETB": "Ethiopia",
    "EUR": "Europe",
    "FJD": "Fiji",
    "FKP": "Falkland Islands",
    "GBP": "United Kingdom",
    "GEL": "Georgia",
    "GGP": "Guernsey",
    "GHS": "Ghana",
    "GIP": "Gibraltar",
    "GMD": "Gambia",
    "GNF": "Guinea",
    "GTQ": "Guatemala",
    "GYD": "Guyana",
    "HKD": "Hong Kong",
    "HNL": "Honduras",
    "HRK": "Croatia",
    "HTG": "Haiti",
    "HUF": "Hungary",
    "IDR": "Indonesia",
    "ILS": "Israel",
    "IMP": "Isle of Man",
    "INR": "India",
    "IQD": "Iraq",
    "IRR": "Iran",
    "ISK": "Iceland",
    "JEP": "Jersey",
    "JMD": "Jamaica",
    "JOD": "Jordan",
    "JPY": "Japan",
    "KES": "Kenya",
    "KGS": "Kyrgyzstan",
    "KHR": "Cambodia",
    "KMF": "Comoros",
    "KPW": "North Korea",
    "KRW": "South Korea",
    "KWD": "Kuwait",
    "KYD": "Cayman Islands",
    "KZT": "Kazakhstan",
    "LAK": "Laos",
    "LBP": "Lebanon",
    "LKR": "Sri Lanka",
    "LRD": "Liberia",
    "LSL": "Lesotho",
    "LTL": "Lithuania (Old)",
    "LVL": "Latvia (Old)",
    "LYD": "Libya",
    "MAD": "Morocco",
    "MDL": "Moldova",
    "MGA": "Madagascar",
    "MKD": "North Macedonia",
    "MMK": "Myanmar",
    "MNT": "Mongolia",
    "MOP": "Macau",
    "MRU": "Mauritania",
    "MUR": "Mauritius",
    "MVR": "Maldives",
    "MWK": "Malawi",
    "MXN": "Mexico",
    "MYR": "Malaysia",
    "MZN": "Mozambique",
    "NAD": "Namibia",
    "NGN": "Nigeria",
    "NIO": "Nicaragua",
    "NOK": "Norway",
    "NPR": "Nepal",
    "NZD": "New Zealand",
    "OMR": "Oman",
    "PAB": "Panama",
    "PEN": "Peru",
    "PGK": "Papua New Guinea",
    "PHP": "Philippines",
    "PKR": "Pakistan",
    "PLN": "Poland",
    "PYG": "Paraguay",
    "QAR": "Qatar",
    "RON": "Romania",
    "RSD": "Serbia",
    "RUB": "Russia",
    "RWF": "Rwanda",
    "SAR": "Saudi Arabia",
    "SBD": "Solomon Islands",
    "SCR": "Seychelles",
    "SDG": "Sudan",
    "SEK": "Sweden",
    "SGD": "Singapore",
    "SHP": "Saint Helena",
    "SLE": "Sierra Leone",
    "SLL": "Sierra Leone (Old)",
    "SOS": "Somalia",
    "SRD": "Suriname",
    "STD": "São Tomé and Príncipe (Old)",
    "SVC": "El Salvador",
    "SYP": "Syria",
    "SZL": "Eswatini",
    "THB": "Thailand",
    "TJS": "Tajikistan",
    "TMT": "Turkmenistan",
    "TND": "Tunisia",
    "TOP": "Tonga",
    "TRY": "Turkey",
    "TTD": "Trinidad and Tobago",
    "TWD": "Taiwan",
    "TZS": "Tanzania",
    "UAH": "Ukraine",
    "UGX": "Uganda",
    "USD": "United States",
    "UYU": "Uruguay",
    "UZS": "Uzbekistan",
    "VES": "Venezuela",
    "VND": "Vietnam",
    "VUV": "Vanuatu",
    "WST": "Samoa",
    "XAF": "Central African CFA Franc",
    "XAG": "Silver (Troy Ounce)",
    "XAU": "Gold (Troy Ounce)",
    "XCD": "Eastern Caribbean Dollar",
    "XDR": "Special Drawing Rights",
    "XOF": "West African CFA Franc",
    "XPF": "CFP Franc",
    "YER": "Yemen",
    "ZAR": "South Africa",
    "ZMK": "Zambia (Old)",
    "ZMW": "Zambia",
    "ZWL": "Zimbabwe"
  };

  // Mapping of currency codes to their symbols
  static const Map<String, String> _currencySymbols = {
    "AED": "د.إ", // UAE Dirham
    "AFN": "؋", // Afghan Afghani
    "ALL": "L", // Albanian Lek
    "AMD": "֏", // Armenian Dram
    "ANG": "ƒ", // Netherlands Antillean Guilder
    "AOA": "Kz", // Angolan Kwanza
    "ARS": "\$", // Argentine Peso
    "AUD": "\$", // Australian Dollar
    "AWG": "ƒ", // Aruban Florin
    "AZN": "₼", // Azerbaijani Manat
    "BAM": "KM", // Bosnia-Herzegovina Convertible Mark
    "BBD": "\$", // Barbadian Dollar
    "BDT": "৳", // Bangladeshi Taka
    "BGN": "лв", // Bulgarian Lev
    "BHD": ".د.ب", // Bahraini Dinar
    "BIF": "FBu", // Burundian Franc
    "BMD": "\$", // Bermudian Dollar
    "BND": "\$", // Brunei Dollar
    "BOB": "Bs.", // Bolivian Boliviano
    "BRL": "R\$", // Brazilian Real
    "BSD": "\$", // Bahamian Dollar
    "BTC": "₿", // Bitcoin
    "BTN": "Nu.", // Bhutanese Ngultrum
    "BWP": "P", // Botswanan Pula
    "BYN": "Br", // Belarusian Ruble
    "BYR": "Br", // Belarusian Ruble (Old)
    "BZD": "BZ\$", // Belize Dollar
    "CAD": "\$", // Canadian Dollar
    "CDF": "FC", // Congolese Franc
    "CHF": "Fr.", // Swiss Franc
    "CLF": "UF", // Chilean Unit of Account (UF)
    "CLP": "\$", // Chilean Peso
    "CNY": "¥", // Chinese Yuan
    "CNH": "¥", // Chinese Yuan (Offshore)
    "COP": "\$", // Colombian Peso
    "CRC": "₡", // Costa Rican Colón
    "CUC": "\$", // Cuban Convertible Peso
    "CUP": "₱", // Cuban Peso
    "CVE": "\$", // Cape Verdean Escudo
    "CZK": "Kč", // Czech Koruna
    "DJF": "Fdj", // Djiboutian Franc
    "DKK": "kr", // Danish Krone
    "DOP": "RD\$", // Dominican Peso
    "DZD": "دج", // Algerian Dinar
    "EGP": "£", // Egyptian Pound
    "ERN": "Nfk", // Eritrean Nakfa
    "ETB": "Br", // Ethiopian Birr
    "EUR": "€", // Euro
    "FJD": "\$", // Fijian Dollar
    "FKP": "£", // Falkland Islands Pound
    "GBP": "£", // British Pound Sterling
    "GEL": "₾", // Georgian Lari
    "GGP": "£", // Guernsey Pound
    "GHS": "₵", // Ghanaian Cedi
    "GIP": "£", // Gibraltar Pound
    "GMD": "D", // Gambian Dalasi
    "GNF": "FG", // Guinean Franc
    "GTQ": "Q", // Guatemalan Quetzal
    "GYD": "\$", // Guyanese Dollar
    "HKD": "\$", // Hong Kong Dollar
    "HNL": "L", // Honduran Lempira
    "HRK": "kn", // Croatian Kuna
    "HTG": "G", // Haitian Gourde
    "HUF": "Ft", // Hungarian Forint
    "IDR": "Rp", // Indonesian Rupiah
    "ILS": "₪", // Israeli New Shekel
    "IMP": "£", // Manx Pound
    "INR": "₹", // Indian Rupee
    "IQD": "ع.د", // Iraqi Dinar
    "IRR": "﷼", // Iranian Rial
    "ISK": "kr", // Icelandic Króna
    "JEP": "£", // Jersey Pound
    "JMD": "J\$", // Jamaican Dollar
    "JOD": "د.ا", // Jordanian Dinar
    "JPY": "¥", // Japanese Yen
    "KES": "KSh", // Kenyan Shilling
    "KGS": "Сом", // Kyrgyzstani Som
    "KHR": "៛", // Cambodian Riel
    "KMF": "CF", // Comorian Franc
    "KPW": "₩", // North Korean Won
    "KRW": "₩", // South Korean Won
    "KWD": "د.ك", // Kuwaiti Dinar
    "KYD": "\$", // Cayman Islands Dollar
    "KZT": "₸", // Kazakhstani Tenge
    "LAK": "₭", // Laotian Kip
    "LBP": "ل.ل", // Lebanese Pound
    "LKR": "₨", // Sri Lankan Rupee
    "LRD": "\$", // Liberian Dollar
    "LSL": "L", // Lesotho Loti
    "LTL": "Lt", // Lithuanian Litas (Old)
    "LVL": "Ls", // Latvian Lats (Old)
    "LYD": "ل.د", // Libyan Dinar
    "MAD": "د.م.", // Moroccan Dirham
    "MDL": "L", // Moldovan Leu
    "MGA": "Ar", // Malagasy Ariary
    "MKD": "ден", // Macedonian Denar
    "MMK": "K", // Myanmar Kyat
    "MNT": "₮", // Mongolian Tugrik
    "MOP": "MOP\$", // Macanese Pataca
    "MRU": "UM", // Mauritanian Ouguiya
    "MUR": "₨", // Mauritian Rupee
    "MVR": "Rf", // Maldivian Rufiyaa
    "MWK": "MK", // Malawian Kwacha
    "MXN": "\$", // Mexican Peso
    "MYR": "RM", // Malaysian Ringgit
    "MZN": "MT", // Mozambican Metical
    "NAD": "\$", // Namibian Dollar
    "NGN": "₦", // Nigerian Naira
    "NIO": "C\$", // Nicaraguan Córdoba
    "NOK": "kr", // Norwegian Krone
    "NPR": "₨", // Nepalese Rupee
    "NZD": "\$", // New Zealand Dollar
    "OMR": "ر.ع.", // Omani Rial
    "PAB": "B/.", // Panamanian Balboa
    "PEN": "S/.", // Peruvian Sol
    "PGK": "K", // Papua New Guinean Kina
    "PHP": "₱", // Philippine Peso
    "PKR": "₨", // Pakistani Rupee
    "PLN": "zł", // Polish Zloty
    "PYG": "₲", // Paraguayan Guarani
    "QAR": "ر.ق", // Qatari Rial
    "RON": "lei", // Romanian Leu
    "RSD": "дин", // Serbian Dinar
    "RUB": "₽", // Russian Ruble
    "RWF": "FRw", // Rwandan Franc
    "SAR": "ر.س", // Saudi Riyal
    "SBD": "\$", // Solomon Islands Dollar
    "SCR": "₨", // Seychellois Rupee
    "SDG": "ج.س.", // Sudanese Pound
    "SEK": "kr", // Swedish Krona
    "SGD": "\$", // Singapore Dollar
    "SHP": "£", // Saint Helena Pound
    "SLE": "Le", // Sierra Leonean Leone
    "SLL": "Le", // Sierra Leonean Leone (Old)
    "SOS": "Sh", // Somali Shilling
    "SRD": "\$", // Surinamese Dollar
    "STD": "Db", // São Tomé and Príncipe Dobra (Old)
    "SVC": "\$", // Salvadoran Colón
    "SYP": "£", // Syrian Pound
    "SZL": "E", // Swazi Lilangeni
    "THB": "฿", // Thai Baht
    "TJS": "SM", // Tajikistani Somoni
    "TMT": "m", // Turkmenistani Manat
    "TND": "د.ت", // Tunisian Dinar
    "TOP": "T\$", // Tongan Paʻanga
    "TRY": "₺", // Turkish Lira
    "TTD": "TT\$", // Trinidad and Tobago Dollar
    "TWD": "NT\$", // New Taiwan Dollar
    "TZS": "TSh", // Tanzanian Shilling
    "UAH": "₴", // Ukrainian Hryvnia
    "UGX": "USh", // Ugandan Shilling
    "USD": "\$", // United States Dollar
    "UYU": "\$U", // Uruguayan Peso
    "UZS": "сўм", // Uzbekistani Som
    "VES": "Bs.", // Venezuelan Bolívar
    "VND": "₫", // Vietnamese Dong
    "VUV": "VT", // Vanuatu Vatu
    "WST": "WS\$", // Samoan Tala
    "XAF": "FCFA", // Central African CFA Franc
    "XAG": "XAG", // Silver (Troy Ounce)
    "XAU": "XAU", // Gold (Troy Ounce)
    "XCD": "\$", // Eastern Caribbean Dollar
    "XDR": "XDR", // Special Drawing Rights
    "XOF": "CFA", // West African CFA Franc
    "XPF": "₣", // CFP Franc
    "YER": "﷼", // Yemeni Rial
    "ZAR": "R", // South African Rand
    "ZMK": "ZK", // Zambian Kwacha (Old)
    "ZMW": "ZK", // Zambian Kwacha
    "ZWL": "\$", // Zimbabwean Dollar
  };

  /// Returns the static exchange rates with EUR as the base.
  Map<String, double> getExchangeRates() {
    final rates = _currencyData['rates'] as Map<String, dynamic>;
    return rates.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  /// Gets the conversion rate from `fromCurrency` to `toCurrency`.
  /// Since the data uses EUR as base, we calculate the rate via EUR.
  double getConversionRate(String fromCurrency, String toCurrency) {
    final rates = getExchangeRates();

    if (!rates.containsKey(fromCurrency) || !rates.containsKey(toCurrency)) {
      throw Exception('Currency not supported: $fromCurrency or $toCurrency');
    }

    final fromRate = rates[fromCurrency]!; // Rate of fromCurrency to EUR
    final toRate = rates[toCurrency]!;     // Rate of toCurrency to EUR

    // Calculate rate from fromCurrency to toCurrency
    // Example: KGS to USD = (EUR/USD) / (EUR/KGS)
    return toRate / fromRate;
  }

  /// Returns a list of all available currency codes.
  List<String> getAllCurrencies() {
    final rates = _currencyData['rates'] as Map<String, dynamic>;
    return rates.keys.toList();
  }

  /// Returns the country name for a given currency code.
  String getCountryForCurrency(String currency) {
    return _currencyToCountry[currency] ?? 'Unknown';
  }

  /// Returns a map of currency codes to country names.
  Map<String, String> getCurrencyToCountryMap() {
    return Map.from(_currencyToCountry);
  }

  /// Returns the symbol for a given currency code.
  /// If no symbol is defined, returns the currency code itself.
  String getCurrencySymbol(String currency) {
    return _currencySymbols[currency] ?? currency;
  }

  /// Returns a map of currency codes to their symbols.
  Map<String, String> getCurrencySymbolsMap() {
    return Map.from(_currencySymbols);
  }
}