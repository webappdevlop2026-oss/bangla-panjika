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

class _CosmicBackgroundState extends State<CosmicBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;
  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
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
                colors: [Color(0xFF071428), Color(0xFF183F69), Color(0xFFF5A64E), Color(0xFF1B2C48)],
                stops: [0.0, 0.45, 0.82, 1.0],
              ),
            ),
          ),
          const Positioned.fill(child: Opacity(opacity: 0.6, child: StarsLayer())),
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
                      gradient: RadialGradient(colors: [Color(0xFFFFFDE0), Color(0xFFFFD65A), Color(0xFFFF8F00)]),
                      boxShadow: [BoxShadow(color: Color(0xFFFFC44D), blurRadius: 22, spreadRadius: 2)],
                    ),
                  ),
                  _buildOrbitRing(92, _orbitController, 1.0, const Color(0xFFFF9D00), 15),
                  _buildOrbitRing(145, _orbitController, 0.63, const Color(0xFF3187FF), 19),
                  _buildOrbitRing(205, _orbitController, 0.43, const Color(0xFFD55B2A), 24),
                ],
              ),
            ),
          ),
          SafeArea(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildOrbitRing(double size, AnimationController controller, double speedMultiplier, Color planetColor, double planetSize) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
        ),
        AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            double angle = controller.value * 2 * math.pi * speedMultiplier;
            double radius = size / 2;
            return Transform.translate(
              offset: Offset(radius * math.cos(angle), radius * math.sin(angle)),
              child: Container(
                width: planetSize,
                height: planetSize,
                decoration: BoxDecoration(shape: BoxShape.circle, color: planetColor, boxShadow: [BoxShadow(color: planetColor.withValues(alpha: 0.6), blurRadius: 8)]),
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
        child: Text('বাংলা পঞ্জিকা', style: TextStyle(fontSize: 34, color: Color(0xFFFFD36E), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
            const Text('স্বাগতম • Welcome', style: TextStyle(fontSize: 16, color: Color(0xFFFFD36E), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('আপনার ভাষা নির্বাচন করুন', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
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
      decoration: BoxDecoration(color: const Color(0xFF091A34).withValues(alpha: 0.85), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        onPressed: () => Navigator.pushNamed(context, '/onboarding'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
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
              decoration: BoxDecoration(color: const Color(0xFF091A34).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFFFD36E).withValues(alpha: 0.3))),
              child: const Column(
                children: [
                  Text('✨ অ্যাপ পরিচিতি', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD36E))),
                  SizedBox(height: 16),
                  Text('এই পঞ্জিকা অ্যাপে আপনি পাবেন সঠিক তিথি, নক্ষত্র, শুভক্ষণ, এবং সম্পূর্ণ বাংলা নেটিভ ক্যালেন্ডারের অভিজ্ঞতা।', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white, height: 1.5)),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD36E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                onPressed: () => Navigator.pushNamed(context, '/location'),
                child: const Text('পরবর্তী ধাপ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF071428))),
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
    'কলকাতা', 'হাওড়া', 'উত্তর ২৪ পরগনা', 'দক্ষিণ ২৪ পরগনা', 'হুগলি',
    'নদিয়া', 'পূর্ব বর্ধমান', 'পশ্চিম বর্ধমান', 'মুর্শিদাবাদ', 'বীরভূম',
    'পূর্ব মেদিনীপুর', 'পশ্চিম মেদিনীপুর', 'বাঁকুড়া', 'পুরুলিয়া',
    'মালদা', 'উত্তর দিনাজপুর', 'দক্ষিণ দিনাজপুর', 'জলপাইগুড়ি',
    'দার্জিলিং', 'আলিপুরদুয়ার', 'কোচবিহার', 'ঝাড়গ্রাম', 'কালিম্পং',
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
            const Text('আপনার অবস্থান নির্বাচন করুন', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('সঠিক তিথি ও সময় গণনার জন্য এটি প্রয়োজন', style: TextStyle(fontSize: 14, color: Colors.white70)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFD36E).withValues(alpha: 0.2) : const Color(0xFF091A34).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? const Color(0xFFFFD36E) : Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(district, style: TextStyle(fontSize: 16, color: isSelected ? const Color(0xFFFFD36E) : Colors.white)),
                          if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFFFD36E), size: 20),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _selectedDistrict == null
                    ? null
                    : () => Navigator.pushNamed(context, '/permission'),
                child: const Text('পরবর্তী ধাপ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF071428))),
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
                border: Border.all(color: const Color(0xFFFFD36E).withValues(alpha: 0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.notifications_active_outlined, size: 48, color: Color(0xFFFFD36E)),
                  SizedBox(height: 16),
                  Text('নোটিফিকেশন অনুমতি', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD36E))),
                  SizedBox(height: 12),
                  Text(
                    'শুভক্ষণ ও গুরুত্বপূর্ণ তিথি সম্পর্কে সময়মতো জানতে নোটিফিকেশন চালু রাখুন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/theme_select'),
                    child: const Text('অনুমতি দিন', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF071428))),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/theme_select'),
                  child: const Text('পরে করব', style: TextStyle(fontSize: 15, color: Colors.white70)),
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
            const Text('থিম নির্বাচন করুন', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
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
                        border: Border.all(color: isSelected ? const Color(0xFFFFD36E) : Colors.white.withValues(alpha: 0.15), width: isSelected ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: theme['color'] as Color, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text(theme['name'] as String, style: const TextStyle(fontSize: 16, color: Colors.white))),
                          if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFFFD36E)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                child: const Text('শুরু করুন', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF071428))),
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
  bool _menuOpen = false;

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

  void _handleOpen(BuildContext context, String title) {
    if (title == 'বাংলা ক্যালেন্ডার') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BengaliCalendarScreen()));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FeatureSheet(title: title),
    );
  }

  void _handleMenuSelect(BuildContext context, String title) {
    setState(() => _menuOpen = false);
    switch (title) {
      case 'রিমাইন্ডার':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderScreen()));
        break;
      case 'নোটস':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
        break;
      case 'সেটিংস':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        break;
      case 'প্রোফাইল':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
      default:
        _handleOpen(context, title);
    }
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
                    setState(() => _menuOpen = true);
                  }),
                  const Text('বাংলা পঞ্জিকা',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFFFFD479))),
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
                  Expanded(child: _MiniPanchang(emoji: '🌅', value: '৫:০৬ AM', label: 'সূর্যোদয়')),
                  SizedBox(width: 9),
                  Expanded(child: _MiniPanchang(emoji: '🌇', value: '৬:২৪ PM', label: 'সূর্যাস্ত')),
                  SizedBox(width: 9),
                  Expanded(child: _MiniPanchang(emoji: '🌙', value: '৩:০৬ PM', label: 'চন্দ্রোদয়')),
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
                    onTap: () => _handleOpen(context, f.title),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ---- Festivals ----
              const _SectionTitle('উৎসব ও বিশেষ দিন'),
              const SizedBox(height: 10),
              SizedBox(
                height: 148,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _festivals.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final f = _festivals[i];
                    return _FestivalCard(item: f, onTap: () => _handleOpen(context, f.title));
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ---- Tithi / Nakshatra / Yoga list ----
              const _SectionTitle('তিথি • নক্ষত্র • যোগ'),
              const SizedBox(height: 10),
              _InfoListBox(rows: const [
                ['তিথি', 'তৃতীয়া'],
                ['নক্ষত্র', 'ধনিষ্ঠা'],
                ['যোগ', 'সিদ্ধি'],
                ['করণ', 'বিষ্টি'],
                ['চন্দ্র রাশি', 'কুম্ভ'],
              ]),

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
              onSelect: (i) {
                if (i == 1) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BengaliCalendarScreen()));
                  return;
                }
                if (i == 3) {
                  _handleOpen(context, 'রাশিফল');
                  return;
                }
                if (i == 4) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  return;
                }
                setState(() => _navIndex = i);
              },
              onFabTap: () => _handleOpen(context, 'পঞ্জিকা'),
            ),
          ),

          // ---- Side menu overlay ----
          if (_menuOpen) ...[
            GestureDetector(
              onTap: () => setState(() => _menuOpen = false),
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 260,
              child: _SideMenu(onSelect: (title) => _handleMenuSelect(context, title)),
            ),
          ],
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
    return Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white));
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
        border: Border.all(color: const Color(0xFFFFD36E).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('আজকের মহাজাগতিক দিন', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          const Text('২৫ শ্রাবণ ১৪৩৩',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFFFD36E))),
          const SizedBox(height: 2),
          const Text('মঙ্গলবার • ১১ আগস্ট ২০২৬', style: TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF7D4A10).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFFFC76A).withValues(alpha: 0.4)),
            ),
            child: const Text('শুক্ল পক্ষ • তৃতীয়া তিথি',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
        border: Border.all(color: const Color(0xFFFFD36E).withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('আজকের লাইভ তথ্য',
              style: TextStyle(color: Color(0xFFFFD36E), fontSize: 12, fontWeight: FontWeight.w700)),
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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Text(_items[i], style: const TextStyle(color: Colors.white, fontSize: 11)),
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

class _TickerBarState extends State<_TickerBar> with SingleTickerProviderStateMixin {
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
      await _controller.animateTo(max, duration: const Duration(seconds: 14), curve: Curves.linear);
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
        child: const Text(_text, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ),
    );
  }
}

class _MiniPanchang extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _MiniPanchang({required this.emoji, required this.value, required this.label});

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
          Text(value, style: const TextStyle(color: Color(0xFFFFD36E), fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
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
                Text(feature.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(feature.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                gradient: RadialGradient(colors: [Color(0xFF8B5A1F), Color(0xFF25153F), Color(0xFF061226)]),
              ),
              child: Text(item.emoji, style: const TextStyle(fontSize: 38)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(item.date, style: const TextStyle(color: Colors.white54, fontSize: 11)),
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
            ? const LinearGradient(colors: [Color(0xFF4D220D), Color(0xFF15152F)])
            : null,
        color: special ? null : const Color(0xFF091A34).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: special ? const Color(0xFFF3B35D).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.13),
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
                  : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(row[0], style: const TextStyle(color: Colors.white70, fontSize: 14)),
                Text(row[1], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
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
                    Text(title, style: const TextStyle(color: Color(0xFFFFD36E), fontSize: 20, fontWeight: FontWeight.bold)),
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
                  children: () {
                    final items = ContentData.categories[title];
                    if (items == null || items.isEmpty) {
                      return [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Text(
                            '$title — এই demo screen কাজ করছে। Final app-এ live database/API data যুক্ত হবে।',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                          ),
                        ),
                      ];
                    }
                    return items
                        .map((row) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(row[0],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(row[1],
                                textAlign: TextAlign.right,
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                        ],
                      ),
                    ))
                        .toList();
                  }(),
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
  const _BottomNavBar({required this.selectedIndex, required this.onSelect, required this.onFabTap});

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
        border: Border(top: BorderSide(color: const Color(0xFFFFD36E).withValues(alpha: 0.22))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, -8))],
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
                    gradient: const LinearGradient(colors: [Color(0xFFF6B84E), Color(0xFF8D4D0E)]),
                    boxShadow: [BoxShadow(color: const Color(0xFFFFB64D).withValues(alpha: 0.45), blurRadius: 20)],
                  ),
                  alignment: Alignment.center,
                  child: const Text('✦', style: TextStyle(fontSize: 22, color: Colors.white)),
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

// =====================================================================
// CONTENT DATA — দ্রুত ব্যবহার sheet-গুলোর জন্য ডেমো ডেটা
// =====================================================================

class ContentData {
  static const Map<String, List<List<String>>> categories = {
    'পঞ্জিকা': [
      ['তিথি', 'শুক্ল পক্ষ • তৃতীয়া'],
      ['নক্ষত্র', 'ধনিষ্ঠা'],
      ['যোগ', 'সিদ্ধি'],
      ['করণ', 'বিষ্টি'],
      ['রাহুকাল', '৭:৩০–৯:০০ AM'],
      ['চন্দ্র রাশি', 'কুম্ভ'],
    ],
    'পূজা ও ব্রত': [
      ['একাদশী', 'উপবাস ও পূজা নির্দেশিকা'],
      ['শিবরাত্রি', 'শিব পূজা ও ব্রত'],
      ['দুর্গাপূজা', 'ষষ্ঠী থেকে দশমী'],
      ['লক্ষ্মীপূজা', 'কোজাগরী পূর্ণিমা'],
      ['কালীপূজা', 'কার্তিক অমাবস্যা'],
      ['সরস্বতী পূজা', 'বসন্ত পঞ্চমী'],
    ],
    'রাশিফল': [
      ['♈ মেষ', 'কর্মে অগ্রগতি • শুভ রং লাল'],
      ['♉ বৃষ', 'অর্থে স্থিরতা • শুভ রং সাদা'],
      ['♊ মিথুন', 'যোগাযোগ শুভ • শুভ রং সবুজ'],
      ['♋ কর্কট', 'পরিবারে সময় দিন • শুভ রং রূপালি'],
      ['♌ সিংহ', 'আত্মবিশ্বাস বৃদ্ধি • শুভ রং সোনালি'],
      ['♍ কন্যা', 'পরিকল্পনায় সাফল্য • শুভ রং নীল'],
      ['♎ তুলা', 'সম্পর্কে ভারসাম্য • শুভ রং গোলাপি'],
      ['♏ বৃশ্চিক', 'সিদ্ধান্তে ধৈর্য • শুভ রং মেরুন'],
      ['♐ ধনু', 'ভ্রমণ শুভ • শুভ রং হলুদ'],
      ['♑ মকর', 'কাজে মনোযোগ • শুভ রং বাদামি'],
      ['♒ কুম্ভ', 'নতুন ভাবনা • শুভ রং আকাশি'],
      ['♓ মীন', 'সৃজনশীল দিন • শুভ রং বেগুনি'],
    ],
    'শুভ দিন': [
      ['💍 বিবাহ', 'শুভ লগ্ন ও নির্বাচিত তারিখ'],
      ['🏠 গৃহপ্রবেশ', 'গৃহপ্রবেশের শুভ সময়'],
      ['👶 অন্নপ্রাশন', 'শিশুর অন্নপ্রাশনের দিন'],
      ['🪔 ব্যবসা শুরু', 'নতুন কাজের শুভ সময়'],
      ['📿 নামকরণ', 'নামকরণ সংস্কারের শুভ দিন'],
    ],
    'পূর্ণিমা': [
      ['শ্রাবণ পূর্ণিমা', '২৮ আগস্ট ২০২৬'],
      ['ভাদ্র পূর্ণিমা', '২৬ সেপ্টেম্বর ২০২৬'],
      ['আশ্বিন পূর্ণিমা', '২৬ অক্টোবর ২০২৬'],
      ['কার্তিক পূর্ণিমা', '২৪ নভেম্বর ২০২৬'],
    ],
    'অমাবস্যা': [
      ['শ্রাবণ অমাবস্যা', '১২ আগস্ট ২০২৬'],
      ['ভাদ্র অমাবস্যা', '১০ সেপ্টেম্বর ২০২৬'],
      ['আশ্বিন অমাবস্যা', '১০ অক্টোবর ২০২৬'],
      ['কার্তিক অমাবস্যা', '৮ নভেম্বর ২০২৬'],
    ],
    'গ্রহণ': [
      ['☀️ সূর্যগ্রহণ', '১২ আগস্ট ২০২৬ • পূর্ণ সূর্যগ্রহণ'],
      ['🌘 চন্দ্রগ্রহণ', '২৮ আগস্ট ২০২৬ • আংশিক চন্দ্রগ্রহণ'],
    ],
    'গ্রহ ও নক্ষত্র': [
      ['☀️ সূর্য', 'দিনের অবস্থান'],
      ['🌙 চন্দ্র', 'চন্দ্র রাশি ও phase'],
      ['🔴 মঙ্গল', 'গ্রহ তথ্য'],
      ['🟡 বৃহস্পতি', 'গ্রহ তথ্য'],
      ['💫 শুক্র', 'গ্রহ তথ্য'],
      ['🪐 শনি', 'গ্রহ তথ্য'],
      ['⭐ নক্ষত্র', 'আজ: ধনিষ্ঠা'],
    ],
    'উৎসব ও বিশেষ দিন': [
      ['🛕 রথযাত্রা', '১৬ জুলাই ২০২৬'],
      ['🦚 জন্মাষ্টমী', '৪ সেপ্টেম্বর ২০২৬'],
      ['🔱 দুর্গাপূজা', '১৯-২০ অক্টোবর ২০২৬'],
      ['🪔 কালীপূজা', '৮ নভেম্বর ২০২৬'],
      ['🌼 সরস্বতী পূজা', '২৩ জানুয়ারি ২০২৬'],
    ],
  };
}

// =====================================================================
// SIDE MENU
// =====================================================================

class _SideMenu extends StatelessWidget {
  final ValueChanged<String> onSelect;
  const _SideMenu({required this.onSelect});

  static const _items = [
    ['🪷', 'পঞ্জিকা'],
    ['📅', 'বাংলা ক্যালেন্ডার'],
    ['🪔', 'উৎসব ও বিশেষ দিন'],
    ['⏰', 'রিমাইন্ডার'],
    ['📝', 'নোটস'],
    ['⚙️', 'সেটিংস'],
    ['👤', 'প্রোফাইল'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1C38), Color(0xFF06101F)],
        ),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('☰ বাংলা পঞ্জিকা',
                  style: TextStyle(color: Color(0xFFFFD36E), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              ..._items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => onSelect(it[1]),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        Text(it[0], style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Text(it[1], style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// SHARED SCREEN HEADER (Back button + title)
// =====================================================================

class _ScreenHeader extends StatelessWidget {
  final String title;
  const _ScreenHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFFD36E), fontSize: 19, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// =====================================================================
// বাংলা ক্যালেন্ডার পেজ
// =====================================================================

// =====================================================================
// বাংলা তারিখ কনভার্সন (আনুমানিক / ডেমো — প্রকৃত পঞ্জিকা ইঞ্জিন পরে যুক্ত হবে)
// =====================================================================

class BengaliMonthInfo {
  final String name;
  final int year;
  final DateTime start;
  final DateTime end;
  BengaliMonthInfo(this.name, this.year, this.start, this.end);
}

class BengaliDateUtil {
  static List<Map<String, dynamic>> _yearBoundaries(int g) {
    final by = g - 593;
    return [
      {'name': 'বৈশাখ', 'date': DateTime(g, 4, 14), 'bYear': by},
      {'name': 'জ্যৈষ্ঠ', 'date': DateTime(g, 5, 15), 'bYear': by},
      {'name': 'আষাঢ়', 'date': DateTime(g, 6, 15), 'bYear': by},
      {'name': 'শ্রাবণ', 'date': DateTime(g, 7, 16), 'bYear': by},
      {'name': 'ভাদ্র', 'date': DateTime(g, 8, 17), 'bYear': by},
      {'name': 'আশ্বিন', 'date': DateTime(g, 9, 17), 'bYear': by},
      {'name': 'কার্তিক', 'date': DateTime(g, 10, 18), 'bYear': by},
      {'name': 'অগ্রহায়ণ', 'date': DateTime(g, 11, 17), 'bYear': by},
      {'name': 'পৌষ', 'date': DateTime(g, 12, 16), 'bYear': by},
      {'name': 'মাঘ', 'date': DateTime(g + 1, 1, 15), 'bYear': by},
      {'name': 'ফাল্গুন', 'date': DateTime(g + 1, 2, 13), 'bYear': by},
      {'name': 'চৈত্র', 'date': DateTime(g + 1, 3, 15), 'bYear': by},
    ];
  }

  static List<Map<String, dynamic>> _boundariesAround(int gregYear) {
    final list = <Map<String, dynamic>>[];
    for (final g in [gregYear - 2, gregYear - 1, gregYear, gregYear + 1]) {
      list.addAll(_yearBoundaries(g));
    }
    list.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return list;
  }

  static BengaliMonthInfo monthInfoFor(DateTime date) {
    final boundaries = _boundariesAround(date.year);
    int idx = 0;
    for (int i = 0; i < boundaries.length; i++) {
      if (!(boundaries[i]['date'] as DateTime).isAfter(date)) idx = i;
    }
    final cur = boundaries[idx];
    final next = boundaries[idx + 1];
    return BengaliMonthInfo(
      cur['name'] as String,
      cur['bYear'] as int,
      cur['date'] as DateTime,
      (next['date'] as DateTime).subtract(const Duration(days: 1)),
    );
  }
}

class CalendarEvent {
  final String label;
  final String category; // general, marriage, annaprashan, griha
  final String icon;
  const CalendarEvent(this.label, this.category, {this.icon = '✦'});
}

class BengaliCalendarData {
  static const Map<String, List<CalendarEvent>> events = {
    '2026-01-01': [CalendarEvent('ইংরেজি নববর্ষ', 'general', icon: '🎉')],
    '2026-01-12': [CalendarEvent('স্বামী বিবেকানন্দ জন্মদিন', 'general', icon: '🧑')],
    '2026-01-23': [CalendarEvent('সরস্বতী পূজা', 'general', icon: '🌼')],
    '2026-01-26': [CalendarEvent('প্রজাতন্ত্র দিবস', 'general', icon: '🇮🇳')],
    '2026-02-17': [CalendarEvent('অমাবস্যা', 'general', icon: '🌑')],
    '2026-03-03': [CalendarEvent('দোলযাত্রা', 'general', icon: '🌕')],
    '2026-03-04': [CalendarEvent('হোলি', 'general', icon: '🎨')],
    '2026-03-26': [CalendarEvent('রাম নবমী', 'general', icon: '🛕')],
    '2026-04-14': [CalendarEvent('পয়লা বৈশাখ', 'general', icon: '🎉')],
    '2026-04-19': [CalendarEvent('অক্ষয় তৃতীয়া', 'marriage', icon: '💍')],
    '2026-05-01': [CalendarEvent('বৈশাখ পূর্ণিমা', 'general', icon: '🌕')],
    '2026-05-08': [CalendarEvent('গৃহপ্রবেশের শুভ দিন', 'griha', icon: '🏠')],
    '2026-06-10': [CalendarEvent('অন্নপ্রাশনের শুভ দিন', 'annaprashan', icon: '👶')],
    '2026-06-29': [CalendarEvent('গুরু পূর্ণিমা', 'general', icon: '🌕')],
    '2026-07-06': [CalendarEvent('বালগঙ্গাধর তিলক জন্মবার্ষিকী', 'general', icon: '🧑')],
    '2026-07-16': [CalendarEvent('রথযাত্রা', 'general', icon: '🛕')],
    '2026-07-24': [CalendarEvent('উল্টোরথ', 'general', icon: '🛕')],
    '2026-07-25': [CalendarEvent('একাদশী', 'general', icon: '🌑')],
    '2026-07-29': [CalendarEvent('পূর্ণিমা', 'general', icon: '🌕')],
    '2026-08-02': [CalendarEvent('আচার্য প্রফুল্লচন্দ্র রায় জন্মদিন', 'general', icon: '🧑')],
    '2026-08-07': [CalendarEvent('বিবাহের শুভ দিন', 'marriage', icon: '💍')],
    '2026-08-08': [CalendarEvent('রবীন্দ্রনাথ ঠাকুরের প্রয়াণ দিবস', 'general', icon: '🧑')],
    '2026-08-09': [CalendarEvent('মনসাদেবীর পূজা', 'general', icon: '🐍')],
    '2026-08-12': [CalendarEvent('একাদশী', 'general', icon: '🌑'), CalendarEvent('পূর্ণ সূর্যগ্রহণ', 'general', icon: '☀️')],
    '2026-08-13': [CalendarEvent('আখেরী চাহার শোম্বা', 'general', icon: '🕌')],
    '2026-08-15': [CalendarEvent('স্বাধীনতা দিবস', 'general', icon: '🇮🇳')],
    '2026-08-17': [CalendarEvent('মনসা পূজা', 'general', icon: '🐍')],
    '2026-08-20': [CalendarEvent('গৃহপ্রবেশের শুভ দিন', 'griha', icon: '🏠')],
    '2026-08-28': [CalendarEvent('রাখী বন্ধন', 'general', icon: '🎗️'), CalendarEvent('পূর্ণিমা', 'general', icon: '🌕')],
    '2026-09-04': [CalendarEvent('শ্রীকৃষ্ণ জন্মাষ্টমী', 'general', icon: '🦚')],
    '2026-09-14': [CalendarEvent('গণেশ চতুর্থী', 'general', icon: '🐘')],
    '2026-09-17': [CalendarEvent('বিশ্বকর্মা পূজা', 'general', icon: '🛠️')],
    '2026-09-26': [CalendarEvent('পূর্ণিমা', 'general', icon: '🌕')],
    '2026-10-10': [CalendarEvent('মহালয়া', 'general', icon: '🪔')],
    '2026-10-19': [CalendarEvent('মহাষ্টমী', 'general', icon: '🔱')],
    '2026-10-20': [CalendarEvent('বিজয়া দশমী', 'general', icon: '🔱')],
    '2026-10-25': [CalendarEvent('কোজাগরী লক্ষ্মীপূজা', 'general', icon: '🪷')],
    '2026-11-06': [CalendarEvent('ধনতেরাস', 'general', icon: '🪙')],
    '2026-11-08': [CalendarEvent('কালীপূজা / দীপাবলি', 'general', icon: '🪔')],
    '2026-11-11': [CalendarEvent('ভাইফোঁটা', 'general', icon: '🎗️')],
    '2026-11-24': [CalendarEvent('কার্তিক পূর্ণিমা', 'general', icon: '🌕')],
    '2026-11-27': [CalendarEvent('অন্নপ্রাশনের শুভ দিন', 'annaprashan', icon: '👶')],
    '2026-12-06': [CalendarEvent('বিবাহের শুভ দিন', 'marriage', icon: '💍')],
    '2026-12-25': [CalendarEvent('বড়দিন', 'general', icon: '🎄')],
  };
}

// =====================================================================
// বাংলা ক্যালেন্ডার পেজ
// =====================================================================

class BengaliCalendarScreen extends StatefulWidget {
  const BengaliCalendarScreen({super.key});
  @override
  State<BengaliCalendarScreen> createState() => _BengaliCalendarScreenState();
}

class _BengaliCalendarScreenState extends State<BengaliCalendarScreen> {
  DateTime _anchor = DateTime(2026, 8, 11);
  String _tab = 'সম্পূর্ণ মাস';
  String? _selectedKey;

  static const _tabs = ['সম্পূর্ণ মাস', 'বিশেষ দিন সমূহ', 'বিবাহ', 'অন্নপ্রাশন', 'গৃহপ্রবেশ'];
  static const _weekDays = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি'];
  static const _engAbbrev = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  static const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

  String _bn(int n) => n.toString().split('').map((c) => _bnDigits[int.parse(c)]).join();
  String _key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';

  String _tabCategory(String tab) {
    switch (tab) {
      case 'বিবাহ':
        return 'marriage';
      case 'অন্নপ্রাশন':
        return 'annaprashan';
      case 'গৃহপ্রবেশ':
        return 'griha';
      default:
        return '';
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      final info = BengaliDateUtil.monthInfoFor(_anchor);
      _anchor = delta > 0
          ? info.end.add(const Duration(days: 5))
          : info.start.subtract(const Duration(days: 5));
      _selectedKey = null;
    });
  }

  void _goToday() {
    setState(() {
      _anchor = DateTime.now();
      _selectedKey = null;
    });
  }

  void _reset() {
    setState(() {
      _tab = 'সম্পূর্ণ মাস';
      _selectedKey = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = BengaliDateUtil.monthInfoFor(_anchor);
    final totalDays = info.end.difference(info.start).inDays + 1;
    final leading = info.start.weekday % 7; // রবি=0 ভিত্তিক
    final trailing = (7 - ((leading + totalDays) % 7)) % 7;

    final prevInfo = BengaliDateUtil.monthInfoFor(info.start.subtract(const Duration(days: 1)));
    final prevTotalDays = prevInfo.end.difference(prevInfo.start).inDays + 1;

    final filterCat = _tabCategory(_tab);

    return CosmicBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('${info.name} ${_bn(info.year)}',
                          style: const TextStyle(color: Color(0xFFFFD36E), fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                          '${_engAbbrev[info.start.month - 1]}-${_engAbbrev[info.end.month - 1]} ${info.start.year}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.today_outlined, color: Colors.white),
                  tooltip: 'আজকের দিনে যাও',
                  onPressed: _goToday,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'রিসেট',
                  onPressed: _reset,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
              children: [
                // মাস navigation
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: () => _changeMonth(-1)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white), onPressed: () => _changeMonth(1)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // ট্যাব বার
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tabs.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final t = _tabs[i];
                      final active = t == _tab;
                      return GestureDetector(
                        onTap: () => setState(() => _tab = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFFD72A3B) : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: active ? const Color(0xFFD72A3B) : Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Text(t, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: _weekDays
                      .map((d) => Expanded(
                    child: Center(child: Text(d, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600))),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 6),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: leading + totalDays + trailing,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    mainAxisExtent: 62,
                  ),
                  itemBuilder: (context, i) {
                    // --- আগের মাসের গ্রে করা দিনগুলো ---
                    if (i < leading) {
                      final d = prevTotalDays - leading + 1 + i;
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(9)),
                        child: Text(_bn(d), style: const TextStyle(color: Colors.white24, fontSize: 13)),
                      );
                    }
                    // --- পরের মাসের গ্রে করা দিনগুলো ---
                    if (i >= leading + totalDays) {
                      final d = i - leading - totalDays + 1;
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(9)),
                        child: Text(_bn(d), style: const TextStyle(color: Colors.white24, fontSize: 13)),
                      );
                    }
                    // --- বর্তমান মাসের দিন ---
                    final bengaliDay = i - leading + 1;
                    final greg = info.start.add(Duration(days: bengaliDay - 1));
                    final key = _key(greg);
                    final events = BengaliCalendarData.events[key] ?? const <CalendarEvent>[];
                    final topLabel = greg.day == 1 ? _engAbbrev[greg.month - 1] : greg.day.toString();
                    final now = DateTime.now();
                    final isToday = greg.year == now.year && greg.month == now.month && greg.day == now.day;
                    final isSelected = key == _selectedKey;
                    final matchesFilter = filterCat.isEmpty
                        ? events.isNotEmpty
                        : events.any((e) => e.category == filterCat);
                    final dim = _tab != 'সম্পূর্ণ মাস' && !matchesFilter;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedKey = key),
                      child: Opacity(
                        opacity: dim ? 0.35 : 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                          decoration: BoxDecoration(
                            color: isToday
                                ? const Color(0xFFF7BD53).withValues(alpha: 0.9)
                                : (matchesFilter && _tab != 'সম্পূর্ণ মাস'
                                ? const Color(0xFFD72A3B).withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF7DC4FF) : Colors.transparent,
                              width: isSelected ? 2 : 0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(topLabel,
                                  style: TextStyle(
                                      fontSize: 8,
                                      color: isToday ? const Color(0xFF071428) : Colors.white38,
                                      fontWeight: FontWeight.w600)),
                              Text(_bn(bengaliDay),
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isToday ? const Color(0xFF071428) : Colors.white)),
                              if (events.isNotEmpty)
                                Text(events.first.icon, style: const TextStyle(fontSize: 9)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: _selectedKey == null
                      ? const Text('একটা দিন সিলেক্ট করো বিস্তারিত দেখতে',
                      style: TextStyle(color: Colors.white54, fontSize: 13))
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedKey!,
                          style: const TextStyle(color: Color(0xFFFFD36E), fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...(BengaliCalendarData.events[_selectedKey] ?? []).map(
                            (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('${e.icon} ${e.label}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                      ),
                      if ((BengaliCalendarData.events[_selectedKey] ?? []).isEmpty)
                        const Text('কোনো বিশেষ দিন নেই', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '📍 বিবাহ/অন্নপ্রাশন/গৃহপ্রবেশের শুভ তারিখ এখানে ডেমো ডেটা হিসেবে দেখানো হয়েছে। প্রকৃত অ্যাপে user-এর তিথি, নক্ষত্র ও লগ্ন অনুযায়ী verified পঞ্জিকা ইঞ্জিন থেকে এই তথ্য আসবে।',
                  style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// রিমাইন্ডার
// =====================================================================

class ReminderItem {
  String text;
  DateTime when;
  ReminderItem(this.text, this.when);
}

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});
  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final List<ReminderItem> _reminders = [];
  final _textController = TextEditingController();
  DateTime? _pickedDateTime;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    setState(() {
      _pickedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _addReminder() {
    final text = _textController.text.trim();
    if (text.isEmpty || _pickedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('টেক্সট ও সময় দুটোই দিন')));
      return;
    }
    setState(() {
      _reminders.insert(0, ReminderItem(text, _pickedDateTime!));
      _textController.clear();
      _pickedDateTime = null;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '⏰ রিমাইন্ডার'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'যেমন: একাদশী ব্রত',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickDateTime,
                  icon: const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                  label: Text(
                    _pickedDateTime == null
                        ? 'তারিখ ও সময় বাছাই করুন'
                        : '${_pickedDateTime!.day}/${_pickedDateTime!.month}/${_pickedDateTime!.year} • ${_pickedDateTime!.hour.toString().padLeft(2, "0")}:${_pickedDateTime!.minute.toString().padLeft(2, "0")}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addReminder,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD36E), padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('রিমাইন্ডার সেভ করুন', style: TextStyle(color: Color(0xFF071428), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                if (_reminders.isEmpty)
                  const Text('এখনও কোনো রিমাইন্ডার নেই।', style: TextStyle(color: Colors.white54))
                else
                  ..._reminders.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active, color: Color(0xFFFFD36E), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              Text(
                                  '${r.when.day}/${r.when.month}/${r.when.year} • ${r.when.hour.toString().padLeft(2, "0")}:${r.when.minute.toString().padLeft(2, "0")}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white54),
                          onPressed: () => setState(() => _reminders.remove(r)),
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// নোটস
// =====================================================================

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<String> _notes = [];
  final _controller = TextEditingController();

  void _add() {
    final v = _controller.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _notes.insert(0, v);
      _controller.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '📝 আমার নোটস'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'আপনার নোট লিখুন...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _add,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD36E), padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('নোট সেভ করুন', style: TextStyle(color: Color(0xFF071428), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                if (_notes.isEmpty)
                  const Text('এখনও কোনো নোট নেই।', style: TextStyle(color: Colors.white54))
                else
                  ..._notes.asMap().entries.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.value, style: const TextStyle(color: Colors.white))),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white54),
                          onPressed: () => setState(() => _notes.removeAt(e.key)),
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// সেটিংস
// =====================================================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _lang = 'বাংলা';
  bool _weather = true;
  bool _skyAnim = true;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '⚙️ সেটিংস'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('ভাষা', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                  child: DropdownButton<String>(
                    value: _lang,
                    dropdownColor: const Color(0xFF0B1B35),
                    isExpanded: true,
                    underline: const SizedBox(),
                    style: const TextStyle(color: Colors.white),
                    items: ['বাংলা', 'Hindi', 'English'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (v) => setState(() => _lang = v ?? _lang),
                  ),
                ),
                const SizedBox(height: 16),
                _switchTile('📍 Live Location Weather', _weather, (v) => setState(() => _weather = v)),
                _switchTile('🌌 Live Sky Animation', _skyAnim, (v) => setState(() => _skyAnim = v)),
                _switchTile('🔔 Notifications', _notifications, (v) => setState(() => _notifications = v)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সেটিংস সেভ হয়েছে')));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD36E), padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('সেটিংস সেভ করুন', style: TextStyle(color: Color(0xFF071428), fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
          Switch(value: value, onChanged: onChanged, activeThumbColor: const Color(0xFFFFD36E)),
        ],
      ),
    );
  }
}

// =====================================================================
// প্রোফাইল
// =====================================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '👤 প্রোফাইল'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('নাম', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'আপনার নাম',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('শহর', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _cityController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'যেমন: কলকাতা',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('প্রোফাইল সেভ হয়েছে')));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD36E), padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('সেভ করুন', style: TextStyle(color: Color(0xFF071428), fontWeight: FontWeight.bold)),
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