import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String itemsStorageKey = 'packing_items_all_v2';
const String oldCustomStorageKey = 'custom_packing_items_v1';
const String favoritesStorageKey = 'favorite_item_ids_v1';
const String recentStorageKey = 'recent_item_ids_v1';

const String filterAll = 'Tümü';
const String filterFavorites = 'Favoriler';
const String filterRecent = 'Son Bakılanlar';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.loadAll();
  runApp(const FinefoodApp());
}

enum AppTextSize {
  small,
  normal,
  large,
}

class FinefoodApp extends StatelessWidget {
  const FinefoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeModeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<AppTextSize>(
          valueListenable: AppSettings.textSizeNotifier,
          builder: (context, textSize, _) {
            return MaterialApp(
              title: 'Finefood Paketleme',
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                fontFamily: 'Roboto',
                scaffoldBackgroundColor: AppColors.lightBg,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.green,
                  brightness: Brightness.light,
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                fontFamily: 'Roboto',
                scaffoldBackgroundColor: AppColors.darkBg,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.green,
                  brightness: Brightness.dark,
                ),
              ),
              builder: (context, child) {
                final media = MediaQuery.of(context);
                return MediaQuery(
                  data: media.copyWith(
                    textScaler: TextScaler.linear(
                      AppSettings.textScaleValue(textSize),
                    ),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}

class AppSettings {
  static const String themeKey = 'theme_mode_v1';
  static const String textSizeKey = 'text_size_v1';
  static const String compactListKey = 'compact_list_v1';

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static final ValueNotifier<AppTextSize> textSizeNotifier =
      ValueNotifier<AppTextSize>(AppTextSize.normal);

  static final ValueNotifier<bool> compactListNotifier =
      ValueNotifier<bool>(false);

  static Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    final themeValue = prefs.getString(themeKey) ?? 'system';
    final textSizeValue = prefs.getString(textSizeKey) ?? 'normal';
    final compactValue = prefs.getBool(compactListKey) ?? false;

    themeModeNotifier.value = _themeModeFromString(themeValue);
    textSizeNotifier.value = _textSizeFromString(textSizeValue);
    compactListNotifier.value = compactValue;
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeKey, _themeModeToString(mode));
    themeModeNotifier.value = mode;
  }

  static Future<void> setTextSize(AppTextSize size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(textSizeKey, _textSizeToString(size));
    textSizeNotifier.value = size;
  }

  static Future<void> setCompactList(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(compactListKey, value);
    compactListNotifier.value = value;
  }

  static double textScaleValue(AppTextSize size) {
    switch (size) {
      case AppTextSize.small:
        return 0.92;
      case AppTextSize.normal:
        return 1.0;
      case AppTextSize.large:
        return 1.15;
    }
  }

  static ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static AppTextSize _textSizeFromString(String value) {
    switch (value) {
      case 'small':
        return AppTextSize.small;
      case 'large':
        return AppTextSize.large;
      default:
        return AppTextSize.normal;
    }
  }

  static String _textSizeToString(AppTextSize size) {
    switch (size) {
      case AppTextSize.small:
        return 'small';
      case AppTextSize.normal:
        return 'normal';
      case AppTextSize.large:
        return 'large';
    }
  }
}

class PackingItem {
  final String id;
  final String title;
  final String category;
  final List<String> keywords;
  final Map<String, String> details;

  const PackingItem({
    required this.id,
    required this.title,
    required this.category,
    required this.keywords,
    required this.details,
  });

  String get copyText {
    final buffer = StringBuffer();
    buffer.writeln(title);
    buffer.writeln('');
    details.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString();
  }

  bool matches(String query) {
    final q = _normalize(query);
    if (q.isEmpty) return true;

    final searchableText = [
      title,
      category,
      ...keywords,
      ...details.keys,
      ...details.values,
    ].map(_normalize).join(' ');

    return searchableText.contains(q);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'keywords': keywords,
      'details': details,
    };
  }

  factory PackingItem.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'];
    final details = rawDetails is Map
        ? rawDetails.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          )
        : <String, String>{};

    final title = (json['title'] ?? 'Adsız Ürün').toString();
    final category = (json['category'] ?? _guessCategory(title)).toString();

    final rawKeywords = json['keywords'];
    final keywords = rawKeywords is List
        ? rawKeywords.map((e) => e.toString()).toList()
        : _createKeywords(
            title: title,
            category: category,
            details: details.cast<String, String>(),
          );

    return PackingItem(
      id: (json['id'] ?? 'custom_${DateTime.now().millisecondsSinceEpoch}')
          .toString(),
      title: title,
      category: category,
      keywords: keywords,
      details: details.cast<String, String>(),
    );
  }
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('×', 'x')
      .replaceAll('`', '')
      .replaceAll("'", '')
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .trim();
}

List<String> _createKeywords({
  required String title,
  required String category,
  required Map<String, String> details,
}) {
  final raw = <String>[
    title,
    category,
    ...details.keys,
    ...details.values,
  ];

  final result = <String>{};

  for (final value in raw) {
    final clean = value.trim();
    if (clean.isEmpty) continue;

    result.add(clean);
    result.add(_normalize(clean));

    final parts = clean.split(RegExp(r'\s+'));
    for (final part in parts) {
      if (part.trim().isNotEmpty) {
        result.add(part.trim());
        result.add(_normalize(part.trim()));
      }
    }
  }

  return result.where((e) => e.trim().isNotEmpty).toList();
}

String _guessCategory(String title) {
  final n = _normalize(title);

  if (n.contains('mcdonald') || n.startsWith('mc')) return 'Mcdonalds';
  if (n.contains('lezita')) return 'Lezita';

  return 'Eklenen Ürünler';
}

const List<PackingItem> builtInPackingItems = [
  PackingItem(
    id: 'mcdonalds_7x7',
    title: 'Mcdonalds 7×7',
    category: 'Mcdonalds',
    keywords: [
      'mc',
      'mcd',
      'mcdonalds',
      'mcdonalds 7x7',
      'mcdonalds 7×7',
      '7x7',
      '7×7',
      'poşet',
      'poset',
      'koli',
      'palet',
      'robot',
      'skt',
      'son kullanma',
      '1 yıl',
      'film',
      'filim',
    ],
    details: {
      'Poşet yazıcı': 'Mcdonalds 7×7 poset nisan-2033',
      'Koli yazıcı': 'Mcdonald`s İC Piyasa 7×7 5×2.5 Kg',
      'Koli': 'Mcdonalds promo 345 lik',
      'Palet': '80×120',
      'Filim': 'Sarı şefaf',
      'Robot sırası': '6',
      'Koli içi poşet sayısı': '5',
      'Skt': '1 Yıl',
    },
  ),
  PackingItem(
    id: 'lezita_pro_9x9',
    title: '9×9 Lezita Pro',
    category: 'Lezita',
    keywords: [
      'lezita',
      'lezita pro',
      '9x9',
      '9×9',
      'pro',
      'lezita 9x9',
      'lezita 9×9',
      '9x9 lezita pro',
      '9×9 lezita pro',
      'poşet',
      'poset',
      'koli',
      'palet',
      'turpal',
      'robot',
      'skt',
      'son kullanma',
      '2 yıl',
      '675 kg',
      'tam palet',
      'film',
      'filim',
    ],
    details: {
      'Poşet yazıcı': 'lezita 9×9 poset nisan-2023',
      'Koli yazıcı': 'lezita pro 9×9 koli 5×2.5 Kg',
      'Koli': '260.390.290 lezita',
      'Palet': '80×120 (Turpal palet)',
      'SKT': '2 Yıl',
      'Filim': 'Kendine özgü Lezita filim',
      'Robot sırası': '6 sıra',
      'Tam palet kg': '675 kg',
      'Koli içi poşet sayısı': '5 Adet',
    },
  ),
];

class AppColors {
  static const Color navy = Color(0xFF0B2D4D);
  static const Color green = Color(0xFF43A047);
  static const Color lightBg = Color(0xFFF4F7F6);
  static const Color darkBg = Color(0xFF071D2E);
  static const Color darkCard = Color(0xFF0E2A3E);
  static const Color darkBorder = Color(0xFF1D4057);
  static const Color border = Color(0xFFE3ECE8);
}

class AppUi {
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color pageBg(BuildContext context) {
    return isDark(context) ? AppColors.darkBg : AppColors.lightBg;
  }

  static Color card(BuildContext context) {
    return isDark(context) ? AppColors.darkCard : Colors.white;
  }

  static Color input(BuildContext context) {
    return isDark(context) ? const Color(0xFF102F45) : Colors.white;
  }

  static Color border(BuildContext context) {
    return isDark(context) ? AppColors.darkBorder : AppColors.border;
  }

  static Color text(BuildContext context) {
    return isDark(context) ? Colors.white : AppColors.navy;
  }

  static Color muted(BuildContext context) {
    return isDark(context) ? Colors.white70 : AppColors.navy.withOpacity(0.72);
  }
}

class BackupHelper {
  static List<PackingItem> parseItems(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => PackingItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static String encodeItems(List<PackingItem> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }

  static String createBackupCode(List<PackingItem> items) {
    final backup = {
      'app': 'Finefood Paketleme',
      'backupVersion': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  static List<PackingItem> parseBackupCode(String raw) {
    final decoded = jsonDecode(raw);

    final rawItems = decoded is Map && decoded['items'] is List
        ? decoded['items'] as List
        : decoded is List
            ? decoded
            : null;

    if (rawItems == null) {
      throw const FormatException('Yedek kodu okunamadı.');
    }

    return rawItems
        .map((e) => PackingItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<List<PackingItem>> readSavedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAll = prefs.getString(itemsStorageKey);

    if (savedAll != null && savedAll.trim().isNotEmpty) {
      try {
        return parseItems(savedAll);
      } catch (_) {}
    }

    return List<PackingItem>.from(builtInPackingItems);
  }

  static Future<void> saveItems(List<PackingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(itemsStorageKey, encodeItems(items));
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 170,
                  height: 170,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(42),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Finefood',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Paketleme',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Hızlı ürün bilgi arama',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 34),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: AppColors.green,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  String _selectedCategory = filterAll;
  bool _loading = true;

  List<PackingItem> _items = [];
  Set<String> _favoriteIds = {};
  List<String> _recentIds = [];

  List<String> get categories {
    final set = <String>{
      filterAll,
      filterFavorites,
      filterRecent,
    };

    for (final item in _items) {
      if (item.category.trim().isNotEmpty) {
        set.add(item.category.trim());
      }
    }

    return set.toList();
  }

  List<PackingItem> get filteredItems {
    if (_selectedCategory == filterFavorites) {
      return _items
          .where((item) =>
              _favoriteIds.contains(item.id) && item.matches(_query))
          .toList();
    }

    if (_selectedCategory == filterRecent) {
      final map = {for (final item in _items) item.id: item};
      return _recentIds
          .map((id) => map[id])
          .whereType<PackingItem>()
          .where((item) => item.matches(_query))
          .toList();
    }

    return _items.where((item) {
      final categoryOk =
          _selectedCategory == filterAll || item.category == _selectedCategory;

      return categoryOk && item.matches(_query);
    }).toList();
  }

  int _categoryCount(String category) {
    if (category == filterAll) return _items.length;
    if (category == filterFavorites) {
      return _items.where((item) => _favoriteIds.contains(item.id)).length;
    }
    if (category == filterRecent) {
      final validIds = _items.map((e) => e.id).toSet();
      return _recentIds.where(validIds.contains).length;
    }

    return _items.where((item) => item.category == category).length;
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedAll = prefs.getString(itemsStorageKey);
    List<PackingItem> loadedItems = [];

    if (savedAll != null && savedAll.trim().isNotEmpty) {
      try {
        loadedItems = BackupHelper.parseItems(savedAll);
      } catch (_) {
        loadedItems = [];
      }
    }

    if (loadedItems.isEmpty) {
      loadedItems = List<PackingItem>.from(builtInPackingItems);

      final oldCustom = prefs.getString(oldCustomStorageKey);
      if (oldCustom != null && oldCustom.trim().isNotEmpty) {
        try {
          final oldItems = BackupHelper.parseItems(oldCustom);
          loadedItems.addAll(oldItems);
        } catch (_) {}
      }

      await BackupHelper.saveItems(loadedItems);
    }

    final validIds = loadedItems.map((e) => e.id).toSet();

    final favoriteIds = (prefs.getStringList(favoritesStorageKey) ?? [])
        .where(validIds.contains)
        .toSet();

    final recentIds = (prefs.getStringList(recentStorageKey) ?? [])
        .where(validIds.contains)
        .toList();

    setState(() {
      _items = loadedItems;
      _favoriteIds = favoriteIds;
      _recentIds = recentIds;
      _loading = false;

      if (!categories.contains(_selectedCategory)) {
        _selectedCategory = filterAll;
      }
    });
  }

  Future<void> _saveItems() async {
    await BackupHelper.saveItems(_items);
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(favoritesStorag
