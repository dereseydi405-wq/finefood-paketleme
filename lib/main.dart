import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const FinefoodApp());
}

class FinefoodApp extends StatelessWidget {
  const FinefoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finefood Paketleme',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF43A047),
          primary: const Color(0xFF43A047),
          secondary: const Color(0xFF0B2D4D),
        ),
      ),
      home: const SplashScreen(),
    );
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

const List<PackingItem> packingItems = [
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
  static const Color border = Color(0xFFE3ECE8);
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

  List<PackingItem> get filteredItems {
    return packingItems.where((item) => item.matches(_query)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Ürün ara... Örn: Mc, Lezita, 9x9',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                            });
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Text(
                    'Kayıtlar',
                    style: TextStyle(
                      color: AppColors.navy,
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
                      color: AppColors.green.withOpacity(0.12),
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
              child: items.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return _PackingCard(
                          item: item,
                          onCopy: () => _copyItem(item),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(item: item),
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
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(18),
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
            color: AppColors.navy.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
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
                const Text(
                  'Finefood',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const Text(
                  'Paketleme',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Hızlı ürün bilgi arama',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.80),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackingCard extends StatelessWidget {
  final PackingItem item;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _PackingCard({
    required this.item,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final firstDetails = item.details.entries.take(4).toList();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.12),
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
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.navy.withOpacity(0.55),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...firstDetails.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: AppColors.navy.withOpacity(0.78),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
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

class DetailScreen extends StatelessWidget {
  final PackingItem item;

  const DetailScreen({
    super.key,
    required this.item,
  });

  Future<void> _copyAll(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: item.copyText));

    if (!context.mounted) return;

    _showSnack(context, '${item.title} bilgileri kopyalandı');
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
      appBar: AppBar(
        title: Text(item.title),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
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
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...item.details.entries.map(
            (entry) {
              final color = _fieldColor(entry.key);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.border,
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
                            style: const TextStyle(
                              color: AppColors.navy,
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
                      color: AppColors.navy,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 58,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'Sonuç bulunamadı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Başka bir kelime ile arama yap.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
