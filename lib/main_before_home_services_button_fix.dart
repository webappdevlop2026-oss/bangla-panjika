import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data' show Uint8List;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  await NotificationService.instance.init();
  await HomeWidgetService.updateWidget();
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
  static const _kEveningLamp = 'evening_lamp_reminder';
  static const _kDeviceId = 'device_id';
  static const _kPremium = 'is_premium';
  static const _kPremiumExpiry = 'premium_expiry';
  // নাম দেখে "প্রথম ইনস্টল" মনে হলেও আসলে এটা এখন "ট্রায়াল অ্যাক্টিভেশন"
  // সময় — ফ্রি-ট্রায়াল ফর্ম (নাম/জন্ম তারিখ-সময়/ঠিকানা) পূরণ করলে তবেই
  // এটা সেট হয়, শুধু অ্যাপ খুললেই না
  static const _kFirstInstall = 'first_install_ts';
  static const _kDob = 'profile_dob';
  static const _kMemberId = 'member_id';
  static const _kAddress = 'profile_address';

  // ট্রায়াল ফর্ম পূরণের দিন থেকে ৩০ দিন গোনা হয়, প্রিমিয়াম আছে কিনা
  // তার সাথে সম্পর্ক নেই
  static const int trialDays = 30;

  SharedPreferences? _prefs;

  String lang = 'বাংলা';
  bool weather = true;
  bool skyAnim = true;
  bool notifications = true;
  String profileName = '';
  String profileCity = '';
  String profileAddress = '';
  // অন করলে প্রতিদিন real সূর্যাস্তের (সন্ধ্যা প্রদীপ জ্বালানোর ঐতিহ্যবাহী
  // সময়ের) সঠিক সময়ে অটো নোটিফিকেশন যাবে — প্রতিদিন সময় পাল্টায় বলে
  // ফিক্সড ঘড়ির সময় নয়, প্রকৃত জ্যোতির্বিদ্যা হিসেব থেকে নেওয়া হয়
  bool eveningLampReminder = false;
  // একবার ভাষা/জেলা/থিম বেছে "শুরু করুন" চাপলে এটা true হয়ে সেভ থাকে —
  // পরের বার অ্যাপ/ওয়েব লিংক খুললে পুরো onboarding আর দেখাতে হয় না,
  // সরাসরি হোম স্ক্রিনে চলে যায়
  bool setupComplete = false;

  // এই ফোনের জন্য একবার তৈরি হয়ে চিরকাল একই থাকা একটা আইডি — লগইন
  // সিস্টেম নেই বলে প্রিমিয়াম সাবস্ক্রিপশন এই আইডি দিয়েই backend-এ
  // চেনা হয়
  String deviceId = '';
  bool isPremium = false;
  DateTime? premiumExpiry;
  DateTime? firstInstallDate;
  DateTime? profileDob;
  // ফ্রি-ট্রায়াল ফর্ম পূরণ করে (নাম+জন্ম তারিখ/সময়+ঠিকানা) ট্রায়াল
  // অ্যাক্টিভ করার সাথে সাথেই একবার জেনারেট হয় (যেমন "BP-2026-A4F9K2")
  // — প্রতিটা ইউজারের জন্য আলাদা, একবার তৈরি হলে প্ল্যান কিনলেও একই
  // আইডি থেকে যায়, শুধু পাশের স্ট্যাটাস "ফ্রি ট্রায়াল" থেকে "সক্রিয়
  // প্ল্যান"-এ বদলায়
  String memberId = '';

  bool get isBangla => lang == 'বাংলা';

  /// প্রিমিয়াম সত্যিই সক্রিয় কিনা — শুধু isPremium true থাকলেই না,
  /// মেয়াদ (premiumExpiry) পার হয়ে গেলে লোকালি-ই এটা false ধরে নেয়
  /// (নেটওয়ার্ক না থাকলেও ভুল করে প্রিমিয়াম দেখাবে না)
  bool get isPremiumActive =>
      isPremium &&
      (premiumExpiry == null || premiumExpiry!.isAfter(DateTime.now()));

  /// ফ্রি-ট্রায়াল ফর্ম (নাম/জন্ম তারিখ-সময়/ঠিকানা) পূরণ করে ট্রায়াল
  /// অ্যাক্টিভ করা হয়েছে কিনা — না করলে ৩০ দিনের গোনাও শুরু হয় না
  bool get trialActivated => firstInstallDate != null;

  /// ফ্রি ট্রায়ালের কত দিন বাকি (এখনো অ্যাক্টিভই না হলে পুরো ৩০ দিন
  /// দেখানো হয় — "শুরু করলে এতদিন পাবেন" বোঝাতে, ০ হলে ট্রায়াল শেষ)
  int get trialDaysLeft {
    if (firstInstallDate == null) return trialDays;
    final passed = DateTime.now().difference(firstInstallDate!).inDays;
    final left = trialDays - passed;
    return left < 0 ? 0 : left;
  }

  bool get inTrialPeriod => trialActivated && trialDaysLeft > 0;

  /// "প্রিমিয়াম-এক্সক্লুসিভ" ফিচারগুলো (কুষ্ঠি চার্ট, PDF এক্সপোর্ট,
  /// ক্লাউড ব্যাকআপ, জ্যোতিষী বুকিং) খোলা রাখার একমাত্র শর্ত — হয় ফ্রি
  /// ট্রায়াল এখনো চলছে, নয়তো আসল প্রিমিয়াম সাবস্ক্রিপশন সক্রিয়
  bool get hasPremiumAccess => isPremiumActive || inTrialPeriod;

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
    eveningLampReminder = p.getBool(_kEveningLamp) ?? false;
    isPremium = p.getBool(_kPremium) ?? false;
    final expiryMs = p.getInt(_kPremiumExpiry);
    premiumExpiry = expiryMs != null
        ? DateTime.fromMillisecondsSinceEpoch(expiryMs)
        : null;
    memberId = p.getString(_kMemberId) ?? '';
    profileAddress = p.getString(_kAddress) ?? '';
    final dobMs = p.getInt(_kDob);
    profileDob = dobMs != null
        ? DateTime.fromMillisecondsSinceEpoch(dobMs)
        : null;
    // একবারই তৈরি হয় — এরপর যতবার অ্যাপ খোলা হোক, একই আইডি থাকে, তাই
    // backend-এ এই ফোনের সাবস্ক্রিপশন সবসময় চেনা যাবে
    deviceId = p.getString(_kDeviceId) ?? '';
    if (deviceId.isEmpty) {
      deviceId = _generateDeviceId();
      await p.setString(_kDeviceId, deviceId);
    }
    // ফ্রি-ট্রায়াল ফর্ম আগে থেকে পূরণ করা থাকলে (activateTrial() আগে
    // ডাকা হয়ে থাকলে) সেই সময়টাই লোড হয় — অ্যাপ চালু করলেই এখানে
    // নিজে থেকে কিছু সেট করা হয় না, ফর্ম পূরণ না করলে ট্রায়াল শুরুই হয় না
    final installMs = p.getInt(_kFirstInstall);
    if (installMs != null) {
      firstInstallDate = DateTime.fromMillisecondsSinceEpoch(installMs);
    }
    final d = p.getString(_kDistrict);
    if (d != null) AppLocation.district = d;
    notifyListeners();
    // আগে থেকে অন করা থাকলে অ্যাপ চালু হওয়ার সাথে সাথেই আগামী কিছুদিনের
    // সন্ধ্যা প্রদীপ নোটিফিকেশন (real সূর্যাস্ত সময় দিয়ে) নতুন করে সেট
    // করা হয়, যাতে তালিকা কখনো শেষ/পুরনো হয়ে না যায়
    if (eveningLampReminder && notifications) {
      await NotificationService.instance.scheduleEveningLampReminders();
    }
  }

  /// টাইমস্ট্যাম্প + র‍্যান্ডম সংখ্যা মিশিয়ে একটা মোটামুটি-ইউনিক আইডি
  /// বানায় — ক্রিপ্টোগ্রাফিক UUID নয়, কিন্তু এই অ্যাপের জন্য (একটা
  /// ফোনকে backend-এ চেনা) এটাই যথেষ্ট
  String _generateDeviceId() {
    final rnd = math.Random();
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = List.generate(
      8,
      (_) => '0123456789abcdefghijklmnopqrstuvwxyz'[rnd.nextInt(36)],
    ).join();
    return '$ts$rand';
  }

  /// ফ্রি-ট্রায়াল ফর্মে নাম/জন্ম তারিখ-সময়/ঠিকানা দিয়ে "ফ্রি ট্রায়াল শুরু
  /// করুন" চাপলে ডাকা হয় — এখান থেকেই ৩০ দিনের গোনা শুরু হয় আর সাথে
  /// সাথেই একটা সদস্য আইডি জেনারেট হয় (প্ল্যান কেনার জন্য অপেক্ষা করতে
  /// হয় না)। একবার অ্যাক্টিভ হয়ে গেলে আবার ডাকলেও পুরনো তারিখ/আইডিই
  /// থেকে যায় — বারবার রিসেট করা যায় না।
  Future<void> activateTrial({
    required String name,
    required DateTime dob,
    required String address,
  }) async {
    profileName = name;
    profileDob = dob;
    profileAddress = address;
    final p = _prefs ??= await SharedPreferences.getInstance();
    await p.setString(_kName, name);
    await p.setInt(_kDob, dob.millisecondsSinceEpoch);
    await p.setString(_kAddress, address);
    if (firstInstallDate == null) {
      firstInstallDate = DateTime.now();
      await p.setInt(_kFirstInstall, firstInstallDate!.millisecondsSinceEpoch);
    }
    if (memberId.isEmpty) {
      memberId = _generateMemberId();
      await p.setString(_kMemberId, memberId);
    }
    notifyListeners();
  }

  /// পেমেন্ট backend থেকে verify হয়ে "সফল" ফিরে এলে ডাকা হয় — লোকালি
  /// প্রিমিয়াম চিহ্নিত করে সেভ করে রাখে (backend-এর status এন্ডপয়েন্ট
  /// দিয়েও পরে যাচাই করা যায়, নেটওয়ার্ক না থাকলে এই লোকাল কপিটাই ব্যবহার হয়)
  Future<void> activatePremium(DateTime expiresAt) async {
    isPremium = true;
    premiumExpiry = expiresAt;
    final p = _prefs ??= await SharedPreferences.getInstance();
    await p.setBool(_kPremium, true);
    await p.setInt(_kPremiumExpiry, expiresAt.millisecondsSinceEpoch);
    // প্রথমবার প্ল্যান কেনার সময়ই একবার মেম্বার আইডি জেনারেট হয় — এরপর
    // মেয়াদ বাড়ালে/রিনিউ করলেও একই আইডি থেকে যায়, নতুন করে বদলায় না
    if (memberId.isEmpty) {
      memberId = _generateMemberId();
      await p.setString(_kMemberId, memberId);
    }
    notifyListeners();
  }

  /// "BP-YYYY-XXXXXX" ফরম্যাটে প্রতিটা প্রিমিয়াম ইউজারের জন্য আলাদা একটা
  /// রেফারেন্স আইডি — সাপোর্ট/প্রোফাইলে দেখানোর জন্য, backend-এর কোনো
  /// আসল সাবস্ক্রিপশন রেকর্ডের বদলি নয় (সেটা device_id দিয়েই হয়)
  String _generateMemberId() {
    final rnd = math.Random();
    final year = DateTime.now().year;
    final code = List.generate(
      6,
      (_) => '0123456789ABCDEFGHJKLMNPQRSTUVWXYZ'[rnd.nextInt(35)],
    ).join();
    return 'BP-$year-$code';
  }

  /// backend থেকে status চেক করে লোকাল অবস্থা আপডেট করে (মেয়াদ শেষ হয়ে
  /// গেলে এখানেই ধরা পড়বে)
  Future<void> applyPremiumStatus({
    required bool active,
    DateTime? expiresAt,
  }) async {
    isPremium = active;
    premiumExpiry = expiresAt;
    final p = _prefs ??= await SharedPreferences.getInstance();
    await p.setBool(_kPremium, active);
    if (expiresAt != null) {
      await p.setInt(_kPremiumExpiry, expiresAt.millisecondsSinceEpoch);
    }
    if (active && memberId.isEmpty) {
      memberId = _generateMemberId();
      await p.setString(_kMemberId, memberId);
    }
    notifyListeners();
  }

  /// "সন্ধ্যা প্রদীপ" অটো-রিমাইন্ডার অন/অফ — অন করলেই প্রতিদিন real সূর্যাস্তের
  /// সময়ে (মানুষ চিরাচরিতভাবে যে সময় সন্ধ্যা দেয়) নোটিফিকেশন যাবে, অফ
  /// করলে সব বাতিল হয়ে যাবে
  Future<void> saveEveningLampReminder(bool value) async {
    eveningLampReminder = value;
    final p = _prefs ??= await SharedPreferences.getInstance();
    await p.setBool(_kEveningLamp, value);
    if (value) {
      await NotificationService.instance.scheduleEveningLampReminders();
    } else {
      await NotificationService.instance.cancelEveningLampReminders();
    }
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
      if (eveningLampReminder) {
        await NotificationService.instance.scheduleEveningLampReminders();
      }
    }
    notifyListeners();
  }

  Future<void> saveDistrict(String district) async {
    AppLocation.select(district);
    final p = _prefs ??= await SharedPreferences.getInstance();
    await p.setString(_kDistrict, AppLocation.district);
    notifyListeners();
  }

  Future<void> saveProfile({
    required String name,
    required String city,
    DateTime? dob,
    String? address,
  }) async {
    profileName = name;
    profileCity = city;
    profileDob = dob;
    if (address != null) profileAddress = address;
    final p = _prefs ??= await SharedPreferences.getInstance();
    await p.setString(_kName, name);
    await p.setString(_kCity, city);
    if (address != null) await p.setString(_kAddress, address);
    if (dob != null) {
      await p.setInt(_kDob, dob.millisecondsSinceEpoch);
    } else {
      await p.remove(_kDob);
    }
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

/// স্থানীয় মন্দির/পূজার সময়সূচি — ব্যবহারকারী নিজে যোগ করেন, ফোনে সেভ
/// থাকে এবং চাইলে নির্ধারিত সময়ে নোটিফিকেশন রিমাইন্ডারও সেট হয়
class TempleEvent {
  String temple; // মন্দির/স্থানের নাম
  String pujaName; // পূজার নাম
  DateTime when;
  bool reminderOn;
  final int id;
  TempleEvent({
    required this.temple,
    required this.pujaName,
    required this.when,
    this.reminderOn = true,
    int? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.remainder(0x7FFFFFFF);
}

class TempleStore {
  TempleStore._();
  static final TempleStore instance = TempleStore._();
  static const _key = 'temple_events';

  final List<TempleEvent> items = [];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_key) ?? const [];
    items
      ..clear()
      ..addAll(
        raw.map((e) {
          final m = jsonDecode(e) as Map<String, dynamic>;
          return TempleEvent(
            temple: m['temple'] as String,
            pujaName: m['pujaName'] as String,
            when: DateTime.fromMillisecondsSinceEpoch(m['when'] as int),
            reminderOn: (m['reminderOn'] as bool?) ?? true,
            id: m['id'] as int,
          );
        }),
      );
    items.sort((a, b) => a.when.compareTo(b.when));
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _key,
      items
          .map(
            (e) => jsonEncode({
              'id': e.id,
              'temple': e.temple,
              'pujaName': e.pujaName,
              'when': e.when.millisecondsSinceEpoch,
              'reminderOn': e.reminderOn,
            }),
          )
          .toList(),
    );
  }

  Future<void> add(TempleEvent event) async {
    items.add(event);
    items.sort((a, b) => a.when.compareTo(b.when));
    await _persist();
    if (event.reminderOn) {
      await NotificationService.instance.scheduleGeneric(
        event.id,
        '🛕 ${event.temple}',
        '${event.pujaName} — আজ',
        event.when.subtract(const Duration(hours: 1)),
      );
    }
  }

  Future<void> remove(TempleEvent event) async {
    items.remove(event);
    await _persist();
    await NotificationService.instance.cancel(event.id);
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

  // "সন্ধ্যা প্রদীপ" রিমাইন্ডারের জন্য আলাদা reserved id রেঞ্জ, যাতে
  // ব্যবহারকারীর হাতে-বসানো রিমাইন্ডারের id-র সাথে কখনো সংঘর্ষ না হয়
  static const int _eveningLampBaseId = 900000;
  static const int _eveningLampDays = 30;

  /// প্রতিদিন real সূর্যাস্তের সময় অনুযায়ী (মানুষ চিরাচরিতভাবে যে সময়
  /// সন্ধ্যা প্রদীপ জ্বালায়) আগামী ৩০ দিনের নোটিফিকেশন শিডিউল করে। প্রতিদিন
  /// সূর্যাস্তের প্রকৃত সময় আলাদা হয় বলে কোনো ফিক্সড ঘড়ির সময় নয় —
  /// প্রতিটা দিনের জন্য আলাদাভাবে জ্যোতির্বিদ্যা হিসেব থেকে বের করা হয়
  /// (ব্যবহারকারীর বেছে নেওয়া/GPS লোকেশন অনুযায়ী)।
  Future<void> scheduleEveningLampReminders() async {
    await init();
    if (kIsWeb) return;
    await cancelEveningLampReminders();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < _eveningLampDays; i++) {
      final day = today.add(Duration(days: i));
      DateTime sunset;
      try {
        sunset = PanchangCalculator.sunTimes(
          day,
          lat: AppLocation.lat,
          lon: AppLocation.lon,
        ).sunset;
      } catch (_) {
        continue;
      }
      if (!sunset.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        _eveningLampBaseId + i,
        '🪔 সন্ধ্যা প্রদীপ',
        'সন্ধ্যা নেমে এসেছে — প্রদীপ জ্বালানোর সময় হয়েছে',
        tz.TZDateTime.from(sunset, tz.local),
        const NotificationDetails(
          android: _androidDetails,
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// মন্দির/পূজার সময়সূচির মতো কাস্টম টাইটেল-সহ নোটিফিকেশনের জন্য —
  /// রিমাইন্ডারের মতো একই সাধারণ মেকানিজম, শুধু নিজস্ব শিরোনাম দেওয়া যায়
  Future<void> scheduleGeneric(
    int id,
    String title,
    String body,
    DateTime when,
  ) async {
    await init();
    if (kIsWeb) return;
    if (!when.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelEveningLampReminders() async {
    await init();
    if (kIsWeb) return;
    for (int i = 0; i < _eveningLampDays; i++) {
      await _plugin.cancel(_eveningLampBaseId + i);
    }
  }
}

// =====================================================================
// টেক্সট-টু-স্পিচ — আজকের পঞ্চাঙ্গ বাংলায় পড়ে শোনানোর জন্য
// =====================================================================

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool isSpeaking = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      // বাংলা ভয়েস না থাকলে ডিভাইস স্বয়ংক্রিয়ভাবে কাছাকাছি একটা ভাষা
      // বেছে নেয় (যেমন হিন্দি/ইংরেজি উচ্চারণে বাংলা লেখা পড়া)
      await _tts.setLanguage('bn-BD');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
    } catch (_) {
      // ভাষা সেট না হলেও ডিফল্ট ভয়েস দিয়ে পড়ার চেষ্টা চলবে
    }
    _ready = true;
  }

  Future<void> speak(String text) async {
    await _ensureReady();
    isSpeaking = true;
    try {
      // ওয়েবে ব্রাউজারের নিজস্ব Web Speech API ব্যবহার হয় — সব ব্রাউজারে
      // বাংলা ভয়েস না-ও থাকতে পারে, তখন ব্রাউজার যা পায় সেই ভয়েস দিয়েই
      // পড়ার চেষ্টা করে, একদম চুপ থাকে না
      await _tts.speak(text);
    } catch (_) {
      isSpeaking = false;
    }
  }

  Future<void> stop() async {
    isSpeaking = false;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

// =====================================================================
// হোম স্ক্রিন উইজেট — home_widget প্যাকেজ দিয়ে Android লঞ্চারে আজকের
// বাংলা তারিখ/তিথি দেখানো। অ্যাপ চালু হওয়ার সময় ও হোম স্ক্রিনে ঢোকার
// সময় ডেটা রিফ্রেশ হয়; Android নিজে থেকেও প্রতি কয়েক ঘন্টায় উইজেট
// রিফ্রেশ করে (widget_info.xml-এ updatePeriodMillis অনুযায়ী)।
// =====================================================================

class HomeWidgetService {
  static const String _providerName = 'PanjikaWidgetProvider';

  static Future<void> updateWidget() async {
    if (kIsWeb) return;
    try {
      final now = DateTime.now();
      final info = BengaliDateUtil.monthInfoFor(now);
      final bengaliDay = now.difference(info.start).inDays + 1;
      final tithi = PanchangCalculator.tithiFor(now);
      await HomeWidget.saveWidgetData<String>(
        'bengali_date',
        '${bnNum(bengaliDay)} ${info.name} ${bnNum(info.year)}',
      );
      await HomeWidget.saveWidgetData<String>(
        'tithi_text',
        '${tithi.paksha} পক্ষ • ${tithi.name}',
      );
      await HomeWidget.updateWidget(
        name: _providerName,
        androidName: _providerName,
      );
    } catch (_) {
      // উইজেট আপডেট ব্যর্থ হলেও বাকি অ্যাপ স্বাভাবিক চলবে
    }
  }
}

// =====================================================================
// বিজ্ঞাপন — google_mobile_ads, প্রিমিয়াম ইউজারদের জন্য ও ওয়েবে বন্ধ থাকে
// =====================================================================

class AdService {
  AdService._();
  static final AdService instance = AdService._();
  bool _initialized = false;

  // এগুলো Google-এর অফিসিয়াল টেস্ট Ad Unit ID — সবসময় নিরাপদে টেস্ট
  // বিজ্ঞাপন দেখাবে, কোনো টাকা তৈরি করে না। নিজের AdMob একাউন্ট থেকে আসল
  // ID বসালে তখন থেকে আসল বিজ্ঞাপন ও আসল আয় শুরু হবে (README.md দেখুন)
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (_) {
      // বিজ্ঞাপন SDK শুরু না হলেও বাকি অ্যাপ স্বাভাবিক চলবে
    }
  }

  /// প্রিমিয়াম ইউজার বা ওয়েবে বিজ্ঞাপন দেখানো হয় না
  bool get shouldShowAds => !kIsWeb && !AppSettings.instance.isPremium;
}

/// হোম স্ক্রিনে দেখানোর জন্য ব্যানার বিজ্ঞাপন — লোড না হলে বা প্রিমিয়াম
/// থাকলে কিছুই দেখায় না, কোনো জায়গা নেয় না
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});
  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AdService.instance.shouldShowAds) return;
    await AdService.instance.init();
    if (!mounted || kIsWeb) return;
    final ad = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    _banner = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.instance.shouldShowAds || !_loaded || _banner == null) {
      return const SizedBox.shrink();
    }
    return Container(
      alignment: Alignment.center,
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: AdWidget(ad: _banner!),
    );
  }
}

// =====================================================================
// নিজস্ব Laravel backend-এর ঠিকানা — প্রিমিয়াম পেমেন্ট, ক্লাউড ব্যাকআপ,
// জ্যোতিষী তালিকা/মন্দির ইভেন্ট/ঘোষণা — সবকিছু এই একই backend থেকে আসে।
// এখন এটা ডেভেলপমেন্টের জন্য লোকাল সার্ভারে (Laragon) পয়েন্ট করা আছে —
// আসল হোস্টিং হয়ে গেলে নিচের 'hosted' URL-টা বদলে দিলেই পুরো অ্যাপ সেটার
// সাথে যুক্ত হয়ে যাবে, আর কোথাও কিছু বদলাতে হবে না।
// =====================================================================

class BackendConfig {
  // ⚠️ হোস্টিং রেডি হলে এটা বদলে দিন, যেমন: 'https://api.banglapanjika.com'
  static const String hosted = '';

  static String get baseUrl {
    if (hosted.isNotEmpty) return hosted;
    // হোস্টিং এখনো নেই — টেস্টিংয়ের জন্য পিসিতে চলা লোকাল Laravel সার্ভার
    // ব্যবহার হচ্ছে। ওয়েবে (একই পিসির ব্রাউজারে) 127.0.0.1 কাজ করবে, কিন্তু
    // ফোনে টেস্ট করতে হলে ফোন ও পিসি একই WiFi-তে থাকতে হবে এবং এখানে
    // পিসির লোকাল নেটওয়ার্ক IP বসাতে হবে (Laragon-এর উইন্ডোর উপরে দেখায়,
    // যেমন 172.18.100.126) — নেটওয়ার্ক বদলালে এই IP-ও বদলাতে পারে।
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return 'http://172.18.100.126:8000';
  }
}

/// অ্যাপের Play Store লিংক — এখনো খালি (অ্যাপ এখনো পাবলিশ হয়নি)। Play
/// Store-এ পাবলিশ হওয়ার পর এখানে আসল লিংক বসিয়ে দিলে "🎉 উৎসব পোস্টার
/// মেকার"-এর পোস্টার ও শেয়ার-করা টেক্সটে অ্যাপ ডাউনলোডের লিংক/ব্যাজ
/// এমনিতেই দেখানো শুরু হয়ে যাবে — কোথাও আর কিছু বদলাতে হবে না। খালি
/// থাকা অবস্থায় এই অংশটা চুপচাপ লুকানো থাকে (ভাঙা/placeholder লিংক
/// দেখায় না)।
class AppLinks {
  // ⚠️ পাবলিশ হওয়ার পর এখানে বসান, যেমন:
  // 'https://play.google.com/store/apps/details?id=com.example.bangla_panjika_native'
  static const String playStore = '';
}

/// ক্লাউড ব্যাকআপ — রিমাইন্ডার ও নোটস নিজস্ব Laravel + MySQL backend-এ
/// সেভ রাখে (কোনো Firebase/থার্ড-পার্টি একাউন্ট লাগে না, backend চালু
/// থাকলেই কাজ করবে)।
class CloudBackupService {
  CloudBackupService._();
  static final CloudBackupService instance = CloudBackupService._();

  /// null মানে সফল হয়েছে, নাহলে দেখানোর জন্য এরর মেসেজ ফেরত দেয়
  Future<String?> backupNow() async {
    try {
      final deviceId = AppSettings.instance.deviceId;
      final res = await http
          .post(
            Uri.parse('${BackendConfig.baseUrl}/api/backup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'device_id': deviceId,
              'data': {
                'reminders': ReminderStore.instance.items
                    .map(
                      (r) => {
                        'id': r.id,
                        'text': r.text,
                        'when': r.when.millisecondsSinceEpoch,
                      },
                    )
                    .toList(),
                'notes': NotesStore.instance.items,
              },
            }),
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200 || data['success'] != true) {
        return data['message']?.toString() ?? 'ব্যাকআপ ব্যর্থ হয়েছে';
      }
      final p = await SharedPreferences.getInstance();
      await p.setInt(
        'last_cloud_backup',
        DateTime.now().millisecondsSinceEpoch,
      );
      return null;
    } catch (e) {
      return 'ব্যাকআপ সার্ভারের সাথে যোগাযোগ করা যায়নি — ইন্টারনেট/সার্ভার চেক করুন';
    }
  }

  Future<String?> restoreNow() async {
    try {
      final deviceId = AppSettings.instance.deviceId;
      final res = await http
          .get(Uri.parse('${BackendConfig.baseUrl}/api/backup/$deviceId'))
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200 || data['success'] != true) {
        return data['message']?.toString() ?? 'কোনো ব্যাকআপ পাওয়া যায়নি';
      }
      final backupData = data['data'] as Map<String, dynamic>;
      final remindersRaw = (backupData['reminders'] as List?) ?? const [];
      ReminderStore.instance.items
        ..clear()
        ..addAll(
          remindersRaw.map(
            (m) => ReminderItem(
              m['text'] as String,
              DateTime.fromMillisecondsSinceEpoch(m['when'] as int),
              id: m['id'] as int,
            ),
          ),
        );
      await ReminderStore.instance._persist();
      final notesRaw = ((backupData['notes'] as List?) ?? const [])
          .cast<String>();
      NotesStore.instance.items
        ..clear()
        ..addAll(notesRaw);
      await NotesStore.instance._persist();
      return null;
    } catch (e) {
      return 'ব্যাকআপ সার্ভারের সাথে যোগাযোগ করা যায়নি — ইন্টারনেট/সার্ভার চেক করুন';
    }
  }

  Future<DateTime?> lastBackupAt() async {
    final p = await SharedPreferences.getInstance();
    final ms = p.getInt('last_cloud_backup');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }
}

// =====================================================================
// প্রিমিয়াম পেমেন্ট — Laravel + Razorpay backend-এর সাথে যোগাযোগ
// =====================================================================

/// প্রিমিয়াম প্ল্যানের তথ্য — দাম শুধু দেখানোর জন্য (আসল দাম backend
/// নির্ধারণ করে, এখান থেকে বদলালে backend-এও বদলাতে হবে যাতে দুটো মিলে)
class PremiumPlan {
  final String id; // 'monthly' / 'yearly'
  final String label;
  final String priceLabel;
  const PremiumPlan(this.id, this.label, this.priceLabel);
}

const List<PremiumPlan> premiumPlans = [
  PremiumPlan('monthly', 'মাসিক প্রিমিয়াম', '₹৪৯ / মাস'),
  PremiumPlan('yearly', 'বার্ষিক প্রিমিয়াম', '₹৪৯৯ / বছর'),
];

/// Laravel backend-এর সাথে পেমেন্ট flow-এর নেটওয়ার্ক কল — অর্ডার তৈরি,
/// ভেরিফাই ও স্ট্যাটাস চেক। backend এখনো হোস্ট না হলে [baseUrl] খালি
/// থাকবে এবং প্রতিটা কল স্পষ্ট এরর মেসেজ দেবে (নীরবে ক্র্যাশ করবে না)।
class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  static String get baseUrl => BackendConfig.baseUrl;

  bool get isConfigured => baseUrl.isNotEmpty;

  Future<Map<String, dynamic>> createOrder(String plan) async {
    if (!isConfigured) {
      throw Exception(
        'Backend এখনো সেট করা হয়নি — PaymentService.baseUrl এ আপনার '
        'Laravel সার্ভারের URL বসান',
      );
    }
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/payment/create-order'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'device_id': AppSettings.instance.deviceId,
            'plan': plan,
          }),
        )
        .timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['message']?.toString() ?? 'অর্ডার তৈরি ব্যর্থ হয়েছে',
      );
    }
    return data;
  }

  Future<DateTime> verify({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/payment/verify'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'device_id': AppSettings.instance.deviceId,
            'razorpay_order_id': orderId,
            'razorpay_payment_id': paymentId,
            'razorpay_signature': signature,
          }),
        )
        .timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? 'যাচাই ব্যর্থ হয়েছে');
    }
    return DateTime.parse(data['expires_at'].toString());
  }

  Future<void> refreshStatus() async {
    if (!isConfigured || AppSettings.instance.deviceId.isEmpty) return;
    try {
      final res = await http
          .get(
            Uri.parse(
              '$baseUrl/api/subscription/status?device_id=${AppSettings.instance.deviceId}',
            ),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] != true) return;
      await AppSettings.instance.applyPremiumStatus(
        active: data['is_premium'] == true,
        expiresAt: data['expires_at'] != null
            ? DateTime.tryParse(data['expires_at'].toString())
            : null,
      );
    } catch (_) {
      // নেটওয়ার্ক না থাকলে যা লোকালি সেভ আছে তাই ব্যবহার হবে
    }
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
        // readability আপডেট: পুরো অ্যাপে এখন Noto Sans Bengali ফন্ট
        // ব্যবহার হচ্ছে (ফোনভেদে ডিফল্ট বাংলা ফন্ট আলাদা/অস্পষ্ট দেখাতে
        // পারত, এটা সব ফোনে একই রকম পরিষ্কার ও মোটা দেখাবে)
        theme: ThemeData(useMaterial3: true, fontFamily: 'NotoSansBengali'),
        // ফোনের সিস্টেম ফন্ট-সাইজ যতই ছোট সেট করা থাকুক (কম বয়সীদের ফোনে
        // এমন থাকতে পারে), অ্যাপের লেখা কখনো ডিজাইন করা সাইজের চেয়ে ছোট
        // দেখাবে না (readability floor) — আবার কেউ সিস্টেম ফন্ট অনেক বড়
        // করে রাখলেও ১.৩ গুণের বেশি বড় হবে না, যাতে কার্ড/বাটনের লেআউট
        // ভেঙে না যায়
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(
                minScaleFactor: 1.0,
                maxScaleFactor: 1.3,
              ),
            ),
            child: child!,
          );
        },
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
    Color(0xFF01030A),
    Color(0xFF050D1E),
    Color(0xFF071228),
    Color(0xFF03060F),
  ];
  // অমাবস্যার রাত — চাঁদের আলো একদমই নেই বলে বাস্তবে আকাশ সবচেয়ে গাঢ়/কালো
  // দেখায়, শুধু তারাগুলো ফুটে থাকে
  static const List<Color> _amavasyaNight = [
    Color(0xFF000000),
    Color(0xFF010103),
    Color(0xFF020208),
    Color(0xFF000000),
  ];
  static const List<Color> _dawnDusk = [
    Color(0xFF030718),
    Color(0xFF0B1430),
    Color(0xFF4A2F5E),
    Color(0xFF10142A),
  ];
  static const List<Color> _sunriseSunset = [
    Color(0xFF040A1C),
    Color(0xFF0E1E42),
    Color(0xFFC2603A),
    Color(0xFF2A1428),
  ];
  static const List<Color> _morningEvening = [
    Color(0xFF04091A),
    Color(0xFF0C1B3C),
    Color(0xFF6E86B8),
    Color(0xFF14203A),
  ];
  static const List<Color> _midday = [
    Color(0xFF04081A),
    Color(0xFF0A1735),
    Color(0xFF2E5F96),
    Color(0xFF0C1730),
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
    final nowMarked = now.toUtc().add(const Duration(hours: 5, minutes: 30));

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
        colors = _lerpColors(
          _morningEvening,
          _sunriseSunset,
          (p - 0.88) / 0.12,
        );
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

/// সৌরজগতের গ্রহ — সূর্য/পৃথিবী বাদে বাকি ৭টি — মহাকাশ ব্যাকগ্রাউন্ডে
/// দেখানোর জন্য প্রতিটির বাস্তব রং (আনুমানিক) ও গড় আপাত উজ্জ্বলতা
/// (mean apparent magnitude — কম মান = বেশি উজ্জ্বল)। উজ্জ্বলতা real-time
/// phase-angle হিসেব করে বদলায় না (তার জন্য অতিরিক্ত জটিল সূত্র লাগত),
/// শুধু ডটের আকার/আভা কতটা প্রকট হবে তার একটা সূক্ষ্ম ইঙ্গিত দিতে
/// ব্যবহৃত হয় — কোনো গ্রহই বাস্তব স্কেলে আঁকা হয় না, শুধু readability-র
/// জন্য subtle পার্থক্য রাখা হয়েছে।
class _PlanetVisual {
  final String key;
  final Color color;
  final double meanMagnitude;
  const _PlanetVisual(this.key, this.color, this.meanMagnitude);
}

const List<_PlanetVisual> _solarSystemPlanets = [
  _PlanetVisual('mercury', Color(0xFFC9C0B3), -0.4),
  _PlanetVisual('venus', Color(0xFFF5E7C8), -4.2),
  _PlanetVisual('mars', Color(0xFFD8683E), -0.5),
  _PlanetVisual('jupiter', Color(0xFFE0C199), -2.2),
  _PlanetVisual('saturn', Color(0xFFE3D3A0), 0.5),
  _PlanetVisual('uranus', Color(0xFF9FE0E0), 5.7),
  _PlanetVisual('neptune', Color(0xFF4169C9), 7.8),
];

/// নবগ্রহ — জ্যোতিষশাস্ত্রের ৯টি গ্রহ, প্রতিটি নিজস্ব রঙে কক্ষপথে ঘুরবে।
class CosmicBackground extends StatefulWidget {
  final Widget child;
  const CosmicBackground({super.key, required this.child});
  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with TickerProviderStateMixin, RouteAware {
  // পুরো অ্যাপের ব্যাকগ্রাউন্ডে লাইভ বৃষ্টির অ্যানিমেশনের জন্য আলাদা কন্ট্রোলার
  late final AnimationController _rainController;
  // গ্রহগুলোর ক্রমাগত, মসৃণ কক্ষপথ-চলাচলের "heartbeat" — প্রতি ফ্রেমে rebuild
  // করায়। অবস্থান কখনো আলাদাভাবে extrapolate/sync করা হয় না — প্রতি
  // ফ্রেমেই real astronomical সূত্র (celestialAltAz) সরাসরি ডাকা হয়, শুধু
  // তাতে দেওয়া সময়টা "accelerated ভার্চুয়াল সময়" (নিচে দেখুন) — তাই real
  // হিসেবই সবসময় একমাত্র উৎস, আর resync-এর কোনো ধাপ না থাকায় কোনো
  // sudden jump-ও হয় না, শুধু ধারাবাহিক, দ্রুততর movement দেখা যায়
  late final AnimationController _planetClock;
  // ভার্চুয়াল "accelerated" সময়ের নোঙর — অ্যাপ চালু হওয়ার মুহূর্তে বাস্তব
  // সময়ের সমান করে সেট হয়, তারপর real সময়ের চেয়ে _planetTimeAcceleration
  // গুণ দ্রুত এগোয় — গ্রহের অবস্থান হিসেবের জন্যই শুধু ব্যবহৃত হয়, সূর্যোদয়/
  // অস্ত, পঞ্চাঙ্গ, আবহাওয়া বা আকাশের রং — এসবে কোনো প্রভাব ফেলে না (সেগুলো
  // এখনও প্রকৃত DateTime.now() দিয়েই হিসেব হয়)
  late final DateTime _planetSimAnchor;
  // বাস্তব গতির (~১৫°/ঘন্টা, পৃথিবীর ঘূর্ণনের কারণে) তুলনায় এত ধীর যে
  // real-time-এ কয়েক সেকেন্ডে কোনো নড়াচড়াই চোখে পড়ে না — তাই শুধু
  // দৃশ্যমান করার জন্য সময়টাকে (অবস্থান নয়) বহুগুণ ত্বরান্বিত করা হচ্ছে;
  // এই গতিতে একটা গ্রহের পুরো আকাশ-প্রদক্ষিণ (৩৬০°) লাগে বাস্তবে ~২৪ ঘন্টা,
  // এখানে দেখাতে লাগবে ~৬ মিনিট — তবুও প্রতিটা মুহূর্তের অবস্থান আসল
  // astronomical সূত্র দিয়েই বের করা, কোনো এলোমেলো/কাল্পনিক গতি নয়
  static const double _planetTimeAcceleration = 240.0;
  Timer? _clockTimer;
  SkyPhase _phase = SkyPhase.forTime(DateTime.now());
  bool _isRaining = false;
  bool _routeVisible = true;

  static const Map<String, double> _planetRingDiameter = {
    'mercury': 66,
    'venus': 88,
    'mars': 112,
    'jupiter': 136,
    'saturn': 160,
    'uranus': 184,
    'neptune': 208,
  };

  @override
  void initState() {
    super.initState();
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _planetClock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _planetSimAnchor = DateTime.now();
    _refreshPhase();
    // নির্বাচিত জেলায় সত্যিই এখন বৃষ্টি হচ্ছে কিনা — লাইভ, লোকেশন-ভিত্তিক
    _isRaining = WeatherService.instance.isRaining;
    _syncRainAnim();
    WeatherService.instance.addListener(_onWeatherChanged);
    WeatherService.instance.refresh();
    // ফোনের/ব্রাউজারের real-time GPS লোকেশন — অনুমতি পেলে সূর্যোদয়/অস্ত ও
    // আবহাওয়া ব্যবহারকারীর প্রকৃত জায়গা ধরে হিসেব হবে, না পেলে ম্যানুয়াল
    // জেলাতেই চুপচাপ থাকবে
    LocationService.instance.addListener(_onLocationChanged);
    LocationService.instance.refresh();
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

  void _onLocationChanged() {
    if (!mounted) return;
    // GPS লোকেশন এইমাত্র পাওয়া গেল — সূর্যোদয়/অস্ত ও আবহাওয়া নতুন করে
    // হিসেব হবে সেই real জায়গা ধরে
    _refreshPhase();
    WeatherService.instance.refresh(force: true);
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
    final now = DateTime.now();
    final phase = SkyPhase.forTime(
      now,
      lat: AppLocation.lat,
      lon: AppLocation.lon,
    );

    setState(() {
      _phase = phase;
    });
    // গ্রহের ঘড়ি (accelerated virtual time) চালু/বন্ধ — সেটিংসে Live Sky
    // Animation বন্ধ থাকলে থেমে যাবে, তখন গ্রহ শেষ ফ্রেমের অবস্থানেই স্থির
    // থাকবে (আকাশের রং/সূর্যোদয়-অস্ত ইত্যাদির ওপর এর কোনো প্রভাব নেই)
    if (AppSettings.instance.skyAnim) {
      if (!_planetClock.isAnimating) _planetClock.repeat();
    } else {
      _planetClock.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPush() {
    _syncRainAnim();
  }

  @override
  void didPopNext() {
    setState(() => _routeVisible = true);
    _refreshPhase();
    WeatherService.instance.refresh();
    _syncRainAnim();
  }

  @override
  void didPushNext() {
    _rainController.stop();
    _planetClock.stop();
    setState(() => _routeVisible = false);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _rainController.dispose();
    _planetClock.dispose();
    WeatherService.instance.removeListener(_onWeatherChanged);
    LocationService.instance.removeListener(_onLocationChanged);
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
          // ---- মাঝেমধ্যে উল্কা/শুটিং-স্টার ও কৃত্রিম উপগ্রহের পথ — শুধু
          // আকাশ যথেষ্ট অন্ধকার থাকলে, খুব ঘনঘন নয়, স্ক্রিন আড়ালে গেলে থামে
          Positioned.fill(
            child: _SkyEventsLayer(
              active:
                  _routeVisible &&
                  AppSettings.instance.skyAnim &&
                  _phase.starOpacity > 0.35,
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
                  _buildPlanetsLayer(),
                ],
              ),
            ),
          ),
          // ---- চাঁদ: প্রকৃত আজকের দশা (শুক্ল/কৃষ্ণপক্ষ) অনুযায়ী আলোকিত অংশ
          // বদলায় — অমাবস্যায় ম্লান, পূর্ণিমায় সম্পূর্ণ গোলাকার। পুরোটা
          // যেন স্ক্রিনের ভেতরেই স্পষ্ট দেখা যায় তাই কোনো কিনারায় কাটা
          // পড়ে না এভাবে বসানো হয়েছে।
          Positioned(
            top: 66,
            left: 18,
            child: SizedBox(
              width: 150,
              height: 150,
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

  /// সূর্য বাদে সৌরজগতের বাকি ৭টি গ্রহ — বাস্তব অবস্থান অনুযায়ী শুধু
  /// এখন GPS লোকেশন ও সময়ে দিগন্তের ওপরে থাকা গ্রহগুলোই ধীরে ধীরে ফুটে
  /// ওঠে, বাকিগুলো লুকানো থাকে — কোনো এলোমেলো/জোর করে-সব-দেখানো নেই।
  /// প্রতিটা ফ্রেমে সরাসরি real astronomical সূত্র (celestialAltAz) ডাকা
  /// হয়, শুধু তাতে দেওয়া সময়টা accelerated ভার্চুয়াল সময় — তাই কোনো
  /// আলাদা sync/extrapolation ধাপ নেই, ফলে কোনো sudden jump-ও হয় না।
  Widget _buildPlanetsLayer() {
    return AnimatedBuilder(
      animation: _planetClock,
      builder: (context, _) {
        final realElapsedMs = DateTime.now()
            .difference(_planetSimAnchor)
            .inMilliseconds;
        final virtualTime = _planetSimAnchor.add(
          Duration(
            milliseconds: (realElapsedMs * _planetTimeAcceleration).round(),
          ),
        );
        final sunAlt =
            PanchangCalculator.celestialAltAz(
              'sun',
              virtualTime,
              lat: AppLocation.lat,
              lon: AppLocation.lon,
            )['altitude'] ??
            0.0;
        final duskFactor = ((-sunAlt) / 8.0).clamp(0.0, 1.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            for (final pv in _solarSystemPlanets)
              Container(
                width: _planetRingDiameter[pv.key],
                height: _planetRingDiameter[pv.key],
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
            for (final pv in _solarSystemPlanets)
              _buildPlanetDot(pv, virtualTime, duskFactor),
          ],
        );
      },
    );
  }

  Widget _buildPlanetDot(
    _PlanetVisual pv,
    DateTime virtualTime,
    double duskFactor,
  ) {
    final altAz = PanchangCalculator.celestialAltAz(
      pv.key,
      virtualTime,
      lat: AppLocation.lat,
      lon: AppLocation.lon,
    );
    final altNow = altAz['altitude'] ?? -90.0;
    // দিগন্তের ঠিক ওপরে ওঠার প্রথম ৮° জুড়ে আস্তে আস্তে ফুটে ওঠে — হঠাৎ
    // পপ-আপ/অদৃশ্য হওয়া এড়াতে
    final altFactor = (altNow / 8.0).clamp(0.0, 1.0);
    final vis = (duskFactor * altFactor).clamp(0.0, 1.0);
    if (vis <= 0.01) return const SizedBox.shrink();
    // সরাসরি real azimuth — accelerated ভার্চুয়াল সময়ে হিসেব করা, তাই
    // দিক (direction) সবসময় astronomically সঠিক, শুধু গতিটা দৃশ্যমান
    // মাত্রায় দ্রুত
    final angleDeg = altAz['azimuth'] ?? 0.0;
    final radius = (_planetRingDiameter[pv.key] ?? 100.0) / 2;
    // magnitude যত কম (উজ্জ্বল), ডট তত সামান্য বড়/উজ্জ্বল — বাস্তব স্কেল
    // নয়, শুধু পাঠযোগ্যতার জন্য সূক্ষ্ম ইঙ্গিত
    final sizeHint = (6.0 - pv.meanMagnitude).clamp(2.0, 9.0);
    final azRad = angleDeg * math.pi / 180.0;
    final dx = radius * math.sin(azRad);
    final dy = -radius * math.cos(azRad);
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: vis.clamp(0.0, 1.0),
        child: Container(
          width: sizeHint,
          height: sizeHint,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pv.color,
            boxShadow: [
              BoxShadow(
                color: pv.color.withValues(alpha: 0.65),
                blurRadius: sizeHint * 1.4,
                spreadRadius: 0.6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// মাঝেমধ্যে বাস্তবসম্মত উল্কা (শুটিং স্টার) ও দূরের কৃত্রিম উপগ্রহের
/// সরলরেখার পথ — শুধু আকাশ যথেষ্ট অন্ধকার থাকলে, এলোমেলো সময়ে কিন্তু
/// খুব ঘনঘন নয়, আর সেটিংসে Live Sky Animation বন্ধ থাকলে বা স্ক্রিন
/// আড়ালে গেলে একদমই দেখা যাবে না
class _SkyEventsLayer extends StatefulWidget {
  final bool active;
  const _SkyEventsLayer({required this.active});
  @override
  State<_SkyEventsLayer> createState() => _SkyEventsLayerState();
}

class _SkyEventsLayerState extends State<_SkyEventsLayer>
    with TickerProviderStateMixin {
  Timer? _meteorTimer;
  Timer? _satelliteTimer;
  late final AnimationController _meteorCtrl;
  late final AnimationController _satelliteCtrl;
  final math.Random _rnd = math.Random();
  Offset _meteorStart = const Offset(0.1, 0.1);
  Offset _meteorEnd = const Offset(0.3, 0.3);
  Offset _satStart = const Offset(0, 0.2);
  Offset _satEnd = const Offset(1, 0.35);
  Color _meteorColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _meteorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _satelliteCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    _scheduleIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _SkyEventsLayer old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) _scheduleIfNeeded();
  }

  void _scheduleIfNeeded() {
    _meteorTimer?.cancel();
    _satelliteTimer?.cancel();
    _meteorTimer = null;
    _satelliteTimer = null;
    if (!widget.active) return;
    _scheduleNextMeteor();
    _scheduleNextSatellite();
  }

  void _scheduleNextMeteor() {
    final delay = Duration(seconds: 22 + _rnd.nextInt(38)); // ২২–৬০ সে. এলোমেলো
    _meteorTimer = Timer(delay, () {
      if (!mounted || !widget.active) return;
      _fireMeteor();
    });
  }

  void _scheduleNextSatellite() {
    final delay = Duration(seconds: 40 + _rnd.nextInt(50)); // ৪০–৯০ সে. এলোমেলো
    _satelliteTimer = Timer(delay, () {
      if (!mounted || !widget.active) return;
      _fireSatellite();
    });
  }

  void _fireMeteor() {
    final startX = _rnd.nextDouble() * 0.7 + 0.05;
    final startY = _rnd.nextDouble() * 0.25;
    final angle =
        (_rnd.nextDouble() * 0.5 + 0.2) * math.pi; // তির্যক নিচের দিকে
    const len = 0.28;
    setState(() {
      _meteorStart = Offset(startX, startY);
      _meteorEnd = Offset(
        (startX + len * math.cos(angle)).clamp(0.0, 1.0),
        (startY + len * math.sin(angle)).clamp(0.0, 1.0),
      );
      _meteorColor = _rnd.nextBool() ? Colors.white : const Color(0xFFBFE0FF);
    });
    _meteorCtrl.forward(from: 0).then((_) {
      _meteorCtrl.reset();
      if (mounted) _scheduleNextMeteor();
    });
  }

  void _fireSatellite() {
    final y = 0.08 + _rnd.nextDouble() * 0.3;
    final leftToRight = _rnd.nextBool();
    setState(() {
      _satStart = Offset(leftToRight ? -0.05 : 1.05, y);
      _satEnd = Offset(
        leftToRight ? 1.05 : -0.05,
        y + (_rnd.nextDouble() - 0.5) * 0.08,
      );
    });
    _satelliteCtrl.forward(from: 0).then((_) {
      _satelliteCtrl.reset();
      if (mounted) _scheduleNextSatellite();
    });
  }

  @override
  void dispose() {
    _meteorTimer?.cancel();
    _satelliteTimer?.cancel();
    _meteorCtrl.dispose();
    _satelliteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_meteorCtrl, _satelliteCtrl]),
        builder: (context, _) {
          return CustomPaint(
            painter: _SkyEventsPainter(
              meteorT: _meteorCtrl.value,
              meteorStart: _meteorStart,
              meteorEnd: _meteorEnd,
              meteorColor: _meteorColor,
              satelliteT: _satelliteCtrl.value,
              satStart: _satStart,
              satEnd: _satEnd,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _SkyEventsPainter extends CustomPainter {
  final double meteorT;
  final Offset meteorStart;
  final Offset meteorEnd;
  final Color meteorColor;
  final double satelliteT;
  final Offset satStart;
  final Offset satEnd;
  _SkyEventsPainter({
    required this.meteorT,
    required this.meteorStart,
    required this.meteorEnd,
    required this.meteorColor,
    required this.satelliteT,
    required this.satStart,
    required this.satEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // উল্কা/শুটিং স্টার — দ্রুত ছুটে যাওয়া, ক্রমশ মিলিয়ে যাওয়া লেজসহ
    if (meteorT > 0.0 && meteorT < 1.0) {
      final head = Offset.lerp(meteorStart, meteorEnd, meteorT)!;
      final tailFrac = (meteorT - 0.22).clamp(0.0, 1.0);
      final tail = Offset.lerp(meteorStart, meteorEnd, tailFrac)!;
      final fade = meteorT < 0.75 ? 1.0 : (1.0 - meteorT) / 0.25;
      final fadeAlpha = fade.clamp(0.0, 1.0);
      final p1 = Offset(head.dx * size.width, head.dy * size.height);
      final p2 = Offset(tail.dx * size.width, tail.dy * size.height);
      final streak = Paint()
        ..shader = ui.Gradient.linear(p2, p1, [
          meteorColor.withValues(alpha: 0.0),
          meteorColor.withValues(alpha: fadeAlpha),
        ])
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p2, p1, streak);
      canvas.drawCircle(
        p1,
        1.6,
        Paint()..color = meteorColor.withValues(alpha: fadeAlpha),
      );
    }

    // কৃত্রিম উপগ্রহ — ধীর, প্রায়-স্থির উজ্জ্বলতার একটা বিন্দু সরলরেখায় চলে
    if (satelliteT > 0.0 && satelliteT < 1.0) {
      final pos = Offset.lerp(satStart, satEnd, satelliteT)!;
      final p = Offset(pos.dx * size.width, pos.dy * size.height);
      final blink = 0.55 + 0.45 * math.sin(satelliteT * 2 * math.pi * 6);
      canvas.drawCircle(
        p,
        1.4,
        Paint()..color = Colors.white.withValues(alpha: blink.clamp(0.3, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SkyEventsPainter old) {
    return old.meteorT != meteorT || old.satelliteT != satelliteT;
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
/// আজকের প্রকৃত চাঁদের দশা আঁকার জন্য একটাই শেয়ার্ড ফাংশন — CosmicBackground
/// আর গ্রামের আকাশ, দুই জায়গাতেই একই বাস্তব হিসেব দিয়ে চাঁদ আঁকা হয়।
void paintMoonPhase(
  Canvas canvas,
  Offset center,
  double r,
  double illumination,
  bool waxing,
) {
  // ম্লান আভা (glow) — সবসময় একটা ন্যূনতম আভা থাকে যাতে অন্ধকার আকাশেও
  // চাঁদটা স্পষ্ট বোঝা যায়, পূর্ণিমার কাছাকাছি সবচেয়ে উজ্জ্বল
  final glowPaint = Paint()
    ..shader = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: 0.30 * illumination + 0.16),
        Colors.white.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: r * 2.1));
  canvas.drawCircle(center, r * 2.1, glowPaint);

  // অন্ধকার/অনালোকিত অংশ — earthshine-এর মতো ম্লান নীলচে-ধূসর (আকাশের
  // রঙের চেয়ে স্পষ্ট আলাদা যাতে গোল আকৃতিটা সবসময় বোঝা যায়)
  final darkPaint = Paint()..color = const Color(0xFF4A5470);
  canvas.drawCircle(center, r, darkPaint);
  // চাঁদের চারপাশে একটা পাতলা উজ্জ্বল কিনারা — কম আলোকিত দশাতেও যেন
  // গোলাকার আকৃতিটা আকাশের বিপরীতে স্পষ্ট বোঝা যায়
  final rimPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.45)
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.0, r * 0.045);
  canvas.drawCircle(center, r, rimPaint);

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
        ..addOval(
          Rect.fromCenter(center: center, width: rx * 2, height: r * 2),
        );
      litPath = Path.combine(PathOperation.difference, halfPath, ellipse);
    } else {
      final rx = r * (2 * k - 1);
      final ellipse = Path()
        ..addOval(
          Rect.fromCenter(center: center, width: rx * 2, height: r * 2),
        );
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

class _MoonPhasePainter extends CustomPainter {
  _MoonPhasePainter({required this.illumination, required this.waxing});
  final double illumination; // ০ (অমাবস্যা) .. ১ (পূর্ণিমা)
  final bool waxing;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 * 0.62;
    paintMoonPhase(canvas, center, r, illumination, waxing);
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

class _StarsLayerState extends State<StarsLayer> with TickerProviderStateMixin {
  late final AnimationController _twinkle;
  // পৃথিবীর ঘূর্ণনের কারণে বাস্তবে তারা আকাশে খুব ধীরে ধীরে সরে বলে মনে
  // হয় — পুরো dome-projection ছাড়াই সেই অনুভূতি আনতে সম্পূর্ণ তারার
  // স্তরে অত্যন্ত সূক্ষ্ম, ধীর ঘূর্ণন (মাত্র ~০.৬° দোলে)
  late final AnimationController _drift;
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
        rnd.nextBool() ? const Color(0xFFB9C7F0) : const Color(0xFFE6D5F5),
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
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 9),
    );
    if (AppSettings.instance.skyAnim) _drift.repeat();
  }

  @override
  void dispose() {
    _twinkle.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        // স্থির স্তর (নীহারিকা + ছায়াপথ) — প্রতি ফ্রেমে আঁকার দরকার নেই
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: DeepSkyPainter(_nebulae, _milkyWay)),
          ),
        ),
        // কয়েকটি পরিচিত তারামণ্ডলের stylized আভাস (সরলীকৃত, নিখুঁত dome
        // অবস্থান নয় — শুধু রাতের আকাশে পরিচিত আকৃতির ইঙ্গিত)
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: const _ConstellationsPainter()),
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
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, child) {
        final angle = (_drift.value - 0.5) * 0.02;
        return Transform.rotate(angle: angle, child: child);
      },
      child: content,
    );
  }
}

/// পরিচিত কয়েকটি তারামণ্ডলের সরলীকৃত, stylized প্যাটার্ন — বাস্তব আকাশে
/// এই মুহূর্তে ঠিক এই অবস্থানে দেখা যাবে এমন নিখুঁত জ্যোতির্বিদ্যা-সম্মত
/// dome projection নয় (তার জন্য পূর্ণ RA/Dec ম্যাপিং লাগত), বরং রাতের
/// আকাশের পটভূমিতে পরিচিত আকৃতির subtle ইঙ্গিত দেওয়ার জন্য সাজসজ্জা
class _ConstellationsPainter extends CustomPainter {
  const _ConstellationsPainter();

  static const List<List<Offset>> _patterns = [
    // সপ্তর্ষিমণ্ডল (Ursa Major) — সরলীকৃত "saucepan" আকৃতি
    [
      Offset(0.12, 0.14),
      Offset(0.17, 0.12),
      Offset(0.22, 0.135),
      Offset(0.27, 0.155),
      Offset(0.27, 0.19),
      Offset(0.22, 0.20),
      Offset(0.19, 0.175),
    ],
    // কালপুরুষ (Orion) — সরলীকৃত বেল্ট ও কাঁধ/পা
    [
      Offset(0.68, 0.10),
      Offset(0.80, 0.09),
      Offset(0.72, 0.155),
      Offset(0.76, 0.155),
      Offset(0.80, 0.155),
      Offset(0.70, 0.22),
      Offset(0.82, 0.22),
    ],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.75);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 0.8;
    for (final pattern in _patterns) {
      for (int i = 0; i < pattern.length; i++) {
        final p = Offset(
          pattern[i].dx * size.width,
          pattern[i].dy * size.height,
        );
        canvas.drawCircle(p, 1.4, dot);
        if (i > 0) {
          final prev = Offset(
            pattern[i - 1].dx * size.width,
            pattern[i - 1].dy * size.height,
          );
          canvas.drawLine(prev, p, line);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationsPainter old) => false;
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
      final wave = math.sin(
        (t * s.twinkleSpeed + s.twinklePhase) * 2 * math.pi,
      );
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
    PanchangFeature('🙏', 'পূজা ও ব্রত', 'উৎসব, উপবাস, পূজা তালিকা'),
    PanchangFeature('🔮', 'রাশিফল', '১২ রাশি, দৈনিক ও মাসিক'),
    PanchangFeature('💍', 'শুভ দিন', 'বিবাহ, গৃহপ্রবেশ, অন্নপ্রাশন'),
    PanchangFeature('🌕', 'পূর্ণিমা', 'পূর্ণিমার তারিখ ও তথ্য'),
    PanchangFeature('🌑', 'অমাবস্যা', 'অমাবস্যার তালিকা ও সময়'),
    PanchangFeature('🌒', 'গ্রহণ', 'সূর্য ও চন্দ্রগ্রহণ'),
    PanchangFeature('🌌', 'গ্রহ ও নক্ষত্র', 'গ্রহের অবস্থান ও জ্যোতির্বিদ্যা'),
  ];

  // আগে এই ৪টা উৎসব হার্ডকোডেড ছিল, তারিখ পার হয়ে গেলেও একই থাকত (যেমন
  // রথযাত্রা "২৭ জ্যৈষ্ঠ" — অনেক আগেই পার হয়ে গেছে)। এখন real তিথি/
  // সংক্রান্তি হিসেব থেকে আজকের-পরের উৎসবগুলো বের করে দেখানো হয়, আর
  // কার্ডগুলো ডান দিকে ধীরে ধীরে আপনাআপনি স্ক্রল হতেই থাকে (loop করে)।
  late final List<FestivalItem> _festivals =
      BengaliCalendarData.upcomingFestivals()
          .map((f) => FestivalItem(f['icon']!, f['title']!, f['date']!))
          .toList();

  final ScrollController _festivalScrollCtrl = ScrollController();
  Timer? _festivalAutoTimer;

  void _startFestivalAutoScroll() {
    _festivalAutoTimer?.cancel();
    if (_festivals.length < 2) return;
    _festivalAutoTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!_festivalScrollCtrl.hasClients) return;
      final max = _festivalScrollCtrl.position.maxScrollExtent;
      if (max <= 0) return;
      final next = _festivalScrollCtrl.offset + 0.6;
      if (next >= max) {
        _festivalScrollCtrl.jumpTo(0);
      } else {
        _festivalScrollCtrl.jumpTo(next);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // ১ম ফ্রেমের পর শুরু করা হয় যাতে maxScrollExtent ততক্ষণে হিসেব হয়ে যায়
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startFestivalAutoScroll();
    });
    // হোম স্ক্রিনে ঢোকার সময় হোম-স্ক্রিন উইজেটের ডেটাও রিফ্রেশ করা হয়
    HomeWidgetService.updateWidget();
  }

  @override
  void dispose() {
    _festivalAutoTimer?.cancel();
    _festivalScrollCtrl.dispose();
    super.dispose();
  }

  void _handleOpen(BuildContext context, String title) {
    if (title == 'বাংলা ক্যালেন্ডার') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BengaliCalendarScreen()),
      );
      return;
    }
    // রাশিফল — আগে একটা ছোট বটম শীট ছিল, এখন পূর্ণ পেজ: ঘূর্ণমান রাশিচক্র,
    // আজকের real রাশিফল (সব ১২টা) ও জন্ম-তারিখ/সময় দিয়ে জন্ম-রাশি বের করার
    // ক্যালকুলেটর — সবকিছু এক জায়গায়
    if (title == 'রাশিফল') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RashiScreen()),
      );
      return;
    }
    // পূর্ণিমা ও অমাবস্যা — আগে দুটো আলাদা শীট ছিল, এখন একই বাক্সে ২টা
    // বাটন দিয়ে টগল করা যায়, দুটোই real তিথি হিসেবের আজকের-পরের তারিখ দেখায়
    if (title == 'পূর্ণিমা' || title == 'অমাবস্যা') {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _MoonPhaseSheet(initialIsPurnima: title == 'পূর্ণিমা'),
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
      case 'পারিবারিক ক্যালেন্ডার':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FamilyCalendarScreen()),
        );
        break;
      case 'শিশুর নামের আদ্যক্ষর':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BabyNamingScreen()),
        );
        break;
      case 'শুভ মুহূর্ত':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShubhoMuhurtaScreen()),
        );
        break;
      case 'উৎসব পোস্টার মেকার':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FestivalPosterScreen()),
        );
        break;
      case 'পঞ্চাঙ্গ শেয়ার কার্ড':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PanchangShareCardScreen()),
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
      case 'প্রিমিয়াম':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
        break;
      case 'শ্রাদ্ধ তিথি ফাইন্ডার':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShraddhaTithiScreen()),
        );
        break;
      case 'মন্দির ও পূজার সময়সূচি':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TempleScreen()),
        );
        break;
      case 'পঞ্জিকা PDF এক্সপোর্ট':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const _PremiumGate(
              featureTitle: '📄 পঞ্জিকা PDF এক্সপোর্ট',
              child: PdfExportScreen(),
            ),
          ),
        );
        break;
      case 'চন্দ্র কুষ্ঠি চার্ট':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const _PremiumGate(
              featureTitle: '🪐 চন্দ্র কুষ্ঠি চার্ট',
              child: KundliScreen(),
            ),
          ),
        );
        break;
      case 'কুষ্ঠি মিলন':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const _PremiumGate(
              featureTitle: '💞 কুষ্ঠি মিলন',
              child: KundliMilanScreen(),
            ),
          ),
        );
        break;
      case 'ক্লাউড ব্যাকআপ':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const _PremiumGate(
              featureTitle: '☁️ ক্লাউড ব্যাকআপ',
              child: CloudBackupScreen(),
            ),
          ),
        );
        break;
      case 'জ্যোতিষী পরামর্শ বুকিং':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const _PremiumGate(
              featureTitle: '🔮 জ্যোতিষী পরামর্শ বুকিং',
              child: AstrologerBookingScreen(),
            ),
          ),
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
              const _TodayTomorrowBoxes(),
              const SizedBox(height: 12),
              const _HistoryBanner(),
              const SizedBox(height: 14),
              _TickerBar(),
              const SizedBox(height: 20),
              const _SectionTitle('আজকের পঞ্চাঙ্গ'),
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  // GPS/হিসেবে কোনো অপ্রত্যাশিত সমস্যা হলেও (যেমন কোনো
                  // ফোনে GPS থেকে অবৈধ কো-অর্ডিনেট) যাতে পুরো কার্ড ৩টা
                  // ফাঁকা/ক্র্যাশ না হয়ে যায় — নিরাপদে জেলার ডিফল্ট
                  // লোকেশন দিয়ে আবার হিসেব করে দেখানো হয়
                  String sunriseTxt, sunsetTxt, moonriseTxt;
                  try {
                    final now = DateTime.now();
                    final sun = PanchangCalculator.sunTimes(now);
                    final moonAge = PanchangCalculator.moonAgeDays(now);
                    final moonrise = sun.sunrise.add(
                      Duration(minutes: (moonAge * 48.8).round()),
                    );
                    sunriseTxt = bnTime12(sun.sunrise);
                    sunsetTxt = bnTime12(sun.sunset);
                    moonriseTxt = bnTime12(moonrise);
                  } catch (_) {
                    final now = DateTime.now();
                    final fallbackLat =
                        AppLocation.coordinates[AppLocation.district]?.lat ??
                        22.5726;
                    final fallbackLon =
                        AppLocation.coordinates[AppLocation.district]?.lon ??
                        88.3639;
                    final sun = PanchangCalculator.sunTimes(
                      now,
                      lat: fallbackLat,
                      lon: fallbackLon,
                    );
                    final moonAge = PanchangCalculator.moonAgeDays(now);
                    final moonrise = sun.sunrise.add(
                      Duration(minutes: (moonAge * 48.8).round()),
                    );
                    sunriseTxt = bnTime12(sun.sunrise);
                    sunsetTxt = bnTime12(sun.sunset);
                    moonriseTxt = bnTime12(moonrise);
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: _MiniPanchang(
                          emoji: '🌅',
                          value: sunriseTxt,
                          label: 'সূর্যোদয়',
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _MiniPanchang(
                          emoji: '🌇',
                          value: sunsetTxt,
                          label: 'সূর্যাস্ত',
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _MiniPanchang(
                          emoji: '🌙',
                          value: moonriseTxt,
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
                child: Listener(
                  // ব্যবহারকারী নিজে টাচ করে স্ক্রল করলে auto-scroll থামিয়ে
                  // দেওয়া হয়, ছেড়ে দিলে আবার আপনাআপনি চলতে শুরু করে
                  onPointerDown: (_) => _festivalAutoTimer?.cancel(),
                  onPointerUp: (_) => _startFestivalAutoScroll(),
                  child: ListView.separated(
                    controller: _festivalScrollCtrl,
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
              ),
              const SizedBox(height: 20),
              const _SectionTitle('উৎসব কাউন্টডাউন'),
              const SizedBox(height: 10),
              const _UpcomingFestivalsCard(count: 3),
              const SizedBox(height: 20),
              const _SectionTitle('গ্রামের আকাশ (লাইভ)'),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const VillageHorizonScene(),
              ),
              const SizedBox(height: 14),
              const AdBannerWidget(),
              const SizedBox(height: 80),
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
                    MaterialPageRoute(builder: (_) => const PremiumScreen()),
                  );
                  return;
                }
                setState(() => _navIndex = i);
              },
              onFabTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorldClockScreen()),
              ),
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
  _HistoricalFigure(
    5,
    7,
    'রবীন্দ্রনাথ ঠাকুর',
    'কবি ও সাহিত্যিক (নোবেলজয়ী)',
    'জন্ম',
    '📖',
  ),
  _HistoricalFigure(
    8,
    7,
    'রবীন্দ্রনাথ ঠাকুর',
    'কবি ও সাহিত্যিক (নোবেলজয়ী)',
    'প্রয়াণ',
    '📖',
  ),
  _HistoricalFigure(5, 25, 'কাজী নজরুল ইসলাম', 'বিদ্রোহী কবি', 'জন্ম', '✒️'),
  _HistoricalFigure(8, 29, 'কাজী নজরুল ইসলাম', 'বিদ্রোহী কবি', 'প্রয়াণ', '✒️'),
  _HistoricalFigure(
    1,
    23,
    'নেতাজি সুভাষচন্দ্র বসু',
    'স্বাধীনতা সংগ্রামী',
    'জন্ম',
    '🇮🇳',
  ),
  _HistoricalFigure(
    1,
    12,
    'স্বামী বিবেকানন্দ',
    'সন্ন্যাসী ও দার্শনিক',
    'জন্ম',
    '🕉',
  ),
  _HistoricalFigure(
    7,
    4,
    'স্বামী বিবেকানন্দ',
    'সন্ন্যাসী ও দার্শনিক',
    'প্রয়াণ',
    '🕉',
  ),
  _HistoricalFigure(
    9,
    26,
    'ঈশ্বরচন্দ্র বিদ্যাসাগর',
    'সমাজ সংস্কারক',
    'জন্ম',
    '📚',
  ),
  _HistoricalFigure(
    7,
    29,
    'ঈশ্বরচন্দ্র বিদ্যাসাগর',
    'সমাজ সংস্কারক',
    'প্রয়াণ',
    '📚',
  ),
  _HistoricalFigure(
    6,
    26,
    'বঙ্কিমচন্দ্র চট্টোপাধ্যায়',
    'সাহিত্যিক',
    'জন্ম',
    '🖋',
  ),
  _HistoricalFigure(
    4,
    8,
    'বঙ্কিমচন্দ্র চট্টোপাধ্যায়',
    'সাহিত্যিক',
    'প্রয়াণ',
    '🖋',
  ),
  _HistoricalFigure(
    9,
    15,
    'শরৎচন্দ্র চট্টোপাধ্যায়',
    'সাহিত্যিক',
    'জন্ম',
    '🖋',
  ),
  _HistoricalFigure(
    1,
    16,
    'শরৎচন্দ্র চট্টোপাধ্যায়',
    'সাহিত্যিক',
    'প্রয়াণ',
    '🖋',
  ),
  _HistoricalFigure(5, 2, 'সত্যজিৎ রায়', 'চলচ্চিত্র নির্মাতা', 'জন্ম', '🎬'),
  _HistoricalFigure(
    4,
    23,
    'সত্যজিৎ রায়',
    'চলচ্চিত্র নির্মাতা',
    'প্রয়াণ',
    '🎬',
  ),
  _HistoricalFigure(11, 30, 'জগদীশচন্দ্র বসু', 'বিজ্ঞানী', 'জন্ম', '🔬'),
  _HistoricalFigure(11, 23, 'জগদীশচন্দ্র বসু', 'বিজ্ঞানী', 'প্রয়াণ', '🔬'),
  _HistoricalFigure(10, 6, 'মেঘনাদ সাহা', 'বিজ্ঞানী', 'জন্ম', '🔬'),
  _HistoricalFigure(2, 16, 'মেঘনাদ সাহা', 'বিজ্ঞানী', 'প্রয়াণ', '🔬'),
  _HistoricalFigure(5, 22, 'রাজা রামমোহন রায়', 'সমাজ সংস্কারক', 'জন্ম', '📜'),
  _HistoricalFigure(
    9,
    27,
    'রাজা রামমোহন রায়',
    'সমাজ সংস্কারক',
    'প্রয়াণ',
    '📜',
  ),
  _HistoricalFigure(10, 2, 'মহাত্মা গান্ধী', 'জাতির জনক', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(1, 30, 'মহাত্মা গান্ধী', 'জাতির জনক', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(
    10,
    15,
    'এ.পি.জে. আব্দুল কালাম',
    'বিজ্ঞানী ও রাষ্ট্রপতি',
    'জন্ম',
    '🚀',
  ),
  _HistoricalFigure(
    7,
    27,
    'এ.পি.জে. আব্দুল কালাম',
    'বিজ্ঞানী ও রাষ্ট্রপতি',
    'প্রয়াণ',
    '🚀',
  ),
  _HistoricalFigure(2, 18, 'শ্রীরামকৃষ্ণ পরমহংস', 'সন্ন্যাসী', 'জন্ম', '🕉'),
  _HistoricalFigure(8, 16, 'শ্রীরামকৃষ্ণ পরমহংস', 'সন্ন্যাসী', 'প্রয়াণ', '🕉'),
  _HistoricalFigure(10, 28, 'ভগিনী নিবেদিতা', 'সমাজসেবী', 'জন্ম', '🤍'),
  _HistoricalFigure(10, 13, 'ভগিনী নিবেদিতা', 'সমাজসেবী', 'প্রয়াণ', '🤍'),
  _HistoricalFigure(1, 25, 'মাইকেল মধুসূদন দত্ত', 'কবি', 'জন্ম', '✒️'),
  _HistoricalFigure(6, 29, 'মাইকেল মধুসূদন দত্ত', 'কবি', 'প্রয়াণ', '✒️'),
  _HistoricalFigure(9, 28, 'রানি রাসমণি', 'সমাজসেবী', 'জন্ম', '🏛'),
  _HistoricalFigure(2, 19, 'রানি রাসমণি', 'সমাজসেবী', 'প্রয়াণ', '🏛'),
  _HistoricalFigure(
    11,
    5,
    'দেশবন্ধু চিত্তরঞ্জন দাশ',
    'রাজনীতিবিদ',
    'জন্ম',
    '🇮🇳',
  ),
  _HistoricalFigure(
    6,
    16,
    'দেশবন্ধু চিত্তরঞ্জন দাশ',
    'রাজনীতিবিদ',
    'প্রয়াণ',
    '🇮🇳',
  ),
  _HistoricalFigure(12, 3, 'ক্ষুদিরাম বসু', 'বিপ্লবী (ফাঁসি)', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(
    8,
    11,
    'ক্ষুদিরাম বসু',
    'বিপ্লবী (ফাঁসি)',
    'প্রয়াণ',
    '🇮🇳',
  ),
  _HistoricalFigure(9, 29, 'মাতঙ্গিনী হাজরা', 'বিপ্লবী', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(12, 9, 'বেগম রোকেয়া', 'সমাজ সংস্কারক', 'জন্ম', '📚'),
  _HistoricalFigure(2, 17, 'জীবনানন্দ দাশ', 'কবি', 'জন্ম', '✒️'),
  _HistoricalFigure(10, 22, 'জীবনানন্দ দাশ', 'কবি', 'প্রয়াণ', '✒️'),
  _HistoricalFigure(
    8,
    2,
    'আচার্য প্রফুল্লচন্দ্র রায়',
    'বিজ্ঞানী',
    'জন্ম',
    '🔬',
  ),
  _HistoricalFigure(
    6,
    16,
    'আচার্য প্রফুল্লচন্দ্র রায়',
    'বিজ্ঞানী',
    'প্রয়াণ',
    '🔬',
  ),
  _HistoricalFigure(
    7,
    1,
    'ডা. বিধানচন্দ্র রায়',
    'চিকিৎসক ও রাজনীতিবিদ',
    'জন্ম ও প্রয়াণ',
    '⚕️',
  ),
  _HistoricalFigure(
    3,
    22,
    'মাস্টারদা সূর্য সেন',
    'বিপ্লবী (ফাঁসি)',
    'জন্ম',
    '🇮🇳',
  ),
  _HistoricalFigure(
    1,
    12,
    'মাস্টারদা সূর্য সেন',
    'বিপ্লবী (ফাঁসি)',
    'প্রয়াণ',
    '🇮🇳',
  ),
  _HistoricalFigure(5, 5, 'প্রীতিলতা ওয়াদ্দেদার', 'বিপ্লবী', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(
    9,
    24,
    'প্রীতিলতা ওয়াদ্দেদার',
    'বিপ্লবী',
    'প্রয়াণ',
    '🇮🇳',
  ),
  _HistoricalFigure(
    7,
    18,
    'কাদম্বিনী গঙ্গোপাধ্যায়',
    'প্রথম নারী চিকিৎসক',
    'জন্ম',
    '⚕️',
  ),
  _HistoricalFigure(
    10,
    3,
    'কাদম্বিনী গঙ্গোপাধ্যায়',
    'প্রথম নারী চিকিৎসক',
    'প্রয়াণ',
    '⚕️',
  ),
  _HistoricalFigure(8, 26, 'মাদার টেরিজা', 'সমাজসেবী (কলকাতা)', 'জন্ম', '🤍'),
  _HistoricalFigure(9, 5, 'মাদার টেরিজা', 'সমাজসেবী (কলকাতা)', 'প্রয়াণ', '🤍'),
  _HistoricalFigure(
    8,
    18,
    'নেতাজি সুভাষচন্দ্র বসু',
    'স্বাধীনতা সংগ্রামী',
    'প্রয়াণ',
    '🇮🇳',
  ),
  _HistoricalFigure(
    11,
    7,
    'বিপিনচন্দ্র পাল',
    'বিপ্লবী (লাল-বাল-পাল)',
    'জন্ম',
    '🇮🇳',
  ),
  _HistoricalFigure(
    5,
    20,
    'বিপিনচন্দ্র পাল',
    'বিপ্লবী (লাল-বাল-পাল)',
    'প্রয়াণ',
    '🇮🇳',
  ),
  _HistoricalFigure(
    7,
    23,
    'তারাশঙ্কর বন্দ্যোপাধ্যায়',
    'সাহিত্যিক',
    'জন্ম',
    '🖋',
  ),
  _HistoricalFigure(
    9,
    14,
    'তারাশঙ্কর বন্দ্যোপাধ্যায়',
    'সাহিত্যিক',
    'প্রয়াণ',
    '🖋',
  ),
  _HistoricalFigure(5, 19, 'মানিক বন্দ্যোপাধ্যায়', 'সাহিত্যিক', 'জন্ম', '🖋'),
  _HistoricalFigure(
    12,
    3,
    'মানিক বন্দ্যোপাধ্যায়',
    'সাহিত্যিক',
    'প্রয়াণ',
    '🖋',
  ),
  _HistoricalFigure(
    9,
    12,
    'বিভূতিভূষণ বন্দ্যোপাধ্যায়',
    'সাহিত্যিক (পথের পাঁচালী)',
    'জন্ম',
    '🖋',
  ),
  _HistoricalFigure(
    11,
    1,
    'বিভূতিভূষণ বন্দ্যোপাধ্যায়',
    'সাহিত্যিক (পথের পাঁচালী)',
    'প্রয়াণ',
    '🖋',
  ),
  _HistoricalFigure(11, 4, 'ঋত্বিক ঘটক', 'চলচ্চিত্র নির্মাতা', 'জন্ম', '🎬'),
  _HistoricalFigure(2, 6, 'ঋত্বিক ঘটক', 'চলচ্চিত্র নির্মাতা', 'প্রয়াণ', '🎬'),
  _HistoricalFigure(5, 14, 'মৃণাল সেন', 'চলচ্চিত্র নির্মাতা', 'জন্ম', '🎬'),
  _HistoricalFigure(12, 30, 'মৃণাল সেন', 'চলচ্চিত্র নির্মাতা', 'প্রয়াণ', '🎬'),
  _HistoricalFigure(4, 7, 'পণ্ডিত রবিশঙ্কর', 'সেতার বাদক', 'জন্ম', '🎶'),
  _HistoricalFigure(12, 11, 'পণ্ডিত রবিশঙ্কর', 'সেতার বাদক', 'প্রয়াণ', '🎶'),
  _HistoricalFigure(9, 3, 'উত্তম কুমার', 'অভিনেতা (মহানায়ক)', 'জন্ম', '🎭'),
  _HistoricalFigure(
    7,
    24,
    'উত্তম কুমার',
    'অভিনেতা (মহানায়ক)',
    'প্রয়াণ',
    '🎭',
  ),
  _HistoricalFigure(
    4,
    6,
    'সুচিত্রা সেন',
    'অভিনেত্রী (মহানায়িকা)',
    'জন্ম',
    '🎭',
  ),
  _HistoricalFigure(
    1,
    17,
    'সুচিত্রা সেন',
    'অভিনেত্রী (মহানায়িকা)',
    'প্রয়াণ',
    '🎭',
  ),
  _HistoricalFigure(6, 16, 'হেমন্ত মুখোপাধ্যায়', 'সঙ্গীতশিল্পী', 'জন্ম', '🎤'),
  _HistoricalFigure(
    9,
    26,
    'হেমন্ত মুখোপাধ্যায়',
    'সঙ্গীতশিল্পী',
    'প্রয়াণ',
    '🎤',
  ),
  _HistoricalFigure(
    8,
    4,
    'কিশোর কুমার',
    'সঙ্গীতশিল্পী ও অভিনেতা',
    'জন্ম',
    '🎤',
  ),
  _HistoricalFigure(
    10,
    13,
    'কিশোর কুমার',
    'সঙ্গীতশিল্পী ও অভিনেতা',
    'প্রয়াণ',
    '🎤',
  ),
  _HistoricalFigure(5, 1, 'মান্না দে', 'সঙ্গীতশিল্পী', 'জন্ম', '🎤'),
  _HistoricalFigure(10, 24, 'মান্না দে', 'সঙ্গীতশিল্পী', 'প্রয়াণ', '🎤'),
  _HistoricalFigure(
    6,
    29,
    'স্যার আশুতোষ মুখোপাধ্যায়',
    'শিক্ষাবিদ',
    'জন্ম',
    '🎓',
  ),
  _HistoricalFigure(
    5,
    25,
    'স্যার আশুতোষ মুখোপাধ্যায়',
    'শিক্ষাবিদ',
    'প্রয়াণ',
    '🎓',
  ),
  _HistoricalFigure(9, 27, 'ভগৎ সিং', 'বিপ্লবী (ফাঁসি)', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(3, 23, 'ভগৎ সিং', 'বিপ্লবী (ফাঁসি)', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(
    11,
    14,
    'জওহরলাল নেহরু',
    'ভারতের প্রথম প্রধানমন্ত্রী',
    'জন্ম',
    '🇮🇳',
  ),
  _HistoricalFigure(
    5,
    27,
    'জওহরলাল নেহরু',
    'ভারতের প্রথম প্রধানমন্ত্রী',
    'প্রয়াণ',
    '🇮🇳',
  ),
  _HistoricalFigure(
    10,
    31,
    'সর্দার বল্লভভাই প্যাটেল',
    'রাষ্ট্রনায়ক',
    'জন্ম',
    '🇮🇳',
  ),
  _HistoricalFigure(
    12,
    15,
    'সর্দার বল্লভভাই প্যাটেল',
    'রাষ্ট্রনায়ক',
    'প্রয়াণ',
    '🇮🇳',
  ),
  _HistoricalFigure(
    4,
    14,
    'ডঃ ভীমরাও আম্বেদকর',
    'সংবিধান প্রণেতা',
    'জন্ম',
    '⚖️',
  ),
  _HistoricalFigure(
    12,
    6,
    'ডঃ ভীমরাও আম্বেদকর',
    'সংবিধান প্রণেতা',
    'প্রয়াণ',
    '⚖️',
  ),
  _HistoricalFigure(
    10,
    2,
    'লাল বাহাদুর শাস্ত্রী',
    'প্রধানমন্ত্রী',
    'জন্ম',
    '🇮🇳',
  ),
  _HistoricalFigure(
    1,
    11,
    'লাল বাহাদুর শাস্ত্রী',
    'প্রধানমন্ত্রী',
    'প্রয়াণ',
    '🇮🇳',
  ),
  _HistoricalFigure(11, 19, 'ইন্দিরা গান্ধী', 'প্রধানমন্ত্রী', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(
    10,
    31,
    'ইন্দিরা গান্ধী',
    'প্রধানমন্ত্রী',
    'প্রয়াণ',
    '🇮🇳',
  ),
  _HistoricalFigure(8, 20, 'রাজীব গান্ধী', 'প্রধানমন্ত্রী', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(5, 21, 'রাজীব গান্ধী', 'প্রধানমন্ত্রী', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(7, 23, 'চন্দ্রশেখর আজাদ', 'বিপ্লবী', 'জন্ম', '🇮🇳'),
  _HistoricalFigure(2, 27, 'চন্দ্রশেখর আজাদ', 'বিপ্লবী', 'প্রয়াণ', '🇮🇳'),
  _HistoricalFigure(
    11,
    7,
    'স্যার সি.ভি. রামন',
    'পদার্থবিজ্ঞানী (নোবেলজয়ী)',
    'জন্ম',
    '🔬',
  ),
  _HistoricalFigure(
    11,
    21,
    'স্যার সি.ভি. রামন',
    'পদার্থবিজ্ঞানী (নোবেলজয়ী)',
    'প্রয়াণ',
    '🔬',
  ),
  _HistoricalFigure(1, 1, 'সত্যেন্দ্রনাথ বসু', 'পদার্থবিজ্ঞানী', 'জন্ম', '🔬'),
  _HistoricalFigure(
    2,
    4,
    'সত্যেন্দ্রনাথ বসু',
    'পদার্থবিজ্ঞানী',
    'প্রয়াণ',
    '🔬',
  ),
  _HistoricalFigure(
    10,
    30,
    'হোমি জাহাঙ্গীর ভাবা',
    'পরমাণু বিজ্ঞানী',
    'জন্ম',
    '⚛️',
  ),
  _HistoricalFigure(
    1,
    24,
    'হোমি জাহাঙ্গীর ভাবা',
    'পরমাণু বিজ্ঞানী',
    'প্রয়াণ',
    '⚛️',
  ),
  _HistoricalFigure(
    2,
    13,
    'সরোজিনী নাইডু',
    'কবি ও স্বাধীনতা সংগ্রামী',
    'জন্ম',
    '🌸',
  ),
  _HistoricalFigure(
    3,
    2,
    'সরোজিনী নাইডু',
    'কবি ও স্বাধীনতা সংগ্রামী',
    'প্রয়াণ',
    '🌸',
  ),
  _HistoricalFigure(8, 15, 'ঋষি অরবিন্দ', 'দার্শনিক ও যোগী', 'জন্ম', '🕉'),
  _HistoricalFigure(12, 5, 'ঋষি অরবিন্দ', 'দার্শনিক ও যোগী', 'প্রয়াণ', '🕉'),
  _HistoricalFigure(
    1,
    14,
    'মহাশ্বেতা দেবী',
    'সাহিত্যিক ও সমাজকর্মী',
    'জন্ম',
    '🖋',
  ),
  _HistoricalFigure(
    7,
    28,
    'মহাশ্বেতা দেবী',
    'সাহিত্যিক ও সমাজকর্মী',
    'প্রয়াণ',
    '🖋',
  ),
  _HistoricalFigure(
    9,
    7,
    'সুনীল গঙ্গোপাধ্যায়',
    'কবি ও সাহিত্যিক',
    'জন্ম',
    '🖋',
  ),
  _HistoricalFigure(
    10,
    23,
    'সুনীল গঙ্গোপাধ্যায়',
    'কবি ও সাহিত্যিক',
    'প্রয়াণ',
    '🖋',
  ),
  _HistoricalFigure(8, 19, 'সুধা মূর্তি', 'লেখিকা ও সমাজসেবী', 'জন্ম', '📖'),
  _HistoricalFigure(
    8,
    19,
    'এস. সত্যমূর্তি',
    'আইনজীবী ও রাজনীতিবিদ',
    'জন্ম',
    '🇮🇳',
  ),
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
                                  fontSize: 11,
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
                          fontSize: 12,
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

class _HeroDateCard extends StatefulWidget {
  const _HeroDateCard({super.key});

  @override
  State<_HeroDateCard> createState() => _HeroDateCardState();
}

class _HeroDateCardState extends State<_HeroDateCard> {
  bool _speaking = false;

  Future<void> _toggleSpeak() async {
    if (_speaking) {
      await TtsService.instance.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    await TtsService.instance.speak(buildTodayPanchangSummary());
    if (mounted) setState(() => _speaking = false);
  }

  void _shareToday() {
    Share.share(
      buildTodayPanchangSummary(),
      subject: 'আজকের পঞ্চাঙ্গ — বাংলা পঞ্জিকা',
    );
  }

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'আজকের মহাজাগতিক দিন',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              InkWell(
                onTap: _toggleSpeak,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _speaking
                        ? Icons.stop_circle_outlined
                        : Icons.volume_up_rounded,
                    color: const Color(0xFFFFD36E),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _shareToday,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.share_rounded,
                    color: Color(0xFFFFD36E),
                    size: 19,
                  ),
                ),
              ),
            ],
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Builder(
            builder: (context) {
              // আগে এখানে সকাল/দিন/সন্ধ্যা/রাত/পূর্ণিমা/অমাবস্যা/গ্রহণ —
              // এই লেবেলগুলো শুধু সাজানোর জন্য ছিল, কোনো real তথ্য দেখাত
              // না। এখন এখানে আজকের প্রকৃত সূর্যোদয়/সূর্যাস্ত ও তিথি/
              // নক্ষত্র দেখানো হয় — একই হিসাব যেটা "আজকের লাইভ তথ্য"-তে
              // ব্যবহার হয় (PanchangCalculator.sunTimes), তাই কোনো নতুন
              // calculation যোগ হয়নি।
              final sun = PanchangCalculator.sunTimes(
                now,
                lat: AppLocation.lat,
                lon: AppLocation.lon,
              );
              final nakIdx = PanchangCalculator.nakshatraIndexFor(now);
              return SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _modeChip('🌅 সূর্যোদয় ${bnTime12(sun.sunrise)}'),
                    _modeChip('🌇 সূর্যাস্ত ${bnTime12(sun.sunset)}'),
                    _modeChip(
                      '⭐ নক্ষত্র ${PanchangCalculator.nakshatraNames[nakIdx]}',
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
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}

/// হোম স্ক্রিনে "আজ" আর "কাল" — দুটো আলাদা বক্সে পাশাপাশি।
/// প্রতিটা বক্সে সেই দিনের তিথি, আর সেদিন যত তিথি/উৎসব/পালন-দিন
/// পড়েছে (BengaliCalendarData.eventsFor থেকে) — সবগুলোই ছোট চিপ
/// আকারে দেখানো হয়, শুধু প্রথমটা নয়।
class _TodayTomorrowBoxes extends StatelessWidget {
  const _TodayTomorrowBoxes();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    // IntrinsicHeight + CrossAxisAlignment.stretch — দুটো বক্সের কনটেন্ট
    // (তিথি/উৎসব সংখ্যা) ভিন্ন হলেও, ছোট বক্সটা বড়টার সমান উচ্চতায়
    // টান-টান হয়ে বসে, যাতে "আজ" আর "কাল" বক্স দেখতে সবসময় সমান লাগে।
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _dayBox(
              label: 'আজ',
              date: now,
              accent: const Color(0xFFFFD36E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _dayBox(
              label: 'কাল',
              date: tomorrow,
              accent: const Color(0xFF7DC4FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayBox({
    required String label,
    required DateTime date,
    required Color accent,
  }) {
    final info = BengaliDateUtil.monthInfoFor(date);
    final bengaliDay = date.difference(info.start).inDays + 1;
    final tithi = PanchangCalculator.tithiFor(date);
    final weekday = PanchangCalculator.weekdayName(date);
    final events = BengaliCalendarData.eventsFor(date);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF08172F).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${bnNum(bengaliDay)} ${info.name} • $weekday',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            '${tithi.paksha} পক্ষ • ${tithi.name} তিথি',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (events.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: events
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${e.icon} ${e.label}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ] else ...[
            const SizedBox(height: 6),
            const Text(
              'কোনো বিশেষ উৎসব নেই',
              style: TextStyle(color: Colors.white38, fontSize: 10.5),
            ),
          ],
        ],
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
    final abhijit = PanchangCalculator.abhijitMuhurta(now);
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
      if (abhijit['applicable'] == true)
        '☀️ অভিজিৎ মুহূর্ত ${bnTime12(abhijit['start'] as DateTime)}–${bnTime12(abhijit['end'] as DateTime)}'
      else
        '☀️ অভিজিৎ মুহূর্ত আজ প্রযোজ্য নয় (বুধবার)',
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
              fontSize: 13,
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
                  style: const TextStyle(color: Colors.white, fontSize: 12),
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
    final abhijit = PanchangCalculator.abhijitMuhurta(now);
    final abhijitText = abhijit['applicable'] == true
        ? '☀️ অভিজিৎ মুহূর্ত ${bnTime12(abhijit['start'] as DateTime)}–${bnTime12(abhijit['end'] as DateTime)} • '
        : '';
    return '☀️ সূর্যোদয় ${bnTime12(sun.sunrise)} • '
        '🌇 সূর্যাস্ত ${bnTime12(sun.sunset)} • '
        '⏳ রাহুকাল ${bnTime12(rahu['start']!)}–${bnTime12(rahu['end']!)} • '
        '${abhijitText}আজ ${tithi.name} তিথি • '
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
    _controller
        .animateTo(
          max,
          duration: const Duration(seconds: 14),
          curve: Curves.linear,
        )
        .then((_) {
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
          style: const TextStyle(color: Colors.white70, fontSize: 13),
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
            style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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

/// হোম স্ক্রিনের "আসন্ন উৎসব" — শুধু নাম/তারিখ না দেখিয়ে, প্রতিটার সাথে
/// "আজ" / "কাল" / "X দিন বাকি" কাউন্টডাউন আর একটা শেয়ার-বাটনও দেখায়।
class _UpcomingFestivalsCard extends StatelessWidget {
  final int count;
  const _UpcomingFestivalsCard({this.count = 3});

  String _countdownLabel(int daysLeft) {
    if (daysLeft <= 0) return 'আজ';
    if (daysLeft == 1) return 'কাল';
    return '${bnNum(daysLeft)} দিন বাকি';
  }

  void _shareFestival(
    String icon,
    String title,
    String date,
    String countdown,
  ) {
    Share.share(
      '$icon শুভ $title\n📅 $date • $countdown\n\n📲 বাংলা পঞ্জিকা অ্যাপ থেকে',
      subject: title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final festivals = BengaliCalendarData.upcomingFestivals(count: count);
    final boxDecoration = BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF4D220D), Color(0xFF15152F)],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF3B35D).withValues(alpha: 0.4)),
    );

    if (festivals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: boxDecoration,
        child: const Text(
          '🌍 কোনো তথ্য নেই — পরে দেখুন',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      );
    }

    return Container(
      decoration: boxDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: List.generate(festivals.length, (i) {
          final f = festivals[i];
          final icon = f['icon'] ?? '🎉';
          final title = f['title'] ?? '';
          final date = f['date'] ?? 'শীঘ্রই';
          final daysLeft = int.tryParse(f['daysLeft'] ?? '') ?? 0;
          final countdown = _countdownLabel(daysLeft);
          // উৎসবের জন্য অ্যাপের নিজস্ব আঁকা illustration (থাকলে)
          final motif = PanjikaArt.motifFor(title, 'general');
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              border: i == festivals.length - 1
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
            ),
            child: Row(
              children: [
                if (motif != null) ...[
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: PanjikaArt(motif, size: 28),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        motif != null ? title : '$icon $title',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD36E).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFFFD36E).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    countdown,
                    style: const TextStyle(
                      color: Color(0xFFFFD36E),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _shareFestival(icon, title, date, countdown),
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.share_rounded,
                      color: Color(0xFFFFD36E),
                      size: 18,
                    ),
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

/// পূর্ণিমা ও অমাবস্যা — একই বাক্সে ২টা টগল বাটন দিয়ে দেখানো হয় (আগে দুটো
/// আলাদা শীট ছিল)। দুটোই real তিথি হিসেব থেকে আজকের পরের তারিখ দেখায়,
/// তাই তারিখ পার হয়ে গেলে পুরনো তারিখ আর দেখা যায় না।
class _MoonPhaseSheet extends StatefulWidget {
  final bool initialIsPurnima;
  const _MoonPhaseSheet({required this.initialIsPurnima});

  @override
  State<_MoonPhaseSheet> createState() => _MoonPhaseSheetState();
}

class _MoonPhaseSheetState extends State<_MoonPhaseSheet> {
  late bool _isPurnima = widget.initialIsPurnima;

  @override
  Widget build(BuildContext context) {
    final title = _isPurnima ? 'পূর্ণিমা' : 'অমাবস্যা';
    final items = ContentData.categories[title] ?? const [];
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _moonToggleButton(
                        label: '🌕 পূর্ণিমা',
                        selected: _isPurnima,
                        onTap: () => setState(() => _isPurnima = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _moonToggleButton(
                        label: '🌑 অমাবস্যা',
                        selected: !_isPurnima,
                        onTap: () => setState(() => _isPurnima = false),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: items.isEmpty
                      ? [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: const Text(
                              'আগামী কিছুদিনে কোনো তারিখ পাওয়া যায়নি।',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ]
                      : items
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _moonToggleButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFD36E).withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xFFFFD36E).withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFFFFD36E) : Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
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
                                      fontSize: 13,
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

  // প্রোফাইল এখন এখানে নেই — সাইড মেনুর (☰) মধ্যে নিয়ে যাওয়া হয়েছে, আর
  // এই জায়গায় সরাসরি প্রিমিয়াম পেজে যাওয়ার শর্টকাট বসানো হয়েছে
  static const _navs = [
    ['🏠', 'হোম'],
    ['📅', 'ক্যালেন্ডার'],
    ['🪷', 'পঞ্জিকা'],
    ['🔮', 'রাশি'],
    ['✨', 'প্রিমিয়াম'],
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
                  child: const _MiniIstClock(),
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
              fontSize: 11,
              color: active ? const Color(0xFFFFD36E) : Colors.white70,
              fontWeight: active ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// নিচের নেভিগেশন বারের মাঝের গোল বোতামে আগে একটা স্থির '✦' চিহ্ন ছিল —
/// এখন তার বদলে একটা ছোট্ট সচল কাঁটাওয়ালা (অ্যানালগ) ঘড়ি আছে, যেটা
/// প্রতি সেকেন্ডে ভারতীয় সময় (IST, UTC+5:30 — সারা বছর একই, DST নেই)
/// অনুযায়ী ঘণ্টা/মিনিট/সেকেন্ডের কাঁটা ঘুরিয়ে দেখায়।
class _MiniIstClock extends StatefulWidget {
  const _MiniIstClock();
  @override
  State<_MiniIstClock> createState() => _MiniIstClockState();
}

class _MiniIstClockState extends State<_MiniIstClock> {
  Timer? _timer;
  late DateTime _istNow = _computeIst();

  static DateTime _computeIst() =>
      DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _istNow = _computeIst());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(54, 54),
      painter: _AnalogClockPainter(_istNow),
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  final DateTime istTime;
  _AnalogClockPainter(this.istTime);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // ঘড়ির ডায়াল
    canvas.drawCircle(
      center,
      radius - 3,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      center,
      radius - 3,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // ১২টি ঘণ্টার দাগ
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final isMajor = i % 3 == 0;
      final outer = Offset(
        center.dx + (radius - 4) * math.sin(angle),
        center.dy - (radius - 4) * math.cos(angle),
      );
      final inner = Offset(
        center.dx + (radius - (isMajor ? 10 : 6)) * math.sin(angle),
        center.dy - (radius - (isMajor ? 10 : 6)) * math.cos(angle),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..strokeWidth = isMajor ? 1.8 : 1.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // ১২, ৩, ৬, ৯ — চারটে প্রধান ঘণ্টার সংখ্যা ডায়ালে
    void drawNumber(String text, int hourIndex) {
      final angle = (hourIndex * 30) * math.pi / 180;
      final r = radius * 0.6;
      final pos = Offset(
        center.dx + r * math.sin(angle),
        center.dy - r * math.cos(angle),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: radius * 0.34,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    drawNumber('12', 0);
    drawNumber('3', 3);
    drawNumber('6', 6);
    drawNumber('9', 9);

    final hourAngle = ((istTime.hour % 12) + istTime.minute / 60) * 30;
    final minuteAngle = (istTime.minute + istTime.second / 60) * 6;
    final secondAngle = istTime.second * 6.0;

    void drawHand(double angleDeg, double length, double width, Color color) {
      final angle = (angleDeg - 90) * math.pi / 180;
      final end = Offset(
        center.dx + length * math.cos(angle),
        center.dy + length * math.sin(angle),
      );
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    drawHand(hourAngle, radius * 0.40, 2.8, Colors.white);
    drawHand(minuteAngle, radius * 0.62, 2.0, Colors.white);
    drawHand(secondAngle, radius * 0.68, 1.0, const Color(0xFFFFD36E));

    canvas.drawCircle(center, 2.4, Paint()..color = const Color(0xFFFFD36E));
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter old) =>
      old.istTime.second != istTime.second;
}

// =====================================================================
// বিশ্ব ঘড়ি (World Clock) — নিচের নেভিগেশন বারের ঘড়ি-বাটনে চাপলে খোলে
// =====================================================================

/// একটা দেশ/শহরের real টাইমজোন তথ্য — IANA টাইমজোন আইডি (tzId) দিয়ে
/// প্রকৃত অফসেট (DST-সহ, যেখানে প্রযোজ্য) বের করা হয়; ওয়েবে টাইমজোন
/// ডেটাবেস লোড করা যায় না বলে সেখানে [fallbackOffset] (ঘণ্টায়) ব্যবহার হয়।
class _WorldCity {
  final String name;
  final String flag;
  final String tzId;
  final double fallbackOffset;
  const _WorldCity(this.name, this.flag, this.tzId, this.fallbackOffset);
}

const List<_WorldCity> _worldCities = [
  _WorldCity('ভারত', '🇮🇳', 'Asia/Kolkata', 5.5),
  _WorldCity('বাংলাদেশ', '🇧🇩', 'Asia/Dhaka', 6.0),
  _WorldCity('নেপাল', '🇳🇵', 'Asia/Kathmandu', 5.75),
  _WorldCity('পাকিস্তান', '🇵🇰', 'Asia/Karachi', 5.0),
  _WorldCity('শ্রীলঙ্কা', '🇱🇰', 'Asia/Colombo', 5.5),
  _WorldCity('যুক্তরাজ্য', '🇬🇧', 'Europe/London', 0.0),
  _WorldCity('ফ্রান্স', '🇫🇷', 'Europe/Paris', 1.0),
  _WorldCity('জার্মানি', '🇩🇪', 'Europe/Berlin', 1.0),
  _WorldCity('স্পেন', '🇪🇸', 'Europe/Madrid', 1.0),
  _WorldCity('ইতালি', '🇮🇹', 'Europe/Rome', 1.0),
  _WorldCity('রাশিয়া (মস্কো)', '🇷🇺', 'Europe/Moscow', 3.0),
  _WorldCity('তুরস্ক', '🇹🇷', 'Europe/Istanbul', 3.0),
  _WorldCity('সংযুক্ত আরব আমিরাত', '🇦🇪', 'Asia/Dubai', 4.0),
  _WorldCity('সৌদি আরব', '🇸🇦', 'Asia/Riyadh', 3.0),
  _WorldCity('চীন', '🇨🇳', 'Asia/Shanghai', 8.0),
  _WorldCity('জাপান', '🇯🇵', 'Asia/Tokyo', 9.0),
  _WorldCity('দক্ষিণ কোরিয়া', '🇰🇷', 'Asia/Seoul', 9.0),
  _WorldCity('সিঙ্গাপুর', '🇸🇬', 'Asia/Singapore', 8.0),
  _WorldCity('ইন্দোনেশিয়া', '🇮🇩', 'Asia/Jakarta', 7.0),
  _WorldCity('থাইল্যান্ড', '🇹🇭', 'Asia/Bangkok', 7.0),
  _WorldCity('যুক্তরাষ্ট্র (নিউ ইয়র্ক)', '🇺🇸', 'America/New_York', -5.0),
  _WorldCity(
    'যুক্তরাষ্ট্র (লস অ্যাঞ্জেলেস)',
    '🇺🇸',
    'America/Los_Angeles',
    -8.0,
  ),
  _WorldCity('কানাডা', '🇨🇦', 'America/Toronto', -5.0),
  _WorldCity('ব্রাজিল', '🇧🇷', 'America/Sao_Paulo', -3.0),
  _WorldCity('মেক্সিকো', '🇲🇽', 'America/Mexico_City', -6.0),
  _WorldCity('দক্ষিণ আফ্রিকা', '🇿🇦', 'Africa/Johannesburg', 2.0),
  _WorldCity('মিশর', '🇪🇬', 'Africa/Cairo', 2.0),
  _WorldCity('অস্ট্রেলিয়া (সিডনি)', '🇦🇺', 'Australia/Sydney', 11.0),
  _WorldCity('নিউজিল্যান্ড', '🇳🇿', 'Pacific/Auckland', 13.0),
];

class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({super.key});
  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// [city]-র প্রকৃত স্থানীয় সময় — মোবাইল/ডেস্কটপে IANA টাইমজোন ডেটাবেস
  /// (DST-সহ real হিসেব) থেকে, ওয়েবে fallback ফিক্সড অফসেট থেকে
  DateTime _localTime(_WorldCity city) {
    if (!kIsWeb) {
      try {
        final loc = tz.getLocation(city.tzId);
        final t = tz.TZDateTime.now(loc);
        return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
      } catch (_) {}
    }
    return DateTime.now().toUtc().add(
      Duration(minutes: (city.fallbackOffset * 60).round()),
    );
  }

  double _offsetHours(_WorldCity city) {
    if (!kIsWeb) {
      try {
        final loc = tz.getLocation(city.tzId);
        return tz.TZDateTime.now(loc).timeZoneOffset.inMinutes / 60.0;
      } catch (_) {}
    }
    return city.fallbackOffset;
  }

  String _bnClock(DateTime dt) {
    final h12raw = dt.hour % 12;
    final h12 = h12raw == 0 ? 12 : h12raw;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '${bnDigits(h12.toString())}:${bnDigits(dt.minute.toString().padLeft(2, '0'))}:${bnDigits(dt.second.toString().padLeft(2, '0'))} $ampm';
  }

  String _diffText(double cityOffset, double indiaOffset) {
    final diff = cityOffset - indiaOffset;
    if (diff.abs() < 0.01) return 'ভারতের সাথে সময় একই';
    final absDiff = diff.abs();
    final hours = absDiff.truncate();
    final minutes = ((absDiff - hours) * 60).round();
    final hm = minutes == 0
        ? '${bnNum(hours)} ঘণ্টা'
        : '${bnNum(hours)} ঘণ্টা ${bnNum(minutes)} মিনিট';
    return diff > 0 ? 'ভারতের চেয়ে $hm এগিয়ে' : 'ভারতের চেয়ে $hm পিছিয়ে';
  }

  /// দিন না রাত — সাধারণ ঘড়ির সময় ধরে (সকাল ৬টা–সন্ধ্যা ৬টা দিন)
  (String, bool) _dayNight(DateTime local) {
    final h = local.hour;
    final isDay = h >= 6 && h < 18;
    return (isDay ? '☀️ দিন' : '🌙 রাত', isDay);
  }

  @override
  Widget build(BuildContext context) {
    final indiaOffset = _offsetHours(_worldCities.first);
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '🌍 বিশ্ব ঘড়ি'),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _worldCities.length,
              itemBuilder: (context, i) {
                final city = _worldCities[i];
                final local = _localTime(city);
                final offset = _offsetHours(city);
                final (dayNightLabel, isDay) = _dayNight(local);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 68,
                        height: 68,
                        child: CustomPaint(painter: _AnalogClockPainter(local)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  city.flag,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    city.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              i == 0
                                  ? dayNightLabel
                                  : '${_diffText(offset, indiaOffset)} • $dayNightLabel',
                              style: TextStyle(
                                color: isDay
                                    ? const Color(0xFFFFD36E)
                                    : Colors.white60,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _bnClock(local),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// রাশিফল — পূর্ণ পেজ (চাকার মতো ঘূর্ণমান রাশিচক্র + আজকের ফল + জন্ম-রাশি)
// =====================================================================

/// প্রতিটা রাশির ভাব (অগ্নি/পৃথিবী/বায়ু/জল), অধিপতি গ্রহ ও এক লাইনের
/// বৈশিষ্ট্য — [PanchangCalculator.rashiNames]-এর ক্রম অনুযায়ী (মেষ..মীন)
class _RashiMeta {
  final String element;
  final String rulingPlanet;
  final String trait;
  const _RashiMeta(this.element, this.rulingPlanet, this.trait);
}

const List<_RashiMeta> _rashiMetaList = [
  _RashiMeta('🔥 অগ্নি', 'মঙ্গল', 'সাহসী ও উদ্যমী'),
  _RashiMeta('🌍 পৃথিবী', 'শুক্র', 'স্থিতধী ও বিশ্বস্ত'),
  _RashiMeta('💨 বায়ু', 'বুধ', 'বুদ্ধিদীপ্ত ও যোগাযোগপ্রিয়'),
  _RashiMeta('💧 জল', 'চন্দ্র', 'সংবেদনশীল ও যত্নশীল'),
  _RashiMeta('🔥 অগ্নি', 'সূর্য', 'আত্মবিশ্বাসী ও নেতৃত্বপ্রবণ'),
  _RashiMeta('🌍 পৃথিবী', 'বুধ', 'বিশ্লেষণী ও নিখুঁত'),
  _RashiMeta('💨 বায়ু', 'শুক্র', 'ভারসাম্যপ্রিয় ও কূটনৈতিক'),
  _RashiMeta('💧 জল', 'মঙ্গল', 'দৃঢ় ও রহস্যময়'),
  _RashiMeta('🔥 অগ্নি', 'বৃহস্পতি', 'স্বাধীনচেতা ও ভ্রমণপ্রিয়'),
  _RashiMeta('🌍 পৃথিবী', 'শনি', 'পরিশ্রমী ও লক্ষ্যস্থির'),
  _RashiMeta('💨 বায়ু', 'শনি', 'উদ্ভাবনী ও স্বতন্ত্র'),
  _RashiMeta('💧 জল', 'বৃহস্পতি', 'কল্পনাপ্রবণ ও সহানুভূতিশীল'),
];

/// ক্রমাগত ঘুরতে থাকা রাশিচক্র — ১২টা রাশির নাম/চিহ্ন সবসময় দেখা যায়,
/// পুরো চাকাটা ধীরে ধীরে ঘোরে (নামগুলো নিজে সবসময় সোজা/পাঠযোগ্য থাকে)
class _RashiWheel extends StatefulWidget {
  const _RashiWheel();
  @override
  State<_RashiWheel> createState() => _RashiWheelState();
}

class _RashiWheelState extends State<_RashiWheel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 70),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 260.0;
    const labelRadius = size / 2 - 34;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final baseAngle = _controller.value * 2 * math.pi;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFD36E).withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.3,
                  ),
                ),
              ),
              Container(
                width: size - 60,
                height: size - 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
              ),
              for (int i = 0; i < 12; i++)
                Transform.translate(
                  offset: Offset(
                    labelRadius * math.cos(baseAngle + i * 30 * math.pi / 180),
                    labelRadius * math.sin(baseAngle + i * 30 * math.pi / 180),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ContentData._rashiSymbols[i],
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFFFFD36E),
                        ),
                      ),
                      Text(
                        PanchangCalculator.rashiNames[i],
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const Text('🔮', style: TextStyle(fontSize: 30)),
            ],
          );
        },
      ),
    );
  }
}

/// জন্ম-তারিখ ও সময় দিলে, ওই মুহূর্তে চাঁদ real হিসেবে কোন রাশিতে ছিল
/// (Vedic চন্দ্র-রাশি) তা বের করে দেখায় — কোনো জেনেরিক টেক্সট নয়,
/// [PanchangCalculator.rashiIndexFor] দিয়ে প্রকৃত জ্যোতির্বিদ্যা হিসেব।
class _BirthRashiFinder extends StatefulWidget {
  const _BirthRashiFinder();
  @override
  State<_BirthRashiFinder> createState() => _BirthRashiFinderState();
}

class _BirthRashiFinderState extends State<_BirthRashiFinder> {
  DateTime? _dob;
  TimeOfDay? _tob;
  int? _resultIndex;

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null && mounted) setState(() => _dob = picked);
  }

  Future<void> _pickTob() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) setState(() => _tob = picked);
  }

  void _findRashi() {
    if (_dob == null || _tob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('জন্ম তারিখ ও সময় দুটোই দিন')),
      );
      return;
    }
    final birth = DateTime(
      _dob!.year,
      _dob!.month,
      _dob!.day,
      _tob!.hour,
      _tob!.minute,
    );
    setState(() {
      _resultIndex = PanchangCalculator.rashiIndexFor(birth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔍 আপনার জন্ম-রাশি বের করুন',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'জন্ম তারিখ ও সময়ে চাঁদ প্রকৃতপক্ষে কোন রাশিতে ছিল, তার real হিসেব',
            style: TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDob,
                  icon: const Icon(
                    Icons.calendar_today,
                    size: 15,
                    color: Colors.white,
                  ),
                  label: Text(
                    _dob == null
                        ? 'জন্ম তারিখ'
                        : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTob,
                  icon: const Icon(
                    Icons.access_time,
                    size: 15,
                    color: Colors.white,
                  ),
                  label: Text(
                    _tob == null ? 'জন্ম সময়' : _tob!.format(context),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _findRashi,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD36E),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'রাশি বের করুন',
                style: TextStyle(
                  color: Color(0xFF071428),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_resultIndex != null) ...[
            const SizedBox(height: 14),
            Builder(
              builder: (context) {
                final idx = _resultIndex!;
                final meta = _rashiMetaList[idx];
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD36E).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFD36E).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ContentData._rashiSymbols[idx]} আপনার রাশি: ${PanchangCalculator.rashiNames[idx]}',
                        style: const TextStyle(
                          color: Color(0xFFFFD36E),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ভাব: ${meta.element}  •  অধিপতি গ্রহ: ${meta.rulingPlanet}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'বৈশিষ্ট্য: ${meta.trait}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// একটা রাশির বিস্তারিত — ট্যাপ করলে ভাব/অধিপতি গ্রহ/বৈশিষ্ট্য দেখায়
void _showRashiDetail(BuildContext context, int idx, [String? forecast]) {
  final meta = _rashiMetaList[idx];
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF0B1B35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${ContentData._rashiSymbols[idx]} ${PanchangCalculator.rashiNames[idx]}',
            style: const TextStyle(
              color: Color(0xFFFFD36E),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          if (forecast != null) ...[
            const SizedBox(height: 12),
            Text(
              'আজকের ফল: $forecast',
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'ভাব: ${meta.element}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'অধিপতি গ্রহ: ${meta.rulingPlanet}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'বৈশিষ্ট্য: ${meta.trait}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 18),
        ],
      ),
    ),
  );
}

class RashiScreen extends StatelessWidget {
  const RashiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = ContentData.categories['রাশিফল'] ?? const <List<String>>[];
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '🔮 রাশিফল'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 150),
                Center(child: const _RashiWheel()),
                const SizedBox(height: 20),
                const _SectionTitle('আজকের রাশিফল (সব রাশি)'),
                const SizedBox(height: 4),
                const Text(
                  'যেকোনো রাশিতে ট্যাপ করলে তার বিস্তারিত ফল দেখাবে',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
                const SizedBox(height: 10),
                // ১২টা রাশি — ১ম লাইনে ৬টা, ২য় লাইনে ৬টা বক্স, ট্যাপ করলে
                // সেই রাশির বিস্তারিত ফল নিচে শীট আকারে খুলবে
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 6,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.8,
                  children: List.generate(rows.length, (i) {
                    final r = rows[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showRashiDetail(context, i, r[1]),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ContentData._rashiSymbols[i],
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFFFFD36E),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              PanchangCalculator.rashiNames[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                const _SectionTitle('জন্ম-রাশি ক্যালকুলেটর'),
                const SizedBox(height: 10),
                const _BirthRashiFinder(),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// শ্রাদ্ধ তিথি ফাইন্ডার — মৃত্যুর তারিখের তিথি অনুযায়ী পরবর্তী বছরগুলোর
// বার্ষিক শ্রাদ্ধের তারিখ (তিথি মিলিয়ে) বের করে
// =====================================================================

class ShraddhaTithiScreen extends StatefulWidget {
  const ShraddhaTithiScreen({super.key});
  @override
  State<ShraddhaTithiScreen> createState() => _ShraddhaTithiScreenState();
}

class _ShraddhaTithiScreenState extends State<ShraddhaTithiScreen> {
  DateTime? _deathDate;
  List<Map<String, dynamic>>? _results;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(1930),
      lastDate: now,
      helpText: 'মৃত্যুর তারিখ নির্বাচন করুন',
    );
    if (picked != null) {
      setState(() {
        _deathDate = picked;
        _results = null;
      });
    }
  }

  /// [targetIdx] তিথি (০-২৯) [approx] তারিখের কাছাকাছি (±২২ দিনের মধ্যে)
  /// খুঁজে বের করে — চান্দ্র তিথি প্রতি সৌরবছরে প্রায় ১০-১১ দিন এগিয়ে আসে
  /// বলে একই গ্রেগরিয়ান তারিখে খুঁজলে মিলবে না, তাই আশেপাশে অনুসন্ধান করা হয়
  DateTime? _findTithiNear(int targetIdx, DateTime approx) {
    DateTime? best;
    int bestDiff = 999;
    for (int off = -22; off <= 22; off++) {
      final day = approx.add(Duration(days: off));
      final t = PanchangCalculator.tithiFor(
        DateTime(day.year, day.month, day.day, 6, 0),
      );
      if (t.index == targetIdx && off.abs() < bestDiff) {
        bestDiff = off.abs();
        best = day;
      }
    }
    return best;
  }

  void _calculate() {
    if (_deathDate == null) return;
    final tithi = PanchangCalculator.tithiFor(
      DateTime(_deathDate!.year, _deathDate!.month, _deathDate!.day, 6, 0),
    );
    final results = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int y = 1; y <= 6; y++) {
      final year = _deathDate!.year + y;
      if (year < now.year) continue;
      final approx = DateTime(year, _deathDate!.month, _deathDate!.day);
      final found = _findTithiNear(tithi.index, approx);
      if (found != null) {
        final info = BengaliDateUtil.monthInfoFor(found);
        final bDay = found.difference(info.start).inDays + 1;
        results.add({
          'date': found,
          'label': '${bnNum(bDay)} ${info.name} ${bnNum(info.year)}',
        });
      }
    }
    results.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );
    setState(() => _results = results);
  }

  Widget _card({required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF08172F).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD36E).withValues(alpha: 0.22),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tithi = _deathDate != null
        ? PanchangCalculator.tithiFor(
            DateTime(
              _deathDate!.year,
              _deathDate!.month,
              _deathDate!.day,
              6,
              0,
            ),
          )
        : null;
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '🕯️ শ্রাদ্ধ তিথি ফাইন্ডার'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'প্রিয়জনের মৃত্যুর (ইংরেজি) তারিখ দিন — সেই দিনের তিথি অনুযায়ী '
                  'পরবর্তী বছরগুলোর বার্ষিক শ্রাদ্ধের তারিখ বের করে দেবে।',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(
                            Icons.calendar_month,
                            color: Color(0xFFFFD36E),
                          ),
                          label: Text(
                            _deathDate == null
                                ? 'মৃত্যুর তারিখ বেছে নিন'
                                : '${bnNum(_deathDate!.day)}/${bnNum(_deathDate!.month)}/${bnNum(_deathDate!.year)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFFD36E)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (tithi != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'ওই দিনের তিথি: ${tithi.paksha} পক্ষ • ${tithi.name}',
                          style: const TextStyle(
                            color: Color(0xFFFFD36E),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _calculate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD36E),
                            ),
                            child: const Text(
                              'বার্ষিক শ্রাদ্ধ তিথি বের করুন',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_results != null) ...[
                  const SizedBox(height: 18),
                  const _SectionTitle('পরবর্তী বছরগুলোর শ্রাদ্ধ তিথি'),
                  const SizedBox(height: 8),
                  ..._results!.map((r) {
                    final d = r['date'] as DateTime;
                    return _card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Text('🕯️', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${bnNum(d.day)} ${gregMonthBn(d.month)} ${bnNum(d.year)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  r['label'] as String,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  const Text(
                    '⚠️ এটি তিথি-ভিত্তিক আনুমানিক হিসেব (±১ দিন কাছাকাছি হতে পারে)। '
                    'চূড়ান্ত সিদ্ধান্তের আগে পারিবারিক পুরোহিতের সাথে যাচাই করে নেওয়া ভালো।',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// স্থানীয় মন্দির/পূজার সময়সূচি ম্যানেজার
// =====================================================================

class TempleScreen extends StatefulWidget {
  const TempleScreen({super.key});
  @override
  State<TempleScreen> createState() => _TempleScreenState();
}

class _TempleScreenState extends State<TempleScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    TempleStore.instance.load().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  Future<void> _addDialog() async {
    final templeCtrl = TextEditingController();
    final pujaCtrl = TextEditingController();
    DateTime when = DateTime.now().add(const Duration(days: 1));
    bool reminder = true;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF0B1C38),
          title: const Text(
            'নতুন পূজা/মন্দির সূচি',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: templeCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'মন্দির/স্থানের নাম',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: pujaCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'পূজার নাম',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: when,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (d == null) return;
                      if (!ctx.mounted) return;
                      final t = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(when),
                      );
                      if (t == null) return;
                      setSt(
                        () => when = DateTime(
                          d.year,
                          d.month,
                          d.day,
                          t.hour,
                          t.minute,
                        ),
                      );
                    },
                    child: Text(
                      '${when.day}/${when.month}/${when.year} — ${TimeOfDay.fromDateTime(when).format(ctx)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'নোটিফিকেশন রিমাইন্ডার',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                    Switch(
                      value: reminder,
                      activeColor: const Color(0xFFFFD36E),
                      onChanged: (v) => setSt(() => reminder = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (templeCtrl.text.trim().isEmpty ||
                    pujaCtrl.text.trim().isEmpty) {
                  return;
                }
                await TempleStore.instance.add(
                  TempleEvent(
                    temple: templeCtrl.text.trim(),
                    pujaName: pujaCtrl.text.trim(),
                    when: when,
                    reminderOn: reminder,
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD36E),
              ),
              child: const Text(
                'যোগ করুন',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = TempleStore.instance.items;
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '🛕 মন্দির ও পূজার সময়সূচি'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addDialog,
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text(
                  'নতুন পূজা/মন্দির সূচি যোগ করুন',
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD36E),
                ),
              ),
            ),
          ),
          Expanded(
            child: !_loaded
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFD36E)),
                  )
                : items.isEmpty
                ? const Center(
                    child: Text(
                      'এখনো কোনো সূচি যোগ করা হয়নি',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final e = items[i];
                      return Dismissible(
                        key: ValueKey(e.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                        ),
                        onDismissed: (_) async {
                          await TempleStore.instance.remove(e);
                          if (mounted) setState(() {});
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF08172F,
                            ).withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(
                                0xFFFFD36E,
                              ).withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('🛕', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.temple,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      e.pujaName,
                                      style: const TextStyle(
                                        color: Color(0xFFFFD36E),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    Text(
                                      '${e.when.day}/${e.when.month}/${e.when.year} • ${TimeOfDay.fromDateTime(e.when).format(context)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (e.reminderOn)
                                const Icon(
                                  Icons.notifications_active,
                                  color: Color(0xFFFFD36E),
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// মাসিক পঞ্জিকা PDF এক্সপোর্ট
// =====================================================================

class PdfExportScreen extends StatefulWidget {
  const PdfExportScreen({super.key});
  @override
  State<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends State<PdfExportScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _busy = false;
  pw.Font? _fontRegular;
  pw.Font? _fontBold;

  Future<void> _loadFonts() async {
    if (_fontRegular != null) return;
    final reg = await rootBundle.load(
      'assets/fonts/NotoSansBengali-Regular.ttf',
    );
    final bold = await rootBundle.load('assets/fonts/NotoSansBengali-Bold.ttf');
    _fontRegular = pw.Font.ttf(reg);
    _fontBold = pw.Font.ttf(bold);
  }

  Future<Uint8List> _buildPdf() async {
    await _loadFonts();
    final doc = pw.Document();
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = <List<String>>[];
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_month.year, _month.month, d);
      SunTimes sun;
      try {
        sun = PanchangCalculator.sunTimes(
          date,
          lat: AppLocation.lat,
          lon: AppLocation.lon,
        );
      } catch (_) {
        sun = PanchangCalculator.sunTimes(date);
      }
      final tithi = PanchangCalculator.tithiFor(sun.sunrise);
      final nakIdx = PanchangCalculator.nakshatraIndexFor(sun.sunrise);
      final info = BengaliDateUtil.monthInfoFor(date);
      final bDay = date.difference(info.start).inDays + 1;
      final events = BengaliCalendarData.eventsFor(
        date,
      ).map((e) => e.label).join(', ');
      rows.add([
        '${date.day}/${date.month}/${date.year}',
        '$bDay ${info.name}',
        '${tithi.paksha} ${tithi.name}',
        PanchangCalculator.nakshatraNames[nakIdx],
        events.isEmpty ? '—' : events,
      ]);
    }
    final theme = pw.ThemeData.withFont(base: _fontRegular!, bold: _fontBold!);
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'বাংলা পঞ্জিকা — ${_month.month}/${_month.year}',
              style: pw.TextStyle(font: _fontBold, fontSize: 18),
            ),
          ),
          pw.TableHelper.fromTextArray(
            headers: ['তারিখ', 'বাংলা তারিখ', 'তিথি', 'নক্ষত্র', 'বিশেষ দিন'],
            data: rows,
            headerStyle: pw.TextStyle(font: _fontBold, fontSize: 9),
            cellStyle: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> _exportAndShare() async {
    setState(() => _busy = true);
    try {
      final bytes = await _buildPdf();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'bangla_panjika_${_month.year}_${_month.month}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF তৈরি করতে সমস্যা হয়েছে: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preview() async {
    await Printing.layoutPdf(onLayout: (format) => _buildPdf());
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '📄 মাসিক পঞ্জিকা PDF এক্সপোর্ট'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'যেকোনো মাসের পুরো বাংলা পঞ্জিকা (তারিখ, তিথি, নক্ষত্র, বিশেষ '
                  'দিন সহ) একটা PDF ফাইলে তৈরি করে প্রিন্ট বা শেয়ার করতে পারবেন।',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF08172F).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFD36E).withValues(alpha: 0.22),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                            ),
                            onPressed: () => setState(
                              () => _month = DateTime(
                                _month.year,
                                _month.month - 1,
                                1,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${gregMonthBn(_month.month)} ${bnNum(_month.year)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                            onPressed: () => setState(
                              () => _month = DateTime(
                                _month.year,
                                _month.month + 1,
                                1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _preview,
                              icon: const Icon(
                                Icons.visibility,
                                color: Color(0xFFFFD36E),
                              ),
                              label: const Text(
                                'প্রিভিউ / প্রিন্ট',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFFFD36E),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _busy ? null : _exportAndShare,
                              icon: _busy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.share,
                                      color: Colors.black,
                                    ),
                              label: const Text(
                                'PDF শেয়ার করুন',
                                style: TextStyle(color: Colors.black),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD36E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

/// জন্ম তারিখ+সময় বেছে নেওয়ার জন্য পুনঃব্যবহারযোগ্য বাটন — কুষ্ঠি চার্ট ও
/// কুষ্ঠি মিলন দুই জায়গাতেই ব্যবহার হয়
class _DateTimePickerField extends StatefulWidget {
  final String label;
  final ValueChanged<DateTime> onChanged;
  const _DateTimePickerField({required this.label, required this.onChanged});
  @override
  State<_DateTimePickerField> createState() => _DateTimePickerFieldState();
}

class _DateTimePickerFieldState extends State<_DateTimePickerField> {
  DateTime? _value;

  Future<void> _pick() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1930),
      lastDate: now,
    );
    if (d == null) return;
    if (!mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
    );
    if (t == null) return;
    final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() => _value = dt);
    widget.onChanged(dt);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _pick,
        icon: const Icon(Icons.calendar_month, color: Color(0xFFFFD36E)),
        label: Text(
          _value == null
              ? widget.label
              : '${_value!.day}/${_value!.month}/${_value!.year} — ${TimeOfDay.fromDateTime(_value!).format(context)}',
          style: const TextStyle(color: Colors.white),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFFD36E)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// =====================================================================
// জন্ম-কুষ্ঠি চার্ট (চন্দ্র কুষ্ঠি) — Sun/Moon/Mars/Jupiter/Venus/Saturn
// দিয়ে D1 রাশি চার্ট। লগ্ন (Ascendant) হিসেব করতে জন্মস্থানের নির্ভুল
// অক্ষাংশ/দ্রাঘিমাংশ লাগে বলে এটা রাশি-নির্ভর চার্ট, ভাব-চার্ট নয়। রাহু/
// কেতু "mean node" সূত্রে হিসেব করা (true node নয়) — প্রথাগত পঞ্জিকায়
// এভাবেই হিসেব হয়।
// =====================================================================

class KundliScreen extends StatefulWidget {
  const KundliScreen({super.key});
  @override
  State<KundliScreen> createState() => _KundliScreenState();
}

class _KundliScreenState extends State<KundliScreen> {
  DateTime? _birth;
  bool _showFullChart = false;

  @override
  Widget build(BuildContext context) {
    Map<int, List<String>>? placements;
    int? moonIdx, nakIdx, sunIdx, pada;
    if (_birth != null) {
      final dt = _birth!;
      sunIdx = PanchangCalculator.sunRashiIndexFor(dt);
      moonIdx = PanchangCalculator.rashiIndexFor(dt);
      nakIdx = PanchangCalculator.nakshatraIndexFor(dt);
      pada = PanchangCalculator.nakshatraPadaFor(dt);
      final map = <int, List<String>>{};
      void put(int idx, String label) =>
          map.putIfAbsent(idx, () => []).add(label);
      put(sunIdx, '☀️ সূর্য');
      put(moonIdx, '🌙 চন্দ্র');
      const planetLabels = {
        'mercury': '🟢 বুধ',
        'mars': '🔴 মঙ্গল',
        'jupiter': '🟡 বৃহস্পতি',
        'venus': '💫 শুক্র',
        'saturn': '🪐 শনি',
      };
      for (final key in ['mercury', 'mars', 'jupiter', 'venus', 'saturn']) {
        final idx = PanchangCalculator.planetRashiIndexFor(key, dt);
        final retro = PanchangCalculator.planetIsRetrograde(key, dt);
        put(idx, retro ? '${planetLabels[key]} (ব)' : planetLabels[key]!);
      }
      put(PanchangCalculator.rahuRashiIndexFor(dt), '🐍 রাহু');
      put(PanchangCalculator.ketuRashiIndexFor(dt), '🪷 কেতু');
      placements = map;
    }
    final ownGrahas = placements?[moonIdx] ?? const <String>[];

    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '🪐 চন্দ্র কুষ্ঠি চার্ট'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'জন্ম তারিখ ও সময় দিন — আপনার চন্দ্র রাশি, জন্ম নক্ষত্র ও '
                  'নবগ্রহের (সূর্য থেকে কেতু) প্রকৃত অবস্থান দেখাবে — প্রতিটা '
                  'মানুষের জন্য আলাদা, একদম তার নিজের জন্ম-মুহূর্ত অনুযায়ী '
                  'হিসেব হয়। লগ্ন (Ascendant) হিসেব করতে জন্মস্থানের নির্ভুল '
                  'অক্ষাংশ/দ্রাঘিমাংশ দরকার হয় বলে এই চার্টটি চন্দ্র-রাশি '
                  'ভিত্তিক (Chandra Kundli)।',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                _DateTimePickerField(
                  label: 'জন্ম তারিখ ও সময় বেছে নিন',
                  onChanged: (dt) => setState(() => _birth = dt),
                ),
                if (_birth != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF08172F).withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD36E).withValues(alpha: 0.22),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🌙 চন্দ্র রাশি: ${PanchangCalculator.rashiNames[moonIdx!]}',
                          style: const TextStyle(
                            color: Color(0xFFFFD36E),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '⭐ জন্ম নক্ষত্র: ${PanchangCalculator.nakshatraNames[nakIdx!]} • পাদ ${bnNum(pada!)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '☀️ সূর্য রাশি: ${PanchangCalculator.rashiNames[sunIdx!]}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle('আপনার রাশি'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF7D4A10), Color(0xFF4A2C08)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFFD36E).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          ContentData._rashiSymbols[moonIdx!],
                          style: const TextStyle(fontSize: 40),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          PanchangCalculator.rashiNames[moonIdx],
                          style: const TextStyle(
                            color: Color(0xFFFFD36E),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        if (ownGrahas.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 4,
                            children: ownGrahas
                                .map(
                                  (g) => Text(
                                    g,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _showFullChart = !_showFullChart),
                      icon: Icon(
                        _showFullChart ? Icons.expand_less : Icons.expand_more,
                        color: const Color(0xFFFFD36E),
                      ),
                      label: Text(
                        _showFullChart
                            ? 'সংক্ষেপে দেখুন'
                            : 'সম্পূর্ণ D1 চার্ট (১২ ঘর) দেখুন',
                        style: const TextStyle(color: Color(0xFFFFD36E)),
                      ),
                    ),
                  ),
                ],
                if (_birth != null && _showFullChart) ...[
                  const SizedBox(height: 8),
                  const _SectionTitle('রাশি চার্ট (D1)'),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 0.85,
                    children: List.generate(12, (i) {
                      final grahas = placements?[i] ?? const <String>[];
                      final isMoonHere = i == moonIdx;
                      return Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isMoonHere
                              ? const Color(0xFF7D4A10).withValues(alpha: 0.55)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFFFFD36E,
                            ).withValues(alpha: 0.28),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ContentData._rashiSymbols[i],
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              PanchangCalculator.rashiNames[i],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            ...grahas.map(
                              (g) => Text(
                                g,
                                style: const TextStyle(
                                  color: Color(0xFFFFD36E),
                                  fontSize: 8.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ব: বক্রী গতি (retrograde)। এই চার্টের ১২টা ঘর সরাসরি ১২টা '
                    'রাশিকে (মেষ থেকে মীন) নির্দেশ করে — লগ্ন-ভিত্তিক ভাব চার্ট নয়।',
                    style: TextStyle(color: Colors.white60, fontSize: 10.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// কুষ্ঠি মিলন — অষ্টকূট গুণ মিলন (Ashtakoot Guna Milan), মোট ৩৬ গুণ।
// চন্দ্র-নক্ষত্র ও চন্দ্র-রাশির উপর ভিত্তি করে — এই দুটোই মিলনের মূল
// ভিত্তি এবং এই অ্যাপে real হিসেব থেকে নির্ভুলভাবে বের করা সম্ভব।
// =====================================================================

class GunaKoot {
  final String name;
  final double score;
  final double max;
  final String note;
  const GunaKoot(this.name, this.score, this.max, this.note);
}

class KundliMilanResult {
  final List<GunaKoot> koots;
  final double total;
  const KundliMilanResult(this.koots, this.total);
}

class KundliMilanCalculator {
  // রাশির বর্ণ-ক্রম (Brahmin=4 সবচেয়ে উঁচু ... Shudra=1)
  static const List<int> _varna = [3, 2, 1, 4, 3, 2, 1, 4, 3, 2, 1, 4];

  // বশ্য গ্রুপ: 0=চতুষ্পদ, 1=মানব, 2=জলচর, 3=কীট
  static const List<int> _vashya = [0, 0, 1, 2, 0, 1, 1, 3, 1, 0, 1, 2];
  static const List<double> _vashyaM = [
    2, 1, 1, 0, //
    1, 2, 1, 0, //
    1, 1, 2, 0.5, //
    0, 0, 0.5, 2, //
  ];

  // ২৭ নক্ষত্রের গণ: 0=দেব, 1=মনুষ্য, 2=রাক্ষস
  static const List<int> _gana = [
    0, 1, 2, 1, 0, 1, 0, 0, 2, //
    2, 1, 1, 0, 2, 0, 2, 0, 2, //
    2, 1, 1, 0, 2, 2, 1, 1, 0, //
  ];
  static const List<List<double>> _ganaM = [
    [6, 5, 1],
    [6, 6, 0],
    [1, 0, 6],
  ];

  // নাড়ি: 0=আদি, 1=মধ্য, 2=অন্ত্য
  static const List<int> _nadi = [
    0, 1, 2, 2, 1, 0, 0, 1, 2, //
    2, 1, 0, 0, 1, 2, 2, 1, 0, //
    0, 1, 2, 2, 1, 0, 0, 1, 2, //
  ];

  // যোনি (১৪টা প্রাণী, id অনুযায়ী): 0 ঘোড়া,1 হাতি,2 ভেড়া,3 সাপ,4 কুকুর,
  // 5 বিড়াল,6 ইঁদুর,7 গরু,8 মহিষ,9 বাঘ,10 হরিণ,11 বানর,12 বেজি,13 সিংহ
  static const List<int> _yoni = [
    0, 1, 2, 3, 3, 4, 5, 2, 5, //
    6, 6, 7, 8, 9, 8, 9, 10, 10, //
    4, 11, 12, 11, 13, 0, 13, 7, 1, //
  ];
  static const List<List<int>> _yoniEnemyPairs = [
    [0, 8], [1, 13], [2, 11], [3, 12], [4, 10], [5, 6], [7, 9], //
  ];

  static const List<String> _rashiLord = [
    'mars', 'venus', 'mercury', 'moon', 'sun', 'mercury', //
    'venus', 'mars', 'jupiter', 'saturn', 'saturn', 'jupiter', //
  ];
  static const Map<String, List<String>> _friends = {
    'sun': ['moon', 'mars', 'jupiter'],
    'moon': ['sun', 'mercury'],
    'mars': ['sun', 'moon', 'jupiter'],
    'mercury': ['sun', 'venus'],
    'jupiter': ['sun', 'moon', 'mars'],
    'venus': ['mercury', 'saturn'],
    'saturn': ['mercury', 'venus'],
  };
  static const Map<String, List<String>> _enemies = {
    'sun': ['venus', 'saturn'],
    'moon': [],
    'mars': ['mercury'],
    'mercury': ['moon'],
    'jupiter': ['mercury', 'venus'],
    'venus': ['sun', 'moon'],
    'saturn': ['sun', 'moon', 'mars'],
  };

  static String _relation(String a, String b) {
    if (a == b) return 'same';
    if (_friends[a]!.contains(b)) return 'friend';
    if (_enemies[a]!.contains(b)) return 'enemy';
    return 'neutral';
  }

  static bool _isYoniEnemy(int a, int b) {
    for (final p in _yoniEnemyPairs) {
      if ((p[0] == a && p[1] == b) || (p[0] == b && p[1] == a)) return true;
    }
    return false;
  }

  static KundliMilanResult compute({
    required int brideNak,
    required int brideRashi,
    required int groomNak,
    required int groomRashi,
  }) {
    final koots = <GunaKoot>[];

    final varnaScore = _varna[groomRashi] >= _varna[brideRashi] ? 1.0 : 0.0;
    koots.add(GunaKoot('বর্ণ', varnaScore, 1, 'আধ্যাত্মিক স্বভাবের সামঞ্জস্য'));

    final vg = _vashya[brideRashi], vb = _vashya[groomRashi];
    final vashyaScore = _vashyaM[vg * 4 + vb];
    koots.add(
      GunaKoot('বশ্য', vashyaScore, 2, 'পারস্পরিক আকর্ষণ ও নিয়ন্ত্রণ'),
    );

    final c1 = ((groomNak - brideNak) % 27 + 27) % 27 + 1;
    final c2 = ((brideNak - groomNak) % 27 + 27) % 27 + 1;
    final t1 = ((c1 - 1) % 9) + 1;
    final t2 = ((c2 - 1) % 9) + 1;
    const goodTara = {2, 4, 6, 8, 9};
    final taraScore =
        (goodTara.contains(t1) ? 1.5 : 0.0) +
        (goodTara.contains(t2) ? 1.5 : 0.0);
    koots.add(GunaKoot('তারা', taraScore, 3, 'দীর্ঘায়ু ও কল্যাণ'));

    final ya = _yoni[brideNak], yb = _yoni[groomNak];
    final yoniScore = ya == yb ? 4.0 : (_isYoniEnemy(ya, yb) ? 0.0 : 2.0);
    koots.add(GunaKoot('যোনি', yoniScore, 4, 'শারীরিক ও যৌন সামঞ্জস্য'));

    final lb = _rashiLord[brideRashi], lg = _rashiLord[groomRashi];
    final rel1 = _relation(lb, lg);
    final rel2 = _relation(lg, lb);
    double gmScore;
    if (lb == lg) {
      gmScore = 5;
    } else if (rel1 == 'friend' && rel2 == 'friend') {
      gmScore = 5;
    } else if ((rel1 == 'friend' && rel2 == 'neutral') ||
        (rel1 == 'neutral' && rel2 == 'friend')) {
      gmScore = 4;
    } else if (rel1 == 'neutral' && rel2 == 'neutral') {
      gmScore = 3;
    } else if ((rel1 == 'friend' && rel2 == 'enemy') ||
        (rel1 == 'enemy' && rel2 == 'friend')) {
      gmScore = 1;
    } else if ((rel1 == 'neutral' && rel2 == 'enemy') ||
        (rel1 == 'enemy' && rel2 == 'neutral')) {
      gmScore = 0.5;
    } else {
      gmScore = 0;
    }
    koots.add(GunaKoot('গ্রহ মৈত্রী', gmScore, 5, 'মানসিক বোঝাপড়া'));

    final gaScore = _ganaM[_gana[brideNak]][_gana[groomNak]];
    koots.add(GunaKoot('গণ', gaScore, 6, 'স্বভাব ও আচরণগত মিল'));

    final bc1 = ((groomRashi - brideRashi) % 12 + 12) % 12 + 1;
    final bcDosha = {2, 5, 6, 8, 9, 12}.contains(bc1);
    final bhakootScore = bcDosha ? 0.0 : 7.0;
    koots.add(
      GunaKoot('ভকূট', bhakootScore, 7, 'পারিবারিক সমৃদ্ধি ও সন্তান সুখ'),
    );

    final nadiScore = _nadi[brideNak] == _nadi[groomNak] ? 0.0 : 8.0;
    koots.add(GunaKoot('নাড়ি', nadiScore, 8, 'স্বাস্থ্য ও সন্তানের কল্যাণ'));

    final total = koots.fold<double>(0, (s, k) => s + k.score);
    return KundliMilanResult(koots, total);
  }
}

class KundliMilanScreen extends StatefulWidget {
  const KundliMilanScreen({super.key});
  @override
  State<KundliMilanScreen> createState() => _KundliMilanScreenState();
}

class _KundliMilanScreenState extends State<KundliMilanScreen> {
  DateTime? _bride;
  DateTime? _groom;
  KundliMilanResult? _result;

  void _calculate() {
    if (_bride == null || _groom == null) return;
    final brideNak = PanchangCalculator.nakshatraIndexFor(_bride!);
    final brideRashi = PanchangCalculator.rashiIndexFor(_bride!);
    final groomNak = PanchangCalculator.nakshatraIndexFor(_groom!);
    final groomRashi = PanchangCalculator.rashiIndexFor(_groom!);
    setState(() {
      _result = KundliMilanCalculator.compute(
        brideNak: brideNak,
        brideRashi: brideRashi,
        groomNak: groomNak,
        groomRashi: groomRashi,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '💞 কুষ্ঠি মিলন'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'বর ও কনের জন্ম তারিখ ও সময় দিন — চন্দ্র নক্ষত্র ও রাশির '
                  'উপর ভিত্তি করে অষ্টকূট গুণ মিলন (৩৬ গুণ পদ্ধতি) হিসেব '
                  'করে দেবে।',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'কনে',
                  style: TextStyle(
                    color: Color(0xFFFFD36E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _DateTimePickerField(
                  label: 'কনের জন্ম তারিখ ও সময়',
                  onChanged: (dt) => setState(() => _bride = dt),
                ),
                const SizedBox(height: 14),
                const Text(
                  'বর',
                  style: TextStyle(
                    color: Color(0xFFFFD36E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _DateTimePickerField(
                  label: 'বরের জন্ম তারিখ ও সময়',
                  onChanged: (dt) => setState(() => _groom = dt),
                ),
                const SizedBox(height: 16),
                if (_bride != null && _groom != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD36E),
                      ),
                      child: const Text(
                        'মিলন দেখুন',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (_result != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7D4A10).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD36E).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${bnNum(_result!.total.round())} / ৩৬',
                          style: const TextStyle(
                            color: Color(0xFFFFD36E),
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _result!.total >= 28
                              ? '💫 অত্যন্ত শুভ মিলন'
                              : _result!.total >= 18
                              ? '✅ গ্রহণযোগ্য মিলন'
                              : '⚠️ মিলন সন্তোষজনক নয়',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._result!.koots.map(
                    (k) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF08172F).withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(
                            0xFFFFD36E,
                          ).withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  k.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  k.note,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${k.score % 1 == 0 ? k.score.toInt() : k.score} / ${k.max.toInt()}',
                            style: const TextStyle(
                              color: Color(0xFFFFD36E),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_result!.koots.any(
                    (k) => k.name == 'নাড়ি' && k.score == 0,
                  ))
                    const Text(
                      '⚠️ নাড়ি দোষ আছে — বিশেষজ্ঞ জ্যোতিষীর পরামর্শ নেওয়া উচিত।',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11.5),
                    ),
                  if (_result!.koots.any(
                    (k) => k.name == 'ভকূট' && k.score == 0,
                  ))
                    const Text(
                      '⚠️ ভকূট দোষ আছে — বিশেষজ্ঞ জ্যোতিষীর পরামর্শ নেওয়া উচিত।',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11.5),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    'এই হিসেব শুধুমাত্র চন্দ্র নক্ষত্র ও রাশির উপর ভিত্তি করে '
                    'করা — সম্পূর্ণ নির্ভুল বিশ্লেষণের জন্য একজন অভিজ্ঞ '
                    'জ্যোতিষীর সাথে যোগাযোগ করুন।',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// ক্লাউড ব্যাকআপ স্ক্রিন
// =====================================================================

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});
  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  bool _busy = false;
  String? _message;
  DateTime? _lastBackup;

  @override
  void initState() {
    super.initState();
    CloudBackupService.instance.lastBackupAt().then((d) {
      if (mounted) setState(() => _lastBackup = d);
    });
  }

  Future<void> _backup() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final err = await CloudBackupService.instance.backupNow();
    final last = await CloudBackupService.instance.lastBackupAt();
    if (mounted) {
      setState(() {
        _busy = false;
        _message = err ?? '✅ ব্যাকআপ সফল হয়েছে';
        _lastBackup = last;
      });
    }
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final err = await CloudBackupService.instance.restoreNow();
    if (mounted) {
      setState(() {
        _busy = false;
        _message = err ?? '✅ রিস্টোর সফল হয়েছে';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '☁️ ক্লাউড ব্যাকআপ'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'আপনার রিমাইন্ডার ও নোটস ক্লাউডে নিরাপদে ব্যাকআপ রাখুন — '
                  'ফোন হারিয়ে গেলে বা বদলালে আবার রিস্টোর করে ফিরে পাবেন।',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                if (_lastBackup != null) ...[
                  Text(
                    'শেষ ব্যাকআপ: ${_lastBackup!.day}/${_lastBackup!.month}/${_lastBackup!.year} • ${TimeOfDay.fromDateTime(_lastBackup!).format(context)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _backup,
                        icon: const Icon(
                          Icons.cloud_upload,
                          color: Colors.black,
                        ),
                        label: const Text(
                          'ব্যাকআপ করুন',
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD36E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _restore,
                        icon: const Icon(
                          Icons.cloud_download,
                          color: Color(0xFFFFD36E),
                        ),
                        label: const Text(
                          'রিস্টোর করুন',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFD36E)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_busy) ...[
                  const SizedBox(height: 14),
                  const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFD36E)),
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _message!,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// জ্যোতিষী কনসালটেশন বুকিং (সরল সংস্করণ — WhatsApp-ভিত্তিক)
// =====================================================================

class AstrologerProfile {
  final String name;
  final String specialty;
  final String experience;
  const AstrologerProfile(this.name, this.specialty, this.experience);
}

// এই তালিকাটা placeholder — আসল জ্যোতিষীদের নাম/বিশেষত্ব দিয়ে বদলে দিন,
// আর নিচের _astrologerWhatsApp নম্বরটাও নিজের/পার্টনারের আসল নম্বর দিয়ে
// বদলাতে হবে (দেশের কোড সহ, + বা স্পেস ছাড়া, যেমন ভারতের জন্য 91XXXXXXXXXX)
const List<AstrologerProfile> _astrologers = [
  AstrologerProfile('জ্যোতিষী ১', 'বিবাহ ও সম্পর্ক', '১৫+ বছরের অভিজ্ঞতা'),
  AstrologerProfile('জ্যোতিষী ২', 'কর্মজীবন ও ব্যবসা', '১০+ বছরের অভিজ্ঞতা'),
  AstrologerProfile(
    'জ্যোতিষী ৩',
    'স্বাস্থ্য ও পারিবারিক সমস্যা',
    '২০+ বছরের অভিজ্ঞতা',
  ),
];
const String _astrologerWhatsApp = '';

class BookingRequest {
  final String name;
  final String phone;
  final String astrologer;
  final String topic;
  final DateTime when;
  final String notes;
  BookingRequest({
    required this.name,
    required this.phone,
    required this.astrologer,
    required this.topic,
    required this.when,
    required this.notes,
  });
}

class BookingStore {
  BookingStore._();
  static final BookingStore instance = BookingStore._();
  static const _key = 'astro_bookings';
  final List<BookingRequest> items = [];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_key) ?? const [];
    items
      ..clear()
      ..addAll(
        raw.map((e) {
          final m = jsonDecode(e) as Map<String, dynamic>;
          return BookingRequest(
            name: m['name'] as String,
            phone: m['phone'] as String,
            astrologer: m['astrologer'] as String,
            topic: m['topic'] as String,
            when: DateTime.fromMillisecondsSinceEpoch(m['when'] as int),
            notes: m['notes'] as String,
          );
        }),
      );
  }

  Future<void> add(BookingRequest b) async {
    items.insert(0, b);
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _key,
      items
          .map(
            (b) => jsonEncode({
              'name': b.name,
              'phone': b.phone,
              'astrologer': b.astrologer,
              'topic': b.topic,
              'when': b.when.millisecondsSinceEpoch,
              'notes': b.notes,
            }),
          )
          .toList(),
    );
  }
}

class AstrologerBookingScreen extends StatefulWidget {
  const AstrologerBookingScreen({super.key});
  @override
  State<AstrologerBookingScreen> createState() =>
      _AstrologerBookingScreenState();
}

class _AstrologerBookingScreenState extends State<AstrologerBookingScreen> {
  AstrologerProfile? _selected;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _topic = 'সাধারণ পরামর্শ';
  DateTime? _when;

  static const _topics = [
    'সাধারণ পরামর্শ',
    'বিবাহ',
    'কর্মজীবন',
    'স্বাস্থ্য',
    'পারিবারিক সমস্যা',
  ];

  @override
  void initState() {
    super.initState();
    BookingStore.instance.load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (d == null) return;
    if (!mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (t == null) return;
    setState(() => _when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _submit() async {
    if (_selected == null ||
        _nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _when == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('সব তথ্য পূরণ করুন')));
      return;
    }
    final when = _when!;
    final booking = BookingRequest(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      astrologer: _selected!.name,
      topic: _topic,
      when: when,
      notes: _notesCtrl.text.trim(),
    );
    await BookingStore.instance.add(booking);
    final timeLabel = TimeOfDay.fromDateTime(when).format(context);
    final extra = booking.notes.isEmpty
        ? ''
        : '\nঅতিরিক্ত তথ্য: ${booking.notes}';
    final msg = Uri.encodeComponent(
      'নমস্কার, আমি ${booking.name} — আমি ${booking.astrologer}-র সাথে '
      '${booking.topic} বিষয়ে পরামর্শের জন্য বুকিং করতে চাই।\n'
      'পছন্দের সময়: ${when.day}/${when.month}/${when.year} $timeLabel\n'
      'ফোন: ${booking.phone}$extra',
    );
    if (_astrologerWhatsApp.isNotEmpty) {
      final uri = Uri.parse('https://wa.me/$_astrologerWhatsApp?text=$msg');
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _notesCtrl.clear();
        _selected = null;
        _when = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ বুকিং রিকোয়েস্ট পাঠানো হয়েছে')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '🔮 জ্যোতিষী পরামর্শ বুকিং'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _SectionTitle('জ্যোতিষী বেছে নিন'),
                const SizedBox(height: 8),
                ..._astrologers.map(
                  (a) => InkWell(
                    onTap: () => setState(() => _selected = a),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selected == a
                            ? const Color(0xFF7D4A10).withValues(alpha: 0.5)
                            : const Color(0xFF08172F).withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(
                            0xFFFFD36E,
                          ).withValues(alpha: _selected == a ? 0.6 : 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🧑‍🏫', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${a.specialty} • ${a.experience}',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selected == a)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFFFFD36E),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionTitle('আপনার তথ্য'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'আপনার নাম',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'ফোন নম্বর',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _topic,
                  dropdownColor: const Color(0xFF0B1C38),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'বিষয়',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  items: _topics
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _topic = v ?? _topic),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickWhen,
                    icon: const Icon(
                      Icons.calendar_month,
                      color: Color(0xFFFFD36E),
                    ),
                    label: Text(
                      _when == null
                          ? 'পছন্দের তারিখ ও সময় বেছে নিন'
                          : '${_when!.day}/${_when!.month}/${_when!.year} — ${TimeOfDay.fromDateTime(_when!).format(context)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFD36E)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'অতিরিক্ত তথ্য (ঐচ্ছিক)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD36E),
                    ),
                    child: const Text(
                      'বুকিং রিকোয়েস্ট পাঠান',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'সাবমিট করলে WhatsApp-এ প্রি-ফিল্ড মেসেজ খুলবে — সেখান '
                  'থেকে পাঠালে জ্যোতিষীর কাছে রিকোয়েস্টটা পৌঁছাবে। '
                  '(README.md-এ WhatsApp নম্বর বসানোর ধাপ আছে)',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10.5,
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
// CONTENT DATA — দ্রুত ব্যবহার sheet-গুলোর জন্য ডেমো ডেটা
// =====================================================================

/// একটা real সূর্য/চন্দ্রগ্রহণের তথ্য — [date] সবসময় স্থানীয় (IST) ক্যালেন্ডার
/// তারিখ, NASA-র eclipse ক্যাটালগ থেকে যাচাই করা (২০২৬-২০২৭)।
class _EclipseEvent {
  final DateTime date;
  final String icon;
  final String title;
  final String desc;

  /// ধাপ-ভিত্তিক সঠিক সময় (IST) — NASA/PIB (ভারত সরকার)/timeanddate.com
  /// থেকে যাচাই করা। যেসব ভবিষ্যৎ গ্রহণের জন্য এখনো যাচাই করা সময় হাতে
  /// নেই, তাদের জন্য null রাখা হয়েছে (আন্দাজ করে ভুল সময় দেখানো হয়নি)।
  final String? timingIst;

  /// ভারত থেকে দেখা যাবে কিনা — সংক্ষিপ্ত নোট
  final String? indiaVisibility;
  const _EclipseEvent(
    this.date,
    this.icon,
    this.title,
    this.desc, {
    this.timingIst,
    this.indiaVisibility,
  });
}

class ContentData {
  /// 'পঞ্জিকা' ট্যাব বাদে বাকি ক্যাটাগরিগুলো কিউরেটেড নমুনা কনটেন্ট (রাশিফল,
  /// উৎসব তালিকা ইত্যাদি — এগুলোর জন্য প্রকৃত জ্যোতিষ ফিড দরকার)।
  /// 'পঞ্জিকা' ট্যাবটি এখন সরাসরি আজকের হিসেব করা তিথি/নক্ষত্র/রাহুকাল দেখায়।
  static Map<String, List<List<String>>> get categories => {
    ..._staticCategories,
    'পঞ্জিকা': _livePanjika(),
    'রাশিফল': _liveRashiphal(),
    'শুভ দিন': _liveAuspiciousDays(),
    'গ্রহ ও নক্ষত্র': _livePlanets(),
    'গ্রহণ': _liveEclipses(),
    'পূর্ণিমা': _livePurnima(),
    'অমাবস্যা': _liveAmabasya(),
    'পূজা ও ব্রত': _livePujaBrata(),
    'উৎসব ও বিশেষ দিন': _liveUpcomingFestivals(),
  };

  /// [label]-এর পরের প্রকৃত অনুষ্ঠান-তারিখ (আজ থেকে শুরু করে) — real
  /// তিথি/সংক্রান্তি হিসেব থেকে ([BengaliCalendarData.eventsFor] ব্যবহার করে)
  static DateTime? _nextEventDate(String label, {int maxDays = 400}) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    for (int i = 0; i <= maxDays; i++) {
      final day = base.add(Duration(days: i));
      if (BengaliCalendarData.eventsFor(day).any((e) => e.label == label)) {
        return day;
      }
    }
    return null;
  }

  /// "পূজা ও ব্রত" — আগে প্রতিটাতে জেনেরিক বর্ণনা ছিল ("উপবাস ও পূজা
  /// নির্দেশিকা", "শিব পূজা ও ব্রত" ইত্যাদি, কোনো তারিখ ছিল না)। এখন
  /// প্রতিটার real পরবর্তী তারিখ (তিথি/সংক্রান্তি হিসেব থেকে) দেখানো হয়।
  static List<List<String>> _livePujaBrata() {
    final ekadashi = _nextEventDate('একাদশী');
    final shivaratri = _nextEventDate('মহাশিবরাত্রি');
    final shashthi = _nextEventDate('মহাষষ্ঠী');
    final dashami = _nextEventDate('বিজয়া দশমী');
    final lakshmi = _nextEventDate('কোজাগরী লক্ষ্মীপূজা');
    final kali = _nextEventDate('কালীপূজা / দীপাবলি');
    final saraswati = _nextEventDate('সরস্বতী পূজা');

    String fmt(DateTime? d) => d == null
        ? 'তারিখ পাওয়া যায়নি'
        : '${bnNum(d.day)} ${gregMonthBn(d.month)} ${bnNum(d.year)}';

    String range(DateTime? a, DateTime? b) {
      if (a == null || b == null) return 'তারিখ পাওয়া যায়নি';
      return '${bnNum(a.day)} ${gregMonthBn(a.month)} – ${bnNum(b.day)} ${gregMonthBn(b.month)} ${bnNum(b.year)}';
    }

    return [
      [
        'একাদশী',
        ekadashi == null
            ? 'তারিখ পাওয়া যায়নি'
            : 'পরবর্তী একাদশী\n${_fmtTithiTimingFor(ekadashi)}',
      ],
      ['শিবরাত্রি', fmt(shivaratri)],
      ['দুর্গাপূজা', range(shashthi, dashami)],
      ['লক্ষ্মীপূজা', fmt(lakshmi)],
      ['কালীপূজা', fmt(kali)],
      ['সরস্বতী পূজা', fmt(saraswati)],
    ];
  }

  /// তিথির শুরু/শেষ মুহূর্ত পুরো তারিখ+সময়সহ পড়ার-যোগ্য টেক্সটে —
  /// "৯ সেপ্টেম্বর, রাত ৯:৪২"-এর মতো। [PanchangCalculator.tithiTiming]-এর
  /// বাইনারি-সার্চ করা প্রকৃত মুহূর্ত থেকে, কোনো গড়/আনুমানিক হিসেব না।
  static String _fmtTithiEdge(DateTime t) =>
      '${bnNum(t.day)} ${gregMonthBn(t.month)}, ${bnTime12(t)}';

  static String _fmtTithiTimingFor(DateTime day) {
    final ref = PanchangCalculator.sunTimes(day).sunrise;
    final (start, end) = PanchangCalculator.tithiTiming(ref);
    return 'শুরু: ${_fmtTithiEdge(start)}\nশেষ: ${_fmtTithiEdge(end)}';
  }

  /// আজকের পরের real পূর্ণিমার তারিখ — real তিথি হিসেব থেকে বের করা
  /// (আগে শুধু তারিখ দেখাত; এখন তিথির প্রকৃত শুরু ও শেষের সময়ও দেখায়)
  static List<List<String>> _livePurnima() {
    final dates = BengaliCalendarData.findAuspiciousDates(
      'purnima',
      count: 4,
      maxDays: 200,
    );
    return dates.map((d) {
      final month = BengaliDateUtil.monthInfoFor(d).name;
      return ['$month পূর্ণিমা', _fmtTithiTimingFor(d)];
    }).toList();
  }

  /// আজকের পরের real অমাবস্যার তারিখ — real তিথি হিসেব থেকে বের করা
  /// (আগে শুধু তারিখ দেখাত; এখন তিথির প্রকৃত শুরু ও শেষের সময়ও দেখায়)
  static List<List<String>> _liveAmabasya() {
    final dates = BengaliCalendarData.findAuspiciousDates(
      'amabasya',
      count: 4,
      maxDays: 200,
    );
    return dates.map((d) {
      final month = BengaliDateUtil.monthInfoFor(d).name;
      return ['$month অমাবস্যা', _fmtTithiTimingFor(d)];
    }).toList();
  }

  /// NASA-র eclipse ক্যাটালগ থেকে যাচাই করা real তারিখ (২০২৬-২০২৭)।
  /// আগে শুধু ২টা তারিখ হার্ডকোডেড ছিল (১২ আগস্ট সূর্যগ্রহণ, ২৮ আগস্ট
  /// চন্দ্রগ্রহণ) — সেই তারিখ পার হয়ে গেলেও সবসময় ওই পুরনো তারিখই দেখাত।
  /// এখন এই পুরো তালিকা থেকে আজকের পরের গ্রহণগুলোই দেখানো হয়, তাই তারিখ
  /// পেরিয়ে গেলে স্বয়ংক্রিয়ভাবে পরের গ্রহণ দেখাবে।
  static final List<_EclipseEvent> _eclipseEvents = [
    _EclipseEvent(
      DateTime(2026, 2, 17),
      '☀️',
      'সূর্যগ্রহণ',
      'বলয়গ্রাস সূর্যগ্রহণ',
      timingIst: 'শুরু ৩:২৬ PM, সর্বোচ্চ ৫:৪২ PM, শেষ ৭:৫৭ PM',
      indiaVisibility:
          'ভারত থেকে দেখা যাবে না (দক্ষিণ গোলার্ধ/আন্টার্কটিকা থেকে দেখা যাবে)',
    ),
    _EclipseEvent(
      DateTime(2026, 3, 3),
      '🌕',
      'চন্দ্রগ্রহণ',
      'পূর্ণ চন্দ্রগ্রহণ',
      timingIst:
          'আংশিক শুরু ৩:২০ PM, পূর্ণগ্রাস শুরু ৪:৩৪ PM, পূর্ণগ্রাস শেষ ৫:৩৩ PM, আংশিক শেষ ৬:৪৮ PM',
      indiaVisibility:
          'ভারতের বেশিরভাগ জায়গা থেকে চাঁদ ওঠার সময় গ্রহণের শেষভাগ দেখা যাবে; উত্তর-পূর্ব ভারত ও আন্দামান-নিকোবর থেকে পূর্ণগ্রাসের শেষও দেখা যাবে',
    ),
    _EclipseEvent(
      DateTime(2026, 8, 12),
      '☀️',
      'সূর্যগ্রহণ',
      'পূর্ণ সূর্যগ্রহণ',
      indiaVisibility:
          'ভারত থেকে দেখা যাবে না (গ্রীনল্যান্ড, আইসল্যান্ড, স্পেন ও ইউরোপের কিছু অংশ থেকে দেখা যাবে)',
    ),
    _EclipseEvent(
      DateTime(2026, 8, 28),
      '🌘',
      'চন্দ্রগ্রহণ',
      'আংশিক চন্দ্রগ্রহণ',
      timingIst: 'আংশিক শুরু ৮:০৪ AM, সর্বোচ্চ ৯:৪৩ AM, আংশিক শেষ ১১:২১ AM',
      indiaVisibility:
          'ভারত থেকে দেখা যাবে না (ভারতে তখন দিন এবং চাঁদ অস্ত গিয়েছে)',
    ),
    _EclipseEvent(
      DateTime(2027, 2, 6),
      '☀️',
      'সূর্যগ্রহণ',
      'বলয়গ্রাস সূর্যগ্রহণ',
    ),
    _EclipseEvent(
      DateTime(2027, 2, 21),
      '🌗',
      'চন্দ্রগ্রহণ',
      'উপচ্ছায়া চন্দ্রগ্রহণ',
    ),
    _EclipseEvent(
      DateTime(2027, 7, 18),
      '🌗',
      'চন্দ্রগ্রহণ',
      'উপচ্ছায়া চন্দ্রগ্রহণ',
    ),
    _EclipseEvent(DateTime(2027, 8, 2), '☀️', 'সূর্যগ্রহণ', 'পূর্ণ সূর্যগ্রহণ'),
    _EclipseEvent(
      DateTime(2027, 8, 17),
      '🌗',
      'চন্দ্রগ্রহণ',
      'উপচ্ছায়া চন্দ্রগ্রহণ',
    ),
  ];

  /// আজকের পরের (আজসহ) গ্রহণগুলো — গ্রেগরিয়ান তারিখের পাশাপাশি real বাংলা
  /// মাসের তারিখও দেখায় (যেমন: "২৮ আগস্ট ২০২৬ (১১ ভাদ্র ১৪৩৩) • আংশিক চন্দ্রগ্রহণ")
  static List<List<String>> _liveEclipses() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final upcoming = _eclipseEvents
        .where((e) => !e.date.isBefore(todayStart))
        .toList();
    if (upcoming.isEmpty) {
      return [
        ['🔭 গ্রহণ', 'আগামী কিছুদিনে কোনো গ্রহণের তথ্য নেই'],
      ];
    }
    return upcoming.map((e) {
      final info = BengaliDateUtil.monthInfoFor(e.date);
      final bDay = e.date.difference(info.start).inDays + 1;
      final gregLabel =
          '${bnNum(e.date.day)} ${gregMonthBn(e.date.month)} ${bnNum(e.date.year)}';
      final bengaliLabel = '${bnNum(bDay)} ${info.name} ${bnNum(info.year)}';
      var detail = '$gregLabel ($bengaliLabel) • ${e.desc}';
      if (e.timingIst != null) {
        detail += '\n⏱️ সময় (IST): ${e.timingIst}';
      }
      if (e.indiaVisibility != null) {
        detail += '\n📍 ${e.indiaVisibility}';
      }
      return ['${e.icon} ${e.title}', detail];
    }).toList();
  }

  /// "উৎসব ও বিশেষ দিন" — আজকের পরের (আজসহ) real আসন্ন উৎসব।
  /// প্রতিটা উৎসবের প্রকৃত বাংলা তারিখ দেখায় (তিথি/সংক্রান্তি হিসেব থেকে)।
  /// কোনো hardcoded/পুরানো তারিখ নেই, সবই live calculation।
  static List<List<String>> _liveUpcomingFestivals() {
    final festivals = BengaliCalendarData.upcomingFestivals(count: 10);
    if (festivals.isEmpty) {
      return [
        ['🎉 উৎসব', 'আগামী কিছুদিনে তথ্য পাওয়া যাচ্ছে না'],
      ];
    }
    return festivals
        .map((f) => ['${f['icon']} ${f['title']}', f['date'] ?? 'শীঘ্রই'])
        .toList();
  }

  /// "গ্রহ ও নক্ষত্র" — আগে সূর্য/চন্দ্র/মঙ্গল/বৃহস্পতি/শুক্র/শনি/নক্ষত্র সবই
  /// স্ট্যাটিক প্লেসহোল্ডার টেক্সট ছিল ("গ্রহ তথ্য", "আজ: ধনিষ্ঠা" হার্ডকোডেড)।
  /// এখন প্রতিটা real heliocentric Keplerian orbital elements (NASA JPL
  /// টেবিল) দিয়ে হিসেব করা আজকের প্রকৃত রাশি ও সরল/বক্রী (retrograde) গতি
  /// দেখায় — কোনো fake ডেটা নেই।
  static List<List<String>> _livePlanets() {
    final now = DateTime.now();
    final sunIdx = PanchangCalculator.sunRashiIndexFor(now);
    final moonIdx = PanchangCalculator.rashiIndexFor(now);
    final nakIdx = PanchangCalculator.nakshatraIndexFor(now);
    const synodic = 29.530588853;
    final moonAge = PanchangCalculator.moonAgeDays(now) % synodic;
    final illum = (1 - math.cos(moonAge / synodic * 2 * math.pi)) / 2;
    final waxing = moonAge < synodic / 2;
    final moonPhaseText = waxing
        ? 'বর্ধিষ্ণু (${(illum * 100).round()}%)'
        : 'ক্ষয়িষ্ণু (${(illum * 100).round()}%)';

    String planetRow(String key) {
      final idx = PanchangCalculator.planetRashiIndexFor(key, now);
      final retro = PanchangCalculator.planetIsRetrograde(key, now);
      final rashi = PanchangCalculator.rashiNames[idx];
      return '$rashi রাশিতে • ${retro ? "বক্রী" : "সরল"} গতি';
    }

    return [
      ['☀️ সূর্য', '${PanchangCalculator.rashiNames[sunIdx]} রাশিতে অবস্থান'],
      [
        '🌙 চন্দ্র',
        '${PanchangCalculator.rashiNames[moonIdx]} রাশিতে • $moonPhaseText',
      ],
      ['🔴 মঙ্গল', planetRow('mars')],
      ['🟡 বৃহস্পতি', planetRow('jupiter')],
      ['💫 শুক্র', planetRow('venus')],
      ['🪐 শনি', planetRow('saturn')],
      ['⭐ নক্ষত্র', 'আজ: ${PanchangCalculator.nakshatraNames[nakIdx]}'],
    ];
  }

  /// "শুভ দিন" — আগে এখানে জেনেরিক প্লেসহোল্ডার টেক্সট থাকত ("শুভ লগ্ন ও
  /// নির্বাচিত তারিখ")। এখন প্রতিটা কাজের জন্য (বিবাহ/গৃহপ্রবেশ/অন্নপ্রাশন/
  /// ব্যবসা শুরু/নামকরণ) আজ থেকে পরবর্তী প্রকৃত শুভ তারিখগুলো real তিথি/
  /// নক্ষত্র হিসেব থেকে বের করে দেখানো হয় — একটা real "লগ্ন ফাইন্ডার"।
  static List<List<String>> _liveAuspiciousDays() {
    const cats = [
      ['💍 বিবাহ', 'marriage'],
      ['🏠 গৃহপ্রবেশ', 'griha'],
      ['👶 অন্নপ্রাশন', 'annaprashan'],
      ['🪔 ব্যবসা শুরু', 'byabosha'],
      ['📿 নামকরণ', 'namakaran'],
    ];
    return cats.map((c) {
      final dates = BengaliCalendarData.findAuspiciousDates(c[1], count: 3);
      final text = dates.isEmpty
          ? 'আগামী কয়েক মাসে নেই'
          : dates
                .map((d) => '${bnNum(d.day)} ${gregMonthBn(d.month)}')
                .join(', ');
      return [c[0], text];
    }).toList();
  }

  static List<List<String>> _livePanjika() {
    final now = DateTime.now();
    final tithi = PanchangCalculator.tithiFor(now);
    final nakIdx = PanchangCalculator.nakshatraIndexFor(now);
    final rashiIdx = PanchangCalculator.rashiIndexFor(now);
    final yogaIdx = PanchangCalculator.yogaIndexFor(now);
    final karana = PanchangCalculator.karanaFor(now);
    final rahu = PanchangCalculator.rahuKalam(now);
    final abhijit = PanchangCalculator.abhijitMuhurta(now);
    return [
      ['তিথি', '${tithi.paksha} পক্ষ • ${tithi.name}'],
      ['নক্ষত্র', PanchangCalculator.nakshatraNames[nakIdx]],
      ['যোগ', PanchangCalculator.yogaNames[yogaIdx]],
      ['করণ', karana],
      [
        'রাহুকাল (এড়িয়ে চলুন)',
        '${bnTime12(rahu['start']!)}–${bnTime12(rahu['end']!)}',
      ],
      [
        'অভিজিৎ মুহূর্ত (শুভ)',
        abhijit['applicable'] == true
            ? '${bnTime12(abhijit['start'] as DateTime)}–${bnTime12(abhijit['end'] as DateTime)}'
            : 'আজ প্রযোজ্য নয় (বুধবার)',
      ],
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

  // পশ্চিমা জ্যোতিষের ♈♉♊ চিহ্নের বদলে ভারতীয়/বৈদিক জ্যোতিষের রাশি
  // অনুযায়ী প্রকৃত প্রতীক (মেষ=ভেড়া, বৃষ=ষাঁড়, মকর=কুমির-আকৃতির জলজন্তু
  // ইত্যাদি) — মেষ..মীন ক্রমে
  static const List<String> _rashiSymbols = [
    '🐏',
    '🐂',
    '👫',
    '🦀',
    '🦁',
    '👧',
    '⚖️',
    '🦂',
    '🏹',
    '🐊',
    '🏺',
    '🐟',
  ];
  static const List<String> _luckyColors = [
    'লাল',
    'সাদা',
    'সবুজ',
    'রূপালি',
    'সোনালি',
    'নীল',
    'গোলাপি',
    'মেরুন',
    'হলুদ',
    'বাদামি',
    'আকাশি',
    'বেগুনি',
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
      final icon = tag == 'শুভ' ? '✅' : (tag == 'সতর্কতা' ? '⚠️' : '➖');
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
    ['🎉', 'উৎসব পোস্টার মেকার'],
    ['📤', 'পঞ্চাঙ্গ শেয়ার কার্ড'],
    ['⏰', 'রিমাইন্ডার'],
    ['📝', 'নোটস'],
    ['👨‍👩‍👧‍👦', 'পারিবারিক ক্যালেন্ডার'],
    ['🔤', 'শিশুর নামের আদ্যক্ষর'],
    ['🕉️', 'শুভ মুহূর্ত'],
    ['🕯️', 'শ্রাদ্ধ তিথি ফাইন্ডার'],
    ['🛕', 'মন্দির ও পূজার সময়সূচি'],
    ['📄', 'পঞ্জিকা PDF এক্সপোর্ট'],
    ['🪐', 'চন্দ্র কুষ্ঠি চার্ট'],
    ['💞', 'কুষ্ঠি মিলন'],
    ['☁️', 'ক্লাউড ব্যাকআপ'],
    ['🔮', 'জ্যোতিষী পরামর্শ বুকিং'],
    ['✨', 'প্রিমিয়াম'],
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
          // আগে এই পুরো Column-টা (টাইটেল + ১৫টা মেনু আইটেম) একসাথে ফিট
          // করানোর চেষ্টা হতো — ছোট স্ক্রিনের ফোনে (বা ফিচার বাড়ার পর)
          // এটা "BOTTOM OVERFLOWED" এরর দিত, শেষের আইটেমগুলো দেখাই যেত
          // না। এখন টাইটেল স্থির থাকে, নিচের মেনু আইটেমগুলো আলাদাভাবে
          // স্ক্রল করা যায় — তাই যত আইটেমই থাকুক, কখনো overflow হবে না।
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
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: _items
                      .map(
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
                                  Text(
                                    it[0],
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      it[1],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
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
// প্রিমিয়াম গেট — কুষ্ঠি চার্ট/মিলন, PDF এক্সপোর্ট, ক্লাউড ব্যাকআপ, জ্যোতিষী
// বুকিং — এই "টপ" ফিচারগুলো ইনস্টলের পর ৩০ দিন ফ্রি ট্রায়ালে সবার জন্য
// খোলা থাকে, ট্রায়াল ফুরালে আসল প্রিমিয়াম সাবস্ক্রিপশন লাগবে। বাকি সব
// (পঞ্জিকা, ক্যালেন্ডার, রিমাইন্ডার, নোটস, শ্রাদ্ধ তিথি, মন্দির সময়সূচি)
// চিরকাল ফ্রি থাকবে — সেগুলো এই গেট দিয়ে wrap করা হয়নি।
// =====================================================================

class _PremiumGate extends StatelessWidget {
  final String featureTitle;
  final Widget child;
  const _PremiumGate({required this.featureTitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final s = AppSettings.instance;
        if (s.hasPremiumAccess) return child;
        // ফ্রি ট্রায়াল/প্রিমিয়াম — কোনোটাই নেই। নাম/জন্ম তারিখ/ঠিকানার
        // ফর্মটা এখানে দেখানো হয় না — সেটা শুধু ✨ প্রিমিয়াম পেজেই আছে।
        // এখান থেকে সরাসরি প্রিমিয়াম পেজে পাঠিয়ে দেওয়া হয়।
        return CosmicBackground(
          child: Column(
            children: [
              _ScreenHeader(title: featureTitle),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔒', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          s.trialActivated
                              ? 'ফ্রি ট্রায়াল শেষ হয়ে গেছে'
                              : 'এখনো ফ্রি ট্রায়াল শুরু করেননি',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.trialActivated
                              ? 'এই ফিচারটা এখন শুধু প্রিমিয়াম সদস্যদের জন্য। '
                                    'আপনার ৩০ দিনের ফ্রি ট্রায়াল শেষ — চালিয়ে '
                                    'যেতে একটা প্ল্যান কিনুন।'
                              : '✨ প্রিমিয়াম পেজে গিয়ে নাম/জন্ম তারিখ/ঠিকানা '
                                    'দিলেই ৩০ দিনের ফ্রি ট্রায়াল শুরু হয়ে যাবে, '
                                    'তখন এই ফিচারটাও খুলে যাবে।',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PremiumScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.workspace_premium),
                          label: Text(
                            s.trialActivated
                                ? 'প্রিমিয়াম প্ল্যান দেখুন'
                                : 'ফ্রি ট্রায়াল শুরু করুন',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD36E),
                            foregroundColor: const Color(0xFF071428),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =====================================================================
// ফ্রি-ট্রায়াল সাইনআপ ফর্ম — শুধু ✨ প্রিমিয়াম পেজের ভেতরে দেখানো হয়
// (আলাদা কোনো স্ক্রিন/রুট নয়)। নাম, জন্ম তারিখ-সময়, ঠিকানা দিলে তবেই
// ৩০ দিনের ফ্রি ট্রায়াল শুরু হয় ও একটা সদস্য আইডি জেনারেট হয়। জমা
// দেওয়ার সাথে সাথেই প্রিমিয়াম পেজ নিজে থেকে রিবিল্ড হয়ে ট্রায়াল-অ্যাক্টিভ
// ভিউ (ফিচার লিস্ট, প্ল্যান কার্ড) দেখাবে। সাইড মেনু/ড্যাশবোর্ড থেকে সরাসরি
// কোনো টপ ফিচারে ঢুকলে এই ফর্মটা আর দেখানো হয় না — শুধু প্রিমিয়াম পেজে
// যাওয়ার বাটন দেখায় (দেখুন _PremiumGate)।
// =====================================================================

class _TrialSignupForm extends StatefulWidget {
  const _TrialSignupForm();
  @override
  State<_TrialSignupForm> createState() => _TrialSignupFormState();
}

class _TrialSignupFormState extends State<_TrialSignupForm> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _dob;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    if (name.isEmpty || address.isEmpty || _dob == null) {
      setState(
        () => _error = 'নাম, জন্ম তারিখ-সময় ও ঠিকানা — সবগুলো দিতে হবে',
      );
      return;
    }
    setState(() => _error = null);
    await AppSettings.instance.activateTrial(
      name: name,
      dob: _dob!,
      address: address,
    );
    // এরপর আলাদা কিছু করার দরকার নেই — উপরের _PremiumGate নিজে থেকেই
    // AppSettings-এর পরিবর্তন শুনে রিবিল্ড হয়ে আসল ফিচারটা দেখাবে
  }

  @override
  Widget build(BuildContext context) {
    // এখানে নিজের কোনো Scaffold/হেডার/স্ক্রল নেই — এই ফর্মটা সরাসরি
    // PremiumScreen-এর ListView-এর একটা আইটেম হিসেবে বসে
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFFFD36E).withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: Text('🎁', style: TextStyle(fontSize: 36))),
              const SizedBox(height: 10),
              const Text(
                'ফ্রি ট্রায়াল শুরু করুন',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'এই তথ্যগুলো একবার দিন — এরপর ৩০ দিন কুষ্ঠি চার্ট, PDF '
                'এক্সপোর্ট, ক্লাউড ব্যাকআপ ও জ্যোতিষী বুকিং সব বিনামূল্যে '
                'ব্যবহার করতে পারবেন।',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
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
                  hintStyle: const TextStyle(color: Colors.white60),
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
                'জন্ম তারিখ ও সময়',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              _DateTimePickerField(
                label: 'জন্ম তারিখ ও সময় বেছে নিন',
                onChanged: (dt) => setState(() => _dob = dt),
              ),
              const SizedBox(height: 14),
              const Text(
                'ঠিকানা',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'আপনার ঠিকানা',
                  hintStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12.5,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD36E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    '🎁 ফ্রি ট্রায়াল শুরু করুন',
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

/// ভাষা 'English' করা থাকলে সংখ্যা ইংরেজি অঙ্কেই থাকে, নাহলে বাংলা অঙ্কে
String bnDigits(String input) {
  if (!AppSettings.instance.isBangla) return input;
  return input.split('').map((c) {
    final code = c.codeUnitAt(0);
    if (code >= 48 && code <= 57) return _bnDigitMap[code - 48];
    return c;
  }).join();
}

String bnNum(int n) =>
    n < 0 ? '-${bnDigits((-n).toString())}' : bnDigits(n.toString());

String bnTime12(DateTime dt) {
  final h12raw = dt.hour % 12;
  final h12 = h12raw == 0 ? 12 : h12raw;
  final ampm = dt.hour < 12 ? 'AM' : 'PM';
  return '${bnDigits(h12.toString())}:${bnDigits(dt.minute.toString().padLeft(2, '0'))} $ampm';
}

// =====================================================================
// ভয়েস রিমাইন্ডার — বলা কথা থেকে তারিখ/সময়/টেক্সট বের করার সরল, সম্পূর্ণ
// লোকাল পার্সার (কোনো API/ব্যাকএন্ড/AI মডেল ব্যবহার হয় না — শুধু কিছু
// নিয়মভিত্তিক প্যাটার্ন মেলানো)। এটা 100% নির্ভুল হবে না বলেই ব্যবহারকারী
// সবসময় সেভ করার আগে ফলাফল দেখে/দরকার হলে ঠিক করে নিতে পারেন
// (_VoiceReminderSheet দেখুন)। Existing ReminderStore/ReminderItem-এর
// কিছুই এখানে বদলানো হয়নি — এই পার্সার শুধু existing টেক্সট-ফিল্ড আর
// তারিখ/সময় স্টেট পূরণ করে দেয়।
// =====================================================================

class VoiceReminderParseResult {
  final DateTime? when;
  final String title;
  final bool dateFound;
  final bool timeFound;
  const VoiceReminderParseResult({
    required this.when,
    required this.title,
    required this.dateFound,
    required this.timeFound,
  });
}

class VoiceReminderParser {
  VoiceReminderParser._();

  static const Map<String, String> _bnToLatinDigit = {
    '০': '0',
    '১': '1',
    '২': '2',
    '৩': '3',
    '৪': '4',
    '৫': '5',
    '৬': '6',
    '৭': '7',
    '৮': '8',
    '৯': '9',
  };

  static String _toLatinDigits(String s) {
    return s.split('').map((c) => _bnToLatinDigit[c] ?? c).join();
  }

  // DateTime.weekday: সোমবার=1 … রবিবার=7
  static const List<String> _weekdaysBn = [
    'সোমবার',
    'মঙ্গলবার',
    'বুধবার',
    'বৃহস্পতিবার',
    'শুক্রবার',
    'শনিবার',
    'রবিবার',
  ];

  static const List<String> _noiseWords = [
    'মনে করিয়ে দিও',
    'মনে করিয়ে দিবে',
    'মনে করিয়ে দাও',
    'রিমাইন্ডার সেট করো',
    'একটা রিমাইন্ডার',
    'রিমাইন্ডার দাও',
    'রিমাইন্ডার',
    'আমাকে',
    'বিষয়ে',
    'কথাটা',
    'কথা',
    ' যে ',
  ];

  static VoiceReminderParseResult parse(String rawSpoken) {
    final now = DateTime.now();
    final today0 = DateTime(now.year, now.month, now.day);
    var text = ' ${_toLatinDigits(rawSpoken.trim())} ';

    DateTime? date;
    bool dateFound = false;
    int? hour;
    int minute = 0;
    bool timeFound = false;

    // --- তারিখ ---
    if (text.contains('পরশু')) {
      date = today0.add(const Duration(days: 2));
      dateFound = true;
      text = text.replaceAll('পরশু', ' ');
    } else if (text.contains('আগামীকাল') || text.contains('আগামিকাল')) {
      date = today0.add(const Duration(days: 1));
      dateFound = true;
      text = text.replaceAll('আগামীকাল', ' ').replaceAll('আগামিকাল', ' ');
    } else if (text.contains('কালকে') || text.contains('কাল')) {
      // একা "কাল" সাধারণত আগামীকাল বোঝায়
      date = today0.add(const Duration(days: 1));
      dateFound = true;
      text = text.replaceAll('কালকে', ' ').replaceAll('কাল', ' ');
    } else if (text.contains('আজকে') || text.contains('আজ')) {
      date = today0;
      dateFound = true;
      text = text.replaceAll('আজকে', ' ').replaceAll('আজ', ' ');
    }

    if (!dateFound) {
      // "২৫ তারিখ" প্যাটার্ন
      final m = RegExp(r'(\d{1,2})\s*তারিখ').firstMatch(text);
      if (m != null) {
        final day = int.tryParse(m.group(1)!) ?? 0;
        if (day >= 1 && day <= 31) {
          var candidate = DateTime(now.year, now.month, day);
          if (candidate.isBefore(today0)) {
            candidate = DateTime(now.year, now.month + 1, day);
          }
          date = candidate;
          dateFound = true;
        }
        text = text.replaceFirst(m.group(0)!, ' ');
      }
    }

    if (!dateFound) {
      // বারের নাম — যেমন "রবিবার" বললে আসন্ন রবিবার ধরা হয়
      for (int i = 0; i < _weekdaysBn.length; i++) {
        if (text.contains(_weekdaysBn[i])) {
          final targetWeekday = i + 1;
          var addDays = (targetWeekday - today0.weekday) % 7;
          if (addDays == 0) addDays = 7;
          date = today0.add(Duration(days: addDays));
          dateFound = true;
          text = text.replaceAll(_weekdaysBn[i], ' ');
          break;
        }
      }
    }

    // --- সময় --- (যেমন: "সকাল ৯টায়", "সন্ধ্যা ৬টায়", "রাত ৮:৩০টায়")
    final timeMatch = RegExp(
      r'(সকাল|দুপুর|বিকেল|সন্ধ্যা|রাত)?\s*(\d{1,2})(?::(\d{2}))?\s*টা(?:য়|র সময়)?',
    ).firstMatch(text);
    if (timeMatch != null) {
      final period = timeMatch.group(1);
      var h = (int.tryParse(timeMatch.group(2)!) ?? 9) % 12;
      final min = timeMatch.group(3) != null
          ? int.tryParse(timeMatch.group(3)!) ?? 0
          : 0;
      switch (period) {
        case 'সকাল':
          break; // AM — ০-১১ ঠিক আছে
        case 'দুপুর':
        case 'বিকেল':
        case 'সন্ধ্যা':
          h += 12;
          break;
        case 'রাত':
          if (h != 0 && h >= 7) h += 12; // রাত ৭-১১টা → PM, বাকিটা মধ্যরাত/ভোর
          break;
      }
      hour = h;
      minute = min;
      timeFound = true;
      text = text.replaceFirst(timeMatch.group(0)!, ' ');
    }

    // --- বাকি অংশ থেকে রিমাইন্ডারের লেখা ---
    var title = text;
    for (final w in _noiseWords) {
      title = title.replaceAll(w, ' ');
    }
    title = title.replaceAll(RegExp(r'[,।]'), ' ');
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (title.isEmpty) title = 'রিমাইন্ডার';

    DateTime? when;
    if (dateFound || timeFound) {
      final baseDate = date ?? today0;
      final h =
          hour ?? 9; // সময় না বললে ডিফল্ট সকাল ৯টা — প্রিভিউতে বদলানো যায়
      when = DateTime(baseDate.year, baseDate.month, baseDate.day, h, minute);
    }

    return VoiceReminderParseResult(
      when: when,
      title: title,
      dateFound: dateFound,
      timeFound: timeFound,
    );
  }
}

/// আজকের সম্পূর্ণ পঞ্চাঙ্গ এক জায়গায় টেক্সট আকারে — শেয়ার (WhatsApp) ও
/// TTS (পড়ে শোনানো) দুটোতেই ব্যবহার হয়, তাই একটাই ফাংশনে রাখা হলো
String buildTodayPanchangSummary() {
  final now = DateTime.now();
  final info = BengaliDateUtil.monthInfoFor(now);
  final bengaliDay = now.difference(info.start).inDays + 1;
  final tithi = PanchangCalculator.tithiFor(now);
  final weekday = PanchangCalculator.weekdayName(now);
  final nakIdx = PanchangCalculator.nakshatraIndexFor(now);
  DateTime sunrise, sunset;
  try {
    final sun = PanchangCalculator.sunTimes(
      now,
      lat: AppLocation.lat,
      lon: AppLocation.lon,
    );
    sunrise = sun.sunrise;
    sunset = sun.sunset;
  } catch (_) {
    final sun = PanchangCalculator.sunTimes(now);
    sunrise = sun.sunrise;
    sunset = sun.sunset;
  }
  return '''🪷 আজকের পঞ্চাঙ্গ — বাংলা পঞ্জিকা
${bnNum(bengaliDay)} ${info.name} ${bnNum(info.year)}, $weekday
${bnNum(now.day)} ${gregMonthBn(now.month)} ${bnNum(now.year)}

তিথি: ${tithi.paksha} পক্ষ • ${tithi.name}
নক্ষত্র: ${PanchangCalculator.nakshatraNames[nakIdx]}
সূর্যোদয়: ${bnTime12(sunrise)}
সূর্যাস্ত: ${bnTime12(sunset)}''';
}

const List<String> _gregMonthsBn = [
  'জানুয়ারি',
  'ফেব্রুয়ারি',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্টেম্বর',
  'অক্টোবর',
  'নভেম্বর',
  'ডিসেম্বর',
];
const List<String> _gregMonthsEn = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
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

  // ফোনের real-time GPS লোকেশন পাওয়া গেলে সেটাই ব্যবহার হয় — না পেলে
  // (অনুমতি না দিলে/ডেস্কটপ ব্রাউজারে/এরর হলে) আগের মতো ম্যানুয়ালি বেছে
  // নেওয়া জেলাতেই চুপচাপ ফিরে যায়, অ্যাপ কখনো আটকে থাকে না
  static double get lat => LocationService.instance.hasGps
      ? LocationService.instance.gpsLat!
      : (coordinates[district]?.lat ?? 22.5726);
  static double get lon => LocationService.instance.hasGps
      ? LocationService.instance.gpsLon!
      : (coordinates[district]?.lon ?? 88.3639);

  static void select(String d) {
    if (coordinates.containsKey(d)) district = d;
  }
}

// =====================================================================
// ফোনের/ব্রাউজারের real-time GPS লোকেশন — অনুমতি পেলে সূর্যোদয়/অস্ত,
// আবহাওয়া, বৃষ্টি সবকিছু ব্যবহারকারীর প্রকৃত জায়গা ধরে হিসেব হবে
// =====================================================================

class LocationService extends ChangeNotifier {
  LocationService._();
  static final LocationService instance = LocationService._();

  double? gpsLat;
  double? gpsLon;
  // NaN/infinite মান কখনো ঢুকে গেলেও (দ্বিতীয় স্তরের নিরাপত্তা — refresh()
  // এ যাচাই করা হলেও) hasGps যেন কখনো "বৈধ" না ধরে, তাই isFinite চেক
  bool get hasGps =>
      gpsLat != null && gpsLon != null && gpsLat!.isFinite && gpsLon!.isFinite;
  bool _loading = false;
  DateTime? _lastFetch;

  Future<void> refresh({bool force = false}) async {
    final fresh =
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < const Duration(minutes: 10);
    if (_loading || (!force && hasGps && fresh)) return;
    _loading = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // অনুমতি না পেলে চুপচাপ ম্যানুয়াল জেলাতেই থাকবে
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 12));
      // কিছু ফোনে/ইমুলেটরে GPS ফিক্স হওয়ার আগেই NaN/অবাস্তব lat-lon
      // ফেরত আসতে পারে — সেটা সরাসরি ব্যবহার করলে সূর্যোদয়/অস্তের হিসেবে
      // NaN ঢুকে "আজকের পঞ্চাঙ্গ" অংশটাই ফাঁকা/ক্র্যাশ দেখাত (অ্যান্ড্রয়েডে
      // দেখা এই বাগটার আসল কারণ)। তাই বৈধতা যাচাই করে তবেই বসানো হচ্ছে।
      final la = pos.latitude;
      final lo = pos.longitude;
      final valid =
          la.isFinite &&
          lo.isFinite &&
          la >= -90 &&
          la <= 90 &&
          lo >= -180 &&
          lo <= 180;
      if (!valid) return; // অবৈধ রিডিং — আগের/ম্যানুয়াল লোকেশনই থেকে যাবে
      gpsLat = la;
      gpsLon = lo;
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (_) {
      // GPS না থাকলে/এরর হলে/ব্রাউজার সাপোর্ট না করলে — কিছুই ভাঙবে না,
      // আগের মতো ম্যানুয়াল জেলাই ব্যবহার হবে
    } finally {
      _loading = false;
    }
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
    final fresh =
        _lastFetch != null &&
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
    with TickerProviderStateMixin {
  late final AnimationController _rainController;
  // ধীর, স্বাভাবিক লুপ — গরু/ছাগল চরা, মানুষ হাঁটা, তারা মিটমিট করা,
  // স্ট্রিট লাইটের আভা — সবকিছুর "জীবন্ত" নড়াচড়া এই একটা কন্ট্রোলার
  // দিয়েই চলে, বৃষ্টির (দ্রুত) লুপ থেকে আলাদা রাখা হয়েছে যাতে দুটো
  // অ্যানিমেশনের গতি একে অপরের সাথে না মিশে যায়
  late final AnimationController _lifeController;
  Timer? _clockTimer;
  double _sunFrac = 0.5; // -1 = রাত (সূর্য দিগন্তের নিচে), 0..1 = দিনের ভগ্নাংশ
  double _nightFrac = 0.5; // ০..১ — রাতের কতটা পার হয়েছে (চাঁদকে আকাশে সরাতে)
  // ০ = পূর্ণ দিনের আলো (স্ট্রিট লাইট/জানালা বন্ধ) → ১ = রাত (পূর্ণ জ্বলছে)।
  // সূর্যাস্ত/সূর্যোদয়ের আশেপাশে (গোধূলি/উষা) ধীরে ধীরে বদলায়, বাকি
  // পুরো রাত ১-এই স্থির থাকে — ঠিক যেমন বাস্তবে স্ট্রিট লাইট কাজ করে
  double _darkAmount = 0.0;
  SkyPhase _sky = SkyPhase.forTime(DateTime.now());

  @override
  void initState() {
    super.initState();
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _lifeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
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
    double nightFrac = 0.5;
    double darkAmount;
    // রাতের মোট সময়ের প্রথম/শেষ ~৭% কে গোধূলি/উষা ধরা হচ্ছে — এই
    // সময়টুকুতে স্ট্রিট লাইট/জানালার আলো ধীরে ধীরে জ্বলে/নেভে, মাঝের
    // পুরোটা সময় পূর্ণ উজ্জ্বল থাকে (বাস্তব স্ট্রিট লাইটের মতোই)
    const twilightEdge = 0.07;
    if (nowMarked.isBefore(today.sunrise) || nowMarked.isAfter(today.sunset)) {
      frac = -1;
      late DateTime nightStart;
      late DateTime nightEnd;
      if (nowMarked.isAfter(today.sunset)) {
        nightStart = today.sunset;
        nightEnd = PanchangCalculator.sunTimes(
          now.add(const Duration(days: 1)),
          lat: AppLocation.lat,
          lon: AppLocation.lon,
        ).sunrise;
      } else {
        nightStart = PanchangCalculator.sunTimes(
          now.subtract(const Duration(days: 1)),
          lat: AppLocation.lat,
          lon: AppLocation.lon,
        ).sunset;
        nightEnd = today.sunrise;
      }
      final total = nightEnd.difference(nightStart).inSeconds;
      final elapsed = nowMarked.difference(nightStart).inSeconds;
      nightFrac = total <= 0 ? 0.5 : (elapsed / total).clamp(0.0, 1.0);
      if (nightFrac < twilightEdge) {
        darkAmount = (nightFrac / twilightEdge).clamp(0.0, 1.0);
      } else if (nightFrac > 1 - twilightEdge) {
        darkAmount = ((1 - nightFrac) / twilightEdge).clamp(0.0, 1.0);
      } else {
        darkAmount = 1.0;
      }
    } else {
      final total = today.sunset.difference(today.sunrise).inSeconds;
      final elapsed = nowMarked.difference(today.sunrise).inSeconds;
      frac = total <= 0 ? 0.5 : (elapsed / total).clamp(0.0, 1.0);
      darkAmount = 0.0;
    }
    // আকাশের রং/তারার উজ্জ্বলতা/চাঁদের দশা — CosmicBackground-এ যে একই
    // বাস্তবসম্মত, মসৃণ গোধূলি/উষা-সহ হিসেব ব্যবহার হয়, এখানেও সেটাই
    // পুনর্ব্যবহার করা হচ্ছে (নতুন করে বানানো হয়নি) — তাই দুই জায়গার
    // আকাশ একই রকম দেখাবে ও কখনো হঠাৎ রং বদলাবে না
    final sky = SkyPhase.forTime(
      now,
      lat: AppLocation.lat,
      lon: AppLocation.lon,
    );
    if (mounted) {
      setState(() {
        _sunFrac = frac;
        _nightFrac = nightFrac;
        _darkAmount = darkAmount;
        _sky = sky;
      });
    }
  }

  @override
  void dispose() {
    _rainController.dispose();
    _lifeController.dispose();
    _clockTimer?.cancel();
    WeatherService.instance.removeListener(_onWeatherChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // GPS থাকলে GPS-এর, না থাকলে বেছে নেওয়া জেলার real তাপমাত্রা
    // (Open-Meteo) — লোকেশন বদলালে এই সংখ্যাও নিজে থেকেই বদলে যায়,
    // কোনো ফিক্সড/হার্ডকোডেড ডিগ্রি নেই
    final temp = WeatherService.instance.tempC;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_rainController, _lifeController]),
              builder: (context, _) {
                return CustomPaint(
                  painter: _VillageHorizonPainter(
                    sunFrac: _sunFrac,
                    nightFrac: _nightFrac,
                    darkAmount: _darkAmount,
                    isRaining: WeatherService.instance.isRaining,
                    rainT: _rainController.value,
                    lifeT: _lifeController.value,
                    sky: _sky,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            if (temp != null)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌡️', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        '${bnNum(temp.round())}° ${LocationService.instance.hasGps ? 'আপনার অবস্থান' : AppLocation.district}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VillageHorizonPainter extends CustomPainter {
  _VillageHorizonPainter({
    required this.sunFrac,
    required this.nightFrac,
    required this.darkAmount,
    required this.isRaining,
    required this.rainT,
    required this.lifeT,
    required this.sky,
  });
  final double sunFrac; // -1 রাত, নাহলে 0..1
  final double nightFrac; // রাতের কতটুকু কেটেছে, 0..1 (চাঁদের অবস্থান বোঝাতে)
  final double
  darkAmount; // 0..1 — কতটা অন্ধকার (street light/window আলো নিয়ন্ত্রণ করে)
  final bool isRaining;
  final double rainT;
  final double lifeT; // 0..1 ধীরগতির লুপ — গরু/ছাগল/মানুষ/তারার চলাফেরার জন্য
  final SkyPhase sky;

  double get dayAmount => 1.0 - darkAmount;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizonY = h * 0.62;
    final isNight = sunFrac < 0;
    final arc = isNight ? 0.0 : math.sin(math.pi * sunFrac);

    // ---- আকাশ: SkyPhase ইঞ্জিন থেকে বাস্তব সময়-ভিত্তিক মসৃণ রং —
    // CosmicBackground-এর মতোই সঠিক সকাল/দিন/সন্ধ্যা/রাত gradient দেয়,
    // শুধু বৃষ্টি হলে মেঘলা ধূসর রঙে বদলে যায়
    final skyRect = Rect.fromLTWH(0, 0, w, horizonY + 24);
    List<Color> skyColors;
    List<double>? skyStops;
    if (isRaining) {
      skyColors = isNight
          ? const [Color(0xFF090C12), Color(0xFF171C24), Color(0xFF232A34)]
          : const [Color(0xFF48525E), Color(0xFF6B7581), Color(0xFF8C97A2)];
      skyStops = null;
    } else {
      skyColors = sky.gradientColors;
      skyStops = sky.gradientStops;
    }
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: skyColors,
        stops: skyStops,
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // ---- তারা — রাতে ধীরে ধীরে ফুটে ওঠে, মৃদু মিটমিট করে ----
    if (!isRaining && darkAmount > 0.02) {
      final starRnd = math.Random(42);
      for (int i = 0; i < 22; i++) {
        final sx = starRnd.nextDouble() * w;
        final sy = starRnd.nextDouble() * (horizonY * 0.78);
        final twinkle = 0.6 + 0.4 * math.sin(lifeT * 2 * math.pi * 3 + i);
        final starPaint = Paint()
          ..color = Colors.white.withValues(
            alpha: (darkAmount * sky.starOpacity * twinkle).clamp(0.0, 1.0),
          );
        canvas.drawCircle(Offset(sx, sy), i % 5 == 0 ? 1.6 : 1.0, starPaint);
      }
    }

    // ---- সূর্য/চাঁদ (ও তার আলো) — বৃষ্টি/মেঘলা থাকলে মেঘে ঢাকা থাকে ----
    if (!isRaining && !isNight) {
      final sunX = w * (0.12 + 0.76 * sunFrac);
      final sunY = horizonY - arc * (h * 0.5) - 6;
      final warmth = Color.lerp(
        const Color(0xFFFF7A3D),
        const Color(0xFFFFE9A8),
        arc.clamp(0.0, 1.0),
      )!;
      final glow = Paint()
        ..shader = RadialGradient(
          colors: [warmth.withValues(alpha: 0.55), warmth.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset(sunX, sunY), radius: 70));
      canvas.drawCircle(Offset(sunX, sunY), 70, glow);
      final sunPaint = Paint()..color = warmth;
      canvas.drawCircle(Offset(sunX, sunY), 16, sunPaint);
    } else if (!isRaining && isNight) {
      final moonArc = math.sin(math.pi * nightFrac);
      final moonX = w * (0.10 + 0.80 * nightFrac);
      final moonY = horizonY - moonArc * (h * 0.42) - 10;
      paintMoonPhase(
        canvas,
        Offset(moonX, moonY),
        18,
        sky.moonIllumination,
        sky.moonWaxing,
      );
    }

    // ---- দূরের পাহাড়ের সিলুয়েট ----
    final farHill = Paint()..color = const Color(0xFF17263F);
    final farPath = Path()..moveTo(0, horizonY - 10);
    farPath.quadraticBezierTo(w * 0.22, horizonY - 42, w * 0.42, horizonY - 14);
    farPath.quadraticBezierTo(w * 0.65, horizonY - 46, w * 0.85, horizonY - 12);
    farPath.quadraticBezierTo(w * 0.95, horizonY - 26, w, horizonY - 8);
    farPath.lineTo(w, horizonY + 4);
    farPath.lineTo(0, horizonY + 4);
    farPath.close();
    canvas.drawPath(farPath, farHill);

    // ---- কাছের পাহাড়/টিলা সিলুয়েট ----
    final nearHill = Paint()..color = const Color(0xFF0C1626);
    final nearPath = Path()..moveTo(0, horizonY + 6);
    nearPath.quadraticBezierTo(w * 0.18, horizonY - 20, w * 0.34, horizonY + 8);
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

    void hut(double x, double baseY, double s, {double glow = 0.0}) {
      final body = Rect.fromLTWH(x - 13 * s, baseY - 16 * s, 26 * s, 16 * s);
      canvas.drawRect(body, treePaint);
      final roof = Path()
        ..moveTo(x - 17 * s, baseY - 16 * s)
        ..lineTo(x, baseY - 30 * s)
        ..lineTo(x + 17 * s, baseY - 16 * s)
        ..close();
      canvas.drawPath(roof, treePaint);
      // জানালার আলো — সন্ধ্যায় ধীরে ধীরে জ্বলে, রাতভর জ্বলে থাকে
      if (glow > 0.02) {
        final windowRect = Rect.fromLTWH(
          x - 4 * s,
          baseY - 11 * s,
          8 * s,
          7 * s,
        );
        canvas.drawRect(
          windowRect,
          Paint()
            ..color = const Color(
              0xFFFFCF6B,
            ).withValues(alpha: glow.clamp(0.0, 1.0) * 0.85),
        );
      }
    }

    // স্ট্রিট লাইট — সন্ধ্যায় ধীরে ধীরে জ্বলে ওঠে, বাস্তব উষ্ণ আলোকবৃত্তসহ
    void streetLamp(double x, double baseY) {
      final poleColor = treePaint.color;
      canvas.drawLine(
        Offset(x, baseY),
        Offset(x, baseY - 30),
        Paint()
          ..color = poleColor
          ..strokeWidth = 2.0,
      );
      if (darkAmount > 0.02) {
        final glowAlpha = darkAmount.clamp(0.0, 1.0);
        final glowPaint = Paint()
          ..shader =
              RadialGradient(
                colors: [
                  const Color(0xFFFFD98A).withValues(alpha: 0.55 * glowAlpha),
                  const Color(0xFFFFD98A).withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: Offset(x, baseY - 30), radius: 22),
              );
        canvas.drawCircle(Offset(x, baseY - 30), 22, glowPaint);
        canvas.drawCircle(
          Offset(x, baseY - 30),
          3,
          Paint()..color = const Color(0xFFFFEFC2).withValues(alpha: glowAlpha),
        );
      }
    }

    // চরে বেড়ানো গরু/ছাগল — দিনে দেখা যায়, সন্ধ্যায় ধীরে মিলিয়ে যায়,
    // মাথা মাঝেমধ্যে নিচু করে ঘাস খায় ও আস্তে আস্তে পাশে সরে
    void grazingAnimal(
      double baseX,
      double baseY,
      double scale,
      double phase, {
      required bool isGoat,
    }) {
      if (dayAmount < 0.02) return;
      final wander = math.sin(lifeT * 2 * math.pi + phase) * 10 * scale;
      final headBob = (math.sin(lifeT * 2 * math.pi * 2.4 + phase) > 0.6)
          ? 3.0 * scale
          : 0.0;
      final x = baseX + wander;
      final animalPaint = Paint()
        ..color = treePaint.color.withValues(alpha: dayAmount.clamp(0.0, 1.0));
      final bodyW = (isGoat ? 15.0 : 20.0) * scale;
      final bodyH = (isGoat ? 8.0 : 10.0) * scale;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, baseY - bodyH / 2),
          width: bodyW,
          height: bodyH,
        ),
        animalPaint,
      );
      final legPaint = animalPaint..strokeWidth = 1.6 * scale;
      for (final dx in [
        -bodyW * 0.32,
        -bodyW * 0.1,
        bodyW * 0.1,
        bodyW * 0.32,
      ]) {
        canvas.drawLine(
          Offset(x + dx, baseY - 1),
          Offset(x + dx, baseY + 5 * scale),
          legPaint,
        );
      }
      canvas.drawCircle(
        Offset(x - bodyW * 0.46, baseY - bodyH + headBob),
        (isGoat ? 3.2 : 4.0) * scale,
        Paint()
          ..color = treePaint.color.withValues(
            alpha: dayAmount.clamp(0.0, 1.0),
          ),
      );
    }

    // পথচারী — দিনে দুই বিন্দুর মধ্যে হেঁটে যাওয়া-আসা করে, পা দুলে হাঁটার ভঙ্গি দেয়
    void walkingPerson(
      double pathStartX,
      double pathEndX,
      double baseY,
      double scale,
      double phase,
    ) {
      if (dayAmount < 0.02) return;
      final tRaw = (lifeT + phase) % 1.0;
      final tri = tRaw < 0.5 ? tRaw * 2 : 2 - tRaw * 2; // 0..1..0 (যাওয়া-আসা)
      final x = pathStartX + (pathEndX - pathStartX) * tri;
      final legSwing = math.sin(lifeT * 2 * math.pi * 9) * 3 * scale;
      final personPaint = Paint()
        ..color = treePaint.color.withValues(alpha: dayAmount.clamp(0.0, 1.0))
        ..strokeWidth = 1.6 * scale;
      final headY = baseY - 16 * scale;
      canvas.drawCircle(
        Offset(x, headY),
        2.6 * scale,
        Paint()..color = personPaint.color,
      );
      canvas.drawLine(
        Offset(x, headY + 2.6 * scale),
        Offset(x, baseY - 5 * scale),
        personPaint,
      );
      canvas.drawLine(
        Offset(x, baseY - 5 * scale),
        Offset(x - legSwing, baseY),
        personPaint,
      );
      canvas.drawLine(
        Offset(x, baseY - 5 * scale),
        Offset(x + legSwing, baseY),
        personPaint,
      );
      canvas.drawLine(
        Offset(x, baseY - 12 * scale),
        Offset(x - 4 * scale, baseY - 7 * scale),
        personPaint,
      );
      canvas.drawLine(
        Offset(x, baseY - 12 * scale),
        Offset(x + 4 * scale, baseY - 7 * scale),
        personPaint,
      );
    }

    tree(w * 0.10, horizonY + 8, 1.0);
    tree(w * 0.16, horizonY + 10, 0.8);
    hut(w * 0.27, horizonY + 12, 1.0, glow: darkAmount);
    streetLamp(w * 0.20, horizonY + 12);
    tree(w * 0.37, horizonY + 9, 0.9);
    hut(w * 0.50, horizonY + 13, 1.1, glow: darkAmount);
    streetLamp(w * 0.44, horizonY + 13);
    tree(w * 0.60, horizonY + 8, 0.85);
    tree(w * 0.72, horizonY + 11, 1.0);
    hut(w * 0.83, horizonY + 12, 0.95, glow: darkAmount);
    streetLamp(w * 0.66, horizonY + 12);
    tree(w * 0.92, horizonY + 9, 0.8);

    // ---- দিনে চরে বেড়ানো গরু-ছাগল ও চলাফেরা করা মানুষ ----
    grazingAnimal(w * 0.44, horizonY + 16, 1.0, 0.0, isGoat: false);
    grazingAnimal(w * 0.58, horizonY + 15, 0.8, 2.1, isGoat: true);
    walkingPerson(w * 0.30, w * 0.46, horizonY + 14, 1.0, 0.15);

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
    if (!isRaining && !isNight) {
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
        canvas.drawLine(Offset(x0, y0), Offset(x0 - 6, y0 + 14), rainPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VillageHorizonPainter old) {
    return old.sunFrac != sunFrac ||
        old.nightFrac != nightFrac ||
        old.darkAmount != darkAmount ||
        old.isRaining != isRaining ||
        old.rainT != rainT ||
        old.lifeT != lifeT ||
        old.sky != sky;
  }
}

class TithiInfo {
  final int
  index; // 0..29 (0..14 = শুক্লপ্রতিপদ..পূর্ণিমা, 15..29 = কৃষ্ণপ্রতিপদ..অমাবস্যা)
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
    'প্রতিপদ',
    'দ্বিতীয়া',
    'তৃতীয়া',
    'চতুর্থী',
    'পঞ্চমী',
    'ষষ্ঠী',
    'সপ্তমী',
    'অষ্টমী',
    'নবমী',
    'দশমী',
    'একাদশী',
    'দ্বাদশী',
    'ত্রয়োদশী',
    'চতুর্দশী',
  ];

  static const List<String> nakshatraNames = [
    'অশ্বিনী',
    'ভরণী',
    'কৃত্তিকা',
    'রোহিণী',
    'মৃগশিরা',
    'আর্দ্রা',
    'পুনর্বসু',
    'পুষ্যা',
    'অশ্লেষা',
    'মঘা',
    'পূর্বফাল্গুনী',
    'উত্তরফাল্গুনী',
    'হস্তা',
    'চিত্রা',
    'স্বাতী',
    'বিশাখা',
    'অনুরাধা',
    'জ্যেষ্ঠা',
    'মূলা',
    'পূর্বাষাঢ়া',
    'উত্তরাষাঢ়া',
    'শ্রবণা',
    'ধনিষ্ঠা',
    'শতভিষা',
    'পূর্বভাদ্রপদ',
    'উত্তরভাদ্রপদ',
    'রেবতী',
  ];

  static const List<String> rashiNames = [
    'মেষ',
    'বৃষ',
    'মিথুন',
    'কর্কট',
    'সিংহ',
    'কন্যা',
    'তুলা',
    'বৃশ্চিক',
    'ধনু',
    'মকর',
    'কুম্ভ',
    'মীন',
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
    final d =
        utc.day + (utc.hour + utc.minute / 60.0 + utc.second / 3600.0) / 24.0;
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
    final c =
        (1.914602 - 0.004817 * t - 0.000014 * t * t) * math.sin(mr) +
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

    final dr = _deg2rad(d),
        mr = _deg2rad(m),
        mpr = _deg2rad(mp),
        fr = _deg2rad(f);

    final dLon =
        6.289 * math.sin(mpr) -
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

  static const double _ayanamsaJ2000 =
      23.8531; // Lahiri ayanamsa, ২০০০ সাল ভিত্তিক
  static double ayanamsa(double jd) {
    final years = (jd - 2451545.0) / 365.25;
    return _ayanamsaJ2000 + years * 0.013972; // ~৫০.২৪ আর্ক-সেকেন্ড/বছর
  }

  // -------------------------------------------------------------------
  // মঙ্গল/বৃহস্পতি/শুক্র/শনি — real heliocentric Keplerian orbital elements
  // (NASA JPL "Keplerian Elements for Approximate Positions of the Major
  // Planets", ১৮০০-২০৫০ সাল কভার করে, উৎস:
  // https://ssd.jpl.nasa.gov/planets/approx_pos.html)। প্রতিটা তালিকায়
  // ক্রমানুসারে: [a, aDot, e, eDot, I, IDot, L, LDot, peri, periDot, node,
  // nodeDot] — a = AU, বাকি সব ডিগ্রি (ও ডিগ্রি/জুলিয়ান-শতাব্দী)।
  static const Map<String, List<double>> _planetElements = {
    'mercury': [
      0.38709927,
      0.00000037,
      0.20563593,
      0.00001906,
      7.00497902,
      -0.00594749,
      252.25032350,
      149472.67411175,
      77.45779628,
      0.16047689,
      48.33076593,
      -0.12534081,
    ],
    'venus': [
      0.72333566,
      0.00000390,
      0.00677672,
      -0.00004107,
      3.39467605,
      -0.00078890,
      181.97909950,
      58517.81538729,
      131.60246718,
      0.00268329,
      76.67984255,
      -0.27769418,
    ],
    'earth': [
      1.00000261,
      0.00000562,
      0.01671123,
      -0.00004392,
      -0.00001531,
      -0.01294668,
      100.46457166,
      35999.37244981,
      102.93768193,
      0.32327364,
      0.0,
      0.0,
    ],
    'mars': [
      1.52371034,
      0.00001847,
      0.09339410,
      0.00007882,
      1.84969142,
      -0.00813131,
      -4.55343205,
      19140.30268499,
      -23.94362959,
      0.44441088,
      49.55953891,
      -0.29257343,
    ],
    'jupiter': [
      5.20288700,
      -0.00011607,
      0.04838624,
      -0.00013253,
      1.30439695,
      -0.00183714,
      34.39644051,
      3034.74612775,
      14.72847983,
      0.21252668,
      100.47390909,
      0.20469106,
    ],
    'saturn': [
      9.53667594,
      -0.00125060,
      0.05386179,
      -0.00050991,
      2.48599187,
      0.00193609,
      49.95424423,
      1222.49362201,
      92.59887831,
      -0.41897216,
      113.66242448,
      -0.28867794,
    ],
    // ইউরেনাস ও নেপচুন — মহাকাশ ব্যাকগ্রাউন্ডে "কোন গ্রহ এখন বাস্তবে
    // দিগন্তের ওপরে" যাচাই করার জন্য যোগ করা হলো (একই NASA JPL টেবিল)
    'uranus': [
      19.18916464,
      -0.00196176,
      0.04725744,
      -0.00004397,
      0.77263783,
      -0.00242939,
      313.23810451,
      428.48202785,
      170.95427630,
      0.40805281,
      74.01692503,
      0.04240589,
    ],
    'neptune': [
      30.06992276,
      0.00026291,
      0.00859048,
      0.00005105,
      1.77004347,
      0.00035372,
      -55.12002969,
      218.45945325,
      44.96476227,
      -0.32241464,
      131.78422574,
      -0.00508664,
    ],
  };

  /// Kepler সমীকরণ (M = E − e·sin E) Newton-Raphson দিয়ে সমাধান, রেডিয়ানে ফেরত
  static double _solveKepler(double mDeg, double e) {
    final mRad = _deg2rad(_norm360(mDeg + 180) - 180); // -180..180 রেঞ্জে
    double eRad = mRad + e * math.sin(mRad);
    for (int i = 0; i < 8; i++) {
      final delta =
          (eRad - e * math.sin(eRad) - mRad) / (1 - e * math.cos(eRad));
      eRad -= delta;
      if (delta.abs() < 1e-9) break;
    }
    return eRad;
  }

  /// একটা গ্রহের heliocentric ecliptic (J2000) x,y,z (AU) — [el] হলো
  /// [_planetElements]-এর ১২টা মানের তালিকা, [t] জুলিয়ান শতাব্দী (J2000 থেকে)
  static List<double> _heliocentricXYZ(List<double> el, double t) {
    final a = el[0] + el[1] * t;
    final e = el[2] + el[3] * t;
    final i = _deg2rad(el[4] + el[5] * t);
    final l = el[6] + el[7] * t;
    final peri = el[8] + el[9] * t;
    final node = el[10] + el[11] * t;
    final w = _deg2rad(peri - node);
    final nodeR = _deg2rad(node);
    final mDeg = l - peri;
    final eAnom = _solveKepler(mDeg, e);
    final xOrb = a * (math.cos(eAnom) - e);
    final yOrb = a * math.sqrt(1 - e * e) * math.sin(eAnom);
    final cosW = math.cos(w), sinW = math.sin(w);
    final cosNode = math.cos(nodeR), sinNode = math.sin(nodeR);
    final cosI = math.cos(i), sinI = math.sin(i);
    final x =
        (cosW * cosNode - sinW * sinNode * cosI) * xOrb +
        (-sinW * cosNode - cosW * sinNode * cosI) * yOrb;
    final y =
        (cosW * sinNode + sinW * cosNode * cosI) * xOrb +
        (-sinW * sinNode + cosW * cosNode * cosI) * yOrb;
    final z = (sinW * sinI) * xOrb + (cosW * sinI) * yOrb;
    return [x, y, z];
  }

  /// [planet]-এর geocentric apparent ecliptic longitude (ডিগ্রি) — পৃথিবীর
  /// heliocentric ভেক্টর বাদ দিয়ে geocentric ভেক্টর বের করে atan2 নেওয়া হয়
  /// (আলোর গতির সময়/aberration বাদ — রাশি নির্ণয়ের জন্য যথেষ্ট নির্ভুল)
  static double _planetGeoLongitude(String planet, double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    final earth = _heliocentricXYZ(_planetElements['earth']!, t);
    final p = _heliocentricXYZ(_planetElements[planet]!, t);
    final gx = p[0] - earth[0];
    final gy = p[1] - earth[1];
    return _norm360(_rad2deg(math.atan2(gy, gx)));
  }

  static double marsLongitude(double jd) => _planetGeoLongitude('mars', jd);
  static double jupiterLongitude(double jd) =>
      _planetGeoLongitude('jupiter', jd);
  static double venusLongitude(double jd) => _planetGeoLongitude('venus', jd);
  static double saturnLongitude(double jd) => _planetGeoLongitude('saturn', jd);
  static double mercuryLongitude(double jd) =>
      _planetGeoLongitude('mercury', jd);

  // -------------------------------------------------------------------
  // মহাকাশ ব্যাকগ্রাউন্ডের জন্য: কোন গ্রহ এই মুহূর্তে ব্যবহারকারীর GPS
  // লোকেশনের আকাশে বাস্তবেই দিগন্তের ওপরে (তাই দেখানো যুক্তিসংগত) তা
  // যাচাই করতে ecliptic → equatorial → horizontal (altitude/azimuth)
  // রূপান্তর দরকার। এই সূত্রগুলো Meeus, Astronomical Algorithms, ch.13-এর
  // প্রমিত সূত্র — শুধু "গ্রহটা এখন আকাশে ওপরে না নিচে" যাচাইয়ের জন্য
  // ব্যবহার হচ্ছে, তাই উচ্চ-নির্ভুলতার প্রয়োজন নেই।

  /// [planet]-এর geocentric ecliptic longitude, latitude (ডিগ্রি) ও দূরত্ব
  /// (AU) — heliocentric ভেক্টর থেকে সরাসরি বের করা, রাশি-নির্ণয়ে ব্যবহৃত
  /// [_planetGeoLongitude]-এর মতোই কিন্তু ecliptic latitude/দূরত্বসহ
  static Map<String, double> planetGeoEcliptic(String planet, double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    final earth = _heliocentricXYZ(_planetElements['earth']!, t);
    final p = _heliocentricXYZ(_planetElements[planet]!, t);
    final gx = p[0] - earth[0];
    final gy = p[1] - earth[1];
    final gz = p[2] - earth[2];
    final dist = math.sqrt(gx * gx + gy * gy + gz * gz);
    final lon = _norm360(_rad2deg(math.atan2(gy, gx)));
    final lat = _rad2deg(math.atan2(gz, math.sqrt(gx * gx + gy * gy)));
    return {'lon': lon, 'lat': lat, 'dist': dist};
  }

  /// চাঁদের ecliptic latitude (ডিগ্রি) — প্রধান পদ (~৫.১৩°) দিয়ে আনুমানিক;
  /// আকাশে ওঠা/নামা (visibility) যাচাইয়ের জন্য যথেষ্ট নির্ভুল
  static double moonLatitude(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    final f = _deg2rad(_norm360(93.2720950 + 483202.0175233 * t));
    return 5.128 * math.sin(f);
  }

  static const double _obliquityDeg = 23.4397; // পৃথিবীর অক্ষের হেলান

  /// Ecliptic (lon,lat) → Equatorial (RA,Dec), ডিগ্রিতে
  static Map<String, double> _eclipticToEquatorial(
    double lonDeg,
    double latDeg,
  ) {
    final eps = _deg2rad(_obliquityDeg);
    final lam = _deg2rad(lonDeg);
    final bet = _deg2rad(latDeg);
    final sinDec =
        math.sin(bet) * math.cos(eps) +
        math.cos(bet) * math.sin(eps) * math.sin(lam);
    final dec = math.asin(sinDec.clamp(-1.0, 1.0));
    final y = math.sin(lam) * math.cos(eps) - math.tan(bet) * math.sin(eps);
    final x = math.cos(lam);
    final ra = _norm360(_rad2deg(math.atan2(y, x)));
    return {'ra': ra, 'dec': _rad2deg(dec)};
  }

  /// Greenwich Mean Sidereal Time (ডিগ্রি) — Meeus ch.12 সূত্র
  static double _gmstDeg(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    final gmst =
        280.46061837 +
        360.98564736629 * (jd - 2451545.0) +
        0.000387933 * t * t -
        (t * t * t) / 38710000.0;
    return _norm360(gmst);
  }

  /// Equatorial (RA,Dec) → altitude/azimuth (ডিগ্রি), পর্যবেক্ষকের
  /// lat/lon দিয়ে — azimuth উত্তর থেকে পূর্বদিকে ঘুরে মাপা (compass-এর মতো)
  static Map<String, double> _equatorialToHorizontal(
    double raDeg,
    double decDeg,
    double latDeg,
    double lonDeg,
    double jd,
  ) {
    final lst = _norm360(_gmstDeg(jd) + lonDeg);
    final haDeg = _norm360(lst - raDeg);
    final ha = _deg2rad(haDeg);
    final decR = _deg2rad(decDeg);
    final latR = _deg2rad(latDeg);
    final sinAlt =
        math.sin(decR) * math.sin(latR) +
        math.cos(decR) * math.cos(latR) * math.cos(ha);
    final alt = math.asin(sinAlt.clamp(-1.0, 1.0));
    final cosAltLat = math.cos(alt) * math.cos(latR);
    final cosAz = cosAltLat.abs() < 1e-9
        ? 0.0
        : ((math.sin(decR) - math.sin(alt) * math.sin(latR)) / cosAltLat).clamp(
            -1.0,
            1.0,
          );
    var az = _rad2deg(math.acos(cosAz));
    if (math.sin(ha) > 0) az = 360.0 - az;
    return {'altitude': _rad2deg(alt), 'azimuth': _norm360(az)};
  }

  /// [body] ('sun', 'moon', 'mercury', 'venus', 'mars', 'jupiter', 'saturn',
  /// 'uranus', 'neptune') — GPS লোকেশন ও সময় অনুযায়ী আকাশে এই মুহূর্তে
  /// altitude/azimuth (ডিগ্রি)। altitude > 0 মানে দিগন্তের ওপরে — অর্থাৎ
  /// বাস্তবে (আকাশ যথেষ্ট অন্ধকার থাকলে) দেখা যাওয়ার কথা।
  static Map<String, double> celestialAltAz(
    String body,
    DateTime localDateTime, {
    double? lat,
    double? lon,
  }) {
    final la = lat ?? AppLocation.lat;
    final lo = lon ?? AppLocation.lon;
    final jd = julianDay(_toTrueUtc(localDateTime));
    double lonDeg;
    double latDeg;
    if (body == 'sun') {
      lonDeg = sunLongitude(jd);
      latDeg = 0.0;
    } else if (body == 'moon') {
      lonDeg = moonLongitude(jd);
      latDeg = moonLatitude(jd);
    } else {
      final e = planetGeoEcliptic(body, jd);
      lonDeg = e['lon']!;
      latDeg = e['lat']!;
    }
    final eq = _eclipticToEquatorial(lonDeg, latDeg);
    return _equatorialToHorizontal(eq['ra']!, eq['dec']!, la, lo, jd);
  }

  /// রাহু (চন্দ্রের mean ascending node) — এটা কোনো বাস্তব গ্রহ নয়, তাই
  /// heliocentric orbital elements দিয়ে হিসেব হয় না। Meeus ch.47-এর
  /// mean-node সূত্র ব্যবহার করা হয়েছে (true node নয়, mean node — এটাই
  /// সাধারণ পঞ্জিকা/সফটওয়্যারে ব্যবহৃত হয়)। কেতু সবসময় রাহু থেকে ঠিক
  /// ১৮০° উল্টো দিকে থাকে বলে আলাদা সূত্র লাগে না।
  static double meanLunarNodeLongitude(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    return _norm360(
      125.0445479 -
          1934.1362891 * t +
          0.0020754 * t * t +
          (t * t * t) / 467441.0 -
          (t * t * t * t) / 60616000.0,
    );
  }

  /// আজ রাহু কোন রাশিতে (sidereal) — রাহু সবসময় বক্রী গতিতে চলে (ব চিহ্ন
  /// লাগানো হয় না, কারণ এটা প্রথাগতভাবে ধরেই নেওয়া হয়)
  static int rahuRashiIndexFor(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final lon = meanLunarNodeLongitude(jd);
    final sidereal = _norm360(lon - ayanamsa(jd));
    return (sidereal / 30.0).floor().clamp(0, 11);
  }

  /// আজ কেতু কোন রাশিতে — রাহুর ঠিক বিপরীত (১৮০°) ঘরে
  static int ketuRashiIndexFor(DateTime localDateTime) {
    final rahu = rahuRashiIndexFor(localDateTime);
    return (rahu + 6) % 12;
  }

  /// আজ [planet] কোন রাশিতে আছে (sidereal, Lahiri ayanamsa বাদ দিয়ে)
  static int planetRashiIndexFor(String planet, DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final lon = _planetGeoLongitude(planet, jd);
    final sidereal = _norm360(lon - ayanamsa(jd));
    return (sidereal / 30.0).floor().clamp(0, 11);
  }

  /// [planet] বক্রী (retrograde) কিনা — আজ ও ১ দিন আগের longitude তুলনা করে
  static bool planetIsRetrograde(String planet, DateTime localDateTime) {
    final jdNow = julianDay(_toTrueUtc(localDateTime));
    final lonNow = _planetGeoLongitude(planet, jdNow);
    final lonPrev = _planetGeoLongitude(planet, jdNow - 1.0);
    var diff = lonNow - lonPrev;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff < 0;
  }

  /// আজ সূর্য কোন রাশিতে আছে (sidereal)
  static int sunRashiIndexFor(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final sun = sunLongitude(jd);
    final sidereal = _norm360(sun - ayanamsa(jd));
    return (sidereal / 30.0).floor().clamp(0, 11);
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

  /// [moment]-এ চলমান তিথিটা ঠিক কখন শুরু হয়েছিল আর কখন শেষ হবে — গড়/
  /// আনুমানিক হিসেব না, [tithiFor]-এর ওপরই বাইনারি সার্চ চালিয়ে প্রকৃত
  /// মুহূর্ত (মিনিট নির্ভুলতায়) বের করা হয়। তাই existing তিথি
  /// calculation-এর সাথেই ১০০% সামঞ্জস্যপূর্ণ — আলাদা কোনো নতুন মডেল না।
  static (DateTime start, DateTime end) tithiTiming(DateTime moment) {
    final idx = tithiFor(moment).index;

    DateTime searchEdge({required bool forward}) {
      var known = moment; // এই মুহূর্তে তিথি == idx, নিশ্চিত
      var unknown = moment.add(Duration(hours: forward ? 6 : -6));
      // coarse ধাপে ধাপে সীমানা খুঁজে বের করা (তিথি সাধারণত ১৯-২৬ ঘণ্টা
      // স্থায়ী হয়, তাই ৬ ঘণ্টা করে ১০ ধাপ = ৬০ ঘণ্টা যথেষ্ট মার্জিন)
      for (int i = 0; i < 10 && tithiFor(unknown).index == idx; i++) {
        known = unknown;
        unknown = unknown.add(Duration(hours: forward ? 6 : -6));
      }
      // বাইনারি সার্চ — মিনিট নির্ভুলতা পর্যন্ত নামিয়ে আনা
      for (int i = 0; i < 20; i++) {
        final mid = DateTime.fromMillisecondsSinceEpoch(
          (known.millisecondsSinceEpoch + unknown.millisecondsSinceEpoch) ~/ 2,
        );
        if (tithiFor(mid).index == idx) {
          known = mid;
        } else {
          unknown = mid;
        }
      }
      return known;
    }

    final start = searchEdge(forward: false);
    final end = searchEdge(forward: true);
    return (start, end);
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

  /// নক্ষত্রের কোন পাদ (১-৪) — কুষ্ঠি চার্টে দেখানোর জন্য
  static int nakshatraPadaFor(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final moon = moonLongitude(jd);
    final sidereal = _norm360(moon - ayanamsa(jd));
    const nakSpan = 360.0 / 27.0;
    final withinNak = sidereal % nakSpan;
    return (withinNak / (nakSpan / 4)).floor().clamp(0, 3) + 1;
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
    final noon = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
      12,
    );
    final n = julianDay(noon) - 2451545.0 + 0.0008;
    final jStar = n - lo / 360.0;
    final m = _norm360(357.5291 + 0.98560028 * jStar);
    final mr = _deg2rad(m);
    final c =
        1.9148 * math.sin(mr) +
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

  /// ☀️ অভিজিৎ মুহূর্ত — স্থানীয় সূর্যোদয়-অস্তের মাঝামাঝি (solar noon) সময়ের
  /// ±২৪ মিনিট, ঐতিহ্যবাহী সর্বজনীন শুভ সময় (বুধবার বাদে সব বার প্রযোজ্য)।
  /// এই একই হিসাব আগে থেকেই findAuspiciousMuhurtas()-এ ব্যবহার হচ্ছিল —
  /// এখানে আলাদা ফাংশন করা হলো যাতে হোমস্ক্রিন/পঞ্জিকা ট্যাবেও (কোনো নতুন
  /// হিসাব ছাড়াই, একই সূত্র পুনরায় ব্যবহার করে) দেখানো যায়।
  static Map<String, dynamic> abhijitMuhurta(
    DateTime localDate, {
    double? lat,
    double? lon,
  }) {
    final st = sunTimes(localDate, lat: lat, lon: lon);
    final solarNoon = st.sunrise.add(st.sunset.difference(st.sunrise) ~/ 2);
    return {
      'start': solarNoon.subtract(const Duration(minutes: 24)),
      'end': solarNoon.add(const Duration(minutes: 24)),
      'applicable': localDate.weekday != DateTime.wednesday,
    };
  }

  /// যমগণ্ড কাল (এড়িয়ে চলার সময়) — রাহুকালের ঠিক একই পদ্ধতিতে হিসেব:
  /// সূর্যোদয়-অস্ত ৮ ভাগে ভাগ করে, প্রতি বারের জন্য ঐতিহ্যবাহী নির্দিষ্ট
  /// ভাগ (source: প্রচলিত পঞ্চাঙ্গ সূত্র — রাহু/যম/গুলিক তিনটাই একই
  /// পদ্ধতির আলাদা আলাদা বার-ভিত্তিক টেবিল, একই দিনে কখনো একে অপরের
  /// ভাগে পড়ে না)।
  static Map<String, DateTime> yamagandaKalam(
    DateTime localDate, {
    double? lat,
    double? lon,
  }) {
    final st = sunTimes(localDate, lat: lat, lon: lon);
    final segment = st.sunset.difference(st.sunrise) ~/ 8;
    const orderByWeekday = {
      1: 4, // সোমবার
      2: 3, // মঙ্গলবার
      3: 2, // বুধবার
      4: 1, // বৃহস্পতিবার
      5: 7, // শুক্রবার
      6: 6, // শনিবার
      7: 5, // রবিবার
    };
    final part = orderByWeekday[localDate.weekday] ?? 8;
    final start = st.sunrise.add(segment * (part - 1));
    final end = st.sunrise.add(segment * part);
    return {'start': start, 'end': end};
  }

  /// গুলিকাল (এড়িয়ে চলার সময়) — রাহুকাল/যমগণ্ডের একই ৮-ভাগ পদ্ধতি,
  /// শুধু বার-ভিত্তিক ভাগ আলাদা (ঐতিহ্যবাহী পঞ্চাঙ্গ সূত্র)।
  static Map<String, DateTime> gulikaKalam(
    DateTime localDate, {
    double? lat,
    double? lon,
  }) {
    final st = sunTimes(localDate, lat: lat, lon: lon);
    final segment = st.sunset.difference(st.sunrise) ~/ 8;
    const orderByWeekday = {
      1: 6, // সোমবার
      2: 5, // মঙ্গলবার
      3: 4, // বুধবার
      4: 3, // বৃহস্পতিবার
      5: 2, // শুক্রবার
      6: 1, // শনিবার
      7: 7, // রবিবার
    };
    final part = orderByWeekday[localDate.weekday] ?? 8;
    final start = st.sunrise.add(segment * (part - 1));
    final end = st.sunrise.add(segment * part);
    return {'start': start, 'end': end};
  }

  /// উত্তরায়ণ/দক্ষিণায়ণ — সূর্যের নিরয়ন (sidereal) দ্রাঘিমা মকর রাশিতে
  /// (২৭০°) ঢোকা থেকে মিথুন রাশি শেষ (৯০°) পর্যন্ত উত্তরায়ণ, বাকি সময়
  /// দক্ষিণায়ণ — রাশি/নক্ষত্র হিসেবেই যে sidereal longitude ব্যবহার হয়,
  /// এখানেও ঠিক সেটাই পুনরায় ব্যবহার হয়েছে (নতুন কোনো astronomy model নয়)।
  static String ayana(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final sidereal = _norm360(sunLongitude(jd) - ayanamsa(jd));
    final inUttarayana = sidereal >= 270.0 || sidereal < 90.0;
    return inUttarayana ? 'উত্তরায়ণ' : 'দক্ষিণায়ণ';
  }

  /// শকাব্দ — বাংলা সনের সাথে ঐতিহ্যবাহী প্রচলিত সম্পর্ক (বাংলা সন + ৫১৫)
  static int shakaYearFromBengali(int bengaliYear) => bengaliYear + 515;

  static String weekdayName(DateTime d) {
    const bn = {
      1: 'সোমবার',
      2: 'মঙ্গলবার',
      3: 'বুধবার',
      4: 'বৃহস্পতিবার',
      5: 'শুক্রবার',
      6: 'শনিবার',
      7: 'রবিবার',
    };
    const en = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    final names = AppSettings.instance.isBangla ? bn : en;
    return names[d.weekday] ?? '';
  }

  static const List<String> yogaNames = [
    'বিষ্কম্ভ',
    'প্রীতি',
    'আয়ুষ্মান',
    'সৌভাগ্য',
    'শোভন',
    'অতিগণ্ড',
    'সুকর্মা',
    'ধৃতি',
    'শূল',
    'গণ্ড',
    'বৃদ্ধি',
    'ধ্রুব',
    'ব্যাঘাত',
    'হর্ষণ',
    'বজ্র',
    'সিদ্ধি',
    'ব্যতীপাত',
    'বরীয়ান',
    'পরিঘ',
    'শিব',
    'সিদ্ধ',
    'সাধ্য',
    'শুভ',
    'শুক্ল',
    'ব্রহ্ম',
    'ইন্দ্র',
    'বৈধৃতি',
  ];

  static int yogaIndexFor(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final sum = _norm360(sunLongitude(jd) + moonLongitude(jd));
    return (sum / (360.0 / 27.0)).floor().clamp(0, 26);
  }

  static const List<String> _karanaMovingNames = [
    'বব',
    'বালব',
    'কৌলব',
    'তৈতিল',
    'গর',
    'বণিজ',
    'বিষ্টি',
  ];
  static const List<String> _karanaFixedNames = [
    'শকুনি',
    'চতুষ্পদ',
    'নাগ',
    'কিংস্তুঘ্ন',
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
    'বৈশাখ',
    'জ্যৈষ্ঠ',
    'আষাঢ়',
    'শ্রাবণ',
    'ভাদ্র',
    'আশ্বিন',
    'কার্তিক',
    'অগ্রহায়ণ',
    'পৌষ',
    'মাঘ',
    'ফাল্গুন',
    'চৈত্র',
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
    var t = DateTime.utc(
      gYear,
      4,
      14,
    ).add(Duration(days: (k * 30.44).round() - 8));
    var prev = _lonOffset(t, target);
    for (int step = 0; step < 80; step++) {
      final next = t.add(const Duration(hours: 6));
      final cur = _lonOffset(next, target);
      if (prev < 0 && cur >= 0) {
        // দুই বিন্দুর মাঝে দ্বিখণ্ডন করে মুহূর্তটা সূক্ষ্ম করি
        var lo = t, hi = next;
        for (int b = 0; b < 22; b++) {
          final mid = lo.add(
            Duration(milliseconds: hi.difference(lo).inMilliseconds ~/ 2),
          );
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
    return DateTime.utc(
      gYear,
      4,
      14,
    ).add(Duration(days: (k * 30.44).round(), hours: 5, minutes: 30));
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
    '2026-08-12': [CalendarEvent('পূর্ণ সূর্যগ্রহণ', 'general', icon: '🌑')],
    '2026-08-13': [CalendarEvent('আখেরী চাহার শোম্বা', 'general', icon: '🕌')],
    '2026-08-28': [CalendarEvent('আংশিক চন্দ্রগ্রহণ', 'general', icon: '🌘')],
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
    '01-23': [CalendarEvent('নেতাজি জন্মজয়ন্তী', 'general', icon: '🧑')],
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
    'রোহিণী',
    'মৃগশিরা',
    'মঘা',
    'উত্তরফাল্গুনী',
    'হস্তা',
    'স্বাতী',
    'অনুরাধা',
    'মূলা',
    'উত্তরাষাঢ়া',
    'উত্তরভাদ্রপদ',
    'রেবতী',
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
    // একই নিয়মে পড়া দিনগুলোকে আটটা ভাগে ভাগ করা হয় (বিবাহ/গৃহপ্রবেশ/
    // অন্নপ্রাশন/ব্যবসা শুরু/নামকরণ/জমি কেনা/বাড়ি কেনা/গাড়ি কেনা) যাতে
    // প্রতিটি কাজের জন্য আলাদা আলাদা বাস্তবসম্মত সংখ্যক শুভ দিন দেখা যায়।
    // ("শুভ মুহূর্ত" ফিচারে জমি/বাড়ি/গাড়ি কেনার ৩টা নতুন ভাগ যোগ হওয়ায়
    // আগের mod-5 থেকে mod-8 করা হলো — এটা এখনো একটা সরলীকৃত ইঙ্গিতমাত্র,
    // প্রকৃত লগ্ন-বিচারের বিকল্প নয়)
    switch (date.day % 8) {
      case 0:
        return const CalendarEvent('বিবাহের শুভ দিন', 'marriage', icon: '💍');
      case 1:
        return const CalendarEvent('গৃহপ্রবেশের শুভ দিন', 'griha', icon: '🏠');
      case 2:
        return const CalendarEvent(
          'অন্নপ্রাশনের শুভ দিন',
          'annaprashan',
          icon: '👶',
        );
      case 3:
        return const CalendarEvent(
          'ব্যবসা শুরুর শুভ দিন',
          'byabosha',
          icon: '🪔',
        );
      case 4:
        return const CalendarEvent('নামকরণের শুভ দিন', 'namakaran', icon: '📿');
      case 5:
        return const CalendarEvent('জমি কেনার শুভ দিন', 'jomi', icon: '🏞️');
      case 6:
        return const CalendarEvent('বাড়ি কেনার শুভ দিন', 'bari', icon: '🏡');
      default:
        return const CalendarEvent('গাড়ি কেনার শুভ দিন', 'gari', icon: '🚗');
    }
  }

  /// "শুভ মুহূর্ত" ফিচারের জন্য — শুধু তারিখ না দিয়ে সেদিনের তিথি/নক্ষত্র/
  /// বার, ☀️ অভিজিৎ মুহূর্ত (স্থানীয় সূর্যোদয়-অস্তের মাঝামাঝি সময়ের ±২৪
  /// মিনিট — ঐতিহ্যবাহী সর্বজনীন শুভ সময়, বুধবার বাদে) আর ⚠️ রাহুকাল
  /// (এড়িয়ে চলার সময়) সহ পুরো তথ্য ফেরত দেয়। lat/lon না দিলে ব্যবহারকারীর
  /// নির্বাচিত জেলা/GPS (AppLocation) অনুযায়ী হিসেব হয়।
  static List<Map<String, dynamic>> findAuspiciousMuhurtas(
    String category, {
    int count = 5,
    int maxDays = 200,
    DateTime? from,
    double? lat,
    double? lon,
  }) {
    final dates = findAuspiciousDates(
      category,
      count: count,
      maxDays: maxDays,
      from: from,
    );
    return dates.map((d) {
      final sun = PanchangCalculator.sunTimes(d, lat: lat, lon: lon);
      final tithi = PanchangCalculator.tithiFor(sun.sunrise);
      final nakIdx = PanchangCalculator.nakshatraIndexFor(sun.sunrise);
      final solarNoon = sun.sunrise.add(
        sun.sunset.difference(sun.sunrise) ~/ 2,
      );
      final rahu = PanchangCalculator.rahuKalam(d, lat: lat, lon: lon);
      return {
        'date': d,
        'tithi': tithi,
        'nakshatra': PanchangCalculator.nakshatraNames[nakIdx],
        'abhijitStart': solarNoon.subtract(const Duration(minutes: 24)),
        'abhijitEnd': solarNoon.add(const Duration(minutes: 24)),
        'abhijitApplicable': d.weekday != DateTime.wednesday,
        'rahuStart': rahu['start'],
        'rahuEnd': rahu['end'],
      };
    }).toList();
  }

  /// আজ থেকে আগামী [maxDays] দিনের মধ্যে নির্দিষ্ট কাজের (marriage/griha/
  /// annaprashan/byabosha/namakaran) জন্য পরবর্তী [count]-টা শুভ দিন খুঁজে
  /// বের করে — real তিথি/নক্ষত্র হিসেব থেকে, কোনো হার্ডকোড করা তারিখ না
  static List<DateTime> findAuspiciousDates(
    String category, {
    int count = 3,
    int maxDays = 200,
    DateTime? from,
  }) {
    final start = from ?? DateTime.now();
    final base = DateTime(start.year, start.month, start.day);
    final results = <DateTime>[];
    for (int i = 1; i <= maxDays && results.length < count; i++) {
      final day = base.add(Duration(days: i));
      if (eventsFor(day).any((e) => e.category == category)) {
        results.add(day);
      }
    }
    return results;
  }

  /// আজকের পরের (আজসহ) real উৎসব/বিশেষ দিন — হোম স্ক্রিনের "উৎসব ও বিশেষ
  /// দিন" carousel-এর জন্য। category 'general'-এর প্রতিটা আলাদা লেবেল
  /// একবার করে, তারিখ-ক্রমে দেওয়া হয়, তাই পার-হয়ে-যাওয়া পুরনো তারিখ কখনো
  /// দেখায় না — আজকের পর যেটা প্রথমে আসে সেটাই তালিকার প্রথমে থাকে।
  static List<Map<String, String>> upcomingFestivals({
    int maxDays = 200,
    int count = 10,
  }) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final results = <Map<String, String>>[];
    final seen = <String>{};
    for (int i = 0; i <= maxDays && results.length < count; i++) {
      final day = base.add(Duration(days: i));
      for (final e in eventsFor(day)) {
        if (e.category != 'general') continue;
        final title = e.label.split(' / ').first;
        if (seen.contains(title)) continue;
        seen.add(title);
        final info = BengaliDateUtil.monthInfoFor(day);
        final bDay = day.difference(info.start).inDays + 1;
        results.add({
          'icon': e.icon,
          'title': title,
          'date': '${bnNum(bDay)} ${info.name}',
          // কতদিন বাকি — কাউন্টডাউন দেখানোর জন্য (existing কলার/UI-গুলো এই
          // নতুন key ইগনোর করবে, তাই কোথাও কিছু ভাঙবে না)
          'daysLeft': i.toString(),
        });
        if (results.length >= count) break;
      }
    }
    return results;
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
// PanjikaArt — অ্যাপের নিজস্ব, সম্পূর্ণ মৌলিক (original) ছোট illustration।
// কোনো প্রকাশনী/বইয়ের ছবি কপি করা হয়নি — সবই এখানে Flutter CustomPainter
// দিয়ে কোডে নতুন করে আঁকা, তাই কোনো ছবি ফাইল লাগে না এবং যেকোনো সাইজে
// ঝকঝকে থাকে (vector)। ঐতিহ্যবাহী বাংলা পঞ্জিকার আবহ রেখে motif গুলো
// সরল/আইকনিক রাখা হয়েছে যাতে ক্যালেন্ডারের ছোট ঘরেও চেনা যায়।
// এটি শুধুই ভিজুয়াল — কোনো Panchang/Calendar ডেটা বা হিসেবের সাথে
// সম্পর্ক নেই।
// =====================================================================

class PanjikaArt extends StatelessWidget {
  final String motif;
  final double size;
  const PanjikaArt(this.motif, {super.key, this.size = 24});

  /// উৎসব/তিথির নাম ও ক্যাটাগরি থেকে উপযুক্ত motif বেছে নেয়।
  /// প্রথমে তিথি-ক্যাটাগরি (পূর্ণিমা/অমাবস্যা/একাদশী/সংক্রান্তি), তারপর
  /// নামের ভেতরের শব্দ মিলিয়ে। কিছুই না মিললে null (তখন আগের ইমোজি/
  /// ডিফল্ট অলঙ্করণ দেখানো হবে)।
  static String? motifFor(
    String label,
    String category, {
    bool sankranti = false,
  }) {
    switch (category) {
      case 'purnima':
        return 'moonFull';
      case 'amabasya':
        return 'moonNew';
      case 'ekadashi':
        return 'tulsi';
    }
    bool has(List<String> keys) => keys.any((k) => label.contains(k));
    if (has([
      'দুর্গা',
      'ষষ্ঠী',
      'সপ্তমী',
      'অষ্টমী',
      'নবমী',
      'দশমী',
      'মহালয়া',
    ])) {
      return 'trishul';
    }
    if (has(['কালী', 'দীপাবলি', 'দিওয়ালি', 'দীপ'])) return 'diya';
    if (has(['লক্ষ্মী', 'কোজাগরী'])) return 'lotus';
    if (has(['সরস্বতী'])) return 'veena';
    if (has(['শিব', 'শিবরাত্রি'])) return 'shiva';
    if (has(['জন্মাষ্টমী', 'কৃষ্ণ'])) return 'peacock';
    if (has(['গণেশ'])) return 'lotus';
    if (has(['রথ'])) return 'temple';
    if (has(['রাম নবমী', 'মন্দির', 'পূজা'])) return 'temple';
    if (has(['রাখি', 'ভাইফোঁটা', 'ভাই'])) return 'rakhi';
    if (has(['ধনতেরাস', 'ধন'])) return 'coin';
    if (has(['দোল', 'হোলি', 'বসন্ত'])) return 'flower';
    if (has(['পূর্ণিমা'])) return 'moonFull';
    if (has(['অমাবস্যা'])) return 'moonNew';
    if (has(['গ্রহণ'])) return 'moonNew';
    if (has(['স্বাধীনতা', 'প্রজাতন্ত্র', 'দিবস'])) return 'flag';
    if (has(['নববর্ষ', 'বড়দিন'])) return 'star';
    // নামের সাথে কিছু না মিললেও, মাস-শুরুর (সংক্রান্তি) দিনে সূর্য
    if (sankranti) return 'sun';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PanjikaArtPainter(motif)),
    );
  }
}

class _PanjikaArtPainter extends CustomPainter {
  final String motif;
  _PanjikaArtPainter(this.motif);

  // ঐতিহ্যবাহী প্যালেট
  static const _saffron = Color(0xFFE8871E);
  static const _saffronLt = Color(0xFFF3A93B);
  static const _red = Color(0xFFC62828);
  static const _gold = Color(0xFFD9A73A);
  static const _goldLt = Color(0xFFF2CE63);
  static const _cream = Color(0xFFF6EFD6);
  static const _navy = Color(0xFF17225C);
  static const _green = Color(0xFF2E7D32);
  static const _leaf = Color(0xFF3FA04A);
  static const _flame = Color(0xFFFF7A00);
  static const _flameCore = Color(0xFFFFD24A);
  static const _moon = Color(0xFFF7EFCF);
  static const _pink = Color(0xFFF39BB8);
  static const _pinkDp = Color(0xFFDB5C86);
  static const _peaBlue = Color(0xFF1E6FB0);
  static const _peaGreen = Color(0xFF1F9E77);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    switch (motif) {
      case 'moonFull':
        // নরম আলোর বলয় + পূর্ণ চাঁদ + কয়েকটা হালকা গর্ত
        fill.color = _goldLt.withValues(alpha: 0.28);
        canvas.drawCircle(p(0.5, 0.5), s * 0.46, fill);
        fill.color = _moon;
        canvas.drawCircle(p(0.5, 0.5), s * 0.34, fill);
        fill.color = const Color(0xFFE4D9B0);
        canvas.drawCircle(p(0.40, 0.42), s * 0.05, fill);
        canvas.drawCircle(p(0.58, 0.55), s * 0.06, fill);
        canvas.drawCircle(p(0.55, 0.36), s * 0.032, fill);
        break;

      case 'moonNew':
        // অন্ধকার চাঁদ, বাঁ দিকে সরু রুপালি কাস্তে
        fill.color = const Color(0xFF3A3F63);
        canvas.drawCircle(p(0.5, 0.5), s * 0.34, fill);
        final crescent = Path()
          ..addArc(
            Rect.fromCircle(center: p(0.5, 0.5), radius: s * 0.34),
            math.pi * 0.62,
            math.pi * 0.76,
          );
        stroke
          ..color = _moon
          ..strokeWidth = s * 0.05;
        canvas.drawPath(crescent, stroke);
        break;

      case 'diya':
        // প্রদীপ — মাটির বাটি, সোনালি রিম, শিখা ও নরম আভা
        fill.color = _flame.withValues(alpha: 0.22);
        canvas.drawCircle(p(0.5, 0.30), s * 0.20, fill);
        // শিখা
        final flame = Path()
          ..moveTo(s * 0.5, s * 0.14)
          ..cubicTo(s * 0.62, s * 0.30, s * 0.60, s * 0.44, s * 0.5, s * 0.46)
          ..cubicTo(s * 0.40, s * 0.44, s * 0.38, s * 0.30, s * 0.5, s * 0.14)
          ..close();
        fill.color = _flame;
        canvas.drawPath(flame, fill);
        final flameIn = Path()
          ..moveTo(s * 0.5, s * 0.24)
          ..cubicTo(s * 0.56, s * 0.32, s * 0.55, s * 0.41, s * 0.5, s * 0.43)
          ..cubicTo(s * 0.45, s * 0.41, s * 0.44, s * 0.32, s * 0.5, s * 0.24)
          ..close();
        fill.color = _flameCore;
        canvas.drawPath(flameIn, fill);
        // বাটি
        final bowl = Path()
          ..moveTo(s * 0.16, s * 0.60)
          ..cubicTo(s * 0.24, s * 0.86, s * 0.76, s * 0.86, s * 0.84, s * 0.60)
          ..close();
        fill.color = const Color(0xFFB5502A);
        canvas.drawPath(bowl, fill);
        // রিম
        stroke
          ..color = _gold
          ..strokeWidth = s * 0.05;
        canvas.drawLine(p(0.16, 0.60), p(0.84, 0.60), stroke);
        fill.color = _goldLt;
        canvas.drawCircle(p(0.5, 0.60), s * 0.05, fill);
        break;

      case 'lotus':
        {
          // পদ্ম — পেছনের সারি হালকা, সামনের সারি গাঢ় ডগা
          void petal(double cx, double angle, double len, Color c) {
            canvas.save();
            canvas.translate(cx * s, 0.66 * s);
            canvas.rotate(angle);
            final path = Path()
              ..moveTo(0, 0)
              ..quadraticBezierTo(-len * 0.28 * s, -len * 0.5 * s, 0, -len * s)
              ..quadraticBezierTo(len * 0.28 * s, -len * 0.5 * s, 0, 0)
              ..close();
            fill.color = c;
            canvas.drawPath(path, fill);
            canvas.restore();
          }

          // পেছনের সারি
          petal(0.5, -0.9, 0.42, _pink.withValues(alpha: 0.8));
          petal(0.5, 0.9, 0.42, _pink.withValues(alpha: 0.8));
          petal(0.5, -0.45, 0.5, _pink);
          petal(0.5, 0.45, 0.5, _pink);
          // সামনের কেন্দ্রীয় পাপড়ি
          petal(0.5, 0.0, 0.56, _pinkDp);
          petal(0.5, -0.22, 0.52, _pink);
          petal(0.5, 0.22, 0.52, _pink);
          fill.color = _goldLt;
          canvas.drawCircle(p(0.5, 0.62), s * 0.05, fill);
        }
        break;

      case 'sun':
        // সূর্য — কেন্দ্র ও চারপাশে রশ্মি (সংক্রান্তি)
        stroke
          ..color = _saffron
          ..strokeWidth = s * 0.045;
        for (int i = 0; i < 12; i++) {
          final a = i * math.pi / 6;
          canvas.drawLine(
            p(0.5 + 0.30 * math.cos(a), 0.5 + 0.30 * math.sin(a)),
            p(0.5 + 0.42 * math.cos(a), 0.5 + 0.42 * math.sin(a)),
            stroke,
          );
        }
        fill.color = _saffronLt;
        canvas.drawCircle(p(0.5, 0.5), s * 0.24, fill);
        fill.color = _saffron;
        canvas.drawCircle(p(0.5, 0.5), s * 0.16, fill);
        break;

      case 'trishul':
        // ত্রিশূল — দুর্গা/শক্তির প্রতীক
        stroke
          ..color = _gold
          ..strokeWidth = s * 0.055;
        canvas.drawLine(p(0.5, 0.30), p(0.5, 0.9), stroke);
        // মাঝের ফলা
        final mid = Path()
          ..moveTo(s * 0.5, s * 0.08)
          ..lineTo(s * 0.44, s * 0.30)
          ..lineTo(s * 0.56, s * 0.30)
          ..close();
        fill.color = _gold;
        canvas.drawPath(mid, fill);
        // পাশের দুই বাঁকানো ফলা
        stroke.strokeWidth = s * 0.05;
        final left = Path()
          ..moveTo(s * 0.30, s * 0.16)
          ..quadraticBezierTo(s * 0.30, s * 0.34, s * 0.42, s * 0.34);
        final right = Path()
          ..moveTo(s * 0.70, s * 0.16)
          ..quadraticBezierTo(s * 0.70, s * 0.34, s * 0.58, s * 0.34);
        canvas.drawPath(left, stroke);
        canvas.drawPath(right, stroke);
        canvas.drawLine(p(0.30, 0.16), p(0.30, 0.30), stroke);
        canvas.drawLine(p(0.70, 0.16), p(0.70, 0.30), stroke);
        // বাঁধন
        fill.color = _red;
        canvas.drawCircle(p(0.5, 0.34), s * 0.045, fill);
        break;

      case 'temple':
        // মন্দির — চূড়া (শিখর), কলস ও পতাকা
        fill.color = _saffronLt;
        // মূল কাঠামো
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.28, s * 0.55, s * 0.44, s * 0.35),
            Radius.circular(s * 0.02),
          ),
          fill,
        );
        // শিখর (ত্রিভুজাকার স্তর)
        final spire = Path()
          ..moveTo(s * 0.5, s * 0.14)
          ..lineTo(s * 0.30, s * 0.55)
          ..lineTo(s * 0.70, s * 0.55)
          ..close();
        fill.color = _saffron;
        canvas.drawPath(spire, fill);
        // দরজা
        fill.color = _navy;
        final door = Path()
          ..moveTo(s * 0.43, s * 0.90)
          ..lineTo(s * 0.43, s * 0.68)
          ..arcToPoint(
            Offset(s * 0.57, s * 0.68),
            radius: Radius.circular(s * 0.07),
          )
          ..lineTo(s * 0.57, s * 0.90)
          ..close();
        canvas.drawPath(door, fill);
        // কলস + পতাকা
        fill.color = _gold;
        canvas.drawCircle(p(0.5, 0.12), s * 0.04, fill);
        stroke
          ..color = _gold
          ..strokeWidth = s * 0.03;
        canvas.drawLine(p(0.5, 0.12), p(0.5, 0.03), stroke);
        fill.color = _red;
        final flag = Path()
          ..moveTo(s * 0.5, s * 0.03)
          ..lineTo(s * 0.66, s * 0.07)
          ..lineTo(s * 0.5, s * 0.11)
          ..close();
        canvas.drawPath(flag, fill);
        break;

      case 'veena':
        // সরস্বতীর বীণা — সরলীকৃত: লম্বা দণ্ড, গোল অনুরণক ও তার
        stroke
          ..color = _gold
          ..strokeWidth = s * 0.05;
        canvas.drawLine(p(0.28, 0.78), p(0.74, 0.24), stroke);
        fill.color = _saffronLt;
        canvas.drawCircle(p(0.26, 0.80), s * 0.14, fill);
        fill.color = _saffron;
        canvas.drawCircle(p(0.26, 0.80), s * 0.09, fill);
        fill.color = _cream;
        canvas.drawCircle(p(0.76, 0.22), s * 0.06, fill);
        stroke
          ..color = _navy
          ..strokeWidth = s * 0.018;
        canvas.drawLine(p(0.30, 0.74), p(0.72, 0.28), stroke);
        break;

      case 'shiva':
        // শিব — ত্রিশূলের সাথে অর্ধচন্দ্র
        stroke
          ..color = _navy
          ..strokeWidth = s * 0.05;
        canvas.drawLine(p(0.5, 0.34), p(0.5, 0.9), stroke);
        final tri = Path()
          ..moveTo(s * 0.5, s * 0.20)
          ..lineTo(s * 0.45, s * 0.34)
          ..lineTo(s * 0.55, s * 0.34)
          ..close();
        fill.color = _navy;
        canvas.drawPath(tri, fill);
        stroke.strokeWidth = s * 0.045;
        canvas.drawLine(p(0.33, 0.24), p(0.33, 0.34), stroke);
        canvas.drawLine(p(0.67, 0.24), p(0.67, 0.34), stroke);
        // অর্ধচন্দ্র
        stroke
          ..color = _gold
          ..strokeWidth = s * 0.05;
        canvas.drawArc(
          Rect.fromCircle(center: p(0.5, 0.14), radius: s * 0.12),
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          stroke,
        );
        break;

      case 'peacock':
        // ময়ূরপালক — জন্মাষ্টমী/কৃষ্ণ
        stroke
          ..color = _peaGreen
          ..strokeWidth = s * 0.03;
        canvas.drawLine(p(0.5, 0.9), p(0.5, 0.34), stroke);
        // পালকের চোখ
        fill.color = _peaBlue.withValues(alpha: 0.85);
        canvas.drawOval(
          Rect.fromCenter(
            center: p(0.5, 0.28),
            width: s * 0.36,
            height: s * 0.5,
          ),
          fill,
        );
        fill.color = _peaGreen;
        canvas.drawOval(
          Rect.fromCenter(
            center: p(0.5, 0.30),
            width: s * 0.24,
            height: s * 0.34,
          ),
          fill,
        );
        fill.color = _gold;
        canvas.drawCircle(p(0.5, 0.30), s * 0.08, fill);
        fill.color = _navy;
        canvas.drawCircle(p(0.5, 0.31), s * 0.045, fill);
        // barbs
        stroke
          ..color = _peaGreen.withValues(alpha: 0.7)
          ..strokeWidth = s * 0.02;
        for (int i = 0; i < 4; i++) {
          final y = 0.5 + i * 0.1;
          canvas.drawLine(p(0.5, y), p(0.5 - 0.12, y - 0.05), stroke);
          canvas.drawLine(p(0.5, y), p(0.5 + 0.12, y - 0.05), stroke);
        }
        break;

      case 'flower':
        // গাঁদা/সাধারণ ফুল — বসন্ত/দোল
        fill.color = _saffron;
        for (int i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawCircle(
            p(0.5 + 0.22 * math.cos(a), 0.5 + 0.22 * math.sin(a)),
            s * 0.11,
            fill,
          );
        }
        fill.color = _saffronLt;
        for (int i = 0; i < 8; i++) {
          final a = i * math.pi / 4 + math.pi / 8;
          canvas.drawCircle(
            p(0.5 + 0.14 * math.cos(a), 0.5 + 0.14 * math.sin(a)),
            s * 0.08,
            fill,
          );
        }
        fill.color = _gold;
        canvas.drawCircle(p(0.5, 0.5), s * 0.10, fill);
        break;

      case 'rakhi':
        // রাখি — মাঝে রোজেট, দুই পাশে সুতো
        stroke
          ..color = _red
          ..strokeWidth = s * 0.05;
        canvas.drawLine(p(0.05, 0.5), p(0.30, 0.5), stroke);
        canvas.drawLine(p(0.70, 0.5), p(0.95, 0.5), stroke);
        fill.color = _gold;
        for (int i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawCircle(
            p(0.5 + 0.16 * math.cos(a), 0.5 + 0.16 * math.sin(a)),
            s * 0.07,
            fill,
          );
        }
        fill.color = _red;
        canvas.drawCircle(p(0.5, 0.5), s * 0.11, fill);
        fill.color = _goldLt;
        canvas.drawCircle(p(0.5, 0.5), s * 0.05, fill);
        break;

      case 'coin':
        // স্বর্ণমুদ্রা — ধনতেরাস
        fill.color = _gold;
        canvas.drawCircle(p(0.5, 0.5), s * 0.34, fill);
        stroke
          ..color = _goldLt
          ..strokeWidth = s * 0.04;
        canvas.drawCircle(p(0.5, 0.5), s * 0.27, stroke);
        // কেন্দ্রে তারা
        fill.color = _cream;
        final star = Path();
        for (int i = 0; i < 10; i++) {
          final r = i.isEven ? 0.16 : 0.07;
          final a = -math.pi / 2 + i * math.pi / 5;
          final pt = p(0.5 + r * math.cos(a), 0.5 + r * math.sin(a));
          if (i == 0) {
            star.moveTo(pt.dx, pt.dy);
          } else {
            star.lineTo(pt.dx, pt.dy);
          }
        }
        star.close();
        canvas.drawPath(star, fill);
        break;

      case 'flag':
        // তেরঙা — জাতীয় দিবস
        stroke
          ..color = const Color(0xFF7A5230)
          ..strokeWidth = s * 0.035;
        canvas.drawLine(p(0.22, 0.12), p(0.22, 0.92), stroke);
        fill.color = _saffron;
        canvas.drawRect(
          Rect.fromLTWH(s * 0.24, s * 0.20, s * 0.54, s * 0.12),
          fill,
        );
        fill.color = Colors.white;
        canvas.drawRect(
          Rect.fromLTWH(s * 0.24, s * 0.32, s * 0.54, s * 0.12),
          fill,
        );
        fill.color = _green;
        canvas.drawRect(
          Rect.fromLTWH(s * 0.24, s * 0.44, s * 0.54, s * 0.12),
          fill,
        );
        stroke
          ..color = _navy
          ..strokeWidth = s * 0.02;
        canvas.drawCircle(p(0.51, 0.38), s * 0.045, stroke);
        break;

      case 'tulsi':
        // তুলসী মঞ্চ — একাদশী/ব্রত
        fill.color = const Color(0xFFB5502A);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.34, s * 0.55, s * 0.32, s * 0.34),
            Radius.circular(s * 0.03),
          ),
          fill,
        );
        fill.color = const Color(0xFF8E3F20);
        canvas.drawRect(
          Rect.fromLTWH(s * 0.30, s * 0.52, s * 0.40, s * 0.06),
          fill,
        );
        // গাছ
        stroke
          ..color = _green
          ..strokeWidth = s * 0.035;
        canvas.drawLine(p(0.5, 0.55), p(0.5, 0.30), stroke);
        fill.color = _leaf;
        for (int i = 0; i < 6; i++) {
          final a = -math.pi / 2 + (i - 2.5) * 0.5;
          canvas.drawOval(
            Rect.fromCenter(
              center: p(0.5 + 0.16 * math.cos(a), 0.34 + 0.14 * math.sin(a)),
              width: s * 0.12,
              height: s * 0.07,
            ),
            fill,
          );
        }
        fill.color = _green;
        canvas.drawCircle(p(0.5, 0.24), s * 0.06, fill);
        break;

      case 'star':
      default:
        // সাধারণ অলঙ্করণ — আট-কোণা তারা
        fill.color = _goldLt;
        final st = Path();
        for (int i = 0; i < 16; i++) {
          final r = i.isEven ? 0.40 : 0.17;
          final a = -math.pi / 2 + i * math.pi / 8;
          final pt = p(0.5 + r * math.cos(a), 0.5 + r * math.sin(a));
          if (i == 0) {
            st.moveTo(pt.dx, pt.dy);
          } else {
            st.lineTo(pt.dx, pt.dy);
          }
        }
        st.close();
        canvas.drawPath(st, fill);
        fill.color = _gold;
        canvas.drawCircle(p(0.5, 0.5), s * 0.10, fill);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PanjikaArtPainter old) => old.motif != motif;
}

// =====================================================================
// বাংলা ক্যালেন্ডার পেজ
// =====================================================================

class _AllServicesHomeButton extends StatelessWidget {
  const _AllServicesHomeButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SuperServicesScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF34105F), Color(0xFF75237F)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4B33C), width: 1.2),
        ),
        child: const Row(
          children: [
            Text('✨', style: TextStyle(fontSize: 27)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'সব সেবা',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'পঞ্জিকা • শুভদিন • পূজা • পরিবার • স্মার্ট টুল',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFFFFD469),
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuperServiceData {
  final String icon;
  final String title;

  const _SuperServiceData(this.icon, this.title);
}

class SuperServicesScreen extends StatelessWidget {
  const SuperServicesScreen({super.key});

  void _open(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title সেবা নির্বাচন করা হয়েছে'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<_SuperServiceData> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF41145F),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            childAspectRatio: 0.98,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return GestureDetector(
              onTap: () => _open(context, item.title),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE4DFEA)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.icon, style: const TextStyle(fontSize: 27)),
                    const SizedBox(height: 7),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF17225C),
                        fontSize: 10.5,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const panjika = [
      _SuperServiceData('📅', 'বাংলা ক্যালেন্ডার'),
      _SuperServiceData('🌞', 'আজকের পঞ্জিকা'),
      _SuperServiceData('🌿', 'একাদশী'),
      _SuperServiceData('🌕', 'পূর্ণিমা'),
      _SuperServiceData('🌑', 'অমাবস্যা'),
      _SuperServiceData('🎉', 'উৎসব'),
    ];

    const goodDays = [
      _SuperServiceData('⭐', 'শুভ মুহূর্ত'),
      _SuperServiceData('💍', 'বিবাহ'),
      _SuperServiceData('🏠', 'গৃহপ্রবেশ'),
      _SuperServiceData('🚗', 'গাড়ি কেনা'),
      _SuperServiceData('🏞️', 'জমি কেনা'),
      _SuperServiceData('🪔', 'ব্যবসা শুরু'),
    ];

    const personal = [
      _SuperServiceData('👨‍👩‍👧', 'Family Calendar'),
      _SuperServiceData('⏰', 'Reminder'),
      _SuperServiceData('🎂', 'বাংলা জন্মদিন'),
      _SuperServiceData('❤️', 'Favourite Day'),
      _SuperServiceData('📝', 'আমার Notes'),
      _SuperServiceData('🔔', 'Festival Alert'),
    ];

    const smart = [
      _SuperServiceData('🔎', 'Smart Search'),
      _SuperServiceData('🎙️', 'বাংলা Voice'),
      _SuperServiceData('🔄', 'Date Converter'),
      _SuperServiceData('🧭', 'আজ কী ভালো'),
      _SuperServiceData('🌙', 'Moon Phase'),
      _SuperServiceData('📊', 'Month Summary'),
    ];

    const puja = [
      _SuperServiceData('🛕', 'Puja Planner'),
      _SuperServiceData('✅', 'Puja Checklist'),
      _SuperServiceData('📿', 'জপ কাউন্টার'),
      _SuperServiceData('🥗', 'উপবাস তথ্য'),
      _SuperServiceData('📖', 'তিথির অর্থ'),
      _SuperServiceData('🏆', 'Festival Countdown'),
    ];

    const create = [
      _SuperServiceData('🖼️', 'Daily Share Card'),
      _SuperServiceData('🎨', 'Festival Poster'),
      _SuperServiceData('📚', 'আজকের ইতিহাস'),
      _SuperServiceData('📱', 'Home Widget'),
      _SuperServiceData('☁️', 'Backup'),
      _SuperServiceData('⚙️', 'Settings'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF241652),
        foregroundColor: Colors.white,
        title: const Text(
          '✨ সব সেবা',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF34105F), Color(0xFF74217E)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Text('🪷', style: TextStyle(fontSize: 38)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'বাংলা পঞ্জিকার সব প্রয়োজনীয় সেবা এক জায়গায়',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _section(context, '📅 পঞ্জিকা ও উৎসব', panjika),
          _section(context, '⭐ শুভ দিন ও কাজ', goodDays),
          _section(context, '👨‍👩‍👧 ব্যক্তিগত ও পরিবার', personal),
          _section(context, '🧠 Smart Tools', smart),
          _section(context, '🪔 পূজা ও ব্রত', puja),
          _section(context, '🎨 Create & Extra', create),
        ],
      ),
    );
  }
}

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
    'ব্যবসা শুরু',
    'নামকরণ',
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
  // রেফারেন্স ছাপা ক্যালেন্ডারের মতো মাস নেভিগেশনে পুরো ইংরেজি মাসের নাম
  static const _engMonthFull = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];
  static const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

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
      case 'ব্যবসা শুরু':
        return 'byabosha';
      case 'নামকরণ':
        return 'namakaran';
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

  // ---- প্রথাগত পঞ্জিকার রং-কোডিং — প্রতিটা দিনের ঘরে এক নজরে বোঝার জন্য ----
  static const Color _purnimaColor = Color(0xFFFFD36E); // সোনালি — পূর্ণিমা
  static const Color _amabasyaColor = Color(
    0xFFA285E8,
  ); // গাঢ় বেগুনি — অমাবস্যা
  static const Color _ekadashiColor = Color(0xFFFF9A3E); // জাফরান — একাদশী
  static const Color _sankrantiColor = Color(
    0xFF2FBFA3,
  ); // টিল — সংক্রান্তি (মাস শুরু)
  static const Color _festivalColor = Color(
    0xFFE0384A,
  ); // লাল — উৎসব/শুভ দিন/রবিবার

  bool _hasCategory(List<CalendarEvent> events, String cat) =>
      events.any((e) => e.category == cat);

  /// দিনের ঘরের প্রধান (সবচেয়ে গুরুত্বপূর্ণ) রং — একাধিক প্রযোজ্য হলে
  /// প্রথাগত পঞ্জিকার অগ্রাধিকার অনুযায়ী: পূর্ণিমা > অমাবস্যা > একাদশী >
  /// সংক্রান্তি > উৎসব/শুভ দিন > রবিবার
  Color? _primaryCategoryColor(
    List<CalendarEvent> events,
    bool isSankranti,
    bool isSunday,
  ) {
    if (_hasCategory(events, 'purnima')) return _purnimaColor;
    if (_hasCategory(events, 'amabasya')) return _amabasyaColor;
    if (_hasCategory(events, 'ekadashi')) return _ekadashiColor;
    if (isSankranti) return _sankrantiColor;
    if (events.isNotEmpty) return _festivalColor;
    if (isSunday) return _festivalColor;
    return null;
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7290), fontSize: 11.5),
        ),
      ],
    );
  }

  Widget _detailChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7290), fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF17225C),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// রেফারেন্স ছাপা পঞ্জিকার মতোই — একটা সরু সাইডবার, গ্রিডের পাশে
  /// পাশাপাশি বসে। শকাব্দ/বাংলা সন/অয়ন, সূর্যোদয়-অস্ত, চন্দ্রোদয়-অস্ত ও
  /// রাহুকাল/যমগণ্ড/গুলিকাল — সবই real হিসেব (নতুন কোনো astronomy model
  /// নয়, আগে থেকেই থাকা sunTimes/rahuKalam-এর প্যাটার্ন পুনরায় ব্যবহার)।
  Widget _sidebarPanel(BuildContext context, BengaliMonthInfo info) {
    final now = DateTime.now();
    final sun = PanchangCalculator.sunTimes(
      now,
      lat: AppLocation.lat,
      lon: AppLocation.lon,
    );
    final moonAge = PanchangCalculator.moonAgeDays(now);
    final moonrise = sun.sunrise.add(
      Duration(minutes: (moonAge * 48.8).round()),
    );
    final moonset = moonrise.add(const Duration(hours: 12, minutes: 25));
    final rahu = PanchangCalculator.rahuKalam(
      now,
      lat: AppLocation.lat,
      lon: AppLocation.lon,
    );
    final yama = PanchangCalculator.yamagandaKalam(
      now,
      lat: AppLocation.lat,
      lon: AppLocation.lon,
    );
    final gulika = PanchangCalculator.gulikaKalam(
      now,
      lat: AppLocation.lat,
      lon: AppLocation.lon,
    );
    final ayana = PanchangCalculator.ayana(now);
    final shaka = PanchangCalculator.shakaYearFromBengali(info.year);

    // একটা তথ্য-জোড়া (আইকন + লেবেল + মান) — মকআপের মতো ২-কলামে বসে
    Widget kv(String icon, String label, String value, {bool warn = false}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Text(
                  icon,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF6B7290),
                        fontSize: 10,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: warn
                            ? const Color(0xFFB4272E)
                            : const Color(0xFF17225C),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E6F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- শকাব্দ / বঙ্গাব্দ / অয়ন — এক সারিতে ----
          Wrap(
            spacing: 14,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'শকাব্দ ${bnNum(shaka)}',
                style: const TextStyle(
                  color: Color(0xFFB4272E),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                'বঙ্গাব্দ ${bnNum(info.year)}',
                style: const TextStyle(
                  color: Color(0xFF17225C),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                '☯ $ayana',
                style: const TextStyle(color: Color(0xFF6B7290), fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFEEF0F5)),
          // ---- সময়গুলো ২ কলামে ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    kv('☀️', 'সূর্যোদয়', bnTime12(sun.sunrise)),
                    kv('🌙', 'চন্দ্রোদয়', bnTime12(moonrise)),
                    kv(
                      '🐍',
                      'রাহুকাল',
                      '${bnTime12(rahu['start']!)} – ${bnTime12(rahu['end']!)}',
                      warn: true,
                    ),
                    kv(
                      '🪐',
                      'গুলিকাল',
                      '${bnTime12(gulika['start']!)} – ${bnTime12(gulika['end']!)}',
                      warn: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    kv('🌇', 'সূর্যাস্ত', bnTime12(sun.sunset)),
                    kv('🌘', 'চন্দ্রাস্ত', bnTime12(moonset)),
                    kv(
                      '⚠️',
                      'যমগণ্ড',
                      '${bnTime12(yama['start']!)} – ${bnTime12(yama['end']!)}',
                      warn: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => const _FeatureSheet(title: 'পঞ্জিকা'),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF17225C),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'পঞ্চাঙ্গ বিস্তারিত ›',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// রেফারেন্স ছাপা ক্যালেন্ডারের নিচের ৮টা ফাংশন-আইকনের সারি — একই
  /// লেবেলগুলো, প্রতিটাই অ্যাপের আগে থেকেই থাকা স্ক্রিন/ফিচারে নিয়ে যায়
  /// (কোনো নতুন স্ক্রিন/প্যাকেজ/ব্যাকএন্ড লাগেনি)।
  Widget _quickIconRow(BuildContext context) {
    Widget item(String icon, String label, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 78,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3E6F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  color: Color(0xFF17225C),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showWeatherQuick(BuildContext context) {
    final temp = WeatherService.instance.tempC;
    final raining = WeatherService.instance.isRaining;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          temp == null
              ? 'আবহাওয়ার তথ্য এখনো পাওয়া যায়নি'
              : '🌡️ তাপমাত্রা ${temp.toStringAsFixed(1)}°C'
                    '${raining ? ' • 🌧️ বৃষ্টি হচ্ছে' : ' • ☀️ বৃষ্টি নেই'}',
        ),
      ),
    );
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

    // রেফারেন্স ছাপা পঞ্জিকার মতো হালকা/সাদা থিম — এই স্ক্রিনটার জন্যই
    // (অ্যাপের বাকি সব স্ক্রিন এখনো আগের গাঢ় cosmic থিমে অপরিবর্তিত)।
    // Material দিয়ে র‍্যাপ করা — নাহলে ভেতরের IconButton/InkWell "No Material
    // widget found" এরর দেখাত (আগে CosmicBackground এই Material দিত)।
    return Material(
      color: const Color(0xFFF2F3F9),
      child: SafeArea(
        child: Column(
          children: [
            // ---- হেডার — নেভি বার, রেফারেন্স ছাপা ক্যালেন্ডারের মতো ----
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF161E52), Color(0xFF2B1F6B)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'বাংলা ক্যালেন্ডার ${info.start.year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _goToday,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        '📅 আজকের দিন',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                children: [
                  // ---- ট্যাব বার (ফিল্টার) ----
                  SizedBox(
                    height: 34,
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
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF161E52)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFF161E52)
                                    : const Color(0xFFD8DCEA),
                              ),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF3A4570),
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
                  const SizedBox(height: 10),
                  // ---- পঞ্চাঙ্গ তথ্য প্যানেল (উপরে, পুরো চওড়া) ----
                  // ফোন খাড়াই (portrait) থাকে — স্ক্রিন rotate হয় না। তাই
                  // সাইডবারটা গ্রিডের পাশে না রেখে উপরে পুরো চওড়া প্যানেল
                  // আকারে বসানো হয়েছে, আর নিচে গ্রিড পুরো চওড়া পায়।
                  _sidebarPanel(context, info),
                  const SizedBox(height: 12),
                  // ---- গ্রিড (পুরো চওড়া) ----
                  Column(
                    children: [
                      // ---- মাস switcher — রেফারেন্সের মতো বড় ইংরেজি
                      // মাসের নাম প্রধান, বাংলা মাস/সাল ছোট সাবটাইটেল
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE3E6F0)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_left,
                                color: Color(0xFF161E52),
                              ),
                              tooltip: 'আগের মাস',
                              onPressed: () => _changeMonth(-1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  // বাংলা মাস ও সন — বড়, প্রধান
                                  Text(
                                    '${info.name} ${_bn(info.year)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFB4272E),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  // ইংরেজি মাস/সাল — ছোট, নিচে
                                  Text(
                                    '${_engMonthFull[info.start.month - 1]}${info.start.month != info.end.month ? '–${_engMonthFull[info.end.month - 1]}' : ''} ${info.start.year}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7290),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF161E52),
                              ),
                              tooltip: 'পরের মাস',
                              onPressed: () => _changeMonth(1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: _weekDays
                            .asMap()
                            .entries
                            .map(
                              (entry) => Expanded(
                                child: Center(
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      // রবিবার (সূচি ০) লাল
                                      color: entry.key == 0
                                          ? _festivalColor
                                          : const Color(0xFF3A4570),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 4),
                      GridView.builder(
                        shrinkWrap: true,
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: false,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: leading + totalDays + trailing,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 3,
                              crossAxisSpacing: 3,
                              mainAxisExtent: 74,
                            ),
                        itemBuilder: (context, i) {
                          // --- আগের মাসের গ্রে করা দিনগুলো ---
                          if (i < leading) {
                            final d = prevTotalDays - leading + 1 + i;
                            return Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F7FB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _bn(d),
                                style: const TextStyle(
                                  color: Color(0xFFC3C7D9),
                                  fontSize: 12,
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
                                color: const Color(0xFFF6F7FB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _bn(d),
                                style: const TextStyle(
                                  color: Color(0xFFC3C7D9),
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          // --- বর্তমান মাসের দিন ---
                          final bengaliDay = i - leading + 1;
                          final greg = info.start.add(
                            Duration(days: bengaliDay - 1),
                          );
                          final key = _key(greg);
                          final events = BengaliCalendarData.eventsFor(greg);
                          final now = DateTime.now();
                          final isToday =
                              greg.year == now.year &&
                              greg.month == now.month &&
                              greg.day == now.day;
                          final isSelected = key == _selectedKey;
                          final isSankranti = bengaliDay == 1;
                          final isSunday = greg.weekday == DateTime.sunday;
                          final matchesFilter = filterCat.isEmpty
                              ? events.isNotEmpty
                              : events.any((e) => e.category == filterCat);
                          final dim = _tab != 'সম্পূর্ণ মাস' && !matchesFilter;

                          // এই দিনের তিথির নাম — আসল বাংলা পঞ্জিকার
                          // মতো প্রতিটা ঘরে দেখানোর জন্য (সূর্যোদয়ের
                          // সময়ের তিথি, প্রচলিত নিয়ম)। বিদ্যমান
                          // tithiFor হিসেবই পুনরায় ব্যবহার — নতুন কিছু নয়।
                          final cellSunrise = PanchangCalculator.sunTimes(
                            greg,
                            lat: AppLocation.lat,
                            lon: AppLocation.lon,
                          ).sunrise;
                          final cellTithi = PanchangCalculator.tithiFor(
                            cellSunrise,
                          ).name;

                          // একই দিনে একাধিক উৎসব/তিথি থাকলে — শুধু
                          // প্রথমটা দেখানোর বদলে, ঘরের নিজস্ব আইকন+রং
                          // কয়েক সেকেন্ড পর পর নরম fade-এ পালা করে
                          // সবগুলো দেখায় (_CalendarDayCell)
                          return _CalendarDayCell(
                            greg: greg,
                            bengaliDay: bengaliDay,
                            bnDay: _bn(bengaliDay),
                            tithiName: cellTithi,
                            // সংক্রান্তির দিনে ছোট ক্যাপশনে বাংলা
                            // মাসের নাম — কোন মাস শুরু হলো বোঝাতে
                            secondaryDateText: isSankranti ? info.name : '',
                            events: events,
                            isToday: isToday,
                            isSelected: isSelected,
                            isSankranti: isSankranti,
                            isSunday: isSunday,
                            dim: dim,
                            highlightTint:
                                matchesFilter && _tab != 'সম্পূর্ণ মাস',
                            primaryCategoryColor: _primaryCategoryColor,
                            onTap: () => setState(() => _selectedKey = key),
                          );
                        },
                      ),
                    ],
                  ),
                  _MonthlyPanjikaSlider(info: info),
                  const SizedBox(height: 10),
                  const SizedBox(height: 14),
                  // ---- রং-কোডিংয়ের সংক্ষিপ্ত নির্দেশিকা ----
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _legendDot(_purnimaColor, 'পূর্ণিমা'),
                      _legendDot(_amabasyaColor, 'অমাবস্যা'),
                      _legendDot(_ekadashiColor, 'একাদশী'),
                      _legendDot(_sankrantiColor, 'সংক্রান্তি'),
                      _legendDot(_festivalColor, 'উৎসব/রবিবার'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE3E6F0)),
                    ),
                    child: _selectedKey == null
                        ? const Text(
                            'একটা দিন সিলেক্ট করো বিস্তারিত দেখতে',
                            style: TextStyle(
                              color: Color(0xFF6B7290),
                              fontSize: 13,
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              final sel = DateTime.parse(_selectedKey!);
                              final sun = PanchangCalculator.sunTimes(
                                sel,
                                lat: AppLocation.lat,
                                lon: AppLocation.lon,
                              );
                              final tithi = PanchangCalculator.tithiFor(
                                sun.sunrise,
                              );
                              final nakIdx =
                                  PanchangCalculator.nakshatraIndexFor(
                                    sun.sunrise,
                                  );
                              final rashiIdx = PanchangCalculator.rashiIndexFor(
                                sun.sunrise,
                              );
                              final yogaIdx = PanchangCalculator.yogaIndexFor(
                                sun.sunrise,
                              );
                              final karana = PanchangCalculator.karanaFor(
                                sun.sunrise,
                              );
                              final rahu = PanchangCalculator.rahuKalam(
                                sel,
                                lat: AppLocation.lat,
                                lon: AppLocation.lon,
                              );
                              final abhijit = PanchangCalculator.abhijitMuhurta(
                                sel,
                                lat: AppLocation.lat,
                                lon: AppLocation.lon,
                              );
                              final (tithiStart, tithiEnd) =
                                  PanchangCalculator.tithiTiming(sun.sunrise);
                              final weekday = PanchangCalculator.weekdayName(
                                sel,
                              );
                              final selEvents = BengaliCalendarData.eventsFor(
                                sel,
                              );
                              // এই দিনের প্রধান উৎসব/তিথির জন্য অ্যাপের নিজস্ব
                              // বড় illustration — যদি থাকে
                              String? headMotif;
                              for (final e in selEvents) {
                                headMotif = PanjikaArt.motifFor(
                                  e.label,
                                  e.category,
                                );
                                if (headMotif != null) break;
                              }
                              headMotif ??=
                                  PanchangCalculator.tithiFor(
                                    sun.sunrise,
                                  ).name.contains('পূর্ণিমা')
                                  ? 'moonFull'
                                  : null;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (headMotif != null) ...[
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFCF6E6),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFEBD9A6),
                                            ),
                                          ),
                                          child: PanjikaArt(
                                            headMotif,
                                            size: 44,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      Expanded(
                                        child: Text(
                                          '${bnNum(sel.day)} ${gregMonthBn(sel.month)} ${bnNum(sel.year)} • $weekday',
                                          style: const TextStyle(
                                            color: Color(0xFFB4272E),
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 14,
                                    runSpacing: 6,
                                    children: [
                                      _detailChip(
                                        '🌙 তিথি',
                                        '${tithi.paksha}পক্ষ ${tithi.name}',
                                      ),
                                      _detailChip(
                                        '⭐ নক্ষত্র',
                                        PanchangCalculator
                                            .nakshatraNames[nakIdx],
                                      ),
                                      _detailChip(
                                        '☀️ সূর্যোদয়',
                                        bnTime12(sun.sunrise),
                                      ),
                                      _detailChip(
                                        '🌇 সূর্যাস্ত',
                                        bnTime12(sun.sunset),
                                      ),
                                      _detailChip(
                                        '🪐 চন্দ্র রাশি',
                                        PanchangCalculator.rashiNames[rashiIdx],
                                      ),
                                      _detailChip(
                                        '🔗 যোগ',
                                        PanchangCalculator.yogaNames[yogaIdx],
                                      ),
                                      _detailChip('⚙️ করণ', karana),
                                      _detailChip(
                                        '⏳ রাহুকাল (এড়িয়ে চলুন)',
                                        '${bnTime12(rahu['start']!)}–${bnTime12(rahu['end']!)}',
                                      ),
                                      _detailChip(
                                        '☀️ অভিজিৎ মুহূর্ত (শুভ)',
                                        abhijit['applicable'] == true
                                            ? '${bnTime12(abhijit['start'] as DateTime)}–${bnTime12(abhijit['end'] as DateTime)}'
                                            : 'প্রযোজ্য নয় (বুধবার)',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '🕉 ${tithi.name} তিথি — শুরু: ${ContentData._fmtTithiEdge(tithiStart)}  •  শেষ: ${ContentData._fmtTithiEdge(tithiEnd)}',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7290),
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                  const Divider(
                                    height: 22,
                                    color: Color(0xFFE3E6F0),
                                  ),
                                  if (selEvents.isEmpty)
                                    const Text(
                                      'কোনো বিশেষ দিন/উৎসব নেই',
                                      style: TextStyle(
                                        color: Color(0xFF6B7290),
                                        fontSize: 13,
                                      ),
                                    )
                                  else
                                    ...selEvents.map(
                                      (e) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          '${e.icon} ${e.label}',
                                          style: const TextStyle(
                                            color: Color(0xFF17225C),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '📍 তিথি, নক্ষত্র, চন্দ্র রাশি, সূর্যোদয়/অস্ত ও রাহুকাল সরাসরি হিসেব করে দেখানো হয় (আনুমানিক নির্ভুলতা)। বিবাহ/অন্নপ্রাশন/গৃহপ্রবেশের শুভ তারিখগুলো ২০২৬ সালের নমুনা তালিকা — সঠিক শুভ মুহূর্তের জন্য একজন জ্যোতিষীর পরামর্শ নেওয়া ভালো।',
                    style: TextStyle(
                      color: Color(0xFF6B7290),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _quickIconRow(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// একই বাংলা তারিখের ঘরে একাধিক তিথি/উৎসব/পালন-দিন একসাথে পড়লে —
/// শুধু প্রথমটা আটকে না রেখে, প্রতিটাকে পালা করে (কয়েক সেকেন্ড পর পর)
/// নরম fade transition-এ দেখানো হয়, যাতে ট্যাপ না করেই সবগুলো চোখে পড়ে।
/// প্রতিটা ঘর নিজের বাংলা তারিখ অনুযায়ী সামান্য ভিন্ন বিলম্বে শুরু হয়,
/// যাতে পুরো গ্রিডের সব ঘর একসাথে না বদলে স্বাভাবিক/জীবন্ত দেখায়।
class _MonthlyPanjikaSlider extends StatefulWidget {
  final BengaliMonthInfo info;

  const _MonthlyPanjikaSlider({required this.info});

  @override
  State<_MonthlyPanjikaSlider> createState() => _MonthlyPanjikaSliderState();
}

class _MonthlyPanjikaSliderState extends State<_MonthlyPanjikaSlider> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startSlider();
  }

  @override
  void didUpdateWidget(covariant _MonthlyPanjikaSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.info.start != widget.info.start) {
      _index = 0;
      _startSlider();
    }
  }

  void _startSlider() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;

      final items = _monthItems();

      if (items.length > 1) {
        setState(() {
          _index = (_index + 1) % items.length;
        });
      }
    });
  }

  List<Map<String, dynamic>> _monthItems() {
    final result = <Map<String, dynamic>>[];

    final total = widget.info.end.difference(widget.info.start).inDays + 1;

    for (var i = 0; i < total; i++) {
      final date = widget.info.start.add(Duration(days: i));

      final events = BengaliCalendarData.eventsFor(date);

      for (final event in events) {
        result.add({
          'date': date,
          'bengaliDay': i + 1,
          'label': event.label,
          'icon': event.icon,
          'category': event.category,
        });
      }
    }

    return result;
  }

  String _bn(int value) {
    const d = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

    return value.toString().split('').map((e) => d[int.parse(e)]).join();
  }

  String _typeName(String category) {
    switch (category) {
      case 'ekadashi':
        return 'একাদশী';
      case 'purnima':
        return 'পূর্ণিমা';
      case 'amabasya':
        return 'অমাবস্যা';
      case 'marriage':
        return 'বিবাহের শুভ দিন';
      case 'annaprashan':
        return 'অন্নপ্রাশনের শুভ দিন';
      case 'griha':
        return 'গৃহপ্রবেশের শুভ দিন';
      case 'byabosha':
        return 'ব্যবসার শুভ দিন';
      case 'namakaran':
        return 'নামকরণের শুভ দিন';
      default:
        return 'পূজা • উৎসব • বিশেষ দিন';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _monthItems();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final item = items[_index % items.length];

    final date = item['date'] as DateTime;
    final bengaliDay = item['bengaliDay'] as int;
    final label = item['label'] as String;
    final icon = item['icon'] as String;
    final category = item['category'] as String;

    return Container(
      width: double.infinity,
      height: 76,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF25104F), Color(0xFF651A78), Color(0xFF25104F)],
        ),
        border: Border.all(color: const Color(0xFFE4B33C), width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.25, 0),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Row(
            key: ValueKey('$label-${date.toIso8601String()}-$_index'),
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(icon, style: const TextStyle(fontSize: 25)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_bn(bengaliDay)} ${widget.info.name} • ${_typeName(category)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFD467),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_index + 1}/${items.length}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatefulWidget {
  final DateTime greg;
  final int bengaliDay;
  final String bnDay;
  final String secondaryDateText;
  final String tithiName;
  final List<CalendarEvent> events;
  final bool isToday;
  final bool isSelected;
  final bool isSankranti;
  final bool isSunday;
  final bool dim;
  final bool highlightTint;
  final Color? Function(
    List<CalendarEvent> events,
    bool isSankranti,
    bool isSunday,
  )
  primaryCategoryColor;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.greg,
    required this.bengaliDay,
    required this.bnDay,
    required this.secondaryDateText,
    required this.tithiName,
    required this.events,
    required this.isToday,
    required this.isSelected,
    required this.isSankranti,
    required this.isSunday,
    required this.dim,
    required this.highlightTint,
    required this.primaryCategoryColor,
    required this.onTap,
  });

  @override
  State<_CalendarDayCell> createState() => _CalendarDayCellState();
}

class _CalendarDayCellState extends State<_CalendarDayCell> {
  int _infoIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startInfoCycle();
  }

  @override
  void didUpdateWidget(covariant _CalendarDayCell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.greg != widget.greg ||
        oldWidget.events.length != widget.events.length ||
        oldWidget.isToday != widget.isToday) {
      _infoIndex = 0;
      _startInfoCycle();
    }
  }

  void _startInfoCycle() {
    _timer?.cancel();

    // Only today's box moves.
    if (!widget.isToday) {
      _infoIndex = 0;
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;

      setState(() {
        _infoIndex++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _specialIcon(CalendarEvent event) {
    switch (event.category) {
      case 'amabasya':
        return Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            shape: BoxShape.circle,
          ),
        );

      case 'purnima':
        return Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEF7),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF333333), width: 1),
          ),
        );

      case 'ekadashi':
        return const Icon(Icons.eco, size: 13, color: Color(0xFF278D4F));

      default:
        if (event.icon.trim().isEmpty || event.icon == '✦') {
          return const Icon(
            Icons.celebration,
            size: 12,
            color: Color(0xFFC62828),
          );
        }

        return Text(
          event.icon,
          style: const TextStyle(fontSize: 11, height: 1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    final primaryEvent = events.isNotEmpty ? events.first : null;

    final categoryColor = widget.primaryCategoryColor(
      events,
      widget.isSankranti,
      widget.isSunday,
    );

    final numberColor =
        categoryColor ??
        (widget.isSunday ? const Color(0xFFC62828) : const Color(0xFF10275E));

    final sun = PanchangCalculator.sunTimes(
      widget.greg,
      lat: AppLocation.lat,
      lon: AppLocation.lon,
    );

    final tithi = PanchangCalculator.tithiFor(sun.sunrise);

    final nakIndex = PanchangCalculator.nakshatraIndexFor(sun.sunrise);

    final rashiIndex = PanchangCalculator.rashiIndexFor(sun.sunrise);

    final nakshatra = PanchangCalculator.nakshatraNames[nakIndex];

    final rashi = PanchangCalculator.rashiNames[rashiIndex];

    final monthShort = const [
      '',
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
    ][widget.greg.month];

    // TODAY box only:
    // Nakshatra/Rashi -> Sunrise -> Event
    // No "আজ" / "কাল" text.
    final movingItems = <String>[
      '$nakshatra \u2022 $rashi',
      '\u2600 ${bnTime12(sun.sunrise)}',
      ...events.map((e) => '${e.icon} ${e.label}'),
    ];

    final movingText = movingItems[_infoIndex % movingItems.length];

    final staticInfo = '$nakshatra \u2022 $rashi';

    return GestureDetector(
      onTap: widget.onTap,
      child: Opacity(
        opacity: widget.dim ? 0.35 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: widget.highlightTint
                ? const Color(0xFFFFF4EE)
                : widget.isToday
                ? const Color(0xFFFFFAE8)
                : const Color(0xFFFFFEF8),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFF593187)
                  : widget.isToday
                  ? const Color(0xFFD69A24)
                  : const Color(0xFFD5CEBF),
              width: widget.isSelected || widget.isToday ? 1.5 : 0.8,
            ),
            boxShadow: widget.isToday
                ? [
                    BoxShadow(
                      color: const Color(0xFFD69A24).withValues(alpha: 0.16),
                      blurRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: ClipRect(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 3, 2, 3),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          '${widget.greg.day} $monthShort',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 6.5,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: widget.isSunday
                                ? const Color(0xFFC62828)
                                : const Color(0xFF383C46),
                          ),
                        ),
                      ),

                      const SizedBox(height: 1),

                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.bnDay,
                              style: TextStyle(
                                fontSize: 30,
                                height: 0.92,
                                fontWeight: FontWeight.w900,
                                color: numberColor,
                              ),
                            ),
                          ),
                        ),
                      ),

                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${tithi.paksha} ${tithi.name}',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 8,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF252525),
                          ),
                        ),
                      ),

                      const SizedBox(height: 2),

                      SizedBox(
                        height: 11,
                        width: double.infinity,
                        child: widget.isToday
                            ? AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                transitionBuilder: (child, animation) {
                                  final slide = Tween<Offset>(
                                    begin: const Offset(0.25, 0),
                                    end: Offset.zero,
                                  ).animate(animation);

                                  return ClipRect(
                                    child: SlideTransition(
                                      position: slide,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    ),
                                  );
                                },
                                child: Center(
                                  key: ValueKey('$movingText-$_infoIndex'),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      movingText,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontSize: 6.8,
                                        height: 1,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF3A3A3A),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    staticInfo,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 6.8,
                                      height: 1,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3A3A3A),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                // Special-day icon only.
                // Normal days stay clean.
                if (primaryEvent != null)
                  Positioned(
                    left: 3,
                    top: 3,
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: Center(child: _specialIcon(primaryEvent)),
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

class ReminderItem {
  String text;
  DateTime when;

  /// নোটিফিকেশন বাতিল/পুনরায় সেট করার জন্য স্থায়ী আইডি
  final int id;
  ReminderItem(this.text, this.when, {int? id})
    : id = id ?? DateTime.now().microsecondsSinceEpoch.remainder(0x7FFFFFFF);
}

// =====================================================================
// ভয়েস রিমাইন্ডার — বটম শীট। মাইকে বলা কথা লাইভ দেখায়, তারপর
// VoiceReminderParser দিয়ে তারিখ/সময়/টেক্সট বের করে প্রিভিউ দেখায়।
// ব্যবহারকারী "ফর্মে বসাও" চাপলেই ফলাফল ফেরত যায় — আসল সেভ existing
// _addReminder()/ReminderStore.instance.add() দিয়েই হয়, এখানে নতুন কোনো
// সেভ-লজিক নেই।
// =====================================================================

class _VoiceReminderSheet extends StatefulWidget {
  const _VoiceReminderSheet();
  @override
  State<_VoiceReminderSheet> createState() => _VoiceReminderSheetState();
}

class _VoiceReminderSheetState extends State<_VoiceReminderSheet> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _initializing = true;
  bool _listening = false;
  String _liveText = '';
  String? _error;
  VoiceReminderParseResult? _result;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final ok = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && mounted) {
            setState(() => _listening = false);
            if (_liveText.trim().isNotEmpty && _result == null) {
              _finalize(_liveText);
            }
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _listening = false;
              _error = 'ভয়েস চেনা যাচ্ছে না — আবার চেষ্টা করুন';
            });
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _available = ok;
        _initializing = false;
      });
      if (ok) _startListening();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _available = false;
        _initializing = false;
        _error = 'এই ফোনে ভয়েস ইনপুট চালু করা যায়নি';
      });
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _listening = true;
      _liveText = '';
      _result = null;
      _error = null;
    });
    void onResult(dynamic result) {
      if (!mounted) return;
      setState(() => _liveText = result.recognizedWords as String);
      if (result.finalResult == true) {
        _finalize(_liveText);
      }
    }

    try {
      // বাংলা লোকেল দিয়ে আগে চেষ্টা — না থাকলে ডিভাইসের ডিফল্ট ভাষাতেই
      await _speech.listen(
        onResult: onResult,
        localeId: 'bn_IN',
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (_) {
      try {
        await _speech.listen(
          onResult: onResult,
          listenFor: const Duration(seconds: 12),
          pauseFor: const Duration(seconds: 3),
        );
      } catch (_) {
        if (mounted) {
          setState(() {
            _listening = false;
            _error = 'ভয়েস ইনপুট শুরু করা যায়নি';
          });
        }
      }
    }
  }

  void _finalize(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _result = VoiceReminderParser.parse(text);
      _listening = false;
    });
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1C38),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mic, color: Color(0xFFFFD36E)),
              SizedBox(width: 8),
              Text(
                'ভয়েস রিমাইন্ডার',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'যেমন: "আগামীকাল সকাল ৯টায় মনে করিয়ে দাও" বা "২৫ তারিখ সন্ধ্যা '
            '৬টায় পূজার কথা মনে করিয়ে দাও"',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (_initializing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD36E)),
              ),
            )
          else if (!_available)
            Text(
              _error ??
                  'এই ফোনে ভয়েস ইনপুট পাওয়া যায়নি — টেক্সট দিয়েই রিমাইন্ডার যোগ করুন',
              style: const TextStyle(color: Colors.white70),
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _liveText.isEmpty
                    ? (_listening ? 'শুনছি… বলুন' : 'মাইক বাটনে চেপে বলুন')
                    : _liveText,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12.5,
                  ),
                ),
              ),
            Center(
              child: GestureDetector(
                onTap: _listening ? () => _speech.stop() : _startListening,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _listening
                        ? const Color(0xFFD72A3B)
                        : const Color(0xFFFFD36E),
                  ),
                  child: Icon(
                    _listening ? Icons.stop : Icons.mic,
                    color: const Color(0xFF071428),
                    size: 28,
                  ),
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD36E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFFD36E).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'বুঝেছি:',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _result!.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _result!.when == null
                          ? 'তারিখ/সময় বোঝা যায়নি — নিচে ম্যানুয়ালি বেছে নিন'
                          : '${_result!.when!.day}/${_result!.when!.month}/${_result!.when!.year}'
                                ' • ${_result!.when!.hour.toString().padLeft(2, "0")}:${_result!.when!.minute.toString().padLeft(2, "0")}'
                                '${!_result!.timeFound ? " (সময় অনুমান করা — ঠিক করে নিন)" : ""}',
                      style: TextStyle(
                        color: _result!.when == null
                            ? Colors.orangeAccent
                            : Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _result),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD36E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'এটাই ঠিক আছে — ফর্মে বসাও',
                    style: TextStyle(
                      color: Color(0xFF071428),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
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

  Future<void> _openVoiceReminder() async {
    final result = await showModalBottomSheet<VoiceReminderParseResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _VoiceReminderSheet(),
    );
    if (result == null || !mounted) return;
    setState(() {
      _textController.text = result.title;
      _pickedDateTime = result.when;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ভয়েস থেকে ফর্ম পূরণ হয়েছে — দেখে নিয়ে সেভ করুন'),
      ),
    );
  }

  void _addReminder() {
    final text = _textController.text.trim();
    if (text.isEmpty || _pickedDateTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('টেক্সট ও সময় দুটোই দিন')));
      return;
    }
    // সেভ করা হয় ফোনে, আর নির্ধারিত সময়ে নোটিফিকেশনও সেট হয়
    ReminderStore.instance.add(ReminderItem(text, _pickedDateTime!)).then((_) {
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                const SizedBox(height: 170),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openVoiceReminder,
                    icon: const Icon(
                      Icons.mic,
                      size: 17,
                      color: Color(0xFFFFD36E),
                    ),
                    label: const Text(
                      'বলে রিমাইন্ডার তৈরি করুন',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: const Color(0xFFFFD36E).withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'যেমন: একাদশী ব্রত',
                    hintStyle: const TextStyle(color: Colors.white60),
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
                    style: TextStyle(color: Colors.white70),
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
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white70,
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
                    hintStyle: const TextStyle(color: Colors.white60),
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
                    style: TextStyle(color: Colors.white70),
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
                              color: Colors.white70,
                            ),
                            onPressed: () =>
                                NotesStore.instance.removeAt(e.key).then((_) {
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
// পারিবারিক ক্যালেন্ডার — পরিবারের সদস্যদের জন্মদিন/বিবাহবার্ষিকী তালিকা
// (শুধু নিজের ফোনে সেভ থাকে, অন্য ডিভাইসের সাথে সিঙ্ক হয় না)
// =====================================================================

class FamilyMemberItem {
  String name;
  String occasion; // 'জন্মদিন' | 'বিবাহবার্ষিকী' | 'অন্যান্য'
  DateTime date;
  final int id;
  FamilyMemberItem(this.name, this.occasion, this.date, {int? id})
    : id = id ?? DateTime.now().microsecondsSinceEpoch.remainder(0x7FFFFFFF);

  /// এই বছর তারিখটা চলে গিয়ে থাকলে পরের বছরের তারিখ ফেরত দেয়
  DateTime get nextOccurrence {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(now.year, date.month, date.day);
    if (next.isBefore(today)) {
      next = DateTime(now.year + 1, date.month, date.day);
    }
    return next;
  }

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return nextOccurrence.difference(today).inDays;
  }

  int get upcomingYears => nextOccurrence.year - date.year;
}

/// পরিবারের সদস্যদের তথ্য — ফোনে সেভ থাকে
class FamilyMemberStore {
  FamilyMemberStore._();
  static final FamilyMemberStore instance = FamilyMemberStore._();
  static const _key = 'family_members';

  final List<FamilyMemberItem> items = [];

  void _sort() => items.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_key) ?? const [];
    items
      ..clear()
      ..addAll(
        raw.map((e) {
          final m = jsonDecode(e) as Map<String, dynamic>;
          return FamilyMemberItem(
            m['name'] as String,
            m['occasion'] as String,
            DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
            id: m['id'] as int,
          );
        }),
      );
    _sort();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _key,
      items
          .map(
            (f) => jsonEncode({
              'id': f.id,
              'name': f.name,
              'occasion': f.occasion,
              'date': f.date.millisecondsSinceEpoch,
            }),
          )
          .toList(),
    );
  }

  Future<void> add(FamilyMemberItem item) async {
    items.add(item);
    _sort();
    await _persist();
  }

  Future<void> remove(FamilyMemberItem item) async {
    items.remove(item);
    await _persist();
  }
}

class FamilyCalendarScreen extends StatefulWidget {
  const FamilyCalendarScreen({super.key});
  @override
  State<FamilyCalendarScreen> createState() => _FamilyCalendarScreenState();
}

class _FamilyCalendarScreenState extends State<FamilyCalendarScreen> {
  List<FamilyMemberItem> get _members => FamilyMemberStore.instance.items;
  final _nameController = TextEditingController();
  String _occasion = 'জন্মদিন';
  DateTime? _pickedDate;

  static const _occasions = ['জন্মদিন', 'বিবাহবার্ষিকী', 'অন্যান্য'];

  @override
  void initState() {
    super.initState();
    FamilyMemberStore.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (d == null) return;
    setState(() => _pickedDate = d);
  }

  void _addMember() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _pickedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('নাম ও তারিখ দুটোই দিন')));
      return;
    }
    FamilyMemberStore.instance
        .add(FamilyMemberItem(name, _occasion, _pickedDate!))
        .then((_) {
          if (mounted) setState(() {});
        });
    _nameController.clear();
    setState(() => _pickedDate = null);
  }

  void _setReminder(FamilyMemberItem m) {
    final occDate = m.nextOccurrence;
    final when = DateTime(occDate.year, occDate.month, occDate.day, 9, 0);
    ReminderStore.instance
        .add(
          ReminderItem(
            '${_emojiFor(m.occasion)} ${m.name} — ${m.occasion}',
            when,
          ),
        )
        .then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('রিমাইন্ডার সেট হয়েছে ⏰')),
            );
          }
        });
  }

  String _emojiFor(String occasion) {
    switch (occasion) {
      case 'জন্মদিন':
        return '🎂';
      case 'বিবাহবার্ষিকী':
        return '💍';
      default:
        return '📌';
    }
  }

  String _subtitleFor(FamilyMemberItem m) {
    final days = m.daysLeft;
    final whenTxt = days == 0 ? 'আজ! 🎉' : 'আর ${bnNum(days)} দিন বাকি';
    final years = m.upcomingYears;
    if (m.occasion == 'জন্মদিন' && years > 0) {
      return '$whenTxt • ${bnNum(years)} বছর পূর্ণ হবে';
    }
    if (m.occasion == 'বিবাহবার্ষিকী' && years > 0) {
      return '$whenTxt • ${bnNum(years)} তম বার্ষিকী';
    }
    return whenTxt;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '👨‍👩‍👧‍👦 পারিবারিক ক্যালেন্ডার'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                const SizedBox(height: 170),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'নাম (যেমন: মা, দাদু, দিদি)',
                    hintStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _occasions.map((o) {
                    final selected = _occasion == o;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _occasion = o),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFFFD36E)
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              o,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFF071428)
                                    : Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    _pickedDate == null
                        ? 'তারিখ বাছাই করুন'
                        : '${_pickedDate!.day}/${_pickedDate!.month}/${_pickedDate!.year}',
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
                    onPressed: _addMember,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD36E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'যোগ করুন',
                      style: TextStyle(
                        color: Color(0xFF071428),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_members.isEmpty)
                  const Text(
                    'এখনও কেউ যোগ করা হয়নি।',
                    style: TextStyle(color: Colors.white70),
                  )
                else
                  ..._members.map(
                    (m) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _emojiFor(m.occasion),
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${m.name} • ${m.occasion}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _subtitleFor(m),
                                  style: const TextStyle(
                                    color: Color(0xFFFFD36E),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_active_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                            tooltip: 'রিমাইন্ডার সেট করুন',
                            onPressed: () => _setReminder(m),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white70,
                            ),
                            onPressed: () =>
                                FamilyMemberStore.instance.remove(m).then((_) {
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
// শিশুর নামের আদ্যক্ষর — জন্ম নক্ষত্র ও পাদ অনুযায়ী ঐতিহ্যবাহী জ্যোতিষ
// পদ্ধতিতে প্রচলিত আদ্যক্ষর সুপারিশ করে (এটা "📿 নামকরণ"-এর শুভদিন
// ফিচার থেকে আলাদা — এটা কোন অক্ষর দিয়ে নাম রাখা ভালো সেটা বলে)
// =====================================================================

class BabyNamingScreen extends StatefulWidget {
  const BabyNamingScreen({super.key});
  @override
  State<BabyNamingScreen> createState() => _BabyNamingScreenState();
}

class _BabyNamingScreenState extends State<BabyNamingScreen> {
  DateTime? _birth;

  // ২৭টি নক্ষত্র × ৪টি পাদ — প্রতিটি নক্ষত্রনামের ক্রম
  // PanchangCalculator.nakshatraNames এর ক্রম অনুযায়ী
  static const List<List<String>> _namingLetters = [
    ['চু', 'চে', 'চো', 'লা'], // অশ্বিনী
    ['লি', 'লু', 'লে', 'লো'], // ভরণী
    ['অ', 'ই', 'উ', 'এ'], // কৃত্তিকা
    ['ও', 'বা', 'বি', 'বু'], // রোহিণী
    ['বে', 'বো', 'কা', 'কি'], // মৃগশিরা
    ['কু', 'ঘ', 'ঙ', 'ছ'], // আর্দ্রা
    ['কে', 'কো', 'হা', 'হি'], // পুনর্বসু
    ['হু', 'হে', 'হো', 'ড'], // পুষ্যা
    ['ডি', 'ডু', 'ডে', 'ডো'], // অশ্লেষা
    ['মা', 'মি', 'মু', 'মে'], // মঘা
    ['মো', 'টা', 'টি', 'টু'], // পূর্বফাল্গুনী
    ['টে', 'টো', 'পা', 'পি'], // উত্তরফাল্গুনী
    ['পু', 'ষ', 'ণ', 'ঠ'], // হস্তা
    ['পে', 'পো', 'রা', 'রি'], // চিত্রা
    ['রু', 'রে', 'রো', 'তা'], // স্বাতী
    ['তি', 'তু', 'তে', 'তো'], // বিশাখা
    ['না', 'নি', 'নু', 'নে'], // অনুরাধা
    ['নো', 'যা', 'যি', 'যু'], // জ্যেষ্ঠা
    ['যে', 'যো', 'ভা', 'ভি'], // মূলা
    ['ভু', 'ধা', 'ফা', 'ঢা'], // পূর্বাষাঢ়া
    ['ভে', 'ভো', 'জা', 'জি'], // উত্তরাষাঢ়া
    ['জু', 'জে', 'জো', 'ঘ'], // শ্রবণা
    ['গা', 'গি', 'গু', 'গে'], // ধনিষ্ঠা
    ['গো', 'সা', 'সি', 'সু'], // শতভিষা
    ['সে', 'সো', 'দা', 'দি'], // পূর্বভাদ্রপদ
    ['দু', 'থা', 'ঝা', 'ঞ'], // উত্তরভাদ্রপদ
    ['দে', 'দো', 'চা', 'চি'], // রেবতী
  ];

  @override
  Widget build(BuildContext context) {
    int? nakIdx;
    int? pada;
    if (_birth != null) {
      nakIdx = PanchangCalculator.nakshatraIndexFor(_birth!);
      pada = PanchangCalculator.nakshatraPadaFor(_birth!);
    }
    final letters = nakIdx != null ? _namingLetters[nakIdx] : null;
    final recommended = (letters != null && pada != null)
        ? letters[pada - 1]
        : null;

    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '🔤 শিশুর নামের আদ্যক্ষর'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                const SizedBox(height: 170),
                const Text(
                  'সন্তানের জন্ম-তারিখ ও সময় দিন — জন্ম-নক্ষত্র ও পাদ '
                  'অনুযায়ী ঐতিহ্যগতভাবে প্রচলিত নামের আদ্যক্ষর দেখানো হবে।',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                _DateTimePickerField(
                  label: 'জন্ম তারিখ ও সময় বাছাই করুন',
                  onChanged: (dt) => setState(() => _birth = dt),
                ),
                const SizedBox(height: 20),
                if (_birth != null && nakIdx != null && pada != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFD36E), Color(0xFFFFB74D)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'সুপারিশকৃত আদ্যক্ষর',
                          style: TextStyle(
                            color: Color(0xFF071428),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recommended ?? '—',
                          style: const TextStyle(
                            color: Color(0xFF071428),
                            fontWeight: FontWeight.w900,
                            fontSize: 44,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '⭐ জন্ম নক্ষত্র: ${PanchangCalculator.nakshatraNames[nakIdx!]} • পাদ ${bnNum(pada!)}',
                          style: const TextStyle(
                            color: Color(0xFF071428),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${PanchangCalculator.nakshatraNames[nakIdx!]} নক্ষত্রের ৪টি পাদের আদ্যক্ষর',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(4, (i) {
                            final isThis = (i + 1) == pada;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isThis
                                    ? const Color(0xFFFFD36E)
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                letters![i],
                                style: TextStyle(
                                  color: isThis
                                      ? const Color(0xFF071428)
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ℹ️ এটি ঐতিহ্যবাহী জ্যোতিষ-শাস্ত্র অনুযায়ী একটি সুপারিশ। '
                    'পরিবার বা পুরোহিতভেদে উচ্চারণে সামান্য পার্থক্য থাকতে '
                    'পারে — চূড়ান্ত সিদ্ধান্তের আগে পারিবারিক পুরোহিত বা '
                    'জ্যোতিষীর সাথে মিলিয়ে নেওয়াই ভালো।',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// শুভ মুহূর্ত — জমি/বাড়ি/গাড়ি কেনা, গৃহপ্রবেশ, বিবাহ, ব্যবসা শুরুর জন্য
// ব্যবহারকারীর নির্বাচিত অবস্থান (জেলা/GPS) ও তারিখ অনুযায়ী পঞ্জিকা-ভিত্তিক
// শুভ দিন ও শুভ সময় (☀️ অভিজিৎ মুহূর্ত + ⚠️ রাহুকাল) দেখায়। এই সংস্করণে
// শুধু UI ও লোকাল হিসেব — কোনো ব্যাকএন্ড কল নেই।
// =====================================================================

class _ShubhoCategory {
  final String emoji;
  final String title;
  final String key;
  const _ShubhoCategory(this.emoji, this.title, this.key);
}

class ShubhoMuhurtaScreen extends StatefulWidget {
  const ShubhoMuhurtaScreen({super.key});
  @override
  State<ShubhoMuhurtaScreen> createState() => _ShubhoMuhurtaScreenState();
}

class _ShubhoMuhurtaScreenState extends State<ShubhoMuhurtaScreen> {
  static const _categories = [
    _ShubhoCategory('💍', 'বিবাহ', 'marriage'),
    _ShubhoCategory('🏠', 'গৃহপ্রবেশ', 'griha'),
    _ShubhoCategory('🪔', 'ব্যবসা শুরু', 'byabosha'),
    _ShubhoCategory('🏞️', 'জমি কেনা', 'jomi'),
    _ShubhoCategory('🏡', 'বাড়ি কেনা', 'bari'),
    _ShubhoCategory('🚗', 'গাড়ি কেনা', 'gari'),
  ];

  String _selectedKey = 'marriage';
  DateTime _fromDate = DateTime.now();

  // "কত দিনের মধ্যে চাই" — ডেডলাইন ফিল্টার। এটা শুধু UI-স্তরের একটা
  // নতুন প্যারামিটার, existing findAuspiciousMuhurtas/findAuspiciousDates
  // ফাংশনে আগে থেকেই থাকা maxDays প্যারামিটারে পাঠানো হয় — নিজে কোনো
  // নতুন হিসাব/লজিক যোগ করা হয়নি, তাই শুভ মুহূর্তের calculation অপরিবর্তিত।
  static const List<int> _deadlineOptions = [7, 15, 30, 60];
  int _deadlineDays = 30;

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final base = _fromDate.isBefore(now) ? now : _fromDate;
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (d == null) return;
    setState(() => _fromDate = d);
  }

  void _pickLocation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LocationPickerSheet(
        onSelected: (d) async {
          await AppSettings.instance.saveDistrict(d);
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _setReminder(_ShubhoCategory cat, Map<String, dynamic> m) {
    final start = m['abhijitApplicable'] == true
        ? m['abhijitStart'] as DateTime
        : m['date'] as DateTime;
    ReminderStore.instance
        .add(ReminderItem('${cat.emoji} ${cat.title} — শুভ মুহূর্ত', start))
        .then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('রিমাইন্ডার সেট হয়েছে ⏰')),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final cat = _categories.firstWhere((c) => c.key == _selectedKey);
    final results = BengaliCalendarData.findAuspiciousMuhurtas(
      _selectedKey,
      count: 30,
      maxDays: _deadlineDays,
      from: _fromDate,
    );

    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '🕉️ শুভ মুহূর্ত'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                const SizedBox(height: 170),
                const Text(
                  'জমি/বাড়ি/গাড়ি কেনা, গৃহপ্রবেশ, বিয়ে বা ব্যবসা শুরুর মতো '
                  'গুরুত্বপূর্ণ কাজের জন্য আপনার অবস্থান অনুযায়ী পরবর্তী শুভ '
                  'দিন ও সময় দেখুন।',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickLocation,
                        icon: const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xFFFFD36E),
                        ),
                        label: Text(
                          AppLocation.district,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFromDate,
                        icon: const Icon(
                          Icons.calendar_today,
                          size: 15,
                          color: Color(0xFFFFD36E),
                        ),
                        label: Text(
                          '${_fromDate.day}/${_fromDate.month}/${_fromDate.year}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((c) {
                    final selected = c.key == _selectedKey;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedKey = c.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFFFD36E)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFFFD36E)
                                : Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          '${c.emoji} ${c.title}',
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF071428)
                                : Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const Text(
                  'কত দিনের মধ্যে চাই?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _deadlineOptions.map((d) {
                    final selected = d == _deadlineDays;
                    return GestureDetector(
                      onTap: () => setState(() => _deadlineDays = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF7DC4FF)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF7DC4FF)
                                : Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          '${bnNum(d)} দিন',
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF071428)
                                : Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
                Text(
                  '${cat.emoji} ${cat.title}-এর পরবর্তী ${bnNum(_deadlineDays)} '
                  'দিনের মধ্যে শুভ দিনগুলো',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                if (results.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'পরবর্তী ${bnNum(_deadlineDays)} দিনের মধ্যে এই কাজের জন্য '
                      'কোনো শুভ দিন পাওয়া যায়নি — বড় সময়সীমা বেছে দেখুন।',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  ...results.map((m) {
                    final date = m['date'] as DateTime;
                    final tithi = m['tithi'] as TithiInfo;
                    final info = BengaliDateUtil.monthInfoFor(date);
                    final bDay = date.difference(info.start).inDays + 1;
                    final abhijitOk = m['abhijitApplicable'] == true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(
                            0xFFFFD36E,
                          ).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${date.day}/${date.month}/${date.year} • '
                                '${PanchangCalculator.weekdayName(date)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${bnNum(bDay)} ${info.name} ${bnNum(info.year)}',
                                style: const TextStyle(
                                  color: Color(0xFFFFD36E),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${tithi.paksha} পক্ষ • ${tithi.name} • '
                            '${m['nakshatra']}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const Divider(color: Colors.white12, height: 22),
                          if (abhijitOk)
                            Row(
                              children: [
                                const Text(
                                  '☀️ ',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Expanded(
                                  child: Text(
                                    'অভিজিৎ মুহূর্ত: '
                                    '${bnTime12(m['abhijitStart'] as DateTime)} – '
                                    '${bnTime12(m['abhijitEnd'] as DateTime)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            const Text(
                              '☀️ আজ বুধবার — ঐতিহ্য অনুযায়ী অভিজিৎ মুহূর্ত '
                              'ধরা হয় না',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                              Expanded(
                                child: Text(
                                  'রাহুকাল (এড়িয়ে চলুন): '
                                  '${bnTime12(m['rahuStart'] as DateTime)} – '
                                  '${bnTime12(m['rahuEnd'] as DateTime)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _setReminder(cat, m),
                              icon: const Icon(
                                Icons.notifications_active_outlined,
                                size: 16,
                                color: Color(0xFFFFD36E),
                              ),
                              label: const Text(
                                'রিমাইন্ডার সেট করুন',
                                style: TextStyle(color: Color(0xFFFFD36E)),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFFFD36E),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                const Text(
                  'ℹ️ এটি তিথি/নক্ষত্র-ভিত্তিক সরলীকৃত হিসেব — প্রকৃত '
                  'লগ্ন-বিচারের বিকল্প নয়। বাড়ি/জমি/গাড়ি রেজিস্ট্রি বা '
                  'বিয়ের মতো বড় সিদ্ধান্তের আগে একজন অভিজ্ঞ জ্যোতিষীর '
                  'সাথে পাকা মুহূর্ত যাচাই করে নেওয়াই ভালো।',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPickerSheet extends StatelessWidget {
  final ValueChanged<String> onSelected;
  const _LocationPickerSheet({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final districts = AppLocation.coordinates.keys.toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0B1B35),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'জেলা বাছাই করুন',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: districts.length,
                  itemBuilder: (context, i) {
                    final d = districts[i];
                    final isSelected = d == AppLocation.district;
                    return ListTile(
                      title: Text(
                        d,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFFFD36E)
                              : Colors.white,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFFFFD36E),
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        onSelected(d);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =====================================================================
// উৎসব পোস্টার মেকার — যেকোনো উৎসব/বিশেষ দিনের জন্য শেয়ারযোগ্য সুন্দর
// পোস্টার বানায় (তারিখ + উৎসবের নাম + ব্যবহারকারীর নাম), ফোনের নেটিভ
// শেয়ার শীট দিয়ে WhatsApp/Facebook/অন্য যেকোনো অ্যাপে পাঠানো যায়। ছবিটা
// সম্পূর্ণ লোকালি (অ্যাপের ভেতরেই RepaintBoundary দিয়ে) তৈরি হয় — কোনো
// ব্যাকএন্ড/ইন্টারনেট লাগে না।
// =====================================================================

// =====================================================================
// পঞ্চাঙ্গ শেয়ার কার্ড — আজকের তিথি/নক্ষত্র/রাশি/সূর্যোদয়-অস্ত একটা
// সুন্দর ডিজাইনের ছবি-কার্ড হিসেবে এক-ট্যাপে শেয়ার করা যায়। কৌশলটা ঠিক
// উৎসব পোস্টার মেকারের মতোই — RepaintBoundary দিয়ে লোকালি ছবি বানিয়ে
// Share.shareXFiles দিয়ে পাঠানো হয়, কোনো ব্যাকএন্ড/ইন্টারনেট লাগে না।
// Panchang calculation-এর কোনো ফাংশন এখানে বদলানো হয়নি, শুধু read করা
// হয়েছে।
// =====================================================================

class PanchangShareCardScreen extends StatefulWidget {
  const PanchangShareCardScreen({super.key});
  @override
  State<PanchangShareCardScreen> createState() =>
      _PanchangShareCardScreenState();
}

class _PanchangShareCardScreenState extends State<PanchangShareCardScreen> {
  final _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final shareText = AppLinks.playStore.isEmpty
          ? 'আজকের পঞ্চাঙ্গ — বাংলা পঞ্জিকা'
          : 'আজকের পঞ্চাঙ্গ — বাংলা পঞ্জিকা\n\n📲 অ্যাপ ডাউনলোড করুন:\n${AppLinks.playStore}';
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: 'ajker_panchang.png',
            mimeType: 'image/png',
          ),
        ],
        text: shareText,
        subject: 'আজকের পঞ্চাঙ্গ',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('কার্ড শেয়ার করা যায়নি — আবার চেষ্টা করুন'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Widget _cardRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12.5),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final info = BengaliDateUtil.monthInfoFor(now);
    final bengaliDay = now.difference(info.start).inDays + 1;
    final tithi = PanchangCalculator.tithiFor(now);
    final weekday = PanchangCalculator.weekdayName(now);
    final nakIdx = PanchangCalculator.nakshatraIndexFor(now);
    final rashiIdx = PanchangCalculator.rashiIndexFor(now);
    final sun = PanchangCalculator.sunTimes(now);
    final rahu = PanchangCalculator.rahuKalam(now);

    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '📤 পঞ্চাঙ্গ শেয়ার কার্ড'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                const SizedBox(height: 170),
                RepaintBoundary(
                  key: _cardKey,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0B1C38),
                          Color(0xFF183F69),
                          Color(0xFF08172F),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFFD36E).withValues(alpha: 0.5),
                        width: 1.4,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '🪷 বাংলা পঞ্জিকা',
                              style: TextStyle(
                                color: Color(0xFFFFD36E),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              weekday,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${bnNum(bengaliDay)} ${info.name} ${bnNum(info.year)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${bnNum(now.day)} ${gregMonthBn(now.month)} ${bnNum(now.year)}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _cardRow(
                                'তিথি',
                                '${tithi.paksha} পক্ষ • ${tithi.name}',
                              ),
                              _cardRow(
                                'নক্ষত্র',
                                PanchangCalculator.nakshatraNames[nakIdx],
                              ),
                              _cardRow(
                                'চন্দ্র রাশি',
                                PanchangCalculator.rashiNames[rashiIdx],
                              ),
                              _cardRow('সূর্যোদয়', bnTime12(sun.sunrise)),
                              _cardRow('সূর্যাস্ত', bnTime12(sun.sunset)),
                              _cardRow(
                                'রাহুকাল',
                                '${bnTime12(rahu['start']!)}–${bnTime12(rahu['end']!)}',
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Center(
                          child: Text(
                            '🌙 বাংলা পঞ্জিকা অ্যাপ 🌙',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _sharing ? null : _share,
                  icon: _sharing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.share_rounded),
                  label: Text(_sharing ? 'তৈরি হচ্ছে...' : 'শেয়ার করুন'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD72A3B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

class _PosterTheme {
  final String name;
  final List<Color> colors;
  final Color textColor;
  const _PosterTheme(this.name, this.colors, this.textColor);
}

class FestivalPosterScreen extends StatefulWidget {
  const FestivalPosterScreen({super.key});
  @override
  State<FestivalPosterScreen> createState() => _FestivalPosterScreenState();
}

class _FestivalPosterScreenState extends State<FestivalPosterScreen> {
  final _posterKey = GlobalKey();
  final _festivalController = TextEditingController();
  final _nameController = TextEditingController();
  DateTime _date = DateTime.now();
  int _themeIndex = 0;
  bool _sharing = false;

  static const _themes = [
    _PosterTheme('সোনালি উৎসব', [
      Color(0xFF7A2E2E),
      Color(0xFFB8860B),
      Color(0xFFFFD36E),
    ], Colors.white),
    _PosterTheme('দুর্গা লাল', [
      Color(0xFF7A0C2E),
      Color(0xFFB3123D),
      Color(0xFFFF6B81),
    ], Colors.white),
    _PosterTheme('রঙিন উৎসব', [
      Color(0xFF3A1C71),
      Color(0xFFD76D77),
      Color(0xFFFFAF7B),
    ], Colors.white),
    _PosterTheme('কসমিক নীল', [
      Color(0xFF0B1C38),
      Color(0xFF183F69),
      Color(0xFFFFD36E),
    ], Colors.white),
    _PosterTheme('সবুজ প্রকৃতি', [
      Color(0xFF134E1E),
      Color(0xFF2E7D32),
      Color(0xFFC5E1A5),
    ], Colors.white),
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = AppSettings.instance.profileName;
  }

  void _pickFestival(String title) {
    setState(() => _festivalController.text = title);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (d == null) return;
    setState(() => _date = d);
  }

  Future<void> _share() async {
    final festival = _festivalController.text.trim();
    if (festival.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('উৎসবের নাম দিন')));
      return;
    }
    setState(() => _sharing = true);
    try {
      final boundary =
          _posterKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final name = _nameController.text.trim();
      final greeting = name.isEmpty
          ? '🪔 শুভ $festival'
          : '🪔 শুভ $festival — শুভেচ্ছান্তে, $name';
      // Play Store-এ পাবলিশ হওয়ার পর AppLinks.playStore-এ লিংক বসালে
      // শেয়ার-করা টেক্সটের সাথে অ্যাপ ডাউনলোডের লিংকও যোগ হয়ে যাবে
      final shareText = AppLinks.playStore.isEmpty
          ? greeting
          : '$greeting\n\n📲 বাংলা পঞ্জিকা অ্যাপ ডাউনলোড করুন:\n${AppLinks.playStore}';
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: 'utsob_shuveccha.png',
            mimeType: 'image/png',
          ),
        ],
        text: shareText,
        subject: 'শুভ $festival',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('পোস্টার তৈরি করা যায়নি — আবার চেষ্টা করুন'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  void dispose() {
    _festivalController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themes[_themeIndex];
    final info = BengaliDateUtil.monthInfoFor(_date);
    final bDay = _date.difference(info.start).inDays + 1;
    final festival = _festivalController.text.trim();

    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(title: '🎉 উৎসব পোস্টার মেকার'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                const SizedBox(height: 170),
                const Text(
                  'উৎসবের নাম, তারিখ ও আপনার নাম দিয়ে একটা সুন্দর শেয়ারযোগ্য '
                  'পোস্টার বানান — WhatsApp/Facebook-এ সরাসরি পাঠাতে পারবেন।',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: BengaliCalendarData.upcomingFestivals(count: 8)
                        .map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              avatar: Text(f['icon'] ?? '🎉'),
                              label: Text(f['title'] ?? ''),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                              labelStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              onPressed: () => _pickFestival(f['title'] ?? ''),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _festivalController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'উৎসবের নাম (যেমন: শুভ বিজয়া দশমী)',
                    hintStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'আপনার নাম (ঐচ্ছিক)',
                    hintStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    '${bnNum(_date.day)} ${gregMonthBn(_date.month)} '
                    '${bnNum(_date.year)} • ${bnNum(bDay)} ${info.name}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'পোস্টারের থিম',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(_themes.length, (i) {
                    final t = _themes[i];
                    final selected = i == _themeIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _themeIndex = i),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: t.colors),
                            border: Border.all(
                              color: selected ? Colors.white : Colors.white24,
                              width: selected ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Center(
                  child: RepaintBoundary(
                    key: _posterKey,
                    child: _PosterCard(
                      theme: theme,
                      festival: festival.isEmpty ? 'উৎসবের নাম' : festival,
                      name: _nameController.text.trim(),
                      dateLabel:
                          '${bnNum(bDay)} ${info.name} ${bnNum(info.year)}',
                      gregLabel: '${_date.day}/${_date.month}/${_date.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sharing ? null : _share,
                    icon: _sharing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF071428),
                            ),
                          )
                        : const Icon(Icons.share, color: Color(0xFF071428)),
                    label: Text(
                      _sharing
                          ? 'পোস্টার তৈরি হচ্ছে...'
                          : '📤 শেয়ার করুন (WhatsApp/Facebook)',
                      style: const TextStyle(
                        color: Color(0xFF071428),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD36E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ℹ️ শেয়ার বাটনে চাপলে ফোনের শেয়ার তালিকা খুলবে — সেখান '
                  'থেকে WhatsApp, Facebook বা অন্য যেকোনো অ্যাপ বেছে নিতে '
                  'পারবেন।',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  final _PosterTheme theme;
  final String festival;
  final String name;
  final String dateLabel;
  final String gregLabel;
  const _PosterCard({
    required this.theme,
    required this.festival,
    required this.name,
    required this.dateLabel,
    required this.gregLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.colors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✨ 🪔 ✨', style: TextStyle(fontSize: 26)),
          const SizedBox(height: 10),
          Text(
            'শুভ',
            style: TextStyle(
              color: theme.textColor.withValues(alpha: 0.85),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            festival,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: theme.textColor.withValues(alpha: 0.3)),
          const SizedBox(height: 14),
          Text(
            '$dateLabel  •  $gregLabel',
            style: TextStyle(
              color: theme.textColor.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'শুভেচ্ছান্তে',
              style: TextStyle(
                color: theme.textColor.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            '🪷 বাংলা পঞ্জিকা',
            style: TextStyle(
              color: theme.textColor.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          // Play Store-এ পাবলিশ হওয়ার পর AppLinks.playStore-এ লিংক বসালে
          // পোস্টারের নিচে এই ডাউনলোড-ব্যাজটা এমনিতেই দেখা যাবে; খালি
          // থাকা অবস্থায় (এখনো পাবলিশ হয়নি) এটা লুকানো থাকে
          if (AppLinks.playStore.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '📲 Play Store-এ ডাউনলোড করুন',
                style: TextStyle(
                  color: theme.textColor.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
  late bool _eveningLamp = AppSettings.instance.eveningLampReminder;

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
                const SizedBox(height: 4),
                const Text(
                  'অটো রিমাইন্ডার',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _switchTile(
                  '🪔 সন্ধ্যা প্রদীপ (প্রতিদিন real সূর্যাস্তে)',
                  _eveningLamp,
                  (v) => setState(() => _eveningLamp = v),
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
                      await AppSettings.instance.saveEveningLampReminder(
                        _eveningLamp,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('সেটিংস সেভ হয়েছে')),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
// প্রিমিয়াম পেজে দেখানো "টপ ফিচার" তালিকা — প্রতিটাতে চাপলেই সরাসরি সেই
// ফিচার খুলে যায় (ট্রায়াল/প্রিমিয়াম না থাকলে _PremiumGate লক দেখাবে,
// আলাদা করে সাইড মেনুতে গিয়ে খুঁজতে হবে না)। বিজ্ঞাপনমুক্ত অভিজ্ঞতার
// কোনো নিজস্ব স্ক্রিন নেই বলে screenBuilder নেই — তাই এটা ট্যাপযোগ্য নয়।
// =====================================================================

class _PremiumFeature {
  final String emoji;
  final String title;
  final Widget Function()? screenBuilder;
  const _PremiumFeature(this.emoji, this.title, [this.screenBuilder]);
}

final List<_PremiumFeature> _premiumFeatures = [
  _PremiumFeature('🪐', 'চন্দ্র কুষ্ঠি চার্ট', () => const KundliScreen()),
  _PremiumFeature('💞', 'কুষ্ঠি মিলন', () => const KundliMilanScreen()),
  _PremiumFeature('📄', 'পঞ্জিকা PDF এক্সপোর্ট', () => const PdfExportScreen()),
  _PremiumFeature('☁️', 'ক্লাউড ব্যাকআপ', () => const CloudBackupScreen()),
  _PremiumFeature(
    '🔮',
    'জ্যোতিষী পরামর্শ বুকিং',
    () => const AstrologerBookingScreen(),
  ),
  const _PremiumFeature('🚫', 'বিজ্ঞাপনমুক্ত অভিজ্ঞতা'),
];

// =====================================================================
// প্রিমিয়াম পেজের একদম উপরে দেখানো কার্ড — নাম, জন্ম তারিখ, ঠিকানা,
// সদস্য আইডি ও স্ট্যাটাস ব্যাজ (ফ্রি ট্রায়াল/সক্রিয় প্ল্যান)। পাশের ✏️
// আইকনে চাপলে এখানেই তথ্য এডিট করা যায় — আলাদা প্রোফাইল পেজে যেতে হয় না।
// =====================================================================

class _MemberDetailsCard extends StatefulWidget {
  // প্রিমিয়াম না থাকলে (ওয়েবেও না) এই বক্সের ভেতরেই মাসিক/বার্ষিক
  // প্ল্যান কেনার বাটন দেখানো হয় — আলাদা করে নিচে প্ল্যান কার্ড রাখা হয়নি
  final bool showPlans;
  final bool processing;
  final String? selectedPlan;
  final ValueChanged<PremiumPlan> onBuyPlan;
  const _MemberDetailsCard({
    required this.showPlans,
    required this.processing,
    required this.selectedPlan,
    required this.onBuyPlan,
  });
  @override
  State<_MemberDetailsCard> createState() => _MemberDetailsCardState();
}

class _MemberDetailsCardState extends State<_MemberDetailsCard> {
  bool _editing = false;
  late final _nameController = TextEditingController(
    text: AppSettings.instance.profileName,
  );
  late final _addressController = TextEditingController(
    text: AppSettings.instance.profileAddress,
  );
  DateTime? _dob = AppSettings.instance.profileDob;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await AppSettings.instance.saveProfile(
      name: _nameController.text.trim(),
      city: AppSettings.instance.profileCity,
      dob: _dob,
      address: _addressController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF08172F).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD36E).withValues(alpha: 0.25),
        ),
      ),
      child: _editing ? _buildEditMode() : _buildViewMode(s),
    );
  }

  Widget _buildViewMode(AppSettings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'সদস্য আইডি: ${s.memberId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:
                    (s.isPremiumActive
                            ? const Color(0xFF1D6E3A)
                            : const Color(0xFF6E5A1D))
                        .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.isPremiumActive ? 'সক্রিয় প্ল্যান' : 'ফ্রি ট্রায়াল',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit, color: Color(0xFFFFD36E), size: 18),
              tooltip: 'এডিট করুন',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'নাম: ${s.profileName.isEmpty ? '—' : s.profileName}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 3),
        Text(
          'জন্ম তারিখ: ${s.profileDob == null ? '—' : '${s.profileDob!.day}/${s.profileDob!.month}/${s.profileDob!.year}'}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 3),
        Text(
          'ঠিকানা: ${s.profileAddress.isEmpty ? '—' : s.profileAddress}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        if (widget.showPlans) ...[
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 14),
          const Text(
            'প্ল্যান বেছে নিন',
            style: TextStyle(
              color: Color(0xFFFFD36E),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          ...premiumPlans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plan.priceLabel,
                          style: const TextStyle(
                            color: Color(0xFFFFD36E),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: widget.processing
                        ? null
                        : () => widget.onBuyPlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD36E),
                    ),
                    child: Text(
                      widget.processing && widget.selectedPlan == plan.id
                          ? '...'
                          : 'কিনুন',
                      style: const TextStyle(
                        color: Color(0xFF071428),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!PaymentService.instance.isConfigured)
            const Text(
              'Backend এখনো সেট করা হয়নি — main.dart এর '
              'PaymentService.baseUrl এ Laravel সার্ভারের URL '
              'বসালে পেমেন্ট চালু হবে।',
              style: TextStyle(color: Colors.white60, fontSize: 11.5),
            ),
        ],
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'তথ্য এডিট করুন',
          style: TextStyle(
            color: Color(0xFFFFD36E),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'নাম',
            hintStyle: const TextStyle(color: Colors.white60),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _DateTimePickerField(
          label: _dob == null
              ? 'জন্ম তারিখ ও সময় বেছে নিন'
              : '${_dob!.day}/${_dob!.month}/${_dob!.year} — ${TimeOfDay.fromDateTime(_dob!).format(context)}',
          onChanged: (dt) => setState(() => _dob = dt),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _addressController,
          maxLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'ঠিকানা',
            hintStyle: const TextStyle(color: Colors.white60),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _editing = false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white60),
                ),
                child: const Text(
                  'বাতিল',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD36E),
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
      ],
    );
  }
}

// =====================================================================
// প্রিমিয়াম সাবস্ক্রিপশন — Razorpay checkout (শুধু মোবাইল app এ, ওয়েবে
// razorpay_flutter কাজ করে না বলে সেখানে সংগ্রহের বার্তা দেখানো হয়)
// =====================================================================

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});
  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  Razorpay? _razorpay;
  String? _selectedPlan;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay()
        ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
        ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError)
        ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    }
    // অ্যাপ খোলার সাথে সাথেই backend থেকে সত্যিকারের প্রিমিয়াম স্ট্যাটাস
    // যাচাই করে নেয় (মেয়াদ শেষ হয়ে থাকলে এখানেই ধরা পড়বে)
    PaymentService.instance.refreshStatus();
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  Future<void> _startPayment(PremiumPlan plan) async {
    setState(() {
      _selectedPlan = plan.id;
      _processing = true;
    });
    try {
      final order = await PaymentService.instance.createOrder(plan.id);
      _razorpay?.open({
        'key': order['key'],
        'amount': order['amount'],
        'currency': order['currency'],
        'order_id': order['order_id'],
        'name': 'বাংলা পঞ্জিকা',
        'description': order['plan_label'],
        'prefill': {'contact': '', 'email': ''},
        'theme': {'color': '#FFD36E'},
      });
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final expiresAt = await PaymentService.instance.verify(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );
      await AppSettings.instance.activatePremium(expiresAt);
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 প্রিমিয়াম সক্রিয় হয়েছে!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'যাচাই ব্যর্থ: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _processing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('পেমেন্ট ব্যর্থ হয়েছে: ${response.message ?? ''}'),
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final s = AppSettings.instance;
        final isPremium = s.isPremiumActive;
        return CosmicBackground(
          child: Column(
            children: [
              const _ScreenHeader(title: '✨ প্রিমিয়াম'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ট্রায়াল/প্রিমিয়াম যেটাই হোক না কেন, আইডি জেনারেট হয়ে
                    // গেলেই এই কার্ডে নাম/জন্ম তারিখ/ঠিকানা/আইডি + এডিট
                    // অপশন সবসময় সবার উপরে দেখানো হয়
                    if (s.memberId.isNotEmpty) ...[
                      _MemberDetailsCard(
                        showPlans: !isPremium && !kIsWeb,
                        processing: _processing,
                        selectedPlan: _selectedPlan,
                        onBuyPlan: _startPayment,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (isPremium)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFFD36E,
                          ).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(
                              0xFFFFD36E,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🎉 আপনি প্রিমিয়াম সদস্য',
                              style: TextStyle(
                                color: Color(0xFFFFD36E),
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            if (AppSettings.instance.premiumExpiry != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'মেয়াদ শেষ: ${AppSettings.instance.premiumExpiry!.day}/${AppSettings.instance.premiumExpiry!.month}/${AppSettings.instance.premiumExpiry!.year}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ],
                        ),
                      )
                    else if (kIsWeb)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'প্রিমিয়াম কেনার সুবিধা এখন শুধু মোবাইল অ্যাপে '
                          'পাওয়া যায় — Android/iOS অ্যাপ থেকে চেষ্টা করুন।',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    else if (!s.trialActivated) ...[
                      const _TrialSignupForm(),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color:
                              (s.inTrialPeriod
                                      ? const Color(0xFF1D6E3A)
                                      : const Color(0xFF6E1D1D))
                                  .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          s.inTrialPeriod
                              ? '🎁 ফ্রি ট্রায়াল চলছে — আর ${bnNum(s.trialDaysLeft)} দিন সব ফিচার বিনামূল্যে ব্যবহার করতে পারবেন।'
                              : (s.trialActivated
                                    ? '🔒 আপনার ৩০ দিনের ফ্রি ট্রায়াল শেষ — কুষ্ঠি চার্ট, PDF এক্সপোর্ট, ক্লাউড ব্যাকআপ ও জ্যোতিষী বুকিং চালিয়ে যেতে একটা প্ল্যান কিনুন।'
                                    : '🎁 কুষ্ঠি চার্ট, PDF এক্সপোর্ট, ক্লাউড ব্যাকআপ বা জ্যোতিষী বুকিং — যেকোনো একটা খুললেই ৩০ দিনের ফ্রি ট্রায়াল শুরু করার ফর্ম আসবে।'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const Text(
                        '✨ প্রিমিয়ামে যা পাবেন — চাপলেই খুলবে',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._premiumFeatures.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: f.screenBuilder == null
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => _PremiumGate(
                                        featureTitle: f.title,
                                        child: f.screenBuilder!(),
                                      ),
                                    ),
                                  ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    f.emoji,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      f.title,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  if (f.screenBuilder != null)
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white60,
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
  late final _addressController = TextEditingController(
    text: AppSettings.instance.profileAddress,
  );
  late DateTime? _dob = AppSettings.instance.profileDob;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1930),
      lastDate: now,
    );
    if (d == null) return;
    setState(() => _dob = d);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final s = AppSettings.instance;
        return CosmicBackground(
          child: Column(
            children: [
              const _ScreenHeader(title: '👤 প্রোফাইল'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ------- সদস্যপদ স্ট্যাটাস (ফ্রি ট্রায়াল / প্রিমিয়াম) -------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF08172F).withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(
                            0xFFFFD36E,
                          ).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.isPremiumActive
                                ? '✨ প্রিমিয়াম সদস্য'
                                : (s.inTrialPeriod
                                      ? '🎁 ফ্রি ট্রায়াল চলছে'
                                      : (s.trialActivated
                                            ? '🔒 ফ্রি ট্রায়াল শেষ'
                                            : '🎁 ফ্রি ট্রায়াল এখনো শুরু হয়নি')),
                            style: const TextStyle(
                              color: Color(0xFFFFD36E),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (s.memberId.isNotEmpty) ...[
                            Row(
                              children: [
                                Text(
                                  'সদস্য আইডি: ${s.memberId}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (s.isPremiumActive
                                                ? const Color(0xFF1D6E3A)
                                                : const Color(0xFF6E5A1D))
                                            .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    s.isPremiumActive
                                        ? 'সক্রিয় প্ল্যান'
                                        : 'ফ্রি ট্রায়াল',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (s.isPremiumActive) ...[
                            if (s.premiumExpiry != null)
                              Text(
                                'মেয়াদ শেষ: ${s.premiumExpiry!.day}/${s.premiumExpiry!.month}/${s.premiumExpiry!.year}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
                          ] else if (s.inTrialPeriod)
                            Text(
                              'আর ${bnNum(s.trialDaysLeft)} দিন সব ফিচার বিনামূল্যে ব্যবহার করতে পারবেন।',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            )
                          else if (s.trialActivated)
                            const Text(
                              'কুষ্ঠি চার্ট, PDF এক্সপোর্ট, ক্লাউড ব্যাকআপ ও জ্যোতিষী বুকিং এখন প্রিমিয়াম প্ল্যানের সাথে পাওয়া যাবে।',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            )
                          else
                            const Text(
                              'কুষ্ঠি চার্ট, PDF এক্সপোর্ট, ক্লাউড ব্যাকআপ বা জ্যোতিষী বুকিং — যেকোনো একটা খুললেই নাম/জন্ম তারিখ/ঠিকানা দিয়ে ৩০ দিনের ফ্রি ট্রায়াল শুরু করতে পারবেন।',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            ),
                          if (!s.isPremiumActive) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PremiumScreen(),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFFFD36E),
                                  ),
                                ),
                                child: const Text(
                                  'প্রিমিয়াম প্ল্যান দেখুন',
                                  style: TextStyle(color: Color(0xFFFFD36E)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
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
                        hintStyle: const TextStyle(color: Colors.white60),
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
                        hintStyle: const TextStyle(color: Colors.white60),
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
                      'জন্ম তারিখ',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickDob,
                        icon: const Icon(Icons.cake, color: Color(0xFFFFD36E)),
                        label: Text(
                          _dob == null
                              ? 'জন্ম তারিখ বেছে নিন'
                              : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFD36E)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'ঠিকানা',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'আপনার ঠিকানা',
                        hintStyle: const TextStyle(color: Colors.white60),
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
                            dob: _dob,
                            address: _addressController.text.trim(),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('প্রোফাইল সেভ হয়েছে'),
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
      },
    );
  }
}
