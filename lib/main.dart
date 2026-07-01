import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String itemsStorageKey = 'packing_items_all_v3';
const String oldItemsStorageKey = 'packing_items_all_v2';
const String oldCustomStorageKey = 'custom_packing_items_v1';
const String favoritesStorageKey = 'favorite_item_ids_v1';
const String recentStorageKey = 'recent_item_ids_v1';
const String searchHistoryStorageKey = 'search_history_v1';
const String autoBackupStorageKey = 'auto_backup_v1';
const String pinStorageKey = 'app_pin_v1';

const String filterAll = 'Tümü';
const String filterFavorites = 'Favoriler';
const String filterRecent = 'Son Bakılanlar';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.loadAll();
  runApp(const FinefoodApp());
}

enum AppTextSize { small, normal, large }

enum SortMode { newestFirst, alphabetical, category, favoritesFirst }

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
  static const String sortModeKey = 'sort_mode_v1';

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static final ValueNotifier<AppTextSize> textSizeNotifier =
      ValueNotifier<AppTextSize>(AppTextSize.normal);

  static final ValueNotifier<bool> compactListNotifier =
      ValueNotifier<bool>(false);

  static final ValueNotifier<SortMode> sortModeNotifier =
      ValueNotifier<SortMode>(SortMode.newestFirst);

  static Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    themeModeNotifier.value =
        _themeModeFromString(prefs.getString(themeKey) ?? 'system');

    textSizeNotifier.value =
        _textSizeFromString(prefs.getString(textSizeKey) ?? 'normal');

    compactListNotifier.value = prefs.getBool(compactListKey) ?? false;

    sortModeNotifier.value =
        _sortModeFromString(prefs.getString(sortModeKey) ?? 'newestFirst');
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

  static Future<void> setSortMode(SortMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(sortModeKey, _sortModeToString(mode));
    sortModeNotifier.value = mode;
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

  static SortMode _sortModeFromString(String value) {
    switch (value) {
      case 'alphabetical':
        return SortMode.alphabetical;
      case 'category':
        return SortMode.category;
      case 'favoritesFirst':
        return SortMode.favoritesFirst;
      default:
        return SortMode.newestFirst;
    }
  }

  static String _sortModeToString(SortMode mode) {
    switch (mode) {
      case SortMode.newestFirst:
        return 'newestFirst';
      case SortMode.alphabetical:
        return 'alphabetical';
      case SortMode.category:
        return 'category';
      case SortMode.favoritesFirst:
        return 'favoritesFirst';
    }
  }
}

class PackingItem {
  final String id;
  final String title;
  final String category;
  final List<String> keywords;
  final Map<String, String> details;
  final String? imagePath;
  final String? code;

  const PackingItem({
    required this.id,
    required this.title,
    required this.category,
    required this.keywords,
    required this.details,
    this.imagePath,
    this.code,
  });

  String get copyText {
    final buffer = StringBuffer();
    buffer.writeln(title);
    buffer.writeln('Kategori: $category');

    if (code != null && code!.trim().isNotEmpty) {
      buffer.writeln('Kod: $code');
    }

    buffer.writeln('');

    details.forEach((key, value) {
      buffer.writeln('$key: $value');
    });

    return buffer.toString();
  }

  String? detailByKey(String wantedKey) {
    final wanted = _normalize(wantedKey);

    for (final entry in details.entries) {
      if (_normalize(entry.key) == wanted) {
        return entry.value;
      }
    }

    return null;
  }

  bool matches(String query) {
    final q = _normalize(query);
    if (q.isEmpty) return true;

    final searchableText = [
      title,
      category,
      code ?? '',
      ...keywords,
      ...details.keys,
      ...details.values,
    ].map(_normalize).join(' ');

    return searchableText.contains(q);
  }

  PackingItem copyWith({
    String? id,
    String? title,
    String? category,
    List<String>? keywords,
    Map<String, String>? details,
    String? imagePath,
    String? code,
    bool clearImage = false,
  }) {
    return PackingItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      keywords: keywords ?? this.keywords,
      details: details ?? this.details,
      imagePath: clearImage ? null : imagePath ?? this.imagePath,
      code: code ?? this.code,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'keywords': keywords,
      'details': details,
      'imagePath': imagePath,
      'code': code,
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
            code: (json['code'] ?? '').toString(),
            details: details.cast<String, String>(),
          );

    return PackingItem(
      id: (json['id'] ?? 'custom_${DateTime.now().millisecondsSinceEpoch}')
          .toString(),
      title: title,
      category: category,
      keywords: keywords,
      details: details.cast<String, String>(),
      imagePath: json['imagePath']?.toString(),
      code: json['code']?.toString(),
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
  String? code,
}) {
  final raw = <String>[
    title,
    category,
    code ?? '',
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

String? _canonicalDetailKey(String key) {
  final n = _normalize(key);

  if (n == 'baslik' || n == 'title') return null;
  if (n == 'kategori' || n == 'category') return null;
  if (n == 'kod' || n == 'barcode' || n == 'barkod' || n == 'qr') return null;

  if (n.contains('poset') && n.contains('yazici')) return 'Poşet yazıcı';
  if (n.contains('koli') && n.contains('yazici')) return 'Koli yazıcı';
  if (n == 'koli') return 'Koli';
  if (n == 'palet') return 'Palet';
  if (n == 'skt' || n.contains('son kullanma')) return 'SKT';
  if (n == 'filim' || n == 'film') return 'Filim';
  if (n.contains('robot')) return 'Robot sırası';
  if (n.contains('tam') && n.contains('palet') && n.contains('kg')) {
    return 'Tam palet kg';
  }
  if (n.contains('koli') && n.contains('poset') && n.contains('sayisi')) {
    return 'Koli içi poşet sayısı';
  }

  if (key.trim().isEmpty) return null;

  return key.trim();
}

int _createdValue(PackingItem item) {
  if (!item.id.startsWith('custom_')) return 0;
  final raw = item.id.replaceFirst('custom_', '').split('_').first;
  return int.tryParse(raw) ?? 0;
}

const List<PackingItem> builtInPackingItems = [
  PackingItem(
    id: 'mcdonalds_7x7',
    title: 'Mcdonalds 7×7',
    category: 'Mcdonalds',
    code: 'MC-7X7',
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
      'MC-7X7',
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
    code: 'LEZITA-9X9-PRO',
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
      'LEZITA-9X9-PRO',
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

class StorageHelper {
  static List<PackingItem> parseItems(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => PackingItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static String encodeItems(List<PackingItem> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }

  static Future<List<PackingItem>> readItems() async {
    final prefs = await SharedPreferences.getInstance();

    final savedV3 = prefs.getString(itemsStorageKey);
    if (savedV3 != null && savedV3.trim().isNotEmpty) {
      try {
        return parseItems(savedV3);
      } catch (_) {}
    }

    final savedV2 = prefs.getString(oldItemsStorageKey);
    if (savedV2 != null && savedV2.trim().isNotEmpty) {
      try {
        final old = parseItems(savedV2);
        await saveItems(old);
        return old;
      } catch (_) {}
    }

    final loadedItems = List<PackingItem>.from(builtInPackingItems);

    final oldCustom = prefs.getString(oldCustomStorageKey);
    if (oldCustom != null && oldCustom.trim().isNotEmpty) {
      try {
        loadedItems.addAll(parseItems(oldCustom));
      } catch (_) {}
    }

    await saveItems(loadedItems);
    return loadedItems;
  }

  static Future<void> saveItems(List<PackingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(itemsStorageKey, encodeItems(items));
  }

  static String createBackupCode(List<PackingItem> items) {
    final backup = {
      'app': 'Finefood Paketleme',
      'backupVersion': 2,
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

  static Future<void> saveAutoBackup(List<PackingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(autoBackupStorageKey, createBackupCode(items));
  }

  static Future<String?> readAutoBackupCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(autoBackupStorageKey);
  }
}

class SecurityHelper {
  static Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(pinStorageKey);

    if (pin == null || pin.trim().isEmpty) return null;

    return pin;
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pinStorageKey, pin);
  }

  static Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(pinStorageKey);
  }
}

class FileHelper {
  static Future<String?> pickAndSaveImage(ImageSource source) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );

    if (picked == null) return null;

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'finefood_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = '${directory.path}/$fileName';

    final bytes = await picked.readAsBytes();
    await File(newPath).writeAsBytes(bytes);

    return newPath;
  }
}

class BulkParser {
  static List<PackingItem> parse(String raw) {
    final lines = raw.replaceAll('\r', '').split('\n');
    final blocks = <List<String>>[];
    var current = <String>[];

    for (final line in lines) {
      final clean = line.trim();
      if (clean.isEmpty) continue;

      final n = _normalize(clean);

      if (n.startsWith('baslik') && current.isNotEmpty) {
        blocks.add(current);
        current = <String>[];
      }

      current.add(clean);
    }

    if (current.isNotEmpty) {
      blocks.add(current);
    }

    final items = <PackingItem>[];
    var index = 0;

    for (final block in blocks) {
      String title = '';
      String category = '';
      String code = '';
      final details = <String, String>{};

      for (final line in block) {
        final equalIndex = line.indexOf('=');
        final colonIndex = line.indexOf(':');

        int splitIndex = -1;

        if (equalIndex >= 0 && colonIndex >= 0) {
          splitIndex = equalIndex < colonIndex ? equalIndex : colonIndex;
        } else if (equalIndex >= 0) {
          splitIndex = equalIndex;
        } else if (colonIndex >= 0) {
          splitIndex = colonIndex;
        }

        if (splitIndex == -1) continue;

        final key = line.substring(0, splitIndex).trim();
        final value = line.substring(splitIndex + 1).trim();

        if (value.isEmpty) continue;

        final normalizedKey = _normalize(key);

        if (normalizedKey == 'baslik' || normalizedKey == 'title') {
          title = value;
          continue;
        }

        if (normalizedKey == 'kategori' || normalizedKey == 'category') {
          category = value;
          continue;
        }

        if (normalizedKey == 'kod' ||
            normalizedKey == 'barkod' ||
            normalizedKey == 'barcode' ||
            normalizedKey == 'qr') {
          code = value;
          continue;
        }

        final detailKey = _canonicalDetailKey(key);

        if (detailKey != null) {
          details[detailKey] = value;
        }
      }

      if (title.trim().isEmpty) continue;

      final finalCategory =
          category.trim().isEmpty ? _guessCategory(title) : category.trim();

      final item = PackingItem(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}_$index',
        title: title.trim(),
        category: finalCategory,
        code: code.trim().isEmpty ? null : code.trim(),
        keywords: _createKeywords(
          title: title.trim(),
          category: finalCategory,
          code: code,
          details: details,
        ),
        details: details,
      );

      items.add(item);
      index++;
    }

    return items;
  }
}

class PdfHelper {
  static Future<void> printAllProducts(List<PackingItem> items) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Text(
              'Finefood Paketleme',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Toplam ürün: ${items.length}'),
            pw.SizedBox(height: 20),
            ...items.map(
              (item) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 16),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item.title,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('Kategori: ${item.category}'),
                      if (item.code != null && item.code!.trim().isNotEmpty)
                        pw.Text('Kod: ${item.code}'),
                      pw.SizedBox(height: 6),
                      ...item.details.entries.map(
                        (entry) => pw.Text('${entry.key}: ${entry.value}'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'Finefood-Paketleme-Urun-Listesi.pdf',
      onLayout: (_) async => doc.save(),
    );
  }
}

class StatsHelper {
  static Future<Map<String, dynamic>> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final items = await StorageHelper.readItems();

    final favoriteIds = prefs.getStringList(favoritesStorageKey) ?? [];
    final recentIds = prefs.getStringList(recentStorageKey) ?? [];

    final categoryCounts = <String, int>{};

    for (final item in items) {
      categoryCounts[item.category] = (categoryCounts[item.category] ?? 0) + 1;
    }

    return {
      'total': items.length,
      'favorites': items.where((e) => favoriteIds.contains(e.id)).length,
      'recent': recentIds.length,
      'categories': categoryCounts,
    };
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

    Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;

      final pin = await SecurityHelper.getPin();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => pin == null ? const MainShell() : PinLockScreen(pin: pin),
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

class PinLockScreen extends StatefulWidget {
  final String pin;

  const PinLockScreen({
    super.key,
    required this.pin,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final TextEditingController _controller = TextEditingController();

  void _unlock() {
    if (_controller.text.trim() == widget.pin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainShell(),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PIN yanlış kank.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icon/app_icon.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 24),
                const Text(
                  'PIN Gir',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    hintText: '****',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _unlock(),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _unlock,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('Aç'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
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
