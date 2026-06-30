import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String itemsStorageKey = 'packing_items_all_v2';
const String oldCustomStorageKey = 'custom_packing_items_v1';

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
  String _selectedCategory = 'Tümü';
  bool _loading = true;
  List<PackingItem> _items = [];

  List<String> get categories {
    final set = <String>{'Tümü'};

    for (final item in _items) {
      if (item.category.trim().isNotEmpty) {
        set.add(item.category.trim());
      }
    }

    return set.toList();
  }

  List<PackingItem> get filteredItems {
    return _items.where((item) {
      final categoryOk =
          _selectedCategory == 'Tümü' || item.category == _selectedCategory;

      return categoryOk && item.matches(_query);
    }).toList();
  }

  int _categoryCount(String category) {
    if (category == 'Tümü') return _items.length;
    return _items.where((item) => item.category == category).length;
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();

    final savedAll = prefs.getString(itemsStorageKey);

    if (savedAll != null && savedAll.trim().isNotEmpty) {
      try {
        final savedItems = BackupHelper.parseItems(savedAll);
        setState(() {
          _items = savedItems;
          _loading = false;
          if (!categories.contains(_selectedCategory)) {
            _selectedCategory = 'Tümü';
          }
        });
        return;
      } catch (_) {}
    }

    final loadedItems = List<PackingItem>.from(builtInPackingItems);

    final oldCustom = prefs.getString(oldCustomStorageKey);
    if (oldCustom != null && oldCustom.trim().isNotEmpty) {
      try {
        final oldItems = BackupHelper.parseItems(oldCustom);
        loadedItems.addAll(oldItems);
      } catch (_) {}
    }

    setState(() {
      _items = loadedItems;
      _loading = false;
    });

    await _saveItems();
  }

  Future<void> _saveItems() async {
    await BackupHelper.saveItems(_items);
  }

  Future<void> _openAddProduct() async {
    final newItem = await Navigator.of(context).push<PackingItem>(
      MaterialPageRoute(
        builder: (_) => const AddProductScreen(),
      ),
    );

    if (newItem == null) return;

    setState(() {
      _items.add(newItem);
      _selectedCategory = newItem.category;
    });

    await _saveItems();

    if (!mounted) return;
    _showSnack('${newItem.title} eklendi');
  }

  Future<void> _updateItem(PackingItem updatedItem) async {
    setState(() {
      final index = _items.indexWhere((e) => e.id == updatedItem.id);

      if (index == -1) {
        _items.add(updatedItem);
      } else {
        _items[index] = updatedItem;
      }

      _selectedCategory = updatedItem.category;
    });

    await _saveItems();

    if (!mounted) return;
    _showSnack('${updatedItem.title} güncellendi');
  }

  Future<void> _deleteItem(PackingItem item) async {
    setState(() {
      _items.removeWhere((e) => e.id == item.id);
      if (!categories.contains(_selectedCategory)) {
        _selectedCategory = 'Tümü';
      }
    });

    await _saveItems();

    if (!mounted) return;
    _showSnack('${item.title} silindi');
  }

  Future<void> _copyItem(PackingItem item) async {
    await Clipboard.setData(ClipboardData(text: item.copyText));

    if (!mounted) return;

    _showSnack('${item.title} bilgileri kopyalandı');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = filteredItems;
    final currentCategories = categories;

    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.compactListNotifier,
      builder: (context, compactList, _) {
        return Scaffold(
          backgroundColor: AppUi.pageBg(context),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAddProduct,
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Ürün Ekle',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  onSettingsClosed: _loadItems,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: AppUi.text(context),
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Ürün ara... Örn: Mc, Lezita, 9x9',
                      hintStyle: TextStyle(color: AppUi.muted(context)),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppUi.muted(context),
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _query = '';
                                });
                              },
                              icon: Icon(
                                Icons.close,
                                color: AppUi.muted(context),
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: AppUi.input(context),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: compactList ? 12 : 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (!_loading)
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      scrollDirection: Axis.horizontal,
                      itemCount: currentCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = currentCategories[index];
                        final selected = category == _selectedCategory;

                        return ChoiceChip(
                          selected: selected,
                          label: Text(
                            '$category (${_categoryCount(category)})',
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppUi.text(context),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          selectedColor: AppColors.green,
                          backgroundColor: AppUi.card(context),
                          side: BorderSide(
                            color: selected
                                ? AppColors.green
                                : AppUi.border(context),
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Text(
                        _selectedCategory == 'Tümü'
                            ? 'Kayıtlar'
                            : _selectedCategory,
                        style: TextStyle(
                          color: AppUi.text(context),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${items.length} sonuç',
                          style: const TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.green,
                          ),
                        )
                      : items.isEmpty
                          ? const _EmptyState()
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 0, 18, 100),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => SizedBox(
                                height: compactList ? 8 : 12,
                              ),
                              itemBuilder: (context, index) {
                                final item = items[index];

                                return _PackingCard(
                                  item: item,
                                  compact: compactList,
                                  onCopy: () => _copyItem(item),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => DetailScreen(
                                          item: item,
                                          onUpdate: _updateItem,
                                          onDelete: _deleteItem,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final Future<void> Function()? onSettingsClosed;

  const _Header({
    this.onSettingsClosed,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.compactListNotifier,
      builder: (context, compact, _) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.all(compact ? 14 : 18),
          padding: EdgeInsets.all(compact ? 14 : 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.navy,
                Color(0xFF123F67),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  AppUi.isDark(context) ? 0.35 : 0.18,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 62 : 76,
                height: compact ? 62 : 76,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finefood',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 23 : 27,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    Text(
                      'Paketleme',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: compact ? 19 : 22,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    if (!compact) const SizedBox(height: 7),
                    if (!compact)
                      const Text(
                        'Hızlı ürün bilgi arama',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );

                  if (changed == true) {
                    await onSettingsClosed?.call();
                  }
                },
                icon: const Icon(Icons.settings_rounded),
                color: Colors.white,
                tooltip: 'Ayarlar',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PackingCard extends StatelessWidget {
  final PackingItem item;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _PackingCard({
    required this.item,
    required this.compact,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final firstDetails = item.details.entries.take(compact ? 2 : 4).toList();

    return Material(
      color: AppUi.card(context),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppUi.border(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: compact ? 42 : 48,
                    height: compact ? 42 : 48,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: AppUi.text(context),
                        fontSize: compact ? 18 : 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppUi.muted(context),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 14),
              ...firstDetails.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(bottom: compact ? 4 : 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: TextStyle(
                          color: AppUi.text(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: AppUi.muted(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!compact) const SizedBox(height: 8),
              if (!compact)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('Detay'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onCopy,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Hepsini kopyala'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddProductScreen extends StatefulWidget {
  final PackingItem? existingItem;

  const AddProductScreen({
    super.key,
    this.existingItem,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _posetController = TextEditingController();
  final _koliYaziciController = TextEditingController();
  final _koliController = TextEditingController();
  final _paletController = TextEditingController();
  final _sktController = TextEditingController();
  final _filimController = TextEditingController();
  final _robotController = TextEditingController();
  final _tamPaletKgController = TextEditingController();
  final _koliIciPosetController = TextEditingController();

  bool get isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();

    final item = widget.existingItem;
    if (item == null) return;

    _titleController.text = item.title;
    _categoryController.text = item.category;
    _posetController.text = _detailValue(item.details, ['Poşet yazıcı']);
    _koliYaziciController.text = _detailValue(item.details, ['Koli yazıcı']);
    _koliController.text = _detailValue(item.details, ['Koli']);
    _paletController.text = _detailValue(item.details, ['Palet']);
    _sktController.text = _detailValue(item.details, ['SKT', 'Skt']);
    _filimController.text = _detailValue(item.details, ['Filim', 'Film']);
    _robotController.text = _detailValue(item.details, ['Robot sırası']);
    _tamPaletKgController.text = _detailValue(item.details, ['Tam palet kg']);
    _koliIciPosetController.text = _detailValue(
      item.details,
      ['Koli içi poşet sayısı', 'Koli ici poşet sayısı'],
    );
  }

  String _detailValue(Map<String, String> details, List<String> possibleKeys) {
    for (final entry in details.entries) {
      for (final key in possibleKeys) {
        if (_normalize(entry.key) == _normalize(key)) {
          return entry.value;
        }
      }
    }

    return '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _posetController.dispose();
    _koliYaziciController.dispose();
    _koliController.dispose();
    _paletController.dispose();
    _sktController.dispose();
    _filimController.dispose();
    _robotController.dispose();
    _tamPaletKgController.dispose();
    _koliIciPosetController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final category = _categoryController.text.trim().isEmpty
        ? _guessCategory(title)
        : _categoryController.text.trim();

    final details = <String, String>{};

    void addDetail(String key, TextEditingController controller) {
      final value = controller.text.trim();
      if (value.isNotEmpty) {
        details[key] = value;
      }
    }

    addDetail('Poşet yazıcı', _posetController);
    addDetail('Koli yazıcı', _koliYaziciController);
    addDetail('Koli', _koliController);
    addDetail('Palet', _paletController);
    addDetail('SKT', _sktController);
    addDetail('Filim', _filimController);
    addDetail('Robot sırası', _robotController);
    addDetail('Tam palet kg', _tamPaletKgController);
    addDetail('Koli içi poşet sayısı', _koliIciPosetController);

    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir ürün bilgisi gir kank.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
        ),
      );
      return;
    }

    final item = PackingItem(
      id: widget.existingItem?.id ??
          'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      keywords: _createKeywords(
        title: title,
        category: category,
        details: details,
      ),
      details: details,
    );

    Navigator.of(context).pop(item);
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool requiredField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        textInputAction: TextInputAction.next,
        style: TextStyle(
          color: AppUi.text(context),
          fontWeight: FontWeight.w600,
        ),
        validator: requiredField
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label zorunlu';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: AppUi.input(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppUi.pageBg(context),
      appBar: AppBar(
        title: Text(isEditing ? 'Ürünü Düzenle' : 'Ürün Ekle'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: AppUi.pageBg(context),
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: Text(isEditing ? 'Güncelle' : 'Kaydet'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      isEditing
                          ? 'Ürün bilgilerini değiştir, güncelle ve aramada hemen kullan.'
                          : 'Yeni ürün bilgilerini doldur, kaydet ve aramada hemen kullan.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _input(
              controller: _titleController,
              label: 'Başlık',
              hint: 'Örn: 9×9 Lezita Pro',
              icon: Icons.title_rounded,
              requiredField: true,
            ),
            _input(
              controller: _categoryController,
              label: 'Kategori',
              hint: 'Örn: Lezita, Mcdonalds, Eklenen Ürünler',
              icon: Icons.category_rounded,
            ),
            _input(
              controller: _posetController,
              label: 'Poşet yazıcı',
              icon: Icons.print_rounded,
            ),
            _input(
              controller: _koliYaziciController,
              label: 'Koli yazıcı',
              icon: Icons.inventory_rounded,
            ),
            _input(
              controller: _koliController,
              label: 'Koli',
              icon: Icons.archive_rounded,
            ),
            _input(
              controller: _paletController,
              label: 'Palet',
              icon: Icons.view_in_ar_rounded,
            ),
            _input(
              controller: _sktController,
              label: 'SKT',
              icon: Icons.event_available_rounded,
            ),
            _input(
              controller: _filimController,
              label: 'Filim',
              icon: Icons.layers_rounded,
            ),
            _input(
              controller: _robotController,
              label: 'Robot sırası',
              icon: Icons.smart_toy_rounded,
            ),
            _input(
              controller: _tamPaletKgController,
              label: 'Tam palet kg',
              icon: Icons.monitor_weight_rounded,
            ),
            _input(
              controller: _koliIciPosetController,
              label: 'Koli içi poşet sayısı',
              icon: Icons.shopping_bag_rounded,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class DetailScreen extends StatefulWidget {
  final PackingItem item;
  final Future<void> Function(PackingItem updatedItem) onUpdate;
  final Future<void> Function(PackingItem item) onDelete;

  const DetailScreen({
    super.key,
    required this.item,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late PackingItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _copyAll(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _item.copyText));

    if (!context.mounted) return;

    _showSnack(context, '${_item.title} bilgileri kopyalandı');
  }

  Future<void> _copyField(
    BuildContext context,
    String title,
    String value,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));

    if (!context.mounted) return;

    _showSnack(context, '$title kopyalandı');
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
      ),
    );
  }

  Future<void> _editItem() async {
    final updated = await Navigator.of(context).push<PackingItem>(
      MaterialPageRoute(
        builder: (_) => AddProductScreen(existingItem: _item),
      ),
    );

    if (updated == null) return;

    await widget.onUpdate(updated);

    if (!mounted) return;

    setState(() {
      _item = updated;
    });
  }

  Future<void> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ürünü sil?'),
        content: Text('${_item.title} kaydı silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (result != true) return;

    await widget.onDelete(_item);

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  Color _fieldColor(String key) {
    final normalized = _normalize(key);

    if (normalized.contains('poset')) return const Color(0xFF2E7D32);
    if (normalized.contains('koli yazici')) return const Color(0xFF1565C0);
    if (normalized.contains('koli')) return const Color(0xFF6A1B9A);
    if (normalized.contains('skt')) return const Color(0xFFEF6C00);
    if (normalized.contains('robot')) return const Color(0xFF00838F);
    if (normalized.contains('palet')) return const Color(0xFFC62828);
    if (normalized.contains('kg')) return const Color(0xFF5D4037);

    return AppColors.green;
  }

  IconData _fieldIcon(String key) {
    final normalized = _normalize(key);

    if (normalized.contains('poset')) return Icons.print_rounded;
    if (normalized.contains('koli yazici')) return Icons.inventory_rounded;
    if (normalized.contains('koli')) return Icons.archive_rounded;
    if (normalized.contains('skt')) return Icons.event_available_rounded;
    if (normalized.contains('robot')) return Icons.smart_toy_rounded;
    if (normalized.contains('palet')) return Icons.view_in_ar_rounded;
    if (normalized.contains('filim') || normalized.contains('film')) {
      return Icons.layers_rounded;
    }
    if (normalized.contains('kg')) return Icons.monitor_weight_rounded;

    return Icons.info_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppUi.pageBg(context),
      appBar: AppBar(
        title: Text(_item.title),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _editItem,
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Düzenle',
          ),
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_rounded),
            tooltip: 'Sil',
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: AppUi.pageBg(context),
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => _copyAll(context),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Tüm bilgileri kopyala'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ürün Bilgisi',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _item.category,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._item.details.entries.map(
            (entry) {
              final color = _fieldColor(entry.key);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppUi.card(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppUi.border(context),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _fieldIcon(entry.key),
                        color: color,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry.value,
                            style: TextStyle(
                              color: AppUi.text(context),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kopyala',
                      onPressed: () {
                        _copyField(context, entry.key, entry.value);
                      },
                      icon: const Icon(Icons.copy_rounded),
                      color: AppUi.text(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _themeTitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Beyaz tema';
      case ThemeMode.dark:
        return 'Siyah tema';
      case ThemeMode.system:
        return 'Telefon temasını kullan';
    }
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.phone_android_rounded;
    }
  }

  String _textSizeTitle(AppTextSize size) {
    switch (size) {
      case AppTextSize.small:
        return 'Küçük yazı';
      case AppTextSize.normal:
        return 'Normal yazı';
      case AppTextSize.large:
        return 'Büyük yazı';
    }
  }

  String _textSizeSubtitle(AppTextSize size) {
    switch (size) {
      case AppTextSize.small:
        return 'Ekrana daha fazla bilgi sığar.';
      case AppTextSize.normal:
        return 'Dengeli ve rahat kullanım.';
      case AppTextSize.large:
        return 'Vardiyada hızlı okumak için daha büyük.';
    }
  }

  IconData _textSizeIcon(AppTextSize size) {
    switch (size) {
      case AppTextSize.small:
        return Icons.text_fields_rounded;
      case AppTextSize.normal:
        return Icons.format_size_rounded;
      case AppTextSize.large:
        return Icons.text_increase_rounded;
    }
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(
        title,
        style: TextStyle(
          color: AppUi.text(context),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Future<void> _copyBackup(BuildContext context) async {
    final items = await BackupHelper.readSavedItems();
    final backupCode = BackupHelper.createBackupCode(items);

    await Clipboard.setData(ClipboardData(text: backupCode));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yedek kodu kopyalandı. Notlara veya WhatsApp’a kaydet.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
      ),
    );
  }

  Future<void> _openRestore(BuildContext context) async {
    final restored = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const RestoreBackupScreen(),
      ),
    );

    if (restored == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppUi.pageBg(context),
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Uygulama görünümünü, listeyi ve yedekleri buradan yönetebilirsin.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(context, 'Tema'),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppSettings.themeModeNotifier,
            builder: (context, currentMode, _) {
              return Column(
                children: ThemeMode.values.map(
                  (mode) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppUi.card(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppUi.border(context)),
                      ),
                      child: RadioListTile<ThemeMode>(
                        value: mode,
                        groupValue: currentMode,
                        activeColor: AppColors.green,
                        onChanged: (value) async {
                          if (value == null) return;
                          await AppSettings.setThemeMode(value);
                        },
                        secondary: Icon(
                          _themeIcon(mode),
                          color: mode == currentMode
                              ? AppColors.green
                              : AppUi.muted(context),
                        ),
                        title: Text(
                          _themeTitle(mode),
                          style: TextStyle(
                            color: AppUi.text(context),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              );
            },
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, 'Yazı boyutu'),
          ValueListenableBuilder<AppTextSize>(
            valueListenable: AppSettings.textSizeNotifier,
            builder: (context, currentSize, _) {
              return Column(
                children: AppTextSize.values.map(
                  (size) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppUi.card(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppUi.border(context)),
                      ),
                      child: RadioListTile<AppTextSize>(
                        value: size,
                        groupValue: currentSize,
                        activeColor: AppColors.green,
                        onChanged: (value) async {
                          if (value == null) return;
                          await AppSettings.setTextSize(value);
                        },
                        secondary: Icon(
                          _textSizeIcon(size),
                          color: size == currentSize
                              ? AppColors.green
                              : AppUi.muted(context),
                        ),
                        title: Text(
                          _textSizeTitle(size),
                          style: TextStyle(
                            color: AppUi.text(context),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          _textSizeSubtitle(size),
                          style: TextStyle(
                            color: AppUi.muted(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              );
            },
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, 'Liste görünümü'),
          ValueListenableBuilder<bool>(
            valueListenable: AppSettings.compactListNotifier,
            builder: (context, compact, _) {
              return Container(
                decoration: BoxDecoration(
                  color: AppUi.card(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppUi.border(context)),
                ),
                child: SwitchListTile(
                  value: compact,
                  activeColor: AppColors.green,
                  onChanged: (value) async {
                    await AppSettings.setCompactList(value);
                  },
                  secondary: Icon(
                    compact
                        ? Icons.view_headline_rounded
                        : Icons.view_agenda_rounded,
                    color: compact ? AppColors.green : AppUi.muted(context),
                  ),
                  title: Text(
                    'Sıkı görünüm',
                    style: TextStyle(
                      color: AppUi.text(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'Açık olursa ekrana daha fazla ürün sığar.',
                    style: TextStyle(
                      color: AppUi.muted(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, 'Yedekleme'),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppUi.card(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppUi.border(context)),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.copy_all_rounded,
                color: AppColors.green,
              ),
              title: Text(
                'Yedek kodu oluştur',
                style: TextStyle(
                  color: AppUi.text(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                'Tüm ürünleri kopyalanabilir yedek koduna çevirir.',
                style: TextStyle(
                  color: AppUi.muted(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: AppUi.muted(context),
              ),
              onTap: () => _copyBackup(context),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppUi.card(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppUi.border(context)),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.restore_rounded,
                color: AppColors.green,
              ),
              title: Text(
                'Yedekten geri yükle',
                style: TextStyle(
                  color: AppUi.text(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                'Daha önce aldığın yedek kodunu yapıştırır.',
                style: TextStyle(
                  color: AppUi.muted(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: AppUi.muted(context),
              ),
              onTap: () => _openRestore(context),
            ),
          ),
        ],
      ),
    );
  }
}

class RestoreBackupScreen extends StatefulWidget {
  const RestoreBackupScreen({super.key});

  @override
  State<RestoreBackupScreen> createState() => _RestoreBackupScreenState();
}

class _RestoreBackupScreenState extends State<RestoreBackupScreen> {
  final TextEditingController _backupController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _backupController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
      ),
    );
  }

  Future<void> _restore() async {
    final raw = _backupController.text.trim();

    if (raw.isEmpty) {
      _showSnack('Yedek kodunu yapıştırman lazım kank.');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final items = BackupHelper.parseBackupCode(raw);

      if (items.isEmpty) {
        _showSnack('Bu yedekte ürün bulunamadı.');
        setState(() {
          _loading = false;
        });
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Yedek geri yüklensin mi?'),
          content: Text(
            '${items.length} ürün geri yüklenecek. Mevcut liste bu yedekle değişecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Geri yükle'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() {
          _loading = false;
        });
        return;
      }

      await BackupHelper.saveItems(items);

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showSnack('Yedek kodu okunamadı. Eksik veya yanlış olabilir.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppUi.pageBg(context),
      appBar: AppBar(
        title: const Text('Yedekten Geri Yükle'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: AppUi.pageBg(context),
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _loading ? null : _restore,
            icon: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.restore_rounded),
            label: Text(_loading ? 'Yükleniyor...' : 'Geri yükle'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_rounded,
                  color: AppColors.green,
                  size: 34,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Ayarlar > Yedek kodu oluştur ile aldığın kodu buraya yapıştır.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _backupController,
            minLines: 12,
            maxLines: 20,
            style: TextStyle(
              color: AppUi.text(context),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'Yedek kodunu buraya yapıştır...',
              hintStyle: TextStyle(color: AppUi.muted(context)),
              filled: true,
              fillColor: AppUi.input(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: AppUi.border(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: AppUi.border(context)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Not: Geri yükleme mevcut ürün listesini yedekteki listeyle değiştirir.',
            style: TextStyle(
              color: AppUi.muted(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 58,
              color: AppUi.muted(context),
            ),
            const SizedBox(height: 12),
            Text(
              'Sonuç bulunamadı',
              style: TextStyle(
                color: AppUi.text(context),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Başka bir kelime ile arama yap.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppUi.muted(context)),
            ),
          ],
        ),
      ),
    );
  }
}
