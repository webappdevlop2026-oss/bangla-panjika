import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BanglaPanjikaApp());
}

class BanglaPanjikaApp extends StatelessWidget {
  const BanglaPanjikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'বাংলা পঞ্জিকা',
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/language': (context) => const LanguageScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/location': (context) => const LocationSelectScreen(),
        '/permission': (context) => const PermissionScreen(),
        '/theme_select': (context) => const ThemeSelectScreen(),
        '/home': (context) => const HomeDashboardScreen(),
      },
    );
  }
}

class CosmicBackground extends StatefulWidget {
  final Widget child;
  const CosmicBackground({super.key, required this.child});
  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;
  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF071428),
                  Color(0xFF183F69),
                  Color(0xFFF5A64E),
                  Color(0xFF1B2C48),
                ],
                stops: [0.0, 0.45, 0.82, 1.0],
              ),
            ),
          ),
          const Positioned.fill(
            child: Opacity(opacity: 0.6, child: StarsLayer()),
          ),
          Positioned(
            top: 40,
            right: -40,
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFFFFFDE0),
                          Color(0xFFFFD65A),
                          Color(0xFFFF8F00),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFFC44D),
                          blurRadius: 22,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  _buildOrbitRing(
                    92,
                    _orbitController,
                    1.0,
                    const Color(0xFFFF9D00),
                    15,
                  ),
                  _buildOrbitRing(
                    145,
                    _orbitController,
                    0.63,
                    const Color(0xFF3187FF),
                    19,
                  ),
                  _buildOrbitRing(
                    205,
                    _orbitController,
                    0.43,
                    const Color(0xFFD55B2A),
                    24,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildOrbitRing(
    double size,
    AnimationController controller,
    double speedMultiplier,
    Color planetColor,
    double planetSize,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
        ),
        AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            double angle = controller.value * 2 * math.pi * speedMultiplier;
            double radius = size / 2;
            return Transform.translate(
              offset: Offset(
                radius * math.cos(angle),
                radius * math.sin(angle),
              ),
              child: Container(
                width: planetSize,
                height: planetSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: planetColor,
                  boxShadow: [
                    BoxShadow(
                      color: planetColor.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class StarsLayer extends StatelessWidget {
  const StarsLayer({super.key});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: StarsPainter());
}

class StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(42);
    for (int i = 0; i < 60; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double radius = random.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/language');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const CosmicBackground(
      child: Center(
        child: Text(
          'বাংলা পঞ্জিকা',
          style: TextStyle(
            fontSize: 34,
            color: Color(0xFFFFD36E),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'স্বাগতম • Welcome',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFFFD36E),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'আপনার ভাষা নির্বাচন করুন',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            _buildGlassButton(context, 'বাংলা'),
            const SizedBox(height: 16),
            _buildGlassButton(context, 'English'),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF091A34).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () => Navigator.pushNamed(context, '/onboarding'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF091A34).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFFFD36E).withValues(alpha: 0.3),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    '✨ অ্যাপ পরিচিতি',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD36E),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'এই পঞ্জিকা অ্যাপে আপনি পাবেন সঠিক তিথি, নক্ষত্র, শুভক্ষণ, এবং সম্পূর্ণ বাংলা নেটিভ ক্যালেন্ডারের অভিজ্ঞতা।',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD36E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => Navigator.pushNamed(context, '/location'),
                child: const Text(
                  'পরবর্তী ধাপ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF071428),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// নিচের ৪টা ক্লাস আগে missing ছিল — main.dart এর routes এ এগুলো
// রেফার করা হচ্ছিল কিন্তু ডিফাইন করা ছিল না, তাই "isn't a class" error আসছিল।
// ---------------------------------------------------------------------

class LocationSelectScreen extends StatefulWidget {
  const LocationSelectScreen({super.key});
  @override
  State<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends State<LocationSelectScreen> {
  String? _selectedDistrict;

  final List<String> _districts = const [
    'কলকাতা',
    'হাওড়া',
    'উত্তর ২৪ পরগনা',
    'দক্ষিণ ২৪ পরগনা',
    'হুগলি',
    'নদিয়া',
    'পূর্ব বর্ধমান',
    'পশ্চিম বর্ধমান',
    'মুর্শিদাবাদ',
    'বীরভূম',
    'পূর্ব মেদিনীপুর',
    'পশ্চিম মেদিনীপুর',
    'বাঁকুড়া',
    'পুরুলিয়া',
    'মালদা',
    'উত্তর দিনাজপুর',
    'দক্ষিণ দিনাজপুর',
    'জলপাইগুড়ি',
    'দার্জিলিং',
    'আলিপুরদুয়ার',
    'কোচবিহার',
    'ঝাড়গ্রাম',
    'কালিম্পং',
  ];

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'আপনার অবস্থান নির্বাচন করুন',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'সঠিক তিথি ও সময় গণনার জন্য এটি প্রয়োজন',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: _districts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final district = _districts[index];
                  final isSelected = district == _selectedDistrict;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDistrict = district),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFD36E).withValues(alpha: 0.2)
                            : const Color(0xFF091A34).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFD36E)
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            district,
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected
                                  ? const Color(0xFFFFD36E)
                                  : Colors.white,
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFFFFD36E),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD36E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _selectedDistrict == null
                    ? null
                    : () => Navigator.pushNamed(context, '/permission'),
                child: const Text(
                  'পরবর্তী ধাপ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF071428),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF091A34).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFFFD36E).withValues(alpha: 0.3),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 48,
                    color: Color(0xFFFFD36E),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'নোটিফিকেশন অনুমতি',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD36E),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'শুভক্ষণ ও গুরুত্বপূর্ণ তিথি সম্পর্কে সময়মতো জানতে নোটিফিকেশন চালু রাখুন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD36E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/theme_select'),
                    child: const Text(
                      'অনুমতি দিন',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF071428),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/theme_select'),
                  child: const Text(
                    'পরে করব',
                    style: TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeSelectScreen extends StatefulWidget {
  const ThemeSelectScreen({super.key});
  @override
  State<ThemeSelectScreen> createState() => _ThemeSelectScreenState();
}

class _ThemeSelectScreenState extends State<ThemeSelectScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _themes = const [
    {'name': 'কসমিক (ডিফল্ট)', 'color': Color(0xFF183F69)},
    {'name': 'ডার্ক', 'color': Color(0xFF0D0D0D)},
    {'name': 'লাইট', 'color': Color(0xFFFFF3D6)},
  ];

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'থিম নির্বাচন করুন',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: _themes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final theme = _themes[index];
                  final isSelected = index == _selectedIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF091A34).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFD36E)
                              : Colors.white.withValues(alpha: 0.15),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme['color'] as Color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              theme['name'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFFFFD36E),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD36E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                ),
                child: const Text(
                  'শুরু করুন',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF071428),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// HOME DASHBOARD — মূল হোম স্ক্রিন (HTML ডিজাইন অনুযায়ী)
// =====================================================================

class PanchangFeature {
  final String emoji;
  final String title;
  final String subtitle;
  const PanchangFeature(this.emoji, this.title, this.subtitle);
}

class FestivalItem {
  final String emoji;
  final String title;
  final String date;
  const FestivalItem(this.emoji, this.title, this.date);
}

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});
  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _navIndex = 0;

  final List<PanchangFeature> _quickFeatures = const [
    PanchangFeature('📅', 'বাংলা ক্যালেন্ডার', '১২ মাস, ছুটি, বিশেষ দিন'),
    PanchangFeature('🙏', 'পূজা ও ব্রত', 'উৎসব, উপবাস, পূজা তালিকা'),
    PanchangFeature('🔮', 'রাশিফল', '১২ রাশি, দৈনিক ও মাসিক'),
    PanchangFeature('💍', 'শুভ দিন', 'বিবাহ, গৃহপ্রবেশ, অন্নপ্রাশন'),
    PanchangFeature('🌕', 'পূর্ণিমা', 'পূর্ণিমার তারিখ ও তথ্য'),
    PanchangFeature('🌑', 'অমাবস্যা', 'অমাবস্যার তালিকা ও সময়'),
    PanchangFeature('🌘', 'গ্রহণ', 'সূর্য ও চন্দ্রগ্রহণ'),
    PanchangFeature('🪐', 'গ্রহ ও নক্ষত্র', 'গ্রহের অবস্থান ও জ্যোতির্বিদ্যা'),
  ];

  final List<FestivalItem> _festivals = const [
    FestivalItem('🛕', 'রথযাত্রা', '২৭ জ্যৈষ্ঠ'),
    FestivalItem('🦚', 'জন্মাষ্টমী', '১৫ ভাদ্র'),
    FestivalItem('🔱', 'দুর্গাপূজা', '৬ আশ্বিন'),
    FestivalItem('🪔', 'কালীপূজা', 'কার্তিক অমাবস্যা'),
  ];

  void _openFeature(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FeatureSheet(title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              // ---- Top bar ----
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _iconButton(Icons.menu, () {
                    // TODO: পরবর্তী ধাপে সাইড মেনু (Reminder, Notes, Settings) যোগ হবে
                  }),
                  const Text(
                    'বাংলা পঞ্জিকা',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFD479),
                    ),
                  ),
                  _iconButton(Icons.notifications_none_rounded, () {}),
                ],
              ),
              const SizedBox(height: 16),

              // ---- Hero date card ----
              _HeroDateCard(),

              const SizedBox(height: 14),

              // ---- Live info row ----
              _LiveInfoRow(),

              const SizedBox(height: 14),

              // ---- Ticker ----
              _TickerBar(),

              const SizedBox(height: 18),

              // ---- Panchang mini row ----
              const _SectionTitle('আজকের পঞ্চাঙ্গ'),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Expanded(
                    child: _MiniPanchang(
                      emoji: '🌅',
                      value: '৫:০৬ AM',
                      label: 'সূর্যোদয়',
                    ),
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: _MiniPanchang(
                      emoji: '🌇',
                      value: '৬:২৪ PM',
                      label: 'সূর্যাস্ত',
                    ),
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: _MiniPanchang(
                      emoji: '🌙',
                      value: '৩:০৬ PM',
                      label: 'চন্দ্রোদয়',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ---- Quick features grid ----
              const _SectionTitle('দ্রুত ব্যবহার'),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _quickFeatures.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 11,
                  mainAxisExtent: 132,
                ),
                itemBuilder: (context, i) {
                  final f = _quickFeatures[i];
                  return _FeatureCard(
                    feature: f,
                    onTap: () => _openFeature(context, f.title),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ---- Festivals ----
              const _SectionTitle('উৎসব ও বিশেষ দিন'),
              const SizedBox(height: 10),
              SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _festivals.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final f = _festivals[i];
                    return _FestivalCard(
                      item: f,
                      onTap: () => _openFeature(context, f.title),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ---- Tithi / Nakshatra / Yoga list ----
              const _SectionTitle('তিথি • নক্ষত্র • যোগ'),
              const SizedBox(height: 10),
              _InfoListBox(
                rows: const [
                  ['তিথি', 'তৃতীয়া'],
                  ['নক্ষত্র', 'ধনিষ্ঠা'],
                  ['যোগ', 'সিদ্ধি'],
                  ['করণ', 'বিষ্টি'],
                  ['চন্দ্র রাশি', 'কুম্ভ'],
                ],
              ),

              const SizedBox(height: 20),

              // ---- Special days ----
              const _SectionTitle('আজকের বিশেষ দিন'),
              const SizedBox(height: 10),
              _InfoListBox(
                special: true,
                rows: const [
                  ['🐍 নাগ পঞ্চমী ব্রত', 'আজ'],
                  ['🪷 শ্রীকৃষ্ণ জন্মাষ্টমী', 'আগামীকাল'],
                ],
              ),

              const SizedBox(height: 10),
            ],
          ),

          // ---- Bottom nav ----
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomNavBar(
              selectedIndex: _navIndex,
              onSelect: (i) => setState(() => _navIndex = i),
              onFabTap: () => _openFeature(context, 'পঞ্জিকা'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

class _HeroDateCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF08172F).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFFFD36E).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'আজকের মহাজাগতিক দিন',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          const Text(
            '২৫ শ্রাবণ ১৪৩৩',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFD36E),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'মঙ্গলবার • ১১ আগস্ট ২০২৬',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF7D4A10).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFFFFC76A).withValues(alpha: 0.4),
              ),
            ),
            child: const Text(
              'শুক্ল পক্ষ • তৃতীয়া তিথি',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _modeChip('🌅 সকাল'),
                _modeChip('☀️ দিন'),
                _modeChip('🌇 সন্ধ্যা'),
                _modeChip('🌙 রাত'),
                _modeChip('🌕 পূর্ণিমা'),
                _modeChip('🌑 অমাবস্যা'),
                _modeChip('🌘 গ্রহণ'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _LiveInfoRow extends StatelessWidget {
  static const _items = [
    '🌅 সূর্যোদয় ৫:০৬ AM',
    '🌇 সূর্যাস্ত ৬:২৪ PM',
    '🌙 চন্দ্রোদয় ৩:০৬ PM',
    '☾ চন্দ্রাস্ত ১:০৮ AM',
    '🕉 তিথি: শুক্ল পক্ষ • তৃতীয়া',
    '⭐ নক্ষত্র: ধনিষ্ঠা',
    '🪐 চন্দ্র রাশি: কুম্ভ',
    '⏰ রাহুকাল: ৭:৩০–৯:০০ AM',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF051630).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD36E).withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'আজকের লাইভ তথ্য',
            style: TextStyle(
              color: Color(0xFFFFD36E),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  _items[i],
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TickerBar extends StatefulWidget {
  @override
  State<_TickerBar> createState() => _TickerBarState();
}

class _TickerBarState extends State<_TickerBar>
    with SingleTickerProviderStateMixin {
  late final ScrollController _controller;
  static const _text =
      '☀️ সূর্যোদয় ৫:০৬ AM • সূর্যাস্ত ৬:২৪ PM • 🌙 চন্দ্রোদয় ৩:০৬ PM • রাহুকাল ৭:৩০–৯:০০ AM • আজ তৃতীয়া তিথি • নক্ষত্র: ধনিষ্ঠা • যোগ: সিদ্ধি';

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scroll());
  }

  void _scroll() async {
    while (mounted) {
      if (!_controller.hasClients) {
        await Future.delayed(const Duration(milliseconds: 200));
        continue;
      }
      final max = _controller.position.maxScrollExtent;
      await _controller.animateTo(
        max,
        duration: const Duration(seconds: 14),
        curve: Curves.linear,
      );
      if (!mounted) return;
      _controller.jumpTo(0);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF061226).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: const Text(
          _text,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }
}

class _MiniPanchang extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _MiniPanchang({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF091A34).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFD36E),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final PanchangFeature feature;
  final VoidCallback onTap;
  const _FeatureCard({required this.feature, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF091A34).withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(feature.emoji, style: const TextStyle(fontSize: 26)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FestivalCard extends StatelessWidget {
  final FestivalItem item;
  final VoidCallback onTap;
  const _FestivalCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1B35).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 76,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF8B5A1F),
                    Color(0xFF25153F),
                    Color(0xFF061226),
                  ],
                ),
              ),
              child: Text(item.emoji, style: const TextStyle(fontSize: 38)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.date,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoListBox extends StatelessWidget {
  final List<List<String>> rows;
  final bool special;
  const _InfoListBox({required this.rows, this.special = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: special
            ? const LinearGradient(
                colors: [Color(0xFF4D220D), Color(0xFF15152F)],
              )
            : null,
        color: special ? null : const Color(0xFF091A34).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: special
              ? const Color(0xFFF3B35D).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.13),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              border: i == rows.length - 1
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  row[0],
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  row[1],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _FeatureSheet extends StatelessWidget {
  final String title;
  const _FeatureSheet({required this.title});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B1B35), Color(0xFF071326), Color(0xFF050D1B)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFFFD36E),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        '$title — এই demo screen কাজ করছে। Final app-এ live database/API data যুক্ত হবে।',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
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
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onFabTap;
  const _BottomNavBar({
    required this.selectedIndex,
    required this.onSelect,
    required this.onFabTap,
  });

  static const _navs = [
    ['🏠', 'হোম'],
    ['📅', 'ক্যালেন্ডার'],
    ['🪷', 'পঞ্জিকা'],
    ['🔮', 'রাশি'],
    ['👤', 'প্রোফাইল'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF030E1F).withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFFD36E).withValues(alpha: 0.22),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0),
            _navItem(1),
            GestureDetector(
              onTap: onFabTap,
              child: Transform.translate(
                offset: const Offset(0, -18),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF6B84E), Color(0xFF8D4D0E)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB64D).withValues(alpha: 0.45),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '✦',
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),
                ),
              ),
            ),
            _navItem(3),
            _navItem(4),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index) {
    final active = index == selectedIndex;
    final data = _navs[index];
    return GestureDetector(
      onTap: () => onSelect(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(data[0], style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 3),
          Text(
            data[1],
            style: TextStyle(
              fontSize: 10,
              color: active ? const Color(0xFFFFD36E) : Colors.white70,
              fontWeight: active ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
