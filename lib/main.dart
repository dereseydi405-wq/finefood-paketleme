import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String itemsStorageKey = 'packing_items_all_v3';
const String oldItemsStorageKey = 'packing_items_all_v2';
const String oldCustomStorageKey = 'custom_packing_items_v1';
const String favoritesStorageKey = 'favorite_item_ids_v1';
const String recentStorageKey = 'recent_item_ids_v1';
const String searchHistoryStorageKey = 'search_history_v1';
const String autoBackupStorageKey = 'auto_backup_v1';
const String pinStorageKey = 'app_pin_v1';
const String trashStorageKey = 'deleted_items_v1';
const String historyStorageKey = 'change_history_v1';

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
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  int _refreshToken = 0;

  Future<void> _openAddProduct() async {
    final newItem = await Navigator.of(context).push<PackingItem>(
      MaterialPageRoute(
        builder: (_) => const AddProductScreen(),
      ),
    );

    if (newItem == null) return;

    final items = await StorageHelper.readItems();
    await StorageHelper.saveAutoBackup(items);

    final updatedItems = [
      ...items,
      newItem,
    ];

    await StorageHelper.saveItems(updatedItems);

    if (!mounted) return;

    setState(() {
      _refreshToken++;
      _selectedIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newItem.title} eklendi'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
      ),
    );
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      _openAddProduct();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        key: ValueKey('home_$_refreshToken'),
        onlyFavorites: false,
      ),
      HomeScreen(
        key: ValueKey('favorites_$_refreshToken'),
        onlyFavorites: true,
      ),
      const SizedBox.shrink(),
      SettingsScreen(
        key: ValueKey('settings_$_refreshToken'),
        onChanged: () {
          setState(() {
            _refreshToken++;
          });
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            selectedIcon: Icon(Icons.home_filled),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border_rounded),
            selectedIcon: Icon(Icons.star_rounded),
            label: 'Favoriler',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Ekle',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool onlyFavorites;

  const HomeScreen({
    super.key,
    required this.onlyFavorites,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  late String _selectedCategory;
  bool _loading = true;

  List<PackingItem> _items = [];
  Set<String> _favoriteIds = {};
  List<String> _recentIds = [];
  List<String> _searchHistory = [];

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
          .where(
            (item) => _favoriteIds.contains(item.id) && item.matches(_query),
          )
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

  List<PackingItem> _sortedItems(List<PackingItem> source, SortMode mode) {
    final result = List<PackingItem>.from(source);

    switch (mode) {
      case SortMode.newestFirst:
        result.sort((a, b) => _createdValue(b).compareTo(_createdValue(a)));
        break;

      case SortMode.alphabetical:
        result.sort(
          (a, b) => _normalize(a.title).compareTo(_normalize(b.title)),
        );
        break;

      case SortMode.category:
        result.sort((a, b) {
          final category =
              _normalize(a.category).compareTo(_normalize(b.category));

          if (category != 0) return category;

          return _normalize(a.title).compareTo(_normalize(b.title));
        });
        break;

      case SortMode.favoritesFirst:
        result.sort((a, b) {
          final af = _favoriteIds.contains(a.id) ? 0 : 1;
          final bf = _favoriteIds.contains(b.id) ? 0 : 1;

          if (af != bf) return af.compareTo(bf);

          return _normalize(a.title).compareTo(_normalize(b.title));
        });
        break;
    }

    return result;
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
    _selectedCategory = widget.onlyFavorites ? filterFavorites : filterAll;
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedItems = await StorageHelper.readItems();

    final validIds = loadedItems.map((e) => e.id).toSet();

    final favoriteIds = (prefs.getStringList(favoritesStorageKey) ?? [])
        .where(validIds.contains)
        .toSet();

    final recentIds = (prefs.getStringList(recentStorageKey) ?? [])
        .where(validIds.contains)
        .toList();

    final searchHistory = prefs.getStringList(searchHistoryStorageKey) ?? [];

    if (!mounted) return;

    setState(() {
      _items = loadedItems;
      _favoriteIds = favoriteIds;
      _recentIds = recentIds;
      _searchHistory = searchHistory.take(8).toList();
      _loading = false;

      if (!categories.contains(_selectedCategory)) {
        _selectedCategory = widget.onlyFavorites ? filterFavorites : filterAll;
      }
    });
  }

  Future<void> _saveItems() async {
    await StorageHelper.saveItems(_items);
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(favoritesStorageKey, _favoriteIds.toList());
  }

  Future<void> _saveRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(recentStorageKey, _recentIds);
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(searchHistoryStorageKey, _searchHistory);
  }

  Future<void> _addSearchHistory(String value) async {
    final q = value.trim();

    if (q.length < 2) return;

    setState(() {
      _searchHistory.removeWhere((e) => _normalize(e) == _normalize(q));
      _searchHistory.insert(0, q);

      if (_searchHistory.length > 8) {
        _searchHistory = _searchHistory.take(8).toList();
      }
    });

    await _saveSearchHistory();
  }

  Future<void> _markRecent(PackingItem item) async {
    setState(() {
      _recentIds.remove(item.id);
      _recentIds.insert(0, item.id);

      if (_recentIds.length > 15) {
        _recentIds = _recentIds.take(15).toList();
      }
    });

    await _saveRecent();
  }

  Future<void> _openAddProduct() async {
    final newItem = await Navigator.of(context).push<PackingItem>(
      MaterialPageRoute(
        builder: (_) => const AddProductScreen(),
      ),
    );

    if (newItem == null) return;

    await StorageHelper.saveAutoBackup(_items);

    setState(() {
      _items.add(newItem);
      _selectedCategory = newItem.category;
    });

    await _saveItems();

    if (!mounted) return;
    _showSnack('${newItem.title} eklendi');
  }

  Future<void> _openDetail(PackingItem item) async {
    if (_query.trim().isNotEmpty) {
      await _addSearchHistory(_query);
    }

    await _markRecent(item);

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          item: item,
          isFavorite: _favoriteIds.contains(item.id),
          onUpdate: _updateItem,
          onDelete: _deleteItem,
          onToggleFavorite: _toggleFavorite,
          onDuplicate: _duplicateItem,
        ),
      ),
    );

    await _loadAllData();
  }

  Future<void> _updateItem(PackingItem updatedItem) async {
  await StorageHelper.saveAutoBackup(_items);

  final oldIndex = _items.indexWhere((e) => e.id == updatedItem.id);
  final oldItem = oldIndex == -1 ? null : _items[oldIndex];

  if (oldItem == null) {
    await ChangeHistoryHelper.add(
      itemId: updatedItem.id,
      itemTitle: updatedItem.title,
      action: 'Yeni ürün eklendi',
    );
  } else {
    final changes = ChangeHistoryHelper.describeChanges(oldItem, updatedItem);

    for (final change in changes) {
      await ChangeHistoryHelper.add(
        itemId: updatedItem.id,
        itemTitle: updatedItem.title,
        action: change,
      );
    }
  }

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
  await StorageHelper.saveAutoBackup(_items);
  await TrashHelper.moveToTrash(item);
  await ChangeHistoryHelper.add(
    itemId: item.id,
    itemTitle: item.title,
    action: 'Ürün çöp kutusuna taşındı',
  );

  setState(() {
    _items.removeWhere((e) => e.id == item.id);
    _favoriteIds.remove(item.id);
    _recentIds.remove(item.id);

    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = widget.onlyFavorites ? filterFavorites : filterAll;
    }
  });

  await _saveItems();
  await _saveFavorites();
  await _saveRecent();

  if (!mounted) return;
  _showSnack('${item.title} çöp kutusuna taşındı.');
}

  Future<bool> _toggleFavorite(PackingItem item) async {
    final bool nowFavorite = !_favoriteIds.contains(item.id);

    setState(() {
      if (nowFavorite) {
        _favoriteIds.add(item.id);
      } else {
        _favoriteIds.remove(item.id);
      }
    });

    await _saveFavorites();

    if (!mounted) return nowFavorite;

    _showSnack(
      nowFavorite
          ? '${item.title} favorilere eklendi'
          : '${item.title} favorilerden çıkarıldı',
    );

    return nowFavorite;
  }

  Future<void> _duplicateItem(PackingItem item) async {
  await StorageHelper.saveAutoBackup(_items);

  final title = '${item.title} Kopya';
  final details = Map<String, String>.from(item.details);

  final newItem = PackingItem(
    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
    title: title,
    category: item.category,
    code: item.code == null ? null : '${item.code}-KOPYA',
    imagePath: item.imagePath,
    keywords: _createKeywords(
      title: title,
      category: item.category,
      code: item.code,
      details: details,
    ),
    details: details,
  );

  await ChangeHistoryHelper.add(
    itemId: newItem.id,
    itemTitle: newItem.title,
    action: '${item.title} ürününden çoğaltıldı',
  );

  setState(() {
    _items.add(newItem);
    _selectedCategory = newItem.category;
  });

  await _saveItems();

  if (!mounted) return;
  _showSnack('$title oluşturuldu');
}

  Future<void> _copyItem(PackingItem item) async {
    await Clipboard.setData(ClipboardData(text: item.copyText));

    if (!mounted) return;

    _showSnack('${item.title} bilgileri kopyalandı');
  }

  Future<void> _copyField(
    PackingItem item,
    String label,
    String value,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) return;

    _showSnack('${item.title} - $label kopyalandı');
  }

  void _useSearchHistory(String value) {
    _searchController.text = value;

    setState(() {
      _query = value;
    });
  }

  Future<void> _clearSearchHistory() async {
    setState(() {
      _searchHistory = [];
    });

    await _saveSearchHistory();
  }

  Future<void> _scanAndSearch() async {
  final result = await SimpleBarcodeScanner.scanBarcode(
    context,
    barcodeAppBar: const BarcodeAppBar(
      appBarTitle: 'Kod Okut',
      centerTitle: false,
      enableBackButton: true,
      backButtonIcon: Icon(Icons.arrow_back_ios),
    ),
    isShowFlashIcon: true,
    delayMillis: 500,
    cameraFace: CameraFace.back,
  );

  if (result == null || result.trim().isEmpty || result == '-1') return;

  _searchController.text = result.trim();

  setState(() {
    _query = result.trim();
  });

  await _addSearchHistory(result.trim());

  if (!mounted) return;
  _showSnack('Kod okutuldu: ${result.trim()}');
}

  Future<void> _printPdf() async {
    if (_items.isEmpty) {
      _showSnack('PDF için ürün yok kank.');
      return;
    }

    await PdfHelper.printAllProducts(_items);
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
    final currentCategories = categories;

    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.compactListNotifier,
      builder: (context, compactList, _) {
        return ValueListenableBuilder<SortMode>(
          valueListenable: AppSettings.sortModeNotifier,
          builder: (context, sortMode, _) {
            final items = _sortedItems(filteredItems, sortMode);

            return Scaffold(
              backgroundColor: AppUi.pageBg(context),
              floatingActionButton: widget.onlyFavorites
                  ? null
                  : FloatingActionButton.extended(
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
                      title: widget.onlyFavorites ? 'Favoriler' : 'Finefood',
                      subtitle: widget.onlyFavorites
                          ? 'Yıldızlı ürünlerin'
                          : 'Paketleme',
                      onScan: _scanAndSearch,
                      onPrint: _printPdf,
                    ),
                    if (!_loading && !widget.onlyFavorites)
                      ProfessionalDashboard(
                        items: _items,
                        favoriteIds: _favoriteIds,
                        recentIds: _recentIds,
                        onMissingTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MissingInfoReportScreen(
                                items: _items,
                              ),
                            ),
                          );
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: AppUi.text(context),
                          fontWeight: FontWeight.w600,
                        ),
                        onSubmitted: _addSearchHistory,
                        onChanged: (value) {
                          setState(() {
                            _query = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Ürün, kod veya barkod ara...',
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
                              : IconButton(
                                  onPressed: _scanAndSearch,
                                  icon: const Icon(Icons.qr_code_scanner),
                                  color: AppColors.green,
                                ),
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
                    if (_query.isEmpty && _searchHistory.isNotEmpty)
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          scrollDirection: Axis.horizontal,
                          itemCount: _searchHistory.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            if (index == _searchHistory.length) {
                              return ActionChip(
                                label: const Text('Temizle'),
                                avatar: const Icon(Icons.close_rounded),
                                onPressed: _clearSearchHistory,
                              );
                            }

                            final search = _searchHistory[index];

                            return ActionChip(
                              label: Text(search),
                              avatar: const Icon(Icons.history_rounded),
                              onPressed: () => _useSearchHistory(search),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (!_loading && !widget.onlyFavorites)
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

                            IconData? icon;

                            if (category == filterFavorites) {
                              icon = Icons.star_rounded;
                            } else if (category == filterRecent) {
                              icon = Icons.history_rounded;
                            }

                            return ChoiceChip(
                              selected: selected,
                              avatar: icon == null
                                  ? null
                                  : Icon(
                                      icon,
                                      size: 18,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.green,
                                    ),
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
                            widget.onlyFavorites
                                ? 'Favoriler'
                                : _selectedCategory == filterAll
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
                                      isFavorite:
                                          _favoriteIds.contains(item.id),
                                      onCopy: () => _copyItem(item),
                                      onQuickCopy: (label, value) {
                                        _copyField(item, label, value);
                                      },
                                      onTap: () => _openDetail(item),
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
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onScan;
  final VoidCallback onPrint;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.onScan,
    required this.onPrint,
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
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 23 : 27,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    Text(
                      subtitle,
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
                onPressed: onScan,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                color: Colors.white,
                tooltip: 'Kod okut',
              ),
              IconButton(
                onPressed: onPrint,
                icon: const Icon(Icons.picture_as_pdf_rounded),
                color: Colors.white,
                tooltip: 'PDF',
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
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final void Function(String label, String value) onQuickCopy;

  const _PackingCard({
    required this.item,
    required this.compact,
    required this.isFavorite,
    required this.onTap,
    required this.onCopy,
    required this.onQuickCopy,
  });

  bool get hasImage {
    final path = item.imagePath;

    if (path == null || path.trim().isEmpty) return false;

    return File(path).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    final firstDetails = item.details.entries.take(compact ? 2 : 4).toList();
    final poset = item.detailByKey('Poşet yazıcı');
    final koliYazici = item.detailByKey('Koli yazıcı');

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
              if (hasImage && !compact) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    File(item.imagePath!),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Container(
                    width: compact ? 42 : 48,
                    height: compact ? 42 : 48,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      hasImage
                          ? Icons.image_rounded
                          : Icons.local_shipping_rounded,
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
                  if (isFavorite)
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                    ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppUi.muted(context),
                  ),
                ],
              ),
              if (item.code != null && item.code!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Kod: ${item.code}',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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
              if (!compact && (poset != null || koliYazici != null))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (poset != null)
                        ActionChip(
                          avatar: const Icon(Icons.print_rounded),
                          label: const Text('Poşet kopyala'),
                          onPressed: () => onQuickCopy('Poşet yazıcı', poset),
                        ),
                      if (koliYazici != null)
                        ActionChip(
                          avatar: const Icon(Icons.inventory_rounded),
                          label: const Text('Koli yazıcı kopyala'),
                          onPressed: () =>
                              onQuickCopy('Koli yazıcı', koliYazici),
                        ),
                    ],
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
  final _codeController = TextEditingController();
  final _posetController = TextEditingController();
  final _koliYaziciController = TextEditingController();
  final _koliController = TextEditingController();
  final _paletController = TextEditingController();
  final _sktController = TextEditingController();
  final _filimController = TextEditingController();
  final _robotController = TextEditingController();
  final _tamPaletKgController = TextEditingController();
  final _koliIciPosetController = TextEditingController();

  String? _imagePath;
  bool _imageLoading = false;

  bool get isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();

    final item = widget.existingItem;
    if (item == null) return;

    _titleController.text = item.title;
    _categoryController.text = item.category;
    _codeController.text = item.code ?? '';
    _imagePath = item.imagePath;

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
    _codeController.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _imageLoading = true;
    });

    try {
      final path = await FileHelper.pickAndSaveImage(source);

      if (!mounted) return;

      if (path != null) {
        setState(() {
          _imagePath = path;
        });
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotoğraf alınamadı. İzinleri kontrol et.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _imageLoading = false;
        });
      }
    }
  }

  Future<void> _scanCode() async {
  final result = await SimpleBarcodeScanner.scanBarcode(
    context,
    barcodeAppBar: const BarcodeAppBar(
      appBarTitle: 'Kod Okut',
      centerTitle: false,
      enableBackButton: true,
      backButtonIcon: Icon(Icons.arrow_back_ios),
    ),
    isShowFlashIcon: true,
    delayMillis: 500,
    cameraFace: CameraFace.back,
  );

  if (result == null || result.trim().isEmpty || result == '-1') return;

  setState(() {
    _codeController.text = result.trim();
  });
}

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final category = _categoryController.text.trim().isEmpty
        ? _guessCategory(title)
        : _categoryController.text.trim();

    final code = _codeController.text.trim();

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

    final missing = <String>[];

    if (_posetController.text.trim().isEmpty) missing.add('Poşet yazıcı');
    if (_koliYaziciController.text.trim().isEmpty) missing.add('Koli yazıcı');
    if (_koliController.text.trim().isEmpty) missing.add('Koli');
    if (_paletController.text.trim().isEmpty) missing.add('Palet');
    if (_sktController.text.trim().isEmpty) missing.add('SKT');
    if (_robotController.text.trim().isEmpty) missing.add('Robot sırası');

    if (_koliIciPosetController.text.trim().isEmpty) {
      missing.add('Koli içi poşet sayısı');
    }

    if (missing.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Eksik bilgiler var'),
          content: Text(
            'Şu alanlar boş:\n\n${missing.join('\n')}\n\nYine de kaydedilsin mi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Düzenle'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    final item = PackingItem(
      id: widget.existingItem?.id ??
          'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      code: code.isEmpty ? null : code,
      imagePath: _imagePath,
      keywords: _createKeywords(
        title: title,
        category: category,
        code: code,
        details: details,
      ),
      details: details,
    );

    if (!mounted) return;

    Navigator.of(context).pop(item);
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool requiredField = false,
    Widget? suffix,
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
          suffixIcon: suffix,
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

  bool get _hasImage {
    final path = _imagePath;

    if (path == null || path.trim().isEmpty) return false;

    return File(path).existsSync();
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
                          ? 'Ürün bilgilerini, kodu ve fotoğrafı düzenle.'
                          : 'Yeni ürün bilgilerini doldur, kod veya fotoğraf ekle.',
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppUi.card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppUi.border(context)),
              ),
              child: Column(
                children: [
                  if (_hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_imagePath!),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_a_photo_rounded,
                          color: AppColors.green,
                          size: 42,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (_imageLoading)
                    const CircularProgressIndicator(color: AppColors.green)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.photo_library_rounded),
                          label: const Text('Galeri'),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.camera_alt_rounded),
                          label: const Text('Kamera'),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                        if (_hasImage)
                          ActionChip(
                            avatar: const Icon(Icons.delete_rounded),
                            label: const Text('Foto sil'),
                            onPressed: () {
                              setState(() {
                                _imagePath = null;
                              });
                            },
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ProductTemplateChips(
              onApplyTemplate: (template) {
                setState(() {
                  if (_titleController.text.trim().isEmpty) {
                    _titleController.text = template.titleHint;
                  }

                  _categoryController.text = template.category;

                  _posetController.text =
                      template.details['Poşet yazıcı'] ?? '';
                  _koliYaziciController.text =
                      template.details['Koli yazıcı'] ?? '';
                  _koliController.text = template.details['Koli'] ?? '';
                  _paletController.text = template.details['Palet'] ?? '';
                  _sktController.text = template.details['SKT'] ?? '';
                  _filimController.text = template.details['Filim'] ?? '';
                  _robotController.text =
                      template.details['Robot sırası'] ?? '';
                  _tamPaletKgController.text =
                      template.details['Tam palet kg'] ?? '';
                  _koliIciPosetController.text =
                      template.details['Koli içi poşet sayısı'] ?? '';
                });
              },
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
              hint: 'Örn: Lezita, Mcdonalds',
              icon: Icons.category_rounded,
            ),
            _input(
              controller: _codeController,
              label: 'Kod / Barkod / QR',
              hint: 'Elle yaz veya okut',
              icon: Icons.qr_code_rounded,
              suffix: IconButton(
                onPressed: _scanCode,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                color: AppColors.green,
              ),
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







class BulkAddScreen extends StatefulWidget {
  const BulkAddScreen({super.key});

  @override
  State<BulkAddScreen> createState() => _BulkAddScreenState();
}

class _BulkAddScreenState extends State<BulkAddScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _importProducts() async {
    final raw = _controller.text.trim();

    if (raw.isEmpty) {
      _showSnack('Toplu ürün metnini yapıştırman lazım kank.');
      return;
    }

    final items = BulkParser.parse(raw);

    if (items.isEmpty) {
      _showSnack('Ürün bulunamadı. Başlık = ... formatını kontrol et.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Toplu ürün eklensin mi?'),
        content: Text('${items.length} ürün eklenecek. Devam edilsin mi?'),
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
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _loading = true;
    });

    final savedItems = await StorageHelper.readItems();
    await StorageHelper.saveAutoBackup(savedItems);

    final merged = [
      ...savedItems,
      ...items,
    ];

    await StorageHelper.saveItems(merged);

    if (!mounted) return;

    Navigator.of(context).pop(true);
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
    return Scaffold(
      backgroundColor: AppUi.pageBg(context),
      appBar: AppBar(
        title: const Text('Toplu Ürün Ekle'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: AppUi.pageBg(context),
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _loading ? null : _importProducts,
            icon: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.playlist_add_rounded),
            label: Text(_loading ? 'Ekleniyor...' : 'Ürünleri ekle'),
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
            child: const Text(
              'Ürünleri aşağıdaki gibi yapıştırabilirsin:\n\nbaşlık = Ürün adı\nkategori = Lezita\nkod = 123456\nPoşet yazıcı = ...\nKoli yazıcı = ...\nKoli = ...\nPalet = ...\nSKT = ...\n\nYeni ürün için tekrar başlık = ... yaz.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            minLines: 14,
            maxLines: 24,
            style: TextStyle(
              color: AppUi.text(context),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'başlık = ...\nkategori = ...\nkod = ...\nPoşet yazıcı = ...',
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
        ],
      ),
    );
  }
}
class DetailScreen extends StatefulWidget {
  final PackingItem item;
  final bool isFavorite;
  final Future<void> Function(PackingItem updatedItem) onUpdate;
  final Future<void> Function(PackingItem item) onDelete;
  final Future<bool> Function(PackingItem item) onToggleFavorite;
  final Future<void> Function(PackingItem item) onDuplicate;

  const DetailScreen({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onUpdate,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onDuplicate,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late PackingItem _item;
  late bool _isFavorite;

  bool get _hasImage {
    final path = _item.imagePath;

    if (path == null || path.trim().isEmpty) return false;

    return File(path).existsSync();
  }

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _isFavorite = widget.isFavorite;
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

  Future<void> _toggleFavorite() async {
    final value = await widget.onToggleFavorite(_item);

    if (!mounted) return;

    setState(() {
      _isFavorite = value;
    });
  }

  Future<void> _duplicateItem() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ürün çoğaltılsın mı?'),
        content: Text('${_item.title} için kopya kayıt oluşturulsun mu?'),
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
            child: const Text('Çoğalt'),
          ),
        ],
      ),
    );

    if (result == true) {
      await widget.onDuplicate(_item);
    }
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
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            ),
            color: _isFavorite ? Colors.amber : Colors.white,
            tooltip: 'Favori',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeHistoryScreen(
                    itemId: _item.id,
                    title: _item.title,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Geçmiş',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductQrScreen(item: _item),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_2_rounded),
            tooltip: 'QR oluştur',
          ),
          IconButton(
            onPressed: _duplicateItem,
            icon: const Icon(Icons.copy_all_rounded),
            tooltip: 'Ürünü çoğalt',
          ),
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
          if (_hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.file(
                File(_item.imagePath!),
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _item.category,
                              style: const TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (_isFavorite) ...[
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      if (_item.code != null &&
                          _item.code!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Kod: ${_item.code}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onChanged;

  const SettingsScreen({
    super.key,
    this.onChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pinEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
  }

  Future<void> _loadPinStatus() async {
    final pin = await SecurityHelper.getPin();

    if (!mounted) return;

    setState(() {
      _pinEnabled = pin != null;
    });
  }

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

  String _sortTitle(SortMode mode) {
    switch (mode) {
      case SortMode.newestFirst:
        return 'Son eklenen önce';
      case SortMode.alphabetical:
        return 'A-Z sırala';
      case SortMode.category:
        return 'Kategoriye göre';
      case SortMode.favoritesFirst:
        return 'Favoriler önce';
    }
  }

  IconData _sortIcon(SortMode mode) {
    switch (mode) {
      case SortMode.newestFirst:
        return Icons.schedule_rounded;
      case SortMode.alphabetical:
        return Icons.sort_by_alpha_rounded;
      case SortMode.category:
        return Icons.category_rounded;
      case SortMode.favoritesFirst:
        return Icons.star_rounded;
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
    final items = await StorageHelper.readItems();
    final backupCode = StorageHelper.createBackupCode(items);

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
      widget.onChanged?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yedek geri yüklendi.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
        ),
      );

      setState(() {});
    }
  }

  Future<void> _openBulkAdd(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const BulkAddScreen(),
      ),
    );

    if (changed == true && context.mounted) {
      widget.onChanged?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toplu ürünler eklendi.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
        ),
      );

      setState(() {});
    }
  }

  Future<void> _restoreAutoBackup(BuildContext context) async {
    final raw = await StorageHelper.readAutoBackupCode();

    if (raw == null || raw.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Henüz otomatik yedek yok.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
        ),
      );
      return;
    }

    try {
      final items = StorageHelper.parseBackupCode(raw);

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Otomatik yedek geri alınsın mı?'),
          content: Text(
            '${items.length} ürün geri yüklenecek. Mevcut liste değişecek.',
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
              child: const Text('Geri al'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final current = await StorageHelper.readItems();
      await StorageHelper.saveAutoBackup(current);
      await StorageHelper.saveItems(items);

      if (!context.mounted) return;

      widget.onChanged?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Otomatik yedek geri alındı.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
        ),
      );

      setState(() {});
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Otomatik yedek okunamadı.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
        ),
      );
    }
  }

  Future<void> _openPinSetup() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PinSetupScreen(),
      ),
    );

    if (changed == true) {
      await _loadPinStatus();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN ayarlandı.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
        ),
      );
    }
  }

  Future<void> _removePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('PIN kaldırılsın mı?'),
        content: const Text('Uygulama açılırken artık PIN istemeyecek.'),
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
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await SecurityHelper.removePin();
    await _loadPinStatus();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PIN kaldırıldı.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
      ),
    );
  }

  Future<void> _printPdf() async {
    final items = await StorageHelper.readItems();

    if (items.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF için ürün yok kank.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
        ),
      );

      return;
    }

    await PdfHelper.printAllProducts(items);
  }

  Widget _statsBox(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: StatsHelper.loadStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppUi.card(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppUi.border(context)),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            ),
          );
        }

        final data = snapshot.data!;
        final categories = data['categories'] as Map<String, int>;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppUi.card(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppUi.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statRow(context, 'Toplam ürün', data['total'].toString()),
              _statRow(context, 'Favoriler', data['favorites'].toString()),
              _statRow(context, 'Son bakılan', data['recent'].toString()),
              const SizedBox(height: 8),
              ...categories.entries.map(
                (entry) => _statRow(context, entry.key, entry.value.toString()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppUi.muted(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppColors.green,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppUi.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppUi.border(context)),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            color: AppUi.text(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppUi.muted(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppUi.muted(context),
        ),
        onTap: onTap,
      ),
    );
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
                    'Görünüm, yedekleme, PDF, toplu ekleme ve PIN ayarları.',
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
          _sectionTitle(context, 'İstatistik'),
          _statsBox(context),
          const SizedBox(height: 14),
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
          _sectionTitle(context, 'Sıralama'),
          ValueListenableBuilder<SortMode>(
            valueListenable: AppSettings.sortModeNotifier,
            builder: (context, currentSort, _) {
              return Column(
                children: SortMode.values.map(
                  (mode) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppUi.card(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppUi.border(context)),
                      ),
                      child: RadioListTile<SortMode>(
                        value: mode,
                        groupValue: currentSort,
                        activeColor: AppColors.green,
                        onChanged: (value) async {
                          if (value == null) return;
                          await AppSettings.setSortMode(value);
                        },
                        secondary: Icon(
                          _sortIcon(mode),
                          color: mode == currentSort
                              ? AppColors.green
                              : AppUi.muted(context),
                        ),
                        title: Text(
                          _sortTitle(mode),
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
          _sectionTitle(context, 'Ürün yönetimi'),
          _settingsTile(
            context: context,
            icon: Icons.manage_history_rounded,
            title: 'Değişiklik geçmişi',
            subtitle: 'Ürünlerde yapılan işlemleri görüntüle.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ChangeHistoryScreen(),
                ),
              );
            },
          ),
          _settingsTile(
            context: context,
            icon: Icons.delete_sweep_rounded,
            title: 'Çöp kutusu',
            subtitle: 'Silinen ürünleri geri yükle veya kalıcı sil.',
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const TrashScreen(),
                ),
              );

              if (changed == true) {
                widget.onChanged?.call();
                setState(() {});
              }
            },
          ),
          _settingsTile(
            context: context,
            icon: Icons.warning_amber_rounded,
            title: 'Eksik bilgi raporu',
            subtitle: 'Palet, SKT, robot sırası gibi eksik alanları gösterir.',
            onTap: () async {
              final items = await StorageHelper.readItems();
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MissingInfoReportScreen(items: items),
                ),
              );
            },
          ),
          _settingsTile(
            context: context,
            icon: Icons.playlist_add_rounded,
            title: 'Toplu ürün ekle',
            subtitle: 'Başlık = ... formatındaki metni ürüne çevirir.',
            onTap: () => _openBulkAdd(context),
          ),
          _settingsTile(
            context: context,
            icon: Icons.picture_as_pdf_rounded,
            title: 'PDF / çıktı al',
            subtitle: 'Tüm ürün listesini PDF olarak oluşturur.',
            onTap: _printPdf,
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, 'Güvenlik'),
          _settingsTile(
            context: context,
            icon: Icons.lock_rounded,
            title: _pinEnabled ? 'PIN değiştir' : 'PIN oluştur',
            subtitle: _pinEnabled
                ? 'Uygulama açılış şifresini değiştir.'
                : 'Uygulama açılışına şifre koy.',
            onTap: _openPinSetup,
          ),
          if (_pinEnabled)
            _settingsTile(
              context: context,
              icon: Icons.lock_open_rounded,
              title: 'PIN kaldır',
              subtitle: 'Uygulama açılırken şifre istemesin.',
              iconColor: Colors.red,
              onTap: _removePin,
            ),
          const SizedBox(height: 14),
          _sectionTitle(context, 'Yedekleme'),
          _settingsTile(
            context: context,
            icon: Icons.copy_all_rounded,
            title: 'Yedek kodu oluştur',
            subtitle: 'Tüm ürünleri kopyalanabilir yedek koduna çevirir.',
            onTap: () => _copyBackup(context),
          ),
          _settingsTile(
            context: context,
            icon: Icons.restore_rounded,
            title: 'Yedekten geri yükle',
            subtitle: 'Daha önce aldığın yedek kodunu yapıştırır.',
            onTap: () => _openRestore(context),
          ),
          _settingsTile(
            context: context,
            icon: Icons.undo_rounded,
            title: 'Son otomatik yedeği geri al',
            subtitle: 'Silme, düzenleme veya geri yükleme öncesi yedeği getirir.',
            onTap: () => _restoreAutoBackup(context),
          ),
          const SizedBox(height: 40),
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
      final items = StorageHelper.parseBackupCode(raw);

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

      final currentItems = await StorageHelper.readItems();
      await StorageHelper.saveAutoBackup(currentItems);
      await StorageHelper.saveItems(items);

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
            'Not: Geri yükleme mevcut ürün listesini yedekteki listeyle değiştirir. İşlem öncesi otomatik yedek alınır.',
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

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _againController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    _againController.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    final pin = _pinController.text.trim();
    final again = _againController.text.trim();

    if (pin.length < 4) {
      _showSnack('PIN en az 4 rakam olsun kank.');
      return;
    }

    if (pin != again) {
      _showSnack('PIN tekrar aynı değil.');
      return;
    }

    await SecurityHelper.setPin(pin);

    if (!mounted) return;

    Navigator.of(context).pop(true);
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

  Widget _pinInput({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppUi.text(context),
        fontSize: 24,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppUi.input(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppUi.pageBg(context),
      appBar: AppBar(
        title: const Text('PIN Ayarla'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: AppUi.pageBg(context),
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _savePin,
            icon: const Icon(Icons.lock_rounded),
            label: const Text('PIN kaydet'),
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
                  Icons.lock_rounded,
                  color: AppColors.green,
                  size: 34,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Uygulama açılışında istenecek PIN kodunu belirle.',
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
          _pinInput(
            controller: _pinController,
            label: 'Yeni PIN',
          ),
          const SizedBox(height: 12),
          _pinInput(
            controller: _againController,
            label: 'PIN tekrar',
          ),
          const SizedBox(height: 12),
          Text(
            'Not: PIN’i unutursan uygulamayı kaldırıp tekrar kurman gerekebilir. Bu yüzden önce yedek kodu alman iyi olur.',
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


class ProductQrScreen extends StatelessWidget {
  final PackingItem item;

  const ProductQrScreen({
    super.key,
    required this.item,
  });

  String get qrData {
    final code = item.code?.trim();
    if (code != null && code.isNotEmpty) return code;
    return item.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppUi.pageBg(context),
      appBar: AppBar(
        title: const Text('Ürün QR'),
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
            child: Column(
              children: [
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kod: $qrData',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppUi.border(context)),
            ),
            child: Center(
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 260,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: qrData));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('QR kod verisi kopyalandı.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.navy,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('QR verisini kopyala'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
            ),
          ),
        ],
      ),
    );
  }
}


List<String> missingFieldsForItem(PackingItem item) {
  const requiredKeys = [
    'Poşet yazıcı',
    'Koli yazıcı',
    'Koli',
    'Palet',
    'SKT',
    'Robot sırası',
    'Koli içi poşet sayısı',
  ];

  final missing = <String>[];

  for (final key in requiredKeys) {
    final value = item.detailByKey(key);
    if (value == null || value.trim().isEmpty) {
      missing.add(key);
    }
  }

  return missing;
}

class ProfessionalDashboard extends StatelessWidget {
  final List<PackingItem> items;
  final Set<String> favoriteIds;
  final List<String> recentIds;
  final VoidCallback onMissingTap;

  const ProfessionalDashboard({
    super.key,
    required this.items,
    required this.favoriteIds,
    required this.recentIds,
    required this.onMissingTap,
  });

  @override
  Widget build(BuildContext context) {
    final favoriteCount = items.where((e) => favoriteIds.contains(e.id)).length;
    final missingCount =
        items.where((item) => missingFieldsForItem(item).isNotEmpty).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DashboardMiniCard(
                  title: 'Toplam',
                  value: items.length.toString(),
                  icon: Icons.inventory_2_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DashboardMiniCard(
                  title: 'Favori',
                  value: favoriteCount.toString(),
                  icon: Icons.star_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DashboardMiniCard(
                  title: 'Eksik',
                  value: missingCount.toString(),
                  icon: Icons.warning_amber_rounded,
                ),
              ),
            ],
          ),
          if (missingCount > 0) ...[
            const SizedBox(height: 10),
            Material(
              color: AppColors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: onMissingTap,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fact_check_rounded,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$missingCount üründe eksik bilgi var. Raporu aç.',
                          style: TextStyle(
                            color: AppUi.text(context),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppUi.muted(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DashboardMiniCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppUi.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppUi.border(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.green),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: AppUi.text(context),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppUi.muted(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class MissingInfoReportScreen extends StatelessWidget {
  final List<PackingItem> items;

  const MissingInfoReportScreen({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final missingItems = items
        .map((item) => MapEntry(item, missingFieldsForItem(item)))
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: AppUi.pageBg(context),
      appBar: AppBar(
        title: const Text('Eksik Bilgi Raporu'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: missingItems.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Eksik bilgi yok',
                      style: TextStyle(
                        color: AppUi.text(context),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tüm önemli alanlar dolu görünüyor kank.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppUi.muted(context)),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: missingItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = missingItems[index];
                final item = entry.key;
                final missing = entry.value;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppUi.card(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppUi.border(context)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                color: AppUi.text(context),
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Eksik: ${missing.join(', ')}',
                              style: TextStyle(
                                color: AppUi.muted(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}


class ProductTemplate {
  final String name;
  final String titleHint;
  final String category;
  final Map<String, String> details;

  const ProductTemplate({
    required this.name,
    required this.titleHint,
    required this.category,
    required this.details,
  });
}

const List<ProductTemplate> finefoodTemplates = [
  ProductTemplate(
    name: 'Standart',
    titleHint: 'Yeni Standart Ürün',
    category: 'Eklenen Ürünler',
    details: {
      'Poşet yazıcı': '',
      'Koli yazıcı': '',
      'Koli': '',
      'Palet': '80×120',
      'SKT': '',
      'Filim': '',
      'Robot sırası': '',
      'Tam palet kg': '',
      'Koli içi poşet sayısı': '',
    },
  ),
  ProductTemplate(
    name: 'Mcdonalds',
    titleHint: 'Mcdonalds Yeni Ürün',
    category: 'Mcdonalds',
    details: {
      'Poşet yazıcı': 'Mcdonalds ... poset',
      'Koli yazıcı': 'Mcdonalds ... koli',
      'Koli': '',
      'Palet': '80×120',
      'SKT': '1 Yıl',
      'Filim': '',
      'Robot sırası': '6',
      'Tam palet kg': '',
      'Koli içi poşet sayısı': '5',
    },
  ),
  ProductTemplate(
    name: 'Lezita',
    titleHint: 'Lezita Yeni Ürün',
    category: 'Lezita',
    details: {
      'Poşet yazıcı': 'Lezita ... poset',
      'Koli yazıcı': 'Lezita ... koli',
      'Koli': '',
      'Palet': '80×120',
      'SKT': '2 Yıl',
      'Filim': 'Lezita filim',
      'Robot sırası': '6 sıra',
      'Tam palet kg': '',
      'Koli içi poşet sayısı': '5 Adet',
    },
  ),
];

class ProductTemplateChips extends StatelessWidget {
  final void Function(ProductTemplate template) onApplyTemplate;

  const ProductTemplateChips({
    super.key,
    required this.onApplyTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppUi.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppUi.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ürün şablonu',
            style: TextStyle(
              color: AppUi.text(context),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hazır şablon seç, alanlar otomatik dolsun.',
            style: TextStyle(
              color: AppUi.muted(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: finefoodTemplates.map((template) {
              return ActionChip(
                avatar: const Icon(Icons.auto_awesome_rounded),
                label: Text(template.name),
                onPressed: () => onApplyTemplate(template),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}


class TrashHelper {
  static Future<List<PackingItem>> readTrash() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(trashStorageKey);

    if (raw == null || raw.trim().isEmpty) return [];

    try {
      return StorageHelper.parseItems(raw);
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTrash(List<PackingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(trashStorageKey, StorageHelper.encodeItems(items));
  }

  static Future<void> moveToTrash(PackingItem item) async {
    final trash = await readTrash();
    trash.removeWhere((e) => e.id == item.id);
    trash.insert(0, item);
    await saveTrash(trash.take(100).toList());
  }
}

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  bool _loading = true;
  List<PackingItem> _trash = [];

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    final trash = await TrashHelper.readTrash();

    if (!mounted) return;

    setState(() {
      _trash = trash;
      _loading = false;
    });
  }

  Future<void> _restore(PackingItem item) async {
    final items = await StorageHelper.readItems();
    await StorageHelper.saveAutoBackup(items);

    items.removeWhere((e) => e.id == item.id);
    items.add(item);

    _trash.removeWhere((e) => e.id == item.id);

    await StorageHelper.saveItems(items);
    await TrashHelper.saveTrash(_trash);

    if (!mounted) return;

    setState(() {});
    Navigator.of(context).pop(true);
  }

  Future<void> _deleteForever(PackingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kalıcı silinsin mi?'),
        content: Text('${item.title} tamamen silinecek.'),
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
            child: const Text('Kalıcı sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _trash.removeWhere((e) => e.id == item.id);
    await TrashHelper.saveTrash(_trash);

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppUi.pageBg(context),
      appBar: AppBar(
        title: const Text('Çöp Kutusu'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            )
          : _trash.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: _trash.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _trash[index];

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppUi.card(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppUi.border(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: AppUi.text(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.category,
                            style: TextStyle(
                              color: AppUi.muted(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _restore(item),
                                  icon: const Icon(Icons.restore_rounded),
                                  label: const Text('Geri yükle'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _deleteForever(item),
                                  icon: const Icon(Icons.delete_forever_rounded),
                                  label: const Text('Kalıcı sil'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}


class ChangeHistoryEntry {
  final String itemId;
  final String itemTitle;
  final String action;
  final String createdAt;

  const ChangeHistoryEntry({
    required this.itemId,
    required this.itemTitle,
    required this.action,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemTitle': itemTitle,
      'action': action,
      'createdAt': createdAt,
    };
  }

  factory ChangeHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ChangeHistoryEntry(
      itemId: (json['itemId'] ?? '').toString(),
      itemTitle: (json['itemTitle'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class ChangeHistoryHelper {
  static Future<List<ChangeHistoryEntry>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(historyStorageKey);

    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded
          .map(
            (e) => ChangeHistoryEntry.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<ChangeHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      historyStorageKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> add({
    required String itemId,
    required String itemTitle,
    required String action,
  }) async {
    final entries = await readAll();

    entries.insert(
      0,
      ChangeHistoryEntry(
        itemId: itemId,
        itemTitle: itemTitle,
        action: action,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    await saveAll(entries.take(300).toList());
  }

  static List<String> describeChanges(PackingItem oldItem, PackingItem newItem) {
    final changes = <String>[];

    if (oldItem.title != newItem.title) {
      changes.add('Başlık değişti: ${oldItem.title} → ${newItem.title}');
    }

    if (oldItem.category != newItem.category) {
      changes.add('Kategori değişti: ${oldItem.category} → ${newItem.category}');
    }

    if ((oldItem.code ?? '') != (newItem.code ?? '')) {
      changes.add('Kod değişti');
    }

    if ((oldItem.imagePath ?? '') != (newItem.imagePath ?? '')) {
      changes.add('Fotoğraf değişti');
    }

    final keys = <String>{
      ...oldItem.details.keys,
      ...newItem.details.keys,
    };

    for (final key in keys) {
      final oldValue = oldItem.details[key] ?? '';
      final newValue = newItem.details[key] ?? '';

      if (oldValue != newValue) {
        changes.add('$key değişti');
      }
    }

    if (changes.isEmpty) {
      changes.add('Ürün kaydedildi');
    }

    return changes;
  }
}

class ChangeHistoryScreen extends StatelessWidget {
  final String? itemId;
  final String? title;

  const ChangeHistoryScreen({
    super.key,
    this.itemId,
    this.title,
  });

  String _formatDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;

    final local = date.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');

    return '${local.day}.${local.month}.${local.year} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppUi.pageBg(context),
      appBar: AppBar(
        title: Text(title == null ? 'Değişiklik Geçmişi' : '$title Geçmişi'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<ChangeHistoryEntry>>(
        future: ChangeHistoryHelper.readAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            );
          }

          final all = snapshot.data ?? [];
          final entries = itemId == null
              ? all
              : all.where((e) => e.itemId == itemId).toList();

          if (entries.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = entries[index];

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppUi.card(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppUi.border(context)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: AppColors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.itemTitle,
                            style: TextStyle(
                              color: AppUi.text(context),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.action,
                            style: TextStyle(
                              color: AppUi.muted(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(entry.createdAt),
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
              );
            },
          );
        },
      ),
    );
  }
}

