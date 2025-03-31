class CurrencyApiService {
  // Static currency data (as provided)
  static const Map<String, dynamic> _currencyData = {
    "success":true,
    "timestamp":1743314643,
    "base":"EUR",
    "date":"2025-03-30",
    "rates":{
      "AED":3.998302,
      "AFN":76.426194,
      "ALL":99.362051,
      "AMD":421.123927,
      "ANG":1.941049,
      "AOA":996.026725,
      "ARS":1153.728687,
      "AUD":1.72704,
      "AWG":1.962117,
      "AZN":1.854862,
      "BAM":1.955447,
      "BBD":2.174607,
      "BDT":130.896355,
      "BGN":1.967628,
      "BHD":0.406027,
      "BIF":3192.223348,
      "BMD":1.088553,
      "BND":1.446139,
      "BOB":7.441656,
      "BRL":6.269201,
      "BSD":1.077005,
      "BTC":1.29978e-5,
      "BTN":92.037374,
      "BWP":14.713342,
      "BYN":3.524563,
      "BYR":21335.645872,
      "BZD":2.163309,
      "CAD":1.565395,
      "CDF":3126.873796,
      "CHF":0.958764,
      "CLF":0.026358,
      "CLP":1011.477284,
      "CNY":7.906494,
      "CNH":7.914197,
      "COP":4493.088357,
      "CRC":538.202778,
      "CUC":1.088553,
      "CUP":28.846664,
      "CVE":110.245085,
      "CZK":25.060719,
      "DJF":191.59539,
      "DKK":7.500573,
      "DOP":67.97772,
      "DZD":144.798843,
      "EGP":54.763107,
      "ERN":16.3283,
      "ETB":141.49494,
      "EUR":1,
      "FJD":2.531,
      "FKP":0.84116,
      "GBP":0.840874,
      "GEL":3.020779,
      "GGP":0.84116,
      "GHS":16.693984,
      "GIP":0.84116,
      "GMD":77.835757,
      "GNF":9311.317979,
      "GTQ":8.308499,
      "GYD":225.319298,
      "HKD":8.473245,
      "HNL":27.551023,
      "HRK":7.572635,
      "HTG":141.144503,
      "HUF":404.648363,
      "IDR":18074.340003,
      "ILS":4.017546,
      "IMP":0.84116,
      "INR":93.113712,
      "IQD":1410.845141,
      "IRR":45828.096874,
      "ISK":143.243157,
      "JEP":0.84116,
      "JMD":169.309415,
      "JOD":0.771827,
      "JPY":163.114321,
      "KES":139.154863,
      "KGS":94.055146,
      "KHR":4311.221209,
      "KMF":496.928739,
      "KPW":979.688282,
      "KRW":1600.612986,
      "KWD":0.335536,
      "KYD":0.897538,
      "KZT":542.771952,
      "LAK":23339.783839,
      "LBP":96508.666417,
      "LKR":319.022371,
      "LRD":215.401089,
      "LSL":19.571864,
      "LTL":3.214215,
      "LVL":0.658455,
      "LYD":5.208059,
      "MAD":10.419018,
      "MDL":19.42849,
      "MGA":5046.088461,
      "MKD":61.523886,
      "MMK":2284.812864,
      "MNT":3800.653034,
      "MOP":8.629641,
      "MRU":42.853259,
      "MUR":49.834385,
      "MVR":16.767792,
      "MWK":1867.66262,
      "MXN":22.185919,
      "MYR":4.83046,
      "MZN":69.562619,
      "NAD":19.571864,
      "NGN":1665.966016,
      "NIO":39.632841,
      "NOK":11.420726,
      "NPR":147.259399,
      "NZD":1.904231,
      "OMR":0.416905,
      "PAB":1.077005,
      "PEN":3.920692,
      "PGK":4.439198,
      "PHP":62.439829,
      "PKR":301.827277,
      "PLN":4.19037,
      "PYG":8627.441516,
      "QAR":3.927091,
      "RON":5.003975,
      "RSD":117.228823,
      "RUB":90.423666,
      "RWF":1551.319765,
      "SAR":4.08195,
      "SBD":9.079475,
      "SCR":15.457408,
      "SDG":653.680295,
      "SEK":10.934617,
      "SGD":1.458775,
      "SHP":0.855432,
      "SLE":24.830306,
      "SLL":22826.420878,
      "SOS":615.488816,
      "SRD":39.786085,
      "STD":22530.856788,
      "SVC":9.423298,
      "SYP":14153.511385,
      "SZL":19.567465,
      "THB":36.936834,
      "TJS":11.728481,
      "TMT":3.809937,
      "TND":3.354494,
      "TOP":2.549505,
      "TRY":41.346309,
      "TTD":7.30768,
      "TWD":36.140629,
      "TZS":2848.985352,
      "UAH":44.67283,
      "UGX":3943.287674,
      "USD":1.088553,
      "UYU":45.371804,
      "UZS":13907.487714,
      "VES":75.03677,
      "VND":27839.752203,
      "VUV":134.217333,
      "WST":3.074051,
      "XAF":655.838528,
      "XAG":0.031916,
      "XAU":0.000353,
      "XCD":2.94187,
      "XDR":0.815653,
      "XOF":655.838528,
      "XPF":119.331742,
      "YER":267.784488,
      "ZAR":19.910036,
      "ZMK":9798.290415,
      "ZMW":30.66746,
      "ZWL":350.513738
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
