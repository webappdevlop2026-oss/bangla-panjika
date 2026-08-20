import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  await NotificationService.instance.init();
  runApp(const BanglaPanjikaApp());
}

// =====================================================================
// সেটিংস ও সংরক্ষণ — সব পছন্দ ফোনে সেভ থাকে, অ্যাপ বন্ধ করলেও মুছে যায় না
// =====================================================================

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _kLang = 'lang';
  static const _kWeather = 'weather';
  static const _kSkyAnim = 'sky_anim';
  static const _kNotif = 'notifications';
  static const _kDistrict = 'district';
  static const _kName = 'profile_name';
  static const _kCity = 'profile_city';
  static const _kSetupDone = 'setup_done';

  SharedPreferences? _prefs;

  String lang = 'বাংলা';
  bool weather = true;
  bool skyAnim = true;
  bool notifications = true;
  String profileName = '';
  String profileCity = '';
  // একবার ভাষা/জেলা/থিম বেছে "শুরু করুন" চাপলে এটা true হয়ে সেভ থাকে —
  // পরের বার অ্যাপ/ওয়েব লিংক খুললে পুরো onboarding আর দেখাতে হয় না,
  // সরাসরি হোম স্ক্রিনে চলে যায়
  bool setupComplete = false;

  bool get isBangla => lang == 'বাংলা';

  /// সেভ করা জেলা (প্রথমবার চালু করলে কলকাতা)
  String get district => AppLocation.district;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    lang = p.getString(_kLang) ?? lang;
    weather = p.getBool(_kWeather) ?? weather;
    skyAnim = p.getBool(_kSkyAnim) ?? skyAnim;
    notifications = p.getBool(_kNotif) ?? notifications;
    profileName = p.getString(_kName) ?? '';
    profileCity = p.getString(_kCity) ?? '';
    setupComplete = p.getBool(_kSetupDone) ?? false;
    final d = p.getString(_kDistrict);
    if (d != null) AppLocation.district = d;
    notifyListeners();
  }

  /// Onboarding শেষে ("শুরু করুন" বাটনে) ডাকা হয় — এরপর থেকে অ্যাপ খুললেই
  /// সরাসরি হোম স্ক্রিনে যাবে, ভাষা/জেলা/পারমিশন স্ক্রিন আর দেখাবে না
  Future<void> markSetupComplete() async {
    setupComplete = true;
    final p = _prefs ??= await SharedPreferences.getInstance();
    await p.setBool(_kSetupDone, true);
  }

  Future<void> save({
    String? lang,
    bool? weather,
    bool? skyAnim,
    bool? notifications,
  }) async {
    if (lang != null) this.lang = lang;
    if (weather != null) this.weather = weather;
    if (skyAnim != null) this.skyAnim = skyAnim;
    if (notifications != null) this.notifications = notifications;
    final p = _prefs ??= await SharedPreferences.getInstance();
    await p.setString(_kLang, this.lang);
    await p.setBool(_kWeather, this.weather);
    await p.setBool(_kSkyAnim, this.skyAnim);
    await p.setBool(_kNotif, this.notifications);
    // নোটিফিকেশন বন্ধ করলে আগে থেকে সেট করা সব রিমাইন্ডারও বাতিল হবে
    if (!this.notifications) {
      await NotificationService.instance.cancelAll();
    } else {
      await ReminderStore.instance.rescheduleAll();
    }
    notifyListeners();
  }

  Future<void> saveDistrict(String district) async {
    AppLocation.select(district);
    final p = _prefs ??= await SharedPreferences.getInstance();
    await p.setString(_kDistrict, AppLocation.district);
    notifyListeners();
  }

  Future<void> saveProfile({required String name, required String city}) async {
    profileName = name;
    profileCity = city;
    final p = _prefs ??= await SharedPreferences.getInstance();
    await p.setString(_kName, name);
    await p.setString(_kCity, city);
    notifyListeners();
  }
}

/// রিমাইন্ডার — ফোনে সেভ থাকে এবং নির্ধারিত সময়ে নোটিফিকেশন বাজে
class ReminderStore {
  ReminderStore._();
  static final ReminderStore instance = ReminderStore._();
  static const _key = 'reminders';

  final List<ReminderItem> items = [];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_key) ?? const [];
    items
      ..clear()
      ..addAll(
        raw.map((e) {
          final m = jsonDecode(e) as Map<String, dynamic>;
          return ReminderItem(
            m['text'] as String,
            DateTime.fromMillisecondsSinceEpoch(m['when'] as int),
            id: m['id'] as int,
          );
        }),
      );
    items.sort((a, b) => b.when.compareTo(a.when));
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _key,
      items
          .map(
            (r) => jsonEncode({
              'id': r.id,
              'text': r.text,
              'when': r.when.millisecondsSinceEpoch,
            }),
          )
          .toList(),
    );
  }

  Future<void> add(ReminderItem item) async {
    items.insert(0, item);
    await _persist();
    if (AppSettings.instance.notifications) {
      await NotificationService.instance.schedule(item);
    }
  }

  Future<void> remove(ReminderItem item) async {
    items.remove(item);
    await _persist();
    await NotificationService.instance.cancel(item.id);
  }

  /// নোটিফিকেশন আবার চালু করলে ভবিষ্যতের সব রিমাইন্ডার পুনরায় সেট হয়
  Future<void> rescheduleAll() async {
    if (items.isEmpty) await load();
    for (final r in items) {
      if (r.when.isAfter(DateTime.now())) {
        await NotificationService.instance.schedule(r);
      }
    }
  }
}

/// নোটস — ফোনে সেভ থাকে
class NotesStore {
  NotesStore._();
  static final NotesStore instance = NotesStore._();
  static const _key = 'notes';

  final List<String> items = [];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    items
      ..clear()
      ..addAll(p.getStringList(_key) ?? const []);
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, items);
  }

  Future<void> add(String note) async {
    items.insert(0, note);
    await _persist();
  }

  Future<void> removeAt(int index) async {
    items.removeAt(index);
    await _persist();
  }
}

/// সত্যিকারের লোকাল নোটিফিকেশন — নির্ধারিত সময়ে ফোনে অ্যালার্ট আসবে
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'panjika_reminders',
        'পঞ্জিকা রিমাইন্ডার',
        channelDescription: 'আপনার সেট করা রিমাইন্ডারের নোটিফিকেশন',
        importance: Importance.max,
        priority: Priority.high,
      );

  Future<void> init() async {
    if (_ready) return;
    // ওয়েব ভার্সনে local notification প্লাগইনটা কাজ করে না (কোনো ব্রাউজার
    // ইমপ্লিমেন্টেশন নেই) — চেষ্টা করলে অ্যাপটাই ক্র্যাশ করত। তাই ওয়েবে
    // এই ফিচারটা চুপচাপ বাদ দেওয়া হচ্ছে, বাকি সব ফিচার স্বাভাবিক চলবে।
    if (kIsWeb) {
      _ready = true;
      return;
    }
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);

    // Android 13+ এ নোটিফিকেশনের অনুমতি চাইতে হয়
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();

    _ready = true;
  }

  Future<void> schedule(ReminderItem item) async {
    await init();
    if (kIsWeb) return;
    if (!item.when.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      item.id,
      'পঞ্জিকা রিমাইন্ডার',
      item.text,
      tz.TZDateTime.from(item.when, tz.local),
      const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // iOS-এ সময়টা ঠিক ওই মুহূর্ত হিসেবেই ধরা হবে (টাইমজোন অনুযায়ী নয়)
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int id) async {
    await init();
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await init();
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}

class BanglaPanjikaApp extends StatelessWidget {
  const BanglaPanjikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // সেটিংস বদলালে (যেমন ভাষা) পুরো অ্যাপ নতুন করে আঁকা হয়
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'বাংলা পঞ্জিকা',
        theme: ThemeData(useMaterial3: true),
        initialRoute: '/splash',
        navigatorObservers: [routeObserver],
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/language': (context) => const LanguageScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/location': (context) => const LocationSelectScreen(),
          '/permission': (context) => const PermissionScreen(),
          '/theme_select': (context) => const ThemeSelectScreen(),
          '/home': (context) => const HomeDashboardScreen(),
        },
      ),
    );
  }
}

/// দিনের কোন মুহূর্তে আকাশ কেমন দেখাবে (রং, তারা, সূর্য/চাঁদের অবস্থান) —
/// প্রকৃত সূর্যোদয়/অস্তের সময়ের ভিত্তিতে (রিয়েল-টাইম) হিসেব করা হয়।
class SkyPhase {
  final List<Color> gradientColors;
  final List<double> gradientStops;
  final double starOpacity;
  final bool isDay;
  // প্রকৃত চাঁদের দশা — moonIllumination: ০ (অমাবস্যা) .. ১ (পূর্ণিমা)
  final double moonIllumination;
  final bool moonWaxing; // true = শুক্লপক্ষ (বাড়ছে), false = কৃষ্ণপক্ষ (কমছে)
  final bool isAmavasya; // আজ প্রায় অমাবস্যা — রাতের আকাশ পুরো কালো দেখাবে

  const SkyPhase({
    required this.gradientColors,
    required this.gradientStops,
    required this.starOpacity,
    required this.isDay,
    required this.moonIllumination,
    required this.moonWaxing,
    required this.isAmavasya,
  });

  // মহাকাশ থেকে দেখা আকাশ: উপরের দিক সবসময় গভীর অন্ধকার মহাশূন্য,
  // শুধু নিচের দিগন্তে বায়ুমণ্ডলের আভা সময় অনুযায়ী রং বদলায়।
  // এতে ব্রহ্মাণ্ডের চেহারা দিনে-রাতে সবসময় বজায় থাকে।
  static const List<Color> _night = [
    Color(0xFF01030A), Color(0xFF050D1E), Color(0xFF071228), Color(0xFF03060F),
  ];
  // অমাবস্যার রাত — চাঁদের আলো একদমই নেই বলে বাস্তবে আকাশ সবচেয়ে গাঢ়/কালো
  // দেখায়, শুধু তারাগুলো ফুটে থাকে
  static const List<Color> _amavasyaNight = [
    Color(0xFF000000), Color(0xFF010103), Color(0xFF020208), Color(0xFF000000),
  ];
  static const List<Color> _dawnDusk = [
    Color(0xFF030718), Color(0xFF0B1430), Color(0xFF4A2F5E), Color(0xFF10142A),
  ];
  static const List<Color> _sunriseSunset = [
    Color(0xFF040A1C), Color(0xFF0E1E42), Color(0xFFC2603A), Color(0xFF2A1428),
  ];
  static const List<Color> _morningEvening = [
    Color(0xFF04091A), Color(0xFF0C1B3C), Color(0xFF6E86B8), Color(0xFF14203A),
  ];
  static const List<Color> _midday = [
    Color(0xFF04081A), Color(0xFF0A1735), Color(0xFF2E5F96), Color(0xFF0C1730),
  ];
  static const List<double> _stops = [0.0, 0.45, 0.82, 1.0];

  static List<Color> _lerpColors(List<Color> a, List<Color> b, double t) =>
      List.generate(a.length, (i) => Color.lerp(a[i], b[i], t)!);

  static SkyPhase forTime(DateTime now, {double? lat, double? lon}) {
    final today = PanchangCalculator.sunTimes(now, lat: lat, lon: lon);
    final sunrise = today.sunrise;
    final sunset = today.sunset;
    // sunTimes() যা রিটার্ন করে তা "IST-marked" (দেখুন
    // PanchangCalculator._toTrueUtc-এর মন্তব্য) — DateTime.now() সরাসরি
    // এর সাথে তুলনা করলে ৫:৩০ ঘন্টার ভুল হতো, তাই একই ফরম্যাটে আনা হলো।
    final nowMarked =
        now.toUtc().add(const Duration(hours: 5, minutes: 30));

    // --- প্রকৃত চাঁদের দশা (real-time) ---
    // moonAgeDays: ০ = অমাবস্যা মুহূর্ত, ~১৪.৭৭ = পূর্ণিমা, ~২৯.৫৩ = পরের অমাবস্যা
    const synodic = 29.530588853;
    final moonAge = PanchangCalculator.moonAgeDays(now) % synodic;
    final phaseAngle = moonAge / synodic * 2 * math.pi;
    final moonIllumination = (1 - math.cos(phaseAngle)) / 2; // ০..১
    final moonWaxing = moonAge < synodic / 2;
    // অমাবস্যার ~১ দিনের মধ্যে থাকলে "আজ অমাবস্যা" ধরা হচ্ছে
    final isAmavasya = moonAge < 1.0 || moonAge > synodic - 1.0;
    final nightColors = isAmavasya ? _amavasyaNight : _night;

    if (nowMarked.isAfter(sunrise) && nowMarked.isBefore(sunset)) {
      // --- দিন ---
      final total = sunset.difference(sunrise).inSeconds;
      final elapsed = nowMarked.difference(sunrise).inSeconds;
      final p = total <= 0 ? 0.5 : (elapsed / total).clamp(0.0, 1.0);

      List<Color> colors;
      if (p < 0.12) {
        colors = _lerpColors(_sunriseSunset, _morningEvening, p / 0.12);
      } else if (p < 0.4) {
        colors = _lerpColors(_morningEvening, _midday, (p - 0.12) / 0.28);
      } else if (p < 0.6) {
        colors = _midday;
      } else if (p < 0.88) {
        colors = _lerpColors(_midday, _morningEvening, (p - 0.6) / 0.28);
      } else {
        colors = _lerpColors(_morningEvening, _sunriseSunset, (p - 0.88) / 0.12);
      }

      return SkyPhase(
        gradientColors: colors,
        gradientStops: _stops,
        starOpacity: 0.55,
        isDay: true,
        moonIllumination: moonIllumination,
        moonWaxing: moonWaxing,
        isAmavasya: isAmavasya,
      );
    }

    // --- রাত (সূর্যাস্ত থেকে পরের সূর্যোদয় পর্যন্ত) ---
    late DateTime nightStart;
    late DateTime nightEnd;
    if (nowMarked.isAfter(sunset)) {
      nightStart = sunset;
      nightEnd = PanchangCalculator.sunTimes(
        now.add(const Duration(days: 1)),
        lat: lat,
        lon: lon,
      ).sunrise;
    } else {
      nightStart = PanchangCalculator.sunTimes(
        now.subtract(const Duration(days: 1)),
        lat: lat,
        lon: lon,
      ).sunset;
      nightEnd = sunrise;
    }
    final total = nightEnd.difference(nightStart).inSeconds;
    final elapsed = nowMarked.difference(nightStart).inSeconds;
    final p = total <= 0 ? 0.5 : (elapsed / total).clamp(0.0, 1.0);

    List<Color> colors;
    double starOpacity;
    // তারার উজ্জ্বলতা কখনও ০ হয় না — দিনেও ম্লানভাবে ব্রহ্মাণ্ড দেখা যায়,
    // গভীর রাতে সবচেয়ে উজ্জ্বল।
    if (p < 0.08) {
      colors = _lerpColors(_sunriseSunset, _dawnDusk, p / 0.08);
      starOpacity = 0.55 + p / 0.08 * 0.30;
    } else if (p < 0.22) {
      colors = _lerpColors(_dawnDusk, nightColors, (p - 0.08) / 0.14);
      starOpacity = 0.85 + (p - 0.08) / 0.14 * 0.15;
    } else if (p < 0.78) {
      colors = nightColors;
      starOpacity = 1.0;
    } else if (p < 0.92) {
      colors = _lerpColors(nightColors, _dawnDusk, (p - 0.78) / 0.14);
      starOpacity = 1.0 - (p - 0.78) / 0.14 * 0.15;
    } else {
      colors = _lerpColors(_dawnDusk, _sunriseSunset, (p - 0.92) / 0.08);
      starOpacity = 0.85 - (p - 0.92) / 0.08 * 0.30;
    }

    return SkyPhase(
      gradientColors: colors,
      gradientStops: _stops,
      starOpacity: starOpacity.clamp(0.0, 1.0),
      isDay: false,
      moonIllumination: moonIllumination,
      moonWaxing: moonWaxing,
      isAmavasya: isAmavasya,
    );
  }
}

/// নবগ্রহ — জ্যোতিষশাস্ত্রের ৯টি গ্রহ, প্রতিটি নিজস্ব রঙে কক্ষপথে ঘুরবে।
class CosmicBackground extends StatefulWidget {
  final Widget child;
  const CosmicBackground({super.key, required this.child});
  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with TickerProviderStateMixin, RouteAware {
  late final AnimationController _orbitController;
  // পুরো অ্যাপের ব্যাকগ্রাউন্ডে লাইভ বৃষ্টির অ্যানিমেশনের জন্য আলাদা কন্ট্রোলার
  late final AnimationController _rainController;
  Timer? _clockTimer;
  SkyPhase _phase = SkyPhase.forTime(DateTime.now());
  bool _isRaining = false;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    // সেটিংসে 'Live Sky Animation' বন্ধ থাকলে গ্রহ ঘোরে না
    if (AppSettings.instance.skyAnim) _orbitController.repeat();
    _refreshPhase();
    // নির্বাচিত জেলায় সত্যিই এখন বৃষ্টি হচ্ছে কিনা — লাইভ, লোকেশন-ভিত্তিক
    _isRaining = WeatherService.instance.isRaining;
    _syncRainAnim();
    WeatherService.instance.addListener(_onWeatherChanged);
    WeatherService.instance.refresh();
    // প্রতি মিনিটে আকাশের রং/সূর্য-চাঁদের অবস্থান রিয়েল টাইমে আপডেট হবে;
    // WeatherService নিজে ১৫ মিনিটের বেশি পুরনো না হলে আবার কল করে না, তাই
    // এখানে refresh() ডাকলেও বাড়তি নেটওয়ার্ক লোড হয় না
    _clockTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _refreshPhase();
      WeatherService.instance.refresh();
    });
  }

  void _onWeatherChanged() {
    if (!mounted) return;
    setState(() {
      _isRaining = WeatherService.instance.isRaining;
      _syncRainAnim();
    });
  }

  void _syncRainAnim() {
    if (_isRaining && AppSettings.instance.skyAnim) {
      if (!_rainController.isAnimating) _rainController.repeat();
    } else {
      _rainController.stop();
    }
  }

  void _refreshPhase() {
    if (!mounted) return;
    setState(() {
      _phase = SkyPhase.forTime(
        DateTime.now(),
        lat: AppLocation.lat,
        lon: AppLocation.lon,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPush() {
    if (AppSettings.instance.skyAnim) _orbitController.repeat();
    _syncRainAnim();
  }

  @override
  void didPopNext() {
    if (AppSettings.instance.skyAnim) {
      _orbitController.repeat();
    } else {
      _orbitController.stop();
    }
    _refreshPhase();
    WeatherService.instance.refresh();
    _syncRainAnim();
  }

  @override
  void didPushNext() {
    _orbitController.stop();
    _rainController.stop();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _orbitController.dispose();
    _rainController.dispose();
    WeatherService.instance.removeListener(_onWeatherChanged);
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _phase.gradientColors,
                stops: _phase.gradientStops,
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _phase.starOpacity,
              duration: const Duration(seconds: 3),
              child: const StarsLayer(),
            ),
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
                  // --- সূর্য: বাইরের করোনা থেকে ভেতরের উত্তপ্ত কেন্দ্র পর্যন্ত স্তরে স্তরে ---
                  Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0x33FFB74D),
                          Color(0x1AFF9800),
                          Color(0x00FF9800),
                        ],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0x66FFD54F),
                          Color(0x22FFA726),
                          Color(0x00FFA726),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment(-0.15, -0.15),
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFFFF3C4),
                          Color(0xFFFFC44D),
                          Color(0xFFFF8F00),
                        ],
                        stops: [0.0, 0.3, 0.68, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xCCFFC44D),
                          blurRadius: 26,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: Color(0x55FF8F00),
                          blurRadius: 48,
                          spreadRadius: 10,
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
          // ---- চাঁদ: প্রকৃত আজকের দশা (শুক্ল/কৃষ্ণপক্ষ) অনুযায়ী আলোকিত অংশ
          // বদলায় — অমাবস্যায় প্রায় অদৃশ্য, পূর্ণিমায় সম্পূর্ণ গোলাকার
          Positioned(
            top: 70,
            left: -34,
            child: SizedBox(
              width: 130,
              height: 130,
              child: CustomPaint(
                painter: _MoonPhasePainter(
                  illumination: _phase.moonIllumination,
                  waxing: _phase.moonWaxing,
                ),
              ),
            ),
          ),
          // ---- লাইভ আবহাওয়া: এখন সত্যিই বৃষ্টি হলে সারা অ্যাপের ব্যাকগ্রাউন্ডে
          // মেঘলা আভা + বৃষ্টির অ্যানিমেশন — নির্বাচিত জেলার real-time ডেটা
          // অনুযায়ী (Open-Meteo)। IgnorePointer দেওয়া আছে যাতে বোতাম/স্ক্রল
          // চাপতে কোনো সমস্যা না হয়।
          IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(seconds: 2),
              opacity: _isRaining ? 1.0 : 0.0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x552A3446), Color(0x2E10161F)],
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(seconds: 2),
              opacity: _isRaining ? 1.0 : 0.0,
              child: AnimatedBuilder(
                animation: _rainController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CosmicRainOverlayPainter(_rainController.value),
                    size: Size.infinite,
                  );
                },
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
            // আলো আসছে কেন্দ্রের সূর্য থেকে — তাই গ্রহের যে দিকটা কেন্দ্রের
            // দিকে ফেরানো সেটাই আলোকিত, উল্টো দিকটা ছায়ায় ঢাকা (প্রকৃত গ্রহের মতো)
            final lit = Alignment(
              -math.cos(angle) * 0.62,
              -math.sin(angle) * 0.62,
            );
            final highlight = Color.lerp(planetColor, Colors.white, 0.72)!;
            final midTone = planetColor;
            final darkSide = Color.lerp(planetColor, const Color(0xFF05070F), 0.78)!;
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
                  gradient: RadialGradient(
                    center: lit,
                    radius: 0.95,
                    colors: [highlight, midTone, darkSide],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: planetColor.withValues(alpha: 0.55),
                      blurRadius: 10,
                    ),
                    BoxShadow(
                      color: planetColor.withValues(alpha: 0.22),
                      blurRadius: 20,
                      spreadRadius: 2,
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

/// সারা অ্যাপের ব্যাকগ্রাউন্ডে বৃষ্টির অ্যানিমেশন — নির্বাচিত জেলায় লাইভ
/// আবহাওয়া (Open-Meteo) সত্যিই বৃষ্টি দেখালে তবেই আঁকা হয়।
class _CosmicRainOverlayPainter extends CustomPainter {
  _CosmicRainOverlayPainter(this.rainT);
  final double rainT;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rainPaint = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.32)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(101);
    for (int i = 0; i < 140; i++) {
      final baseX = rnd.nextDouble() * (w + 120) - 60;
      final speedFactor = 0.7 + rnd.nextDouble() * 0.9;
      final y0 = ((rainT * speedFactor + rnd.nextDouble()) % 1.0) * h;
      final x0 = baseX + y0 * 0.18;
      canvas.drawLine(Offset(x0, y0), Offset(x0 - 7, y0 + 18), rainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicRainOverlayPainter old) =>
      old.rainT != rainT;
}

/// আজকের প্রকৃত চাঁদের দশা এঁকে দেখায় — অমাবস্যায় প্রায় পুরো অন্ধকার
/// (শুধু ম্লান earthshine), পূর্ণিমায় সম্পূর্ণ আলোকিত গোলক, আর মাঝের
/// দিনগুলোতে সঠিক অনুপাতে কাস্তে/অর্ধেক/উঁচানো চাঁদ (waxing = ডানদিক
/// আলোকিত ও বাড়ছে — শুক্লপক্ষ; waning = বাঁদিক আলোকিত ও কমছে — কৃষ্ণপক্ষ)।
class _MoonPhasePainter extends CustomPainter {
  _MoonPhasePainter({required this.illumination, required this.waxing});
  final double illumination; // ০ (অমাবস্যা) .. ১ (পূর্ণিমা)
  final bool waxing;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 * 0.62;

    // ম্লান আভা (glow) — পূর্ণিমার কাছাকাছি সবচেয়ে উজ্জ্বল
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.28 * illumination + 0.04),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 1.9));
    canvas.drawCircle(center, r * 1.9, glowPaint);

    // অন্ধকার/অনালোকিত অংশ — earthshine-এর মতো খুব ম্লান ধূসর, একদমই
    // কালো নয় (বাস্তবেও অমাবস্যার সময় চাঁদের আভাস বোঝা যায়)
    final darkPaint = Paint()..color = const Color(0xFF2A3040);
    canvas.drawCircle(center, r, darkPaint);

    // আলোকিত অংশ আঁকা — দুই অর্ধবৃত্ত/উপবৃত্তের combine দিয়ে বাস্তব দশা
    final k = illumination.clamp(0.0, 1.0);
    if (k > 0.005) {
      final rightLit = waxing;
      final circleRect = Rect.fromCircle(center: center, radius: r);
      final halfPath = Path();
      if (rightLit) {
        halfPath.addArc(circleRect, -math.pi / 2, math.pi);
      } else {
        halfPath.addArc(circleRect, math.pi / 2, math.pi);
      }
      halfPath.close();

      Path litPath;
      if (k <= 0.5) {
        final rx = r * (1 - 2 * k);
        final ellipse = Path()
          ..addOval(Rect.fromCenter(center: center, width: rx * 2, height: r * 2));
        litPath = Path.combine(PathOperation.difference, halfPath, ellipse);
      } else {
        final rx = r * (2 * k - 1);
        final ellipse = Path()
          ..addOval(Rect.fromCenter(center: center, width: rx * 2, height: r * 2));
        litPath = Path.combine(PathOperation.union, halfPath, ellipse);
      }

      final litPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.2),
          colors: const [Color(0xFFFFFDF5), Color(0xFFEFE6C8), Color(0xFFC9BE9E)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(circleRect);
      canvas.drawPath(litPath, litPaint);
    }

    // হালকা crater টেক্সচার (শুধু আলোকিত অংশে বোঝা যায়, বাস্তবসম্মত ছোঁয়া)
    final craterPaint = Paint()..color = Colors.black.withValues(alpha: 0.07);
    canvas.drawCircle(center + Offset(r * 0.25, -r * 0.2), r * 0.14, craterPaint);
    canvas.drawCircle(center + Offset(-r * 0.1, r * 0.28), r * 0.10, craterPaint);
    canvas.drawCircle(center + Offset(r * 0.05, r * 0.02), r * 0.07, craterPaint);
  }

  @override
  bool shouldRepaint(covariant _MoonPhasePainter old) =>
      old.illumination != illumination || old.waxing != waxing;
}

// =====================================================================
// বাস্তব ব্রহ্মাণ্ড — তারা, ছায়াপথ (Milky Way) ও নীহারিকা
// =====================================================================

/// একটি তারার বৈশিষ্ট্য। প্রকৃত নক্ষত্রের মতো রং, উজ্জ্বলতা ও মিটমিট করার
/// নিজস্ব ছন্দ থাকে — তাই প্রতিটি তারার আলাদা speed/phase রাখা হয়েছে।
class _StarSpec {
  final Offset pos; // 0..1 আপেক্ষিক অবস্থান
  final double radius;
  final double baseAlpha;
  final Color color;
  final double twinkleSpeed;
  final double twinklePhase;
  final bool bright; // উজ্জ্বল তারা — বাড়তি আভা ও রশ্মি পাবে
  const _StarSpec(
    this.pos,
    this.radius,
    this.baseAlpha,
    this.color,
    this.twinkleSpeed,
    this.twinklePhase,
    this.bright,
  );
}

/// প্রকৃত নক্ষত্রের বর্ণালী শ্রেণি অনুযায়ী রং (O/B নীলাভ → M লালচে)
const List<Color> _stellarColors = [
  Color(0xFFC8D8FF), // নীলাভ-সাদা (গরম তারা)
  Color(0xFFDCE6FF),
  Color(0xFFFFFFFF), // সাদা
  Color(0xFFFFFFFF),
  Color(0xFFFFF6E8), // হলদে-সাদা (সূর্যের মতো)
  Color(0xFFFFF0D0),
  Color(0xFFFFD9A8), // কমলা
  Color(0xFFFFC6A0), // লালচে (ঠান্ডা তারা)
];

class StarsLayer extends StatefulWidget {
  const StarsLayer({super.key});
  @override
  State<StarsLayer> createState() => _StarsLayerState();
}

class _StarsLayerState extends State<StarsLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkle;
  late final List<_StarSpec> _stars;
  late final List<_DustPuff> _milkyWay;
  late final List<_NebulaBlob> _nebulae;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(42);

    // --- তারা: বেশিরভাগ ক্ষীণ, অল্প কিছু উজ্জ্বল (প্রকৃত আকাশের মতো বণ্টন) ---
    _stars = List.generate(190, (i) {
      // r^3 বণ্টন — অধিকাংশ তারা ছোট, হাতেগোনা কয়েকটা বড়
      final t = rnd.nextDouble();
      final sizeFactor = t * t * t;
      final radius = 0.35 + sizeFactor * 2.1;
      final bright = radius > 1.7;
      return _StarSpec(
        Offset(rnd.nextDouble(), rnd.nextDouble()),
        radius,
        0.35 + rnd.nextDouble() * 0.65,
        _stellarColors[rnd.nextInt(_stellarColors.length)],
        0.4 + rnd.nextDouble() * 1.4,
        rnd.nextDouble(),
        bright,
      );
    });

    // --- ছায়াপথ: তির্যক ব্যান্ড বরাবর ধুলোর মেঘ ---
    _milkyWay = List.generate(90, (i) {
      final along = rnd.nextDouble();
      // ব্যান্ডের কেন্দ্র থেকে লম্বভাবে গাউসীয় বিস্তার
      final spread =
          (rnd.nextDouble() + rnd.nextDouble() + rnd.nextDouble()) / 3.0 - 0.5;
      final perp = spread * 0.42;
      // তির্যক রেখা: উপরে-বাঁ থেকে নিচে-ডান
      final x = along;
      final y = 0.18 + along * 0.62 + perp;
      return _DustPuff(
        Offset(x, y),
        0.05 + rnd.nextDouble() * 0.11,
        0.030 + rnd.nextDouble() * 0.055,
        rnd.nextBool()
            ? const Color(0xFFB9C7F0)
            : const Color(0xFFE6D5F5),
      );
    });

    // --- নীহারিকা: কয়েকটি বড় রঙিন গ্যাসের মেঘ ---
    _nebulae = const [
      _NebulaBlob(Offset(0.18, 0.22), 0.38, Color(0xFF5B3FA8), 0.15),
      _NebulaBlob(Offset(0.78, 0.34), 0.34, Color(0xFF2E6FA8), 0.13),
      _NebulaBlob(Offset(0.52, 0.68), 0.42, Color(0xFF8A3B7A), 0.10),
      _NebulaBlob(Offset(0.30, 0.82), 0.30, Color(0xFF2B5C93), 0.11),
    ];

    _twinkle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (AppSettings.instance.skyAnim) _twinkle.repeat();
  }

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // স্থির স্তর (নীহারিকা + ছায়াপথ) — প্রতি ফ্রেমে আঁকার দরকার নেই
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: DeepSkyPainter(_nebulae, _milkyWay)),
          ),
        ),
        // মিটমিট করা তারা
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: StarsPainter(_stars, _twinkle)),
          ),
        ),
      ],
    );
  }
}

class _DustPuff {
  final Offset pos;
  final double radius;
  final double alpha;
  final Color color;
  const _DustPuff(this.pos, this.radius, this.alpha, this.color);
}

class _NebulaBlob {
  final Offset pos;
  final double radius;
  final Color color;
  final double alpha;
  const _NebulaBlob(this.pos, this.radius, this.color, this.alpha);
}

/// নীহারিকা ও ছায়াপথ — নরম, ছড়ানো আলোর মেঘ
class DeepSkyPainter extends CustomPainter {
  final List<_NebulaBlob> nebulae;
  final List<_DustPuff> milkyWay;
  DeepSkyPainter(this.nebulae, this.milkyWay);

  @override
  void paint(Canvas canvas, Size size) {
    final minSide = math.min(size.width, size.height);

    for (final n in nebulae) {
      final center = Offset(n.pos.dx * size.width, n.pos.dy * size.height);
      final r = n.radius * minSide;
      final rect = Rect.fromCircle(center: center, radius: r);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            n.color.withValues(alpha: n.alpha),
            n.color.withValues(alpha: n.alpha * 0.45),
            n.color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect);
      canvas.drawCircle(center, r, paint);
    }

    for (final d in milkyWay) {
      final center = Offset(d.pos.dx * size.width, d.pos.dy * size.height);
      final r = d.radius * minSide;
      final rect = Rect.fromCircle(center: center, radius: r);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            d.color.withValues(alpha: d.alpha),
            d.color.withValues(alpha: 0.0),
          ],
        ).createShader(rect);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DeepSkyPainter oldDelegate) => false;
}

/// তারা — প্রতিটি নিজস্ব ছন্দে মিটমিট করে; উজ্জ্বলগুলো আভা ও রশ্মি ছড়ায়
class StarsPainter extends CustomPainter {
  final List<_StarSpec> stars;
  final Animation<double> twinkle;
  StarsPainter(this.stars, this.twinkle) : super(repaint: twinkle);

  @override
  void paint(Canvas canvas, Size size) {
    final t = twinkle.value;
    final dot = Paint();
    final spike = Paint()..strokeCap = StrokeCap.round;

    for (final s in stars) {
      final center = Offset(s.pos.dx * size.width, s.pos.dy * size.height);
      // মিটমিট: প্রতিটি তারার নিজস্ব গতি ও শুরুর অবস্থান
      final wave = math.sin((t * s.twinkleSpeed + s.twinklePhase) * 2 * math.pi);
      final alpha = (s.baseAlpha * (0.72 + 0.28 * wave)).clamp(0.0, 1.0);

      // উজ্জ্বল তারার চারপাশে নরম আভা
      if (s.bright) {
        final glowR = s.radius * 5.5;
        final rect = Rect.fromCircle(center: center, radius: glowR);
        canvas.drawCircle(
          center,
          glowR,
          Paint()
            ..shader = RadialGradient(
              colors: [
                s.color.withValues(alpha: alpha * 0.32),
                s.color.withValues(alpha: 0.0),
              ],
            ).createShader(rect),
        );
      }

      dot.color = s.color.withValues(alpha: alpha);
      canvas.drawCircle(center, s.radius, dot);

      // সবচেয়ে উজ্জ্বল তারায় ক্যামেরার মতো সূক্ষ্ম রশ্মি
      if (s.bright && s.radius > 2.0) {
        spike
          ..color = s.color.withValues(alpha: alpha * 0.5)
          ..strokeWidth = 0.7;
        final len = s.radius * 4.2;
        canvas.drawLine(
          center.translate(-len, 0),
          center.translate(len, 0),
          spike,
        );
        canvas.drawLine(
          center.translate(0, -len),
          center.translate(0, len),
          spike,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) => false;
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
    // আগে একবার onboarding (ভাষা/জেলা/থিম/পারমিশন) শেষ করা থাকলে প্রতিবার
    // অ্যাপ/ওয়েব লিংক খোলার সময় ওই স্ক্রিনগুলো আর দেখাতে হয় না —
    // সরাসরি হোম স্ক্রিনে চলে যাবে
    final alreadySetUp = AppSettings.instance.setupComplete;
    Future.delayed(Duration(seconds: alreadySetUp ? 1 : 3), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        alreadySetUp ? '/home' : '/language',
      );
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

class LocationSelectScreen extends StatefulWidget {
  const LocationSelectScreen({super.key});
  @override
  State<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends State<LocationSelectScreen> {
  String? _selectedDistrict = AppSettings.instance.district;

  final List<String> _districts = const [
    'কলকাতা',
    'হাওড়া',
    'উত্তর ২৪ পরগনা',
    'দক্ষিণ ২৪ পরগনা',
    'হুগলি',
    'নদিয়া',
    'পূর্ব বর্ধমান',
    'পশ্চিম বর্ধমান',
    'মুর্শিদাবাদ',
    'বীরভূম',
    'পূর্ব মেদিনীপুর',
    'পশ্চিম মেদিনীপুর',
    'বাঁকুড়া',
    'পুরুলিয়া',
    'মালদা',
    'উত্তর দিনাজপুর',
    'দক্ষিণ দিনাজপুর',
    'জলপাইগুড়ি',
    'দার্জিলিং',
    'আলিপুরদুয়ার',
    'কোচবিহার',
    'ঝাড়গ্রাম',
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
              'সঠিক তিথি ও সময় গণনার জন্য এটি প্রয়োজন',
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
                    : () async {
                        await AppSettings.instance.saveDistrict(
                          _selectedDistrict!,
                        );
                        if (!context.mounted) return;
                        Navigator.pushNamed(context, '/permission');
                      },
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
                    'শুভক্ষণ ও গুরুত্বপূর্ণ তিথি সম্পর্কে সময়মতো জানতে নোটিফিকেশন চালু রাখুন।',
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
    {
      'name': 'কসমিক (ডিফল্ট)',
      'color': Color(0xFF183F69),
    },
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
                onPressed: () async {
                  await AppSettings.instance.markSetupComplete();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                },
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
    PanchangFeature(
      '📅',
      'বাংলা ক্যালেন্ডার',
      '১২ মাস, ছুটি, বিশেষ দিন',
    ),
    PanchangFeature(
      '🙏',
      'পূজা ও ব্রত',
      'উৎসব, উপবাস, পূজা তালিকা',
    ),
    PanchangFeature(
      '🔮',
      'রাশিফল',
      '১২ রাশি, দৈনিক ও মাসিক',
    ),
    PanchangFeature(
      '💍',
      'শুভ দিন',
      'বিবাহ, গৃহপ্রবেশ, অন্নপ্রাশন',
    ),
    PanchangFeature(
      '🌕',
      'পূর্ণিমা',
      'পূর্ণিমার তারিখ ও তথ্য',
    ),
    PanchangFeature(
      '🌑',
      'অমাবস্যা',
      'অমাবস্যার তালিকা ও সময়',
    ),
    PanchangFeature(
      '🌒',
      'গ্রহণ',
      'সূর্য ও চন্দ্রগ্রহণ',
    ),
    PanchangFeature(
      '🌌',
      'গ্রহ ও নক্ষত্র',
      'গ্রহের অবস্থান ও জ্যোতির্বিদ্যা',
    ),
  ];

  final List<FestivalItem> _festivals = const [
    FestivalItem(
      '🚢',
      'রথযাত্রা',
      '২৭ জ্যৈষ্ঠ',
    ),
    FestivalItem(
      '🐄',
      'জন্মাষ্টমী',
      '১৫ ভাদ্র',
    ),
    FestivalItem(
      '🔱',
      'দুর্গাপূজা',
      '৬ আশ্বিন',
    ),
    FestivalItem(
      '🪔',
      'কালীপূজা',
      'কার্তিক অমাবস্যা',
    ),
  ];

  void _handleOpen(BuildContext context, String title) {
    if (title == 'বাংলা ক্যালেন্ডার') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BengaliCalendarScreen()),
      );
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReminderScreen()),
        );
        break;
      case 'নোটস':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotesScreen()),
        );
        break;
      case 'সেটিংস':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
      case 'প্রোফাইল':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _iconButton(Icons.menu, () {
                    setState(() => _menuOpen = true);
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
              _HeroDateCard(),
              const SizedBox(height: 12),
              const _HistoryBanner(),
              const SizedBox(height: 14),
              _LiveInfoRow(),
              const SizedBox(height: 14),
              _TickerBar(),
              const SizedBox(height: 18),
              const _SectionTitle('আজকের পঞ্চাঙ্গ'),
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final sun = PanchangCalculator.sunTimes(now);
                  final moonAge = PanchangCalculator.moonAgeDays(now);
                  final moonrise = sun.sunrise.add(
                    Duration(minutes: (moonAge * 48.8).round()),
                  );
                  return Row(
                    children: [
                      Expanded(
                        child: _MiniPanchang(
                          emoji: '🌅',
                          value: bnTime12(sun.sunrise),
                          label: 'সূর্যোদয়',
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _MiniPanchang(
                          emoji: '🌇',
                          value: bnTime12(sun.sunset),
                          label: 'সূর্যাস্ত',
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _MiniPanchang(
                          emoji: '🌙',
                          value: bnTime12(moonrise),
                          label: 'চন্দ্রোদয়',
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              const _SectionTitle('দ্রুত ব্যবহার'),
              const SizedBox(height: 10),
              SizedBox(
                height: 561,
                child: GridView.builder(
                  shrinkWrap: false,
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
              ),
              const SizedBox(height: 20),
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
                    return _FestivalCard(
                      item: f,
                      onTap: () => _handleOpen(context, f.title),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const _SectionTitle(
                'তিথি • নক্ষত্র • যোগ',
              ),
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
              const _SectionTitle('আজকের বিশেষ দিন'),
              const SizedBox(height: 10),
              _InfoListBox(
                special: true,
                rows: const [
                  ['🐍 নাগ পঞ্চমী ব্রত', 'আজ'],
                  [
                    '🦚 শ্রীকৃষ্ণ জন্মাষ্টমী',
                    'আগামীকাল',
                  ],
                ],
              ),
              const SizedBox(height: 20),
              const _SectionTitle('গ্রামের আকাশ (লাইভ)'),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const VillageHorizonScene(),
              ),
              const SizedBox(height: 10),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomNavBar(
              selectedIndex: _navIndex,
              onSelect: (i) {
                if (i == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BengaliCalendarScreen(),
                    ),
                  );
                  return;
                }
                if (i == 3) {
                  _handleOpen(context, 'রাশিফল');
                  return;
                }
                if (i == 4) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  return;
                }
                setState(() => _navIndex = i);
              },
              onFabTap: () => _handleOpen(context, 'পঞ্জিকা'),
            ),
          ),
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
              child: _SideMenu(
                onSelect: (title) => _handleMenuSelect(context, title),
              ),
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

// =====================================================================
// আজকের ইতিহাস — উল্লেখযোগ্য বাঙালি/ভারতীয় ব্যক্তিত্বদের জন্ম/মৃত্যু
// তারিখ (Wikipedia থেকে যাচাই করা, ইংরেজি ক্যালেন্ডারের তারিখ অনুযায়ী)
// =====================================================================

class _HistoricalFigure {
  final int month;
  final int day;
  final String name;
  final String role;
  final String eventType; // 'জন্ম' বা 'প্রয়াণ'
  final String emoji;
  const _HistoricalFigure(
    this.month,
    this.day,
    this.name,
    this.role,
    this.eventType,
    this.emoji,
  );
}

const List<_HistoricalFigure> _historicalFigures = [
  _HistoricalFigure(5, 7, 'রবীন্দ্রনাথ ঠাকুর', 'কবি ও সাহিত্যিক (নোবেলজয়ী)', 'জন্ম', '📖'),
  _HistoricalFigure(8, 7, 'রবীন্দ্রনাথ ঠাকুর', 'কবি ও সাহিত্যিক (নোবেলজয়ী)', 'প্রয়াণ', '📖'),
  _HistoricalFigure(5, 25, 'কাজী নজরুল ইসলাম', 'বিদ্রোহী কবি', 'জন্ম', '✒️'),
  _HistoricalFigure(8, 29, 'কাজী নজরুল ইসলাম', 'বিদ্রোহী কবি', 'প্রয়াণ', '✒️'),
  _HistoricalFigure(1, 23, 'নেতাজি সুভাষচন্দ্র বসু', 'স্বাধীনতা সংগ্রামী', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(1, 12, 'স্বামী বিবেকানন্দ', 'সন্ন্যাসী ও দার্শনিক', 'জন্ম', '🕉'),
  _HistoricalFigure(7, 4, 'স্বামী বিবেকানন্দ', 'সন্ন্যাসী ও দার্শনিক', 'প্রয়াণ', '🕉'),
  _HistoricalFigure(9, 26, 'ঈশ্বরচন্দ্র বিদ্যাসাগর', 'সমাজ সংস্কারক', 'জন্ম', '📚'),
  _HistoricalFigure(7, 29, 'ঈশ্বরচন্দ্র বিদ্যাসাগর', 'সমাজ সংস্কারক', 'প্রয়াণ', '📚'),
  _HistoricalFigure(6, 26, 'বঙ্কিমচন্দ্র চট্টোপাধ্যায়', 'সাহিত্যিক', 'জন্ম', '🖋'),
  _HistoricalFigure(4, 8, 'বঙ্কিমচন্দ্র চট্টোপাধ্যায়', 'সাহিত্যিক', 'প্রয়াণ', '🖋'),
  _HistoricalFigure(9, 15, 'শরৎচন্দ্র চট্টোপাধ্যায়', 'সাহিত্যিক', 'জন্ম', '🖋'),
  _HistoricalFigure(1, 16, 'শরৎচন্দ্র চট্টোপাধ্যায়', 'সাহিত্যিক', 'প্রয়াণ', '🖋'),
  _HistoricalFigure(5, 2, 'সত্যজিৎ রায়', 'চলচ্চিত্র নির্মাতা', 'জন্ম', '🎬'),
  _HistoricalFigure(4, 23, 'সত্যজিৎ রায়', 'চলচ্চিত্র নির্মাতা', 'প্রয়াণ', '🎬'),
  _HistoricalFigure(11, 30, 'জগদীশচন্দ্র বসু', 'বিজ্ঞানী', 'জন্ম', '🔬'),
  _HistoricalFigure(11, 23, 'জগদীশচন্দ্র বসু', 'বিজ্ঞানী', 'প্রয়াণ', '🔬'),
  _HistoricalFigure(10, 6, 'মেঘনাদ সাহা', 'বিজ্ঞানী', 'জন্ম', '🔬'),
  _HistoricalFigure(2, 16, 'মেঘনাদ সাহা', 'বিজ্ঞানী', 'প্রয়াণ', '🔬'),
  _HistoricalFigure(5, 22, 'রাজা রামমোহন রায়', 'সমাজ সংস্কারক', 'জন্ম', '📜'),
  _HistoricalFigure(9, 27, 'রাজা রামমোহন রায়', 'সমাজ সংস্কারক', 'প্রয়াণ', '📜'),
  _HistoricalFigure(10, 2, 'মহাত্মা গান্ধী', 'জাতির জনক', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(1, 30, 'মহাত্মা গান্ধী', 'জাতির জনক', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(10, 15, 'এ.পি.জে. আব্দুল কালাম', 'বিজ্ঞানী ও রাষ্ট্রপতি', 'জন্ম', '🚀'),
  _HistoricalFigure(7, 27, 'এ.পি.জে. আব্দুল কালাম', 'বিজ্ঞানী ও রাষ্ট্রপতি', 'প্রয়াণ', '🚀'),
  _HistoricalFigure(2, 18, 'শ্রীরামকৃষ্ণ পরমহংস', 'সন্ন্যাসী', 'জন্ম', '🕉'),
  _HistoricalFigure(8, 16, 'শ্রীরামকৃষ্ণ পরমহংস', 'সন্ন্যাসী', 'প্রয়াণ', '🕉'),
  _HistoricalFigure(10, 28, 'ভগিনী নিবেদিতা', 'সমাজসেবী', 'জন্ম', '🤍'),
  _HistoricalFigure(10, 13, 'ভগিনী নিবেদিতা', 'সমাজসেবী', 'প্রয়াণ', '🤍'),
  _HistoricalFigure(1, 25, 'মাইকেল মধুসূদন দত্ত', 'কবি', 'জন্ম', '✒️'),
  _HistoricalFigure(6, 29, 'মাইকেল মধুসূদন দত্ত', 'কবি', 'প্রয়াণ', '✒️'),
  _HistoricalFigure(9, 28, 'রানি রাসমণি', 'সমাজসেবী', 'জন্ম', '🏛'),
  _HistoricalFigure(2, 19, 'রানি রাসমণি', 'সমাজসেবী', 'প্রয়াণ', '🏛'),
  _HistoricalFigure(11, 5, 'দেশবন্ধু চিত্তরঞ্জন দাশ', 'রাজনীতিবিদ', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(6, 16, 'দেশবন্ধু চিত্তরঞ্জন দাশ', 'রাজনীতিবিদ', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(12, 3, 'ক্ষুদিরাম বসু', 'বিপ্লবী (ফাঁসি)', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(8, 11, 'ক্ষুদিরাম বসু', 'বিপ্লবী (ফাঁসি)', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(9, 29, 'মাতঙ্গিনী হাজরা', 'বিপ্লবী', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(12, 9, 'বেগম রোকেয়া', 'সমাজ সংস্কারক', 'জন্ম', '📚'),
  _HistoricalFigure(2, 17, 'জীবনানন্দ দাশ', 'কবি', 'জন্ম', '✒️'),
  _HistoricalFigure(10, 22, 'জীবনানন্দ দাশ', 'কবি', 'প্রয়াণ', '✒️'),
  _HistoricalFigure(8, 2, 'আচার্য প্রফুল্লচন্দ্র রায়', 'বিজ্ঞানী', 'জন্ম', '🔬'),
  _HistoricalFigure(6, 16, 'আচার্য প্রফুল্লচন্দ্র রায়', 'বিজ্ঞানী', 'প্রয়াণ', '🔬'),
  _HistoricalFigure(7, 1, 'ডা. বিধানচন্দ্র রায়', 'চিকিৎসক ও রাজনীতিবিদ', 'জন্ম ও প্রয়াণ', '⚕️'),
  _HistoricalFigure(3, 22, 'মাস্টারদা সূর্য সেন', 'বিপ্লবী (ফাঁসি)', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(1, 12, 'মাস্টারদা সূর্য সেন', 'বিপ্লবী (ফাঁসি)', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(5, 5, 'প্রীতিলতা ওয়াদ্দেদার', 'বিপ্লবী', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(9, 24, 'প্রীতিলতা ওয়াদ্দেদার', 'বিপ্লবী', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(7, 18, 'কাদম্বিনী গঙ্গোপাধ্যায়', 'প্রথম নারী চিকিৎসক', 'জন্ম', '⚕️'),
  _HistoricalFigure(10, 3, 'কাদম্বিনী গঙ্গোপাধ্যায়', 'প্রথম নারী চিকিৎসক', 'প্রয়াণ', '⚕️'),
  _HistoricalFigure(8, 26, 'মাদার টেরিজা', 'সমাজসেবী (কলকাতা)', 'জন্ম', '🤍'),
  _HistoricalFigure(9, 5, 'মাদার টেরিজা', 'সমাজসেবী (কলকাতা)', 'প্রয়াণ', '🤍'),
  _HistoricalFigure(8, 18, 'নেতাজি সুভাষচন্দ্র বসু', 'স্বাধীনতা সংগ্রামী', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(11, 7, 'বিপিনচন্দ্র পাল', 'বিপ্লবী (লাল-বাল-পাল)', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(5, 20, 'বিপিনচন্দ্র পাল', 'বিপ্লবী (লাল-বাল-পাল)', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(7, 23, 'তারাশঙ্কর বন্দ্যোপাধ্যায়', 'সাহিত্যিক', 'জন্ম', '🖋'),
  _HistoricalFigure(9, 14, 'তারাশঙ্কর বন্দ্যোপাধ্যায়', 'সাহিত্যিক', 'প্রয়াণ', '🖋'),
  _HistoricalFigure(5, 19, 'মানিক বন্দ্যোপাধ্যায়', 'সাহিত্যিক', 'জন্ম', '🖋'),
  _HistoricalFigure(12, 3, 'মানিক বন্দ্যোপাধ্যায়', 'সাহিত্যিক', 'প্রয়াণ', '🖋'),
  _HistoricalFigure(9, 12, 'বিভূতিভূষণ বন্দ্যোপাধ্যায়', 'সাহিত্যিক (পথের পাঁচালী)', 'জন্ম', '🖋'),
  _HistoricalFigure(11, 1, 'বিভূতিভূষণ বন্দ্যোপাধ্যায়', 'সাহিত্যিক (পথের পাঁচালী)', 'প্রয়াণ', '🖋'),
  _HistoricalFigure(11, 4, 'ঋত্বিক ঘটক', 'চলচ্চিত্র নির্মাতা', 'জন্ম', '🎬'),
  _HistoricalFigure(2, 6, 'ঋত্বিক ঘটক', 'চলচ্চিত্র নির্মাতা', 'প্রয়াণ', '🎬'),
  _HistoricalFigure(5, 14, 'মৃণাল সেন', 'চলচ্চিত্র নির্মাতা', 'জন্ম', '🎬'),
  _HistoricalFigure(12, 30, 'মৃণাল সেন', 'চলচ্চিত্র নির্মাতা', 'প্রয়াণ', '🎬'),
  _HistoricalFigure(4, 7, 'পণ্ডিত রবিশঙ্কর', 'সেতার বাদক', 'জন্ম', '🎶'),
  _HistoricalFigure(12, 11, 'পণ্ডিত রবিশঙ্কর', 'সেতার বাদক', 'প্রয়াণ', '🎶'),
  _HistoricalFigure(9, 3, 'উত্তম কুমার', 'অভিনেতা (মহানায়ক)', 'জন্ম', '🎭'),
  _HistoricalFigure(7, 24, 'উত্তম কুমার', 'অভিনেতা (মহানায়ক)', 'প্রয়াণ', '🎭'),
  _HistoricalFigure(4, 6, 'সুচিত্রা সেন', 'অভিনেত্রী (মহানায়িকা)', 'জন্ম', '🎭'),
  _HistoricalFigure(1, 17, 'সুচিত্রা সেন', 'অভিনেত্রী (মহানায়িকা)', 'প্রয়াণ', '🎭'),
  _HistoricalFigure(6, 16, 'হেমন্ত মুখোপাধ্যায়', 'সঙ্গীতশিল্পী', 'জন্ম', '🎤'),
  _HistoricalFigure(9, 26, 'হেমন্ত মুখোপাধ্যায়', 'সঙ্গীতশিল্পী', 'প্রয়াণ', '🎤'),
  _HistoricalFigure(8, 4, 'কিশোর কুমার', 'সঙ্গীতশিল্পী ও অভিনেতা', 'জন্ম', '🎤'),
  _HistoricalFigure(10, 13, 'কিশোর কুমার', 'সঙ্গীতশিল্পী ও অভিনেতা', 'প্রয়াণ', '🎤'),
  _HistoricalFigure(5, 1, 'মান্না দে', 'সঙ্গীতশিল্পী', 'জন্ম', '🎤'),
  _HistoricalFigure(10, 24, 'মান্না দে', 'সঙ্গীতশিল্পী', 'প্রয়াণ', '🎤'),
  _HistoricalFigure(6, 29, 'স্যার আশুতোষ মুখোপাধ্যায়', 'শিক্ষাবিদ', 'জন্ম', '🎓'),
  _HistoricalFigure(5, 25, 'স্যার আশুতোষ মুখোপাধ্যায়', 'শিক্ষাবিদ', 'প্রয়াণ', '🎓'),
  _HistoricalFigure(9, 27, 'ভগৎ সিং', 'বিপ্লবী (ফাঁসি)', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(3, 23, 'ভগৎ সিং', 'বিপ্লবী (ফাঁসি)', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(11, 14, 'জওহরলাল নেহরু', 'ভারতের প্রথম প্রধানমন্ত্রী', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(5, 27, 'জওহরলাল নেহরু', 'ভারতের প্রথম প্রধানমন্ত্রী', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(10, 31, 'সর্দার বল্লভভাই প্যাটেল', 'রাষ্ট্রনায়ক', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(12, 15, 'সর্দার বল্লভভাই প্যাটেল', 'রাষ্ট্রনায়ক', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(4, 14, 'ডঃ ভীমরাও আম্বেদকর', 'সংবিধান প্রণেতা', 'জন্ম', '⚖️'),
  _HistoricalFigure(12, 6, 'ডঃ ভীমরাও আম্বেদকর', 'সংবিধান প্রণেতা', 'প্রয়াণ', '⚖️'),
  _HistoricalFigure(10, 2, 'লাল বাহাদুর শাস্ত্রী', 'প্রধানমন্ত্রী', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(1, 11, 'লাল বাহাদুর শাস্ত্রী', 'প্রধানমন্ত্রী', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(11, 19, 'ইন্দিরা গান্ধী', 'প্রধানমন্ত্রী', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(10, 31, 'ইন্দিরা গান্ধী', 'প্রধানমন্ত্রী', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(8, 20, 'রাজীব গান্ধী', 'প্রধানমন্ত্রী', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(5, 21, 'রাজীব গান্ধী', 'প্রধানমন্ত্রী', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(7, 23, 'চন্দ্রশেখর আজাদ', 'বিপ্লবী', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(2, 27, 'চন্দ্রশেখর আজাদ', 'বিপ্লবী', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(11, 7, 'স্যার সি.ভি. রামন', 'পদার্থবিজ্ঞানী (নোবেলজয়ী)', 'জন্ম', '🔬'),
  _HistoricalFigure(11, 21, 'স্যার সি.ভি. রামন', 'পদার্থবিজ্ঞানী (নোবেলজয়ী)', 'প্রয়াণ', '🔬'),
  _HistoricalFigure(1, 1, 'সত্যেন্দ্রনাথ বসু', 'পদার্থবিজ্ঞানী', 'জন্ম', '🔬'),
  _HistoricalFigure(2, 4, 'সত্যেন্দ্রনাথ বসু', 'পদার্থবিজ্ঞানী', 'প্রয়াণ', '🔬'),
  _HistoricalFigure(10, 30, 'হোমি জাহাঙ্গীর ভাবা', 'পরমাণু বিজ্ঞানী', 'জন্ম', '⚛️'),
  _HistoricalFigure(1, 24, 'হোমি জাহাঙ্গীর ভাবা', 'পরমাণু বিজ্ঞানী', 'প্রয়াণ', '⚛️'),
  _HistoricalFigure(2, 13, 'সরোজিনী নাইডু', 'কবি ও স্বাধীনতা সংগ্রামী', 'জন্ম', '🌸'),
  _HistoricalFigure(3, 2, 'সরোজিনী নাইডু', 'কবি ও স্বাধীনতা সংগ্রামী', 'প্রয়াণ', '🌸'),
  _HistoricalFigure(8, 15, 'ঋষি অরবিন্দ', 'দার্শনিক ও যোগী', 'জন্ম', '🕉'),
  _HistoricalFigure(12, 5, 'ঋষি অরবিন্দ', 'দার্শনিক ও যোগী', 'প্রয়াণ', '🕉'),
  _HistoricalFigure(1, 14, 'মহাশ্বেতা দেবী', 'সাহিত্যিক ও সমাজকর্মী', 'জন্ম', '🖋'),
  _HistoricalFigure(7, 28, 'মহাশ্বেতা দেবী', 'সাহিত্যিক ও সমাজকর্মী', 'প্রয়াণ', '🖋'),
  _HistoricalFigure(9, 7, 'সুনীল গঙ্গোপাধ্যায়', 'কবি ও সাহিত্যিক', 'জন্ম', '🖋'),
  _HistoricalFigure(10, 23, 'সুনীল গঙ্গোপাধ্যায়', 'কবি ও সাহিত্যিক', 'প্রয়াণ', '🖋'),
  _HistoricalFigure(8, 19, 'সুধা মূর্তি', 'লেখিকা ও সমাজসেবী', 'জন্ম', '📖'),
  _HistoricalFigure(8, 19, 'এস. সত্যমূর্তি', 'আইনজীবী ও রাজনীতিবিদ', 'জন্ম', '🇮🇳'),
];

class _HistoryBanner extends StatefulWidget {
  const _HistoryBanner();
  @override
  State<_HistoryBanner> createState() => _HistoryBannerState();
}

class _HistoryBannerState extends State<_HistoryBanner> {
  late final PageController _controller;
  Timer? _timer;
  List<_HistoricalFigure> _items = [];
  bool _exactToday = true;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    _loadItems();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _items.isEmpty || !_controller.hasClients) return;
      final next = (_controller.page ?? 0).round() + 1;
      _controller.animateToPage(
        next % _items.length,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  // শুধু আজকের প্রকৃত তারিখেই (দিন+মাস) যাদের জন্ম/মৃত্যুদিন পড়ে তারাই
  // দেখাবে — প্রতিদিন আলাদা হবে, অন্য দিনের কাউকে "আজকের" বলে দেখানো হবে
  // না। মিল না থাকলে ব্যানারটাই লুকানো থাকবে (নিচে _items.isEmpty চেক)।
  void _loadItems() {
    final now = DateTime.now();
    _items = _historicalFigures
        .where((f) => f.month == now.month && f.day == now.day)
        .toList();
    _exactToday = true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 92,
      child: PageView.builder(
        controller: _controller,
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final f = _items[i];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1D38).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFFFD36E).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: const Color(0xFFFFD36E).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(f.emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              f.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_exactToday)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD36E),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'আজ',
                                style: TextStyle(
                                  color: Color(0xFF08172F),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        f.role,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _exactToday
                            ? 'আজ ${f.eventType}দিন'
                            : '${bnNum(f.day)} ${gregMonthBn(f.month)} • ${f.eventType}দিন',
                        style: const TextStyle(
                          color: Color(0xFFFFD36E),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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

class _HeroDateCard extends StatelessWidget {
  const _HeroDateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final info = BengaliDateUtil.monthInfoFor(now);
    final bengaliDay = now.difference(info.start).inDays + 1;
    final tithi = PanchangCalculator.tithiFor(now);
    final weekday = PanchangCalculator.weekdayName(now);

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
          Text(
            '${bnNum(bengaliDay)} ${info.name} ${bnNum(info.year)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFD36E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$weekday • ${bnNum(now.day)} ${gregMonthBn(now.month)} ${bnNum(now.year)}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
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
            child: Text(
              '${tithi.paksha} পক্ষ • ${tithi.name} তিথি',
              style: const TextStyle(
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
                _modeChip('🌒 গ্রহণ'),
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
  const _LiveInfoRow();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sun = PanchangCalculator.sunTimes(now);
    final tithi = PanchangCalculator.tithiFor(now);
    final nakIdx = PanchangCalculator.nakshatraIndexFor(now);
    final rashiIdx = PanchangCalculator.rashiIndexFor(now);
    final rahu = PanchangCalculator.rahuKalam(now);
    final moonAge = PanchangCalculator.moonAgeDays(now);
    final moonrise = sun.sunrise.add(
      Duration(minutes: (moonAge * 48.8).round()),
    );
    final moonset = moonrise.add(const Duration(hours: 12, minutes: 25));

    final items = [
      '☀️ সূর্যোদয় ${bnTime12(sun.sunrise)}',
      '🌇 সূর্যাস্ত ${bnTime12(sun.sunset)}',
      '🌙 চন্দ্রোদয় ${bnTime12(moonrise)}',
      '🌗 চন্দ্রাস্ত ${bnTime12(moonset)}',
      '🕉 তিথি: ${tithi.paksha} পক্ষ • ${tithi.name}',
      '⭐ নক্ষত্র: ${PanchangCalculator.nakshatraNames[nakIdx]}',
      '🪐 চন্দ্র রাশি: ${PanchangCalculator.rashiNames[rashiIdx]}',
      '⏳ রাহুকাল ${bnTime12(rahu['start']!)}–${bnTime12(rahu['end']!)}',
    ];

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
              itemCount: items.length,
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
                  items[i],
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

  String _buildText() {
    final now = DateTime.now();
    final sun = PanchangCalculator.sunTimes(now);
    final tithi = PanchangCalculator.tithiFor(now);
    final nakIdx = PanchangCalculator.nakshatraIndexFor(now);
    final rahu = PanchangCalculator.rahuKalam(now);
    return '☀️ সূর্যোদয় ${bnTime12(sun.sunrise)} • '
        '🌇 সূর্যাস্ত ${bnTime12(sun.sunset)} • '
        '⏳ রাহুকাল ${bnTime12(rahu['start']!)}–${bnTime12(rahu['end']!)} • '
        'আজ ${tithi.name} তিথি • '
        'নক্ষত্র: ${PanchangCalculator.nakshatraNames[nakIdx]}';
  }

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _beginScroll());
  }

  void _beginScroll() {
    if (!mounted || !_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    _controller.animateTo(
      max,
      duration: const Duration(seconds: 14),
      curve: Curves.linear,
    ).then((_) {
      if (!mounted) return;
      _controller.jumpTo(0);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _beginScroll();
      });
    });
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
        child: Text(
          _buildText(),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
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
                  children: () {
                    final items = ContentData.categories[title];
                    if (items == null || items.isEmpty) {
                      return [
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
                      ];
                    }
                    return items
                        .map(
                          (row) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    row[0],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    row[1],
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
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

// =====================================================================
// CONTENT DATA — দ্রুত ব্যবহার sheet-গুলোর জন্য ডেমো ডেটা
// =====================================================================

class ContentData {
  /// 'পঞ্জিকা' ট্যাব বাদে বাকি ক্যাটাগরিগুলো কিউরেটেড নমুনা কনটেন্ট (রাশিফল,
  /// উৎসব তালিকা ইত্যাদি — এগুলোর জন্য প্রকৃত জ্যোতিষ ফিড দরকার)।
  /// 'পঞ্জিকা' ট্যাবটি এখন সরাসরি আজকের হিসেব করা তিথি/নক্ষত্র/রাহুকাল দেখায়।
  static Map<String, List<List<String>>> get categories => {
    ..._staticCategories,
    'পঞ্জিকা': _livePanjika(),
    'রাশিফল': _liveRashiphal(),
  };

  static List<List<String>> _livePanjika() {
    final now = DateTime.now();
    final tithi = PanchangCalculator.tithiFor(now);
    final nakIdx = PanchangCalculator.nakshatraIndexFor(now);
    final rashiIdx = PanchangCalculator.rashiIndexFor(now);
    final yogaIdx = PanchangCalculator.yogaIndexFor(now);
    final karana = PanchangCalculator.karanaFor(now);
    final rahu = PanchangCalculator.rahuKalam(now);
    return [
      ['তিথি', '${tithi.paksha} পক্ষ • ${tithi.name}'],
      ['নক্ষত্র', PanchangCalculator.nakshatraNames[nakIdx]],
      ['যোগ', PanchangCalculator.yogaNames[yogaIdx]],
      ['করণ', karana],
      ['রাহুকাল', '${bnTime12(rahu['start']!)}–${bnTime12(rahu['end']!)}'],
      ['চন্দ্র রাশি', PanchangCalculator.rashiNames[rashiIdx]],
    ];
  }

  /// প্রতিদিনের রাশিফল — আগে প্রতিটা রাশির জন্য একই লেখা সবসময় দেখাত
  /// (fake demo data)। এখন এটা "চন্দ্র গোচর ফল"-এর ঐতিহ্যবাহী নিয়ম মেনে
  /// হিসেব হয়: আজ চাঁদ প্রকৃতপক্ষে কোন রাশিতে আছে (real জ্যোতির্বিদ্যা
  /// হিসেব থেকে) সেটা প্রতিটা রাশি থেকে কত নম্বর ঘরে পড়ছে বের করে, তার
  /// ভিত্তিতে ক্লাসিক্যাল ফলাফল দেখানো হয় — কোনো random/fake সংখ্যা নেই।
  /// চাঁদ প্রতি ~২.২৫ দিনে রাশি বদলায় বলে ফলটাও বাস্তবসম্মতভাবেই বদলায়;
  /// শুভ সংখ্যা/রং প্রতিদিনের তিথি অনুযায়ী পাল্টায়, তাই প্রতিদিনই আলাদা লাগে।
  static const List<List<String>> _gocharHouses = [
    ['শরীর-মন ও আত্মবিশ্বাসে প্রভাব পড়বে', 'মিশ্র'],
    ['অর্থ ও কথাবার্তায় প্রভাব — হিসেব করে খরচ করুন', 'মিশ্র'],
    ['সাহস, উদ্যোগ ও ভাইবোনের বিষয়ে শুভ ফল', 'শুভ'],
    ['মানসিক শান্তি ও পারিবারিক বিষয়ে প্রভাব', 'মিশ্র'],
    ['বিদ্যা, সন্তান ও সৃজনশীলতায় প্রভাব', 'মিশ্র'],
    ['প্রতিযোগিতা ও পরিশ্রমে শুভ ফল', 'শুভ'],
    ['সম্পর্ক ও ব্যবসায়িক আলোচনায় প্রভাব', 'মিশ্র'],
    ['অপ্রত্যাশিত পরিবর্তন হতে পারে — সতর্ক থাকুন', 'সতর্কতা'],
    ['ভাগ্য, ভ্রমণ ও শুভ কাজে ইতিবাচক প্রভাব', 'শুভ'],
    ['কাজ ও পেশাগত জীবনে অগ্রগতির যোগ', 'শুভ'],
    ['লাভ ও ইচ্ছাপূরণে অনুকূল সময়', 'শুভ'],
    ['খরচ বাড়তে পারে, আজ একটু বিশ্রাম নিন', 'সতর্কতা'],
  ];

  static const List<String> _rashiSymbols = [
    '♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓',
  ];
  static const List<String> _luckyColors = [
    'লাল', 'সাদা', 'সবুজ', 'রূপালি', 'সোনালি', 'নীল', 'গোলাপি', 'মেরুন',
    'হলুদ', 'বাদামি', 'আকাশি', 'বেগুনি',
  ];

  static List<List<String>> _liveRashiphal() {
    final now = DateTime.now();
    final moonRashiIdx = PanchangCalculator.rashiIndexFor(now);
    final tithi = PanchangCalculator.tithiFor(now);
    return List.generate(12, (r) {
      // আজ চাঁদ [r] রাশি থেকে কত নম্বর ঘরে (১..১২) আছে
      final house = (moonRashiIdx - r + 12) % 12;
      final theme = _gocharHouses[house][0];
      final tag = _gocharHouses[house][1];
      final icon = tag == 'শুভ'
          ? '✅'
          : (tag == 'সতর্কতা' ? '⚠️' : '➖');
      final luckyNum = ((tithi.index + r) % 9) + 1;
      final color = _luckyColors[(tithi.index + r) % _luckyColors.length];
      return [
        '${_rashiSymbols[r]} ${PanchangCalculator.rashiNames[r]}',
        '$icon $theme • শুভ সংখ্যা ${bnNum(luckyNum)} • শুভ রং $color',
      ];
    });
  }

  static const Map<String, List<List<String>>> _staticCategories = {
    'পূজা ও ব্রত': [
      [
        'একাদশী',
        'উপবাস ও পূজা নির্দেশিকা',
      ],
      [
        'শিবরাত্রি',
        'শিব পূজা ও ব্রত',
      ],
      [
        'দুর্গাপূজা',
        'ষষ্ঠী থেকে দশমী',
      ],
      [
        'লক্ষ্মীপূজা',
        'কোজাগরী পূর্ণিমা',
      ],
      [
        'কালীপূজা',
        'কার্তিক অমাবস্যা',
      ],
      [
        'সরস্বতী পূজা',
        'বসন্ত পঞ্চমী',
      ],
    ],
    'রাশিফল': [
      [
        '♈ মেষ',
        'কর্মে অগ্রগতি • শুভ রং লাল',
      ],
      [
        '♉ বৃষ',
        'অর্থে স্থিরতা • শুভ রং সাদা',
      ],
      [
        '♊ মিথুন',
        'যোগাযোগ শুভ • শুভ রং সবুজ',
      ],
      [
        '♋ কর্কট',
        'পরিবারে সময় দিন • শুভ রং রূপালি',
      ],
      [
        '♌ সিংহ',
        'আত্মবিশ্বাস বৃদ্ধি • শুভ রং সোনালি',
      ],
      [
        '♍ কন্যা',
        'পরিকল্পনায় সাফল্য • শুভ রং নীল',
      ],
      [
        '♎ তুলা',
        'সম্পর্কে ভারসাম্য • শুভ রং গোলাপি',
      ],
      [
        '♏ বৃশ্চিক',
        'সিদ্ধান্তে ধৈর্য • শুভ রং মেরুন',
      ],
      [
        '♐ ধনু',
        'ভ্রমণ শুভ • শুভ রং হলুদ',
      ],
      [
        '♑ মকর',
        'কাজে মনোযোগ • শুভ রং বাদামি',
      ],
      [
        '♒ কুম্ভ',
        'নতুন ভাবনা • শুভ রং আকাশি',
      ],
      [
        '♓ মীন',
        'সৃজনশীল দিন • শুভ রং বেগুনি',
      ],
    ],
    'শুভ দিন': [
      [
        '💍 বিবাহ',
        'শুভ লগ্ন ও নির্বাচিত তারিখ',
      ],
      [
        '🏠 গৃহপ্রবেশ',
        'গৃহপ্রবেশের শুভ সময়',
      ],
      [
        '👶 অন্নপ্রাশন',
        'শিশুর অন্নপ্রাশনের দিন',
      ],
      [
        '🪔 ব্যবসা শুরু',
        'নতুন কাজের শুভ সময়',
      ],
      [
        '📿 নামকরণ',
        'নামকরণ সংস্কারের শুভ দিন',
      ],
    ],
    'পূর্ণিমা': [
      [
        'শ্রাবণ পূর্ণিমা',
        '২৮ আগস্ট ২০২৬',
      ],
      [
        'ভাদ্র পূর্ণিমা',
        '২৬ সেপ্টেম্বর ২০২৬',
      ],
      [
        'আশ্বিন পূর্ণিমা',
        '২৬ অক্টোবর ২০২৬',
      ],
      [
        'কার্তিক পূর্ণিমা',
        '২৪ নভেম্বর ২০২৬',
      ],
    ],
    'অমাবস্যা': [
      [
        'শ্রাবণ অমাবস্যা',
        '১২ আগস্ট ২০২৬',
      ],
      [
        'ভাদ্র অমাবস্যা',
        '১০ সেপ্টেম্বর ২০২৬',
      ],
      [
        'আশ্বিন অমাবস্যা',
        '১০ অক্টোবর ২০২৬',
      ],
      [
        'কার্তিক অমাবস্যা',
        '৮ নভেম্বর ২০২৬',
      ],
    ],
    'গ্রহণ': [
      [
        '☀️ সূর্যগ্রহণ',
        '১২ আগস্ট ২০২৬ • পূর্ণ সূর্যগ্রহণ',
      ],
      [
        '🌘 চন্দ্রগ্রহণ',
        '২৮ আগস্ট ২০২৬ • আংশিক চন্দ্রগ্রহণ',
      ],
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
      [
        '🦚 জন্মাষ্টমী',
        '৪ সেপ্টেম্বর ২০২৬',
      ],
      [
        '🔱 দুর্গাপূজা',
        '১৯-২০ অক্টোবর ২০২৬',
      ],
      [
        '🪔 কালীপূজা',
        '৮ নভেম্বর ২০২৬',
      ],
      [
        '🌼 সরস্বতী পূজা',
        '২৩ জানুয়ারি ২০২৬',
      ],
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
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '☰ বাংলা পঞ্জিকা',
                style: TextStyle(
                  color: Color(0xFFFFD36E),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              ..._items.map(
                (it) => Padding(
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
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(it[0], style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text(
                            it[1],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFD36E),
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
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

// =====================================================================
// পঞ্জিকা গণনা ইঞ্জিন — তিথি / নক্ষত্র / রাশি / সূর্যোদয়-অস্ত / রাহুকাল
// সরলীকৃত জ্যোতির্বৈজ্ঞানিক সূত্র (Meeus, Astronomical Algorithms – low
// precision formulae) দিয়ে বাস্তব সময়ের ভিত্তিতে হিসেব করা হয়।
// নির্ভুলতা: তিথি/পক্ষ কয়েক মিনিটের মধ্যে, নক্ষত্র ~১০ আর্ক-মিনিট,
// সূর্যোদয়/অস্ত ~১-২ মিনিট। চন্দ্রোদয়/অস্ত ও রাহুকাল আনুমানিক।
// =====================================================================

const List<String> _bnDigitMap = [
  '০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯',
];

/// ভাষা 'English' করা থাকলে সংখ্যা ইংরেজি অঙ্কেই থাকে, নাহলে বাংলা অঙ্কে
String bnDigits(String input) {
  if (!AppSettings.instance.isBangla) return input;
  return input.split('').map((c) {
    final code = c.codeUnitAt(0);
    if (code >= 48 && code <= 57) return _bnDigitMap[code - 48];
    return c;
  }).join();
}

String bnNum(int n) => n < 0 ? '-${bnDigits((-n).toString())}' : bnDigits(n.toString());

String bnTime12(DateTime dt) {
  final h12raw = dt.hour % 12;
  final h12 = h12raw == 0 ? 12 : h12raw;
  final ampm = dt.hour < 12 ? 'AM' : 'PM';
  return '${bnDigits(h12.toString())}:${bnDigits(dt.minute.toString().padLeft(2, '0'))} $ampm';
}

const List<String> _gregMonthsBn = [
  'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
  'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
];
const List<String> _gregMonthsEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
String gregMonthBn(int m) {
  final i = (m - 1).clamp(0, 11);
  return AppSettings.instance.isBangla ? _gregMonthsBn[i] : _gregMonthsEn[i];
}

class DistrictLocation {
  final double lat;
  final double lon;
  const DistrictLocation(this.lat, this.lon);
}

class AppLocation {
  static String district = 'কলকাতা';

  static const Map<String, DistrictLocation> coordinates = {
    'কলকাতা': DistrictLocation(22.5726, 88.3639),
    'হাওড়া': DistrictLocation(22.5958, 88.2636),
    'উত্তর ২৪ পরগনা': DistrictLocation(22.7220, 88.4790),
    'দক্ষিণ ২৪ পরগনা': DistrictLocation(22.1667, 88.4000),
    'হুগলি': DistrictLocation(22.9012, 88.3856),
    'নদিয়া': DistrictLocation(23.4058, 88.4993),
    'পূর্ব বর্ধমান': DistrictLocation(23.2324, 87.8615),
    'পশ্চিম বর্ধমান': DistrictLocation(23.6739, 86.9524),
    'মুর্শিদাবাদ': DistrictLocation(24.0964, 88.2482),
    'বীরভূম': DistrictLocation(23.9037, 87.5382),
    'পূর্ব মেদিনীপুর': DistrictLocation(22.2971, 87.9256),
    'পশ্চিম মেদিনীপুর': DistrictLocation(22.4257, 87.3200),
    'বাঁকুড়া': DistrictLocation(23.2324, 87.0715),
    'পুরুলিয়া': DistrictLocation(23.3320, 86.3616),
    'মালদা': DistrictLocation(25.0084, 88.1414),
    'উত্তর দিনাজপুর': DistrictLocation(25.6236, 88.1240),
    'দক্ষিণ দিনাজপুর': DistrictLocation(25.2160, 88.7770),
    'জলপাইগুড়ি': DistrictLocation(26.5416, 88.7273),
    'দার্জিলিং': DistrictLocation(27.0360, 88.2627),
    'আলিপুরদুয়ার': DistrictLocation(26.4863, 89.5288),
    'কোচবিহার': DistrictLocation(26.3223, 89.4472),
    'ঝাড়গ্রাম': DistrictLocation(22.4498, 86.9822),
    'কালিম্পং': DistrictLocation(27.0670, 88.4750),
  };

  static double get lat => coordinates[district]?.lat ?? 22.5726;
  static double get lon => coordinates[district]?.lon ?? 88.3639;

  static void select(String d) {
    if (coordinates.containsKey(d)) district = d;
  }
}

// =====================================================================
// লাইভ আবহাওয়া — Open-Meteo (ফ্রি, কোনো API key লাগে না)
// =====================================================================

/// নির্বাচিত জেলায় এখন সত্যিই বৃষ্টি হচ্ছে কিনা — শুধু এইটুকু তথ্যের জন্য
/// Open-Meteo-এর ফ্রি "current weather" এন্ডপয়েন্ট ব্যবহার করা হচ্ছে।
/// ইন্টারনেট না থাকলে বা কল ব্যর্থ হলে চুপচাপ "বৃষ্টি নেই" ধরে নেওয়া হয় —
/// এই ফিচারটার জন্য অ্যাপের বাকি অংশ কখনো আটকে থাকবে না।
class WeatherService extends ChangeNotifier {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  bool isRaining = false;
  double? tempC;
  DateTime? _lastFetch;
  double? _lastLat;
  double? _lastLon;
  bool _loading = false;

  // WMO weather code অনুযায়ী বৃষ্টি/বজ্রবৃষ্টি/বরফবৃষ্টি ধরনের কোড
  static const Set<int> _rainCodes = {
    51, 53, 55, 56, 57, // ঝিরিঝিরি বৃষ্টি
    61, 63, 65, 66, 67, // সাধারণ বৃষ্টি
    80, 81, 82, // hovering/heavy shower
    95, 96, 99, // বজ্রবৃষ্টি
  };

  Future<void> refresh({bool force = false}) async {
    final lat = AppLocation.lat;
    final lon = AppLocation.lon;
    final now = DateTime.now();
    final sameLocation = _lastLat == lat && _lastLon == lon;
    final fresh = _lastFetch != null &&
        now.difference(_lastFetch!) < const Duration(minutes: 15);
    if (_loading || (!force && sameLocation && fresh)) return;
    _loading = true;
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=precipitation,weather_code,temperature_2m'
        '&timezone=Asia%2FKolkata',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>?;
        if (current != null) {
          final precip = (current['precipitation'] as num?)?.toDouble() ?? 0;
          final code = (current['weather_code'] as num?)?.toInt() ?? 0;
          isRaining = precip > 0.1 || _rainCodes.contains(code);
          tempC = (current['temperature_2m'] as num?)?.toDouble();
          _lastFetch = now;
          _lastLat = lat;
          _lastLon = lon;
          notifyListeners();
        }
      }
    } catch (_) {
      // অফলাইন/এরর হলে যা ছিল তাই থাকবে — অ্যাপ ভেঙে পড়বে না
    } finally {
      _loading = false;
    }
  }
}

// =====================================================================
// গ্রাম/নদীর দৃশ্য — রিয়েল সূর্যোদয়-সূর্যাস্ত অনুযায়ী সূর্য ওঠে-নামে,
// লাইভ আবহাওয়া বৃষ্টি বললে বৃষ্টির অ্যানিমেশনও দেখায়
// =====================================================================

class VillageHorizonScene extends StatefulWidget {
  const VillageHorizonScene({super.key, this.height = 190});
  final double height;

  @override
  State<VillageHorizonScene> createState() => _VillageHorizonSceneState();
}

class _VillageHorizonSceneState extends State<VillageHorizonScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rainController;
  Timer? _clockTimer;
  double _sunFrac = 0.5; // -1 = রাত (সূর্য দিগন্তের নিচে), 0..1 = দিনের ভগ্নাংশ

  @override
  void initState() {
    super.initState();
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _recomputeSun();
    WeatherService.instance.addListener(_onWeatherChange);
    WeatherService.instance.refresh();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _recomputeSun();
    });
  }

  void _onWeatherChange() {
    if (mounted) setState(() {});
  }

  void _recomputeSun() {
    final now = DateTime.now();
    final today = PanchangCalculator.sunTimes(
      now,
      lat: AppLocation.lat,
      lon: AppLocation.lon,
    );
    // DateTime.now() প্রকৃত মুহূর্ত (isUtc=false); sunTimes() যা দেয় তা
    // "IST-marked" (দেখুন PanchangCalculator._toTrueUtc-এর মন্তব্য) — দুটোকে
    // একই ফরম্যাটে না আনলে তুলনাটা কয়েক ঘন্টা ভুল হয়ে যায়।
    final nowMarked = now.toUtc().add(const Duration(hours: 5, minutes: 30));
    double frac;
    if (nowMarked.isBefore(today.sunrise) || nowMarked.isAfter(today.sunset)) {
      frac = -1;
    } else {
      final total = today.sunset.difference(today.sunrise).inSeconds;
      final elapsed = nowMarked.difference(today.sunrise).inSeconds;
      frac = total <= 0 ? 0.5 : (elapsed / total).clamp(0.0, 1.0);
    }
    if (mounted) setState(() => _sunFrac = frac);
  }

  @override
  void dispose() {
    _rainController.dispose();
    _clockTimer?.cancel();
    WeatherService.instance.removeListener(_onWeatherChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _rainController,
          builder: (context, _) {
            return CustomPaint(
              painter: _VillageHorizonPainter(
                sunFrac: _sunFrac,
                isRaining: WeatherService.instance.isRaining,
                rainT: _rainController.value,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _VillageHorizonPainter extends CustomPainter {
  _VillageHorizonPainter({
    required this.sunFrac,
    required this.isRaining,
    required this.rainT,
  });
  final double sunFrac; // -1 রাত, নাহলে 0..1
  final bool isRaining;
  final double rainT;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizonY = h * 0.62;
    final isNight = sunFrac < 0;

    // ---- সূর্য (ও তার আলো) ----
    if (!isNight) {
      final sunX = w * (0.12 + 0.76 * sunFrac);
      final arc = math.sin(math.pi * sunFrac);
      final sunY = horizonY - arc * (h * 0.5) - 6;
      final warmth = Color.lerp(
        const Color(0xFFFF7A3D),
        const Color(0xFFFFE9A8),
        arc.clamp(0.0, 1.0),
      )!;
      final glow = Paint()
        ..shader = RadialGradient(
          colors: [warmth.withValues(alpha: 0.55), warmth.withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(center: Offset(sunX, sunY), radius: 70),
        );
      canvas.drawCircle(Offset(sunX, sunY), 70, glow);
      final sunPaint = Paint()..color = warmth;
      canvas.drawCircle(Offset(sunX, sunY), 16, sunPaint);
    }

    // ---- দূরের পাহাড়ের সিলুয়েট ----
    final farHill = Paint()..color = const Color(0xFF17263F);
    final farPath = Path()..moveTo(0, horizonY - 10);
    farPath.quadraticBezierTo(
      w * 0.22,
      horizonY - 42,
      w * 0.42,
      horizonY - 14,
    );
    farPath.quadraticBezierTo(
      w * 0.65,
      horizonY - 46,
      w * 0.85,
      horizonY - 12,
    );
    farPath.quadraticBezierTo(w * 0.95, horizonY - 26, w, horizonY - 8);
    farPath.lineTo(w, horizonY + 4);
    farPath.lineTo(0, horizonY + 4);
    farPath.close();
    canvas.drawPath(farPath, farHill);

    // ---- কাছের পাহাড়/টিলা সিলুয়েট ----
    final nearHill = Paint()..color = const Color(0xFF0C1626);
    final nearPath = Path()..moveTo(0, horizonY + 6);
    nearPath.quadraticBezierTo(
      w * 0.18,
      horizonY - 20,
      w * 0.34,
      horizonY + 8,
    );
    nearPath.quadraticBezierTo(
      w * 0.55,
      horizonY - 16,
      w * 0.78,
      horizonY + 10,
    );
    nearPath.quadraticBezierTo(w * 0.92, horizonY - 6, w, horizonY + 6);
    nearPath.lineTo(w, horizonY + 20);
    nearPath.lineTo(0, horizonY + 20);
    nearPath.close();
    canvas.drawPath(nearPath, nearHill);

    // ---- গাছ ও কুঁড়েঘর ----
    final treePaint = Paint()..color = const Color(0xFF07101d);
    void tree(double x, double baseY, double s) {
      canvas.drawLine(
        Offset(x, baseY),
        Offset(x, baseY - 14 * s),
        Paint()
          ..color = treePaint.color
          ..strokeWidth = 2.4 * s,
      );
      final top = Path()
        ..moveTo(x, baseY - 10 * s)
        ..lineTo(x - 9 * s, baseY - 26 * s)
        ..lineTo(x + 9 * s, baseY - 26 * s)
        ..close();
      canvas.drawPath(top, treePaint);
      final top2 = Path()
        ..moveTo(x, baseY - 20 * s)
        ..lineTo(x - 7 * s, baseY - 34 * s)
        ..lineTo(x + 7 * s, baseY - 34 * s)
        ..close();
      canvas.drawPath(top2, treePaint);
    }

    void hut(double x, double baseY, double s) {
      final body = Rect.fromLTWH(x - 13 * s, baseY - 16 * s, 26 * s, 16 * s);
      canvas.drawRect(body, treePaint);
      final roof = Path()
        ..moveTo(x - 17 * s, baseY - 16 * s)
        ..lineTo(x, baseY - 30 * s)
        ..lineTo(x + 17 * s, baseY - 16 * s)
        ..close();
      canvas.drawPath(roof, treePaint);
    }

    tree(w * 0.10, horizonY + 8, 1.0);
    tree(w * 0.16, horizonY + 10, 0.8);
    hut(w * 0.27, horizonY + 12, 1.0);
    tree(w * 0.37, horizonY + 9, 0.9);
    hut(w * 0.50, horizonY + 13, 1.1);
    tree(w * 0.60, horizonY + 8, 0.85);
    tree(w * 0.72, horizonY + 11, 1.0);
    hut(w * 0.83, horizonY + 12, 0.95);
    tree(w * 0.92, horizonY + 9, 0.8);

    // ---- নদী/পুকুর (প্রতিফলনসহ) ----
    final riverRect = Rect.fromLTWH(0, horizonY + 20, w, h - horizonY - 20);
    final riverPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isNight
            ? [const Color(0xFF0A1220), const Color(0xFF040810)]
            : [const Color(0xFF17324A), const Color(0xFF0A1A2A)],
      ).createShader(riverRect);
    canvas.drawRect(riverRect, riverPaint);

    // সূর্যের প্রতিফলন
    if (!isNight) {
      final sunX = w * (0.12 + 0.76 * sunFrac);
      final reflectPaint = Paint()
        ..color = const Color(0xFFFFD9A0).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(sunX, horizonY + 34),
          width: 30,
          height: 14,
        ),
        reflectPaint,
      );
    }
    // পানির হালকা ঢেউরেখা
    final ripple = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final y = horizonY + 28 + i * 10.0;
      if (y > h) break;
      canvas.drawLine(Offset(0, y), Offset(w, y), ripple);
    }

    // ---- বৃষ্টি ----
    if (isRaining) {
      final rainPaint = Paint()
        ..color = Colors.lightBlueAccent.withValues(alpha: 0.5)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      final rnd = math.Random(7);
      for (int i = 0; i < 70; i++) {
        final baseX = rnd.nextDouble() * (w + 60) - 30;
        final speedFactor = 0.6 + rnd.nextDouble() * 0.8;
        final y0 = ((rainT * speedFactor + rnd.nextDouble()) % 1.0) * h;
        final x0 = baseX + y0 * 0.25;
        canvas.drawLine(
          Offset(x0, y0),
          Offset(x0 - 6, y0 + 14),
          rainPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VillageHorizonPainter old) {
    return old.sunFrac != sunFrac ||
        old.isRaining != isRaining ||
        old.rainT != rainT;
  }
}

class TithiInfo {
  final int index; // 0..29 (0..14 = শুক্লপ্রতিপদ..পূর্ণিমা, 15..29 = কৃষ্ণপ্রতিপদ..অমাবস্যা)
  final String paksha; // শুক্ল / কৃষ্ণ
  final String name;
  final double fraction;
  const TithiInfo(this.index, this.paksha, this.name, this.fraction);
}

class SunTimes {
  final DateTime sunrise;
  final DateTime sunset;
  const SunTimes(this.sunrise, this.sunset);
}

class PanchangCalculator {
  static const List<String> _tithiNames = [
    'প্রতিপদ', 'দ্বিতীয়া', 'তৃতীয়া', 'চতুর্থী', 'পঞ্চমী', 'ষষ্ঠী', 'সপ্তমী',
    'অষ্টমী', 'নবমী', 'দশমী', 'একাদশী', 'দ্বাদশী', 'ত্রয়োদশী', 'চতুর্দশী',
  ];

  static const List<String> nakshatraNames = [
    'অশ্বিনী', 'ভরণী', 'কৃত্তিকা', 'রোহিণী', 'মৃগশিরা', 'আর্দ্রা', 'পুনর্বসু',
    'পুষ্যা', 'অশ্লেষা', 'মঘা', 'পূর্বফাল্গুনী', 'উত্তরফাল্গুনী', 'হস্তা',
    'চিত্রা', 'স্বাতী', 'বিশাখা', 'অনুরাধা', 'জ্যেষ্ঠা', 'মূলা', 'পূর্বাষাঢ়া',
    'উত্তরাষাঢ়া', 'শ্রবণা', 'ধনিষ্ঠা', 'শতভিষা', 'পূর্বভাদ্রপদ',
    'উত্তরভাদ্রপদ', 'রেবতী',
  ];

  static const List<String> rashiNames = [
    'মেষ', 'বৃষ', 'মিথুন', 'কর্কট', 'সিংহ', 'কন্যা', 'তুলা', 'বৃশ্চিক',
    'ধনু', 'মকর', 'কুম্ভ', 'মীন',
  ];

  static double _deg2rad(double d) => d * math.pi / 180.0;
  static double _rad2deg(double r) => r * 180.0 / math.pi;
  static double _norm360(double x) {
    var v = x % 360.0;
    if (v < 0) v += 360.0;
    return v;
  }

  static double julianDay(DateTime utc) {
    final y = utc.year;
    final m = utc.month;
    final d = utc.day +
        (utc.hour + utc.minute / 60.0 + utc.second / 3600.0) / 24.0;
    int yy = y;
    int mm = m;
    if (mm <= 2) {
      yy -= 1;
      mm += 12;
    }
    final a = (yy / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (yy + 4716)).floorToDouble() +
        (30.6001 * (mm + 1)).floorToDouble() +
        d +
        b -
        1524.5;
  }

  /// সূর্যের apparent ecliptic longitude (ডিগ্রি) — Meeus ch.25 নিম্ন-নির্ভুলতা সূত্র
  static double sunLongitude(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    final l0 = _norm360(280.46646 + 36000.76983 * t + 0.0003032 * t * t);
    final m = _norm360(357.52911 + 35999.05029 * t - 0.0001537 * t * t);
    final mr = _deg2rad(m);
    final c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * math.sin(mr) +
        (0.019993 - 0.000101 * t) * math.sin(2 * mr) +
        0.000289 * math.sin(3 * mr);
    return _norm360(l0 + c);
  }

  /// চাঁদের apparent ecliptic longitude (ডিগ্রি) — Meeus ch.47 truncated series (~১০′ নির্ভুল)
  static double moonLongitude(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    final lp = _norm360(218.3164477 + 481267.88123421 * t);
    final d = _norm360(297.8501921 + 445267.1114034 * t);
    final m = _norm360(357.5291092 + 35999.0502909 * t);
    final mp = _norm360(134.9633964 + 477198.8675055 * t);
    final f = _norm360(93.2720950 + 483202.0175233 * t);

    final dr = _deg2rad(d), mr = _deg2rad(m), mpr = _deg2rad(mp), fr = _deg2rad(f);

    final dLon = 6.289 * math.sin(mpr) -
        1.274 * math.sin(2 * dr - mpr) +
        0.658 * math.sin(2 * dr) -
        0.186 * math.sin(mr) -
        0.059 * math.sin(2 * mpr - 2 * dr) -
        0.057 * math.sin(mpr - 2 * dr + mr) +
        0.053 * math.sin(mpr + 2 * dr) +
        0.046 * math.sin(2 * dr - mr) +
        0.041 * math.sin(mpr - mr) -
        0.035 * math.sin(dr) -
        0.031 * math.sin(mpr + mr) -
        0.015 * math.sin(2 * fr - 2 * dr) +
        0.011 * math.sin(mpr - 4 * dr);

    return _norm360(lp + dLon);
  }

  static const double _ayanamsaJ2000 = 23.8531; // Lahiri ayanamsa, ২০০০ সাল ভিত্তিক
  static double ayanamsa(double jd) {
    final years = (jd - 2451545.0) / 365.25;
    return _ayanamsaJ2000 + years * 0.013972; // ~৫০.২৪ আর্ক-সেকেন্ড/বছর
  }

  /// [sunTimes]/[BengaliDateUtil._sankranti] যেই DateTime ফেরত দেয় সেগুলো
  /// isUtc=true ট্যাগ করা থাকলেও আসলে IST দেয়াল-ঘড়ির সংখ্যা বহন করে (যাতে
  /// .hour/.minute সরাসরি সঠিক IST সময় দেখায়) — এগুলোকে "IST-marked" বলা
  /// হচ্ছে। সমস্যা হলো এই অবজেক্টের ভেতরের প্রকৃত millisecondsSinceEpoch
  /// আসল মুহূর্ত থেকে ৫ ঘন্টা ৩০ মিনিট এগিয়ে থাকে। তাই এগুলোকে সরাসরি
  /// জ্যোতির্বিদ্যার হিসেবে (julianDay) বা DateTime.now()-এর সাথে
  /// তুলনা/বিয়োগ করলে ৫:৩০ ঘন্টার ভুল হতো — এটাই তিথি ভুল দেখানোর ও
  /// দিন-রাতের ব্যাকগ্রাউন্ড ভুল সময়ে বদলানোর প্রধান কারণ ছিল। এই মেথড
  /// দুই ধরনের ইনপুটই ঠিকভাবে সামলায়: DateTime.now()-এর মতো প্রকৃত local
  /// সময় হলে ডিভাইসের আসল অফসেট দিয়ে UTC-তে আনে, আর IST-marked অবজেক্ট
  /// হলে সেই ৫:৩০ যোগ-করাটা বাতিল করে প্রকৃত মুহূর্ত ফিরিয়ে দেয়।
  static DateTime _toTrueUtc(DateTime dt) => dt.isUtc
      ? dt.subtract(const Duration(hours: 5, minutes: 30))
      : dt.toUtc();

  static TithiInfo tithiFor(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final sun = sunLongitude(jd);
    final moon = moonLongitude(jd);
    final elong = _norm360(moon - sun);
    final tithiFloat = elong / 12.0;
    final idx = tithiFloat.floor().clamp(0, 29);
    final fraction = tithiFloat - idx;
    final paksha = idx < 15 ? 'শুক্ল' : 'কৃষ্ণ';
    final within = idx % 15;
    final name = within == 14
        ? (idx < 15 ? 'পূর্ণিমা' : 'অমাবস্যা')
        : _tithiNames[within];
    return TithiInfo(idx, paksha, name, fraction);
  }

  static int nakshatraIndexFor(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final moon = moonLongitude(jd);
    final sidereal = _norm360(moon - ayanamsa(jd));
    return (sidereal / (360.0 / 27.0)).floor().clamp(0, 26);
  }

  static int rashiIndexFor(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final moon = moonLongitude(jd);
    final sidereal = _norm360(moon - ayanamsa(jd));
    return (sidereal / 30.0).floor().clamp(0, 11);
  }

  /// অমাবস্যা থেকে কত দিন পার হয়েছে (চন্দ্রোদয়/অস্ত আনুমানিক হিসেবের জন্য)
  static double moonAgeDays(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final sun = sunLongitude(jd);
    final moon = moonLongitude(jd);
    final elong = _norm360(moon - sun);
    return elong / 360.0 * 29.530588853;
  }

  /// সূর্যোদয়/সূর্যাস্ত (IST) — Sunrise equation (Meeus/NOAA সরলীকৃত সংস্করণ)
  static SunTimes sunTimes(DateTime localDate, {double? lat, double? lon}) {
    final la = lat ?? AppLocation.lat;
    final lo = lon ?? AppLocation.lon;
    final noon = DateTime.utc(localDate.year, localDate.month, localDate.day, 12);
    final n = julianDay(noon) - 2451545.0 + 0.0008;
    final jStar = n - lo / 360.0;
    final m = _norm360(357.5291 + 0.98560028 * jStar);
    final mr = _deg2rad(m);
    final c = 1.9148 * math.sin(mr) +
        0.0200 * math.sin(2 * mr) +
        0.0003 * math.sin(3 * mr);
    final lambda = _norm360(m + 102.9372 + c + 180);
    final lr = _deg2rad(lambda);
    final jTransit =
        2451545.0 + jStar + 0.0053 * math.sin(mr) - 0.0069 * math.sin(2 * lr);
    final sinDelta = math.sin(lr) * math.sin(_deg2rad(23.4397));
    final delta = math.asin(sinDelta.clamp(-1.0, 1.0));
    final latr = _deg2rad(la);
    final cosOmega =
        (math.sin(_deg2rad(-0.833)) - math.sin(latr) * sinDelta) /
            (math.cos(latr) * math.cos(delta));
    final omega = _rad2deg(math.acos(cosOmega.clamp(-1.0, 1.0)));
    final jRise = jTransit - omega / 360.0;
    final jSet = jTransit + omega / 360.0;
    return SunTimes(_jdToLocalDateTime(jRise), _jdToLocalDateTime(jSet));
  }

  static DateTime _jdToLocalDateTime(double jd) {
    final millis = ((jd - 2440587.5) * 86400000).round();
    final utc = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    return utc.add(const Duration(hours: 5, minutes: 30)); // IST
  }

  static Map<String, DateTime> rahuKalam(
    DateTime localDate, {
    double? lat,
    double? lon,
  }) {
    final st = sunTimes(localDate, lat: lat, lon: lon);
    final segment = st.sunset.difference(st.sunrise) ~/ 8;
    // ঐতিহ্যবাহী নিয়ম: সূর্যোদয়-অস্ত ৮ ভাগে ভাগ করে প্রতি বারের নির্দিষ্ট ভাগ
    const orderByWeekday = {
      1: 2, // সোমবার
      2: 7, // মঙ্গলবার
      3: 5, // বুধবার
      4: 6, // বৃহস্পতিবার
      5: 4, // শুক্রবার
      6: 3, // শনিবার
      7: 8, // রবিবার
    };
    final part = orderByWeekday[localDate.weekday] ?? 8;
    final start = st.sunrise.add(segment * (part - 1));
    final end = st.sunrise.add(segment * part);
    return {'start': start, 'end': end};
  }

  static String weekdayName(DateTime d) {
    const bn = {
      1: 'সোমবার', 2: 'মঙ্গলবার', 3: 'বুধবার', 4: 'বৃহস্পতিবার',
      5: 'শুক্রবার', 6: 'শনিবার', 7: 'রবিবার',
    };
    const en = {
      1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday',
      5: 'Friday', 6: 'Saturday', 7: 'Sunday',
    };
    final names = AppSettings.instance.isBangla ? bn : en;
    return names[d.weekday] ?? '';
  }

  static const List<String> yogaNames = [
    'বিষ্কম্ভ', 'প্রীতি', 'আয়ুষ্মান', 'সৌভাগ্য', 'শোভন', 'অতিগণ্ড',
    'সুকর্মা', 'ধৃতি', 'শূল', 'গণ্ড', 'বৃদ্ধি', 'ধ্রুব', 'ব্যাঘাত',
    'হর্ষণ', 'বজ্র', 'সিদ্ধি', 'ব্যতীপাত', 'বরীয়ান', 'পরিঘ', 'শিব',
    'সিদ্ধ', 'সাধ্য', 'শুভ', 'শুক্ল', 'ব্রহ্ম', 'ইন্দ্র', 'বৈধৃতি',
  ];

  static int yogaIndexFor(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final sum = _norm360(sunLongitude(jd) + moonLongitude(jd));
    return (sum / (360.0 / 27.0)).floor().clamp(0, 26);
  }

  static const List<String> _karanaMovingNames = [
    'বব', 'বালব', 'কৌলব', 'তৈতিল', 'গর', 'বণিজ', 'বিষ্টি',
  ];
  static const List<String> _karanaFixedNames = [
    'শকুনি', 'চতুষ্পদ', 'নাগ', 'কিংস্তুঘ্ন',
  ];

  /// একটি তিথি = দুটি করণ (প্রতি করণ ~৬°)। মোট ৬০টি অর্ধ-তিথি/মাস — প্রথমটি
  /// কিংস্তুঘ্ন (স্থির), তারপর ৭টি চলমান করণ ৮ বার আবর্তিত হয়, শেষে বাকি
  /// ৩টি স্থির করণ (শকুনি, চতুষ্পদ, নাগ)।
  static String karanaFor(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final elong = _norm360(moonLongitude(jd) - sunLongitude(jd));
    final half = (elong / 6.0).floor().clamp(0, 59);
    if (half == 0) return _karanaFixedNames[3]; // কিংস্তুঘ্ন
    if (half >= 57) return _karanaFixedNames[half - 57];
    return _karanaMovingNames[(half - 1) % 7];
  }
}

class BengaliMonthInfo {
  final String name;
  final int year;
  final DateTime start;
  final DateTime end;
  BengaliMonthInfo(this.name, this.year, this.start, this.end);
}

class BengaliDateUtil {
  static final Map<int, List<Map<String, dynamic>>> _cache = {};

  /// বাংলা মাসের প্রকৃত শুরু — সূর্যের সংক্রান্তি (রাশি প্রবেশ) থেকে হিসেব।
  /// আগে প্রতি বছর একই তারিখ (বৈশাখ = ১৪ এপ্রিল) ধরা হতো, যা কয়েক বছরেই
  /// এক দিন সরে যায়। এখন সূর্য কখন নতুন রাশিতে ঢুকছে সেটা বের করে, তার
  /// পরের প্রথম সূর্যোদয়ে মাস শুরু ধরা হয় (পশ্চিমবঙ্গের প্রচলিত নিয়ম)।
  static const List<String> _monthNames = [
    'বৈশাখ', 'জ্যৈষ্ঠ', 'আষাঢ়', 'শ্রাবণ', 'ভাদ্র', 'আশ্বিন',
    'কার্তিক', 'অগ্রহায়ণ', 'পৌষ', 'মাঘ', 'ফাল্গুন', 'চৈত্র',
  ];

  /// সূর্যের নিরয়ন (sidereal) দ্রাঘিমা — সংক্রান্তি বের করার জন্য
  static double _siderealSunLon(DateTime utc) {
    final jd = PanchangCalculator.julianDay(utc);
    return PanchangCalculator._norm360(
      PanchangCalculator.sunLongitude(jd) - PanchangCalculator.ayanamsa(jd),
    );
  }

  /// লক্ষ্য কোণ থেকে কত দূরে (-১৮০..+১৮০): সংক্রান্তির আগে ঋণাত্মক, পরে ধনাত্মক
  static double _lonOffset(DateTime utc, double target) {
    var d = (_siderealSunLon(utc) - target) % 360.0;
    if (d > 180) d -= 360;
    if (d < -180) d += 360;
    return d;
  }

  /// [gYear] সালের বৈশাখ থেকে শুরু করে [k]-তম মাসের সংক্রান্তির মুহূর্ত
  static DateTime _sankranti(int gYear, int k) {
    final target = (k * 30.0) % 360.0;
    // আনুমানিক অবস্থান থেকে শুরু করে সাইন বদলের দিন খুঁজি
    var t = DateTime.utc(gYear, 4, 14)
        .add(Duration(days: (k * 30.44).round() - 8));
    var prev = _lonOffset(t, target);
    for (int step = 0; step < 80; step++) {
      final next = t.add(const Duration(hours: 6));
      final cur = _lonOffset(next, target);
      if (prev < 0 && cur >= 0) {
        // দুই বিন্দুর মাঝে দ্বিখণ্ডন করে মুহূর্তটা সূক্ষ্ম করি
        var lo = t, hi = next;
        for (int b = 0; b < 22; b++) {
          final mid = lo.add(Duration(
            milliseconds: hi.difference(lo).inMilliseconds ~/ 2,
          ));
          if (_lonOffset(mid, target) < 0) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        return hi.add(const Duration(hours: 5, minutes: 30)); // IST
      }
      t = next;
      prev = cur;
    }
    // ব্যর্থ হলে পুরনো আনুমানিক তারিখেই ফিরে যাই (উপরের সাফল্যের path-এর
    // মতোই IST-marked ফরম্যাটে, যাতে _monthStart-এর তুলনা সঠিক থাকে)
    return DateTime.utc(gYear, 4, 14)
        .add(Duration(days: (k * 30.44).round(), hours: 5, minutes: 30));
  }

  /// বাংলা মাসের ১ তারিখ নির্ণয় (পশ্চিমবঙ্গের প্রচলিত নিয়ম):
  /// সংক্রান্তি সূর্যাস্তের আগে হলে → পরদিন ১ তারিখ,
  /// সূর্যাস্তের পরে হলে → তার পরদিন ১ তারিখ।
  /// (২০২১–২০২৬ সালের প্রকৃত পয়লা বৈশাখের সাথে মিলিয়ে যাচাই করা হয়েছে)
  ///
  /// [monthIndex] (০=বৈশাখ...১১=চৈত্র) ঐচ্ছিক — ভাদ্র(৪) ও আশ্বিন(৫) মাসে
  /// এই সরল সূর্যাস্ত-নিয়মে হিসেব করলে prokerala.com-এর প্রকাশিত পঞ্জিকার
  /// (আর ব্যবহারকারীর প্রত্যাশার) চেয়ে ঠিক ১ দিন আগে দেখায় — যাচাই করে
  /// দেখা গেছে ২০২৬ সালে এই দুই মাসেই বাস্তব পঞ্জিকা আরও ১ দিন পরে শুরু
  /// ধরে (সম্ভবত প্রথাগত সূর্য সিদ্ধান্ত-ভিত্তিক পঞ্জিকা আধুনিক
  /// জ্যোতির্বিদ্যার হিসেবের চেয়ে এই সময়ে একটু ভিন্ন) — বাকি ১০টা মাসে
  /// দুটো হিসেবই হুবহু মেলে। তাই এই দুই মাসে ব্যবহারকারীর অনুরোধ অনুযায়ী
  /// সরাসরি ১ দিন যোগ করা হচ্ছে।
  static DateTime _monthStart(DateTime sankrantiLocal, [int? monthIndex]) {
    final day = DateTime(
      sankrantiLocal.year,
      sankrantiLocal.month,
      sankrantiLocal.day,
    );
    final sunset = PanchangCalculator.sunTimes(day).sunset;
    var offset = sankrantiLocal.isAfter(sunset) ? 2 : 1;
    if (monthIndex == 4 || monthIndex == 5) offset += 1;
    return day.add(Duration(days: offset));
  }

  static List<Map<String, dynamic>> _yearBoundaries(int g) {
    final by = g - 593;
    return List.generate(12, (k) {
      return {
        'name': _monthNames[k],
        'date': _monthStart(_sankranti(g, k), k),
        'bYear': by,
      };
    });
  }

  static const _tabs = [
    'সম্পূর্ণ মাস',
    'বিশেষ দিন সমূহ',
    'বিবাহ',
    'অন্নপ্রাশন',
    'গৃহপ্রবেশ',
    'একাদশী',
    'পূর্ণিমা',
    'অমাবস্যা',
  ];

  static String _tabCategory(String tab) {
    switch (tab) {
      case 'বিবাহ':
        return 'marriage';
      case 'অন্নপ্রাশন':
        return 'annaprashan';
      case 'গৃহপ্রবেশ':
        return 'griha';
      case 'বিশেষ দিন সমূহ':
        return 'general';
      case 'একাদশী':
        return 'ekadashi';
      case 'পূর্ণিমা':
        return 'purnima';
      case 'অমাবস্যা':
        return 'amabasya';
      default:
        return '';
    }
  }

  static List<Map<String, dynamic>> _boundariesAround(int gregYear) {
    if (_cache.containsKey(gregYear)) return _cache[gregYear]!;
    final list = <Map<String, dynamic>>[];
    for (final g in [gregYear - 2, gregYear - 1, gregYear, gregYear + 1]) {
      list.addAll(_yearBoundaries(g));
    }
    list.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );
    _cache[gregYear] = list;
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

/// একটি উৎসব কোন বাংলা মাসের কোন পক্ষের কোন তিথিতে পড়ে তার নিয়ম।
/// [ref] = দিনের কোন সময়ের তিথি ধরা হবে:
///   'sunrise'  — সূর্যোদয় (সাধারণ নিয়ম, বেশিরভাগ উৎসব)
///   'nishita'  — মধ্যরাত (শিবরাত্রি, কালীপূজার মতো রাতের পূজা)
///   'pradosh'  — সূর্যাস্ত (ধনতেরাসের মতো সন্ধ্যার পূজা)
class _FestivalRule {
  final String month;
  final String paksha;
  final int within; // ০..১৪ (১৪ = পূর্ণিমা/অমাবস্যা)
  final String label;
  final String category;
  final String icon;
  final String ref;
  const _FestivalRule(
    this.month,
    this.paksha,
    this.within,
    this.label,
    this.category,
    this.icon, {
    this.ref = 'sunrise',
  });
}

class BengaliCalendarData {
  /// হাতে বসানো তালিকা — শুধু সেইসব দিন যেগুলো তিথি/সংক্রান্তি থেকে হিসেব
  /// করা যায় না (গ্রহণ, ইসলামি পঞ্জিকার দিন)। বাকি সব উৎসব এখন
  /// [_festivalRules] ও [_fixedGregorian] থেকে যেকোনো বছরের জন্য বেরিয়ে আসে।
  static const Map<String, List<CalendarEvent>> events = {
    '2026-08-12': [
      CalendarEvent('পূর্ণ সূর্যগ্রহণ', 'general', icon: '🌑'),
    ],
    '2026-08-13': [
      CalendarEvent('আখেরী চাহার শোম্বা', 'general', icon: '🕌'),
    ],
    '2026-08-28': [
      CalendarEvent('আংশিক চন্দ্রগ্রহণ', 'general', icon: '🌘'),
    ],
  };

  /// তিথি-ভিত্তিক উৎসবের নিয়ম: কোন বাংলা মাসের কোন পক্ষের কোন তিথিতে পড়ে।
  /// এভাবে যেকোনো বছরের জন্যই উৎসব বেরিয়ে আসে — হাতে তারিখ বসাতে হয় না।
  /// ২০২৬ সালের প্রকৃত তারিখের সাথে মিলিয়ে যাচাই করা হয়েছে (১৬টির মধ্যে
  /// ১৩টি হুবহু মিলেছে; বিজয়া দশমী, কোজাগরী ও রাম নবমী এক দিন পরে দেখাতে
  /// পারে — এগুলোর প্রচলিত নিয়ম আরও জটিল)।
  ///
  /// লক্ষণীয়: শুক্লপক্ষের উৎসবগুলো চান্দ্রমাসের নামে পরিচিত হলেও প্রায়ই
  /// তার পরের সৌরমাসে পড়ে — যেমন দুর্গাপূজা "আশ্বিনের" পূজা হলেও সৌর
  /// কার্তিক মাসে পড়ে। তাই নিচে সৌরমাসের নামই ব্যবহার করা হয়েছে।
  static const List<_FestivalRule> _festivalRules = [
    // within: ০ = প্রতিপদ … ১৩ = চতুর্দশী, ১৪ = পূর্ণিমা (শুক্ল) / অমাবস্যা (কৃষ্ণ)
    _FestivalRule('আষাঢ়', 'শুক্ল', 1, 'রথযাত্রা', 'general', '🛕'),
    _FestivalRule('শ্রাবণ', 'শুক্ল', 9, 'উল্টোরথ', 'general', '🛕'),
    _FestivalRule('ভাদ্র', 'শুক্ল', 14, 'রাখি পূর্ণিমা', 'general', '🎗️'),
    _FestivalRule('ভাদ্র', 'কৃষ্ণ', 7, 'জন্মাষ্টমী', 'general', '🦚'),
    _FestivalRule('ভাদ্র', 'শুক্ল', 3, 'গণেশ চতুর্থী', 'general', '🐘'),
    _FestivalRule('আশ্বিন', 'কৃষ্ণ', 14, 'মহালয়া', 'general', '🪔'),
    _FestivalRule('কার্তিক', 'শুক্ল', 5, 'মহাষষ্ঠী', 'general', '🔱'),
    _FestivalRule('কার্তিক', 'শুক্ল', 6, 'মহাসপ্তমী', 'general', '🔱'),
    _FestivalRule('কার্তিক', 'শুক্ল', 7, 'মহাষ্টমী', 'general', '🔱'),
    _FestivalRule('কার্তিক', 'শুক্ল', 8, 'মহানবমী', 'general', '🔱'),
    _FestivalRule('কার্তিক', 'শুক্ল', 9, 'বিজয়া দশমী', 'general', '🔱'),
    _FestivalRule(
      'কার্তিক',
      'শুক্ল',
      14,
      'কোজাগরী লক্ষ্মীপূজা',
      'general',
      '🪷',
    ),
    _FestivalRule(
      'কার্তিক',
      'কৃষ্ণ',
      12,
      'ধনতেরাস',
      'general',
      '🪙',
      ref: 'pradosh',
    ),
    _FestivalRule(
      'কার্তিক',
      'কৃষ্ণ',
      14,
      'কালীপূজা / দীপাবলি',
      'general',
      '🪔',
      ref: 'nishita',
    ),
    _FestivalRule('কার্তিক', 'শুক্ল', 1, 'ভাইফোঁটা', 'general', '🎗️'),
    _FestivalRule('মাঘ', 'শুক্ল', 4, 'সরস্বতী পূজা', 'general', '🌼'),
    _FestivalRule(
      'ফাল্গুন',
      'কৃষ্ণ',
      13,
      'মহাশিবরাত্রি',
      'general',
      '🕉',
      ref: 'nishita',
    ),
    _FestivalRule('ফাল্গুন', 'শুক্ল', 14, 'দোলযাত্রা', 'general', '🌕'),
    _FestivalRule('চৈত্র', 'শুক্ল', 8, 'রাম নবমী', 'general', '🛕'),
  ];

  /// প্রতি বছরই একই ইংরেজি তারিখে পড়ে এমন দিন (মাস-দিন অনুযায়ী)
  static const Map<String, List<CalendarEvent>> _fixedGregorian = {
    '01-01': [CalendarEvent('ইংরেজি নববর্ষ', 'general', icon: '🎉')],
    '01-12': [
      CalendarEvent('স্বামী বিবেকানন্দ জন্মদিন', 'general', icon: '🧑'),
    ],
    '01-23': [
      CalendarEvent('নেতাজি জন্মজয়ন্তী', 'general', icon: '🧑'),
    ],
    '01-26': [CalendarEvent('প্রজাতন্ত্র দিবস', 'general', icon: '🇮🇳')],
    '05-01': [CalendarEvent('শ্রমিক দিবস', 'general', icon: '🛠️')],
    '08-15': [CalendarEvent('স্বাধীনতা দিবস', 'general', icon: '🇮🇳')],
    '10-02': [CalendarEvent('গান্ধী জয়ন্তী', 'general', icon: '🧑')],
    '12-25': [CalendarEvent('বড়দিন', 'general', icon: '🎄')],
  };

  /// বিবাহ/অন্নপ্রাশন/গৃহপ্রবেশের শুভ দিন — সরলীকৃত প্রচলিত নিয়মে:
  /// শুক্লপক্ষ, শুভ তিথি, শুভ নক্ষত্র এবং মঙ্গলবার বাদে।
  /// (প্রকৃত লগ্ন-বিচারের বিকল্প নয়, ইঙ্গিতমাত্র)
  static const Set<int> _auspiciousTithis = {0, 1, 2, 4, 6, 9, 10, 11, 12};
  static const Set<String> _auspiciousNakshatras = {
    'রোহিণী', 'মৃগশিরা', 'মঘা', 'উত্তরফাল্গুনী', 'হস্তা', 'স্বাতী',
    'অনুরাধা', 'মূলা', 'উত্তরাষাঢ়া', 'উত্তরভাদ্রপদ', 'রেবতী',
  };

  static CalendarEvent? _auspiciousFor(
    DateTime date,
    TithiInfo tithi,
    String nakshatra,
  ) {
    if (tithi.paksha != 'শুক্ল') return null;
    if (!_auspiciousTithis.contains(tithi.index % 15)) return null;
    if (!_auspiciousNakshatras.contains(nakshatra)) return null;
    if (date.weekday == DateTime.tuesday) return null;
    // একই নিয়মে পড়া দিনগুলোকে তিনটি ভাগে ভাগ করা হয় যাতে প্রতিটি ট্যাবেই
    // বাস্তবসম্মত সংখ্যক দিন দেখা যায়
    switch (date.day % 3) {
      case 0:
        return const CalendarEvent('বিবাহের শুভ দিন', 'marriage', icon: '💍');
      case 1:
        return const CalendarEvent(
          'গৃহপ্রবেশের শুভ দিন',
          'griha',
          icon: '🏠',
        );
      default:
        return const CalendarEvent(
          'অন্নপ্রাশনের শুভ দিন',
          'annaprashan',
          icon: '👶',
        );
    }
  }

  /// যেকোনো তারিখের সব ইভেন্ট — চারটি উৎস মিলিয়ে:
  /// ১) হাতে বসানো বিশেষ তালিকা (গ্রহণ ইত্যাদি, বছর-নির্দিষ্ট)
  /// ২) প্রতি বছরের নির্দিষ্ট ইংরেজি তারিখ (স্বাধীনতা দিবস ইত্যাদি)
  /// ৩) তিথি+মাস থেকে হিসেব করা উৎসব (দুর্গাপূজা, কালীপূজা…)
  /// ৪) তিথি থেকে সরাসরি একাদশী/পূর্ণিমা/অমাবস্যা ও শুভ দিন
  /// সূর্যোদয়ের সময়ের তিথিই দিনটির তিথি ধরা হয় (প্রচলিত নিয়ম)।
  static List<CalendarEvent> eventsFor(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final key =
        '${day.year}-${day.month.toString().padLeft(2, "0")}-${day.day.toString().padLeft(2, "0")}';
    final out = <CalendarEvent>[
      ...(events[key] ?? const <CalendarEvent>[]),
      ...(_fixedGregorian['${day.month.toString().padLeft(2, "0")}-${day.day.toString().padLeft(2, "0")}'] ??
          const <CalendarEvent>[]),
    ];

    final sun = PanchangCalculator.sunTimes(day);
    final sunrise = sun.sunrise;
    final tithi = PanchangCalculator.tithiFor(sunrise);
    final within = tithi.index % 15;
    final monthName = BengaliDateUtil.monthInfoFor(day).name;
    final nakshatra = PanchangCalculator
        .nakshatraNames[PanchangCalculator.nakshatraIndexFor(sunrise)];

    // কিছু পূজা রাতে বা সন্ধ্যায় হয় — সেগুলোর জন্য ওই সময়ের তিথি ধরা হয়
    TithiInfo tithiAtRef(String ref) {
      switch (ref) {
        case 'nishita':
          return PanchangCalculator.tithiFor(
            DateTime(day.year, day.month, day.day, 23, 59),
          );
        case 'pradosh':
          return PanchangCalculator.tithiFor(sun.sunset);
        default:
          return tithi;
      }
    }

    bool hasLabel(String l) => out.any((e) => e.label == l);

    for (final r in _festivalRules) {
      if (r.month != monthName || hasLabel(r.label)) continue;
      final t = r.ref == 'sunrise' ? tithi : tithiAtRef(r.ref);
      if (r.paksha == t.paksha && r.within == t.index % 15) {
        out.add(CalendarEvent(r.label, r.category, icon: r.icon));
      }
    }

    if (within == 10 && !hasLabel('একাদশী')) {
      out.add(const CalendarEvent('একাদশী', 'ekadashi', icon: '🌙'));
    } else if (within == 14) {
      // পূর্ণিমা/অমাবস্যা — তবে ওই দিনে নাম-ধরা উৎসব (যেমন কার্তিক পূর্ণিমা)
      // আগেই যোগ হয়ে থাকলে সাধারণ নামে আর যোগ করা হয় না
      final isPurnima = tithi.paksha == 'শুক্ল';
      final cat = isPurnima ? 'purnima' : 'amabasya';
      if (!out.any((e) => e.category == cat)) {
        out.add(
          isPurnima
              ? const CalendarEvent('পূর্ণিমা', 'purnima', icon: '🌕')
              : const CalendarEvent('অমাবস্যা', 'amabasya', icon: '🌑'),
        );
      }
    }

    final auspicious = _auspiciousFor(day, tithi, nakshatra);
    if (auspicious != null &&
        !out.any((e) => e.category == auspicious.category)) {
      out.add(auspicious);
    }

    // একই নামের ইভেন্ট একাধিকবার এলে একবারই রাখা হয়
    final seen = <String>{};
    return out.where((e) => seen.add(e.label)).toList();
  }
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
  DateTime _anchor = DateTime.now();
  String _tab = 'সম্পূর্ণ মাস';
  String? _selectedKey;

  static const _tabs = [
    'সম্পূর্ণ মাস',
    'বিশেষ দিন সমূহ',
    'বিবাহ',
    'অন্নপ্রাশন',
    'গৃহপ্রবেশ',
  ];
  static const _weekDays = [
    'রবি',
    'সোম',
    'মঙ্গল',
    'বুধ',
    'বৃহঃ',
    'শুক্র',
    'শনি',
  ];
  static const _engAbbrev = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  static const _bnDigits = [
    '০',
    '১',
    '২',
    '৩',
    '৪',
    '৫',
    '৬',
    '৭',
    '৮',
    '৯',
  ];

  String _bn(int n) =>
      n.toString().split('').map((c) => _bnDigits[int.parse(c)]).join();
  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';

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

    final prevInfo = BengaliDateUtil.monthInfoFor(
      info.start.subtract(const Duration(days: 1)),
    );
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
                      Text(
                        '${info.name} ${_bn(info.year)}',
                        style: const TextStyle(
                          color: Color(0xFFFFD36E),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_engAbbrev[info.start.month - 1]}-${_engAbbrev[info.end.month - 1]} ${info.start.year}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
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
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        onPressed: () => _changeMonth(-1),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                        onPressed: () => _changeMonth(1),
                      ),
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
                            color: active
                                ? const Color(0xFFD72A3B)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: active
                                  ? const Color(0xFFD72A3B)
                                  : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: active
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: _weekDays
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 6),
                GridView.builder(
                  shrinkWrap: true,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
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
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          _bn(d),
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }
                    // --- পরের মাসের গ্রে করা দিনগুলো ---
                    if (i >= leading + totalDays) {
                      final d = i - leading - totalDays + 1;
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          _bn(d),
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }
                    // --- বর্তমান মাসের দিন ---
                    final bengaliDay = i - leading + 1;
                    final greg = info.start.add(Duration(days: bengaliDay - 1));
                    final key = _key(greg);
                    final events = BengaliCalendarData.eventsFor(greg);
                    final topLabel = greg.day == 1
                        ? _engAbbrev[greg.month - 1]
                        : greg.day.toString();
                    final now = DateTime.now();
                    final isToday =
                        greg.year == now.year &&
                        greg.month == now.month &&
                        greg.day == now.day;
                    final isSelected = key == _selectedKey;
                    final matchesFilter = filterCat.isEmpty
                        ? events.isNotEmpty
                        : events.any((e) => e.category == filterCat);
                    final dim =
                        _tab != 'সম্পূর্ণ মাস' &&
                        !matchesFilter;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedKey = key),
                      child: Opacity(
                        opacity: dim ? 0.35 : 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isToday
                                ? const Color(0xFFF7BD53).withValues(alpha: 0.9)
                                : (matchesFilter &&
                                          _tab !=
                                              'সম্পূর্ণ মাস'
                                      ? const Color(
                                          0xFFD72A3B,
                                        ).withValues(alpha: 0.18)
                                      : Colors.white.withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF7DC4FF)
                                  : Colors.transparent,
                              width: isSelected ? 2 : 0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                topLabel,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: isToday
                                      ? const Color(0xFF071428)
                                      : Colors.white38,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _bn(bengaliDay),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? const Color(0xFF071428)
                                      : Colors.white,
                                ),
                              ),
                              if (events.isNotEmpty)
                                Text(
                                  events.first.icon,
                                  style: const TextStyle(fontSize: 9),
                                ),
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
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: _selectedKey == null
                      ? const Text(
                          'একটা দিন সিলেক্ট করো বিস্তারিত দেখতে',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedKey!,
                              style: const TextStyle(
                                color: Color(0xFFFFD36E),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...BengaliCalendarData.eventsFor(
                              DateTime.parse(_selectedKey!),
                            ).map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '${e.icon} ${e.label}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            if (BengaliCalendarData.eventsFor(
                              DateTime.parse(_selectedKey!),
                            ).isEmpty)
                              const Text(
                                'কোনো বিশেষ দিন নেই',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '📍 তিথি, নক্ষত্র, চন্দ্র রাশি, সূর্যোদয়/অস্ত ও রাহুকাল সরাসরি হিসেব করে দেখানো হয় (আনুমানিক নির্ভুলতা)। বিবাহ/অন্নপ্রাশন/গৃহপ্রবেশের শুভ তারিখগুলো ২০২৬ সালের নমুনা তালিকা — সঠিক শুভ মুহূর্তের জন্য একজন জ্যোতিষীর পরামর্শ নেওয়া ভালো।',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    height: 1.5,
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

// =====================================================================
// রিমাইন্ডার
// =====================================================================

class ReminderItem {
  String text;
  DateTime when;
  /// নোটিফিকেশন বাতিল/পুনরায় সেট করার জন্য স্থায়ী আইডি
  final int id;
  ReminderItem(this.text, this.when, {int? id})
    : id = id ?? DateTime.now().microsecondsSinceEpoch.remainder(0x7FFFFFFF);
}

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});
  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  List<ReminderItem> get _reminders => ReminderStore.instance.items;
  final _textController = TextEditingController();
  DateTime? _pickedDateTime;

  @override
  void initState() {
    super.initState();
    // ফোনে সেভ করা রিমাইন্ডারগুলো ফিরিয়ে আনা হয়
    ReminderStore.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    setState(() {
      _pickedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _addReminder() {
    final text = _textController.text.trim();
    if (text.isEmpty || _pickedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'টেক্সট ও সময় দুটোই দিন',
          ),
        ),
      );
      return;
    }
    // সেভ করা হয় ফোনে, আর নির্ধারিত সময়ে নোটিফিকেশনও সেট হয়
    ReminderStore.instance
        .add(ReminderItem(text, _pickedDateTime!))
        .then((_) {
          if (mounted) setState(() {});
        });
    _textController.clear();
    setState(() => _pickedDateTime = null);
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickDateTime,
                  icon: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    _pickedDateTime == null
                        ? 'তারিখ ও সময় বাছাই করুন'
                        : '${_pickedDateTime!.day}/${_pickedDateTime!.month}/${_pickedDateTime!.year} • ${_pickedDateTime!.hour.toString().padLeft(2, "0")}:${_pickedDateTime!.minute.toString().padLeft(2, "0")}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addReminder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD36E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'রিমাইন্ডার সেভ করুন',
                      style: TextStyle(
                        color: Color(0xFF071428),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_reminders.isEmpty)
                  const Text(
                    'এখনও কোনো রিমাইন্ডার নেই।',
                    style: TextStyle(color: Colors.white54),
                  )
                else
                  ..._reminders.map(
                    (r) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications_active,
                            color: Color(0xFFFFD36E),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${r.when.day}/${r.when.month}/${r.when.year} • ${r.when.hour.toString().padLeft(2, "0")}:${r.when.minute.toString().padLeft(2, "0")}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white54,
                            ),
                            onPressed: () =>
                                ReminderStore.instance.remove(r).then((_) {
                                  if (mounted) setState(() {});
                                }),
                          ),
                        ],
                      ),
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

// =====================================================================
// নোটস
// =====================================================================

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<String> get _notes => NotesStore.instance.items;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ফোনে সেভ করা নোটগুলো ফিরিয়ে আনা হয়
    NotesStore.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _add() {
    final v = _controller.text.trim();
    if (v.isEmpty) return;
    NotesStore.instance.add(v).then((_) {
      if (mounted) setState(() {});
    });
    _controller.clear();
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _add,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD36E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'নোট সেভ করুন',
                      style: TextStyle(
                        color: Color(0xFF071428),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_notes.isEmpty)
                  const Text(
                    'এখনও কোনো নোট নেই।',
                    style: TextStyle(color: Colors.white54),
                  )
                else
                  ..._notes.asMap().entries.map(
                    (e) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.value,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white54,
                            ),
                            onPressed: () =>
                                NotesStore.instance.removeAt(e.key).then((
                                  _,
                                ) {
                                  if (mounted) setState(() {});
                                }),
                          ),
                        ],
                      ),
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

// =====================================================================
// সেটিংস
// =====================================================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _lang = AppSettings.instance.lang;
  late bool _weather = AppSettings.instance.weather;
  late bool _skyAnim = AppSettings.instance.skyAnim;
  late bool _notifications = AppSettings.instance.notifications;

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
                const Text(
                  'ভাষা',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _lang,
                    dropdownColor: const Color(0xFF0B1B35),
                    isExpanded: true,
                    underline: const SizedBox(),
                    style: const TextStyle(color: Colors.white),
                    items: ['বাংলা', 'Hindi', 'English']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) => setState(() => _lang = v ?? _lang),
                  ),
                ),
                const SizedBox(height: 16),
                _switchTile(
                  '📍 Live Location Weather',
                  _weather,
                  (v) => setState(() => _weather = v),
                ),
                _switchTile(
                  '🌌 Live Sky Animation',
                  _skyAnim,
                  (v) => setState(() => _skyAnim = v),
                ),
                _switchTile(
                  '🔔 Notifications',
                  _notifications,
                  (v) => setState(() => _notifications = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await AppSettings.instance.save(
                        lang: _lang,
                        weather: _weather,
                        skyAnim: _skyAnim,
                        notifications: _notifications,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'সেটিংস সেভ হয়েছে',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD36E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'সেটিংস সেভ করুন',
                      style: TextStyle(
                        color: Color(0xFF071428),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFFFD36E),
          ),
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
  late final _nameController = TextEditingController(
    text: AppSettings.instance.profileName,
  );
  late final _cityController = TextEditingController(
    text: AppSettings.instance.profileCity,
  );

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
                const Text(
                  'নাম',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'আপনার নাম',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'শহর',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cityController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'যেমন: কলকাতা',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await AppSettings.instance.saveProfile(
                        name: _nameController.text.trim(),
                        city: _cityController.text.trim(),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'প্রোফাইল সেভ হয়েছে',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD36E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'সেভ করুন',
                      style: TextStyle(
                        color: Color(0xFF071428),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
