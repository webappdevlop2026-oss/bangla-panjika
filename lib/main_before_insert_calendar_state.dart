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
// Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¸ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦â€šÃ Â¦Â°Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â£ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦ÂªÃ Â¦â€ºÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¦ Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡, Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â¦Â®Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾
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
  // Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§â€¡ "Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â® Ã Â¦â€¡Ã Â¦Â¨Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â²" Ã Â¦Â®Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ "Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨"
  // Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿-Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â«Ã Â¦Â°Ã Â§ÂÃ Â¦Â® (Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®/Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“-Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾) Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â¦Â£ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€¡
  // Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦â€“Ã Â§ÂÃ Â¦Â²Ã Â¦Â²Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¨Ã Â¦Â¾
  static const _kFirstInstall = 'first_install_ts';
  static const _kDob = 'profile_dob';
  static const _kMemberId = 'member_id';
  static const _kAddress = 'profile_address';

  // Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â«Ã Â¦Â°Ã Â§ÂÃ Â¦Â® Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â¦Â£Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â§Â©Ã Â§Â¦ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€”Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦â€ Ã Â¦â€ºÃ Â§â€¡ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾
  // Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â¦Â°Ã Â§ÂÃ Â¦â€¢ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡
  static const int trialDays = 30;

  SharedPreferences? _prefs;

  String lang = 'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾';
  bool weather = true;
  bool skyAnim = true;
  bool notifications = true;
  String profileName = '';
  String profileCity = '';
  String profileAddress = '';
  // Ã Â¦â€¦Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ real Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° (Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¦Ã Â§â‚¬Ã Â¦Âª Ã Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â§â‚¬
  // Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â°) Ã Â¦Â¸Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€¦Ã Â¦Å¸Ã Â§â€¹ Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â²Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡
  // Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Â¡ Ã Â¦ËœÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
  bool eveningLampReminder = false;
  // Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â¾/Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾/Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â® Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ "Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨" Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ true Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ Ã¢â‚¬â€
  // Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª/Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€šÃ Â¦â€¢ Ã Â¦â€“Ã Â§ÂÃ Â¦Â²Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ onboarding Ã Â¦â€ Ã Â¦Â° Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾,
  // Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â® Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
  bool setupComplete = false;

  // Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¤Ã Â§Ë†Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦Â²Ã Â¦â€”Ã Â¦â€¡Ã Â¦Â¨
  // Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§â€¡Ã Â¦Â® Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¶Ã Â¦Â¨ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¡ backend-Ã Â¦Â
  // Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
  String deviceId = '';
  bool isPremium = false;
  DateTime? premiumExpiry;
  DateTime? firstInstallDate;
  DateTime? profileDob;
  // Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿-Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â«Ã Â¦Â°Ã Â§ÂÃ Â¦Â® Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â¦Â£ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ (Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®+Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“/Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼+Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾) Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²
  // Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦Â­ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨ "BP-2026-A4F9K2")
  // Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¡Ã Â¦â€°Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾, Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¤Ã Â§Ë†Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡
  // Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¸ "Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²" Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ "Ã Â¦Â¸Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼
  // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨"-Ã Â¦Â Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
  String memberId = '';

  bool get isBangla => lang == 'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾';

  /// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¸Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¡ Ã Â¦Â¸Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â isPremium true Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¨Ã Â¦Â¾,
  /// Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¦ (premiumExpiry) Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿-Ã Â¦â€¡ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ false Ã Â¦Â§Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼
  /// (Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å¸Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â¦Â­Ã Â§ÂÃ Â¦Â² Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾)
  bool get isPremiumActive =>
      isPremium &&
      (premiumExpiry == null || premiumExpiry!.isAfter(DateTime.now()));

  /// Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿-Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â«Ã Â¦Â°Ã Â§ÂÃ Â¦Â® (Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®/Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“-Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾) Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â¦Â£ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²
  /// Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦Â­ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã Â§Â©Ã Â§Â¦ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€”Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â¾Ã Â¦â€œ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾
  bool get trialActivated => firstInstallDate != null;

  /// Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¤ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ (Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦Â­Ã Â¦â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â§Â©Ã Â§Â¦ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨
  /// Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ "Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦Â¤Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¨" Ã Â¦Â¬Ã Â§â€¹Ã Â¦ÂÃ Â¦Â¾Ã Â¦Â¤Ã Â§â€¡, Ã Â§Â¦ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·)
  int get trialDaysLeft {
    if (firstInstallDate == null) return trialDays;
    final passed = DateTime.now().difference(firstInstallDate!).inDays;
    final left = trialDays - passed;
    return left < 0 ? 0 : left;
  }

  bool get inTrialPeriod => trialActivated && trialDaysLeft > 0;

  /// "Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â®-Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¸Ã Â¦Â¿Ã Â¦Â­" Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ (Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸, PDF Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸,
  /// Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª, Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š) Ã Â¦â€“Ã Â§â€¹Ã Â¦Â²Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â¶Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤ Ã¢â‚¬â€ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿
  /// Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Å¡Ã Â¦Â²Ã Â¦â€ºÃ Â§â€¡, Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¤Ã Â§â€¹ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼
  bool get hasPremiumAccess => isPremiumActive || inTrialPeriod;

  /// Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾ (Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â®Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â²Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¾)
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
    // Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¡ Ã Â¦Â¤Ã Â§Ë†Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦Â°Ã Â¦ÂªÃ Â¦Â° Ã Â¦Â¯Ã Â¦Â¤Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦â€“Ã Â§â€¹Ã Â¦Â²Ã Â¦Â¾ Ã Â¦Â¹Ã Â§â€¹Ã Â¦â€¢, Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡
    // backend-Ã Â¦Â Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡
    deviceId = p.getString(_kDeviceId) ?? '';
    if (deviceId.isEmpty) {
      deviceId = _generateDeviceId();
      await p.setString(_kDeviceId, deviceId);
    }
    // Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿-Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â«Ã Â¦Â°Ã Â§ÂÃ Â¦Â® Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â¦Â£ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ (activateTrial() Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡
    // Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡) Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â²Ã Â§â€¹Ã Â¦Â¡ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡Ã Â¦â€¡ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡
    // Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§Â Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾, Ã Â¦Â«Ã Â¦Â°Ã Â§ÂÃ Â¦Â® Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â¦Â£ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦â€¡ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾
    final installMs = p.getInt(_kFirstInstall);
    if (installMs != null) {
      firstInstallDate = DateTime.fromMillisecondsSinceEpoch(installMs);
    }
    final d = p.getString(_kDistrict);
    if (d != null) AppLocation.district = d;
    notifyListeners();
    // Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€¦Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â§Â Ã Â¦Â¹Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¡ Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â°
    // Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¦Ã Â§â‚¬Ã Â¦Âª Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ (real Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡) Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸
    // Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·/Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
    if (eveningLampReminder && notifications) {
      await NotificationService.instance.scheduleEveningLampReminders();
    }
  }

  /// Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â®Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â®Ã Â§ÂÃ Â¦Âª + Ã Â¦Â°Ã¢â‚¬ÂÃ Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â® Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€“Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â®Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â®Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿-Ã Â¦â€¡Ã Â¦â€°Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿
  /// Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢ UUID Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§Â Ã Â¦ÂÃ Â¦â€¡ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ (Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾
  /// Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â¦â€¢Ã Â§â€¡ backend-Ã Â¦Â Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾) Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¯Ã Â¦Â¥Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸
  String _generateDeviceId() {
    final rnd = math.Random();
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = List.generate(
      8,
      (_) => '0123456789abcdefghijklmnopqrstuvwxyz'[rnd.nextInt(36)],
    ).join();
    return '$ts$rand';
  }

  /// Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿-Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â«Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®/Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“-Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ "Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â
  /// Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨" Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â²Ã Â§â€¡ Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦â€¡ Ã Â§Â©Ã Â§Â¦ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€”Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€ Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡
  /// Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€¦Ã Â¦ÂªÃ Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡
  /// Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾)Ã Â¥Â¤ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦Â­ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“/Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€¡
  /// Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤
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

  /// Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸ backend Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ verify Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ "Ã Â¦Â¸Ã Â¦Â«Ã Â¦Â²" Ã Â¦Â«Ã Â¦Â¿Ã Â¦Â°Ã Â§â€¡ Ã Â¦ÂÃ Â¦Â²Ã Â§â€¡ Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿
  /// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â§â€¡ (backend-Ã Â¦ÂÃ Â¦Â° status Ã Â¦ÂÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦ÂªÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸
  /// Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€œ Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å¸Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â¦â€¢Ã Â¦ÂªÃ Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼)
  Future<void> activatePremium(DateTime expiresAt) async {
    isPremium = true;
    premiumExpiry = expiresAt;
    final p = _prefs ??= await SharedPreferences.getInstance();
    await p.setBool(_kPremium, true);
    await p.setInt(_kPremiumExpiry, expiresAt.millisecondsSinceEpoch);
    // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â®Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â®Ã Â§â€¡Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦Â°Ã Â¦ÂªÃ Â¦Â°
    // Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¦ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡/Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾
    if (memberId.isEmpty) {
      memberId = _generateMemberId();
      await p.setString(_kMemberId, memberId);
    }
    notifyListeners();
  }

  /// "BP-YYYY-XXXXXX" Ã Â¦Â«Ã Â¦Â°Ã Â¦Â®Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦â€¡Ã Â¦â€°Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾
  /// Ã Â¦Â°Ã Â§â€¡Ã Â¦Â«Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¸ Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸/Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯, backend-Ã Â¦ÂÃ Â¦Â° Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹
  /// Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¶Ã Â¦Â¨ Ã Â¦Â°Ã Â§â€¡Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¿ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾ device_id Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼)
  String _generateMemberId() {
    final rnd = math.Random();
    final year = DateTime.now().year;
    final code = List.generate(
      6,
      (_) => '0123456789ABCDEFGHJKLMNPQRSTUVWXYZ'[rnd.nextInt(35)],
    ).join();
    return 'BP-$year-$code';
  }

  /// backend Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ status Ã Â¦Å¡Ã Â§â€¡Ã Â¦â€¢ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾ Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¡Ã Â§â€¡Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ (Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¦ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡
  /// Ã Â¦â€”Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â§Ã Â¦Â°Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¬Ã Â§â€¡)
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

  /// "Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¦Ã Â§â‚¬Ã Â¦Âª" Ã Â¦â€¦Ã Â¦Å¸Ã Â§â€¹-Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¨/Ã Â¦â€¦Ã Â¦Â« Ã¢â‚¬â€ Ã Â¦â€¦Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡Ã Â¦â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ real Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â°
  /// Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ (Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â· Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¤Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¯Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼) Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡, Ã Â¦â€¦Ã Â¦Â«
  /// Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â² Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡
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

  /// Onboarding Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·Ã Â§â€¡ ("Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨" Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¨Ã Â§â€¡) Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦Â°Ã Â¦ÂªÃ Â¦Â° Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦â€“Ã Â§ÂÃ Â¦Â²Ã Â¦Â²Ã Â§â€¡Ã Â¦â€¡
  /// Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â® Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡, Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â¾/Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾/Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€ Ã Â¦Â° Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾
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
    // Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€œ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â² Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡
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

/// Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã¢â‚¬â€ Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ Ã Â¦ÂÃ Â¦Â¬Ã Â¦â€š Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Å“Ã Â§â€¡
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

  /// Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â­Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¨Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
  Future<void> rescheduleAll() async {
    if (items.isEmpty) await load();
    for (final r in items) {
      if (r.when.isAfter(DateTime.now())) {
        await NotificationService.instance.schedule(r);
      }
    }
  }
}

/// Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¸ Ã¢â‚¬â€ Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡
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

/// Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â°/Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¸Ã Â§â€šÃ Â¦Å¡Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¨, Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­
/// Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ Ã Â¦ÂÃ Â¦Â¬Ã Â¦â€š Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€œ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
class TempleEvent {
  String
  temple; // Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â°/Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®
  String pujaName; // Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®
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
        'Ã°Å¸â€ºâ€¢ ${event.temple}',
        '${event.pujaName} Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Å“',
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

/// Ã Â¦Â¸Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â¬Ã Â§â€¡
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const AndroidNotificationDetails
  _androidDetails = AndroidNotificationDetails(
    'panjika_reminders',
    'Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
    channelDescription:
        'Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨',
    importance: Importance.max,
    priority: Priority.high,
  );

  Future<void> init() async {
    if (_ready) return;
    // Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¸Ã Â¦Â¨Ã Â§â€¡ local notification Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â¦â€¡Ã Â¦Â¨Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ (Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â°
    // Ã Â¦â€¡Ã Â¦Â®Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â¦Â¿Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡) Ã¢â‚¬â€ Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¶ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¤Ã Â¥Â¤ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡
    // Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Å¡Ã Â§ÂÃ Â¦ÂªÃ Â¦Å¡Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡, Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¬Ã Â§â€¡Ã Â¥Â¤
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

    // Android 13+ Ã Â¦Â Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
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
      'Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
      item.text,
      tz.TZDateTime.from(item.when, tz.local),
      const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // iOS-Ã Â¦Â Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€œÃ Â¦â€¡ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â§Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡ (Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â®Ã Â¦Å“Ã Â§â€¹Ã Â¦Â¨ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼)
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

  // "Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¦Ã Â§â‚¬Ã Â¦Âª" Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ reserved id Ã Â¦Â°Ã Â§â€¡Ã Â¦Å¾Ã Â§ÂÃ Â¦Å“, Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡
  // Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡-Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° id-Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¸Ã Â¦â€šÃ Â¦ËœÃ Â¦Â°Ã Â§ÂÃ Â¦Â· Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
  static const int _eveningLampBaseId = 900000;
  static const int _eveningLampDays = 30;

  /// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ real Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ (Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â· Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¤Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¯Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼
  /// Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¦Ã Â§â‚¬Ã Â¦Âª Ã Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼) Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬ Ã Â§Â©Ã Â§Â¦ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€°Ã Â¦Â² Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡Ã Â¥Â¤ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨
  /// Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Â¡ Ã Â¦ËœÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€
  /// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
  /// (Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬Ã Â¦Â° Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾/GPS Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬)Ã Â¥Â¤
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
        'Ã°Å¸Âªâ€ Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¦Ã Â§â‚¬Ã Â¦Âª',
        'Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â®Ã Â§â€¡ Ã Â¦ÂÃ Â¦Â¸Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¦Ã Â§â‚¬Ã Â¦Âª Ã Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡',
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

  /// Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â°/Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¸Ã Â§â€šÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â® Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â²-Ã Â¦Â¸Ã Â¦Â¹ Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã¢â‚¬â€
  /// Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£ Ã Â¦Â®Ã Â§â€¡Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â®, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬ Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â°Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
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
// Ã Â¦Å¸Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Å¸-Ã Â¦Å¸Ã Â§Â-Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¿Ã Â¦Å¡ Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€” Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¶Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯
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
      // Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â­Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¸ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¡Ã Â¦Â¿Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¸ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€ºÃ Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€ºÃ Â¦Â¿ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â¾
      // Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿/Ã Â¦â€¡Ã Â¦â€šÃ Â¦Â°Ã Â§â€¡Ã Â¦Å“Ã Â¦Â¿ Ã Â¦â€°Ã Â¦Å¡Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â²Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾)
      await _tts.setLanguage('bn-BD');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
    } catch (_) {
      // Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â¾ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â¦Â¡Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â­Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¸ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¬Ã Â§â€¡
    }
    _ready = true;
  }

  Future<void> speak(String text) async {
    await _ensureReady();
    isSpeaking = true;
    try {
      // Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬ Web Speech API Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡
      // Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â­Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¸ Ã Â¦Â¨Ã Â¦Â¾-Ã Â¦â€œ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§â€¡, Ã Â¦Â¤Ã Â¦â€“Ã Â¦Â¨ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¯Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â­Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¸ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¡
      // Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡, Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¦Ã Â¦Â® Ã Â¦Å¡Ã Â§ÂÃ Â¦Âª Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾
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
// Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â® Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€°Ã Â¦â€¡Ã Â¦Å“Ã Â§â€¡Ã Â¦Å¸ Ã¢â‚¬â€ home_widget Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡Ã Â¦Å“ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Android Ã Â¦Â²Ã Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡ Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â°
// Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“/Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¥Â¤ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â§Â Ã Â¦Â¹Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€œ Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â® Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¢Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°
// Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¡Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â¶ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼; Android Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦â€œ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦â€¢Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¢ Ã Â¦ËœÃ Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€°Ã Â¦â€¡Ã Â¦Å“Ã Â§â€¡Ã Â¦Å¸
// Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â¶ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ (widget_info.xml-Ã Â¦Â updatePeriodMillis Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬)Ã Â¥Â¤
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
        '${tithi.paksha} Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â· Ã¢â‚¬Â¢ ${tithi.name}',
      );
      await HomeWidget.updateWidget(
        name: _providerName,
        androidName: _providerName,
      );
    } catch (_) {
      // Ã Â¦â€°Ã Â¦â€¡Ã Â¦Å“Ã Â§â€¡Ã Â¦Å¸ Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¡Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¬Ã Â§â€¡
    }
  }
}

// =====================================================================
// Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¨ Ã¢â‚¬â€ google_mobile_ads, Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦â€¡Ã Â¦â€°Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€œ Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡
// =====================================================================

class AdService {
  AdService._();
  static final AdService instance = AdService._();
  bool _initialized = false;

  // Ã Â¦ÂÃ Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Google-Ã Â¦ÂÃ Â¦Â° Ã Â¦â€¦Ã Â¦Â«Ã Â¦Â¿Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸ Ad Unit ID Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¦Ã Â§â€¡ Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸
  // Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¨ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡, Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¤Ã Â§Ë†Ã Â¦Â°Ã Â¦Â¿ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡Ã Â¦Â° AdMob Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â²
  // ID Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¤Ã Â¦â€“Ã Â¦Â¨ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¨ Ã Â¦â€œ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦â€ Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡ (README.md Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨)
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (_) {
      // Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¨ SDK Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¬Ã Â§â€¡
    }
  }

  /// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦â€¡Ã Â¦â€°Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¨ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾
  bool get shouldShowAds => !kIsWeb && !AppSettings.instance.isPremium;
}

/// Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â® Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¨ Ã¢â‚¬â€ Ã Â¦Â²Ã Â§â€¹Ã Â¦Â¡ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â®
/// Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§ÂÃ Â¦â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾, Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€”Ã Â¦Â¾ Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾
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
// Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬ Laravel backend-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸, Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª,
// Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾/Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€¡Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸/Ã Â¦ËœÃ Â§â€¹Ã Â¦Â·Ã Â¦Â£Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§Â Ã Â¦ÂÃ Â¦â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ backend Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¸Ã Â§â€¡Ã Â¥Â¤
// Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â­Ã Â§â€¡Ã Â¦Â²Ã Â¦ÂªÃ Â¦Â®Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡ (Laragon) Ã Â¦ÂªÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦â€ Ã Â¦â€ºÃ Â§â€¡ Ã¢â‚¬â€
// Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦â€š Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â° 'hosted' URL-Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â²Ã Â§â€¡Ã Â¦â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â°
// Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¯Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡, Ã Â¦â€ Ã Â¦Â° Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€œ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§Â Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤
// =====================================================================

class BackendConfig {
  // Ã¢Å¡Â Ã¯Â¸Â Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦â€š Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¡Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨, Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨: 'https://api.banglapanjika.com'
  static const String hosted = '';

  static String get baseUrl {
    if (hosted.isNotEmpty) return hosted;
    // Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦â€š Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡ Ã¢â‚¬â€ Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂªÃ Â¦Â¿Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¾ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Laravel Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â¦Â¾Ã Â¦Â°
    // Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡Ã Â¥Â¤ Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡ (Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦ÂªÃ Â¦Â¿Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡) 127.0.0.1 Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¬Ã Â§â€¡, Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§Â
    // Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨ Ã Â¦â€œ Ã Â¦ÂªÃ Â¦Â¿Ã Â¦Â¸Ã Â¦Â¿ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ WiFi-Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡ Ã Â¦ÂÃ Â¦Â¬Ã Â¦â€š Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡
    // Ã Â¦ÂªÃ Â¦Â¿Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å¸Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢ IP Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡ (Laragon-Ã Â¦ÂÃ Â¦Â° Ã Â¦â€°Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â§â€¹Ã Â¦Â° Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼,
    // Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨ 172.18.100.126) Ã¢â‚¬â€ Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å¸Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¡ IP-Ã Â¦â€œ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¥Â¤
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return 'http://172.18.100.126:8000';
  }
}

/// Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â° Play Store Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€šÃ Â¦â€¢ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿ (Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¶ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿)Ã Â¥Â¤ Play
/// Store-Ã Â¦Â Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¶ Ã Â¦Â¹Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â° Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€šÃ Â¦â€¢ Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â²Ã Â§â€¡ "Ã°Å¸Å½â€° Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â°
/// Ã Â¦Â®Ã Â§â€¡Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°"-Ã Â¦ÂÃ Â¦Â° Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€œ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°-Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Å¸Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Å¸Ã Â§â€¡ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â¦Â²Ã Â§â€¹Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â° Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€šÃ Â¦â€¢/Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å“
/// Ã Â¦ÂÃ Â¦Â®Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€œ Ã Â¦â€ Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§Â Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤ Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿
/// Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦â€¦Ã Â¦â€šÃ Â¦Â¶Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Å¡Ã Â§ÂÃ Â¦ÂªÃ Â¦Å¡Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â²Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ (Ã Â¦Â­Ã Â¦Â¾Ã Â¦â„¢Ã Â¦Â¾/placeholder Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€šÃ Â¦â€¢
/// Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾)Ã Â¥Â¤
class AppLinks {
  // Ã¢Å¡Â Ã¯Â¸Â Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¶ Ã Â¦Â¹Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â° Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¨, Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨:
  // 'https://play.google.com/store/apps/details?id=com.example.bangla_panjika_native'
  static const String playStore = '';
}

/// Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª Ã¢â‚¬â€ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€œ Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¸ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬ Laravel + MySQL backend-Ã Â¦Â
/// Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â§â€¡ (Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Firebase/Ã Â¦Â¥Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡-Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾, backend Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â§Â
/// Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¬Ã Â§â€¡)Ã Â¥Â¤
class CloudBackupService {
  CloudBackupService._();
  static final CloudBackupService instance = CloudBackupService._();

  /// null Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â«Ã Â¦Â² Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡, Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂÃ Â¦Â°Ã Â¦Â° Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å“ Ã Â¦Â«Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¤ Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼
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
        return data['message']?.toString() ??
            'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡';
      }
      final p = await SharedPreferences.getInstance();
      await p.setInt(
        'last_cloud_backup',
        DateTime.now().millisecondsSinceEpoch,
      );
      return null;
    } catch (e) {
      return 'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å¸/Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¡Ã Â¦â€¢ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨';
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
        return data['message']?.toString() ??
            'Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿';
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
      return 'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å¸/Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¡Ã Â¦â€¢ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨';
    }
  }

  Future<DateTime?> lastBackupAt() async {
    final p = await SharedPreferences.getInstance();
    final ms = p.getInt('last_cloud_backup');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }
}

// =====================================================================
// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸ Ã¢â‚¬â€ Laravel + Razorpay backend-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”
// =====================================================================

/// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã¢â‚¬â€ Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ (Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â® backend
/// Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡, Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡ backend-Ã Â¦ÂÃ Â¦â€œ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â§â€¡)
class PremiumPlan {
  final String id; // 'monthly' / 'yearly'
  final String label;
  final String priceLabel;
  const PremiumPlan(this.id, this.label, this.priceLabel);
}

const List<PremiumPlan> premiumPlans = [
  PremiumPlan(
    'monthly',
    'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â®',
    'Ã¢â€šÂ¹Ã Â§ÂªÃ Â§Â¯ / Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸',
  ),
  PremiumPlan(
    'yearly',
    'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â®',
    'Ã¢â€šÂ¹Ã Â§ÂªÃ Â§Â¯Ã Â§Â¯ / Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°',
  ),
];

/// Laravel backend-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸ flow-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å¸Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢ Ã Â¦â€¢Ã Â¦Â² Ã¢â‚¬â€ Ã Â¦â€¦Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¤Ã Â§Ë†Ã Â¦Â°Ã Â¦Â¿,
/// Ã Â¦Â­Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€œ Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦Å¡Ã Â§â€¡Ã Â¦â€¢Ã Â¥Â¤ backend Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ [baseUrl] Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿
/// Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¬Ã Â§â€¡ Ã Â¦ÂÃ Â¦Â¬Ã Â¦â€š Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â² Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â·Ã Â§ÂÃ Â¦Å¸ Ã Â¦ÂÃ Â¦Â°Ã Â¦Â° Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å“ Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡ (Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â°Ã Â¦Â¬Ã Â§â€¡ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¶ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾)Ã Â¥Â¤
class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  static String get baseUrl => BackendConfig.baseUrl;

  bool get isConfigured => baseUrl.isNotEmpty;

  Future<Map<String, dynamic>> createOrder(String plan) async {
    if (!isConfigured) {
      throw Exception(
        'Backend Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿ Ã¢â‚¬â€ PaymentService.baseUrl Ã Â¦Â Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° '
        'Laravel Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° URL Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¨',
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
        data['message']?.toString() ??
            'Ã Â¦â€¦Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¤Ã Â§Ë†Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡',
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
      throw Exception(
        data['message']?.toString() ??
            'Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡',
      );
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
      // Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å¸Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦â€ Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡
    }
  }
}

class BanglaPanjikaApp extends StatelessWidget {
  const BanglaPanjikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¸ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡ (Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â¾) Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title:
            'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾',
        // readability Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¡Ã Â§â€¡Ã Â¦Å¸: Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Noto Sans Bengali Ã Â¦Â«Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸
        // Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡ (Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¦Ã Â§â€¡ Ã Â¦Â¡Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â«Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾/Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â·Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡
        // Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¤, Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â® Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€œ Ã Â¦Â®Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡)
        theme: ThemeData(useMaterial3: true, fontFamily: 'NotoSansBengali'),
        // Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§â€¡Ã Â¦Â® Ã Â¦Â«Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸-Ã Â¦Â¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Å“ Ã Â¦Â¯Ã Â¦Â¤Ã Â¦â€¡ Ã Â¦â€ºÃ Â§â€¹Ã Â¦Å¸ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§ÂÃ Â¦â€¢ (Ã Â¦â€¢Ã Â¦Â® Ã Â¦Â¬Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¸Ã Â§â‚¬Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡
        // Ã Â¦ÂÃ Â¦Â®Ã Â¦Â¨ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§â€¡), Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â° Ã Â¦Â²Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¡Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Å“Ã Â§â€¡Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€ºÃ Â§â€¹Ã Â¦Å¸
        // Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ (readability floor) Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â§â€¡Ã Â¦â€° Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§â€¡Ã Â¦Â® Ã Â¦Â«Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸ Ã Â¦â€¦Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¢ Ã Â¦Â¬Ã Â¦Â¡Ã Â¦Â¼
        // Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â§Â§.Ã Â§Â© Ã Â¦â€”Ã Â§ÂÃ Â¦Â£Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦Â¬Ã Â¦Â¡Ã Â¦Â¼ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾, Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡/Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â²Ã Â§â€¡Ã Â¦â€ Ã Â¦â€°Ã Â¦Å¸
        // Ã Â¦Â­Ã Â§â€¡Ã Â¦â„¢Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
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

/// Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ (Ã Â¦Â°Ã Â¦â€š, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾, Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯/Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨) Ã¢â‚¬â€
/// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ (Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â²-Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â®) Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
class SkyPhase {
  final List<Color> gradientColors;
  final List<double> gradientStops;
  final double starOpacity;
  final bool isDay;
  // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¶Ã Â¦Â¾ Ã¢â‚¬â€ moonIllumination: Ã Â§Â¦ (Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾) .. Ã Â§Â§ (Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾)
  final double moonIllumination;
  final bool
  moonWaxing; // true = Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â· (Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦â€ºÃ Â§â€¡), false = Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â· (Ã Â¦â€¢Ã Â¦Â®Ã Â¦â€ºÃ Â§â€¡)
  final bool
  isAmavasya; // Ã Â¦â€ Ã Â¦Å“ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¹ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡

  const SkyPhase({
    required this.gradientColors,
    required this.gradientStops,
    required this.starOpacity,
    required this.isDay,
    required this.moonIllumination,
    required this.moonWaxing,
    required this.isAmavasya,
  });

  // Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶: Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€”Ã Â¦Â­Ã Â§â‚¬Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€šÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¯,
  // Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€”Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§ÂÃ Â¦Â®Ã Â¦Â£Ã Â§ÂÃ Â¦Â¡Ã Â¦Â²Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦Â­Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦Â°Ã Â¦â€š Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
  // Ã Â¦ÂÃ Â¦Â¤Ã Â§â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â£Ã Â§ÂÃ Â¦Â¡Ã Â§â€¡Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡-Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡Ã Â¥Â¤
  static const List<Color> _night = [
    Color(0xFF01030A),
    Color(0xFF050D1E),
    Color(0xFF071228),
    Color(0xFF03060F),
  ];
  // Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤ Ã¢â‚¬â€ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¦Ã Â¦Â®Ã Â¦â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬Ã Â§â€¡ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¢Ã Â¦Â¼/Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¹
  // Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦Â«Ã Â§ÂÃ Â¦Å¸Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡
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
    // sunTimes() Ã Â¦Â¯Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¾ "IST-marked" (Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨
    // PanchangCalculator._toTrueUtc-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯) Ã¢â‚¬â€ DateTime.now() Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿
    // Ã Â¦ÂÃ Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¤Ã Â§ÂÃ Â¦Â²Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã Â§Â«:Ã Â§Â©Ã Â§Â¦ Ã Â¦ËœÃ Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â­Ã Â§ÂÃ Â¦Â² Ã Â¦Â¹Ã Â¦Â¤Ã Â§â€¹, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â«Ã Â¦Â°Ã Â¦Â®Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¹Ã Â¥Â¤
    final nowMarked = now.toUtc().add(const Duration(hours: 5, minutes: 30));

    // --- Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¶Ã Â¦Â¾ (real-time) ---
    // moonAgeDays: Ã Â§Â¦ = Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤, ~Ã Â§Â§Ã Â§Âª.Ã Â§Â­Ã Â§Â­ = Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾, ~Ã Â§Â¨Ã Â§Â¯.Ã Â§Â«Ã Â§Â© = Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾
    const synodic = 29.530588853;
    final moonAge = PanchangCalculator.moonAgeDays(now) % synodic;
    final phaseAngle = moonAge / synodic * 2 * math.pi;
    final moonIllumination = (1 - math.cos(phaseAngle)) / 2; // Ã Â§Â¦..Ã Â§Â§
    final moonWaxing = moonAge < synodic / 2;
    // Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â° ~Ã Â§Â§ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ "Ã Â¦â€ Ã Â¦Å“ Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾" Ã Â¦Â§Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡
    final isAmavasya = moonAge < 1.0 || moonAge > synodic - 1.0;
    final nightColors = isAmavasya ? _amavasyaNight : _night;

    if (nowMarked.isAfter(sunrise) && nowMarked.isBefore(sunset)) {
      // --- Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ ---
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

    // --- Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤ (Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂªÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤) ---
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
    // Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨Ã Â¦â€œ Ã Â§Â¦ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œ Ã Â¦Â®Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â£Ã Â§ÂÃ Â¦Â¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼,
    // Ã Â¦â€”Ã Â¦Â­Ã Â§â‚¬Ã Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²Ã Â¥Â¤
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

/// Ã Â¦Â¸Ã Â§Å’Ã Â¦Â°Ã Â¦Å“Ã Â¦â€”Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯/Ã Â¦ÂªÃ Â§Æ’Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â¬Ã Â§â‚¬ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ Ã Â§Â­Ã Â¦Å¸Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â§â€¡
/// Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ Ã Â¦Â°Ã Â¦â€š (Ã Â¦â€ Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢) Ã Â¦â€œ Ã Â¦â€”Ã Â¦Â¡Ã Â¦Â¼ Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¤ Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²Ã Â¦Â¤Ã Â¦Â¾
/// (mean apparent magnitude Ã¢â‚¬â€ Ã Â¦â€¢Ã Â¦Â® Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨ = Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²)Ã Â¥Â¤ Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²Ã Â¦Â¤Ã Â¦Â¾ real-time
/// phase-angle Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾ (Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€¦Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¤ Ã Â¦Å“Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â² Ã Â¦Â¸Ã Â§â€šÃ Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â¤),
/// Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¡Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°/Ã Â¦â€ Ã Â¦Â­Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â¤Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â¦Å¸ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¸Ã Â§â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â® Ã Â¦â€¡Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡
/// Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â readability-Ã Â¦Â°
/// Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ subtle Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡Ã Â¥Â¤
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

/// Ã Â¦Â¨Ã Â¦Â¬Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã¢â‚¬â€ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â¦Â¶Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â§Â¯Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹, Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬ Ã Â¦Â°Ã Â¦â„¢Ã Â§â€¡ Ã Â¦â€¢Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦ÂªÃ Â¦Â¥Ã Â§â€¡ Ã Â¦ËœÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¥Â¤
class CosmicBackground extends StatefulWidget {
  final Widget child;
  const CosmicBackground({super.key, required this.child});
  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with TickerProviderStateMixin, RouteAware {
  // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â§â€¡ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â­ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â°
  late final AnimationController _rainController;
  // Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦Â° Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â¤, Ã Â¦Â®Ã Â¦Â¸Ã Â§Æ’Ã Â¦Â£ Ã Â¦â€¢Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦ÂªÃ Â¦Â¥-Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â²Ã Â§â€¡Ã Â¦Â° "heartbeat" Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â®Ã Â§â€¡ rebuild
  // Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤ Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ extrapolate/sync Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿
  // Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â®Ã Â§â€¡Ã Â¦â€¡ real astronomical Ã Â¦Â¸Ã Â§â€šÃ Â¦Â¤Ã Â§ÂÃ Â¦Â° (celestialAltAz) Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â
  // Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Å¸Ã Â¦Â¾ "accelerated Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¡Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼" (Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨) Ã¢â‚¬â€ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ real
  // Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â¦â€¡ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸, Ã Â¦â€ Ã Â¦Â° resync-Ã Â¦ÂÃ Â¦Â° Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â§Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹
  // sudden jump-Ã Â¦â€œ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦â€¢, Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¤Ã Â¦Â° movement Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
  late final AnimationController _planetClock;
  // Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¡Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² "accelerated" Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â§â€¹Ã Â¦â„¢Ã Â¦Â° Ã¢â‚¬â€ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â§Â Ã Â¦Â¹Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬
  // Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦ÂªÃ Â¦Â° real Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ _planetTimeAcceleration
  // Ã Â¦â€”Ã Â§ÂÃ Â¦Â£ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ Ã Â¦ÂÃ Â¦â€”Ã Â§â€¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¡ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼/
  // Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤, Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”, Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã Â¦Â°Ã Â¦â€š Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦Â¸Ã Â¦Â¬Ã Â§â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬ Ã Â¦Â«Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ (Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹
  // Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â¦â€œ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ DateTime.now() Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼)
  late final DateTime _planetSimAnchor;
  // Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â° (~Ã Â§Â§Ã Â§Â«Ã‚Â°/Ã Â¦ËœÃ Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾, Ã Â¦ÂªÃ Â§Æ’Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â¬Ã Â§â‚¬Ã Â¦Â° Ã Â¦ËœÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£Ã Â§â€¡) Ã Â¦Â¤Ã Â§ÂÃ Â¦Â²Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂÃ Â¦Â¤ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â° Ã Â¦Â¯Ã Â§â€¡
  // real-time-Ã Â¦Â Ã Â¦â€¢Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¢ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â§â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¨Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Å¡Ã Â§â€¹Ã Â¦â€“Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â
  // Ã Â¦Â¦Ã Â§Æ’Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¯Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ (Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼) Ã Â¦Â¬Ã Â¦Â¹Ã Â§ÂÃ Â¦â€”Ã Â§ÂÃ Â¦Â£ Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¬Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡;
  // Ã Â¦ÂÃ Â¦â€¡ Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶-Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦Â£ (Ã Â§Â©Ã Â§Â¬Ã Â§Â¦Ã‚Â°) Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬Ã Â§â€¡ ~Ã Â§Â¨Ã Â§Âª Ã Â¦ËœÃ Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾,
  // Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â¬Ã Â§â€¡ ~Ã Â§Â¬ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¸ Ã¢â‚¬â€ Ã Â¦Â¤Ã Â¦Â¬Ã Â§ÂÃ Â¦â€œ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â²
  // astronomical Ã Â¦Â¸Ã Â§â€šÃ Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾, Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦Â®Ã Â§â€¡Ã Â¦Â²Ã Â§â€¹/Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼
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
    // Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¡ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â­, Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨-Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢
    _isRaining = WeatherService.instance.isRaining;
    _syncRainAnim();
    WeatherService.instance.addListener(_onWeatherChanged);
    WeatherService.instance.refresh();
    // Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â°/Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° real-time GPS Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€œ
    // Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€”Ã Â¦Â¾ Ã Â¦Â§Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡, Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²
    // Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Å¡Ã Â§ÂÃ Â¦ÂªÃ Â¦Å¡Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¬Ã Â§â€¡
    LocationService.instance.addListener(_onLocationChanged);
    LocationService.instance.refresh();
    // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¸Ã Â§â€¡ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã Â¦Â°Ã Â¦â€š/Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯-Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â² Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â®Ã Â§â€¡ Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¡Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡;
    // WeatherService Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡ Ã Â§Â§Ã Â§Â« Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â² Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡
    // Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ refresh() Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å¸Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢ Ã Â¦Â²Ã Â§â€¹Ã Â¦Â¡ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾
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
    // GPS Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦ÂÃ Â¦â€¡Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â² Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€œ Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡
    // Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¡ real Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€”Ã Â¦Â¾ Ã Â¦Â§Ã Â¦Â°Ã Â§â€¡
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
    // Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â§â€¡Ã Â¦Â° Ã Â¦ËœÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿ (accelerated virtual time) Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â§Â/Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¸Ã Â§â€¡ Live Sky
    // Animation Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¥Ã Â§â€¡Ã Â¦Â®Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡, Ã Â¦Â¤Ã Â¦â€“Ã Â¦Â¨ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â®Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¿Ã Â¦Â°
    // Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¬Ã Â§â€¡ (Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã Â¦Â°Ã Â¦â€š/Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼-Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€¡Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€œÃ Â¦ÂªÃ Â¦Â° Ã Â¦ÂÃ Â¦Â° Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡)
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
          // ---- Ã Â¦Â®Ã Â¦Â¾Ã Â¦ÂÃ Â§â€¡Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡ Ã Â¦â€°Ã Â¦Â²Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾/Ã Â¦Â¶Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦â€š-Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€œ Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â® Ã Â¦â€°Ã Â¦ÂªÃ Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â¥ Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â
          // Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶ Ã Â¦Â¯Ã Â¦Â¥Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡, Ã Â¦â€“Ã Â§ÂÃ Â¦Â¬ Ã Â¦ËœÃ Â¦Â¨Ã Â¦ËœÃ Â¦Â¨ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€ Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡
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
                  // --- Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯: Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¤ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â§â€¡ ---
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
          // ---- Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦: Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¶Ã Â¦Â¾ (Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²/Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·) Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦â€¦Ã Â¦â€šÃ Â¦Â¶
          // Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â®Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦Â¨, Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦â€”Ã Â§â€¹Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â¥Â¤ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¾
          // Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â¨ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â°Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â·Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾
          // Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦ÂÃ Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡Ã Â¥Â¤
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
          // ---- Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â­ Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾: Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¡ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â§â€¡
          // Ã Â¦Â®Ã Â§â€¡Ã Â¦ËœÃ Â¦Â²Ã Â¦Â¾ Ã Â¦â€ Ã Â¦Â­Ã Â¦Â¾ + Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â° real-time Ã Â¦Â¡Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾
          // Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ (Open-Meteo)Ã Â¥Â¤ IgnorePointer Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦â€ Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¬Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â®/Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â²
          // Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¤Ã Â§â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
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

  /// Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦Ã Â§â€¡ Ã Â¦Â¸Ã Â§Å’Ã Â¦Â°Ã Â¦Å“Ã Â¦â€”Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ Ã Â§Â­Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â
  /// Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ GPS Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€”Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦â€œÃ Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦â€¡ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â«Ã Â§ÂÃ Â¦Å¸Ã Â§â€¡
  /// Ã Â¦â€œÃ Â¦Â Ã Â§â€¡, Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦Â²Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦Â®Ã Â§â€¡Ã Â¦Â²Ã Â§â€¹/Ã Â¦Å“Ã Â§â€¹Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡-Ã Â¦Â¸Ã Â¦Â¬-Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡Ã Â¥Â¤
  /// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â®Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ real astronomical Ã Â¦Â¸Ã Â§â€šÃ Â¦Â¤Ã Â§ÂÃ Â¦Â° (celestialAltAz) Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾
  /// Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Å¸Ã Â¦Â¾ accelerated Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¡Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹
  /// Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ sync/extrapolation Ã Â¦Â§Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡, Ã Â¦Â«Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ sudden jump-Ã Â¦â€œ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤
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
    // Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€”Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€œÃ Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã Â¦â€œÃ Â¦Â Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â® Ã Â§Â®Ã‚Â° Ã Â¦Å“Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡ Ã Â¦Â«Ã Â§ÂÃ Â¦Å¸Ã Â§â€¡ Ã Â¦â€œÃ Â¦Â Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¹Ã Â¦Â Ã Â¦Â¾Ã Â§Å½
    // Ã Â¦ÂªÃ Â¦Âª-Ã Â¦â€ Ã Â¦Âª/Ã Â¦â€¦Ã Â¦Â¦Ã Â§Æ’Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¹Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦ÂÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡
    final altFactor = (altNow / 8.0).clamp(0.0, 1.0);
    final vis = (duskFactor * altFactor).clamp(0.0, 1.0);
    if (vis <= 0.01) return const SizedBox.shrink();
    // Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ real azimuth Ã¢â‚¬â€ accelerated Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¡Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡
    // Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€¢ (direction) Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ astronomically Ã Â¦Â¸Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¦Ã Â§Æ’Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¯Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨
    // Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤
    final angleDeg = altAz['azimuth'] ?? 0.0;
    final radius = (_planetRingDiameter[pv.key] ?? 100.0) / 2;
    // magnitude Ã Â¦Â¯Ã Â¦Â¤ Ã Â¦â€¢Ã Â¦Â® (Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²), Ã Â¦Â¡Ã Â¦Å¸ Ã Â¦Â¤Ã Â¦Â¤ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¬Ã Â¦Â¡Ã Â¦Â¼/Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â² Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§â€¡Ã Â¦Â²
    // Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¸Ã Â§â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â® Ã Â¦â€¡Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â¿Ã Â¦Â¤
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

/// Ã Â¦Â®Ã Â¦Â¾Ã Â¦ÂÃ Â§â€¡Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦Â®Ã Â¦Â¤ Ã Â¦â€°Ã Â¦Â²Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾ (Ã Â¦Â¶Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦â€š Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â°) Ã Â¦â€œ Ã Â¦Â¦Ã Â§â€šÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â® Ã Â¦â€°Ã Â¦ÂªÃ Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â§â€¡Ã Â¦Â°
/// Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â²Ã Â¦Â°Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â¥ Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶ Ã Â¦Â¯Ã Â¦Â¥Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡, Ã Â¦ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦Â®Ã Â§â€¡Ã Â¦Â²Ã Â§â€¹ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§Â
/// Ã Â¦â€“Ã Â§ÂÃ Â¦Â¬ Ã Â¦ËœÃ Â¦Â¨Ã Â¦ËœÃ Â¦Â¨ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦â€ Ã Â¦Â° Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¸Ã Â§â€¡ Live Sky Animation Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨
/// Ã Â¦â€ Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¦Ã Â¦Â®Ã Â¦â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾
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
    final delay = Duration(
      seconds: 22 + _rnd.nextInt(38),
    ); // Ã Â§Â¨Ã Â§Â¨Ã¢â‚¬â€œÃ Â§Â¬Ã Â§Â¦ Ã Â¦Â¸Ã Â§â€¡. Ã Â¦ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦Â®Ã Â§â€¡Ã Â¦Â²Ã Â§â€¹
    _meteorTimer = Timer(delay, () {
      if (!mounted || !widget.active) return;
      _fireMeteor();
    });
  }

  void _scheduleNextSatellite() {
    final delay = Duration(
      seconds: 40 + _rnd.nextInt(50),
    ); // Ã Â§ÂªÃ Â§Â¦Ã¢â‚¬â€œÃ Â§Â¯Ã Â§Â¦ Ã Â¦Â¸Ã Â§â€¡. Ã Â¦ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦Â®Ã Â§â€¡Ã Â¦Â²Ã Â§â€¹
    _satelliteTimer = Timer(delay, () {
      if (!mounted || !widget.active) return;
      _fireSatellite();
    });
  }

  void _fireMeteor() {
    final startX = _rnd.nextDouble() * 0.7 + 0.05;
    final startY = _rnd.nextDouble() * 0.25;
    final angle =
        (_rnd.nextDouble() * 0.5 + 0.2) *
        math.pi; // Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¢ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡
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
    // Ã Â¦â€°Ã Â¦Â²Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾/Ã Â¦Â¶Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦â€š Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã¢â‚¬â€ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€ºÃ Â§ÂÃ Â¦Å¸Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾, Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â®Ã Â¦Â¶ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â²Ã Â§â€¡Ã Â¦Å“Ã Â¦Â¸Ã Â¦Â¹
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

    // Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â® Ã Â¦â€°Ã Â¦ÂªÃ Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã¢â‚¬â€ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°, Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼-Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§Â Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â²Ã Â¦Â°Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Å¡Ã Â¦Â²Ã Â§â€¡
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

/// Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â§â€¡ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â­
/// Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ (Open-Meteo) Ã Â¦Â¸Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¡ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€¡ Ã Â¦â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
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

/// Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¶Ã Â¦Â¾ Ã Â¦ÂÃ Â¦ÂÃ Â¦â€¢Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°
/// (Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â®Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦Â¨ earthshine), Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦â€”Ã Â§â€¹Ã Â¦Â²Ã Â¦â€¢, Ã Â¦â€ Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¾Ã Â¦ÂÃ Â§â€¡Ã Â¦Â°
/// Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡/Ã Â¦â€¦Ã Â¦Â°Ã Â§ÂÃ Â¦Â§Ã Â§â€¡Ã Â¦â€¢/Ã Â¦â€°Ã Â¦ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦ (waxing = Ã Â¦Â¡Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€¢
/// Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦â€œ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦â€ºÃ Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·; waning = Ã Â¦Â¬Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦â€œ Ã Â¦â€¢Ã Â¦Â®Ã Â¦â€ºÃ Â§â€¡ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·)Ã Â¥Â¤
/// Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¶Ã Â¦Â¾ Ã Â¦â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡ Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â¶Ã Â¦Â¨ Ã¢â‚¬â€ CosmicBackground
/// Ã Â¦â€ Ã Â¦Â° Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶, Ã Â¦Â¦Ã Â§ÂÃ Â¦â€¡ Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦ Ã Â¦â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
void paintMoonPhase(
  Canvas canvas,
  Offset center,
  double r,
  double illumination,
  bool waxing,
) {
  // Ã Â¦Â®Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€ Ã Â¦Â­Ã Â¦Â¾ (glow) Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â§â€šÃ Â¦Â¨Ã Â¦Â¤Ã Â¦Â® Ã Â¦â€ Ã Â¦Â­Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡Ã Â¦â€œ
  // Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â·Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¬Ã Â§â€¹Ã Â¦ÂÃ Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€ºÃ Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€ºÃ Â¦Â¿ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²
  final glowPaint = Paint()
    ..shader = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: 0.30 * illumination + 0.16),
        Colors.white.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: r * 2.1));
  canvas.drawCircle(center, r * 2.1, glowPaint);

  // Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°/Ã Â¦â€¦Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦â€¦Ã Â¦â€šÃ Â¦Â¶ Ã¢â‚¬â€ earthshine-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦Â®Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â²Ã Â¦Å¡Ã Â§â€¡-Ã Â¦Â§Ã Â§â€šÃ Â¦Â¸Ã Â¦Â° (Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â°
  // Ã Â¦Â°Ã Â¦â„¢Ã Â§â€¡Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â·Ã Â§ÂÃ Â¦Å¸ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦â€”Ã Â§â€¹Ã Â¦Â² Ã Â¦â€ Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â§â€¹Ã Â¦ÂÃ Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼)
  final darkPaint = Paint()..color = const Color(0xFF4A5470);
  canvas.drawCircle(center, r, darkPaint);
  // Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¤Ã Â¦Â²Ã Â¦Â¾ Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â² Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â¦Â® Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¦Ã Â¦Â¶Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦â€œ Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â¨
  // Ã Â¦â€”Ã Â§â€¹Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€ Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â°Ã Â§â‚¬Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â·Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¬Ã Â§â€¹Ã Â¦ÂÃ Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
  final rimPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.45)
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.0, r * 0.045);
  canvas.drawCircle(center, r, rimPaint);

  // Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦â€¦Ã Â¦â€šÃ Â¦Â¶ Ã Â¦â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¦Ã Â§ÂÃ Â¦â€¡ Ã Â¦â€¦Ã Â¦Â°Ã Â§ÂÃ Â¦Â§Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤/Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â¬Ã Â§Æ’Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° combine Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ Ã Â¦Â¦Ã Â¦Â¶Ã Â¦Â¾
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

  // Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â²Ã Â¦â€¢Ã Â¦Â¾ crater Ã Â¦Å¸Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â° (Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦â€¦Ã Â¦â€šÃ Â¦Â¶Ã Â§â€¡ Ã Â¦Â¬Ã Â§â€¹Ã Â¦ÂÃ Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦Â®Ã Â¦Â¤ Ã Â¦â€ºÃ Â§â€¹Ã Â¦ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾)
  final craterPaint = Paint()..color = Colors.black.withValues(alpha: 0.07);
  canvas.drawCircle(center + Offset(r * 0.25, -r * 0.2), r * 0.14, craterPaint);
  canvas.drawCircle(center + Offset(-r * 0.1, r * 0.28), r * 0.10, craterPaint);
  canvas.drawCircle(center + Offset(r * 0.05, r * 0.02), r * 0.07, craterPaint);
}

class _MoonPhasePainter extends CustomPainter {
  _MoonPhasePainter({required this.illumination, required this.waxing});
  final double
  illumination; // Ã Â§Â¦ (Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾) .. Ã Â§Â§ (Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾)
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
// Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â£Ã Â§ÂÃ Â¦Â¡ Ã¢â‚¬â€ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾, Ã Â¦â€ºÃ Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¥ (Milky Way) Ã Â¦â€œ Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾
// =====================================================================

/// Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¥Â¤ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦Â°Ã Â¦â€š, Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â®Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â°
/// Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬ Ã Â¦â€ºÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¦ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ speed/phase Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡Ã Â¥Â¤
class _StarSpec {
  final Offset
  pos; // 0..1 Ã Â¦â€ Ã Â¦ÂªÃ Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨
  final double radius;
  final double baseAlpha;
  final Color color;
  final double twinkleSpeed;
  final double twinklePhase;
  final bool
  bright; // Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â² Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦â€ Ã Â¦Â­Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦Â°Ã Â¦Â¶Ã Â§ÂÃ Â¦Â®Ã Â¦Â¿ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¬Ã Â§â€¡
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

/// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¾Ã Â¦Â²Ã Â§â‚¬ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â£Ã Â¦Â¿ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦Â°Ã Â¦â€š (O/B Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â­ Ã¢â€ â€™ M Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â²Ã Â¦Å¡Ã Â§â€¡)
const List<Color> _stellarColors = [
  Color(
    0xFFC8D8FF,
  ), // Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â­-Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ (Ã Â¦â€”Ã Â¦Â°Ã Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾)
  Color(0xFFDCE6FF),
  Color(0xFFFFFFFF), // Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾
  Color(0xFFFFFFFF),
  Color(
    0xFFFFF6E8,
  ), // Ã Â¦Â¹Ã Â¦Â²Ã Â¦Â¦Ã Â§â€¡-Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ (Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹)
  Color(0xFFFFF0D0),
  Color(0xFFFFD9A8), // Ã Â¦â€¢Ã Â¦Â®Ã Â¦Â²Ã Â¦Â¾
  Color(
    0xFFFFC6A0,
  ), // Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â²Ã Â¦Å¡Ã Â§â€¡ (Ã Â¦Â Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾)
];

class StarsLayer extends StatefulWidget {
  const StarsLayer({super.key});
  @override
  State<StarsLayer> createState() => _StarsLayerState();
}

class _StarsLayerState extends State<StarsLayer> with TickerProviderStateMixin {
  late final AnimationController _twinkle;
  // Ã Â¦ÂªÃ Â§Æ’Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â¬Ã Â§â‚¬Ã Â¦Â° Ã Â¦ËœÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡ Ã Â¦â€“Ã Â§ÂÃ Â¦Â¬ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â®Ã Â¦Â¨Ã Â§â€¡
  // Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ dome-projection Ã Â¦â€ºÃ Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¡ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â­Ã Â§â€šÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦â€ Ã Â¦Â¨Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â°
  // Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â§â€¡ Ã Â¦â€¦Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¸Ã Â§â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â®, Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â° Ã Â¦ËœÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¨ (Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° ~Ã Â§Â¦.Ã Â§Â¬Ã‚Â° Ã Â¦Â¦Ã Â§â€¹Ã Â¦Â²Ã Â§â€¡)
  late final AnimationController _drift;
  late final List<_StarSpec> _stars;
  late final List<_DustPuff> _milkyWay;
  late final List<_NebulaBlob> _nebulae;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(42);

    // --- Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾: Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€” Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§â‚¬Ã Â¦Â£, Ã Â¦â€¦Ã Â¦Â²Ã Â§ÂÃ Â¦Âª Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§Â Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â² (Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦Â¬Ã Â¦Â£Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¨) ---
    _stars = List.generate(190, (i) {
      // r^3 Ã Â¦Â¬Ã Â¦Â£Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦â€¦Ã Â¦Â§Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â¶ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾ Ã Â¦â€ºÃ Â§â€¹Ã Â¦Å¸, Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦â€”Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â¡Ã Â¦Â¼
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

    // --- Ã Â¦â€ºÃ Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¥: Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¢ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡ Ã Â¦Â¬Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â° Ã Â¦Â§Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦Â° Ã Â¦Â®Ã Â§â€¡Ã Â¦Ëœ ---
    _milkyWay = List.generate(90, (i) {
      final along = rnd.nextDouble();
      // Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â²Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦â€”Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¸Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾Ã Â¦Â°
      final spread =
          (rnd.nextDouble() + rnd.nextDouble() + rnd.nextDouble()) / 3.0 - 0.5;
      final perp = spread * 0.42;
      // Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¢ Ã Â¦Â°Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾: Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡-Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡-Ã Â¦Â¡Ã Â¦Â¾Ã Â¦Â¨
      final x = along;
      final y = 0.18 + along * 0.62 + perp;
      return _DustPuff(
        Offset(x, y),
        0.05 + rnd.nextDouble() * 0.11,
        0.030 + rnd.nextDouble() * 0.055,
        rnd.nextBool() ? const Color(0xFFB9C7F0) : const Color(0xFFE6D5F5),
      );
    });

    // --- Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾: Ã Â¦â€¢Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¢Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¬Ã Â¦Â¡Ã Â¦Â¼ Ã Â¦Â°Ã Â¦â„¢Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€”Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â§â€¡Ã Â¦Ëœ ---
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
        // Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â° (Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ + Ã Â¦â€ºÃ Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¥) Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â®Ã Â§â€¡ Ã Â¦â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: DeepSkyPainter(_nebulae, _milkyWay)),
          ),
        ),
        // Ã Â¦â€¢Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¢Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â£Ã Â§ÂÃ Â¦Â¡Ã Â¦Â²Ã Â§â€¡Ã Â¦Â° stylized Ã Â¦â€ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¸ (Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â²Ã Â§â‚¬Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤, Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€“Ã Â§ÂÃ Â¦ÂÃ Â¦Â¤ dome
        // Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦â€ Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€¡Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â¿Ã Â¦Â¤)
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: const _ConstellationsPainter()),
          ),
        ),
        // Ã Â¦Â®Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â®Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾
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

/// Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦â€¢Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¢Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â£Ã Â§ÂÃ Â¦Â¡Ã Â¦Â²Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â²Ã Â§â‚¬Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤, stylized Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨ Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡
/// Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡ Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦ÂÃ Â¦Â®Ã Â¦Â¨ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€“Ã Â§ÂÃ Â¦ÂÃ Â¦Â¤ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾-Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦Â®Ã Â¦Â¤
/// dome projection Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ RA/Dec Ã Â¦Â®Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¿Ã Â¦â€š Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â¤), Ã Â¦Â¬Ã Â¦Â°Ã Â¦â€š Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â°
/// Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Å¸Ã Â¦Â­Ã Â§â€šÃ Â¦Â®Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦â€ Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â° subtle Ã Â¦â€¡Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¸Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â¦Â¾
class _ConstellationsPainter extends CustomPainter {
  const _ConstellationsPainter();

  static const List<List<Offset>> _patterns = [
    // Ã Â¦Â¸Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â£Ã Â§ÂÃ Â¦Â¡Ã Â¦Â² (Ursa Major) Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â²Ã Â§â‚¬Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ "saucepan" Ã Â¦â€ Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤Ã Â¦Â¿
    [
      Offset(0.12, 0.14),
      Offset(0.17, 0.12),
      Offset(0.22, 0.135),
      Offset(0.27, 0.155),
      Offset(0.27, 0.19),
      Offset(0.22, 0.20),
      Offset(0.19, 0.175),
    ],
    // Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â· (Orion) Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â²Ã Â§â‚¬Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â²Ã Â§ÂÃ Â¦Å¸ Ã Â¦â€œ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â§/Ã Â¦ÂªÃ Â¦Â¾
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

/// Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦â€ºÃ Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¥ Ã¢â‚¬â€ Ã Â¦Â¨Ã Â¦Â°Ã Â¦Â®, Ã Â¦â€ºÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹Ã Â¦Â° Ã Â¦Â®Ã Â§â€¡Ã Â¦Ëœ
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

/// Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬ Ã Â¦â€ºÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§â€¡ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â®Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡; Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦â€ Ã Â¦Â­Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦Â°Ã Â¦Â¶Ã Â§ÂÃ Â¦Â®Ã Â¦Â¿ Ã Â¦â€ºÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
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
      // Ã Â¦Â®Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â®Ã Â¦Â¿Ã Â¦Å¸: Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬ Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦â€œ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â° Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨
      final wave = math.sin(
        (t * s.twinkleSpeed + s.twinklePhase) * 2 * math.pi,
      );
      final alpha = (s.baseAlpha * (0.72 + 0.28 * wave)).clamp(0.0, 1.0);

      // Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â² Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â°Ã Â¦Â® Ã Â¦â€ Ã Â¦Â­Ã Â¦Â¾
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

      // Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â² Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦Â¸Ã Â§â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â® Ã Â¦Â°Ã Â¦Â¶Ã Â§ÂÃ Â¦Â®Ã Â¦Â¿
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
    // Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° onboarding (Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â¾/Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾/Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â®/Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¶Ã Â¦Â¨) Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
    // Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª/Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€šÃ Â¦â€¢ Ã Â¦â€“Ã Â§â€¹Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€œÃ Â¦â€¡ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦â€ Ã Â¦Â° Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€
    // Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â® Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡
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
          'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾',
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
              'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â® Ã¢â‚¬Â¢ Welcome',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFFFD36E),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â¾ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            _buildGlassButton(context, 'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾'),
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
                    'Ã¢Å“Â¨ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤Ã Â¦Â¿',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD36E),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Ã Â¦ÂÃ Â¦â€¡ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡ Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¿ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿, Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â£, Ã Â¦ÂÃ Â¦Â¬Ã Â¦â€š Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â­ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¤Ã Â¦Â¾Ã Â¥Â¤',
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
                  'Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â‚¬ Ã Â¦Â§Ã Â¦Â¾Ã Â¦Âª',
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
    'Ã Â¦â€¢Ã Â¦Â²Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¾',
    'Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â€œÃ Â§Å“Ã Â¦Â¾',
    'Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â° Ã Â§Â¨Ã Â§Âª Ã Â¦ÂªÃ Â¦Â°Ã Â¦â€”Ã Â¦Â¨Ã Â¦Â¾',
    'Ã Â¦Â¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦Â£ Ã Â§Â¨Ã Â§Âª Ã Â¦ÂªÃ Â¦Â°Ã Â¦â€”Ã Â¦Â¨Ã Â¦Â¾',
    'Ã Â¦Â¹Ã Â§ÂÃ Â¦â€”Ã Â¦Â²Ã Â¦Â¿',
    'Ã Â¦Â¨Ã Â¦Â¦Ã Â¦Â¿Ã Â§Å¸Ã Â¦Â¾',
    'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¬ Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â§Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨',
    'Ã Â¦ÂªÃ Â¦Â¶Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â® Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â§Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨',
    'Ã Â¦Â®Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¶Ã Â¦Â¿Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦',
    'Ã Â¦Â¬Ã Â§â‚¬Ã Â¦Â°Ã Â¦Â­Ã Â§â€šÃ Â¦Â®',
    'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¬ Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â‚¬Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°',
    'Ã Â¦ÂªÃ Â¦Â¶Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â® Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â‚¬Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°',
    'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â§Å“Ã Â¦Â¾',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â²Ã Â¦Â¿Ã Â§Å¸Ã Â¦Â¾',
    'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¦Ã Â¦Â¾',
    'Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Å“Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°',
    'Ã Â¦Â¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦Â£ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Å“Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°',
    'Ã Â¦Å“Ã Â¦Â²Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€¡Ã Â¦â€”Ã Â§ÂÃ Â§Å“Ã Â¦Â¿',
    'Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€š',
    'Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¦Ã Â§ÂÃ Â§Å¸Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦â€¢Ã Â§â€¹Ã Â¦Å¡Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦ÂÃ Â¦Â¾Ã Â§Å“Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®',
    'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â¦â€š',
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
              'Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ã Â¦Â¸Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â§Å¸ Ã Â¦â€”Ã Â¦Â£Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§Å¸Ã Â§â€¹Ã Â¦Å“Ã Â¦Â¨',
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
                  'Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â‚¬ Ã Â¦Â§Ã Â¦Â¾Ã Â¦Âª',
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
                    'Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¤Ã Â¦Â¿',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD36E),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â£ Ã Â¦â€œ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â¬Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â¦Â°Ã Â§ÂÃ Â¦â€¢Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â®Ã Â§Å¸Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â§Â Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨Ã Â¥Â¤',
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
                      'Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
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
                    'Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¬',
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
      'name':
          'Ã Â¦â€¢Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¿Ã Â¦â€¢ (Ã Â¦Â¡Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²Ã Â§ÂÃ Â¦Å¸)',
      'color': Color(0xFF183F69),
    },
    {'name': 'Ã Â¦Â¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢', 'color': Color(0xFF0D0D0D)},
    {'name': 'Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Å¸', 'color': Color(0xFFFFF3D6)},
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
              'Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â® Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
                  'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
      'Ã°Å¸â„¢Â',
      'Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¤',
      'Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬, Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸, Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾',
    ),
    PanchangFeature(
      'Ã°Å¸â€Â®',
      'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²',
      'Ã Â§Â§Ã Â§Â¨ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿, Ã Â¦Â¦Ã Â§Ë†Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€œ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â¿Ã Â¦â€¢',
    ),
    PanchangFeature(
      'Ã°Å¸â€™Â',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
      'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹, Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶, Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¨',
    ),
    PanchangFeature(
      'Ã°Å¸Å’â€¢',
      'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾',
      'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯',
    ),
    PanchangFeature(
      'Ã°Å¸Å’â€˜',
      'Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
      'Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â§Å¸',
    ),
    PanchangFeature(
      'Ã°Å¸Å’â€™',
      'Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      'Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€œ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
    ),
    PanchangFeature(
      'Ã°Å¸Å’Å’',
      'Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã Â¦â€œ Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°',
      'Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€œ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
    ),
  ];

  // Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¡ Ã Â§ÂªÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â¡ Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â², Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¤ (Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨
  // Ã Â¦Â°Ã Â¦Â¥Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾ "Ã Â§Â¨Ã Â§Â­ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§Ë†Ã Â¦Â·Ã Â§ÂÃ Â¦Â " Ã¢â‚¬â€ Ã Â¦â€¦Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¢ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡Ã Â¦â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€”Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡)Ã Â¥Â¤ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ real Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/
  // Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â°-Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦â€ Ã Â¦Â°
  // Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦Â¡Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¿ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â² Ã Â¦Â¹Ã Â¦Â¤Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ (loop Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡)Ã Â¥Â¤
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
    // Ã Â§Â§Ã Â¦Â® Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â®Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ maxScrollExtent Ã Â¦Â¤Ã Â¦Â¤Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â£Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startFestivalAutoScroll();
    });
    // Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â® Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¢Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â®-Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€°Ã Â¦â€¡Ã Â¦Å“Ã Â§â€¡Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¡Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€œ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â¶ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
    HomeWidgetService.updateWidget();
  }

  @override
  void dispose() {
    _festivalAutoTimer?.cancel();
    _festivalScrollCtrl.dispose();
    super.dispose();
  }

  void _handleOpen(BuildContext context, String title) {
    if (title ==
        'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BengaliCalendarScreen()),
      );
      return;
    }
    // Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â² Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€ºÃ Â§â€¹Ã Â¦Å¸ Ã Â¦Â¬Ã Â¦Å¸Ã Â¦Â® Ã Â¦Â¶Ã Â§â‚¬Ã Â¦Å¸ Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â², Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦ÂªÃ Â§â€¡Ã Â¦Å“: Ã Â¦ËœÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Å¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°,
    // Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° real Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â² (Ã Â¦Â¸Ã Â¦Â¬ Ã Â§Â§Ã Â§Â¨Ã Â¦Å¸Ã Â¦Â¾) Ã Â¦â€œ Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®-Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“/Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®-Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â°
    // Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â° Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§Â Ã Â¦ÂÃ Â¦â€¢ Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
    if (title == 'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RashiScreen()),
      );
      return;
    }
    // Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â¶Ã Â§â‚¬Ã Â¦Å¸ Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â², Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â§â€¡ Ã Â§Â¨Ã Â¦Å¸Ã Â¦Â¾
    // Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¨ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Å¸Ã Â¦â€”Ã Â¦Â² Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦â€¡ real Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â°-Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
    if (title == 'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾' ||
        title == 'Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾') {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _MoonPhaseSheet(
          initialIsPurnima:
              title == 'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾',
        ),
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
      case 'Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReminderScreen()),
        );
        break;
      case 'Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¸':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotesScreen()),
        );
        break;
      case 'Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FamilyCalendarScreen()),
        );
        break;
      case 'Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â°':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BabyNamingScreen()),
        );
        break;
      case 'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShubhoMuhurtaScreen()),
        );
        break;
      case 'Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â®Ã Â§â€¡Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FestivalPosterScreen()),
        );
        break;
      case 'Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€” Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PanchangShareCardScreen()),
        );
        break;
      case 'Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¸':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
      case 'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â²':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
      case 'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â®':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
        break;
      case 'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShraddhaTithiScreen()),
        );
        break;
      case 'Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€œ Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¸Ã Â§â€šÃ Â¦Å¡Ã Â¦Â¿':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TempleScreen()),
        );
        break;
      case 'Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ PDF Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const _PremiumGate(
              featureTitle:
                  'Ã°Å¸â€œâ€ž Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ PDF Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸',
              child: PdfExportScreen(),
            ),
          ),
        );
        break;
      case 'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const _PremiumGate(
              featureTitle:
                  'Ã°Å¸ÂªÂ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸',
              child: KundliScreen(),
            ),
          ),
        );
        break;
      case 'Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¨':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const _PremiumGate(
              featureTitle:
                  'Ã°Å¸â€™Å¾ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¨',
              child: KundliMilanScreen(),
            ),
          ),
        );
        break;
      case 'Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const _PremiumGate(
              featureTitle:
                  'Ã¢ËœÂÃ¯Â¸Â Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª',
              child: CloudBackupScreen(),
            ),
          ),
        );
        break;
      case 'Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â°Ã Â§ÂÃ Â¦Â¶ Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const _PremiumGate(
              featureTitle:
                  'Ã°Å¸â€Â® Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â°Ã Â§ÂÃ Â¦Â¶ Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š',
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
                    'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾',
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
              const _SectionTitle(
                'Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”',
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  // GPS/Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€¦Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ (Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹
                  // Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡ GPS Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€¦Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â§ Ã Â¦â€¢Ã Â§â€¹-Ã Â¦â€¦Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å¸) Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡ Ã Â§Â©Ã Â¦Å¸Ã Â¦Â¾
                  // Ã Â¦Â«Ã Â¦Â¾Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾/Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¶ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¦Ã Â§â€¡ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¡Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²Ã Â§ÂÃ Â¦Å¸
                  // Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
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
                          emoji: 'Ã°Å¸Å’â€¦',
                          value: sunriseTxt,
                          label:
                              'Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼',
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _MiniPanchang(
                          emoji: 'Ã°Å¸Å’â€¡',
                          value: sunsetTxt,
                          label:
                              'Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤',
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _MiniPanchang(
                          emoji: 'Ã°Å¸Å’â„¢',
                          value: moonriseTxt,
                          label:
                              'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼',
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              const _SectionTitle(
                'Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°',
              ),
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
              const _SectionTitle(
                'Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦â€œ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 148,
                child: Listener(
                  // Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡ Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Å¡ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â² Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ auto-scroll Ã Â¦Â¥Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡
                  // Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦â€ºÃ Â§â€¡Ã Â¦Â¡Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡
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
              const _SectionTitle(
                'Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨',
              ),
              const SizedBox(height: 10),
              const _UpcomingFestivalsCard(count: 3),
              const SizedBox(height: 20),
              const _SectionTitle(
                'Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶ (Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â­)',
              ),
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
                  _handleOpen(context, 'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²');
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
// Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¡Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¸ Ã¢â‚¬â€ Ã Â¦â€°Ã Â¦Â²Ã Â§ÂÃ Â¦Â²Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â„¢Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿/Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®/Ã Â¦Â®Ã Â§Æ’Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â§Â
// Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ (Wikipedia Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾, Ã Â¦â€¡Ã Â¦â€šÃ Â¦Â°Ã Â§â€¡Ã Â¦Å“Ã Â¦Â¿ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬)
// =====================================================================

class _HistoricalFigure {
  final int month;
  final int day;
  final String name;
  final String role;
  final String
  eventType; // 'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®' Ã Â¦Â¬Ã Â¦Â¾ 'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£'
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
    'Ã Â¦Â°Ã Â¦Â¬Ã Â§â‚¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¥ Ã Â¦Â Ã Â¦Â¾Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°',
    'Ã Â¦â€¢Ã Â¦Â¬Ã Â¦Â¿ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢ (Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â²Ã Â¦Å“Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬)',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€œâ€“',
  ),
  _HistoricalFigure(
    8,
    7,
    'Ã Â¦Â°Ã Â¦Â¬Ã Â§â‚¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¥ Ã Â¦Â Ã Â¦Â¾Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°',
    'Ã Â¦â€¢Ã Â¦Â¬Ã Â¦Â¿ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢ (Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â²Ã Â¦Å“Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬)',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€œâ€“',
  ),
  _HistoricalFigure(
    5,
    25,
    'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“Ã Â§â‚¬ Ã Â¦Â¨Ã Â¦Å“Ã Â¦Â°Ã Â§ÂÃ Â¦Â² Ã Â¦â€¡Ã Â¦Â¸Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â®',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â¹Ã Â§â‚¬ Ã Â¦â€¢Ã Â¦Â¬Ã Â¦Â¿',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã¢Å“â€™Ã¯Â¸Â',
  ),
  _HistoricalFigure(
    8,
    29,
    'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“Ã Â§â‚¬ Ã Â¦Â¨Ã Â¦Å“Ã Â¦Â°Ã Â§ÂÃ Â¦Â² Ã Â¦â€¡Ã Â¦Â¸Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â®',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â¹Ã Â§â‚¬ Ã Â¦â€¢Ã Â¦Â¬Ã Â¦Â¿',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã¢Å“â€™Ã¯Â¸Â',
  ),
  _HistoricalFigure(
    1,
    23,
    'Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¿ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â­Ã Â¦Â¾Ã Â¦Â·Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â¬Ã Â¦Â¸Ã Â§Â',
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â¨Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    1,
    12,
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦',
    'Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§â‚¬ Ã Â¦â€œ Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¢â€°',
  ),
  _HistoricalFigure(
    7,
    4,
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦',
    'Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§â‚¬ Ã Â¦â€œ Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¢â€°',
  ),
  _HistoricalFigure(
    9,
    26,
    'Ã Â¦Ë†Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â¦Â°Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â°',
    'Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å“ Ã Â¦Â¸Ã Â¦â€šÃ Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€œÅ¡',
  ),
  _HistoricalFigure(
    7,
    29,
    'Ã Â¦Ë†Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â¦Â°Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â°',
    'Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å“ Ã Â¦Â¸Ã Â¦â€šÃ Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€œÅ¡',
  ),
  _HistoricalFigure(
    6,
    26,
    'Ã Â¦Â¬Ã Â¦â„¢Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦Â®Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Å¡Ã Â¦Å¸Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€“â€¹',
  ),
  _HistoricalFigure(
    4,
    8,
    'Ã Â¦Â¬Ã Â¦â„¢Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦Â®Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Å¡Ã Â¦Å¸Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€“â€¹',
  ),
  _HistoricalFigure(
    9,
    15,
    'Ã Â¦Â¶Ã Â¦Â°Ã Â§Å½Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Å¡Ã Â¦Å¸Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€“â€¹',
  ),
  _HistoricalFigure(
    1,
    16,
    'Ã Â¦Â¶Ã Â¦Â°Ã Â§Å½Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Å¡Ã Â¦Å¸Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€“â€¹',
  ),
  _HistoricalFigure(
    5,
    2,
    'Ã Â¦Â¸Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Å“Ã Â¦Â¿Ã Â§Å½ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Å¡Ã Â¦Â²Ã Â¦Å¡Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¾',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸Å½Â¬',
  ),
  _HistoricalFigure(
    4,
    23,
    'Ã Â¦Â¸Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Å“Ã Â¦Â¿Ã Â§Å½ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Å¡Ã Â¦Â²Ã Â¦Å¡Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¾',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸Å½Â¬',
  ),
  _HistoricalFigure(
    11,
    30,
    'Ã Â¦Å“Ã Â¦â€”Ã Â¦Â¦Ã Â§â‚¬Ã Â¦Â¶Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â¬Ã Â¦Â¸Ã Â§Â',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€Â¬',
  ),
  _HistoricalFigure(
    11,
    23,
    'Ã Â¦Å“Ã Â¦â€”Ã Â¦Â¦Ã Â§â‚¬Ã Â¦Â¶Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â¬Ã Â¦Â¸Ã Â§Â',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€Â¬',
  ),
  _HistoricalFigure(
    10,
    6,
    'Ã Â¦Â®Ã Â§â€¡Ã Â¦ËœÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â¦ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¾',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€Â¬',
  ),
  _HistoricalFigure(
    2,
    16,
    'Ã Â¦Â®Ã Â§â€¡Ã Â¦ËœÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â¦ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¾',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€Â¬',
  ),
  _HistoricalFigure(
    5,
    22,
    'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â®Ã Â§â€¹Ã Â¦Â¹Ã Â¦Â¨ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å“ Ã Â¦Â¸Ã Â¦â€šÃ Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€œÅ“',
  ),
  _HistoricalFigure(
    9,
    27,
    'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â®Ã Â§â€¹Ã Â¦Â¹Ã Â¦Â¨ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å“ Ã Â¦Â¸Ã Â¦â€šÃ Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€œÅ“',
  ),
  _HistoricalFigure(
    10,
    2,
    'Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â¦â€¢',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    1,
    30,
    'Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â¦â€¢',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    10,
    15,
    'Ã Â¦Â.Ã Â¦ÂªÃ Â¦Â¿.Ã Â¦Å“Ã Â§â€¡. Ã Â¦â€ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â² Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â®',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬ Ã Â¦â€œ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸Å¡â‚¬',
  ),
  _HistoricalFigure(
    7,
    27,
    'Ã Â¦Â.Ã Â¦ÂªÃ Â¦Â¿.Ã Â¦Å“Ã Â§â€¡. Ã Â¦â€ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â² Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â®',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬ Ã Â¦â€œ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸Å¡â‚¬',
  ),
  _HistoricalFigure(
    2,
    18,
    'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â®Ã Â¦Â¹Ã Â¦â€šÃ Â¦Â¸',
    'Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¢â€°',
  ),
  _HistoricalFigure(
    8,
    16,
    'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â®Ã Â¦Â¹Ã Â¦â€šÃ Â¦Â¸',
    'Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¢â€°',
  ),
  _HistoricalFigure(
    10,
    28,
    'Ã Â¦Â­Ã Â¦â€”Ã Â¦Â¿Ã Â¦Â¨Ã Â§â‚¬ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¤Ã Â¦Â¾',
    'Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸Â¤Â',
  ),
  _HistoricalFigure(
    10,
    13,
    'Ã Â¦Â­Ã Â¦â€”Ã Â¦Â¿Ã Â¦Â¨Ã Â§â‚¬ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¤Ã Â¦Â¾',
    'Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸Â¤Â',
  ),
  _HistoricalFigure(
    1,
    25,
    'Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â² Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¸Ã Â§â€šÃ Â¦Â¦Ã Â¦Â¨ Ã Â¦Â¦Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤',
    'Ã Â¦â€¢Ã Â¦Â¬Ã Â¦Â¿',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã¢Å“â€™Ã¯Â¸Â',
  ),
  _HistoricalFigure(
    6,
    29,
    'Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â² Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¸Ã Â§â€šÃ Â¦Â¦Ã Â¦Â¨ Ã Â¦Â¦Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤',
    'Ã Â¦â€¢Ã Â¦Â¬Ã Â¦Â¿',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã¢Å“â€™Ã¯Â¸Â',
  ),
  _HistoricalFigure(
    9,
    28,
    'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â£Ã Â¦Â¿',
    'Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸Ââ€º',
  ),
  _HistoricalFigure(
    2,
    19,
    'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â£Ã Â¦Â¿',
    'Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸Ââ€º',
  ),
  _HistoricalFigure(
    11,
    5,
    'Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¨ Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â¶',
    'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    6,
    16,
    'Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¨ Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â¶',
    'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    12,
    3,
    'Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¬Ã Â¦Â¸Ã Â§Â',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â‚¬ (Ã Â¦Â«Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¸Ã Â¦Â¿)',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    8,
    11,
    'Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¬Ã Â¦Â¸Ã Â§Â',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â‚¬ (Ã Â¦Â«Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¸Ã Â¦Â¿)',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    9,
    29,
    'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â¿Ã Â¦Â¨Ã Â§â‚¬ Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â°Ã Â¦Â¾',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    12,
    9,
    'Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€”Ã Â¦Â® Ã Â¦Â°Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾',
    'Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å“ Ã Â¦Â¸Ã Â¦â€šÃ Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€œÅ¡',
  ),
  _HistoricalFigure(
    2,
    17,
    'Ã Â¦Å“Ã Â§â‚¬Ã Â¦Â¬Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦ Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â¶',
    'Ã Â¦â€¢Ã Â¦Â¬Ã Â¦Â¿',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã¢Å“â€™Ã¯Â¸Â',
  ),
  _HistoricalFigure(
    10,
    22,
    'Ã Â¦Å“Ã Â§â‚¬Ã Â¦Â¬Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦ Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â¶',
    'Ã Â¦â€¢Ã Â¦Â¬Ã Â¦Â¿',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã¢Å“â€™Ã¯Â¸Â',
  ),
  _HistoricalFigure(
    8,
    2,
    'Ã Â¦â€ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â«Ã Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â²Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€Â¬',
  ),
  _HistoricalFigure(
    6,
    16,
    'Ã Â¦â€ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â«Ã Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â²Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€Â¬',
  ),
  _HistoricalFigure(
    7,
    1,
    'Ã Â¦Â¡Ã Â¦Â¾. Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Å¡Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¿Ã Â§Å½Ã Â¦Â¸Ã Â¦â€¢ Ã Â¦â€œ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦â€œ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã¢Å¡â€¢Ã¯Â¸Â',
  ),
  _HistoricalFigure(
    3,
    22,
    'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¨',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â‚¬ (Ã Â¦Â«Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¸Ã Â¦Â¿)',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    1,
    12,
    'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¨',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â‚¬ (Ã Â¦Â«Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¸Ã Â¦Â¿)',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    5,
    5,
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â‚¬Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    9,
    24,
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â‚¬Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    7,
    18,
    'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨Ã Â§â‚¬ Ã Â¦â€”Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â® Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬ Ã Â¦Å¡Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¿Ã Â§Å½Ã Â¦Â¸Ã Â¦â€¢',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã¢Å¡â€¢Ã¯Â¸Â',
  ),
  _HistoricalFigure(
    10,
    3,
    'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨Ã Â§â‚¬ Ã Â¦â€”Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â® Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬ Ã Â¦Å¡Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¿Ã Â§Å½Ã Â¦Â¸Ã Â¦â€¢',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã¢Å¡â€¢Ã¯Â¸Â',
  ),
  _HistoricalFigure(
    8,
    26,
    'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¾',
    'Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â‚¬ (Ã Â¦â€¢Ã Â¦Â²Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¾)',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸Â¤Â',
  ),
  _HistoricalFigure(
    9,
    5,
    'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¾',
    'Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â‚¬ (Ã Â¦â€¢Ã Â¦Â²Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¾)',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸Â¤Â',
  ),
  _HistoricalFigure(
    8,
    18,
    'Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¿ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â­Ã Â¦Â¾Ã Â¦Â·Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â¬Ã Â¦Â¸Ã Â§Â',
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â¨Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    11,
    7,
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¿Ã Â¦Â¨Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â²',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â‚¬ (Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â²-Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â²-Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â²)',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    5,
    20,
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¿Ã Â¦Â¨Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â²',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â‚¬ (Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â²-Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â²-Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â²)',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    7,
    23,
    'Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦â„¢Ã Â§ÂÃ Â¦â€¢Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€“â€¹',
  ),
  _HistoricalFigure(
    9,
    14,
    'Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦â„¢Ã Â§ÂÃ Â¦â€¢Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€“â€¹',
  ),
  _HistoricalFigure(
    5,
    19,
    'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€“â€¹',
  ),
  _HistoricalFigure(
    12,
    3,
    'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€“â€¹',
  ),
  _HistoricalFigure(
    9,
    12,
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â­Ã Â§â€šÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â­Ã Â§â€šÃ Â¦Â·Ã Â¦Â£ Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢ (Ã Â¦ÂªÃ Â¦Â¥Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â¾Ã Â¦ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â§â‚¬)',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€“â€¹',
  ),
  _HistoricalFigure(
    11,
    1,
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â­Ã Â§â€šÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â­Ã Â§â€šÃ Â¦Â·Ã Â¦Â£ Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢ (Ã Â¦ÂªÃ Â¦Â¥Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â¾Ã Â¦ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â§â‚¬)',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€“â€¹',
  ),
  _HistoricalFigure(
    11,
    4,
    'Ã Â¦â€¹Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ËœÃ Â¦Å¸Ã Â¦â€¢',
    'Ã Â¦Å¡Ã Â¦Â²Ã Â¦Å¡Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¾',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸Å½Â¬',
  ),
  _HistoricalFigure(
    2,
    6,
    'Ã Â¦â€¹Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ËœÃ Â¦Å¸Ã Â¦â€¢',
    'Ã Â¦Å¡Ã Â¦Â²Ã Â¦Å¡Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¾',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸Å½Â¬',
  ),
  _HistoricalFigure(
    5,
    14,
    'Ã Â¦Â®Ã Â§Æ’Ã Â¦Â£Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¨',
    'Ã Â¦Å¡Ã Â¦Â²Ã Â¦Å¡Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¾',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸Å½Â¬',
  ),
  _HistoricalFigure(
    12,
    30,
    'Ã Â¦Â®Ã Â§Æ’Ã Â¦Â£Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¨',
    'Ã Â¦Å¡Ã Â¦Â²Ã Â¦Å¡Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¾',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸Å½Â¬',
  ),
  _HistoricalFigure(
    4,
    7,
    'Ã Â¦ÂªÃ Â¦Â£Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â¦â„¢Ã Â§ÂÃ Â¦â€¢Ã Â¦Â°',
    'Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦Ã Â¦â€¢',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸Å½Â¶',
  ),
  _HistoricalFigure(
    12,
    11,
    'Ã Â¦ÂªÃ Â¦Â£Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â¦â„¢Ã Â§ÂÃ Â¦â€¢Ã Â¦Â°',
    'Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦Ã Â¦â€¢',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸Å½Â¶',
  ),
  _HistoricalFigure(
    9,
    3,
    'Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â® Ã Â¦â€¢Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â¾ (Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€¢)',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸Å½Â­',
  ),
  _HistoricalFigure(
    7,
    24,
    'Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â® Ã Â¦â€¢Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â¾ (Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€¢)',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸Å½Â­',
  ),
  _HistoricalFigure(
    4,
    6,
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¨',
    'Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬ (Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾)',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸Å½Â­',
  ),
  _HistoricalFigure(
    1,
    17,
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¨',
    'Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬ (Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾)',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸Å½Â­',
  ),
  _HistoricalFigure(
    6,
    16,
    'Ã Â¦Â¹Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â®Ã Â§ÂÃ Â¦â€“Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¸Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â§â‚¬Ã Â¦Â¤Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â²Ã Â§ÂÃ Â¦ÂªÃ Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸Å½Â¤',
  ),
  _HistoricalFigure(
    9,
    26,
    'Ã Â¦Â¹Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â®Ã Â§ÂÃ Â¦â€“Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¸Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â§â‚¬Ã Â¦Â¤Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â²Ã Â§ÂÃ Â¦ÂªÃ Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸Å½Â¤',
  ),
  _HistoricalFigure(
    8,
    4,
    'Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¹Ã Â¦Â° Ã Â¦â€¢Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦Â¸Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â§â‚¬Ã Â¦Â¤Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â²Ã Â§ÂÃ Â¦ÂªÃ Â§â‚¬ Ã Â¦â€œ Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â¾',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸Å½Â¤',
  ),
  _HistoricalFigure(
    10,
    13,
    'Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¹Ã Â¦Â° Ã Â¦â€¢Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦Â¸Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â§â‚¬Ã Â¦Â¤Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â²Ã Â§ÂÃ Â¦ÂªÃ Â§â‚¬ Ã Â¦â€œ Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â¾',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸Å½Â¤',
  ),
  _HistoricalFigure(
    5,
    1,
    'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¦Ã Â§â€¡',
    'Ã Â¦Â¸Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â§â‚¬Ã Â¦Â¤Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â²Ã Â§ÂÃ Â¦ÂªÃ Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸Å½Â¤',
  ),
  _HistoricalFigure(
    10,
    24,
    'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¦Ã Â§â€¡',
    'Ã Â¦Â¸Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â§â‚¬Ã Â¦Â¤Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â²Ã Â§ÂÃ Â¦ÂªÃ Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸Å½Â¤',
  ),
  _HistoricalFigure(
    6,
    29,
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¤Ã Â§â€¹Ã Â¦Â· Ã Â¦Â®Ã Â§ÂÃ Â¦â€“Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¶Ã Â¦Â¿Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸Å½â€œ',
  ),
  _HistoricalFigure(
    5,
    25,
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¤Ã Â§â€¹Ã Â¦Â· Ã Â¦Â®Ã Â§ÂÃ Â¦â€“Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦Â¶Ã Â¦Â¿Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸Å½â€œ',
  ),
  _HistoricalFigure(
    9,
    27,
    'Ã Â¦Â­Ã Â¦â€”Ã Â§Å½ Ã Â¦Â¸Ã Â¦Â¿Ã Â¦â€š',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â‚¬ (Ã Â¦Â«Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¸Ã Â¦Â¿)',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    3,
    23,
    'Ã Â¦Â­Ã Â¦â€”Ã Â§Å½ Ã Â¦Â¸Ã Â¦Â¿Ã Â¦â€š',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â‚¬ (Ã Â¦Â«Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¸Ã Â¦Â¿)',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    11,
    14,
    'Ã Â¦Å“Ã Â¦â€œÃ Â¦Â¹Ã Â¦Â°Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¹Ã Â¦Â°Ã Â§Â',
    'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â® Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    5,
    27,
    'Ã Â¦Å“Ã Â¦â€œÃ Â¦Â¹Ã Â¦Â°Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¹Ã Â¦Â°Ã Â§Â',
    'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â® Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    10,
    31,
    'Ã Â¦Â¸Ã Â¦Â°Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â²Ã Â§ÂÃ Â¦Â²Ã Â¦Â­Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â²',
    'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€¢',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    12,
    15,
    'Ã Â¦Â¸Ã Â¦Â°Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â²Ã Â§ÂÃ Â¦Â²Ã Â¦Â­Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â²',
    'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€¢',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    4,
    14,
    'Ã Â¦Â¡Ã Â¦Æ’ Ã Â¦Â­Ã Â§â‚¬Ã Â¦Â®Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€œ Ã Â¦â€ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â§â€¡Ã Â¦Â¦Ã Â¦â€¢Ã Â¦Â°',
    'Ã Â¦Â¸Ã Â¦â€šÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â£Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â¾',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã¢Å¡â€“Ã¯Â¸Â',
  ),
  _HistoricalFigure(
    12,
    6,
    'Ã Â¦Â¡Ã Â¦Æ’ Ã Â¦Â­Ã Â§â‚¬Ã Â¦Â®Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€œ Ã Â¦â€ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â§â€¡Ã Â¦Â¦Ã Â¦â€¢Ã Â¦Â°',
    'Ã Â¦Â¸Ã Â¦â€šÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â£Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â¾',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã¢Å¡â€“Ã¯Â¸Â',
  ),
  _HistoricalFigure(
    10,
    2,
    'Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â¶Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    1,
    11,
    'Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â¶Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    11,
    19,
    'Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¾ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    10,
    31,
    'Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¾ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    8,
    20,
    'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Å“Ã Â§â‚¬Ã Â¦Â¬ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    5,
    21,
    'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Å“Ã Â§â‚¬Ã Â¦Â¬ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    7,
    23,
    'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â¶Ã Â§â€¡Ã Â¦â€“Ã Â¦Â° Ã Â¦â€ Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¦',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    2,
    27,
    'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â¶Ã Â§â€¡Ã Â¦â€“Ã Â¦Â° Ã Â¦â€ Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¦',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
  ),
  _HistoricalFigure(
    11,
    7,
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¿.Ã Â¦Â­Ã Â¦Â¿. Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¨',
    'Ã Â¦ÂªÃ Â¦Â¦Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬ (Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â²Ã Â¦Å“Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬)',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€Â¬',
  ),
  _HistoricalFigure(
    11,
    21,
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¿.Ã Â¦Â­Ã Â¦Â¿. Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¨',
    'Ã Â¦ÂªÃ Â¦Â¦Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬ (Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â²Ã Â¦Å“Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬)',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€Â¬',
  ),
  _HistoricalFigure(
    1,
    1,
    'Ã Â¦Â¸Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¥ Ã Â¦Â¬Ã Â¦Â¸Ã Â§Â',
    'Ã Â¦ÂªÃ Â¦Â¦Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€Â¬',
  ),
  _HistoricalFigure(
    2,
    4,
    'Ã Â¦Â¸Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¥ Ã Â¦Â¬Ã Â¦Â¸Ã Â§Â',
    'Ã Â¦ÂªÃ Â¦Â¦Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€Â¬',
  ),
  _HistoricalFigure(
    10,
    30,
    'Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â®Ã Â¦Â¿ Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â§â‚¬Ã Â¦Â° Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¾',
    'Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â£Ã Â§Â Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã¢Å¡â€ºÃ¯Â¸Â',
  ),
  _HistoricalFigure(
    1,
    24,
    'Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â®Ã Â¦Â¿ Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â§â‚¬Ã Â¦Â° Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¾',
    'Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â£Ã Â§Â Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã¢Å¡â€ºÃ¯Â¸Â',
  ),
  _HistoricalFigure(
    2,
    13,
    'Ã Â¦Â¸Ã Â¦Â°Ã Â§â€¹Ã Â¦Å“Ã Â¦Â¿Ã Â¦Â¨Ã Â§â‚¬ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¡Ã Â§Â',
    'Ã Â¦â€¢Ã Â¦Â¬Ã Â¦Â¿ Ã Â¦â€œ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â¨Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸Å’Â¸',
  ),
  _HistoricalFigure(
    3,
    2,
    'Ã Â¦Â¸Ã Â¦Â°Ã Â§â€¹Ã Â¦Å“Ã Â¦Â¿Ã Â¦Â¨Ã Â§â‚¬ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¡Ã Â§Â',
    'Ã Â¦â€¢Ã Â¦Â¬Ã Â¦Â¿ Ã Â¦â€œ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â¨Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸Å’Â¸',
  ),
  _HistoricalFigure(
    8,
    15,
    'Ã Â¦â€¹Ã Â¦Â·Ã Â¦Â¿ Ã Â¦â€¦Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦',
    'Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€œ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¢â€°',
  ),
  _HistoricalFigure(
    12,
    5,
    'Ã Â¦â€¹Ã Â¦Â·Ã Â¦Â¿ Ã Â¦â€¦Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦',
    'Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€œ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€¢â€°',
  ),
  _HistoricalFigure(
    1,
    14,
    'Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¬Ã Â§â‚¬',
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å“Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€“â€¹',
  ),
  _HistoricalFigure(
    7,
    28,
    'Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¬Ã Â§â‚¬',
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å“Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€“â€¹',
  ),
  _HistoricalFigure(
    9,
    7,
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¨Ã Â§â‚¬Ã Â¦Â² Ã Â¦â€”Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦â€¢Ã Â¦Â¬Ã Â¦Â¿ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€“â€¹',
  ),
  _HistoricalFigure(
    10,
    23,
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¨Ã Â§â‚¬Ã Â¦Â² Ã Â¦â€”Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â§â€¹Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼',
    'Ã Â¦â€¢Ã Â¦Â¬Ã Â¦Â¿ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â£',
    'Ã°Å¸â€“â€¹',
  ),
  _HistoricalFigure(
    8,
    19,
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â§Ã Â¦Â¾ Ã Â¦Â®Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿',
    'Ã Â¦Â²Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â‚¬',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€œâ€“',
  ),
  _HistoricalFigure(
    8,
    19,
    'Ã Â¦ÂÃ Â¦Â¸. Ã Â¦Â¸Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â®Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿',
    'Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¨Ã Â¦Å“Ã Â§â‚¬Ã Â¦Â¬Ã Â§â‚¬ Ã Â¦â€œ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦',
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
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

  // Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â§â€¡Ã Â¦â€¡ (Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨+Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸) Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®/Ã Â¦Â®Ã Â§Æ’Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€¡
  // Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡, Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€°Ã Â¦â€¢Ã Â§â€¡ "Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â°" Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡
  // Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â² Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â°Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â²Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¬Ã Â§â€¡ (Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡ _items.isEmpty Ã Â¦Å¡Ã Â§â€¡Ã Â¦â€¢)Ã Â¥Â¤
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
                                'Ã Â¦â€ Ã Â¦Å“',
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
                            ? 'Ã Â¦â€ Ã Â¦Å“ ${f.eventType}Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨'
                            : '${bnNum(f.day)} ${gregMonthBn(f.month)} Ã¢â‚¬Â¢ ${f.eventType}Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
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
      subject:
          'Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€” Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾',
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
                  'Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
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
            '$weekday Ã¢â‚¬Â¢ ${bnNum(now.day)} ${gregMonthBn(now.month)} ${bnNum(now.year)}',
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
              '${tithi.paksha} Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â· Ã¢â‚¬Â¢ ${tithi.name} Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿',
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
              // Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¸Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²/Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨/Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾/Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤/Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾/Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾/Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£ Ã¢â‚¬â€
              // Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â²Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â², Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ real Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¤
              // Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€œ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/
              // Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¬ Ã Â¦Â¯Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾ "Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â­ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯"-Ã Â¦Â¤Ã Â§â€¡
              // Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ (PanchangCalculator.sunTimes), Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨
              // calculation Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿Ã Â¥Â¤
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
                    _modeChip(
                      'Ã°Å¸Å’â€¦ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼ ${bnTime12(sun.sunrise)}',
                    ),
                    _modeChip(
                      'Ã°Å¸Å’â€¡ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ ${bnTime12(sun.sunset)}',
                    ),
                    _modeChip(
                      'Ã¢Â­Â Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° ${PanchangCalculator.nakshatraNames[nakIdx]}',
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

/// Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â® Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ "Ã Â¦â€ Ã Â¦Å“" Ã Â¦â€ Ã Â¦Â° "Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²" Ã¢â‚¬â€ Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¥Â¤
/// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿, Ã Â¦â€ Ã Â¦Â° Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¯Ã Â¦Â¤ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬/Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â²Ã Â¦Â¨-Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨
/// Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ (BengaliCalendarData.eventsFor Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡) Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦â€¡ Ã Â¦â€ºÃ Â§â€¹Ã Â¦Å¸ Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Âª
/// Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â®Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
class _TodayTomorrowBoxes extends StatelessWidget {
  const _TodayTomorrowBoxes();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    // IntrinsicHeight + CrossAxisAlignment.stretch Ã¢â‚¬â€ Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹ Ã Â¦Â¬Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¨Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸
    // (Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€“Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾) Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ, Ã Â¦â€ºÃ Â§â€¹Ã Â¦Å¸ Ã Â¦Â¬Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€°Ã Â¦Å¡Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
    // Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¨-Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¸Ã Â§â€¡, Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ "Ã Â¦â€ Ã Â¦Å“" Ã Â¦â€ Ã Â¦Â° "Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²" Ã Â¦Â¬Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â§â€¡Ã Â¥Â¤
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _dayBox(
              label: 'Ã Â¦â€ Ã Â¦Å“',
              date: now,
              accent: const Color(0xFFFFD36E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _dayBox(
              label: 'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²',
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
            '${bnNum(bengaliDay)} ${info.name} Ã¢â‚¬Â¢ $weekday',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            '${tithi.paksha} Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â· Ã¢â‚¬Â¢ ${tithi.name} Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿',
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
              'Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡',
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
      'Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼ ${bnTime12(sun.sunrise)}',
      'Ã°Å¸Å’â€¡ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ ${bnTime12(sun.sunset)}',
      'Ã°Å¸Å’â„¢ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼ ${bnTime12(moonrise)}',
      'Ã°Å¸Å’â€” Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ ${bnTime12(moonset)}',
      'Ã°Å¸â€¢â€° Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿: ${tithi.paksha} Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â· Ã¢â‚¬Â¢ ${tithi.name}',
      'Ã¢Â­Â Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°: ${PanchangCalculator.nakshatraNames[nakIdx]}',
      'Ã°Å¸ÂªÂ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿: ${PanchangCalculator.rashiNames[rashiIdx]}',
      'Ã¢ÂÂ³ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â² ${bnTime12(rahu['start']!)}Ã¢â‚¬â€œ${bnTime12(rahu['end']!)}',
      if (abhijit['applicable'] == true)
        'Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¿Ã Â§Å½ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ ${bnTime12(abhijit['start'] as DateTime)}Ã¢â‚¬â€œ${bnTime12(abhijit['end'] as DateTime)}'
      else
        'Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¿Ã Â§Å½ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€ Ã Â¦Å“ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â§â€¹Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Â¬Ã Â§ÂÃ Â¦Â§Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°)',
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
            'Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â­ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯',
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
        ? 'Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¿Ã Â§Å½ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ ${bnTime12(abhijit['start'] as DateTime)}Ã¢â‚¬â€œ${bnTime12(abhijit['end'] as DateTime)} Ã¢â‚¬Â¢ '
        : '';
    return 'Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼ ${bnTime12(sun.sunrise)} Ã¢â‚¬Â¢ '
        'Ã°Å¸Å’â€¡ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ ${bnTime12(sun.sunset)} Ã¢â‚¬Â¢ '
        'Ã¢ÂÂ³ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â² ${bnTime12(rahu['start']!)}Ã¢â‚¬â€œ${bnTime12(rahu['end']!)} Ã¢â‚¬Â¢ '
        '${abhijitText}Ã Â¦â€ Ã Â¦Å“ ${tithi.name} Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã¢â‚¬Â¢ '
        'Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°: ${PanchangCalculator.nakshatraNames[nakIdx]}';
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

/// Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â® Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° "Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬" Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®/Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡, Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡
/// "Ã Â¦â€ Ã Â¦Å“" / "Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²" / "X Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿" Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨ Ã Â¦â€ Ã Â¦Â° Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°-Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¨Ã Â¦â€œ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
class _UpcomingFestivalsCard extends StatelessWidget {
  final int count;
  const _UpcomingFestivalsCard({this.count = 3});

  String _countdownLabel(int daysLeft) {
    if (daysLeft <= 0) return 'Ã Â¦â€ Ã Â¦Å“';
    if (daysLeft == 1) return 'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²';
    return '${bnNum(daysLeft)} Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿';
  }

  void _shareFestival(
    String icon,
    String title,
    String date,
    String countdown,
  ) {
    Share.share(
      '$icon Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ $title\nÃ°Å¸â€œâ€¦ $date Ã¢â‚¬Â¢ $countdown\n\nÃ°Å¸â€œÂ² Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡',
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
          'Ã°Å¸Å’Â Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨',
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
          final icon = f['icon'] ?? 'Ã°Å¸Å½â€°';
          final title = f['title'] ?? '';
          final date = f['date'] ?? 'Ã Â¦Â¶Ã Â§â‚¬Ã Â¦ËœÃ Â§ÂÃ Â¦Â°Ã Â¦â€¡';
          final daysLeft = int.tryParse(f['daysLeft'] ?? '') ?? 0;
          final countdown = _countdownLabel(daysLeft);
          // Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬ Ã Â¦â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾ illustration (Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡)
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

/// Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â§â€¡ Ã Â§Â¨Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Å¸Ã Â¦â€”Ã Â¦Â² Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¨ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹
/// Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â¶Ã Â§â‚¬Ã Â¦Å¸ Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â²)Ã Â¥Â¤ Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦â€¡ real Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼,
/// Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€ Ã Â¦Â° Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤
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
    final title = _isPurnima
        ? 'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾'
        : 'Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾';
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
                        label:
                            'Ã°Å¸Å’â€¢ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾',
                        selected: _isPurnima,
                        onTap: () => setState(() => _isPurnima = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _moonToggleButton(
                        label:
                            'Ã°Å¸Å’â€˜ Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
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
                              'Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿Ã Â¥Â¤',
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
                            '$title Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¡ demo screen Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“ Ã Â¦â€¢Ã Â¦Â°Ã Â¦â€ºÃ Â§â€¡Ã Â¥Â¤ Final app-Ã Â¦Â live database/API data Ã Â¦Â¯Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡Ã Â¥Â¤',
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

  // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â² Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¡ Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â° (Ã¢ËœÂ°) Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡, Ã Â¦â€ Ã Â¦Â°
  // Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§â€¡Ã Â¦Å“Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¶Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å¸ Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡
  static const _navs = [
    ['Ã°Å¸ÂÂ ', 'Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â®'],
    [
      'Ã°Å¸â€œâ€¦',
      'Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
    ],
    ['Ã°Å¸ÂªÂ·', 'Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾'],
    ['Ã°Å¸â€Â®', 'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿'],
    ['Ã¢Å“Â¨', 'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â®'],
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

/// Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â­Ã Â¦Â¿Ã Â¦â€”Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¾Ã Â¦ÂÃ Â§â€¡Ã Â¦Â° Ã Â¦â€”Ã Â§â€¹Ã Â¦Â² Ã Â¦Â¬Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¿Ã Â¦Â° 'Ã¢Å“Â¦' Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â² Ã¢â‚¬â€
/// Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€ºÃ Â§â€¹Ã Â¦Å¸Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¸Ã Â¦Å¡Ã Â¦Â² Ã Â¦â€¢Ã Â¦Â¾Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¾ (Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â²Ã Â¦â€”) Ã Â¦ËœÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿ Ã Â¦â€ Ã Â¦â€ºÃ Â§â€¡, Ã Â¦Â¯Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾
/// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â§â€¡ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ (IST, UTC+5:30 Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â° Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡, DST Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡)
/// Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦ËœÃ Â¦Â£Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾/Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¸/Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¾Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦ËœÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
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

    // Ã Â¦ËœÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¡Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²
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

    // Ã Â§Â§Ã Â§Â¨Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦ËœÃ Â¦Â£Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¾Ã Â¦â€”
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

    // Ã Â§Â§Ã Â§Â¨, Ã Â§Â©, Ã Â§Â¬, Ã Â§Â¯ Ã¢â‚¬â€ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦Å¸Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦ËœÃ Â¦Â£Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€“Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦Â¡Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡
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
// Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬ Ã Â¦ËœÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿ (World Clock) Ã¢â‚¬â€ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â­Ã Â¦Â¿Ã Â¦â€”Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦ËœÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿-Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â²Ã Â§â€¡ Ã Â¦â€“Ã Â§â€¹Ã Â¦Â²Ã Â§â€¡
// =====================================================================

/// Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¶/Ã Â¦Â¶Ã Â¦Â¹Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° real Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â®Ã Â¦Å“Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã¢â‚¬â€ IANA Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â®Ã Â¦Å“Ã Â§â€¹Ã Â¦Â¨ Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿ (tzId) Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡
/// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦â€¦Ã Â¦Â«Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ (DST-Ã Â¦Â¸Ã Â¦Â¹, Ã Â¦Â¯Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â§â€¹Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯) Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼; Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â®Ã Â¦Å“Ã Â§â€¹Ã Â¦Â¨
/// Ã Â¦Â¡Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¸ Ã Â¦Â²Ã Â§â€¹Ã Â¦Â¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ [fallbackOffset] (Ã Â¦ËœÃ Â¦Â£Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼) Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
class _WorldCity {
  final String name;
  final String flag;
  final String tzId;
  final double fallbackOffset;
  const _WorldCity(this.name, this.flag, this.tzId, this.fallbackOffset);
}

const List<_WorldCity> _worldCities = [
  _WorldCity(
    'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
    'Asia/Kolkata',
    5.5,
  ),
  _WorldCity(
    'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¶',
    'Ã°Å¸â€¡Â§Ã°Å¸â€¡Â©',
    'Asia/Dhaka',
    6.0,
  ),
  _WorldCity(
    'Ã Â¦Â¨Ã Â§â€¡Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â²',
    'Ã°Å¸â€¡Â³Ã°Å¸â€¡Âµ',
    'Asia/Kathmandu',
    5.75,
  ),
  _WorldCity(
    'Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾Ã Â¦Â¨',
    'Ã°Å¸â€¡ÂµÃ°Å¸â€¡Â°',
    'Asia/Karachi',
    5.0,
  ),
  _WorldCity(
    'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬Ã Â¦Â²Ã Â¦â„¢Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾',
    'Ã°Å¸â€¡Â±Ã°Å¸â€¡Â°',
    'Asia/Colombo',
    5.5,
  ),
  _WorldCity(
    'Ã Â¦Â¯Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Â¾Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯',
    'Ã°Å¸â€¡Â¬Ã°Å¸â€¡Â§',
    'Europe/London',
    0.0,
  ),
  _WorldCity(
    'Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¸',
    'Ã°Å¸â€¡Â«Ã°Å¸â€¡Â·',
    'Europe/Paris',
    1.0,
  ),
  _WorldCity(
    'Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿',
    'Ã°Å¸â€¡Â©Ã°Å¸â€¡Âª',
    'Europe/Berlin',
    1.0,
  ),
  _WorldCity(
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â§â€¡Ã Â¦Â¨',
    'Ã°Å¸â€¡ÂªÃ°Å¸â€¡Â¸',
    'Europe/Madrid',
    1.0,
  ),
  _WorldCity(
    'Ã Â¦â€¡Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â¹',
    'Europe/Rome',
    1.0,
  ),
  _WorldCity(
    'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ (Ã Â¦Â®Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§â€¹)',
    'Ã°Å¸â€¡Â·Ã°Å¸â€¡Âº',
    'Europe/Moscow',
    3.0,
  ),
  _WorldCity(
    'Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢',
    'Ã°Å¸â€¡Â¹Ã°Å¸â€¡Â·',
    'Europe/Istanbul',
    3.0,
  ),
  _WorldCity(
    'Ã Â¦Â¸Ã Â¦â€šÃ Â¦Â¯Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€ Ã Â¦Â°Ã Â¦Â¬ Ã Â¦â€ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤',
    'Ã°Å¸â€¡Â¦Ã°Å¸â€¡Âª',
    'Asia/Dubai',
    4.0,
  ),
  _WorldCity(
    'Ã Â¦Â¸Ã Â§Å’Ã Â¦Â¦Ã Â¦Â¿ Ã Â¦â€ Ã Â¦Â°Ã Â¦Â¬',
    'Ã°Å¸â€¡Â¸Ã°Å¸â€¡Â¦',
    'Asia/Riyadh',
    3.0,
  ),
  _WorldCity('Ã Â¦Å¡Ã Â§â‚¬Ã Â¦Â¨', 'Ã°Å¸â€¡Â¨Ã°Å¸â€¡Â³', 'Asia/Shanghai', 8.0),
  _WorldCity(
    'Ã Â¦Å“Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¨',
    'Ã°Å¸â€¡Â¯Ã°Å¸â€¡Âµ',
    'Asia/Tokyo',
    9.0,
  ),
  _WorldCity(
    'Ã Â¦Â¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦Â£ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾',
    'Ã°Å¸â€¡Â°Ã°Å¸â€¡Â·',
    'Asia/Seoul',
    9.0,
  ),
  _WorldCity(
    'Ã Â¦Â¸Ã Â¦Â¿Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â¾Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°',
    'Ã°Å¸â€¡Â¸Ã°Å¸â€¡Â¬',
    'Asia/Singapore',
    8.0,
  ),
  _WorldCity(
    'Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾',
    'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â©',
    'Asia/Jakarta',
    7.0,
  ),
  _WorldCity(
    'Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡',
    'Ã°Å¸â€¡Â¹Ã°Å¸â€¡Â­',
    'Asia/Bangkok',
    7.0,
  ),
  _WorldCity(
    'Ã Â¦Â¯Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â° (Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€° Ã Â¦â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢)',
    'Ã°Å¸â€¡ÂºÃ°Å¸â€¡Â¸',
    'America/New_York',
    -5.0,
  ),
  _WorldCity(
    'Ã Â¦Â¯Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â° (Ã Â¦Â²Ã Â¦Â¸ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¸)',
    'Ã°Å¸â€¡ÂºÃ°Å¸â€¡Â¸',
    'America/Los_Angeles',
    -8.0,
  ),
  _WorldCity(
    'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¾',
    'Ã°Å¸â€¡Â¨Ã°Å¸â€¡Â¦',
    'America/Toronto',
    -5.0,
  ),
  _WorldCity(
    'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¿Ã Â¦Â²',
    'Ã°Å¸â€¡Â§Ã°Å¸â€¡Â·',
    'America/Sao_Paulo',
    -3.0,
  ),
  _WorldCity(
    'Ã Â¦Â®Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¹',
    'Ã°Å¸â€¡Â²Ã°Å¸â€¡Â½',
    'America/Mexico_City',
    -6.0,
  ),
  _WorldCity(
    'Ã Â¦Â¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦Â£ Ã Â¦â€ Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾',
    'Ã°Å¸â€¡Â¿Ã°Å¸â€¡Â¦',
    'Africa/Johannesburg',
    2.0,
  ),
  _WorldCity(
    'Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¶Ã Â¦Â°',
    'Ã°Å¸â€¡ÂªÃ°Å¸â€¡Â¬',
    'Africa/Cairo',
    2.0,
  ),
  _WorldCity(
    'Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ (Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â¡Ã Â¦Â¨Ã Â¦Â¿)',
    'Ã°Å¸â€¡Â¦Ã°Å¸â€¡Âº',
    'Australia/Sydney',
    11.0,
  ),
  _WorldCity(
    'Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€°Ã Â¦Å“Ã Â¦Â¿Ã Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡',
    'Ã°Å¸â€¡Â³Ã°Å¸â€¡Â¿',
    'Pacific/Auckland',
    13.0,
  ),
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

  /// [city]-Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦Â®Ã Â§â€¹Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â²/Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦ÂªÃ Â§â€¡ IANA Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â®Ã Â¦Å“Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â¡Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¸
  /// (DST-Ã Â¦Â¸Ã Â¦Â¹ real Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬) Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡, Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡ fallback Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Â¡ Ã Â¦â€¦Ã Â¦Â«Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡
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
    if (diff.abs() < 0.01)
      return 'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡';
    final absDiff = diff.abs();
    final hours = absDiff.truncate();
    final minutes = ((absDiff - hours) * 60).round();
    final hm = minutes == 0
        ? '${bnNum(hours)} Ã Â¦ËœÃ Â¦Â£Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾'
        : '${bnNum(hours)} Ã Â¦ËœÃ Â¦Â£Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾ ${bnNum(minutes)} Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¸';
    return diff > 0
        ? 'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ $hm Ã Â¦ÂÃ Â¦â€”Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡'
        : 'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ $hm Ã Â¦ÂªÃ Â¦Â¿Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡';
  }

  /// Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£ Ã Â¦ËœÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â§Ã Â¦Â°Ã Â§â€¡ (Ã Â¦Â¸Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â§Â¬Ã Â¦Å¸Ã Â¦Â¾Ã¢â‚¬â€œÃ Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â§Â¬Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨)
  (String, bool) _dayNight(DateTime local) {
    final h = local.hour;
    final isDay = h >= 6 && h < 18;
    return (
      isDay
          ? 'Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨'
          : 'Ã°Å¸Å’â„¢ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤',
      isDay,
    );
  }

  @override
  Widget build(BuildContext context) {
    final indiaOffset = _offsetHours(_worldCities.first);
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(
            title:
                'Ã°Å¸Å’Â Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬ Ã Â¦ËœÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿',
          ),
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
                                  : '${_diffText(offset, indiaOffset)} Ã¢â‚¬Â¢ $dayNightLabel',
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
// Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â² Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦ÂªÃ Â§â€¡Ã Â¦Å“ (Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦ËœÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Å¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â° + Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦Â«Ã Â¦Â² + Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®-Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿)
// =====================================================================

/// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬ (Ã Â¦â€¦Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¿/Ã Â¦ÂªÃ Â§Æ’Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â¬Ã Â§â‚¬/Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§Â/Ã Â¦Å“Ã Â¦Â²), Ã Â¦â€¦Ã Â¦Â§Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã Â¦â€œ Ã Â¦ÂÃ Â¦â€¢ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â°
/// Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â¯ Ã¢â‚¬â€ [PanchangCalculator.rashiNames]-Ã Â¦ÂÃ Â¦Â° Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â® Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ (Ã Â¦Â®Ã Â§â€¡Ã Â¦Â·..Ã Â¦Â®Ã Â§â‚¬Ã Â¦Â¨)
class _RashiMeta {
  final String element;
  final String rulingPlanet;
  final String trait;
  const _RashiMeta(this.element, this.rulingPlanet, this.trait);
}

const List<_RashiMeta> _rashiMetaList = [
  _RashiMeta(
    'Ã°Å¸â€Â¥ Ã Â¦â€¦Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¿',
    'Ã Â¦Â®Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â²',
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¸Ã Â§â‚¬ Ã Â¦â€œ Ã Â¦â€°Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â®Ã Â§â‚¬',
  ),
  _RashiMeta(
    'Ã°Å¸Å’Â Ã Â¦ÂªÃ Â§Æ’Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â¬Ã Â§â‚¬',
    'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°',
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¿Ã Â¦Â¤Ã Â¦Â§Ã Â§â‚¬ Ã Â¦â€œ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤',
  ),
  _RashiMeta(
    'Ã°Å¸â€™Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§Â',
    'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â§',
    'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â¦Â¿Ã Â¦Â¦Ã Â§â‚¬Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¤ Ã Â¦â€œ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼',
  ),
  _RashiMeta(
    'Ã°Å¸â€™Â§ Ã Â¦Å“Ã Â¦Â²',
    'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°',
    'Ã Â¦Â¸Ã Â¦â€šÃ Â¦Â¬Ã Â§â€¡Ã Â¦Â¦Ã Â¦Â¨Ã Â¦Â¶Ã Â§â‚¬Ã Â¦Â² Ã Â¦â€œ Ã Â¦Â¯Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¶Ã Â§â‚¬Ã Â¦Â²',
  ),
  _RashiMeta(
    'Ã°Å¸â€Â¥ Ã Â¦â€¦Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¿',
    'Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯',
    'Ã Â¦â€ Ã Â¦Â¤Ã Â§ÂÃ Â¦Â®Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§â‚¬ Ã Â¦â€œ Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¤Ã Â§Æ’Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¬Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â£',
  ),
  _RashiMeta(
    'Ã°Å¸Å’Â Ã Â¦ÂªÃ Â§Æ’Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â¬Ã Â§â‚¬',
    'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â§',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â²Ã Â§â€¡Ã Â¦Â·Ã Â¦Â£Ã Â§â‚¬ Ã Â¦â€œ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€“Ã Â§ÂÃ Â¦ÂÃ Â¦Â¤',
  ),
  _RashiMeta(
    'Ã°Å¸â€™Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§Â',
    'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°',
    'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â®Ã Â§ÂÃ Â¦Â¯Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€œ Ã Â¦â€¢Ã Â§â€šÃ Â¦Å¸Ã Â¦Â¨Ã Â§Ë†Ã Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢',
  ),
  _RashiMeta(
    'Ã°Å¸â€™Â§ Ã Â¦Å“Ã Â¦Â²',
    'Ã Â¦Â®Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â²',
    'Ã Â¦Â¦Ã Â§Æ’Ã Â¦Â¢Ã Â¦Â¼ Ã Â¦â€œ Ã Â¦Â°Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼',
  ),
  _RashiMeta(
    'Ã°Å¸â€Â¥ Ã Â¦â€¦Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¿',
    'Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿',
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â¨Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦Â­Ã Â§ÂÃ Â¦Â°Ã Â¦Â®Ã Â¦Â£Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼',
  ),
  _RashiMeta(
    'Ã°Å¸Å’Â Ã Â¦ÂªÃ Â§Æ’Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â¬Ã Â§â‚¬',
    'Ã Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿',
    'Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â®Ã Â§â‚¬ Ã Â¦â€œ Ã Â¦Â²Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¿Ã Â¦Â°',
  ),
  _RashiMeta(
    'Ã°Å¸â€™Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§Â',
    'Ã Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿',
    'Ã Â¦â€°Ã Â¦Â¦Ã Â§ÂÃ Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¨Ã Â§â‚¬ Ã Â¦â€œ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¤Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°',
  ),
  _RashiMeta(
    'Ã°Å¸â€™Â§ Ã Â¦Å“Ã Â¦Â²',
    'Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿',
    'Ã Â¦â€¢Ã Â¦Â²Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â£ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â­Ã Â§â€šÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¶Ã Â§â‚¬Ã Â¦Â²',
  ),
];

/// Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â¤ Ã Â¦ËœÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Å¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â° Ã¢â‚¬â€ Ã Â§Â§Ã Â§Â¨Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®/Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¨ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼,
/// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦ËœÃ Â§â€¹Ã Â¦Â°Ã Â§â€¡ (Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â§â€¹Ã Â¦Å“Ã Â¦Â¾/Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡)
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
              const Text('Ã°Å¸â€Â®', style: TextStyle(fontSize: 30)),
            ],
          );
        },
      ),
    );
  }
}

/// Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®-Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â²Ã Â§â€¡, Ã Â¦â€œÃ Â¦â€¡ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦ real Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â²
/// (Vedic Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°-Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿) Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Å¸Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Å¸ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼,
/// [PanchangCalculator.rashiIndexFor] Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â¥Â¤
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
        const SnackBar(
          content: Text(
            'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
          ),
        ),
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
            'Ã°Å¸â€Â Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®-Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â², Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° real Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬',
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
                        ? 'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“'
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
                    _tob == null
                        ? 'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼'
                        : _tob!.format(context),
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
                'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
                        '${ContentData._rashiSymbols[idx]} Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿: ${PanchangCalculator.rashiNames[idx]}',
                        style: const TextStyle(
                          color: Color(0xFFFFD36E),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬: ${meta.element}  Ã¢â‚¬Â¢  Ã Â¦â€¦Ã Â¦Â§Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹: ${meta.rulingPlanet}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â¯: ${meta.trait}',
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

/// Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¤ Ã¢â‚¬â€ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬/Ã Â¦â€¦Ã Â¦Â§Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹/Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
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
              'Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦Â«Ã Â¦Â²: $forecast',
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬: ${meta.element}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Ã Â¦â€¦Ã Â¦Â§Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹: ${meta.rulingPlanet}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â¯: ${meta.trait}',
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
    final rows =
        ContentData.categories['Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²'] ??
        const <List<String>>[];
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(
            title: 'Ã°Å¸â€Â® Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 150),
                Center(child: const _RashiWheel()),
                const SizedBox(height: 20),
                const _SectionTitle(
                  'Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â² (Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿)',
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ã Â¦Â¯Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â«Ã Â¦Â² Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
                const SizedBox(height: 10),
                // Ã Â§Â§Ã Â§Â¨Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â§Â§Ã Â¦Â® Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§â€¡ Ã Â§Â¬Ã Â¦Å¸Ã Â¦Â¾, Ã Â§Â¨Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§â€¡ Ã Â§Â¬Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸, Ã Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡
                // Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â«Ã Â¦Â² Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡ Ã Â¦Â¶Ã Â§â‚¬Ã Â¦Å¸ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡ Ã Â¦â€“Ã Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â€¡
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
                const _SectionTitle(
                  'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®-Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â°',
                ),
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
// Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã¢â‚¬â€ Ã Â¦Â®Ã Â§Æ’Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â§ÂÃ Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â‚¬ Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦Â°
// Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ (Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡) Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡
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
      helpText:
          'Ã Â¦Â®Ã Â§Æ’Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â§ÂÃ Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
    );
    if (picked != null) {
      setState(() {
        _deathDate = picked;
        _results = null;
      });
    }
  }

  /// [targetIdx] Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ (Ã Â§Â¦-Ã Â§Â¨Ã Â§Â¯) [approx] Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€ºÃ Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€ºÃ Â¦Â¿ (Ã‚Â±Ã Â§Â¨Ã Â§Â¨ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡)
  /// Ã Â¦â€“Ã Â§ÂÃ Â¦ÂÃ Â¦Å“Ã Â§â€¡ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¸Ã Â§Å’Ã Â¦Â°Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â§Â§Ã Â§Â¦-Ã Â§Â§Ã Â§Â§ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦ÂÃ Â¦â€”Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¸Ã Â§â€¡
  /// Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦â€”Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â§â€¡ Ã Â¦â€“Ã Â§ÂÃ Â¦ÂÃ Â¦Å“Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€ Ã Â¦Â¶Ã Â§â€¡Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â§â€¡ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
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
          const _ScreenHeader(
            title:
                'Ã°Å¸â€¢Â¯Ã¯Â¸Â Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Å“Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â§Æ’Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â§ÂÃ Â¦Â° (Ã Â¦â€¡Ã Â¦â€šÃ Â¦Â°Ã Â§â€¡Ã Â¦Å“Ã Â¦Â¿) Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ '
                  'Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â‚¬ Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡Ã Â¥Â¤',
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
                                ? 'Ã Â¦Â®Ã Â§Æ’Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â§ÂÃ Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¨'
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
                          'Ã Â¦â€œÃ Â¦â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿: ${tithi.paksha} Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â· Ã¢â‚¬Â¢ ${tithi.name}',
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
                              'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
                  const _SectionTitle(
                    'Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â‚¬ Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿',
                  ),
                  const SizedBox(height: 8),
                  ..._results!.map((r) {
                    final d = r['date'] as DateTime;
                    return _card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Text(
                            'Ã°Å¸â€¢Â¯Ã¯Â¸Â',
                            style: TextStyle(fontSize: 20),
                          ),
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
                    'Ã¢Å¡Â Ã¯Â¸Â Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿-Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€ Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ (Ã‚Â±Ã Â§Â§ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€ºÃ Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€ºÃ Â¦Â¿ Ã Â¦Â¹Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§â€¡)Ã Â¥Â¤ '
                    'Ã Â¦Å¡Ã Â§â€šÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¹Ã Â¥Â¤',
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
// Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â°/Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¸Ã Â§â€šÃ Â¦Å¡Ã Â¦Â¿ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â°
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
            'Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾/Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¸Ã Â§â€šÃ Â¦Å¡Ã Â¦Â¿',
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
                    labelText:
                        'Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â°/Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: pujaCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText:
                        'Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®',
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
                      '${when.day}/${when.month}/${when.year} Ã¢â‚¬â€ ${TimeOfDay.fromDateTime(when).format(ctx)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
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
              child: const Text('Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â²'),
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
                'Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
          const _ScreenHeader(
            title:
                'Ã°Å¸â€ºâ€¢ Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€œ Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¸Ã Â§â€šÃ Â¦Å¡Ã Â¦Â¿',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addDialog,
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text(
                  'Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾/Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¸Ã Â§â€šÃ Â¦Å¡Ã Â¦Â¿ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
                      'Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¸Ã Â§â€šÃ Â¦Å¡Ã Â¦Â¿ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿',
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
                              const Text(
                                'Ã°Å¸â€ºâ€¢',
                                style: TextStyle(fontSize: 22),
                              ),
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
                                      '${e.when.day}/${e.when.month}/${e.when.year} Ã¢â‚¬Â¢ ${TimeOfDay.fromDateTime(e.when).format(context)}',
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
// Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ PDF Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸
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
        events.isEmpty ? 'Ã¢â‚¬â€' : events,
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
              'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã¢â‚¬â€ ${_month.month}/${_month.year}',
              style: pw.TextStyle(font: _fontBold, fontSize: 18),
            ),
          ),
          pw.TableHelper.fromTextArray(
            headers: [
              'Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“',
              'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“',
              'Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿',
              'Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°',
              'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
            ],
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
          SnackBar(
            content: Text(
              'PDF Ã Â¦Â¤Ã Â§Ë†Ã Â¦Â°Ã Â¦Â¿ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡: $e',
            ),
          ),
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
          const _ScreenHeader(
            title:
                'Ã°Å¸â€œâ€ž Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ PDF Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Ã Â¦Â¯Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ (Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“, Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿, Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°, Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· '
                  'Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â¹) Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ PDF Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¤Ã Â§Ë†Ã Â¦Â°Ã Â¦Â¿ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¨Ã Â¥Â¤',
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
                                'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â­Ã Â¦Â¿Ã Â¦â€° / Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸',
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
                                'PDF Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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

/// Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“+Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¨Ã Â¦Æ’Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸ Ã Â¦â€œ
/// Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¨ Ã Â¦Â¦Ã Â§ÂÃ Â¦â€¡ Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
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
              : '${_value!.day}/${_value!.month}/${_value!.year} Ã¢â‚¬â€ ${TimeOfDay.fromDateTime(_value!).format(context)}',
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
// Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®-Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸ (Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿) Ã¢â‚¬â€ Sun/Moon/Mars/Jupiter/Venus/Saturn
// Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ D1 Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸Ã Â¥Â¤ Ã Â¦Â²Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨ (Ascendant) Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â§ÂÃ Â¦Â²
// Ã Â¦â€¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â¶/Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦ËœÃ Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â¶ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿-Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â¦Â° Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸, Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬-Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§Â/
// Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¤Ã Â§Â "mean node" Ã Â¦Â¸Ã Â§â€šÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ (true node Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼) Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â¤ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
// Ã Â¦ÂÃ Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
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
      put(sunIdx, 'Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯');
      put(moonIdx, 'Ã°Å¸Å’â„¢ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°');
      const planetLabels = {
        'mercury': 'Ã°Å¸Å¸Â¢ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â§',
        'mars': 'Ã°Å¸â€Â´ Ã Â¦Â®Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â²',
        'jupiter': 'Ã°Å¸Å¸Â¡ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿',
        'venus': 'Ã°Å¸â€™Â« Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°',
        'saturn': 'Ã°Å¸ÂªÂ Ã Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿',
      };
      for (final key in ['mercury', 'mars', 'jupiter', 'venus', 'saturn']) {
        final idx = PanchangCalculator.planetRashiIndexFor(key, dt);
        final retro = PanchangCalculator.planetIsRetrograde(key, dt);
        put(idx, retro ? '${planetLabels[key]} (Ã Â¦Â¬)' : planetLabels[key]!);
      }
      put(
        PanchangCalculator.rahuRashiIndexFor(dt),
        'Ã°Å¸ÂÂ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§Â',
      );
      put(
        PanchangCalculator.ketuRashiIndexFor(dt),
        'Ã°Å¸ÂªÂ· Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¤Ã Â§Â',
      );
      placements = map;
    }
    final ownGrahas = placements?[moonIdx] ?? const <String>[];

    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(
            title:
                'Ã°Å¸ÂªÂ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿, Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦â€œ '
                  'Ã Â¦Â¨Ã Â¦Â¬Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â§â€¡Ã Â¦Â° (Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¤Ã Â§Â) Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ '
                  'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â·Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾, Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¦Ã Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®-Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ '
                  'Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤ Ã Â¦Â²Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨ (Ascendant) Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â§ÂÃ Â¦Â² '
                  'Ã Â¦â€¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â¶/Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦ËœÃ Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â¶ Ã Â¦Â¦Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°-Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ '
                  'Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ (Chandra Kundli)Ã Â¥Â¤',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                _DateTimePickerField(
                  label:
                      'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¨',
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
                          'Ã°Å¸Å’â„¢ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿: ${PanchangCalculator.rashiNames[moonIdx!]}',
                          style: const TextStyle(
                            color: Color(0xFFFFD36E),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ã¢Â­Â Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°: ${PanchangCalculator.nakshatraNames[nakIdx!]} Ã¢â‚¬Â¢ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¦ ${bnNum(pada!)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿: ${PanchangCalculator.rashiNames[sunIdx!]}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle(
                    'Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿',
                  ),
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
                            ? 'Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§â€¡Ã Â¦ÂªÃ Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨'
                            : 'Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ D1 Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸ (Ã Â§Â§Ã Â§Â¨ Ã Â¦ËœÃ Â¦Â°) Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨',
                        style: const TextStyle(color: Color(0xFFFFD36E)),
                      ),
                    ),
                  ),
                ],
                if (_birth != null && _showFullChart) ...[
                  const SizedBox(height: 8),
                  const _SectionTitle(
                    'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸ (D1)',
                  ),
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
                    'Ã Â¦Â¬: Ã Â¦Â¬Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬ Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â¿ (retrograde)Ã Â¥Â¤ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸Ã Â§â€¡Ã Â¦Â° Ã Â§Â§Ã Â§Â¨Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ËœÃ Â¦Â° Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â§Â§Ã Â§Â¨Ã Â¦Å¸Ã Â¦Â¾ '
                    'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡ (Ã Â¦Â®Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â®Ã Â§â‚¬Ã Â¦Â¨) Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â¶ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â²Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨-Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤',
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
// Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦â€¦Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦â€¢Ã Â§â€šÃ Â¦Å¸ Ã Â¦â€”Ã Â§ÂÃ Â¦Â£ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¨ (Ashtakoot Guna Milan), Ã Â¦Â®Ã Â§â€¹Ã Â¦Å¸ Ã Â§Â©Ã Â§Â¬ Ã Â¦â€”Ã Â§ÂÃ Â¦Â£Ã Â¥Â¤
// Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°-Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦â€œ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°-Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â° Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦â€¡ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â§â€šÃ Â¦Â²
// Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦ÂÃ Â¦Â¬Ã Â¦â€š Ã Â¦ÂÃ Â¦â€¡ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡ real Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â§ÂÃ Â¦Â²Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦Â­Ã Â¦Â¬Ã Â¥Â¤
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
  // Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â£-Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â® (Brahmin=4 Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€°Ã Â¦ÂÃ Â¦Å¡Ã Â§Â ... Shudra=1)
  static const List<int> _varna = [3, 2, 1, 4, 3, 2, 1, 4, 3, 2, 1, 4];

  // Ã Â¦Â¬Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Âª: 0=Ã Â¦Å¡Ã Â¦Â¤Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¦, 1=Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¬, 2=Ã Â¦Å“Ã Â¦Â²Ã Â¦Å¡Ã Â¦Â°, 3=Ã Â¦â€¢Ã Â§â‚¬Ã Â¦Å¸
  static const List<int> _vashya = [0, 0, 1, 2, 0, 1, 1, 3, 1, 0, 1, 2];
  static const List<double> _vashyaM = [
    2, 1, 1, 0, //
    1, 2, 1, 0, //
    1, 1, 2, 0.5, //
    0, 0, 0.5, 2, //
  ];

  // Ã Â§Â¨Ã Â§Â­ Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦â€”Ã Â¦Â£: 0=Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¬, 1=Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â¯, 2=Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¸
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

  // Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿: 0=Ã Â¦â€ Ã Â¦Â¦Ã Â¦Â¿, 1=Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯, 2=Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â¯
  static const List<int> _nadi = [
    0, 1, 2, 2, 1, 0, 0, 1, 2, //
    2, 1, 0, 0, 1, 2, 2, 1, 0, //
    0, 1, 2, 2, 1, 0, 0, 1, 2, //
  ];

  // Ã Â¦Â¯Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â¿ (Ã Â§Â§Ã Â§ÂªÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â£Ã Â§â‚¬, id Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬): 0 Ã Â¦ËœÃ Â§â€¹Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾,1 Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¿,2 Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾,3 Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Âª,4 Ã Â¦â€¢Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°,
  // 5 Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²,6 Ã Â¦â€¡Ã Â¦ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°,7 Ã Â¦â€”Ã Â¦Â°Ã Â§Â,8 Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â·,9 Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Ëœ,10 Ã Â¦Â¹Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â£,11 Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â°,12 Ã Â¦Â¬Ã Â§â€¡Ã Â¦Å“Ã Â¦Â¿,13 Ã Â¦Â¸Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¹
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
    koots.add(
      GunaKoot(
        'Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â£',
        varnaScore,
        1,
        'Ã Â¦â€ Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â®Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â®Ã Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯',
      ),
    );

    final vg = _vashya[brideRashi], vb = _vashya[groomRashi];
    final vashyaScore = _vashyaM[vg * 4 + vb];
    koots.add(
      GunaKoot(
        'Ã Â¦Â¬Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¯',
        vashyaScore,
        2,
        'Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â·Ã Â¦Â£ Ã Â¦â€œ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â£',
      ),
    );

    final c1 = ((groomNak - brideNak) % 27 + 27) % 27 + 1;
    final c2 = ((brideNak - groomNak) % 27 + 27) % 27 + 1;
    final t1 = ((c1 - 1) % 9) + 1;
    final t2 = ((c2 - 1) % 9) + 1;
    const goodTara = {2, 4, 6, 8, 9};
    final taraScore =
        (goodTara.contains(t1) ? 1.5 : 0.0) +
        (goodTara.contains(t2) ? 1.5 : 0.0);
    koots.add(
      GunaKoot(
        'Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾',
        taraScore,
        3,
        'Ã Â¦Â¦Ã Â§â‚¬Ã Â¦Â°Ã Â§ÂÃ Â¦ËœÃ Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§Â Ã Â¦â€œ Ã Â¦â€¢Ã Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â£',
      ),
    );

    final ya = _yoni[brideNak], yb = _yoni[groomNak];
    final yoniScore = ya == yb ? 4.0 : (_isYoniEnemy(ya, yb) ? 0.0 : 2.0);
    koots.add(
      GunaKoot(
        'Ã Â¦Â¯Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â¿',
        yoniScore,
        4,
        'Ã Â¦Â¶Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€œ Ã Â¦Â¯Ã Â§Å’Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â®Ã Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯',
      ),
    );

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
    koots.add(
      GunaKoot(
        'Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã Â¦Â®Ã Â§Ë†Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬',
        gmScore,
        5,
        'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¸Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¬Ã Â§â€¹Ã Â¦ÂÃ Â¦Â¾Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾',
      ),
    );

    final gaScore = _ganaM[_gana[brideNak]][_gana[groomNak]];
    koots.add(
      GunaKoot(
        'Ã Â¦â€”Ã Â¦Â£',
        gaScore,
        6,
        'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬ Ã Â¦â€œ Ã Â¦â€ Ã Â¦Å¡Ã Â¦Â°Ã Â¦Â£Ã Â¦â€”Ã Â¦Â¤ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²',
      ),
    );

    final bc1 = ((groomRashi - brideRashi) % 12 + 12) % 12 + 1;
    final bcDosha = {2, 5, 6, 8, 9, 12}.contains(bc1);
    final bhakootScore = bcDosha ? 0.0 : 7.0;
    koots.add(
      GunaKoot(
        'Ã Â¦Â­Ã Â¦â€¢Ã Â§â€šÃ Â¦Å¸',
        bhakootScore,
        7,
        'Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¸Ã Â¦Â®Ã Â§Æ’Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â¦Â¿ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€“',
      ),
    );

    final nadiScore = _nadi[brideNak] == _nadi[groomNak] ? 0.0 : 8.0;
    koots.add(
      GunaKoot(
        'Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿',
        nadiScore,
        8,
        'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â£',
      ),
    );

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
          const _ScreenHeader(
            title:
                'Ã°Å¸â€™Å¾ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¨',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Ã Â¦Â¬Ã Â¦Â° Ã Â¦â€œ Ã Â¦â€¢Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦â€œ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â° '
                  'Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â° Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦â€¦Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦â€¢Ã Â§â€šÃ Â¦Å¸ Ã Â¦â€”Ã Â§ÂÃ Â¦Â£ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¨ (Ã Â§Â©Ã Â§Â¬ Ã Â¦â€”Ã Â§ÂÃ Â¦Â£ Ã Â¦ÂªÃ Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â¦Â¤Ã Â¦Â¿) Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ '
                  'Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡Ã Â¥Â¤',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ã Â¦â€¢Ã Â¦Â¨Ã Â§â€¡',
                  style: TextStyle(
                    color: Color(0xFFFFD36E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _DateTimePickerField(
                  label:
                      'Ã Â¦â€¢Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼',
                  onChanged: (dt) => setState(() => _bride = dt),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Ã Â¦Â¬Ã Â¦Â°',
                  style: TextStyle(
                    color: Color(0xFFFFD36E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _DateTimePickerField(
                  label:
                      'Ã Â¦Â¬Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼',
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
                        'Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¨ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨',
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
                          '${bnNum(_result!.total.round())} / Ã Â§Â©Ã Â§Â¬',
                          style: const TextStyle(
                            color: Color(0xFFFFD36E),
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _result!.total >= 28
                              ? 'Ã°Å¸â€™Â« Ã Â¦â€¦Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¨'
                              : _result!.total >= 18
                              ? 'Ã¢Å“â€¦ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¨'
                              : 'Ã¢Å¡Â Ã¯Â¸Â Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â€¹Ã Â¦Â·Ã Â¦Å“Ã Â¦Â¨Ã Â¦â€¢ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼',
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
                    (k) =>
                        k.name == 'Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿' &&
                        k.score == 0,
                  ))
                    const Text(
                      'Ã¢Å¡Â Ã¯Â¸Â Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿ Ã Â¦Â¦Ã Â§â€¹Ã Â¦Â· Ã Â¦â€ Ã Â¦â€ºÃ Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â°Ã Â§ÂÃ Â¦Â¶ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦â€°Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤Ã Â¥Â¤',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11.5),
                    ),
                  if (_result!.koots.any(
                    (k) =>
                        k.name == 'Ã Â¦Â­Ã Â¦â€¢Ã Â§â€šÃ Â¦Å¸' && k.score == 0,
                  ))
                    const Text(
                      'Ã¢Å¡Â Ã¯Â¸Â Ã Â¦Â­Ã Â¦â€¢Ã Â§â€šÃ Â¦Å¸ Ã Â¦Â¦Ã Â§â€¹Ã Â¦Â· Ã Â¦â€ Ã Â¦â€ºÃ Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â°Ã Â§ÂÃ Â¦Â¶ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦â€°Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤Ã Â¥Â¤',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11.5),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦â€œ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â° Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ '
                    'Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â§ÂÃ Â¦Â² Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â²Ã Â§â€¡Ã Â¦Â·Ã Â¦Â£Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å“Ã Â¦Â¨ Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾ '
                    'Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨Ã Â¥Â¤',
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
// Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨
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
        _message =
            err ??
            'Ã¢Å“â€¦ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª Ã Â¦Â¸Ã Â¦Â«Ã Â¦Â² Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡';
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
        _message =
            err ??
            'Ã¢Å“â€¦ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â«Ã Â¦Â² Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(
            title:
                'Ã¢ËœÂÃ¯Â¸Â Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€œ Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¸ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¦Ã Â§â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨ Ã¢â‚¬â€ '
                  'Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â«Ã Â¦Â¿Ã Â¦Â°Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¨Ã Â¥Â¤',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                if (_lastBackup != null) ...[
                  Text(
                    'Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª: ${_lastBackup!.day}/${_lastBackup!.month}/${_lastBackup!.year} Ã¢â‚¬Â¢ ${TimeOfDay.fromDateTime(_lastBackup!).format(context)}',
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
                          'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
                          'Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
// Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â¦â€¢Ã Â¦Â¨Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â²Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š (Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â² Ã Â¦Â¸Ã Â¦â€šÃ Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â¦Â°Ã Â¦Â£ Ã¢â‚¬â€ WhatsApp-Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢)
// =====================================================================

class AstrologerProfile {
  final String name;
  final String specialty;
  final String experience;
  const AstrologerProfile(this.name, this.specialty, this.experience);
}

// Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾ placeholder Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®/Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¬ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨,
// Ã Â¦â€ Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â° _astrologerWhatsApp Ã Â¦Â¨Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â°Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€œ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡Ã Â¦Â°/Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦Â¨Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡
// Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡ (Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¡ Ã Â¦Â¸Ã Â¦Â¹, + Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â§â€¡Ã Â¦Â¸ Ã Â¦â€ºÃ Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾, Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ 91XXXXXXXXXX)
const List<AstrologerProfile> _astrologers = [
  AstrologerProfile(
    'Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â§Â§',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â¦Â°Ã Â§ÂÃ Â¦â€¢',
    'Ã Â§Â§Ã Â§Â«+ Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¤Ã Â¦Â¾',
  ),
  AstrologerProfile(
    'Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â§Â¨',
    'Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â¦Å“Ã Â§â‚¬Ã Â¦Â¬Ã Â¦Â¨ Ã Â¦â€œ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾',
    'Ã Â§Â§Ã Â§Â¦+ Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¤Ã Â¦Â¾',
  ),
  AstrologerProfile(
    'Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â§Â©',
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€œ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
    'Ã Â§Â¨Ã Â§Â¦+ Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¤Ã Â¦Â¾',
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
  String _topic =
      'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â°Ã Â§ÂÃ Â¦Â¶';
  DateTime? _when;

  static const _topics = [
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â°Ã Â§ÂÃ Â¦Â¶',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹',
    'Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â¦Å“Ã Â§â‚¬Ã Â¦Â¬Ã Â¦Â¨',
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â§ÂÃ Â¦Â¯',
    'Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â¦Â£ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
          ),
        ),
      );
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
        : '\nÃ Â¦â€¦Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯: ${booking.notes}';
    final msg = Uri.encodeComponent(
      'Ã Â¦Â¨Ã Â¦Â®Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â°, Ã Â¦â€ Ã Â¦Â®Ã Â¦Â¿ ${booking.name} Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Â®Ã Â¦Â¿ ${booking.astrologer}-Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ '
      '${booking.topic} Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â·Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â°Ã Â§ÂÃ Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡Ã Â¥Â¤\n'
      'Ã Â¦ÂªÃ Â¦â€ºÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼: ${when.day}/${when.month}/${when.year} $timeLabel\n'
      'Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨: ${booking.phone}$extra',
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
        const SnackBar(
          content: Text(
            'Ã¢Å“â€¦ Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Column(
        children: [
          const _ScreenHeader(
            title:
                'Ã°Å¸â€Â® Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â°Ã Â§ÂÃ Â¦Â¶ Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _SectionTitle(
                  'Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¨',
                ),
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
                          const Text(
                            'Ã°Å¸Â§â€˜Ã¢â‚¬ÂÃ°Å¸ÂÂ«',
                            style: TextStyle(fontSize: 22),
                          ),
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
                                  '${a.specialty} Ã¢â‚¬Â¢ ${a.experience}',
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
                const _SectionTitle(
                  'Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯',
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText:
                        'Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText:
                        'Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â¨Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â°',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _topic,
                  dropdownColor: const Color(0xFF0B1C38),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â·Ã Â¦Â¯Ã Â¦Â¼',
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
                          ? 'Ã Â¦ÂªÃ Â¦â€ºÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¨'
                          : '${_when!.day}/${_when!.month}/${_when!.year} Ã¢â‚¬â€ ${TimeOfDay.fromDateTime(_when!).format(context)}',
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
                    labelText:
                        'Ã Â¦â€¦Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯ (Ã Â¦ÂÃ Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â¦Â¿Ã Â¦â€¢)',
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
                      'Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â Ã Â¦Â¾Ã Â¦Â¨',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â®Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ WhatsApp-Ã Â¦Â Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿-Ã Â¦Â«Ã Â¦Â¿Ã Â¦Â²Ã Â§ÂÃ Â¦Â¡ Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å“ Ã Â¦â€“Ã Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨ '
                  'Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂªÃ Â§Å’Ã Â¦ÂÃ Â¦â€ºÃ Â¦Â¾Ã Â¦Â¬Ã Â§â€¡Ã Â¥Â¤ '
                  '(README.md-Ã Â¦Â WhatsApp Ã Â¦Â¨Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦Â§Ã Â¦Â¾Ã Â¦Âª Ã Â¦â€ Ã Â¦â€ºÃ Â§â€¡)',
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
// CONTENT DATA Ã¢â‚¬â€ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° sheet-Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â®Ã Â§â€¹ Ã Â¦Â¡Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾
// =====================================================================

/// Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ real Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯/Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã¢â‚¬â€ [date] Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼ (IST) Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°
/// Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“, NASA-Ã Â¦Â° eclipse Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â²Ã Â¦â€” Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ (Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬-Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â­)Ã Â¥Â¤
class _EclipseEvent {
  final DateTime date;
  final String icon;
  final String title;
  final String desc;

  /// Ã Â¦Â§Ã Â¦Â¾Ã Â¦Âª-Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¸Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ (IST) Ã¢â‚¬â€ NASA/PIB (Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤ Ã Â¦Â¸Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°)/timeanddate.com
  /// Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾Ã Â¥Â¤ Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â­Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Â¯Ã Â§Å½ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡
  /// Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ null Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ (Ã Â¦â€ Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¾Ã Â¦Å“ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â­Ã Â§ÂÃ Â¦Â² Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿)Ã Â¥Â¤
  final String? timingIst;

  /// Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¤ Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸
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
  /// 'Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾' Ã Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€°Ã Â¦Â°Ã Â§â€¡Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â¡ Ã Â¦Â¨Ã Â¦Â®Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â¨Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸ (Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²,
  /// Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€¡Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â· Ã Â¦Â«Ã Â¦Â¿Ã Â¦Â¡ Ã Â¦Â¦Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°)Ã Â¥Â¤
  /// 'Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾' Ã Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°/Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
  static Map<String, List<List<String>>> get categories => {
    ..._staticCategories,
    'Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾': _livePanjika(),
    'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²': _liveRashiphal(),
    'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨': _liveAuspiciousDays(),
    'Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã Â¦â€œ Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°':
        _livePlanets(),
    'Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£': _liveEclipses(),
    'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾': _livePurnima(),
    'Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾': _liveAmabasya(),
    'Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¤':
        _livePujaBrata(),
    'Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦â€œ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨':
        _liveUpcomingFestivals(),
  };

  /// [label]-Ã Â¦ÂÃ Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¾Ã Â¦Â¨-Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ (Ã Â¦â€ Ã Â¦Å“ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡) Ã¢â‚¬â€ real
  /// Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ ([BengaliCalendarData.eventsFor] Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡)
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

  /// "Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¤" Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â² ("Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦â€œ Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾
  /// Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾", "Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¬ Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¤" Ã Â¦â€¡Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¿, Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â² Ã Â¦Â¨Ã Â¦Â¾)Ã Â¥Â¤ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨
  /// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â° real Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â‚¬ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ (Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡) Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
  static List<List<String>> _livePujaBrata() {
    final ekadashi = _nextEventDate('Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬');
    final shivaratri = _nextEventDate(
      'Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿',
    );
    final shashthi = _nextEventDate(
      'Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â§â‚¬',
    );
    final dashami = _nextEventDate(
      'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¶Ã Â¦Â®Ã Â§â‚¬',
    );
    final lakshmi = _nextEventDate(
      'Ã Â¦â€¢Ã Â§â€¹Ã Â¦Å“Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â°Ã Â§â‚¬ Ã Â¦Â²Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â®Ã Â§â‚¬Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾',
    );
    final kali = _nextEventDate(
      'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â§â‚¬Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾ / Ã Â¦Â¦Ã Â§â‚¬Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â¿',
    );
    final saraswati = _nextEventDate(
      'Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¤Ã Â§â‚¬ Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾',
    );

    String fmt(DateTime? d) => d == null
        ? 'Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿'
        : '${bnNum(d.day)} ${gregMonthBn(d.month)} ${bnNum(d.year)}';

    String range(DateTime? a, DateTime? b) {
      if (a == null || b == null)
        return 'Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿';
      return '${bnNum(a.day)} ${gregMonthBn(a.month)} Ã¢â‚¬â€œ ${bnNum(b.day)} ${gregMonthBn(b.month)} ${bnNum(b.year)}';
    }

    return [
      [
        'Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬',
        ekadashi == null
            ? 'Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿'
            : 'Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â‚¬ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬\n${_fmtTithiTimingFor(ekadashi)}',
      ],
      [
        'Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿',
        fmt(shivaratri),
      ],
      [
        'Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦â€”Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾',
        range(shashthi, dashami),
      ],
      [
        'Ã Â¦Â²Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â®Ã Â§â‚¬Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾',
        fmt(lakshmi),
      ],
      ['Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â§â‚¬Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾', fmt(kali)],
      [
        'Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¤Ã Â§â‚¬ Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾',
        fmt(saraswati),
      ],
    ];
  }

  /// Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â/Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“+Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¸Ã Â¦Â¹ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°-Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â§ÂÃ Â¦Â¯ Ã Â¦Å¸Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Å¸Ã Â§â€¡ Ã¢â‚¬â€
  /// "Ã Â§Â¯ Ã Â¦Â¸Ã Â§â€¡Ã Â¦ÂªÃ Â§ÂÃ Â¦Å¸Ã Â§â€¡Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â°, Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤ Ã Â§Â¯:Ã Â§ÂªÃ Â§Â¨"-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹Ã Â¥Â¤ [PanchangCalculator.tithiTiming]-Ã Â¦ÂÃ Â¦Â°
  /// Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿-Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡, Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€”Ã Â¦Â¡Ã Â¦Â¼/Ã Â¦â€ Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤
  static String _fmtTithiEdge(DateTime t) =>
      '${bnNum(t.day)} ${gregMonthBn(t.month)}, ${bnTime12(t)}';

  static String _fmtTithiTimingFor(DateTime day) {
    final ref = PanchangCalculator.sunTimes(day).sunrise;
    final (start, end) = PanchangCalculator.tithiTiming(ref);
    return 'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â: ${_fmtTithiEdge(start)}\nÃ Â¦Â¶Ã Â§â€¡Ã Â¦Â·: ${_fmtTithiEdge(end)}';
  }

  /// Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° real Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã¢â‚¬â€ real Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾
  /// (Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¤; Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€œ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€œ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼)
  static List<List<String>> _livePurnima() {
    final dates = BengaliCalendarData.findAuspiciousDates(
      'purnima',
      count: 4,
      maxDays: 200,
    );
    return dates.map((d) {
      final month = BengaliDateUtil.monthInfoFor(d).name;
      return [
        '$month Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾',
        _fmtTithiTimingFor(d),
      ];
    }).toList();
  }

  /// Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° real Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã¢â‚¬â€ real Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾
  /// (Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¤; Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€œ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€œ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼)
  static List<List<String>> _liveAmabasya() {
    final dates = BengaliCalendarData.findAuspiciousDates(
      'amabasya',
      count: 4,
      maxDays: 200,
    );
    return dates.map((d) {
      final month = BengaliDateUtil.monthInfoFor(d).name;
      return [
        '$month Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
        _fmtTithiTimingFor(d),
      ];
    }).toList();
  }

  /// NASA-Ã Â¦Â° eclipse Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â²Ã Â¦â€” Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ real Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ (Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬-Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â­)Ã Â¥Â¤
  /// Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â§Â¨Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â¡ Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â² (Ã Â§Â§Ã Â§Â¨ Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£, Ã Â§Â¨Ã Â§Â® Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸
  /// Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£) Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€œÃ Â¦â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â¦â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¤Ã Â¥Â¤
  /// Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“
  /// Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡Ã Â¥Â¤
  static final List<_EclipseEvent> _eclipseEvents = [
    _EclipseEvent(
      DateTime(2026, 2, 17),
      'Ã¢Ëœâ‚¬Ã¯Â¸Â',
      'Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      'Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      timingIst:
          'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â§Â©:Ã Â§Â¨Ã Â§Â¬ PM, Ã Â¦Â¸Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â§â€¹Ã Â¦Å¡Ã Â§ÂÃ Â¦Å¡ Ã Â§Â«:Ã Â§ÂªÃ Â§Â¨ PM, Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â§Â­:Ã Â§Â«Ã Â§Â­ PM',
      indiaVisibility:
          'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ (Ã Â¦Â¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦Â£ Ã Â¦â€”Ã Â§â€¹Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â§/Ã Â¦â€ Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡)',
    ),
    _EclipseEvent(
      DateTime(2026, 3, 3),
      'Ã°Å¸Å’â€¢',
      'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      timingIst:
          'Ã Â¦â€ Ã Â¦â€šÃ Â¦Â¶Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â§Â©:Ã Â§Â¨Ã Â§Â¦ PM, Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â§Âª:Ã Â§Â©Ã Â§Âª PM, Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â§Â«:Ã Â§Â©Ã Â§Â© PM, Ã Â¦â€ Ã Â¦â€šÃ Â¦Â¶Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â§Â¬:Ã Â§ÂªÃ Â§Â® PM',
      indiaVisibility:
          'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€” Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€”Ã Â¦Â¾ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦ Ã Â¦â€œÃ Â¦Â Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€” Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡; Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°-Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¬ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤ Ã Â¦â€œ Ã Â¦â€ Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨-Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¬Ã Â¦Â° Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·Ã Â¦â€œ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡',
    ),
    _EclipseEvent(
      DateTime(2026, 8, 12),
      'Ã¢Ëœâ‚¬Ã¯Â¸Â',
      'Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      indiaVisibility:
          'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ (Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬Ã Â¦Â¨Ã Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡, Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¸Ã Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡, Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â§â€¡Ã Â¦Â¨ Ã Â¦â€œ Ã Â¦â€¡Ã Â¦â€°Ã Â¦Â°Ã Â§â€¹Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§Â Ã Â¦â€¦Ã Â¦â€šÃ Â¦Â¶ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡)',
    ),
    _EclipseEvent(
      DateTime(2026, 8, 28),
      'Ã°Å¸Å’Ëœ',
      'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      'Ã Â¦â€ Ã Â¦â€šÃ Â¦Â¶Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      timingIst:
          'Ã Â¦â€ Ã Â¦â€šÃ Â¦Â¶Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â§Â®:Ã Â§Â¦Ã Â§Âª AM, Ã Â¦Â¸Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â§â€¹Ã Â¦Å¡Ã Â§ÂÃ Â¦Å¡ Ã Â§Â¯:Ã Â§ÂªÃ Â§Â© AM, Ã Â¦â€ Ã Â¦â€šÃ Â¦Â¶Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â§Â§Ã Â§Â§:Ã Â§Â¨Ã Â§Â§ AM',
      indiaVisibility:
          'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ (Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¤Ã Â¦â€“Ã Â¦Â¨ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦ÂÃ Â¦Â¬Ã Â¦â€š Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦ Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€”Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡)',
    ),
    _EclipseEvent(
      DateTime(2027, 2, 6),
      'Ã¢Ëœâ‚¬Ã¯Â¸Â',
      'Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      'Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
    ),
    _EclipseEvent(
      DateTime(2027, 2, 21),
      'Ã°Å¸Å’â€”',
      'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      'Ã Â¦â€°Ã Â¦ÂªÃ Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
    ),
    _EclipseEvent(
      DateTime(2027, 7, 18),
      'Ã°Å¸Å’â€”',
      'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      'Ã Â¦â€°Ã Â¦ÂªÃ Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
    ),
    _EclipseEvent(
      DateTime(2027, 8, 2),
      'Ã¢Ëœâ‚¬Ã¯Â¸Â',
      'Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
    ),
    _EclipseEvent(
      DateTime(2027, 8, 17),
      'Ã°Å¸Å’â€”',
      'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      'Ã Â¦â€°Ã Â¦ÂªÃ Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
    ),
  ];

  /// Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° (Ã Â¦â€ Ã Â¦Å“Ã Â¦Â¸Ã Â¦Â¹) Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã¢â‚¬â€ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦â€”Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ real Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾
  /// Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â¦â€œ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨: "Ã Â§Â¨Ã Â§Â® Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸ Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬ (Ã Â§Â§Ã Â§Â§ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â§Â§Ã Â§ÂªÃ Â§Â©Ã Â§Â©) Ã¢â‚¬Â¢ Ã Â¦â€ Ã Â¦â€šÃ Â¦Â¶Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£")
  static List<List<String>> _liveEclipses() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final upcoming = _eclipseEvents
        .where((e) => !e.date.isBefore(todayStart))
        .toList();
    if (upcoming.isEmpty) {
      return [
        [
          'Ã°Å¸â€Â­ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
          'Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡',
        ],
      ];
    }
    return upcoming.map((e) {
      final info = BengaliDateUtil.monthInfoFor(e.date);
      final bDay = e.date.difference(info.start).inDays + 1;
      final gregLabel =
          '${bnNum(e.date.day)} ${gregMonthBn(e.date.month)} ${bnNum(e.date.year)}';
      final bengaliLabel = '${bnNum(bDay)} ${info.name} ${bnNum(info.year)}';
      var detail = '$gregLabel ($bengaliLabel) Ã¢â‚¬Â¢ ${e.desc}';
      if (e.timingIst != null) {
        detail +=
            '\nÃ¢ÂÂ±Ã¯Â¸Â Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ (IST): ${e.timingIst}';
      }
      if (e.indiaVisibility != null) {
        detail += '\nÃ°Å¸â€œÂ ${e.indiaVisibility}';
      }
      return ['${e.icon} ${e.title}', detail];
    }).toList();
  }

  /// "Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦â€œ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨" Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° (Ã Â¦â€ Ã Â¦Å“Ã Â¦Â¸Ã Â¦Â¹) real Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬Ã Â¥Â¤
  /// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡)Ã Â¥Â¤
  /// Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ hardcoded/Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡, Ã Â¦Â¸Ã Â¦Â¬Ã Â¦â€¡ live calculationÃ Â¥Â¤
  static List<List<String>> _liveUpcomingFestivals() {
    final festivals = BengaliCalendarData.upcomingFestivals(count: 10);
    if (festivals.isEmpty) {
      return [
        [
          'Ã°Å¸Å½â€° Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬',
          'Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾',
        ],
      ];
    }
    return festivals
        .map(
          (f) => [
            '${f['icon']} ${f['title']}',
            f['date'] ?? 'Ã Â¦Â¶Ã Â§â‚¬Ã Â¦ËœÃ Â§ÂÃ Â¦Â°Ã Â¦â€¡',
          ],
        )
        .toList();
  }

  /// "Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã Â¦â€œ Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°" Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯/Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°/Ã Â¦Â®Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â²/Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿/Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°/Ã Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿/Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â¸Ã Â¦Â¬Ã Â¦â€¡
  /// Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§â€¡Ã Â¦Â¸Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â²Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¸Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Å¸ Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â² ("Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯", "Ã Â¦â€ Ã Â¦Å“: Ã Â¦Â§Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¾" Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â¡)Ã Â¥Â¤
  /// Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ real heliocentric Keplerian orbital elements (NASA JPL
  /// Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â²) Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â²/Ã Â¦Â¬Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬ (retrograde) Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â¿
  /// Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ fake Ã Â¦Â¡Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡Ã Â¥Â¤
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
        ? 'Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â§Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Â£Ã Â§Â (${(illum * 100).round()}%)'
        : 'Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Â£Ã Â§Â (${(illum * 100).round()}%)';

    String planetRow(String key) {
      final idx = PanchangCalculator.planetRashiIndexFor(key, now);
      final retro = PanchangCalculator.planetIsRetrograde(key, now);
      final rashi = PanchangCalculator.rashiNames[idx];
      return '$rashi Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã¢â‚¬Â¢ ${retro ? "Ã Â¦Â¬Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬" : "Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â²"} Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â¿';
    }

    return [
      [
        'Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯',
        '${PanchangCalculator.rashiNames[sunIdx]} Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨',
      ],
      [
        'Ã°Å¸Å’â„¢ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°',
        '${PanchangCalculator.rashiNames[moonIdx]} Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã¢â‚¬Â¢ $moonPhaseText',
      ],
      ['Ã°Å¸â€Â´ Ã Â¦Â®Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â²', planetRow('mars')],
      [
        'Ã°Å¸Å¸Â¡ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿',
        planetRow('jupiter'),
      ],
      ['Ã°Å¸â€™Â« Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°', planetRow('venus')],
      ['Ã°Å¸ÂªÂ Ã Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿', planetRow('saturn')],
      [
        'Ã¢Â­Â Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°',
        'Ã Â¦â€ Ã Â¦Å“: ${PanchangCalculator.nakshatraNames[nakIdx]}',
      ],
    ];
  }

  /// "Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨" Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§â€¡Ã Â¦Â¸Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â²Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¸Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Å¸ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¤ ("Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â²Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€œ
  /// Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“")Ã Â¥Â¤ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ (Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹/Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶/Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¨/
  /// Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â/Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£) Ã Â¦â€ Ã Â¦Å“ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â‚¬ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ real Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/
  /// Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ real "Ã Â¦Â²Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨ Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°"Ã Â¥Â¤
  static List<List<String>> _liveAuspiciousDays() {
    const cats = [
      ['Ã°Å¸â€™Â Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹', 'marriage'],
      [
        'Ã°Å¸ÂÂ  Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶',
        'griha',
      ],
      [
        'Ã°Å¸â€˜Â¶ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¨',
        'annaprashan',
      ],
      [
        'Ã°Å¸Âªâ€ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â',
        'byabosha',
      ],
      ['Ã°Å¸â€œÂ¿ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£', 'namakaran'],
    ];
    return cats.map((c) {
      final dates = BengaliCalendarData.findAuspiciousDates(c[1], count: 3);
      final text = dates.isEmpty
          ? 'Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬ Ã Â¦â€¢Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¢ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡'
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
      [
        'Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿',
        '${tithi.paksha} Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â· Ã¢â‚¬Â¢ ${tithi.name}',
      ],
      [
        'Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°',
        PanchangCalculator.nakshatraNames[nakIdx],
      ],
      ['Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”', PanchangCalculator.yogaNames[yogaIdx]],
      ['Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£', karana],
      [
        'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â² (Ã Â¦ÂÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â²Ã Â§ÂÃ Â¦Â¨)',
        '${bnTime12(rahu['start']!)}Ã¢â‚¬â€œ${bnTime12(rahu['end']!)}',
      ],
      [
        'Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¿Ã Â§Å½ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ (Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­)',
        abhijit['applicable'] == true
            ? '${bnTime12(abhijit['start'] as DateTime)}Ã¢â‚¬â€œ${bnTime12(abhijit['end'] as DateTime)}'
            : 'Ã Â¦â€ Ã Â¦Å“ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â§â€¹Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Â¬Ã Â§ÂÃ Â¦Â§Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°)',
      ],
      [
        'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿',
        PanchangCalculator.rashiNames[rashiIdx],
      ],
    ];
  }

  /// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â² Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â²Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¤
  /// (fake demo data)Ã Â¥Â¤ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ "Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦â€”Ã Â§â€¹Ã Â¦Å¡Ã Â¦Â° Ã Â¦Â«Ã Â¦Â²"-Ã Â¦ÂÃ Â¦Â° Ã Â¦ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â§â‚¬ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â® Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¨Ã Â§â€¡
  /// Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼: Ã Â¦â€ Ã Â¦Å“ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦â€ Ã Â¦â€ºÃ Â§â€¡ (real Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾
  /// Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡) Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â¤ Ã Â¦Â¨Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â° Ã Â¦ËœÃ Â¦Â°Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°
  /// Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â¿Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â«Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â«Ã Â¦Â² Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ random/fake Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€“Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡Ã Â¥Â¤
  /// Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿ ~Ã Â§Â¨.Ã Â§Â¨Ã Â§Â« Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â«Ã Â¦Â²Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€œ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦Â®Ã Â¦Â¤Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼;
  /// Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€“Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾/Ã Â¦Â°Ã Â¦â€š Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â²Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â¦â€¡ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â§â€¡Ã Â¥Â¤
  static const List<List<String>> _gocharHouses = [
    [
      'Ã Â¦Â¶Ã Â¦Â°Ã Â§â‚¬Ã Â¦Â°-Ã Â¦Â®Ã Â¦Â¨ Ã Â¦â€œ Ã Â¦â€ Ã Â¦Â¤Ã Â§ÂÃ Â¦Â®Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¬Ã Â§â€¡',
      'Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°',
    ],
    [
      'Ã Â¦â€¦Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥ Ã Â¦â€œ Ã Â¦â€¢Ã Â¦Â¥Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬ Ã¢â‚¬â€ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦â€“Ã Â¦Â°Ã Â¦Å¡ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
      'Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°',
    ],
    [
      'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¸, Ã Â¦â€°Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦â€œ Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¬Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â·Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â«Ã Â¦Â²',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­',
    ],
    [
      'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¸Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¶Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦â€œ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â·Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬',
      'Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°',
    ],
    [
      'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾, Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€œ Ã Â¦Â¸Ã Â§Æ’Ã Â¦Å“Ã Â¦Â¨Ã Â¦Â¶Ã Â§â‚¬Ã Â¦Â²Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬',
      'Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°',
    ],
    [
      'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â¦Â¿Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â®Ã Â§â€¡ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â«Ã Â¦Â²',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­',
    ],
    [
      'Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â¦Â°Ã Â§ÂÃ Â¦â€¢ Ã Â¦â€œ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹Ã Â¦Å¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬',
      'Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°',
    ],
    [
      'Ã Â¦â€¦Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¨ Ã Â¦Â¹Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¤Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¨',
      'Ã Â¦Â¸Ã Â¦Â¤Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¤Ã Â¦Â¾',
    ],
    [
      'Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€”Ã Â§ÂÃ Â¦Â¯, Ã Â¦Â­Ã Â§ÂÃ Â¦Â°Ã Â¦Â®Ã Â¦Â£ Ã Â¦â€œ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“Ã Â§â€¡ Ã Â¦â€¡Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Å¡Ã Â¦â€¢ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­',
    ],
    [
      'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“ Ã Â¦â€œ Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â¶Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â¤ Ã Â¦Å“Ã Â§â‚¬Ã Â¦Â¬Ã Â¦Â¨Ã Â§â€¡ Ã Â¦â€¦Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­',
    ],
    [
      'Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â­ Ã Â¦â€œ Ã Â¦â€¡Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â¦Â¾Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â¦Â£Ã Â§â€¡ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦â€¢Ã Â§â€šÃ Â¦Â² Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­',
    ],
    [
      'Ã Â¦â€“Ã Â¦Â°Ã Â¦Å¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§â€¡, Ã Â¦â€ Ã Â¦Å“ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â§Â Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¨',
      'Ã Â¦Â¸Ã Â¦Â¤Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¤Ã Â¦Â¾',
    ],
  ];

  // Ã Â¦ÂªÃ Â¦Â¶Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â€¡Ã Â¦Â° Ã¢â„¢Ë†Ã¢â„¢â€°Ã¢â„¢Å  Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¤Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â€¡Ã Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿
  // Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â§â‚¬Ã Â¦â€¢ (Ã Â¦Â®Ã Â§â€¡Ã Â¦Â·=Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾, Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·=Ã Â¦Â·Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¡Ã Â¦Â¼, Ã Â¦Â®Ã Â¦â€¢Ã Â¦Â°=Ã Â¦â€¢Ã Â§ÂÃ Â¦Â®Ã Â¦Â¿Ã Â¦Â°-Ã Â¦â€ Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â° Ã Â¦Å“Ã Â¦Â²Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§Â
  // Ã Â¦â€¡Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¿) Ã¢â‚¬â€ Ã Â¦Â®Ã Â§â€¡Ã Â¦Â·..Ã Â¦Â®Ã Â§â‚¬Ã Â¦Â¨ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â®Ã Â§â€¡
  static const List<String> _rashiSymbols = [
    'Ã°Å¸ÂÂ',
    'Ã°Å¸Ââ€š',
    'Ã°Å¸â€˜Â«',
    'Ã°Å¸Â¦â‚¬',
    'Ã°Å¸Â¦Â',
    'Ã°Å¸â€˜Â§',
    'Ã¢Å¡â€“Ã¯Â¸Â',
    'Ã°Å¸Â¦â€š',
    'Ã°Å¸ÂÂ¹',
    'Ã°Å¸ÂÅ ',
    'Ã°Å¸ÂÂº',
    'Ã°Å¸ÂÅ¸',
  ];
  static const List<String> _luckyColors = [
    'Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â²',
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾',
    'Ã Â¦Â¸Ã Â¦Â¬Ã Â§ÂÃ Â¦Å“',
    'Ã Â¦Â°Ã Â§â€šÃ Â¦ÂªÃ Â¦Â¾Ã Â¦Â²Ã Â¦Â¿',
    'Ã Â¦Â¸Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿',
    'Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â²',
    'Ã Â¦â€”Ã Â§â€¹Ã Â¦Â²Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¿',
    'Ã Â¦Â®Ã Â§â€¡Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
    'Ã Â¦Â¹Ã Â¦Â²Ã Â§ÂÃ Â¦Â¦',
    'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¿',
    'Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿',
    'Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¿',
  ];

  static List<List<String>> _liveRashiphal() {
    final now = DateTime.now();
    final moonRashiIdx = PanchangCalculator.rashiIndexFor(now);
    final tithi = PanchangCalculator.tithiFor(now);
    return List.generate(12, (r) {
      // Ã Â¦â€ Ã Â¦Å“ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦ [r] Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â¤ Ã Â¦Â¨Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â° Ã Â¦ËœÃ Â¦Â°Ã Â§â€¡ (Ã Â§Â§..Ã Â§Â§Ã Â§Â¨) Ã Â¦â€ Ã Â¦â€ºÃ Â§â€¡
      final house = (moonRashiIdx - r + 12) % 12;
      final theme = _gocharHouses[house][0];
      final tag = _gocharHouses[house][1];
      final icon = tag == 'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­'
          ? 'Ã¢Å“â€¦'
          : (tag == 'Ã Â¦Â¸Ã Â¦Â¤Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¤Ã Â¦Â¾'
                ? 'Ã¢Å¡Â Ã¯Â¸Â'
                : 'Ã¢Å¾â€“');
      final luckyNum = ((tithi.index + r) % 9) + 1;
      final color = _luckyColors[(tithi.index + r) % _luckyColors.length];
      return [
        '${_rashiSymbols[r]} ${PanchangCalculator.rashiNames[r]}',
        '$icon $theme Ã¢â‚¬Â¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€“Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ ${bnNum(luckyNum)} Ã¢â‚¬Â¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â°Ã Â¦â€š $color',
      ];
    });
  }

  static const Map<String, List<List<String>>> _staticCategories = {
    'Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¤': [
      [
        'Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬',
        'Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦â€œ Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾',
      ],
      [
        'Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿',
        'Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¬ Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¤',
      ],
      [
        'Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦â€”Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾',
        'Ã Â¦Â·Ã Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â§â‚¬ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¦Ã Â¦Â¶Ã Â¦Â®Ã Â§â‚¬',
      ],
      [
        'Ã Â¦Â²Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â®Ã Â§â‚¬Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾',
        'Ã Â¦â€¢Ã Â§â€¹Ã Â¦Å“Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â°Ã Â§â‚¬ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾',
      ],
      [
        'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â§â‚¬Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾',
        'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
      ],
      [
        'Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¤Ã Â§â‚¬ Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾',
        'Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â®Ã Â§â‚¬',
      ],
    ],
    'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²': [
      [
        'Ã¢â„¢Ë† Ã Â¦Â®Ã Â§â€¡Ã Â¦Â·',
        'Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â§â€¡ Ã Â¦â€¦Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â¿ Ã¢â‚¬Â¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â°Ã Â¦â€š Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â²',
      ],
      [
        'Ã¢â„¢â€° Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·',
        'Ã Â¦â€¦Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥Ã Â§â€¡ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¤Ã Â¦Â¾ Ã¢â‚¬Â¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â°Ã Â¦â€š Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾',
      ],
      [
        'Ã¢â„¢Å  Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¨',
        'Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã¢â‚¬Â¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â°Ã Â¦â€š Ã Â¦Â¸Ã Â¦Â¬Ã Â§ÂÃ Â¦Å“',
      ],
      [
        'Ã¢â„¢â€¹ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢Ã Â¦Å¸',
        'Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã¢â‚¬Â¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â°Ã Â¦â€š Ã Â¦Â°Ã Â§â€šÃ Â¦ÂªÃ Â¦Â¾Ã Â¦Â²Ã Â¦Â¿',
      ],
      [
        'Ã¢â„¢Å’ Ã Â¦Â¸Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¹',
        'Ã Â¦â€ Ã Â¦Â¤Ã Â§ÂÃ Â¦Â®Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â¦Â¿ Ã¢â‚¬Â¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â°Ã Â¦â€š Ã Â¦Â¸Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿',
      ],
      [
        'Ã¢â„¢Â Ã Â¦â€¢Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
        'Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â²Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â«Ã Â¦Â²Ã Â§ÂÃ Â¦Â¯ Ã¢â‚¬Â¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â°Ã Â¦â€š Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â²',
      ],
      [
        'Ã¢â„¢Å½ Ã Â¦Â¤Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾',
        'Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â¦Â°Ã Â§ÂÃ Â¦â€¢Ã Â§â€¡ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â®Ã Â§ÂÃ Â¦Â¯ Ã¢â‚¬Â¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â°Ã Â¦â€š Ã Â¦â€”Ã Â§â€¹Ã Â¦Â²Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¿',
      ],
      [
        'Ã¢â„¢Â Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¶Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦â€¢',
        'Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡ Ã Â¦Â§Ã Â§Ë†Ã Â¦Â°Ã Â§ÂÃ Â¦Â¯ Ã¢â‚¬Â¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â°Ã Â¦â€š Ã Â¦Â®Ã Â§â€¡Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
      ],
      [
        'Ã¢â„¢Â Ã Â¦Â§Ã Â¦Â¨Ã Â§Â',
        'Ã Â¦Â­Ã Â§ÂÃ Â¦Â°Ã Â¦Â®Ã Â¦Â£ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã¢â‚¬Â¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â°Ã Â¦â€š Ã Â¦Â¹Ã Â¦Â²Ã Â§ÂÃ Â¦Â¦',
      ],
      [
        'Ã¢â„¢â€˜ Ã Â¦Â®Ã Â¦â€¢Ã Â¦Â°',
        'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“Ã Â§â€¡ Ã Â¦Â®Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã¢â‚¬Â¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â°Ã Â¦â€š Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¿',
      ],
      [
        'Ã¢â„¢â€™ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â®Ã Â§ÂÃ Â¦Â­',
        'Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬Â¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â°Ã Â¦â€š Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿',
      ],
      [
        'Ã¢â„¢â€œ Ã Â¦Â®Ã Â§â‚¬Ã Â¦Â¨',
        'Ã Â¦Â¸Ã Â§Æ’Ã Â¦Å“Ã Â¦Â¨Ã Â¦Â¶Ã Â§â‚¬Ã Â¦Â² Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã¢â‚¬Â¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â°Ã Â¦â€š Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¿',
      ],
    ],
    'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨': [
      [
        'Ã°Å¸â€™Â Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹',
        'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â²Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€œ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“',
      ],
      [
        'Ã°Å¸ÂÂ  Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶',
        'Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼',
      ],
      [
        'Ã°Å¸â€˜Â¶ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¨',
        'Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â° Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
      ],
      [
        'Ã°Å¸Âªâ€ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â',
        'Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼',
      ],
      [
        'Ã°Å¸â€œÂ¿ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£',
        'Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£ Ã Â¦Â¸Ã Â¦â€šÃ Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
      ],
    ],
    'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾': [
      [
        'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â£ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾',
        'Ã Â§Â¨Ã Â§Â® Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸ Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬',
      ],
      [
        'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾',
        'Ã Â§Â¨Ã Â§Â¬ Ã Â¦Â¸Ã Â§â€¡Ã Â¦ÂªÃ Â§ÂÃ Â¦Å¸Ã Â§â€¡Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â° Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬',
      ],
      [
        'Ã Â¦â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾',
        'Ã Â§Â¨Ã Â§Â¬ Ã Â¦â€¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦Â¬Ã Â¦Â° Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬',
      ],
      [
        'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾',
        'Ã Â§Â¨Ã Â§Âª Ã Â¦Â¨Ã Â¦Â­Ã Â§â€¡Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â° Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬',
      ],
    ],
    'Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾': [
      [
        'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â£ Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
        'Ã Â§Â§Ã Â§Â¨ Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸ Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬',
      ],
      [
        'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
        'Ã Â§Â§Ã Â§Â¦ Ã Â¦Â¸Ã Â§â€¡Ã Â¦ÂªÃ Â§ÂÃ Â¦Å¸Ã Â§â€¡Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â° Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬',
      ],
      [
        'Ã Â¦â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
        'Ã Â§Â§Ã Â§Â¦ Ã Â¦â€¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦Â¬Ã Â¦Â° Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬',
      ],
      [
        'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
        'Ã Â§Â® Ã Â¦Â¨Ã Â¦Â­Ã Â§â€¡Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â° Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬',
      ],
    ],
    'Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£': [
      [
        'Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
        'Ã Â§Â§Ã Â§Â¨ Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸ Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬ Ã¢â‚¬Â¢ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      ],
      [
        'Ã°Å¸Å’Ëœ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
        'Ã Â§Â¨Ã Â§Â® Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸ Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬ Ã¢â‚¬Â¢ Ã Â¦â€ Ã Â¦â€šÃ Â¦Â¶Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
      ],
    ],
    'Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã Â¦â€œ Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°': [
      [
        'Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯',
        'Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨',
      ],
      [
        'Ã°Å¸Å’â„¢ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°',
        'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦â€œ phase',
      ],
      [
        'Ã°Å¸â€Â´ Ã Â¦Â®Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â²',
        'Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯',
      ],
      [
        'Ã°Å¸Å¸Â¡ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿',
        'Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯',
      ],
      [
        'Ã°Å¸â€™Â« Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°',
        'Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯',
      ],
      [
        'Ã°Å¸ÂªÂ Ã Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿',
        'Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯',
      ],
      [
        'Ã¢Â­Â Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°',
        'Ã Â¦â€ Ã Â¦Å“: Ã Â¦Â§Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¾',
      ],
    ],
    'Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦â€œ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨': [
      [
        'Ã°Å¸â€ºâ€¢ Ã Â¦Â°Ã Â¦Â¥Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾',
        'Ã Â§Â§Ã Â§Â¬ Ã Â¦Å“Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€¡ Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬',
      ],
      [
        'Ã°Å¸Â¦Å¡ Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â®Ã Â§â‚¬',
        'Ã Â§Âª Ã Â¦Â¸Ã Â§â€¡Ã Â¦ÂªÃ Â§ÂÃ Â¦Å¸Ã Â§â€¡Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â° Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬',
      ],
      [
        'Ã°Å¸â€Â± Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦â€”Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾',
        'Ã Â§Â§Ã Â§Â¯-Ã Â§Â¨Ã Â§Â¦ Ã Â¦â€¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦Â¬Ã Â¦Â° Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬',
      ],
      [
        'Ã°Å¸Âªâ€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â§â‚¬Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾',
        'Ã Â§Â® Ã Â¦Â¨Ã Â¦Â­Ã Â§â€¡Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â° Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬',
      ],
      [
        'Ã°Å¸Å’Â¼ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¤Ã Â§â‚¬ Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾',
        'Ã Â§Â¨Ã Â§Â© Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿ Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬',
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
    ['Ã°Å¸ÂªÂ·', 'Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾'],
    [
      'Ã°Å¸â€œâ€¦',
      'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
    ],
    [
      'Ã°Å¸Âªâ€',
      'Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦â€œ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
    ],
    [
      'Ã°Å¸Å½â€°',
      'Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â®Ã Â§â€¡Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°',
    ],
    [
      'Ã°Å¸â€œÂ¤',
      'Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€” Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡',
    ],
    ['Ã¢ÂÂ°', 'Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°'],
    ['Ã°Å¸â€œÂ', 'Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¸'],
    [
      'Ã°Å¸â€˜Â¨Ã¢â‚¬ÂÃ°Å¸â€˜Â©Ã¢â‚¬ÂÃ°Å¸â€˜Â§Ã¢â‚¬ÂÃ°Å¸â€˜Â¦',
      'Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
    ],
    [
      'Ã°Å¸â€Â¤',
      'Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â°',
    ],
    [
      'Ã°Å¸â€¢â€°Ã¯Â¸Â',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤',
    ],
    [
      'Ã°Å¸â€¢Â¯Ã¯Â¸Â',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
    ],
    [
      'Ã°Å¸â€ºâ€¢',
      'Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€œ Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¸Ã Â§â€šÃ Â¦Å¡Ã Â¦Â¿',
    ],
    [
      'Ã°Å¸â€œâ€ž',
      'Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ PDF Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸',
    ],
    [
      'Ã°Å¸ÂªÂ',
      'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸',
    ],
    [
      'Ã°Å¸â€™Å¾',
      'Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¨',
    ],
    [
      'Ã¢ËœÂÃ¯Â¸Â',
      'Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª',
    ],
    [
      'Ã°Å¸â€Â®',
      'Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â°Ã Â§ÂÃ Â¦Â¶ Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š',
    ],
    ['Ã¢Å“Â¨', 'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â®'],
    ['Ã¢Å¡â„¢Ã¯Â¸Â', 'Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¸'],
    ['Ã°Å¸â€˜Â¤', 'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â²'],
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
          // Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Column-Ã Â¦Å¸Ã Â¦Â¾ (Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â² + Ã Â§Â§Ã Â§Â«Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¨Ã Â§Â Ã Â¦â€ Ã Â¦â€¡Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â®) Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¸
          // Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¤Ã Â§â€¹ Ã¢â‚¬â€ Ã Â¦â€ºÃ Â§â€¹Ã Â¦Å¸ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡ (Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â°)
          // Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ "BOTTOM OVERFLOWED" Ã Â¦ÂÃ Â¦Â°Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¤, Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦â€¡Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â®Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â¤
          // Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â² Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡, Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¨Ã Â§Â Ã Â¦â€ Ã Â¦â€¡Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â®Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡
          // Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â² Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¯Ã Â¦Â¤ Ã Â¦â€ Ã Â¦â€¡Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â®Ã Â¦â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§ÂÃ Â¦â€¢, Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨Ã Â§â€¹ overflow Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ã¢ËœÂ° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾',
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
// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦â€”Ã Â§â€¡Ã Â¦Å¸ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸/Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¨, PDF Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸, Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª, Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬
// Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¡ "Ã Â¦Å¸Ã Â¦Âª" Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦â€¡Ã Â¦Â¨Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â²Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â° Ã Â§Â©Ã Â§Â¦ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯
// Ã Â¦â€“Ã Â§â€¹Ã Â¦Â²Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡, Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¶Ã Â¦Â¨ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â¬Ã Â§â€¡Ã Â¥Â¤ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ Ã Â¦Â¸Ã Â¦Â¬
// (Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾, Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°, Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°, Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¸, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿, Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¸Ã Â§â€šÃ Â¦Å¡Ã Â¦Â¿)
// Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¬Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦â€”Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ wrap Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿Ã Â¥Â¤
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
        // Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²/Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡Ã Â¥Â¤ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®/Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“/Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â°
        // Ã Â¦Â«Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã¢Å“Â¨ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§â€¡Ã Â¦Å“Ã Â§â€¡Ã Â¦â€¡ Ã Â¦â€ Ã Â¦â€ºÃ Â§â€¡Ã Â¥Â¤
        // Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§â€¡Ã Â¦Å“Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
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
                        const Text(
                          'Ã°Å¸â€â€™',
                          style: TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s.trialActivated
                              ? 'Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€”Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡'
                              : 'Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¨Ã Â¦Â¿',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.trialActivated
                              ? 'Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¸Ã Â¦Â¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¥Â¤ '
                                    'Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â§Â©Ã Â§Â¦ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã¢â‚¬â€ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ '
                                    'Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¥Â¤'
                              : 'Ã¢Å“Â¨ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§â€¡Ã Â¦Å“Ã Â§â€¡ Ã Â¦â€”Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®/Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“/Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾ '
                                    'Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â²Ã Â§â€¡Ã Â¦â€¡ Ã Â§Â©Ã Â§Â¦ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡, '
                                    'Ã Â¦Â¤Ã Â¦â€“Ã Â¦Â¨ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€œ Ã Â¦â€“Ã Â§ÂÃ Â¦Â²Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡Ã Â¥Â¤',
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
                                ? 'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨'
                                : 'Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
// Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿-Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â¦â€ Ã Â¦Âª Ã Â¦Â«Ã Â¦Â°Ã Â§ÂÃ Â¦Â® Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã¢Å“Â¨ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§â€¡Ã Â¦Å“Ã Â§â€¡Ã Â¦Â° Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
// (Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨/Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼)Ã Â¥Â¤ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®, Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“-Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€¡
// Ã Â§Â©Ã Â§Â¦ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€œ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤ Ã Â¦Å“Ã Â¦Â®Ã Â¦Â¾
// Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§â€¡Ã Â¦Å“ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â²Ã Â§ÂÃ Â¦Â¡ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²-Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦Â­
// Ã Â¦Â­Ã Â¦Â¿Ã Â¦â€° (Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸, Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡) Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡Ã Â¥Â¤ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¡ Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¨Ã Â§Â/Ã Â¦Â¡Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¬Ã Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿
// Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Å¸Ã Â¦Âª Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¢Ã Â§ÂÃ Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â«Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€ Ã Â¦Â° Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§â€¡Ã Â¦Å“Ã Â§â€¡
// Ã Â¦Â¯Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¨ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨ _PremiumGate)Ã Â¥Â¤
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
        () => _error =
            'Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®, Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“-Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€œ Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡',
      );
      return;
    }
    setState(() => _error = null);
    await AppSettings.instance.activateTrial(
      name: name,
      dob: _dob!,
      address: address,
    );
    // Ã Â¦ÂÃ Â¦Â°Ã Â¦ÂªÃ Â¦Â° Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡ Ã¢â‚¬â€ Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° _PremiumGate Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦â€¡
    // AppSettings-Ã Â¦ÂÃ Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¨ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¨Ã Â§â€¡ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â²Ã Â§ÂÃ Â¦Â¡ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡
  }

  @override
  Widget build(BuildContext context) {
    // Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Scaffold/Ã Â¦Â¹Ã Â§â€¡Ã Â¦Â¡Ã Â¦Â¾Ã Â¦Â°/Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â² Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â«Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿
    // PremiumScreen-Ã Â¦ÂÃ Â¦Â° ListView-Ã Â¦ÂÃ Â¦Â° Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€ Ã Â¦â€¡Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â® Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¸Ã Â§â€¡
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
              const Center(
                child: Text('Ã°Å¸Å½Â', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦Â°Ã Â¦ÂªÃ Â¦Â° Ã Â§Â©Ã Â§Â¦ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸, PDF '
                'Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸, Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª Ã Â¦â€œ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â§â€šÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡ '
                'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¨Ã Â¥Â¤',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      'Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®',
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
                'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              _DateTimePickerField(
                label:
                    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¨',
                onChanged: (dt) => setState(() => _dob = dt),
              ),
              const SizedBox(height: 14),
              const Text(
                'Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText:
                      'Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾',
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
                    'Ã°Å¸Å½Â Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
// Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â§â€¡Ã Â¦Å“
// =====================================================================

// =====================================================================
// Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€¢Ã Â¦Â¨Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¸Ã Â¦Â¨ (Ã Â¦â€ Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ / Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â®Ã Â§â€¹ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€¡Ã Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â¯Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡)
// =====================================================================

// =====================================================================
// Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€”Ã Â¦Â£Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦â€¡Ã Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ / Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° / Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ / Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼-Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ / Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â²
// Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â²Ã Â§â‚¬Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â§Ë†Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â¤Ã Â§ÂÃ Â¦Â° (Meeus, Astronomical Algorithms Ã¢â‚¬â€œ low
// precision formulae) Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
// Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â§ÂÃ Â¦Â²Ã Â¦Â¤Ã Â¦Â¾: Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â· Ã Â¦â€¢Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¢ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡, Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° ~Ã Â§Â§Ã Â§Â¦ Ã Â¦â€ Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢-Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¸,
// Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ ~Ã Â§Â§-Ã Â§Â¨ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¸Ã Â¥Â¤ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€œ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â¦â€ Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢Ã Â¥Â¤
// =====================================================================

const List<String> _bnDigitMap = [
  'Ã Â§Â¦',
  'Ã Â§Â§',
  'Ã Â§Â¨',
  'Ã Â§Â©',
  'Ã Â§Âª',
  'Ã Â§Â«',
  'Ã Â§Â¬',
  'Ã Â§Â­',
  'Ã Â§Â®',
  'Ã Â§Â¯',
];

/// Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â¾ 'English' Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€“Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦â€¡Ã Â¦â€šÃ Â¦Â°Ã Â§â€¡Ã Â¦Å“Ã Â¦Â¿ Ã Â¦â€¦Ã Â¦â„¢Ã Â§ÂÃ Â¦â€¢Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡, Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦â€¦Ã Â¦â„¢Ã Â§ÂÃ Â¦â€¢Ã Â§â€¡
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
// Ã Â¦Â­Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¸ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â¥Ã Â¦Â¾ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“/Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦Å¸Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Å¸ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â², Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£
// Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¸Ã Â¦Â¾Ã Â¦Â° (Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ API/Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦ÂÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¡/AI Ã Â¦Â®Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â² Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§Â
// Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â®Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨ Ã Â¦Â®Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹)Ã Â¥Â¤ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ 100% Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â§ÂÃ Â¦Â² Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬
// Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â«Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â«Ã Â¦Â² Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§â€¡/Ã Â¦Â¦Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¨
// (_VoiceReminderSheet Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨)Ã Â¥Â¤ Existing ReminderStore/ReminderItem-Ã Â¦ÂÃ Â¦Â°
// Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§ÂÃ Â¦â€¡ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â existing Ã Â¦Å¸Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Å¸-Ã Â¦Â«Ã Â¦Â¿Ã Â¦Â²Ã Â§ÂÃ Â¦Â¡ Ã Â¦â€ Ã Â¦Â°
// Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“/Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â¦Â£ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
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
    'Ã Â§Â¦': '0',
    'Ã Â§Â§': '1',
    'Ã Â§Â¨': '2',
    'Ã Â§Â©': '3',
    'Ã Â§Âª': '4',
    'Ã Â§Â«': '5',
    'Ã Â§Â¬': '6',
    'Ã Â§Â­': '7',
    'Ã Â§Â®': '8',
    'Ã Â§Â¯': '9',
  };

  static String _toLatinDigits(String s) {
    return s.split('').map((c) => _bnToLatinDigit[c] ?? c).join();
  }

  // DateTime.weekday: Ã Â¦Â¸Ã Â§â€¹Ã Â¦Â®Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°=1 Ã¢â‚¬Â¦ Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°=7
  static const List<String> _weekdaysBn = [
    'Ã Â¦Â¸Ã Â§â€¹Ã Â¦Â®Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦Â®Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â²Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â§Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°',
  ];

  static const List<String> _noiseWords = [
    'Ã Â¦Â®Ã Â¦Â¨Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€œ',
    'Ã Â¦Â®Ã Â¦Â¨Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¬Ã Â§â€¡',
    'Ã Â¦Â®Ã Â¦Â¨Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¦Ã Â¦Â¾Ã Â¦â€œ',
    'Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¹',
    'Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¾Ã Â¦â€œ',
    'Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
    'Ã Â¦â€ Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â·Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡',
    'Ã Â¦â€¢Ã Â¦Â¥Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾',
    'Ã Â¦â€¢Ã Â¦Â¥Ã Â¦Â¾',
    ' Ã Â¦Â¯Ã Â§â€¡ ',
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

    // --- Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ ---
    if (text.contains('Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¶Ã Â§Â')) {
      date = today0.add(const Duration(days: 2));
      dateFound = true;
      text = text.replaceAll('Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¶Ã Â§Â', ' ');
    } else if (text.contains(
          'Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²',
        ) ||
        text.contains('Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²')) {
      date = today0.add(const Duration(days: 1));
      dateFound = true;
      text = text
          .replaceAll(
            'Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²',
            ' ',
          )
          .replaceAll(
            'Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²',
            ' ',
          );
    } else if (text.contains('Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â¦â€¢Ã Â§â€¡') ||
        text.contains('Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²')) {
      // Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾ "Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²" Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£Ã Â¦Â¤ Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¬Ã Â§â€¹Ã Â¦ÂÃ Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
      date = today0.add(const Duration(days: 1));
      dateFound = true;
      text = text
          .replaceAll('Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â¦â€¢Ã Â§â€¡', ' ')
          .replaceAll('Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²', ' ');
    } else if (text.contains('Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡') ||
        text.contains('Ã Â¦â€ Ã Â¦Å“')) {
      date = today0;
      dateFound = true;
      text = text
          .replaceAll('Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡', ' ')
          .replaceAll('Ã Â¦â€ Ã Â¦Å“', ' ');
    }

    if (!dateFound) {
      // "Ã Â§Â¨Ã Â§Â« Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“" Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨
      final m = RegExp(
        r'(\d{1,2})\s*Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“',
      ).firstMatch(text);
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
      // Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â® Ã¢â‚¬â€ Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨ "Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°" Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨ Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â§Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
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

    // --- Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ --- (Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨: "Ã Â¦Â¸Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â§Â¯Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼", "Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â§Â¬Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼", "Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤ Ã Â§Â®:Ã Â§Â©Ã Â§Â¦Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼")
    final timeMatch = RegExp(
      r'(Ã Â¦Â¸Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²|Ã Â¦Â¦Ã Â§ÂÃ Â¦ÂªÃ Â§ÂÃ Â¦Â°|Ã Â¦Â¬Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â²|Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾|Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤)?\s*(\d{1,2})(?::(\d{2}))?\s*Ã Â¦Å¸Ã Â¦Â¾(?:Ã Â¦Â¯Ã Â¦Â¼|Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼)?',
    ).firstMatch(text);
    if (timeMatch != null) {
      final period = timeMatch.group(1);
      var h = (int.tryParse(timeMatch.group(2)!) ?? 9) % 12;
      final min = timeMatch.group(3) != null
          ? int.tryParse(timeMatch.group(3)!) ?? 0
          : 0;
      switch (period) {
        case 'Ã Â¦Â¸Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²':
          break; // AM Ã¢â‚¬â€ Ã Â§Â¦-Ã Â§Â§Ã Â§Â§ Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€ Ã Â¦â€ºÃ Â§â€¡
        case 'Ã Â¦Â¦Ã Â§ÂÃ Â¦ÂªÃ Â§ÂÃ Â¦Â°':
        case 'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â²':
        case 'Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾':
          h += 12;
          break;
        case 'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤':
          if (h != 0 && h >= 7)
            h +=
                12; // Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤ Ã Â§Â­-Ã Â§Â§Ã Â§Â§Ã Â¦Å¸Ã Â¦Â¾ Ã¢â€ â€™ PM, Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤/Ã Â¦Â­Ã Â§â€¹Ã Â¦Â°
          break;
      }
      hour = h;
      minute = min;
      timeFound = true;
      text = text.replaceFirst(timeMatch.group(0)!, ' ');
    }

    // --- Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ Ã Â¦â€¦Ã Â¦â€šÃ Â¦Â¶ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â²Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ ---
    var title = text;
    for (final w in _noiseWords) {
      title = title.replaceAll(w, ' ');
    }
    title = title.replaceAll(RegExp(r'[,Ã Â¥Â¤]'), ' ');
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (title.isEmpty)
      title = 'Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°';

    DateTime? when;
    if (dateFound || timeFound) {
      final baseDate = date ?? today0;
      final h =
          hour ??
          9; // Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¡Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¸Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â§Â¯Ã Â¦Å¸Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â­Ã Â¦Â¿Ã Â¦â€°Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
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

/// Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€” Ã Â¦ÂÃ Â¦â€¢ Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Å¸Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Å¸ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° (WhatsApp) Ã Â¦â€œ
/// TTS (Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¶Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹) Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦Â¤Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â¶Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¹
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
  return '''Ã°Å¸ÂªÂ· Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€” Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾
${bnNum(bengaliDay)} ${info.name} ${bnNum(info.year)}, $weekday
${bnNum(now.day)} ${gregMonthBn(now.month)} ${bnNum(now.year)}

Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿: ${tithi.paksha} Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â· Ã¢â‚¬Â¢ ${tithi.name}
Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°: ${PanchangCalculator.nakshatraNames[nakIdx]}
Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼: ${bnTime12(sunrise)}
Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤: ${bnTime12(sunset)}''';
}

const List<String> _gregMonthsBn = [
  'Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿',
  'Ã Â¦Â«Ã Â§â€¡Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿',
  'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¡',
  'Ã Â¦ÂÃ Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â²',
  'Ã Â¦Â®Ã Â§â€¡',
  'Ã Â¦Å“Ã Â§ÂÃ Â¦Â¨',
  'Ã Â¦Å“Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€¡',
  'Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸',
  'Ã Â¦Â¸Ã Â§â€¡Ã Â¦ÂªÃ Â§ÂÃ Â¦Å¸Ã Â§â€¡Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â°',
  'Ã Â¦â€¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦Â¬Ã Â¦Â°',
  'Ã Â¦Â¨Ã Â¦Â­Ã Â§â€¡Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â°',
  'Ã Â¦Â¡Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â°',
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
  static String district = 'Ã Â¦â€¢Ã Â¦Â²Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¾';

  static const Map<String, DistrictLocation> coordinates = {
    'Ã Â¦â€¢Ã Â¦Â²Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¾': DistrictLocation(
      22.5726,
      88.3639,
    ),
    'Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾': DistrictLocation(22.5958, 88.2636),
    'Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â° Ã Â§Â¨Ã Â§Âª Ã Â¦ÂªÃ Â¦Â°Ã Â¦â€”Ã Â¦Â¨Ã Â¦Â¾':
        DistrictLocation(22.7220, 88.4790),
    'Ã Â¦Â¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦Â£ Ã Â§Â¨Ã Â§Âª Ã Â¦ÂªÃ Â¦Â°Ã Â¦â€”Ã Â¦Â¨Ã Â¦Â¾':
        DistrictLocation(22.1667, 88.4000),
    'Ã Â¦Â¹Ã Â§ÂÃ Â¦â€”Ã Â¦Â²Ã Â¦Â¿': DistrictLocation(22.9012, 88.3856),
    'Ã Â¦Â¨Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾': DistrictLocation(23.4058, 88.4993),
    'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¬ Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â§Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨':
        DistrictLocation(23.2324, 87.8615),
    'Ã Â¦ÂªÃ Â¦Â¶Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â® Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â§Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨':
        DistrictLocation(23.6739, 86.9524),
    'Ã Â¦Â®Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¶Ã Â¦Â¿Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦':
        DistrictLocation(24.0964, 88.2482),
    'Ã Â¦Â¬Ã Â§â‚¬Ã Â¦Â°Ã Â¦Â­Ã Â§â€šÃ Â¦Â®': DistrictLocation(
      23.9037,
      87.5382,
    ),
    'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¬ Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â‚¬Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°':
        DistrictLocation(22.2971, 87.9256),
    'Ã Â¦ÂªÃ Â¦Â¶Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â® Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â‚¬Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°':
        DistrictLocation(22.4257, 87.3200),
    'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾': DistrictLocation(
      23.2324,
      87.0715,
    ),
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â²Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾': DistrictLocation(
      23.3320,
      86.3616,
    ),
    'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¦Ã Â¦Â¾': DistrictLocation(25.0084, 88.1414),
    'Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Å“Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°':
        DistrictLocation(25.6236, 88.1240),
    'Ã Â¦Â¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦Â£ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Å“Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°':
        DistrictLocation(25.2160, 88.7770),
    'Ã Â¦Å“Ã Â¦Â²Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€¡Ã Â¦â€”Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿':
        DistrictLocation(26.5416, 88.7273),
    'Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€š': DistrictLocation(
      27.0360,
      88.2627,
    ),
    'Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°':
        DistrictLocation(26.4863, 89.5288),
    'Ã Â¦â€¢Ã Â§â€¹Ã Â¦Å¡Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°': DistrictLocation(
      26.3223,
      89.4472,
    ),
    'Ã Â¦ÂÃ Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®': DistrictLocation(
      22.4498,
      86.9822,
    ),
    'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â¦â€š': DistrictLocation(
      27.0670,
      88.4750,
    ),
  };

  // Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° real-time GPS Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â²Ã Â§â€¡
  // (Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â²Ã Â§â€¡/Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Âª Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡/Ã Â¦ÂÃ Â¦Â°Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡) Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿ Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡
  // Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Å¡Ã Â§ÂÃ Â¦ÂªÃ Â¦Å¡Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â«Ã Â¦Â¿Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€ Ã Â¦Å¸Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾
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
// Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â°/Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° real-time GPS Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤,
// Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾, Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§Â Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€”Ã Â¦Â¾ Ã Â¦Â§Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡
// =====================================================================

class LocationService extends ChangeNotifier {
  LocationService._();
  static final LocationService instance = LocationService._();

  double? gpsLat;
  double? gpsLon;
  // NaN/infinite Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¢Ã Â§ÂÃ Â¦â€¢Ã Â§â€¡ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ (Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¤Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾ Ã¢â‚¬â€ refresh()
  // Ã Â¦Â Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ) hasGps Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨Ã Â§â€¹ "Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â§" Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â§Ã Â¦Â°Ã Â§â€¡, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ isFinite Ã Â¦Å¡Ã Â§â€¡Ã Â¦â€¢
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
        // Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦Å¡Ã Â§ÂÃ Â¦ÂªÃ Â¦Å¡Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â®Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¬Ã Â§â€¡
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 12));
      // Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§Â Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡/Ã Â¦â€¡Ã Â¦Â®Ã Â§ÂÃ Â¦Â²Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â°Ã Â§â€¡ GPS Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸ Ã Â¦Â¹Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡Ã Â¦â€¡ NaN/Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ lat-lon
      // Ã Â¦Â«Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¤ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡
      // NaN Ã Â¦Â¢Ã Â§ÂÃ Â¦â€¢Ã Â§â€¡ "Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”" Ã Â¦â€¦Ã Â¦â€šÃ Â¦Â¶Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â«Ã Â¦Â¾Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾/Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¶ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¤ (Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¡Ã Â§â€¡
      // Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€”Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£)Ã Â¥Â¤ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â§Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡Ã Â¥Â¤
      final la = pos.latitude;
      final lo = pos.longitude;
      final valid =
          la.isFinite &&
          lo.isFinite &&
          la >= -90 &&
          la <= 90 &&
          lo >= -180 &&
          lo <= 180;
      if (!valid)
        return; // Ã Â¦â€¦Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â§ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€š Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â°/Ã Â¦Â®Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨Ã Â¦â€¡ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡
      gpsLat = la;
      gpsLon = lo;
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (_) {
      // GPS Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡/Ã Â¦ÂÃ Â¦Â°Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡/Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§ÂÃ Â¦â€¡ Ã Â¦Â­Ã Â¦Â¾Ã Â¦â„¢Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾,
      // Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡
    } finally {
      _loading = false;
    }
  }
}

// =====================================================================
// Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â­ Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã¢â‚¬â€ Open-Meteo (Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿, Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ API key Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾)
// =====================================================================

/// Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¡ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦ÂÃ Â¦â€¡Ã Â¦Å¸Ã Â§ÂÃ Â¦â€¢Ã Â§Â Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯
/// Open-Meteo-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ "current weather" Ã Â¦ÂÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦ÂªÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡Ã Â¥Â¤
/// Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â² Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦Å¡Ã Â§ÂÃ Â¦ÂªÃ Â¦Å¡Ã Â¦Â¾Ã Â¦Âª "Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡" Ã Â¦Â§Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€
/// Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ Ã Â¦â€¦Ã Â¦â€šÃ Â¦Â¶ Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€ Ã Â¦Å¸Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤
class WeatherService extends ChangeNotifier {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  bool isRaining = false;
  double? tempC;
  DateTime? _lastFetch;
  double? _lastLat;
  double? _lastLon;
  bool _loading = false;

  // WMO weather code Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿/Ã Â¦Â¬Ã Â¦Å“Ã Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿/Ã Â¦Â¬Ã Â¦Â°Ã Â¦Â«Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦Â§Ã Â¦Â°Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¡
  static const Set<int> _rainCodes = {
    51,
    53,
    55,
    56,
    57, // Ã Â¦ÂÃ Â¦Â¿Ã Â¦Â°Ã Â¦Â¿Ã Â¦ÂÃ Â¦Â¿Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿
    61,
    63,
    65,
    66,
    67, // Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿
    80, 81, 82, // hovering/heavy shower
    95, 96, 99, // Ã Â¦Â¬Ã Â¦Å“Ã Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿
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
      // Ã Â¦â€¦Ã Â¦Â«Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨/Ã Â¦ÂÃ Â¦Â°Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾ Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â² Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¬Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â­Ã Â§â€¡Ã Â¦â„¢Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾
    } finally {
      _loading = false;
    }
  }
}

// =====================================================================
// Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®/Ã Â¦Â¨Ã Â¦Â¦Ã Â§â‚¬Ã Â¦Â° Ã Â¦Â¦Ã Â§Æ’Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¯ Ã¢â‚¬â€ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â² Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼-Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€œÃ Â¦Â Ã Â§â€¡-Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡,
// Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â­ Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨Ã Â¦â€œ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
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
  // Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°, Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â²Ã Â§ÂÃ Â¦Âª Ã¢â‚¬â€ Ã Â¦â€”Ã Â¦Â°Ã Â§Â/Ã Â¦â€ºÃ Â¦Â¾Ã Â¦â€”Ã Â¦Â² Ã Â¦Å¡Ã Â¦Â°Ã Â¦Â¾, Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â· Ã Â¦Â¹Ã Â¦Â¾Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â®Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾,
  // Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦Â­Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§ÂÃ Â¦Â° "Ã Â¦Å“Ã Â§â‚¬Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤" Ã Â¦Â¨Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â°
  // Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Å¡Ã Â¦Â²Ã Â§â€¡, Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿Ã Â¦Â° (Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤) Ã Â¦Â²Ã Â§ÂÃ Â¦Âª Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹
  // Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦ÂÃ Â¦â€¢Ã Â§â€¡ Ã Â¦â€¦Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
  late final AnimationController _lifeController;
  Timer? _clockTimer;
  double _sunFrac =
      0.5; // -1 = Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤ (Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€”Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡), 0..1 = Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â­Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â¶
  double _nightFrac =
      0.5; // Ã Â§Â¦..Ã Â§Â§ Ã¢â‚¬â€ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¤Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ (Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡)
  // Ã Â§Â¦ = Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹ (Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Å¸/Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§) Ã¢â€ â€™ Ã Â§Â§ = Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤ (Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²Ã Â¦â€ºÃ Â§â€¡)Ã Â¥Â¤
  // Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤/Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦Â¶Ã Â§â€¡Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â§â€¡ (Ã Â¦â€”Ã Â§â€¹Ã Â¦Â§Ã Â§â€šÃ Â¦Â²Ã Â¦Â¿/Ã Â¦â€°Ã Â¦Â·Ã Â¦Â¾) Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿
  // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤ Ã Â§Â§-Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡
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
    // DateTime.now() Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ (isUtc=false); sunTimes() Ã Â¦Â¯Ã Â¦Â¾ Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¤Ã Â¦Â¾
    // "IST-marked" (Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨ PanchangCalculator._toTrueUtc-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯) Ã¢â‚¬â€ Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡
    // Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â«Ã Â¦Â°Ã Â¦Â®Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦â€ Ã Â¦Â¨Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¤Ã Â§ÂÃ Â¦Â²Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¢ Ã Â¦ËœÃ Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦Â­Ã Â§ÂÃ Â¦Â² Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
    final nowMarked = now.toUtc().add(const Duration(hours: 5, minutes: 30));
    double frac;
    double nightFrac = 0.5;
    double darkAmount;
    // Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â§â€¹Ã Â¦Å¸ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â®/Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· ~Ã Â§Â­% Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€”Ã Â§â€¹Ã Â¦Â§Ã Â§â€šÃ Â¦Â²Ã Â¦Â¿/Ã Â¦â€°Ã Â¦Â·Ã Â¦Â¾ Ã Â¦Â§Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¡
    // Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Å¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡ Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Å¸/Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²Ã Â§â€¡/Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â­Ã Â§â€¡, Ã Â¦Â®Ã Â¦Â¾Ã Â¦ÂÃ Â§â€¡Ã Â¦Â°
    // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â² Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ (Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹Ã Â¦â€¡)
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
    // Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã Â¦Â°Ã Â¦â€š/Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€°Ã Â¦Å“Ã Â§ÂÃ Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²Ã Â¦Â¤Ã Â¦Â¾/Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¶Ã Â¦Â¾ Ã¢â‚¬â€ CosmicBackground-Ã Â¦Â Ã Â¦Â¯Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡
    // Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦Â®Ã Â¦Â¤, Ã Â¦Â®Ã Â¦Â¸Ã Â§Æ’Ã Â¦Â£ Ã Â¦â€”Ã Â§â€¹Ã Â¦Â§Ã Â§â€šÃ Â¦Â²Ã Â¦Â¿/Ã Â¦â€°Ã Â¦Â·Ã Â¦Â¾-Ã Â¦Â¸Ã Â¦Â¹ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡
    // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¨Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡ (Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿) Ã¢â‚¬â€ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¦Ã Â§ÂÃ Â¦â€¡ Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â°
    // Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â® Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦â€œ Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â Ã Â¦Â¾Ã Â§Å½ Ã Â¦Â°Ã Â¦â€š Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾
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
    // GPS Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ GPS-Ã Â¦ÂÃ Â¦Â°, Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â° real Ã Â¦Â¤Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾
    // (Open-Meteo) Ã¢â‚¬â€ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€“Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€œ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼,
    // Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Â¡/Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â¡ Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡
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
                      const Text(
                        'Ã°Å¸Å’Â¡Ã¯Â¸Â',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${bnNum(temp.round())}Ã‚Â° ${LocationService.instance.hasGps ? 'Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨' : AppLocation.district}',
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
  final double
  sunFrac; // -1 Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤, Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ 0..1
  final double
  nightFrac; // Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¤Ã Â¦Å¸Ã Â§ÂÃ Â¦â€¢Ã Â§Â Ã Â¦â€¢Ã Â§â€¡Ã Â¦Å¸Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡, 0..1 (Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¬Ã Â§â€¹Ã Â¦ÂÃ Â¦Â¾Ã Â¦Â¤Ã Â§â€¡)
  final double
  darkAmount; // 0..1 Ã¢â‚¬â€ Ã Â¦â€¢Ã Â¦Â¤Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° (street light/window Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â£ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡)
  final bool isRaining;
  final double rainT;
  final double
  lifeT; // 0..1 Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â²Ã Â§ÂÃ Â¦Âª Ã¢â‚¬â€ Ã Â¦â€”Ã Â¦Â°Ã Â§Â/Ã Â¦â€ºÃ Â¦Â¾Ã Â¦â€”Ã Â¦Â²/Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â·/Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â«Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯
  final SkyPhase sky;

  double get dayAmount => 1.0 - darkAmount;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizonY = h * 0.62;
    final isNight = sunFrac < 0;
    final arc = isNight ? 0.0 : math.sin(math.pi * sunFrac);

    // ---- Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶: SkyPhase Ã Â¦â€¡Ã Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼-Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â®Ã Â¦Â¸Ã Â§Æ’Ã Â¦Â£ Ã Â¦Â°Ã Â¦â€š Ã¢â‚¬â€
    // CosmicBackground-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹Ã Â¦â€¡ Ã Â¦Â¸Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¸Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²/Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨/Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾/Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤ gradient Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼,
    // Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â®Ã Â§â€¡Ã Â¦ËœÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â§Ã Â§â€šÃ Â¦Â¸Ã Â¦Â° Ã Â¦Â°Ã Â¦â„¢Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
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

    // ---- Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â«Ã Â§ÂÃ Â¦Å¸Ã Â§â€¡ Ã Â¦â€œÃ Â¦Â Ã Â§â€¡, Ã Â¦Â®Ã Â§Æ’Ã Â¦Â¦Ã Â§Â Ã Â¦Â®Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â®Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ ----
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

    // ---- Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯/Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦ (Ã Â¦â€œ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹) Ã¢â‚¬â€ Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿/Ã Â¦Â®Ã Â§â€¡Ã Â¦ËœÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â®Ã Â§â€¡Ã Â¦ËœÃ Â§â€¡ Ã Â¦Â¢Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ ----
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

    // ---- Ã Â¦Â¦Ã Â§â€šÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Å¸ ----
    final farHill = Paint()..color = const Color(0xFF17263F);
    final farPath = Path()..moveTo(0, horizonY - 10);
    farPath.quadraticBezierTo(w * 0.22, horizonY - 42, w * 0.42, horizonY - 14);
    farPath.quadraticBezierTo(w * 0.65, horizonY - 46, w * 0.85, horizonY - 12);
    farPath.quadraticBezierTo(w * 0.95, horizonY - 26, w, horizonY - 8);
    farPath.lineTo(w, horizonY + 4);
    farPath.lineTo(0, horizonY + 4);
    farPath.close();
    canvas.drawPath(farPath, farHill);

    // ---- Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€ºÃ Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼/Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Å¸ ----
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

    // ---- Ã Â¦â€”Ã Â¦Â¾Ã Â¦â€º Ã Â¦â€œ Ã Â¦â€¢Ã Â§ÂÃ Â¦ÂÃ Â¦Â¡Ã Â¦Â¼Ã Â§â€¡Ã Â¦ËœÃ Â¦Â° ----
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
      // Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²Ã Â§â€¡, Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â­Ã Â¦Â° Ã Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡
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

    // Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Å¸ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¬Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€œÃ Â¦Â Ã Â§â€¡, Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ Ã Â¦â€°Ã Â¦Â·Ã Â§ÂÃ Â¦Â£ Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¸Ã Â¦Â¹
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

    // Ã Â¦Å¡Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€”Ã Â¦Â°Ã Â§Â/Ã Â¦â€ºÃ Â¦Â¾Ã Â¦â€”Ã Â¦Â² Ã¢â‚¬â€ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼,
    // Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¥Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¾Ã Â¦ÂÃ Â§â€¡Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦ËœÃ Â¦Â¾Ã Â¦Â¸ Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€œ Ã Â¦â€ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â°Ã Â§â€¡
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

    // Ã Â¦ÂªÃ Â¦Â¥Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬ Ã¢â‚¬â€ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¦Ã Â§ÂÃ Â¦â€¡ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡ Ã Â¦Â¹Ã Â§â€¡Ã Â¦ÂÃ Â¦Å¸Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾-Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡, Ã Â¦ÂªÃ Â¦Â¾ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â²Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¾Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â­Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â¿ Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼
    void walkingPerson(
      double pathStartX,
      double pathEndX,
      double baseY,
      double scale,
      double phase,
    ) {
      if (dayAmount < 0.02) return;
      final tRaw = (lifeT + phase) % 1.0;
      final tri = tRaw < 0.5
          ? tRaw * 2
          : 2 -
                tRaw *
                    2; // 0..1..0 (Ã Â¦Â¯Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾-Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â¾)
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

    // ---- Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€”Ã Â¦Â°Ã Â§Â-Ã Â¦â€ºÃ Â¦Â¾Ã Â¦â€”Ã Â¦Â² Ã Â¦â€œ Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â«Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â· ----
    grazingAnimal(w * 0.44, horizonY + 16, 1.0, 0.0, isGoat: false);
    grazingAnimal(w * 0.58, horizonY + 15, 0.8, 2.1, isGoat: true);
    walkingPerson(w * 0.30, w * 0.46, horizonY + 14, 1.0, 0.15);

    // ---- Ã Â¦Â¨Ã Â¦Â¦Ã Â§â‚¬/Ã Â¦ÂªÃ Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â° (Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²Ã Â¦Â¨Ã Â¦Â¸Ã Â¦Â¹) ----
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

    // Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²Ã Â¦Â¨
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
    // Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â²Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¢Ã Â§â€¡Ã Â¦â€°Ã Â¦Â°Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾
    final ripple = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final y = horizonY + 28 + i * 10.0;
      if (y > h) break;
      canvas.drawLine(Offset(0, y), Offset(w, y), ripple);
    }

    // ---- Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿ ----
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
  index; // 0..29 (0..14 = Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¦..Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾, 15..29 = Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¦..Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾)
  final String
  paksha; // Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â² / Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£
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
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¦',
    'Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¤Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾',
    'Ã Â¦Â¤Ã Â§Æ’Ã Â¦Â¤Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾',
    'Ã Â¦Å¡Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¥Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â®Ã Â§â‚¬',
    'Ã Â¦Â·Ã Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â§â‚¬',
    'Ã Â¦Â¸Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¤Ã Â¦Â®Ã Â§â‚¬',
    'Ã Â¦â€¦Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â®Ã Â§â‚¬',
    'Ã Â¦Â¨Ã Â¦Â¬Ã Â¦Â®Ã Â§â‚¬',
    'Ã Â¦Â¦Ã Â¦Â¶Ã Â¦Â®Ã Â§â‚¬',
    'Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬',
    'Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬',
    'Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬',
    'Ã Â¦Å¡Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬',
  ];

  static const List<String> nakshatraNames = [
    'Ã Â¦â€¦Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨Ã Â§â‚¬',
    'Ã Â¦Â­Ã Â¦Â°Ã Â¦Â£Ã Â§â‚¬',
    'Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾',
    'Ã Â¦Â°Ã Â§â€¹Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â£Ã Â§â‚¬',
    'Ã Â¦Â®Ã Â§Æ’Ã Â¦â€”Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¾',
    'Ã Â¦â€ Ã Â¦Â°Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¨Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¸Ã Â§Â',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
    'Ã Â¦â€¦Ã Â¦Â¶Ã Â§ÂÃ Â¦Â²Ã Â§â€¡Ã Â¦Â·Ã Â¦Â¾',
    'Ã Â¦Â®Ã Â¦ËœÃ Â¦Â¾',
    'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â«Ã Â¦Â¾Ã Â¦Â²Ã Â§ÂÃ Â¦â€”Ã Â§ÂÃ Â¦Â¨Ã Â§â‚¬',
    'Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Â«Ã Â¦Â¾Ã Â¦Â²Ã Â§ÂÃ Â¦â€”Ã Â§ÂÃ Â¦Â¨Ã Â§â‚¬',
    'Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾',
    'Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾',
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â¤Ã Â§â‚¬',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â¾',
    'Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾',
    'Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¾',
    'Ã Â¦Â®Ã Â§â€šÃ Â¦Â²Ã Â¦Â¾',
    'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â¾Ã Â¦Â¢Ã Â¦Â¼Ã Â¦Â¾',
    'Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â¾Ã Â¦Â¢Ã Â¦Â¼Ã Â¦Â¾',
    'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â£Ã Â¦Â¾',
    'Ã Â¦Â§Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¾',
    'Ã Â¦Â¶Ã Â¦Â¤Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â·Ã Â¦Â¾',
    'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦ÂªÃ Â¦Â¦',
    'Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦ÂªÃ Â¦Â¦',
    'Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¬Ã Â¦Â¤Ã Â§â‚¬',
  ];

  static const List<String> rashiNames = [
    'Ã Â¦Â®Ã Â§â€¡Ã Â¦Â·',
    'Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·',
    'Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¨',
    'Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢Ã Â¦Å¸',
    'Ã Â¦Â¸Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¹',
    'Ã Â¦â€¢Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
    'Ã Â¦Â¤Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾',
    'Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¶Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦â€¢',
    'Ã Â¦Â§Ã Â¦Â¨Ã Â§Â',
    'Ã Â¦Â®Ã Â¦â€¢Ã Â¦Â°',
    'Ã Â¦â€¢Ã Â§ÂÃ Â¦Â®Ã Â§ÂÃ Â¦Â­',
    'Ã Â¦Â®Ã Â§â‚¬Ã Â¦Â¨',
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

  /// Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡Ã Â¦Â° apparent ecliptic longitude (Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿) Ã¢â‚¬â€ Meeus ch.25 Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â®Ã Â§ÂÃ Â¦Â¨-Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â§ÂÃ Â¦Â²Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°
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

  /// Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â° apparent ecliptic longitude (Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿) Ã¢â‚¬â€ Meeus ch.47 truncated series (~Ã Â§Â§Ã Â§Â¦Ã¢â‚¬Â² Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â§ÂÃ Â¦Â²)
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
      23.8531; // Lahiri ayanamsa, Ã Â§Â¨Ã Â§Â¦Ã Â§Â¦Ã Â§Â¦ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢
  static double ayanamsa(double jd) {
    final years = (jd - 2451545.0) / 365.25;
    return _ayanamsaJ2000 +
        years *
            0.013972; // ~Ã Â§Â«Ã Â§Â¦.Ã Â§Â¨Ã Â§Âª Ã Â¦â€ Ã Â¦Â°Ã Â§ÂÃ Â¦â€¢-Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡/Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°
  }

  // -------------------------------------------------------------------
  // Ã Â¦Â®Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â²/Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿/Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°/Ã Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿ Ã¢â‚¬â€ real heliocentric Keplerian orbital elements
  // (NASA JPL "Keplerian Elements for Approximate Positions of the Major
  // Planets", Ã Â§Â§Ã Â§Â®Ã Â§Â¦Ã Â§Â¦-Ã Â§Â¨Ã Â§Â¦Ã Â§Â«Ã Â§Â¦ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â² Ã Â¦â€¢Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡, Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸:
  // https://ssd.jpl.nasa.gov/planets/approx_pos.html)Ã Â¥Â¤ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
  // Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡: [a, aDot, e, eDot, I, IDot, L, LDot, peri, periDot, node,
  // nodeDot] Ã¢â‚¬â€ a = AU, Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ (Ã Â¦â€œ Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿/Ã Â¦Å“Ã Â§ÂÃ Â¦Â²Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¨-Ã Â¦Â¶Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¦Ã Â§â‚¬)Ã Â¥Â¤
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
    // Ã Â¦â€¡Ã Â¦â€°Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦â€œ Ã Â¦Â¨Ã Â§â€¡Ã Â¦ÂªÃ Â¦Å¡Ã Â§ÂÃ Â¦Â¨ Ã¢â‚¬â€ Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â§â€¡ "Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬Ã Â§â€¡
    // Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€”Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦â€œÃ Â¦ÂªÃ Â¦Â°Ã Â§â€¡" Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¹ (Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ NASA JPL Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â²)
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

  /// Kepler Ã Â¦Â¸Ã Â¦Â®Ã Â§â‚¬Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£ (M = E Ã¢Ë†â€™ eÃ‚Â·sin E) Newton-Raphson Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨, Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¡Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â«Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¤
  static double _solveKepler(double mDeg, double e) {
    final mRad = _deg2rad(
      _norm360(mDeg + 180) - 180,
    ); // -180..180 Ã Â¦Â°Ã Â§â€¡Ã Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â§â€¡
    double eRad = mRad + e * math.sin(mRad);
    for (int i = 0; i < 8; i++) {
      final delta =
          (eRad - e * math.sin(eRad) - mRad) / (1 - e * math.cos(eRad));
      eRad -= delta;
      if (delta.abs() < 1e-9) break;
    }
    return eRad;
  }

  /// Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â§â€¡Ã Â¦Â° heliocentric ecliptic (J2000) x,y,z (AU) Ã¢â‚¬â€ [el] Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¹
  /// [_planetElements]-Ã Â¦ÂÃ Â¦Â° Ã Â§Â§Ã Â§Â¨Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾, [t] Ã Â¦Å“Ã Â§ÂÃ Â¦Â²Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¶Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¦Ã Â§â‚¬ (J2000 Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡)
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

  /// [planet]-Ã Â¦ÂÃ Â¦Â° geocentric apparent ecliptic longitude (Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿) Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§Æ’Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â¬Ã Â§â‚¬Ã Â¦Â°
  /// heliocentric Ã Â¦Â­Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ geocentric Ã Â¦Â­Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸Ã Â¦Â° Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ atan2 Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
  /// (Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹Ã Â¦Â° Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼/aberration Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦ Ã¢â‚¬â€ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¯Ã Â¦Â¥Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â§ÂÃ Â¦Â²)
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
  // Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯: Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬Ã Â¦Â° GPS
  // Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€”Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦â€œÃ Â¦ÂªÃ Â¦Â°Ã Â§â€¡ (Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¯Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€”Ã Â¦Â¤) Ã Â¦Â¤Ã Â¦Â¾
  // Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡ ecliptic Ã¢â€ â€™ equatorial Ã¢â€ â€™ horizontal (altitude/azimuth)
  // Ã Â¦Â°Ã Â§â€šÃ Â¦ÂªÃ Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â¥Â¤ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Meeus, Astronomical Algorithms, ch.13-Ã Â¦ÂÃ Â¦Â°
  // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â "Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡ Ã Â¦â€œÃ Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡" Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯
  // Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€°Ã Â¦Å¡Ã Â§ÂÃ Â¦Å¡-Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â§ÂÃ Â¦Â²Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¹Ã Â¦Å“Ã Â¦Â¨ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡Ã Â¥Â¤

  /// [planet]-Ã Â¦ÂÃ Â¦Â° geocentric ecliptic longitude, latitude (Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿) Ã Â¦â€œ Ã Â¦Â¦Ã Â§â€šÃ Â¦Â°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¬
  /// (AU) Ã¢â‚¬â€ heliocentric Ã Â¦Â­Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸Ã Â¦Â° Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾, Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿-Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â§Æ’Ã Â¦Â¤
  /// [_planetGeoLongitude]-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§Â ecliptic latitude/Ã Â¦Â¦Ã Â§â€šÃ Â¦Â°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¸Ã Â¦Â¹
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

  /// Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â° ecliptic latitude (Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿) Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦ÂªÃ Â¦Â¦ (~Ã Â§Â«.Ã Â§Â§Ã Â§Â©Ã‚Â°) Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢;
  /// Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡ Ã Â¦â€œÃ Â¦Â Ã Â¦Â¾/Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¾ (visibility) Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¯Ã Â¦Â¥Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â§ÂÃ Â¦Â²
  static double moonLatitude(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    final f = _deg2rad(_norm360(93.2720950 + 483202.0175233 * t));
    return 5.128 * math.sin(f);
  }

  static const double _obliquityDeg =
      23.4397; // Ã Â¦ÂªÃ Â§Æ’Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â¬Ã Â§â‚¬Ã Â¦Â° Ã Â¦â€¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¹Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¨

  /// Ecliptic (lon,lat) Ã¢â€ â€™ Equatorial (RA,Dec), Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡
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

  /// Greenwich Mean Sidereal Time (Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿) Ã¢â‚¬â€ Meeus ch.12 Ã Â¦Â¸Ã Â§â€šÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°
  static double _gmstDeg(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    final gmst =
        280.46061837 +
        360.98564736629 * (jd - 2451545.0) +
        0.000387933 * t * t -
        (t * t * t) / 38710000.0;
    return _norm360(gmst);
  }

  /// Equatorial (RA,Dec) Ã¢â€ â€™ altitude/azimuth (Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿), Ã Â¦ÂªÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â°
  /// lat/lon Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã¢â‚¬â€ azimuth Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â° Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡ Ã Â¦ËœÃ Â§ÂÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â®Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¾ (compass-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹)
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
  /// 'uranus', 'neptune') Ã¢â‚¬â€ GPS Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡
  /// altitude/azimuth (Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿)Ã Â¥Â¤ altitude > 0 Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€”Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦â€œÃ Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦â€¦Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â§Å½
  /// Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬Ã Â§â€¡ (Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶ Ã Â¦Â¯Ã Â¦Â¥Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡) Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¥Ã Â¦Â¾Ã Â¥Â¤
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

  /// Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§Â (Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° mean ascending node) Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡
  /// heliocentric orbital elements Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤ Meeus ch.47-Ã Â¦ÂÃ Â¦Â°
  /// mean-node Ã Â¦Â¸Ã Â§â€šÃ Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ (true node Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼, mean node Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡
  /// Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾/Ã Â¦Â¸Ã Â¦Â«Ã Â¦Å¸Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼)Ã Â¥Â¤ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¤Ã Â§Â Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§Â Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢
  /// Ã Â§Â§Ã Â§Â®Ã Â§Â¦Ã‚Â° Ã Â¦â€°Ã Â¦Â²Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤
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

  /// Ã Â¦â€ Ã Â¦Å“ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§Â Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ (sidereal) Ã¢â‚¬â€ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§Â Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬ Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â²Ã Â§â€¡ (Ã Â¦Â¬ Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¨
  /// Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾, Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â§Ã Â¦Â°Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼)
  static int rahuRashiIndexFor(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final lon = meanLunarNodeLongitude(jd);
    final sidereal = _norm360(lon - ayanamsa(jd));
    return (sidereal / 30.0).floor().clamp(0, 11);
  }

  /// Ã Â¦â€ Ã Â¦Å“ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¤Ã Â§Â Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦Â° Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â°Ã Â§â‚¬Ã Â¦Â¤ (Ã Â§Â§Ã Â§Â®Ã Â§Â¦Ã‚Â°) Ã Â¦ËœÃ Â¦Â°Ã Â§â€¡
  static int ketuRashiIndexFor(DateTime localDateTime) {
    final rahu = rahuRashiIndexFor(localDateTime);
    return (rahu + 6) % 12;
  }

  /// Ã Â¦â€ Ã Â¦Å“ [planet] Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦â€ Ã Â¦â€ºÃ Â§â€¡ (sidereal, Lahiri ayanamsa Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡)
  static int planetRashiIndexFor(String planet, DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final lon = _planetGeoLongitude(planet, jd);
    final sidereal = _norm360(lon - ayanamsa(jd));
    return (sidereal / 30.0).floor().clamp(0, 11);
  }

  /// [planet] Ã Â¦Â¬Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬ (retrograde) Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Å“ Ã Â¦â€œ Ã Â§Â§ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â° longitude Ã Â¦Â¤Ã Â§ÂÃ Â¦Â²Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡
  static bool planetIsRetrograde(String planet, DateTime localDateTime) {
    final jdNow = julianDay(_toTrueUtc(localDateTime));
    final lonNow = _planetGeoLongitude(planet, jdNow);
    final lonPrev = _planetGeoLongitude(planet, jdNow - 1.0);
    var diff = lonNow - lonPrev;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff < 0;
  }

  /// Ã Â¦â€ Ã Â¦Å“ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦â€ Ã Â¦â€ºÃ Â§â€¡ (sidereal)
  static int sunRashiIndexFor(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final sun = sunLongitude(jd);
    final sidereal = _norm360(sun - ayanamsa(jd));
    return (sidereal / 30.0).floor().clamp(0, 11);
  }

  /// [sunTimes]/[BengaliDateUtil._sankranti] Ã Â¦Â¯Ã Â§â€¡Ã Â¦â€¡ DateTime Ã Â¦Â«Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¤ Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹
  /// isUtc=true Ã Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â²Ã Â§â€¡ IST Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²-Ã Â¦ËœÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€“Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ (Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡
  /// .hour/.minute Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¸Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ IST Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼) Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡ "IST-marked" Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â¾
  /// Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡Ã Â¥Â¤ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¹ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Å“Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ millisecondsSinceEpoch
  /// Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â§Â« Ã Â¦ËœÃ Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â§Â©Ã Â§Â¦ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦ÂÃ Â¦â€”Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡Ã Â¥Â¤ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦ÂÃ Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿
  /// Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡ (julianDay) Ã Â¦Â¬Ã Â¦Â¾ DateTime.now()-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡
  /// Ã Â¦Â¤Ã Â§ÂÃ Â¦Â²Ã Â¦Â¨Ã Â¦Â¾/Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¹Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ Ã Â§Â«:Ã Â§Â©Ã Â§Â¦ Ã Â¦ËœÃ Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â­Ã Â§ÂÃ Â¦Â² Ã Â¦Â¹Ã Â¦Â¤Ã Â§â€¹ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â­Ã Â§ÂÃ Â¦Â² Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦â€œ
  /// Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨-Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡ Ã Â¦Â­Ã Â§ÂÃ Â¦Â² Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£ Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â²Ã Â¥Â¤ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¥Ã Â¦Â¡
  /// Ã Â¦Â¦Ã Â§ÂÃ Â¦â€¡ Ã Â¦Â§Ã Â¦Â°Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¡Ã Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Å¸Ã Â¦â€¡ Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼: DateTime.now()-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ local
  /// Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¡Ã Â¦Â¿Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦â€¦Ã Â¦Â«Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ UTC-Ã Â¦Â¤Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¨Ã Â§â€¡, Ã Â¦â€ Ã Â¦Â° IST-marked Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Å“Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸
  /// Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¡ Ã Â§Â«:Ã Â§Â©Ã Â§Â¦ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”-Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â² Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â«Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
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
    final paksha = idx < 15
        ? 'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²'
        : 'Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£';
    final within = idx % 15;
    final name = within == 14
        ? (idx < 15
              ? 'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾'
              : 'Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾')
        : _tithiNames[within];
    return TithiInfo(idx, paksha, name, fraction);
  }

  /// [moment]-Ã Â¦Â Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â¦Â¿Ã Â¦Â² Ã Â¦â€ Ã Â¦Â° Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦â€”Ã Â¦Â¡Ã Â¦Â¼/
  /// Ã Â¦â€ Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¨Ã Â¦Â¾, [tithiFor]-Ã Â¦ÂÃ Â¦Â° Ã Â¦â€œÃ Â¦ÂªÃ Â¦Â°Ã Â¦â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¡ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤
  /// Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ (Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â§ÂÃ Â¦Â²Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼) Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ existing Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿
  /// calculation-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¡ Ã Â§Â§Ã Â§Â¦Ã Â§Â¦% Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â®Ã Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦Â®Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â² Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤
  static (DateTime start, DateTime end) tithiTiming(DateTime moment) {
    final idx = tithiFor(moment).index;

    DateTime searchEdge({required bool forward}) {
      var known =
          moment; // Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ == idx, Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤
      var unknown = moment.add(Duration(hours: forward ? 6 : -6));
      // coarse Ã Â¦Â§Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡ Ã Â¦Â§Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡ Ã Â¦Â¸Ã Â§â‚¬Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦â€“Ã Â§ÂÃ Â¦ÂÃ Â¦Å“Ã Â§â€¡ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ (Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£Ã Â¦Â¤ Ã Â§Â§Ã Â§Â¯-Ã Â§Â¨Ã Â§Â¬ Ã Â¦ËœÃ Â¦Â£Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾
      // Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â§Â¬ Ã Â¦ËœÃ Â¦Â£Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â§Â§Ã Â§Â¦ Ã Â¦Â§Ã Â¦Â¾Ã Â¦Âª = Ã Â§Â¬Ã Â§Â¦ Ã Â¦ËœÃ Â¦Â£Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¥Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦Â¨)
      for (int i = 0; i < 10 && tithiFor(unknown).index == idx; i++) {
        known = unknown;
        unknown = unknown.add(Duration(hours: forward ? 6 : -6));
      }
      // Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¡ Ã¢â‚¬â€ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â§ÂÃ Â¦Â²Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¨Ã Â¦Â¾
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

  /// Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¦ (Ã Â§Â§-Ã Â§Âª) Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯
  static int nakshatraPadaFor(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final moon = moonLongitude(jd);
    final sidereal = _norm360(moon - ayanamsa(jd));
    const nakSpan = 360.0 / 27.0;
    final withinNak = sidereal % nakSpan;
    return (withinNak / (nakSpan / 4)).floor().clamp(0, 3) + 1;
  }

  /// Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â¤ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ (Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€ Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯)
  static double moonAgeDays(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final sun = sunLongitude(jd);
    final moon = moonLongitude(jd);
    final elong = _norm360(moon - sun);
    return elong / 360.0 * 29.530588853;
  }

  /// Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ (IST) Ã¢â‚¬â€ Sunrise equation (Meeus/NOAA Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â²Ã Â§â‚¬Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¸Ã Â¦â€šÃ Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â¦Â°Ã Â¦Â£)
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
    // Ã Â¦ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â§â‚¬ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â®: Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼-Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ Ã Â§Â® Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€”
    const orderByWeekday = {
      1: 2, // Ã Â¦Â¸Ã Â§â€¹Ã Â¦Â®Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      2: 7, // Ã Â¦Â®Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â²Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      3: 5, // Ã Â¦Â¬Ã Â§ÂÃ Â¦Â§Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      4: 6, // Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      5: 4, // Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      6: 3, // Ã Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      7: 8, // Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
    };
    final part = orderByWeekday[localDate.weekday] ?? 8;
    final start = st.sunrise.add(segment * (part - 1));
    final end = st.sunrise.add(segment * part);
    return {'start': start, 'end': end};
  }

  /// Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¿Ã Â§Å½ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼-Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¾Ã Â¦Â®Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¿ (solar noon) Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â°
  /// Ã‚Â±Ã Â§Â¨Ã Â§Âª Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¸, Ã Â¦ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â§â‚¬ Ã Â¦Â¸Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Å“Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¨ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Â¬Ã Â§ÂÃ Â¦Â§Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â§â€¹Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯)Ã Â¥Â¤
  /// Ã Â¦ÂÃ Â¦â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¬ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦â€¡ findAuspiciousMuhurtas()-Ã Â¦Â Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â¦Â¿Ã Â¦Â² Ã¢â‚¬â€
  /// Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â¶Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¹ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â®Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨/Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€œ (Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨
  /// Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¬ Ã Â¦â€ºÃ Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦â€¡, Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¨Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡) Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
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

  /// Ã Â¦Â¯Ã Â¦Â®Ã Â¦â€”Ã Â¦Â£Ã Â§ÂÃ Â¦Â¡ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² (Ã Â¦ÂÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼) Ã¢â‚¬â€ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â° Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦ÂªÃ Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬:
  /// Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼-Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ Ã Â§Â® Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡, Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â§â‚¬ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸
  /// Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€” (source: Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€” Ã Â¦Â¸Ã Â§â€šÃ Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã¢â‚¬â€ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§Â/Ã Â¦Â¯Ã Â¦Â®/Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡
  /// Ã Â¦ÂªÃ Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°-Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â², Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦ÂÃ Â¦â€¢Ã Â§â€¡ Ã Â¦â€¦Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â°
  /// Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€”Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾)Ã Â¥Â¤
  static Map<String, DateTime> yamagandaKalam(
    DateTime localDate, {
    double? lat,
    double? lon,
  }) {
    final st = sunTimes(localDate, lat: lat, lon: lon);
    final segment = st.sunset.difference(st.sunrise) ~/ 8;
    const orderByWeekday = {
      1: 4, // Ã Â¦Â¸Ã Â§â€¹Ã Â¦Â®Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      2: 3, // Ã Â¦Â®Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â²Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      3: 2, // Ã Â¦Â¬Ã Â§ÂÃ Â¦Â§Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      4: 1, // Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      5: 7, // Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      6: 6, // Ã Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      7: 5, // Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
    };
    final part = orderByWeekday[localDate.weekday] ?? 8;
    final start = st.sunrise.add(segment * (part - 1));
    final end = st.sunrise.add(segment * part);
    return {'start': start, 'end': end};
  }

  /// Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² (Ã Â¦ÂÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼) Ã¢â‚¬â€ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â²/Ã Â¦Â¯Ã Â¦Â®Ã Â¦â€”Ã Â¦Â£Ã Â§ÂÃ Â¦Â¡Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â§Â®-Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€” Ã Â¦ÂªÃ Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â¦Â¤Ã Â¦Â¿,
  /// Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°-Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€” Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ (Ã Â¦ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â§â‚¬ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€” Ã Â¦Â¸Ã Â§â€šÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°)Ã Â¥Â¤
  static Map<String, DateTime> gulikaKalam(
    DateTime localDate, {
    double? lat,
    double? lon,
  }) {
    final st = sunTimes(localDate, lat: lat, lon: lon);
    final segment = st.sunset.difference(st.sunrise) ~/ 8;
    const orderByWeekday = {
      1: 6, // Ã Â¦Â¸Ã Â§â€¹Ã Â¦Â®Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      2: 5, // Ã Â¦Â®Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â²Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      3: 4, // Ã Â¦Â¬Ã Â§ÂÃ Â¦Â§Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      4: 3, // Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      5: 2, // Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      6: 1, // Ã Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
      7: 7, // Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
    };
    final part = orderByWeekday[localDate.weekday] ?? 8;
    final start = st.sunrise.add(segment * (part - 1));
    final end = st.sunrise.add(segment * part);
    return {'start': start, 'end': end};
  }

  /// Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â£/Ã Â¦Â¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦Â£Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â£ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨ (sidereal) Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦ËœÃ Â¦Â¿Ã Â¦Â®Ã Â¦Â¾ Ã Â¦Â®Ã Â¦â€¢Ã Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡
  /// (Ã Â§Â¨Ã Â§Â­Ã Â§Â¦Ã‚Â°) Ã Â¦Â¢Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¨ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· (Ã Â§Â¯Ã Â§Â¦Ã‚Â°) Ã Â¦ÂªÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â£, Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼
  /// Ã Â¦Â¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦Â£Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â£ Ã¢â‚¬â€ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿/Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¯Ã Â§â€¡ sidereal longitude Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼,
  /// Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œ Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¨Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ (Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ astronomy model Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼)Ã Â¥Â¤
  static String ayana(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final sidereal = _norm360(sunLongitude(jd) - ayanamsa(jd));
    final inUttarayana = sidereal >= 270.0 || sidereal < 90.0;
    return inUttarayana
        ? 'Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â£'
        : 'Ã Â¦Â¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦Â£Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â£';
  }

  /// Ã Â¦Â¶Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¦ Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â§â‚¬ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â¦Â°Ã Â§ÂÃ Â¦â€¢ (Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â¨ + Ã Â§Â«Ã Â§Â§Ã Â§Â«)
  static int shakaYearFromBengali(int bengaliYear) => bengaliYear + 515;

  static String weekdayName(DateTime d) {
    const bn = {
      1: 'Ã Â¦Â¸Ã Â§â€¹Ã Â¦Â®Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°',
      2: 'Ã Â¦Â®Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â²Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°',
      3: 'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â§Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°',
      4: 'Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°',
      5: 'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°',
      6: 'Ã Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°',
      7: 'Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°',
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
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦â€¢Ã Â¦Â®Ã Â§ÂÃ Â¦Â­',
    'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â‚¬Ã Â¦Â¤Ã Â¦Â¿',
    'Ã Â¦â€ Ã Â¦Â¯Ã Â¦Â¼Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¨',
    'Ã Â¦Â¸Ã Â§Å’Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€”Ã Â§ÂÃ Â¦Â¯',
    'Ã Â¦Â¶Ã Â§â€¹Ã Â¦Â­Ã Â¦Â¨',
    'Ã Â¦â€¦Ã Â¦Â¤Ã Â¦Â¿Ã Â¦â€”Ã Â¦Â£Ã Â§ÂÃ Â¦Â¡',
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾',
    'Ã Â¦Â§Ã Â§Æ’Ã Â¦Â¤Ã Â¦Â¿',
    'Ã Â¦Â¶Ã Â§â€šÃ Â¦Â²',
    'Ã Â¦â€”Ã Â¦Â£Ã Â§ÂÃ Â¦Â¡',
    'Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â¦Â¿',
    'Ã Â¦Â§Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¬',
    'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ËœÃ Â¦Â¾Ã Â¦Â¤',
    'Ã Â¦Â¹Ã Â¦Â°Ã Â§ÂÃ Â¦Â·Ã Â¦Â£',
    'Ã Â¦Â¬Ã Â¦Å“Ã Â§ÂÃ Â¦Â°',
    'Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â¦Â¿',
    'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¤Ã Â§â‚¬Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¤',
    'Ã Â¦Â¬Ã Â¦Â°Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¨',
    'Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Ëœ',
    'Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¬',
    'Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§',
    'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯',
    'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­',
    'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²',
    'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â§ÂÃ Â¦Â®',
    'Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°',
    'Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â§Ã Â§Æ’Ã Â¦Â¤Ã Â¦Â¿',
  ];

  static int yogaIndexFor(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final sum = _norm360(sunLongitude(jd) + moonLongitude(jd));
    return (sum / (360.0 / 27.0)).floor().clamp(0, 26);
  }

  static const List<String> _karanaMovingNames = [
    'Ã Â¦Â¬Ã Â¦Â¬',
    'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¬',
    'Ã Â¦â€¢Ã Â§Å’Ã Â¦Â²Ã Â¦Â¬',
    'Ã Â¦Â¤Ã Â§Ë†Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â²',
    'Ã Â¦â€”Ã Â¦Â°',
    'Ã Â¦Â¬Ã Â¦Â£Ã Â¦Â¿Ã Â¦Å“',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿',
  ];
  static const List<String> _karanaFixedNames = [
    'Ã Â¦Â¶Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¿',
    'Ã Â¦Å¡Ã Â¦Â¤Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¦',
    'Ã Â¦Â¨Ã Â¦Â¾Ã Â¦â€”',
    'Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦ËœÃ Â§ÂÃ Â¦Â¨',
  ];

  /// Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ = Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£ (Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£ ~Ã Â§Â¬Ã‚Â°)Ã Â¥Â¤ Ã Â¦Â®Ã Â§â€¹Ã Â¦Å¸ Ã Â§Â¬Ã Â§Â¦Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦â€¦Ã Â¦Â°Ã Â§ÂÃ Â¦Â§-Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â®Ã Â¦Å¸Ã Â¦Â¿
  /// Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦ËœÃ Â§ÂÃ Â¦Â¨ (Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¿Ã Â¦Â°), Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦ÂªÃ Â¦Â° Ã Â§Â­Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£ Ã Â§Â® Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿
  /// Ã Â§Â©Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£ (Ã Â¦Â¶Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¿, Ã Â¦Å¡Ã Â¦Â¤Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¦, Ã Â¦Â¨Ã Â¦Â¾Ã Â¦â€”)Ã Â¥Â¤
  static String karanaFor(DateTime localDateTime) {
    final jd = julianDay(_toTrueUtc(localDateTime));
    final elong = _norm360(moonLongitude(jd) - sunLongitude(jd));
    final half = (elong / 6.0).floor().clamp(0, 59);
    if (half == 0)
      return _karanaFixedNames[3]; // Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦ËœÃ Â§ÂÃ Â¦Â¨
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

  /// Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿ (Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶) Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â¥Â¤
  /// Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â° Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ (Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â¶Ã Â¦Â¾Ã Â¦â€“ = Ã Â§Â§Ã Â§Âª Ã Â¦ÂÃ Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â²) Ã Â¦Â§Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¤Ã Â§â€¹, Ã Â¦Â¯Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¢ Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°Ã Â§â€¡Ã Â¦â€¡
  /// Ã Â¦ÂÃ Â¦â€¢ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨ Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¢Ã Â§ÂÃ Â¦â€¢Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°
  /// Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â® Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦Â§Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦ÂªÃ Â¦Â¶Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¬Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â®)Ã Â¥Â¤
  static const List<String> _monthNames = [
    'Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â¶Ã Â¦Â¾Ã Â¦â€“',
    'Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§Ë†Ã Â¦Â·Ã Â§ÂÃ Â¦Â ',
    'Ã Â¦â€ Ã Â¦Â·Ã Â¦Â¾Ã Â¦Â¢Ã Â¦Â¼',
    'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â£',
    'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°',
    'Ã Â¦â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨',
    'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢',
    'Ã Â¦â€¦Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â£',
    'Ã Â¦ÂªÃ Â§Å’Ã Â¦Â·',
    'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Ëœ',
    'Ã Â¦Â«Ã Â¦Â¾Ã Â¦Â²Ã Â§ÂÃ Â¦â€”Ã Â§ÂÃ Â¦Â¨',
    'Ã Â¦Å¡Ã Â§Ë†Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°',
  ];

  /// Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨ (sidereal) Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦ËœÃ Â¦Â¿Ã Â¦Â®Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯
  static double _siderealSunLon(DateTime utc) {
    final jd = PanchangCalculator.julianDay(utc);
    return PanchangCalculator._norm360(
      PanchangCalculator.sunLongitude(jd) - PanchangCalculator.ayanamsa(jd),
    );
  }

  /// Ã Â¦Â²Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â£ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â¤ Ã Â¦Â¦Ã Â§â€šÃ Â¦Â°Ã Â§â€¡ (-Ã Â§Â§Ã Â§Â®Ã Â§Â¦..+Ã Â§Â§Ã Â§Â®Ã Â§Â¦): Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â° Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦â€¹Ã Â¦Â£Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â®Ã Â¦â€¢, Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â§Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â®Ã Â¦â€¢
  static double _lonOffset(DateTime utc, double target) {
    var d = (_siderealSunLon(utc) - target) % 360.0;
    if (d > 180) d -= 360;
    if (d < -180) d += 360;
    return d;
  }

  /// [gYear] Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â¶Ã Â¦Â¾Ã Â¦â€“ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ [k]-Ã Â¦Â¤Ã Â¦Â® Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤
  static DateTime _sankranti(int gYear, int k) {
    final target = (k * 30.0) % 360.0;
    // Ã Â¦â€ Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€“Ã Â§ÂÃ Â¦ÂÃ Â¦Å“Ã Â¦Â¿
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
        // Ã Â¦Â¦Ã Â§ÂÃ Â¦â€¡ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â®Ã Â¦Â¾Ã Â¦ÂÃ Â§â€¡ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦â€“Ã Â¦Â£Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¸Ã Â§â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â® Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¿
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
    // Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€ Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â«Ã Â¦Â¿Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦â€¡ (Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â«Ã Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡Ã Â¦Â° path-Ã Â¦ÂÃ Â¦Â°
    // Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹Ã Â¦â€¡ IST-marked Ã Â¦Â«Ã Â¦Â°Ã Â¦Â®Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â§â€¡, Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ _monthStart-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â¤Ã Â§ÂÃ Â¦Â²Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡)
    return DateTime.utc(
      gYear,
      4,
      14,
    ).add(Duration(days: (k * 30.44).round(), hours: 5, minutes: 30));
  }

  /// Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â§Â§ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦ÂªÃ Â¦Â¶Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¬Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â®):
  /// Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã¢â€ â€™ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â§Â§ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“,
  /// Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã¢â€ â€™ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â§Â§ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â¥Â¤
  /// (Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â§Ã¢â‚¬â€œÃ Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦ÂªÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â²Ã Â¦Â¾ Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â¶Ã Â¦Â¾Ã Â¦â€“Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡)
  ///
  /// [monthIndex] (Ã Â§Â¦=Ã Â¦Â¬Ã Â§Ë†Ã Â¦Â¶Ã Â¦Â¾Ã Â¦â€“...Ã Â§Â§Ã Â§Â§=Ã Â¦Å¡Ã Â§Ë†Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°) Ã Â¦ÂÃ Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â¦Â¿Ã Â¦â€¢ Ã¢â‚¬â€ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°(Ã Â§Âª) Ã Â¦â€œ Ã Â¦â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨(Ã Â§Â«) Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡
  /// Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â² Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤-Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â®Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â²Ã Â§â€¡ prokerala.com-Ã Â¦ÂÃ Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°
  /// (Ã Â¦â€ Ã Â¦Â° Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¾Ã Â¦Â°) Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â§Â§ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡
  /// Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦â€”Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¦Ã Â§ÂÃ Â¦â€¡ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€ Ã Â¦Â°Ã Â¦â€œ Ã Â§Â§ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â
  /// Ã Â¦Â§Ã Â¦Â°Ã Â§â€¡ (Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦Â­Ã Â¦Â¬Ã Â¦Â¤ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â¤ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤-Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€ Ã Â¦Â§Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢
  /// Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â§Â Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨) Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ Ã Â§Â§Ã Â§Â¦Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡
  /// Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â¦â€¡ Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¹Ã Â§Â Ã Â¦Â®Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡Ã Â¥Â¤ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¦Ã Â§ÂÃ Â¦â€¡ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â§ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬
  /// Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â§Â§ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡Ã Â¥Â¤
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
    'Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â®Ã Â§â€šÃ Â¦Â¹',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹',
    'Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¨',
    'Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶',
    'Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬',
    'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾',
    'Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
  ];

  static String _tabCategory(String tab) {
    switch (tab) {
      case 'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹':
        return 'marriage';
      case 'Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¨':
        return 'annaprashan';
      case 'Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶':
        return 'griha';
      case 'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â®Ã Â§â€šÃ Â¦Â¹':
        return 'general';
      case 'Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬':
        return 'ekadashi';
      case 'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾':
        return 'purnima';
      case 'Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾':
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
  const CalendarEvent(this.label, this.category, {this.icon = 'Ã¢Å“Â¦'});
}

/// Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â®Ã Â¥Â¤
/// [ref] = Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â§Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡:
///   'sunrise'  Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â®, Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€” Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬)
///   'nishita'  Ã¢â‚¬â€ Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤ (Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿, Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â§â‚¬Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾)
///   'pradosh'  Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ (Ã Â¦Â§Ã Â¦Â¨Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾)
class _FestivalRule {
  final String month;
  final String paksha;
  final int
  within; // Ã Â§Â¦..Ã Â§Â§Ã Â§Âª (Ã Â§Â§Ã Â§Âª = Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾/Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾)
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
  /// Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¡Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¯Ã Â§â€¡Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬
  /// Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾ (Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£, Ã Â¦â€¡Ã Â¦Â¸Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¿ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨)Ã Â¥Â¤ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨
  /// [_festivalRules] Ã Â¦â€œ [_fixedGregorian] Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¯Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¸Ã Â§â€¡Ã Â¥Â¤
  static const Map<String, List<CalendarEvent>> events = {
    '2026-08-12': [
      CalendarEvent(
        'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
        'general',
        icon: 'Ã°Å¸Å’â€˜',
      ),
    ],
    '2026-08-13': [
      CalendarEvent(
        'Ã Â¦â€ Ã Â¦â€“Ã Â§â€¡Ã Â¦Â°Ã Â§â‚¬ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¶Ã Â§â€¹Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾',
        'general',
        icon: 'Ã°Å¸â€¢Å’',
      ),
    ],
    '2026-08-28': [
      CalendarEvent(
        'Ã Â¦â€ Ã Â¦â€šÃ Â¦Â¶Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£',
        'general',
        icon: 'Ã°Å¸Å’Ëœ',
      ),
    ],
  };

  /// Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿-Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â®: Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â§â€¡Ã Â¥Â¤
  /// Ã Â¦ÂÃ Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¯Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¡ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¸Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤
  /// Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ (Ã Â§Â§Ã Â§Â¬Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡
  /// Ã Â§Â§Ã Â§Â©Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¹Ã Â§Â Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡; Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¶Ã Â¦Â®Ã Â§â‚¬, Ã Â¦â€¢Ã Â§â€¹Ã Â¦Å“Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â°Ã Â§â‚¬ Ã Â¦â€œ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¨Ã Â¦Â¬Ã Â¦Â®Ã Â§â‚¬ Ã Â¦ÂÃ Â¦â€¢ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡
  /// Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â® Ã Â¦â€ Ã Â¦Â°Ã Â¦â€œ Ã Â¦Å“Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â²)Ã Â¥Â¤
  ///
  /// Ã Â¦Â²Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â£Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼: Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§â€¡Ã Â¦Â° Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€¡
  /// Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â§Å’Ã Â¦Â°Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦â€”Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾ "Ã Â¦â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â°" Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ Ã Â¦Â¸Ã Â§Å’Ã Â¦Â°
  /// Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â§â€¡Ã Â¥Â¤ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡ Ã Â¦Â¸Ã Â§Å’Ã Â¦Â°Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â¦â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡Ã Â¥Â¤
  static const List<_FestivalRule> _festivalRules = [
    // within: Ã Â§Â¦ = Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¦ Ã¢â‚¬Â¦ Ã Â§Â§Ã Â§Â© = Ã Â¦Å¡Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬, Ã Â§Â§Ã Â§Âª = Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾ (Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²) / Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ (Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£)
    _FestivalRule(
      'Ã Â¦â€ Ã Â¦Â·Ã Â¦Â¾Ã Â¦Â¢Ã Â¦Â¼',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²',
      1,
      'Ã Â¦Â°Ã Â¦Â¥Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾',
      'general',
      'Ã°Å¸â€ºâ€¢',
    ),
    _FestivalRule(
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â£',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²',
      9,
      'Ã Â¦â€°Ã Â¦Â²Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦Â°Ã Â¦Â¥',
      'general',
      'Ã°Å¸â€ºâ€¢',
    ),
    _FestivalRule(
      'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²',
      14,
      'Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â¿ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾',
      'general',
      'Ã°Å¸Å½â€”Ã¯Â¸Â',
    ),
    _FestivalRule(
      'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°',
      'Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£',
      7,
      'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â®Ã Â§â‚¬',
      'general',
      'Ã°Å¸Â¦Å¡',
    ),
    _FestivalRule(
      'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²',
      3,
      'Ã Â¦â€”Ã Â¦Â£Ã Â§â€¡Ã Â¦Â¶ Ã Â¦Å¡Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¥Ã Â§â‚¬',
      'general',
      'Ã°Å¸ÂËœ',
    ),
    _FestivalRule(
      'Ã Â¦â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨',
      'Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£',
      14,
      'Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾',
      'general',
      'Ã°Å¸Âªâ€',
    ),
    _FestivalRule(
      'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²',
      5,
      'Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â§â‚¬',
      'general',
      'Ã°Å¸â€Â±',
    ),
    _FestivalRule(
      'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²',
      6,
      'Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¸Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¤Ã Â¦Â®Ã Â§â‚¬',
      'general',
      'Ã°Å¸â€Â±',
    ),
    _FestivalRule(
      'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²',
      7,
      'Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â®Ã Â§â‚¬',
      'general',
      'Ã°Å¸â€Â±',
    ),
    _FestivalRule(
      'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²',
      8,
      'Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¬Ã Â¦Â®Ã Â§â‚¬',
      'general',
      'Ã°Å¸â€Â±',
    ),
    _FestivalRule(
      'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²',
      9,
      'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¶Ã Â¦Â®Ã Â§â‚¬',
      'general',
      'Ã°Å¸â€Â±',
    ),
    _FestivalRule(
      'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²',
      14,
      'Ã Â¦â€¢Ã Â§â€¹Ã Â¦Å“Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â°Ã Â§â‚¬ Ã Â¦Â²Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â®Ã Â§â‚¬Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾',
      'general',
      'Ã°Å¸ÂªÂ·',
    ),
    _FestivalRule(
      'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢',
      'Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£',
      12,
      'Ã Â¦Â§Ã Â¦Â¨Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸',
      'general',
      'Ã°Å¸Âªâ„¢',
      ref: 'pradosh',
    ),
    _FestivalRule(
      'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢',
      'Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£',
      14,
      'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â§â‚¬Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾ / Ã Â¦Â¦Ã Â§â‚¬Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â¿',
      'general',
      'Ã°Å¸Âªâ€',
      ref: 'nishita',
    ),
    _FestivalRule(
      'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²',
      1,
      'Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â«Ã Â§â€¹Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾',
      'general',
      'Ã°Å¸Å½â€”Ã¯Â¸Â',
    ),
    _FestivalRule(
      'Ã Â¦Â®Ã Â¦Â¾Ã Â¦Ëœ',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²',
      4,
      'Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¤Ã Â§â‚¬ Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾',
      'general',
      'Ã°Å¸Å’Â¼',
    ),
    _FestivalRule(
      'Ã Â¦Â«Ã Â¦Â¾Ã Â¦Â²Ã Â§ÂÃ Â¦â€”Ã Â§ÂÃ Â¦Â¨',
      'Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£',
      13,
      'Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿',
      'general',
      'Ã°Å¸â€¢â€°',
      ref: 'nishita',
    ),
    _FestivalRule(
      'Ã Â¦Â«Ã Â¦Â¾Ã Â¦Â²Ã Â§ÂÃ Â¦â€”Ã Â§ÂÃ Â¦Â¨',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²',
      14,
      'Ã Â¦Â¦Ã Â§â€¹Ã Â¦Â²Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾',
      'general',
      'Ã°Å¸Å’â€¢',
    ),
    _FestivalRule(
      'Ã Â¦Å¡Ã Â§Ë†Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°',
      'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²',
      8,
      'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¨Ã Â¦Â¬Ã Â¦Â®Ã Â§â‚¬',
      'general',
      'Ã°Å¸â€ºâ€¢',
    ),
  ];

  /// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°Ã Â¦â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦â€¡Ã Â¦â€šÃ Â¦Â°Ã Â§â€¡Ã Â¦Å“Ã Â¦Â¿ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â§â€¡ Ã Â¦ÂÃ Â¦Â®Ã Â¦Â¨ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ (Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸-Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬)
  static const Map<String, List<CalendarEvent>> _fixedGregorian = {
    '01-01': [
      CalendarEvent(
        'Ã Â¦â€¡Ã Â¦â€šÃ Â¦Â°Ã Â§â€¡Ã Â¦Å“Ã Â¦Â¿ Ã Â¦Â¨Ã Â¦Â¬Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â·',
        'general',
        icon: 'Ã°Å¸Å½â€°',
      ),
    ],
    '01-12': [
      CalendarEvent(
        'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦ Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
        'general',
        icon: 'Ã°Å¸Â§â€˜',
      ),
    ],
    '01-23': [
      CalendarEvent(
        'Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Å“Ã Â¦Â¿ Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Å“Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â‚¬',
        'general',
        icon: 'Ã°Å¸Â§â€˜',
      ),
    ],
    '01-26': [
      CalendarEvent(
        'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¸',
        'general',
        icon: 'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
      ),
    ],
    '05-01': [
      CalendarEvent(
        'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â®Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¸',
        'general',
        icon: 'Ã°Å¸â€ºÂ Ã¯Â¸Â',
      ),
    ],
    '08-15': [
      CalendarEvent(
        'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â¨Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¸',
        'general',
        icon: 'Ã°Å¸â€¡Â®Ã°Å¸â€¡Â³',
      ),
    ],
    '10-02': [
      CalendarEvent(
        'Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§â‚¬ Ã Â¦Å“Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â‚¬',
        'general',
        icon: 'Ã°Å¸Â§â€˜',
      ),
    ],
    '12-25': [
      CalendarEvent(
        'Ã Â¦Â¬Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
        'general',
        icon: 'Ã°Å¸Å½â€ž',
      ),
    ],
  };

  /// Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹/Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¨/Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â²Ã Â§â‚¬Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â®Ã Â§â€¡:
  /// Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦ÂÃ Â¦Â¬Ã Â¦â€š Ã Â¦Â®Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â²Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦Ã Â§â€¡Ã Â¥Â¤
  /// (Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â²Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨-Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â²Ã Â§ÂÃ Â¦Âª Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦â€¡Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â¿Ã Â¦Â¤Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°)
  static const Set<int> _auspiciousTithis = {0, 1, 2, 4, 6, 9, 10, 11, 12};
  static const Set<String> _auspiciousNakshatras = {
    'Ã Â¦Â°Ã Â§â€¹Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â£Ã Â§â‚¬',
    'Ã Â¦Â®Ã Â§Æ’Ã Â¦â€”Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¾',
    'Ã Â¦Â®Ã Â¦ËœÃ Â¦Â¾',
    'Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Â«Ã Â¦Â¾Ã Â¦Â²Ã Â§ÂÃ Â¦â€”Ã Â§ÂÃ Â¦Â¨Ã Â§â‚¬',
    'Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾',
    'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â¤Ã Â§â‚¬',
    'Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾',
    'Ã Â¦Â®Ã Â§â€šÃ Â¦Â²Ã Â¦Â¾',
    'Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â¾Ã Â¦Â¢Ã Â¦Â¼Ã Â¦Â¾',
    'Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦ÂªÃ Â¦Â¦',
    'Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¬Ã Â¦Â¤Ã Â§â‚¬',
  };

  static CalendarEvent? _auspiciousFor(
    DateTime date,
    TithiInfo tithi,
    String nakshatra,
  ) {
    if (tithi.paksha != 'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²') return null;
    if (!_auspiciousTithis.contains(tithi.index % 15)) return null;
    if (!_auspiciousNakshatras.contains(nakshatra)) return null;
    if (date.weekday == DateTime.tuesday) return null;
    // Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â®Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€ Ã Â¦Å¸Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹/Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶/
    // Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¨/Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â/Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£/Ã Â¦Å“Ã Â¦Â®Ã Â¦Â¿ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾/Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾/Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾) Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡
    // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦Â®Ã Â¦Â¤ Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€“Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
    // ("Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤" Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡ Ã Â¦Å“Ã Â¦Â®Ã Â¦Â¿/Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿/Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â§Â©Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€” Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦Â¹Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
    // Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â° mod-5 Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ mod-8 Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¹ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â²Ã Â§â‚¬Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦â€¡Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â¿Ã Â¦Â¤Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°,
    // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â²Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨-Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â²Ã Â§ÂÃ Â¦Âª Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼)
    switch (date.day % 8) {
      case 0:
        return const CalendarEvent(
          'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
          'marriage',
          icon: 'Ã°Å¸â€™Â',
        );
      case 1:
        return const CalendarEvent(
          'Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
          'griha',
          icon: 'Ã°Å¸ÂÂ ',
        );
      case 2:
        return const CalendarEvent(
          'Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
          'annaprashan',
          icon: 'Ã°Å¸â€˜Â¶',
        );
      case 3:
        return const CalendarEvent(
          'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
          'byabosha',
          icon: 'Ã°Å¸Âªâ€',
        );
      case 4:
        return const CalendarEvent(
          'Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
          'namakaran',
          icon: 'Ã°Å¸â€œÂ¿',
        );
      case 5:
        return const CalendarEvent(
          'Ã Â¦Å“Ã Â¦Â®Ã Â¦Â¿ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
          'jomi',
          icon: 'Ã°Å¸ÂÅ¾Ã¯Â¸Â',
        );
      case 6:
        return const CalendarEvent(
          'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
          'bari',
          icon: 'Ã°Å¸ÂÂ¡',
        );
      default:
        return const CalendarEvent(
          'Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
          'gari',
          icon: 'Ã°Å¸Å¡â€”',
        );
    }
  }

  /// "Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤" Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°/
  /// Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°, Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¿Ã Â§Å½ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ (Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼-Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¾Ã Â¦Â®Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¿ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã‚Â±Ã Â§Â¨Ã Â§Âª
  /// Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¸ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â§â‚¬ Ã Â¦Â¸Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Å“Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â¨ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¬Ã Â§ÂÃ Â¦Â§Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¦Ã Â§â€¡) Ã Â¦â€ Ã Â¦Â° Ã¢Å¡Â Ã¯Â¸Â Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â²
  /// (Ã Â¦ÂÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼) Ã Â¦Â¸Ã Â¦Â¹ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â«Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¤ Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤ lat/lon Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬Ã Â¦Â°
  /// Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾/GPS (AppLocation) Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
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

  /// Ã Â¦â€ Ã Â¦Å“ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬ [maxDays] Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“Ã Â§â€¡Ã Â¦Â° (marriage/griha/
  /// annaprashan/byabosha/namakaran) Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â‚¬ [count]-Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€“Ã Â§ÂÃ Â¦ÂÃ Â¦Å“Ã Â§â€¡
  /// Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã¢â‚¬â€ real Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡, Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¨Ã Â¦Â¾
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

  /// Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° (Ã Â¦â€ Ã Â¦Å“Ã Â¦Â¸Ã Â¦Â¹) real Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬/Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â® Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° "Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦â€œ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·
  /// Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨" carousel-Ã Â¦ÂÃ Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¥Â¤ category 'general'-Ã Â¦ÂÃ Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â²
  /// Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“-Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â®Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°-Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡-Ã Â¦Â¯Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€¢Ã Â¦â€“Ã Â¦Â¨Ã Â§â€¹
  /// Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â° Ã Â¦Â¯Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â®Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¸Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â®Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡Ã Â¥Â¤
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
          // Ã Â¦â€¢Ã Â¦Â¤Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ (existing Ã Â¦â€¢Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â°/UI-Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦ÂÃ Â¦â€¡
          // Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ key Ã Â¦â€¡Ã Â¦â€”Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¬Ã Â§â€¡, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€œ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§Â Ã Â¦Â­Ã Â¦Â¾Ã Â¦â„¢Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾)
          'daysLeft': i.toString(),
        });
        if (results.length >= count) break;
      }
    }
    return results;
  }

  /// Ã Â¦Â¯Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦â€¡Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸ Ã¢â‚¬â€ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡:
  /// Ã Â§Â§) Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ (Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£ Ã Â¦â€¡Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¿, Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°-Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸)
  /// Ã Â§Â¨) Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿ Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸ Ã Â¦â€¡Ã Â¦â€šÃ Â¦Â°Ã Â§â€¡Ã Â¦Å“Ã Â¦Â¿ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ (Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â¨Ã Â¦Â¤Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¸ Ã Â¦â€¡Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¿)
  /// Ã Â§Â©) Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿+Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ (Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦â€”Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾, Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â§â‚¬Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾Ã¢â‚¬Â¦)
  /// Ã Â§Âª) Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬/Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾/Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨
  /// Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿Ã Â¦â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â§Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â®)Ã Â¥Â¤
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

    // Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§Â Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€œÃ Â¦â€¡ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â§Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
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

    if (within == 10 && !hasLabel('Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬')) {
      out.add(
        const CalendarEvent(
          'Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬',
          'ekadashi',
          icon: 'Ã°Å¸Å’â„¢',
        ),
      );
    } else if (within == 14) {
      // Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾/Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¤Ã Â¦Â¬Ã Â§â€¡ Ã Â¦â€œÃ Â¦â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®-Ã Â¦Â§Ã Â¦Â°Ã Â¦Â¾ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ (Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾)
      // Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â° Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾
      final isPurnima = tithi.paksha == 'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â²';
      final cat = isPurnima ? 'purnima' : 'amabasya';
      if (!out.any((e) => e.category == cat)) {
        out.add(
          isPurnima
              ? const CalendarEvent(
                  'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾',
                  'purnima',
                  icon: 'Ã°Å¸Å’â€¢',
                )
              : const CalendarEvent(
                  'Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
                  'amabasya',
                  icon: 'Ã°Å¸Å’â€˜',
                ),
        );
      }
    }

    final auspicious = _auspiciousFor(day, tithi, nakshatra);
    if (auspicious != null &&
        !out.any((e) => e.category == auspicious.category)) {
      out.add(auspicious);
    }

    // Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¡Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂÃ Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¡ Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
    final seen = <String>{};
    return out.where((e) => seen.add(e.label)).toList();
  }
}

// =====================================================================
// PanjikaArt Ã¢â‚¬â€ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬, Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â®Ã Â§Å’Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢ (original) Ã Â¦â€ºÃ Â§â€¹Ã Â¦Å¸ illustrationÃ Â¥Â¤
// Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¨Ã Â§â‚¬/Ã Â¦Â¬Ã Â¦â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ºÃ Â¦Â¬Ã Â¦Â¿ Ã Â¦â€¢Ã Â¦ÂªÃ Â¦Â¿ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦â€¡ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Flutter CustomPainter
// Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¡Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€ºÃ Â¦Â¬Ã Â¦Â¿ Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â² Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦ÂÃ Â¦Â¬Ã Â¦â€š Ã Â¦Â¯Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Å“Ã Â§â€¡
// Ã Â¦ÂÃ Â¦â€¢Ã Â¦ÂÃ Â¦â€¢Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ (vector)Ã Â¥Â¤ Ã Â¦ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â§â‚¬ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¹ Ã Â¦Â°Ã Â§â€¡Ã Â¦â€“Ã Â§â€¡ motif Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹
// Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â²/Ã Â¦â€ Ã Â¦â€¡Ã Â¦â€¢Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ºÃ Â§â€¹Ã Â¦Å¸ Ã Â¦ËœÃ Â¦Â°Ã Â§â€¡Ã Â¦â€œ Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
// Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦â€¡ Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Panchang/Calendar Ã Â¦Â¡Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡
// Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â¦Â°Ã Â§ÂÃ Â¦â€¢ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡Ã Â¥Â¤
// =====================================================================

class PanjikaArt extends StatelessWidget {
  final String motif;
  final double size;
  const PanjikaArt(this.motif, {super.key, this.size = 24});

  /// Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬/Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â® Ã Â¦â€œ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â¯Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¤ motif Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
  /// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â®Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿-Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â°Ã Â¦Â¿ (Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾/Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾/Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬/Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿), Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦ÂªÃ Â¦Â°
  /// Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡Ã Â¦Â° Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¶Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¦ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¥Â¤ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§ÂÃ Â¦â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â²Ã Â§â€¡ null (Ã Â¦Â¤Ã Â¦â€“Ã Â¦Â¨ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¡Ã Â¦Â®Ã Â§â€¹Ã Â¦Å“Ã Â¦Â¿/
  /// Ã Â¦Â¡Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²Ã Â§ÂÃ Â¦Å¸ Ã Â¦â€¦Ã Â¦Â²Ã Â¦â„¢Ã Â§ÂÃ Â¦â€¢Ã Â¦Â°Ã Â¦Â£ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡)Ã Â¥Â¤
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
      'Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦â€”Ã Â¦Â¾',
      'Ã Â¦Â·Ã Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â§â‚¬',
      'Ã Â¦Â¸Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¤Ã Â¦Â®Ã Â§â‚¬',
      'Ã Â¦â€¦Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â®Ã Â§â‚¬',
      'Ã Â¦Â¨Ã Â¦Â¬Ã Â¦Â®Ã Â§â‚¬',
      'Ã Â¦Â¦Ã Â¦Â¶Ã Â¦Â®Ã Â§â‚¬',
      'Ã Â¦Â®Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾',
    ])) {
      return 'trishul';
    }
    if (has([
      'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â§â‚¬',
      'Ã Â¦Â¦Ã Â§â‚¬Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â¿',
      'Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿',
      'Ã Â¦Â¦Ã Â§â‚¬Ã Â¦Âª',
    ]))
      return 'diya';
    if (has([
      'Ã Â¦Â²Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â®Ã Â§â‚¬',
      'Ã Â¦â€¢Ã Â§â€¹Ã Â¦Å“Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â°Ã Â§â‚¬',
    ]))
      return 'lotus';
    if (has(['Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¤Ã Â§â‚¬'])) return 'veena';
    if (has([
      'Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¬',
      'Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿',
    ]))
      return 'shiva';
    if (has([
      'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â®Ã Â§â‚¬',
      'Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£',
    ]))
      return 'peacock';
    if (has(['Ã Â¦â€”Ã Â¦Â£Ã Â§â€¡Ã Â¦Â¶'])) return 'lotus';
    if (has(['Ã Â¦Â°Ã Â¦Â¥'])) return 'temple';
    if (has([
      'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¨Ã Â¦Â¬Ã Â¦Â®Ã Â§â‚¬',
      'Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â°',
      'Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾',
    ]))
      return 'temple';
    if (has([
      'Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â¿',
      'Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â«Ã Â§â€¹Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾',
      'Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€¡',
    ]))
      return 'rakhi';
    if (has(['Ã Â¦Â§Ã Â¦Â¨Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸', 'Ã Â¦Â§Ã Â¦Â¨']))
      return 'coin';
    if (has([
      'Ã Â¦Â¦Ã Â§â€¹Ã Â¦Â²',
      'Ã Â¦Â¹Ã Â§â€¹Ã Â¦Â²Ã Â¦Â¿',
      'Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤',
    ]))
      return 'flower';
    if (has(['Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾']))
      return 'moonFull';
    if (has(['Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾']))
      return 'moonNew';
    if (has(['Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â¦Â£'])) return 'moonNew';
    if (has([
      'Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â§Ã Â§â‚¬Ã Â¦Â¨Ã Â¦Â¤Ã Â¦Â¾',
      'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â°',
      'Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¸',
    ]))
      return 'flag';
    if (has([
      'Ã Â¦Â¨Ã Â¦Â¬Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â·',
      'Ã Â¦Â¬Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
    ]))
      return 'star';
    // Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§Â Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â²Ã Â§â€¡Ã Â¦â€œ, Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸-Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â° (Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿) Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯
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

  // Ã Â¦ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â§â‚¬ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Å¸
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
        // Ã Â¦Â¨Ã Â¦Â°Ã Â¦Â® Ã Â¦â€ Ã Â¦Â²Ã Â§â€¹Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â¯Ã Â¦Â¼ + Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦ + Ã Â¦â€¢Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â²Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€”Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤
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
        // Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦, Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â Ã Â¦Â¦Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â°Ã Â§Â Ã Â¦Â°Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¾Ã Â¦Â²Ã Â¦Â¿ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡
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
        // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¦Ã Â§â‚¬Ã Â¦Âª Ã¢â‚¬â€ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¿, Ã Â¦Â¸Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®, Ã Â¦Â¶Ã Â¦Â¿Ã Â¦â€“Ã Â¦Â¾ Ã Â¦â€œ Ã Â¦Â¨Ã Â¦Â°Ã Â¦Â® Ã Â¦â€ Ã Â¦Â­Ã Â¦Â¾
        fill.color = _flame.withValues(alpha: 0.22);
        canvas.drawCircle(p(0.5, 0.30), s * 0.20, fill);
        // Ã Â¦Â¶Ã Â¦Â¿Ã Â¦â€“Ã Â¦Â¾
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
        // Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¿
        final bowl = Path()
          ..moveTo(s * 0.16, s * 0.60)
          ..cubicTo(s * 0.24, s * 0.86, s * 0.76, s * 0.86, s * 0.84, s * 0.60)
          ..close();
        fill.color = const Color(0xFFB5502A);
        canvas.drawPath(bowl, fill);
        // Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®
        stroke
          ..color = _gold
          ..strokeWidth = s * 0.05;
        canvas.drawLine(p(0.16, 0.60), p(0.84, 0.60), stroke);
        fill.color = _goldLt;
        canvas.drawCircle(p(0.5, 0.60), s * 0.05, fill);
        break;

      case 'lotus':
        {
          // Ã Â¦ÂªÃ Â¦Â¦Ã Â§ÂÃ Â¦Â® Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§â€¡Ã Â¦â€ºÃ Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â²Ã Â¦â€¢Ã Â¦Â¾, Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¢Ã Â¦Â¼ Ã Â¦Â¡Ã Â¦â€”Ã Â¦Â¾
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

          // Ã Â¦ÂªÃ Â§â€¡Ã Â¦â€ºÃ Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿
          petal(0.5, -0.9, 0.42, _pink.withValues(alpha: 0.8));
          petal(0.5, 0.9, 0.42, _pink.withValues(alpha: 0.8));
          petal(0.5, -0.45, 0.5, _pink);
          petal(0.5, 0.45, 0.5, _pink);
          // Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿
          petal(0.5, 0.0, 0.56, _pinkDp);
          petal(0.5, -0.22, 0.52, _pink);
          petal(0.5, 0.22, 0.52, _pink);
          fill.color = _goldLt;
          canvas.drawCircle(p(0.5, 0.62), s * 0.05, fill);
        }
        break;

      case 'sun':
        // Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦â€œ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â§â€¡ Ã Â¦Â°Ã Â¦Â¶Ã Â§ÂÃ Â¦Â®Ã Â¦Â¿ (Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿)
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
        // Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€šÃ Â¦Â² Ã¢â‚¬â€ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦â€”Ã Â¦Â¾/Ã Â¦Â¶Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â§â‚¬Ã Â¦â€¢
        stroke
          ..color = _gold
          ..strokeWidth = s * 0.055;
        canvas.drawLine(p(0.5, 0.30), p(0.5, 0.9), stroke);
        // Ã Â¦Â®Ã Â¦Â¾Ã Â¦ÂÃ Â§â€¡Ã Â¦Â° Ã Â¦Â«Ã Â¦Â²Ã Â¦Â¾
        final mid = Path()
          ..moveTo(s * 0.5, s * 0.08)
          ..lineTo(s * 0.44, s * 0.30)
          ..lineTo(s * 0.56, s * 0.30)
          ..close();
        fill.color = _gold;
        canvas.drawPath(mid, fill);
        // Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¦Ã Â§ÂÃ Â¦â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â«Ã Â¦Â²Ã Â¦Â¾
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
        // Ã Â¦Â¬Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â§Ã Â¦Â¨
        fill.color = _red;
        canvas.drawCircle(p(0.5, 0.34), s * 0.045, fill);
        break;

      case 'temple':
        // Ã Â¦Â®Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â¿Ã Â¦Â° Ã¢â‚¬â€ Ã Â¦Å¡Ã Â§â€šÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾ (Ã Â¦Â¶Ã Â¦Â¿Ã Â¦â€“Ã Â¦Â°), Ã Â¦â€¢Ã Â¦Â²Ã Â¦Â¸ Ã Â¦â€œ Ã Â¦ÂªÃ Â¦Â¤Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾
        fill.color = _saffronLt;
        // Ã Â¦Â®Ã Â§â€šÃ Â¦Â² Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¹
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.28, s * 0.55, s * 0.44, s * 0.35),
            Radius.circular(s * 0.02),
          ),
          fill,
        );
        // Ã Â¦Â¶Ã Â¦Â¿Ã Â¦â€“Ã Â¦Â° (Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â­Ã Â§ÂÃ Â¦Å“Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°)
        final spire = Path()
          ..moveTo(s * 0.5, s * 0.14)
          ..lineTo(s * 0.30, s * 0.55)
          ..lineTo(s * 0.70, s * 0.55)
          ..close();
        fill.color = _saffron;
        canvas.drawPath(spire, fill);
        // Ã Â¦Â¦Ã Â¦Â°Ã Â¦Å“Ã Â¦Â¾
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
        // Ã Â¦â€¢Ã Â¦Â²Ã Â¦Â¸ + Ã Â¦ÂªÃ Â¦Â¤Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾
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
        // Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¤Ã Â§â‚¬Ã Â¦Â° Ã Â¦Â¬Ã Â§â‚¬Ã Â¦Â£Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â²Ã Â§â‚¬Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤: Ã Â¦Â²Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â£Ã Â§ÂÃ Â¦Â¡, Ã Â¦â€”Ã Â§â€¹Ã Â¦Â² Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â°Ã Â¦Â£Ã Â¦â€¢ Ã Â¦â€œ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°
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
        // Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¬ Ã¢â‚¬â€ Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€šÃ Â¦Â²Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦â€¦Ã Â¦Â°Ã Â§ÂÃ Â¦Â§Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°
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
        // Ã Â¦â€¦Ã Â¦Â°Ã Â§ÂÃ Â¦Â§Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°
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
        // Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€šÃ Â¦Â°Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â²Ã Â¦â€¢ Ã¢â‚¬â€ Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â®Ã Â§â‚¬/Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Â£
        stroke
          ..color = _peaGreen
          ..strokeWidth = s * 0.03;
        canvas.drawLine(p(0.5, 0.9), p(0.5, 0.34), stroke);
        // Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â²Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¹Ã Â¦â€“
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
        // Ã Â¦â€”Ã Â¦Â¾Ã Â¦ÂÃ Â¦Â¦Ã Â¦Â¾/Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£ Ã Â¦Â«Ã Â§ÂÃ Â¦Â² Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤/Ã Â¦Â¦Ã Â§â€¹Ã Â¦Â²
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
        // Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦Â®Ã Â¦Â¾Ã Â¦ÂÃ Â§â€¡ Ã Â¦Â°Ã Â§â€¹Ã Â¦Å“Ã Â§â€¡Ã Â¦Å¸, Ã Â¦Â¦Ã Â§ÂÃ Â¦â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â§â€¡ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¹
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
        // Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â®Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â§Ã Â¦Â¨Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸
        fill.color = _gold;
        canvas.drawCircle(p(0.5, 0.5), s * 0.34, fill);
        stroke
          ..color = _goldLt
          ..strokeWidth = s * 0.04;
        canvas.drawCircle(p(0.5, 0.5), s * 0.27, stroke);
        // Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾
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
        // Ã Â¦Â¤Ã Â§â€¡Ã Â¦Â°Ã Â¦â„¢Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â¤Ã Â§â‚¬Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¸
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
        // Ã Â¦Â¤Ã Â§ÂÃ Â¦Â²Ã Â¦Â¸Ã Â§â‚¬ Ã Â¦Â®Ã Â¦Å¾Ã Â§ÂÃ Â¦Å¡ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬/Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¤
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
        // Ã Â¦â€”Ã Â¦Â¾Ã Â¦â€º
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
        // Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£ Ã Â¦â€¦Ã Â¦Â²Ã Â¦â„¢Ã Â§ÂÃ Â¦â€¢Ã Â¦Â°Ã Â¦Â£ Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Å¸-Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â£Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾
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
// Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â§â€¡Ã Â¦Å“
// =====================================================================

class BengaliCalendarScreen extends StatefulWidget {
  const BengaliCalendarScreen({super.key});
  @override
  State<BengaliCalendarScreen> createState() => _BengaliCalendarScreenState();
}

class _BengaliCalendarScreenState extends State<BengaliCalendarScreen> {
  DateTime _anchor = DateTime.now();
  String _tab =
      'Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸';
  String? _selectedKey;

  static const _tabs = [
    'Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â®Ã Â§â€šÃ Â¦Â¹',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹',
    'Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¨',
    'Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶',
    'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â',
    'Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£',
  ];
  static const _weekDays = [
    'Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿',
    'Ã Â¦Â¸Ã Â§â€¹Ã Â¦Â®',
    'Ã Â¦Â®Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â²',
    'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â§',
    'Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â¹Ã Â¦Æ’',
    'Ã Â¦Â¶Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°',
    'Ã Â¦Â¶Ã Â¦Â¨Ã Â¦Â¿',
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
  // Ã Â¦Â°Ã Â§â€¡Ã Â¦Â«Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¸ Ã Â¦â€ºÃ Â¦Â¾Ã Â¦ÂªÃ Â¦Â¾ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â­Ã Â¦Â¿Ã Â¦â€”Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦â€¡Ã Â¦â€šÃ Â¦Â°Ã Â§â€¡Ã Â¦Å“Ã Â¦Â¿ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®
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
  static const _bnDigits = [
    'Ã Â§Â¦',
    'Ã Â§Â§',
    'Ã Â§Â¨',
    'Ã Â§Â©',
    'Ã Â§Âª',
    'Ã Â§Â«',
    'Ã Â§Â¬',
    'Ã Â§Â­',
    'Ã Â§Â®',
    'Ã Â§Â¯',
  ];

  String _bn(int n) =>
      n.toString().split('').map((c) => _bnDigits[int.parse(c)]).join();
  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';

  String _tabCategory(String tab) {
    switch (tab) {
      case 'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹':
        return 'marriage';
      case 'Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¨':
        return 'annaprashan';
      case 'Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶':
        return 'griha';
      case 'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â':
        return 'byabosha';
      case 'Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£':
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
      _tab =
          'Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸';
      _selectedKey = null;
    });
  }

  // ---- Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â¤ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â°Ã Â¦â€š-Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€š Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦ËœÃ Â¦Â°Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢ Ã Â¦Â¨Ã Â¦Å“Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¬Ã Â§â€¹Ã Â¦ÂÃ Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ ----
  static const Color _purnimaColor = Color(
    0xFFFFD36E,
  ); // Ã Â¦Â¸Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾
  static const Color _amabasyaColor = Color(
    0xFFA285E8,
  ); // Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¢Ã Â¦Â¼ Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾
  static const Color _ekadashiColor = Color(
    0xFFFF9A3E,
  ); // Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â«Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬
  static const Color _sankrantiColor = Color(
    0xFF2FBFA3,
  ); // Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â² Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿ (Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â)
  static const Color _festivalColor = Color(
    0xFFE0384A,
  ); // Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â² Ã¢â‚¬â€ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬/Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨/Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°

  bool _hasCategory(List<CalendarEvent> events, String cat) =>
      events.any((e) => e.category == cat);

  /// Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦ËœÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨ (Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â¬Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£) Ã Â¦Â°Ã Â¦â€š Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â§â€¹Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡
  /// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€”Ã Â¦Â¤ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¦Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬: Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾ > Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ > Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬ >
  /// Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿ > Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬/Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ > Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°
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

  /// Ã Â¦Â°Ã Â§â€¡Ã Â¦Â«Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¸ Ã Â¦â€ºÃ Â¦Â¾Ã Â¦ÂªÃ Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹Ã Â¦â€¡ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â°Ã Â§Â Ã Â¦Â¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°, Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â§â€¡
  /// Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿ Ã Â¦Â¬Ã Â¦Â¸Ã Â§â€¡Ã Â¥Â¤ Ã Â¦Â¶Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¦/Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â¸Ã Â¦Â¨/Ã Â¦â€¦Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨, Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼-Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤, Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼-Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€œ
  /// Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â²/Ã Â¦Â¯Ã Â¦Â®Ã Â¦â€”Ã Â¦Â£Ã Â§ÂÃ Â¦Â¡/Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦â€¡ real Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ (Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ astronomy model
  /// Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ sunTimes/rahuKalam-Ã Â¦ÂÃ Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¨Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°)Ã Â¥Â¤
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

    // Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯-Ã Â¦Å“Ã Â§â€¹Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾ (Ã Â¦â€ Ã Â¦â€¡Ã Â¦â€¢Ã Â¦Â¨ + Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â² + Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨) Ã¢â‚¬â€ Ã Â¦Â®Ã Â¦â€¢Ã Â¦â€ Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â§Â¨-Ã Â¦â€¢Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¸Ã Â§â€¡
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
          // ---- Ã Â¦Â¶Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¦ / Ã Â¦Â¬Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â¾Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¦ / Ã Â¦â€¦Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¢ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ ----
          Wrap(
            spacing: 14,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Ã Â¦Â¶Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¦ ${bnNum(shaka)}',
                style: const TextStyle(
                  color: Color(0xFFB4272E),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                'Ã Â¦Â¬Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”Ã Â¦Â¾Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¦ ${bnNum(info.year)}',
                style: const TextStyle(
                  color: Color(0xFF17225C),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                'Ã¢ËœÂ¯ $ayana',
                style: const TextStyle(color: Color(0xFF6B7290), fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFEEF0F5)),
          // ---- Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â§Â¨ Ã Â¦â€¢Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡ ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    kv(
                      'Ã¢Ëœâ‚¬Ã¯Â¸Â',
                      'Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼',
                      bnTime12(sun.sunrise),
                    ),
                    kv(
                      'Ã°Å¸Å’â„¢',
                      'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼',
                      bnTime12(moonrise),
                    ),
                    kv(
                      'Ã°Å¸ÂÂ',
                      'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â²',
                      '${bnTime12(rahu['start']!)} Ã¢â‚¬â€œ ${bnTime12(rahu['end']!)}',
                      warn: true,
                    ),
                    kv(
                      'Ã°Å¸ÂªÂ',
                      'Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²',
                      '${bnTime12(gulika['start']!)} Ã¢â‚¬â€œ ${bnTime12(gulika['end']!)}',
                      warn: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    kv(
                      'Ã°Å¸Å’â€¡',
                      'Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤',
                      bnTime12(sun.sunset),
                    ),
                    kv(
                      'Ã°Å¸Å’Ëœ',
                      'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤',
                      bnTime12(moonset),
                    ),
                    kv(
                      'Ã¢Å¡Â Ã¯Â¸Â',
                      'Ã Â¦Â¯Ã Â¦Â®Ã Â¦â€”Ã Â¦Â£Ã Â§ÂÃ Â¦Â¡',
                      '${bnTime12(yama['start']!)} Ã¢â‚¬â€œ ${bnTime12(yama['end']!)}',
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
              builder: (_) => const _FeatureSheet(
                title: 'Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾',
              ),
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
                'Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€” Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¤ Ã¢â‚¬Âº',
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

  /// Ã Â¦Â°Ã Â§â€¡Ã Â¦Â«Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¸ Ã Â¦â€ºÃ Â¦Â¾Ã Â¦ÂªÃ Â¦Â¾ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â° Ã Â§Â®Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â¶Ã Â¦Â¨-Ã Â¦â€ Ã Â¦â€¡Ã Â¦â€¢Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡
  /// Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â²Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹, Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨/Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼
  /// (Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨/Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡Ã Â¦Å“/Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦ÂÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¡ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¿)Ã Â¥Â¤
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

    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          item(
            'Ã°Å¸â€œâ€¦',
            'Ã Â¦â€ Ã Â¦Å“ + Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²',
            () => Navigator.pop(context),
          ),
          item(
            'Ã°Å¸â€Â¯',
            'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShubhoMuhurtaScreen()),
            ),
          ),
          item(
            'Ã°Å¸Å½â€°',
            'Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬',
            () => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => const _FeatureSheet(
                title:
                    'Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦â€œ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
              ),
            ),
          ),
          item(
            'Ã¢â„¢Ë†',
            'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RashiScreen()),
            ),
          ),
          item(
            'Ã°Å¸â€˜Â¨Ã¢â‚¬ÂÃ°Å¸â€˜Â©Ã¢â‚¬ÂÃ°Å¸â€˜Â§',
            'Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FamilyCalendarScreen()),
            ),
          ),
          item(
            'Ã°Å¸â€â€”',
            'Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°',
            () => Share.share(
              buildTodayPanchangSummary(),
              subject:
                  'Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€” Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾',
            ),
          ),
          item(
            'Ã¢â€ºâ€¦',
            'Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Å“Ã Â¦Â¾Ã Â¦Â°',
            () => _showWeatherQuick(context),
          ),
          item(
            'Ã¢Å¡â„¢Ã¯Â¸Â',
            'Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¸',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  void _showWeatherQuick(BuildContext context) {
    final temp = WeatherService.instance.tempC;
    final raining = WeatherService.instance.isRaining;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          temp == null
              ? 'Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿'
              : 'Ã°Å¸Å’Â¡Ã¯Â¸Â Ã Â¦Â¤Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾ ${temp.toStringAsFixed(1)}Ã‚Â°C'
                    '${raining ? ' Ã¢â‚¬Â¢ Ã°Å¸Å’Â§Ã¯Â¸Â Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡' : ' Ã¢â‚¬Â¢ Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦Â¬Ã Â§Æ’Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡'}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = BengaliDateUtil.monthInfoFor(_anchor);
    final totalDays = info.end.difference(info.start).inDays + 1;
    final leading =
        info.start.weekday %
        7; // Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿=0 Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢
    final trailing = (7 - ((leading + totalDays) % 7)) % 7;

    final prevInfo = BengaliDateUtil.monthInfoFor(
      info.start.subtract(const Duration(days: 1)),
    );
    final prevTotalDays = prevInfo.end.difference(prevInfo.start).inDays + 1;

    final filterCat = _tabCategory(_tab);

    // Ã Â¦Â°Ã Â§â€¡Ã Â¦Â«Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¸ Ã Â¦â€ºÃ Â¦Â¾Ã Â¦ÂªÃ Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â²Ã Â¦â€¢Ã Â¦Â¾/Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â® Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¡
    // (Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿ Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â° Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¢Ã Â¦Â¼ cosmic Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â®Ã Â§â€¡ Ã Â¦â€¦Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¤)Ã Â¥Â¤
    // Material Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â°Ã¢â‚¬ÂÃ Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° IconButton/InkWell "No Material
    // widget found" Ã Â¦ÂÃ Â¦Â°Ã Â¦Â° Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¤ (Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ CosmicBackground Ã Â¦ÂÃ Â¦â€¡ Material Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¤)Ã Â¥Â¤
    return Material(
      color: const Color(0xFFF2F3F9),
      child: SafeArea(
        child: Column(
          children: [
            // ---- Ã Â¦Â¹Ã Â§â€¡Ã Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã¢â‚¬â€ Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â­Ã Â¦Â¿ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°, Ã Â¦Â°Ã Â§â€¡Ã Â¦Â«Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¸ Ã Â¦â€ºÃ Â¦Â¾Ã Â¦ÂªÃ Â¦Â¾ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ ----
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
                      'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° ${info.start.year}',
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
                        'Ã°Å¸â€œâ€¦ Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
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
                  // ---- Ã Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° (Ã Â¦Â«Ã Â¦Â¿Ã Â¦Â²Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â°) ----
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
                  // ---- Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€” Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â² (Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡, Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦Å¡Ã Â¦â€œÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾) ----
                  // Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨ Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦â€¡ (portrait) Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨ rotate Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡
                  // Ã Â¦Â¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â°Ã Â§â€¡Ã Â¦â€“Ã Â§â€¡ Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦Å¡Ã Â¦â€œÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â²
                  // Ã Â¦â€ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡, Ã Â¦â€ Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦Å¡Ã Â¦â€œÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
                  _sidebarPanel(context, info),
                  const SizedBox(height: 12),
                  // ---- Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¡ (Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦Å¡Ã Â¦â€œÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾) ----
                  Column(
                    children: [
                      // ---- Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸ switcher Ã¢â‚¬â€ Ã Â¦Â°Ã Â§â€¡Ã Â¦Â«Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦Â¬Ã Â¦Â¡Ã Â¦Â¼ Ã Â¦â€¡Ã Â¦â€šÃ Â¦Â°Ã Â§â€¡Ã Â¦Å“Ã Â¦Â¿
                      // Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨, Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸/Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â² Ã Â¦â€ºÃ Â§â€¹Ã Â¦Å¸ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â²
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
                              tooltip:
                                  'Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸',
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
                                  // Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¡Ã Â¦Â¼, Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨
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
                                  // Ã Â¦â€¡Ã Â¦â€šÃ Â¦Â°Ã Â§â€¡Ã Â¦Å“Ã Â¦Â¿ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸/Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â² Ã¢â‚¬â€ Ã Â¦â€ºÃ Â§â€¹Ã Â¦Å¸, Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡
                                  Text(
                                    '${_engMonthFull[info.start.month - 1]}${info.start.month != info.end.month ? 'Ã¢â‚¬â€œ${_engMonthFull[info.end.month - 1]}' : ''} ${info.start.year}',
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
                              tooltip:
                                  'Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸',
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
                                      // Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° (Ã Â¦Â¸Ã Â§â€šÃ Â¦Å¡Ã Â¦Â¿ Ã Â§Â¦) Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â²
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
                              mainAxisExtent: 68,
                            ),
                        itemBuilder: (context, i) {
                          // --- Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ ---
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
                          // --- Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ ---
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
                          // --- Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ ---
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
                          final dim =
                              _tab !=
                                  'Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸' &&
                              !matchesFilter;

                          // Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â® Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°
                          // Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ËœÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ (Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â°
                          // Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿, Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â®)Ã Â¥Â¤ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨
                          // tithiFor Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â¦â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¨Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã¢â‚¬â€ Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦â€ºÃ Â§Â Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
                          final cellSunrise = PanchangCalculator.sunTimes(
                            greg,
                            lat: AppLocation.lat,
                            lon: AppLocation.lon,
                          ).sunrise;
                          final cellTithi = PanchangCalculator.tithiFor(
                            cellSunrise,
                          ).name;

                          // Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬/Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â
                          // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â®Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â§â€¡, Ã Â¦ËœÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬ Ã Â¦â€ Ã Â¦â€¡Ã Â¦â€¢Ã Â¦Â¨+Ã Â¦Â°Ã Â¦â€š
                          // Ã Â¦â€¢Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¢ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡ Ã Â¦ÂªÃ Â¦Â° Ã Â¦ÂªÃ Â¦Â° Ã Â¦Â¨Ã Â¦Â°Ã Â¦Â® fade-Ã Â¦Â Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â²Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡
                          // Ã Â¦Â¸Ã Â¦Â¬Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ (_CalendarDayCell)
                          return _CalendarDayCell(
                            greg: greg,
                            bengaliDay: bengaliDay,
                            bnDay: _bn(bengaliDay),
                            tithiName: cellTithi,
                            // Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡ Ã Â¦â€ºÃ Â§â€¹Ã Â¦Å¸ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¶Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾
                            // Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â® Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦Â¹Ã Â¦Â²Ã Â§â€¹ Ã Â¦Â¬Ã Â§â€¹Ã Â¦ÂÃ Â¦Â¾Ã Â¦Â¤Ã Â§â€¡
                            secondaryDateText: isSankranti ? info.name : '',
                            events: events,
                            isToday: isToday,
                            isSelected: isSelected,
                            isSankranti: isSankranti,
                            isSunday: isSunday,
                            dim: dim,
                            highlightTint:
                                matchesFilter &&
                                _tab !=
                                    'Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸',
                            primaryCategoryColor: _primaryCategoryColor,
                            onTap: () => setState(() => _selectedKey = key),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ---- Ã Â¦Â°Ã Â¦â€š-Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¡Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¤ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¦Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ ----
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _legendDot(
                        _purnimaColor,
                        'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾',
                      ),
                      _legendDot(
                        _amabasyaColor,
                        'Ã Â¦â€¦Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾',
                      ),
                      _legendDot(
                        _ekadashiColor,
                        'Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬',
                      ),
                      _legendDot(
                        _sankrantiColor,
                        'Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿',
                      ),
                      _legendDot(
                        _festivalColor,
                        'Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬/Ã Â¦Â°Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°',
                      ),
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
                            'Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â²Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¹ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¤Ã Â§â€¡',
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
                              // Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â§Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬/Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬
                              // Ã Â¦Â¬Ã Â¦Â¡Ã Â¦Â¼ illustration Ã¢â‚¬â€ Ã Â¦Â¯Ã Â¦Â¦Ã Â¦Â¿ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡
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
                                  ).name.contains(
                                    'Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾',
                                  )
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
                                          '${bnNum(sel.day)} ${gregMonthBn(sel.month)} ${bnNum(sel.year)} Ã¢â‚¬Â¢ $weekday',
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
                                        'Ã°Å¸Å’â„¢ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿',
                                        '${tithi.paksha}Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â· ${tithi.name}',
                                      ),
                                      _detailChip(
                                        'Ã¢Â­Â Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°',
                                        PanchangCalculator
                                            .nakshatraNames[nakIdx],
                                      ),
                                      _detailChip(
                                        'Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼',
                                        bnTime12(sun.sunrise),
                                      ),
                                      _detailChip(
                                        'Ã°Å¸Å’â€¡ Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤',
                                        bnTime12(sun.sunset),
                                      ),
                                      _detailChip(
                                        'Ã°Å¸ÂªÂ Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿',
                                        PanchangCalculator.rashiNames[rashiIdx],
                                      ),
                                      _detailChip(
                                        'Ã°Å¸â€â€” Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”',
                                        PanchangCalculator.yogaNames[yogaIdx],
                                      ),
                                      _detailChip(
                                        'Ã¢Å¡â„¢Ã¯Â¸Â Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£',
                                        karana,
                                      ),
                                      _detailChip(
                                        'Ã¢ÂÂ³ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â² (Ã Â¦ÂÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â²Ã Â§ÂÃ Â¦Â¨)',
                                        '${bnTime12(rahu['start']!)}Ã¢â‚¬â€œ${bnTime12(rahu['end']!)}',
                                      ),
                                      _detailChip(
                                        'Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¿Ã Â§Å½ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ (Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­)',
                                        abhijit['applicable'] == true
                                            ? '${bnTime12(abhijit['start'] as DateTime)}Ã¢â‚¬â€œ${bnTime12(abhijit['end'] as DateTime)}'
                                            : 'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¯Ã Â§â€¹Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Â¬Ã Â§ÂÃ Â¦Â§Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°)',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Ã°Å¸â€¢â€° ${tithi.name} Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â: ${ContentData._fmtTithiEdge(tithiStart)}  Ã¢â‚¬Â¢  Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·: ${ContentData._fmtTithiEdge(tithiEnd)}',
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
                                      'Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨/Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡',
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
                    'Ã°Å¸â€œÂ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿, Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°, Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿, Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€œ Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦â€ Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â§ÂÃ Â¦Â²Ã Â¦Â¤Ã Â¦Â¾)Ã Â¥Â¤ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹/Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¨/Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â§Â¨Ã Â§Â¦Ã Â§Â¨Ã Â§Â¬ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â®Ã Â§ÂÃ Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å“Ã Â¦Â¨ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â°Ã Â§ÂÃ Â¦Â¶ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¹Ã Â¥Â¤',
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

/// Ã Â¦ÂÃ Â¦â€¢Ã Â¦â€¡ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â§â€¡Ã Â¦Â° Ã Â¦ËœÃ Â¦Â°Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬/Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â²Ã Â¦Â¨-Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â²Ã Â§â€¡ Ã¢â‚¬â€
/// Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¥Ã Â¦Â®Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€ Ã Â¦Å¸Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â°Ã Â§â€¡Ã Â¦â€“Ã Â§â€¡, Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â²Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ (Ã Â¦â€¢Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¢ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡ Ã Â¦ÂªÃ Â¦Â° Ã Â¦ÂªÃ Â¦Â°)
/// Ã Â¦Â¨Ã Â¦Â°Ã Â¦Â® fade transition-Ã Â¦Â Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦Å¡Ã Â§â€¹Ã Â¦â€“Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â§â€¡Ã Â¥Â¤
/// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ËœÃ Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â®Ã Â§ÂÃ Â¦Â¬Ã Â§â€¡ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼,
/// Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹ Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦ËœÃ Â¦Â° Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¿Ã Â¦â€¢/Ã Â¦Å“Ã Â§â‚¬Ã Â¦Â¬Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
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

class ReminderItem {
  String text;
  DateTime when;

  /// Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â²/Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¨Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿
  final int id;
  ReminderItem(this.text, this.when, {int? id})
    : id = id ?? DateTime.now().microsecondsSinceEpoch.remainder(0x7FFFFFFF);
}

// =====================================================================
// Ã Â¦Â­Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¸ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Å¸Ã Â¦Â® Ã Â¦Â¶Ã Â§â‚¬Ã Â¦Å¸Ã Â¥Â¤ Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â¥Ã Â¦Â¾ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â­ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦ÂªÃ Â¦Â°
// VoiceReminderParser Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“/Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼/Ã Â¦Å¸Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Å¸ Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â­Ã Â¦Â¿Ã Â¦â€° Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
// Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬ "Ã Â¦Â«Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦â€œ" Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â²Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â«Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â«Ã Â¦Â² Ã Â¦Â«Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¤ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â² Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ existing
// _addReminder()/ReminderStore.instance.add() Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹
// Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­-Ã Â¦Â²Ã Â¦Å“Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡Ã Â¥Â¤
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
              _error =
                  'Ã Â¦Â­Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¸ Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨';
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
        _error =
            'Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â­Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¸ Ã Â¦â€¡Ã Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Å¸ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿';
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
      // Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â² Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¡Ã Â¦Â¿Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¡Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â²Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡Ã Â¦â€¡
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
            _error =
                'Ã Â¦Â­Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¸ Ã Â¦â€¡Ã Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Å¸ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿';
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
                'Ã Â¦Â­Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¸ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
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
            'Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨: "Ã Â¦â€ Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â®Ã Â§â‚¬Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¸Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â§Â¯Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â®Ã Â¦Â¨Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¦Ã Â¦Â¾Ã Â¦â€œ" Ã Â¦Â¬Ã Â¦Â¾ "Ã Â§Â¨Ã Â§Â« Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ '
            'Ã Â§Â¬Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂªÃ Â§â€šÃ Â¦Å“Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¥Ã Â¦Â¾ Ã Â¦Â®Ã Â¦Â¨Ã Â§â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¦Ã Â¦Â¾Ã Â¦â€œ"',
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
                  'Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â­Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¸ Ã Â¦â€¡Ã Â¦Â¨Ã Â¦ÂªÃ Â§ÂÃ Â¦Å¸ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦Å¸Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Å¸ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
                    ? (_listening
                          ? 'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¨Ã Â¦â€ºÃ Â¦Â¿Ã¢â‚¬Â¦ Ã Â¦Â¬Ã Â¦Â²Ã Â§ÂÃ Â¦Â¨'
                          : 'Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦â€¢ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Å¡Ã Â§â€¡Ã Â¦ÂªÃ Â§â€¡ Ã Â¦Â¬Ã Â¦Â²Ã Â§ÂÃ Â¦Â¨')
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
                      'Ã Â¦Â¬Ã Â§ÂÃ Â¦ÂÃ Â§â€¡Ã Â¦â€ºÃ Â¦Â¿:',
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
                          ? 'Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“/Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â§â€¹Ã Â¦ÂÃ Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿ Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¨'
                          : '${_result!.when!.day}/${_result!.when!.month}/${_result!.when!.year}'
                                ' Ã¢â‚¬Â¢ ${_result!.when!.hour.toString().padLeft(2, "0")}:${_result!.when!.minute.toString().padLeft(2, "0")}'
                                '${!_result!.timeFound ? " (Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¨)" : ""}',
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
                    'Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€ Ã Â¦â€ºÃ Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â«Ã Â¦Â°Ã Â§ÂÃ Â¦Â®Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦â€œ',
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
    // Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦Â«Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
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
        content: Text(
          'Ã Â¦Â­Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¸ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â«Ã Â¦Â°Ã Â§ÂÃ Â¦Â® Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â¦Â£ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
        ),
      ),
    );
  }

  void _addReminder() {
    final text = _textController.text.trim();
    if (text.isEmpty || _pickedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ã Â¦Å¸Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Å¸ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
          ),
        ),
      );
      return;
    }
    // Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡, Ã Â¦â€ Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â§Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â«Ã Â¦Â¿Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¶Ã Â¦Â¨Ã Â¦â€œ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
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
          const _ScreenHeader(
            title:
                'Ã¢ÂÂ° Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
          ),
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
                      'Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¤Ã Â§Ë†Ã Â¦Â°Ã Â¦Â¿ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
                    hintText:
                        'Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨: Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¶Ã Â§â‚¬ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â°Ã Â¦Â¤',
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
                        ? 'Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€ºÃ Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨'
                        : '${_pickedDateTime!.day}/${_pickedDateTime!.month}/${_pickedDateTime!.year} Ã¢â‚¬Â¢ ${_pickedDateTime!.hour.toString().padLeft(2, "0")}:${_pickedDateTime!.minute.toString().padLeft(2, "0")}',
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
                      'Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
                    'Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â¦â€œ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡Ã Â¥Â¤',
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
                                  '${r.when.day}/${r.when.month}/${r.when.year} Ã¢â‚¬Â¢ ${r.when.hour.toString().padLeft(2, "0")}:${r.when.minute.toString().padLeft(2, "0")}',
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
// Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¸
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
    // Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹ Ã Â¦Â«Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
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
          const _ScreenHeader(
            title:
                'Ã°Å¸â€œÂ Ã Â¦â€ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸Ã Â¦Â¸',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText:
                        'Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸ Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨...',
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
                      'Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
                    'Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â¦â€œ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¨Ã Â§â€¹Ã Â¦Å¸ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡Ã Â¥Â¤',
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
// Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã¢â‚¬â€ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨/Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦â€¢Ã Â§â‚¬ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾
// (Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡Ã Â¦Â° Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡, Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¡Ã Â¦Â¿Ã Â¦Â­Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¿Ã Â¦â„¢Ã Â§ÂÃ Â¦â€¢ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾)
// =====================================================================

class FamilyMemberItem {
  String name;
  String
  occasion; // 'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨' | 'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦â€¢Ã Â§â‚¬' | 'Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯'
  DateTime date;
  final int id;
  FamilyMemberItem(this.name, this.occasion, this.date, {int? id})
    : id = id ?? DateTime.now().microsecondsSinceEpoch.remainder(0x7FFFFFFF);

  /// Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Å¡Ã Â¦Â²Ã Â§â€¡ Ã Â¦â€”Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â«Ã Â§â€¡Ã Â¦Â°Ã Â¦Â¤ Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼
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

/// Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã¢â‚¬â€ Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡
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
  String _occasion = 'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨';
  DateTime? _pickedDate;

  static const _occasions = [
    'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦â€¢Ã Â§â‚¬',
    'Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯',
  ];

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â® Ã Â¦â€œ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¦Ã Â§ÂÃ Â¦Å¸Ã Â§â€¹Ã Â¦â€¡ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
          ),
        ),
      );
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
            '${_emojiFor(m.occasion)} ${m.name} Ã¢â‚¬â€ ${m.occasion}',
            when,
          ),
        )
        .then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã¢ÂÂ°',
                ),
              ),
            );
          }
        });
  }

  String _emojiFor(String occasion) {
    switch (occasion) {
      case 'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨':
        return 'Ã°Å¸Å½â€š';
      case 'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦â€¢Ã Â§â‚¬':
        return 'Ã°Å¸â€™Â';
      default:
        return 'Ã°Å¸â€œÅ’';
    }
  }

  String _subtitleFor(FamilyMemberItem m) {
    final days = m.daysLeft;
    final whenTxt = days == 0
        ? 'Ã Â¦â€ Ã Â¦Å“! Ã°Å¸Å½â€°'
        : 'Ã Â¦â€ Ã Â¦Â° ${bnNum(days)} Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¿';
    final years = m.upcomingYears;
    if (m.occasion == 'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨' &&
        years > 0) {
      return '$whenTxt Ã¢â‚¬Â¢ ${bnNum(years)} Ã Â¦Â¬Ã Â¦â€ºÃ Â¦Â° Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡';
    }
    if (m.occasion ==
            'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦â€¢Ã Â§â‚¬' &&
        years > 0) {
      return '$whenTxt Ã¢â‚¬Â¢ ${bnNum(years)} Ã Â¦Â¤Ã Â¦Â® Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦â€¢Ã Â§â‚¬';
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
          const _ScreenHeader(
            title:
                'Ã°Å¸â€˜Â¨Ã¢â‚¬ÂÃ°Å¸â€˜Â©Ã¢â‚¬ÂÃ°Å¸â€˜Â§Ã¢â‚¬ÂÃ°Å¸â€˜Â¦ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                const SizedBox(height: 170),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText:
                        'Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â® (Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨: Ã Â¦Â®Ã Â¦Â¾, Ã Â¦Â¦Ã Â¦Â¾Ã Â¦Â¦Ã Â§Â, Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¦Ã Â¦Â¿)',
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
                        ? 'Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€ºÃ Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨'
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
                      'Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
                    'Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â¦â€œ Ã Â¦â€¢Ã Â§â€¡Ã Â¦â€° Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿Ã Â¥Â¤',
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
                                  '${m.name} Ã¢â‚¬Â¢ ${m.occasion}',
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
                            tooltip:
                                'Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
// Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â° Ã¢â‚¬â€ Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦â€œ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¦ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â§â‚¬ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·
// Ã Â¦ÂªÃ Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦â€ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â° Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¶ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ (Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ "Ã°Å¸â€œÂ¿ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â£"-Ã Â¦ÂÃ Â¦Â° Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨
// Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨ Ã Â¦â€¦Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â° Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¹ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡)
// =====================================================================

class BabyNamingScreen extends StatefulWidget {
  const BabyNamingScreen({super.key});
  @override
  State<BabyNamingScreen> createState() => _BabyNamingScreenState();
}

class _BabyNamingScreenState extends State<BabyNamingScreen> {
  DateTime? _birth;

  // Ã Â§Â¨Ã Â§Â­Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ãƒâ€” Ã Â§ÂªÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¦ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡Ã Â¦Â° Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â®
  // PanchangCalculator.nakshatraNames Ã Â¦ÂÃ Â¦Â° Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â® Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬
  static const List<List<String>> _namingLetters = [
    [
      'Ã Â¦Å¡Ã Â§Â',
      'Ã Â¦Å¡Ã Â§â€¡',
      'Ã Â¦Å¡Ã Â§â€¹',
      'Ã Â¦Â²Ã Â¦Â¾',
    ], // Ã Â¦â€¦Ã Â¦Â¶Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨Ã Â§â‚¬
    [
      'Ã Â¦Â²Ã Â¦Â¿',
      'Ã Â¦Â²Ã Â§Â',
      'Ã Â¦Â²Ã Â§â€¡',
      'Ã Â¦Â²Ã Â§â€¹',
    ], // Ã Â¦Â­Ã Â¦Â°Ã Â¦Â£Ã Â§â‚¬
    [
      'Ã Â¦â€¦',
      'Ã Â¦â€¡',
      'Ã Â¦â€°',
      'Ã Â¦Â',
    ], // Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾
    [
      'Ã Â¦â€œ',
      'Ã Â¦Â¬Ã Â¦Â¾',
      'Ã Â¦Â¬Ã Â¦Â¿',
      'Ã Â¦Â¬Ã Â§Â',
    ], // Ã Â¦Â°Ã Â§â€¹Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â£Ã Â§â‚¬
    [
      'Ã Â¦Â¬Ã Â§â€¡',
      'Ã Â¦Â¬Ã Â§â€¹',
      'Ã Â¦â€¢Ã Â¦Â¾',
      'Ã Â¦â€¢Ã Â¦Â¿',
    ], // Ã Â¦Â®Ã Â§Æ’Ã Â¦â€”Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â°Ã Â¦Â¾
    [
      'Ã Â¦â€¢Ã Â§Â',
      'Ã Â¦Ëœ',
      'Ã Â¦â„¢',
      'Ã Â¦â€º',
    ], // Ã Â¦â€ Ã Â¦Â°Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾
    [
      'Ã Â¦â€¢Ã Â§â€¡',
      'Ã Â¦â€¢Ã Â§â€¹',
      'Ã Â¦Â¹Ã Â¦Â¾',
      'Ã Â¦Â¹Ã Â¦Â¿',
    ], // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¨Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¸Ã Â§Â
    [
      'Ã Â¦Â¹Ã Â§Â',
      'Ã Â¦Â¹Ã Â§â€¡',
      'Ã Â¦Â¹Ã Â§â€¹',
      'Ã Â¦Â¡',
    ], // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾
    [
      'Ã Â¦Â¡Ã Â¦Â¿',
      'Ã Â¦Â¡Ã Â§Â',
      'Ã Â¦Â¡Ã Â§â€¡',
      'Ã Â¦Â¡Ã Â§â€¹',
    ], // Ã Â¦â€¦Ã Â¦Â¶Ã Â§ÂÃ Â¦Â²Ã Â§â€¡Ã Â¦Â·Ã Â¦Â¾
    [
      'Ã Â¦Â®Ã Â¦Â¾',
      'Ã Â¦Â®Ã Â¦Â¿',
      'Ã Â¦Â®Ã Â§Â',
      'Ã Â¦Â®Ã Â§â€¡',
    ], // Ã Â¦Â®Ã Â¦ËœÃ Â¦Â¾
    [
      'Ã Â¦Â®Ã Â§â€¹',
      'Ã Â¦Å¸Ã Â¦Â¾',
      'Ã Â¦Å¸Ã Â¦Â¿',
      'Ã Â¦Å¸Ã Â§Â',
    ], // Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â«Ã Â¦Â¾Ã Â¦Â²Ã Â§ÂÃ Â¦â€”Ã Â§ÂÃ Â¦Â¨Ã Â§â‚¬
    [
      'Ã Â¦Å¸Ã Â§â€¡',
      'Ã Â¦Å¸Ã Â§â€¹',
      'Ã Â¦ÂªÃ Â¦Â¾',
      'Ã Â¦ÂªÃ Â¦Â¿',
    ], // Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Â«Ã Â¦Â¾Ã Â¦Â²Ã Â§ÂÃ Â¦â€”Ã Â§ÂÃ Â¦Â¨Ã Â§â‚¬
    [
      'Ã Â¦ÂªÃ Â§Â',
      'Ã Â¦Â·',
      'Ã Â¦Â£',
      'Ã Â¦Â ',
    ], // Ã Â¦Â¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾
    [
      'Ã Â¦ÂªÃ Â§â€¡',
      'Ã Â¦ÂªÃ Â§â€¹',
      'Ã Â¦Â°Ã Â¦Â¾',
      'Ã Â¦Â°Ã Â¦Â¿',
    ], // Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾
    [
      'Ã Â¦Â°Ã Â§Â',
      'Ã Â¦Â°Ã Â§â€¡',
      'Ã Â¦Â°Ã Â§â€¹',
      'Ã Â¦Â¤Ã Â¦Â¾',
    ], // Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â¤Ã Â§â‚¬
    [
      'Ã Â¦Â¤Ã Â¦Â¿',
      'Ã Â¦Â¤Ã Â§Â',
      'Ã Â¦Â¤Ã Â§â€¡',
      'Ã Â¦Â¤Ã Â§â€¹',
    ], // Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â¾
    [
      'Ã Â¦Â¨Ã Â¦Â¾',
      'Ã Â¦Â¨Ã Â¦Â¿',
      'Ã Â¦Â¨Ã Â§Â',
      'Ã Â¦Â¨Ã Â§â€¡',
    ], // Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â§Ã Â¦Â¾
    [
      'Ã Â¦Â¨Ã Â§â€¹',
      'Ã Â¦Â¯Ã Â¦Â¾',
      'Ã Â¦Â¯Ã Â¦Â¿',
      'Ã Â¦Â¯Ã Â§Â',
    ], // Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¾
    [
      'Ã Â¦Â¯Ã Â§â€¡',
      'Ã Â¦Â¯Ã Â§â€¹',
      'Ã Â¦Â­Ã Â¦Â¾',
      'Ã Â¦Â­Ã Â¦Â¿',
    ], // Ã Â¦Â®Ã Â§â€šÃ Â¦Â²Ã Â¦Â¾
    [
      'Ã Â¦Â­Ã Â§Â',
      'Ã Â¦Â§Ã Â¦Â¾',
      'Ã Â¦Â«Ã Â¦Â¾',
      'Ã Â¦Â¢Ã Â¦Â¾',
    ], // Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â¾Ã Â¦Â¢Ã Â¦Â¼Ã Â¦Â¾
    [
      'Ã Â¦Â­Ã Â§â€¡',
      'Ã Â¦Â­Ã Â§â€¹',
      'Ã Â¦Å“Ã Â¦Â¾',
      'Ã Â¦Å“Ã Â¦Â¿',
    ], // Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â¾Ã Â¦Â¢Ã Â¦Â¼Ã Â¦Â¾
    [
      'Ã Â¦Å“Ã Â§Â',
      'Ã Â¦Å“Ã Â§â€¡',
      'Ã Â¦Å“Ã Â§â€¹',
      'Ã Â¦Ëœ',
    ], // Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â£Ã Â¦Â¾
    [
      'Ã Â¦â€”Ã Â¦Â¾',
      'Ã Â¦â€”Ã Â¦Â¿',
      'Ã Â¦â€”Ã Â§Â',
      'Ã Â¦â€”Ã Â§â€¡',
    ], // Ã Â¦Â§Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¾
    [
      'Ã Â¦â€”Ã Â§â€¹',
      'Ã Â¦Â¸Ã Â¦Â¾',
      'Ã Â¦Â¸Ã Â¦Â¿',
      'Ã Â¦Â¸Ã Â§Â',
    ], // Ã Â¦Â¶Ã Â¦Â¤Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â·Ã Â¦Â¾
    [
      'Ã Â¦Â¸Ã Â§â€¡',
      'Ã Â¦Â¸Ã Â§â€¹',
      'Ã Â¦Â¦Ã Â¦Â¾',
      'Ã Â¦Â¦Ã Â¦Â¿',
    ], // Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦ÂªÃ Â¦Â¦
    [
      'Ã Â¦Â¦Ã Â§Â',
      'Ã Â¦Â¥Ã Â¦Â¾',
      'Ã Â¦ÂÃ Â¦Â¾',
      'Ã Â¦Å¾',
    ], // Ã Â¦â€°Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â¦ÂªÃ Â¦Â¦
    [
      'Ã Â¦Â¦Ã Â§â€¡',
      'Ã Â¦Â¦Ã Â§â€¹',
      'Ã Â¦Å¡Ã Â¦Â¾',
      'Ã Â¦Å¡Ã Â¦Â¿',
    ], // Ã Â¦Â°Ã Â§â€¡Ã Â¦Â¬Ã Â¦Â¤Ã Â§â‚¬
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
          const _ScreenHeader(
            title:
                'Ã°Å¸â€Â¤ Ã Â¦Â¶Ã Â¦Â¿Ã Â¦Â¶Ã Â§ÂÃ Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â°',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                const SizedBox(height: 170),
                const Text(
                  'Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®-Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â®-Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦â€œ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¦ '
                  'Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¯Ã Â¦â€”Ã Â¦Â¤Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Å¡Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â° Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡Ã Â¥Â¤',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                _DateTimePickerField(
                  label:
                      'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€ºÃ Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
                          'Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¶Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦â€ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â°',
                          style: TextStyle(
                            color: Color(0xFF071428),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recommended ?? 'Ã¢â‚¬â€',
                          style: const TextStyle(
                            color: Color(0xFF071428),
                            fontWeight: FontWeight.w900,
                            fontSize: 44,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ã¢Â­Â Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°: ${PanchangCalculator.nakshatraNames[nakIdx!]} Ã¢â‚¬Â¢ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¦ ${bnNum(pada!)}',
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
                          '${PanchangCalculator.nakshatraNames[nakIdx!]} Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â§ÂªÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¦Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦Â¦Ã Â§ÂÃ Â¦Â¯Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â°',
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
                    'Ã¢â€žÂ¹Ã¯Â¸Â Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹Ã Â§â‚¬ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·-Ã Â¦Â¶Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â° Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¸Ã Â§ÂÃ Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¶Ã Â¥Â¤ '
                    'Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¦Ã Â§â€¡ Ã Â¦â€°Ã Â¦Å¡Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â£Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¤Ã Â§â€¡ '
                    'Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Å¡Ã Â§â€šÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦Â¬Ã Â¦Â¾ '
                    'Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¹Ã Â¥Â¤',
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
// Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ Ã¢â‚¬â€ Ã Â¦Å“Ã Â¦Â®Ã Â¦Â¿/Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿/Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾, Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶, Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹, Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯
// Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â°Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¿Ã Â¦Â¤ Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨ (Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾/GPS) Ã Â¦â€œ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾-Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢
// Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€œ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ (Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¿Ã Â§Å½ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ + Ã¢Å¡Â Ã¯Â¸Â Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â²) Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¸Ã Â¦â€šÃ Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â¦Â°Ã Â¦Â£Ã Â§â€¡
// Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â UI Ã Â¦â€œ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦ÂÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¡ Ã Â¦â€¢Ã Â¦Â² Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡Ã Â¥Â¤
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
    _ShubhoCategory('Ã°Å¸â€™Â', 'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¹', 'marriage'),
    _ShubhoCategory(
      'Ã°Å¸ÂÂ ',
      'Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶',
      'griha',
    ),
    _ShubhoCategory(
      'Ã°Å¸Âªâ€',
      'Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â',
      'byabosha',
    ),
    _ShubhoCategory(
      'Ã°Å¸ÂÅ¾Ã¯Â¸Â',
      'Ã Â¦Å“Ã Â¦Â®Ã Â¦Â¿ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾',
      'jomi',
    ),
    _ShubhoCategory(
      'Ã°Å¸ÂÂ¡',
      'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾',
      'bari',
    ),
    _ShubhoCategory(
      'Ã°Å¸Å¡â€”',
      'Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾',
      'gari',
    ),
  ];

  String _selectedKey = 'marriage';
  DateTime _fromDate = DateTime.now();

  // "Ã Â¦â€¢Ã Â¦Â¤ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡" Ã¢â‚¬â€ Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â¡Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨ Ã Â¦Â«Ã Â¦Â¿Ã Â¦Â²Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â¥Â¤ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â UI-Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾
  // Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â°, existing findAuspiciousMuhurtas/findAuspiciousDates
  // Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â¶Ã Â¦Â¨Ã Â§â€¡ Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ maxDays Ã Â¦ÂªÃ Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â§â€¡ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹
  // Ã Â¦Â¨Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¨ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¬/Ã Â¦Â²Ã Â¦Å“Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° calculation Ã Â¦â€¦Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¤Ã Â¥Â¤
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
        .add(
          ReminderItem(
            '${cat.emoji} ${cat.title} Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤',
            start,
          ),
        )
        .then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã¢ÂÂ°',
                ),
              ),
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
          const _ScreenHeader(
            title:
                'Ã°Å¸â€¢â€°Ã¯Â¸Â Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                const SizedBox(height: 170),
                const Text(
                  'Ã Â¦Å“Ã Â¦Â®Ã Â¦Â¿/Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿/Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾, Ã Â¦â€”Ã Â§Æ’Ã Â¦Â¹Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¶, Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ '
                  'Ã Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§ÂÃ Â¦Â¬Ã Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â‚¬ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ '
                  'Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨Ã Â¥Â¤',
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
                  'Ã Â¦â€¢Ã Â¦Â¤ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡?',
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
                          '${bnNum(d)} Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
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
                  '${cat.emoji} ${cat.title}-Ã Â¦ÂÃ Â¦Â° Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â‚¬ ${bnNum(_deadlineDays)} '
                  'Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â¦â€”Ã Â§ÂÃ Â¦Â²Ã Â§â€¹',
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
                      'Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¬Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â§â‚¬ ${bnNum(_deadlineDays)} Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ '
                      'Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¡Ã Â¦Â¼ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¸Ã Â§â‚¬Ã Â¦Â®Ã Â¦Â¾ Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨Ã Â¥Â¤',
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
                                '${date.day}/${date.month}/${date.year} Ã¢â‚¬Â¢ '
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
                            '${tithi.paksha} Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â· Ã¢â‚¬Â¢ ${tithi.name} Ã¢â‚¬Â¢ '
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
                                  'Ã¢Ëœâ‚¬Ã¯Â¸Â ',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Expanded(
                                  child: Text(
                                    'Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¿Ã Â§Å½ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤: '
                                    '${bnTime12(m['abhijitStart'] as DateTime)} Ã¢â‚¬â€œ '
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
                              'Ã¢Ëœâ‚¬Ã¯Â¸Â Ã Â¦â€ Ã Â¦Å“ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â§Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã¢â‚¬â€ Ã Â¦ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦Â¹Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â§â‚¬ Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¿Ã Â§Å½ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ '
                              'Ã Â¦Â§Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text(
                                'Ã¢Å¡Â Ã¯Â¸Â ',
                                style: TextStyle(fontSize: 14),
                              ),
                              Expanded(
                                child: Text(
                                  'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â² (Ã Â¦ÂÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â²Ã Â§ÂÃ Â¦Â¨): '
                                  '${bnTime12(m['rahuStart'] as DateTime)} Ã¢â‚¬â€œ '
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
                                'Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
                  'Ã¢â€žÂ¹Ã¯Â¸Â Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¿ Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°-Ã Â¦Â­Ã Â¦Â¿Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â²Ã Â§â‚¬Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤ '
                  'Ã Â¦Â²Ã Â¦â€”Ã Â§ÂÃ Â¦Â¨-Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â²Ã Â§ÂÃ Â¦Âª Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿/Ã Â¦Å“Ã Â¦Â®Ã Â¦Â¿/Ã Â¦â€”Ã Â¦Â¾Ã Â¦Â¡Ã Â¦Â¼Ã Â¦Â¿ Ã Â¦Â°Ã Â§â€¡Ã Â¦Å“Ã Â¦Â¿Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Â¬Ã Â¦Â¾ '
                  'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹ Ã Â¦Â¬Ã Â¦Â¡Ã Â¦Â¼ Ã Â¦Â¸Ã Â¦Â¿Ã Â¦Â¦Ã Â§ÂÃ Â¦Â§Ã Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ Ã Â¦â€”Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å“Ã Â¦Â¨ Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬Ã Â¦Â° '
                  'Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦Â®Ã Â§ÂÃ Â¦Â¹Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¤ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¹Ã Â¥Â¤',
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
                'Ã Â¦Å“Ã Â§â€¡Ã Â¦Â²Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€ºÃ Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
// Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â®Ã Â§â€¡Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â° Ã¢â‚¬â€ Ã Â¦Â¯Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬/Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â°
// Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ + Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â® + Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â°Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â‚¬Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®), Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¿Ã Â¦Â­
// Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¶Ã Â§â‚¬Ã Â¦Å¸ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ WhatsApp/Facebook/Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¯Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤ Ã Â¦â€ºÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾
// Ã Â¦Â¸Ã Â¦Â®Ã Â§ÂÃ Â¦ÂªÃ Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â£ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿ (Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â° Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â°Ã Â§â€¡Ã Â¦â€¡ RepaintBoundary Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡) Ã Â¦Â¤Ã Â§Ë†Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹
// Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦ÂÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¡/Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤
// =====================================================================

// =====================================================================
// Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€” Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡ Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿/Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°/Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿/Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼-Ã Â¦â€¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾
// Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â° Ã Â¦Â¡Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦â€ºÃ Â¦Â¬Ã Â¦Â¿-Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡ Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢-Ã Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤ Ã Â¦â€¢Ã Â§Å’Ã Â¦Â¶Ã Â¦Â²Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢
// Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â®Ã Â§â€¡Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â®Ã Â¦Â¤Ã Â§â€¹Ã Â¦â€¡ Ã¢â‚¬â€ RepaintBoundary Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â²Ã Â§â€¹Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿ Ã Â¦â€ºÃ Â¦Â¬Ã Â¦Â¿ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡
// Share.shareXFiles Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼, Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦ÂÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¡/Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¨Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â²Ã Â¦Â¾Ã Â¦â€”Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤
// Panchang calculation-Ã Â¦ÂÃ Â¦Â° Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â¶Ã Â¦Â¨ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¬Ã Â¦Â¦Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿, Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â read Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾
// Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡Ã Â¥Â¤
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
          ? 'Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€” Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾'
          : 'Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€” Ã¢â‚¬â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾\n\nÃ°Å¸â€œÂ² Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â¦Â²Ã Â§â€¹Ã Â¦Â¡ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨:\n${AppLinks.playStore}';
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: 'ajker_panchang.png',
            mimeType: 'image/png',
          ),
        ],
        text: shareText,
        subject:
            'Ã Â¦â€ Ã Â¦Å“Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€”',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
            ),
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
          const _ScreenHeader(
            title:
                'Ã°Å¸â€œÂ¤ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å¡Ã Â¦Â¾Ã Â¦â„¢Ã Â§ÂÃ Â¦â€” Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡',
          ),
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
                              'Ã°Å¸ÂªÂ· Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾',
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
                                'Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¥Ã Â¦Â¿',
                                '${tithi.paksha} Ã Â¦ÂªÃ Â¦â€¢Ã Â§ÂÃ Â¦Â· Ã¢â‚¬Â¢ ${tithi.name}',
                              ),
                              _cardRow(
                                'Ã Â¦Â¨Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â¦Â¤Ã Â§ÂÃ Â¦Â°',
                                PanchangCalculator.nakshatraNames[nakIdx],
                              ),
                              _cardRow(
                                'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¶Ã Â¦Â¿',
                                PanchangCalculator.rashiNames[rashiIdx],
                              ),
                              _cardRow(
                                'Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¦Ã Â¦Â¯Ã Â¦Â¼',
                                bnTime12(sun.sunrise),
                              ),
                              _cardRow(
                                'Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤',
                                bnTime12(sun.sunset),
                              ),
                              _cardRow(
                                'Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¹Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â²',
                                '${bnTime12(rahu['start']!)}Ã¢â‚¬â€œ${bnTime12(rahu['end']!)}',
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Center(
                          child: Text(
                            'Ã°Å¸Å’â„¢ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã°Å¸Å’â„¢',
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
                  label: Text(
                    _sharing
                        ? 'Ã Â¦Â¤Ã Â§Ë†Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡...'
                        : 'Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
                  ),
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
    _PosterTheme(
      'Ã Â¦Â¸Ã Â§â€¹Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬',
      [Color(0xFF7A2E2E), Color(0xFFB8860B), Color(0xFFFFD36E)],
      Colors.white,
    ),
    _PosterTheme('Ã Â¦Â¦Ã Â§ÂÃ Â¦Â°Ã Â§ÂÃ Â¦â€”Ã Â¦Â¾ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â²', [
      Color(0xFF7A0C2E),
      Color(0xFFB3123D),
      Color(0xFFFF6B81),
    ], Colors.white),
    _PosterTheme('Ã Â¦Â°Ã Â¦â„¢Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬', [
      Color(0xFF3A1C71),
      Color(0xFFD76D77),
      Color(0xFFFFAF7B),
    ], Colors.white),
    _PosterTheme('Ã Â¦â€¢Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Â¨Ã Â§â‚¬Ã Â¦Â²', [
      Color(0xFF0B1C38),
      Color(0xFF183F69),
      Color(0xFFFFD36E),
    ], Colors.white),
    _PosterTheme(
      'Ã Â¦Â¸Ã Â¦Â¬Ã Â§ÂÃ Â¦Å“ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦â€¢Ã Â§Æ’Ã Â¦Â¤Ã Â¦Â¿',
      [Color(0xFF134E1E), Color(0xFF2E7D32), Color(0xFFC5E1A5)],
      Colors.white,
    ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨',
          ),
        ),
      );
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
          ? 'Ã°Å¸Âªâ€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ $festival'
          : 'Ã°Å¸Âªâ€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ $festival Ã¢â‚¬â€ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­Ã Â§â€¡Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡, $name';
      // Play Store-Ã Â¦Â Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¶ Ã Â¦Â¹Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â° AppLinks.playStore-Ã Â¦Â Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€šÃ Â¦â€¢ Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡
      // Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°-Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Å¸Ã Â§â€¡Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦Å¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â¦Â²Ã Â§â€¹Ã Â¦Â¡Ã Â§â€¡Ã Â¦Â° Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€šÃ Â¦â€¢Ã Â¦â€œ Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€” Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡
      final shareText = AppLinks.playStore.isEmpty
          ? greeting
          : '$greeting\n\nÃ°Å¸â€œÂ² Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â¦Â²Ã Â§â€¹Ã Â¦Â¡ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨:\n${AppLinks.playStore}';
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: 'utsob_shuveccha.png',
            mimeType: 'image/png',
          ),
        ],
        text: shareText,
        subject: 'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ $festival',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¤Ã Â§Ë†Ã Â¦Â°Ã Â¦Â¿ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿ Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
            ),
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
          const _ScreenHeader(
            title:
                'Ã°Å¸Å½â€° Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â®Ã Â§â€¡Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                const SizedBox(height: 170),
                const Text(
                  'Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®, Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â¦Â° Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â§ÂÃ Â¦Â¯ '
                  'Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â¨ Ã¢â‚¬â€ WhatsApp/Facebook-Ã Â¦Â Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¨Ã Â¥Â¤',
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
                              avatar: Text(f['icon'] ?? 'Ã°Å¸Å½â€°'),
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
                    hintText:
                        'Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â® (Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨: Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¶Ã Â¦Â®Ã Â§â‚¬)',
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
                    hintText:
                        'Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â® (Ã Â¦ÂÃ Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â¦Â¿Ã Â¦â€¢)',
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
                    '${bnNum(_date.year)} Ã¢â‚¬Â¢ ${bnNum(bDay)} ${info.name}',
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
                  'Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¥Ã Â¦Â¿Ã Â¦Â®',
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
                      festival: festival.isEmpty
                          ? 'Ã Â¦â€°Ã Â§Å½Ã Â¦Â¸Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®'
                          : festival,
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
                          ? 'Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¤Ã Â§Ë†Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¹Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â§â€¡...'
                          : 'Ã°Å¸â€œÂ¤ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨ (WhatsApp/Facebook)',
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
                  'Ã¢â€žÂ¹Ã¯Â¸Â Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â²Ã Â§â€¡ Ã Â¦Â«Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€“Ã Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â€¡ Ã¢â‚¬â€ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨ '
                  'Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ WhatsApp, Facebook Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦â€¦Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¯Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡ '
                  'Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¨Ã Â¥Â¤',
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
          const Text('Ã¢Å“Â¨ Ã°Å¸Âªâ€ Ã¢Å“Â¨', style: TextStyle(fontSize: 26)),
          const SizedBox(height: 10),
          Text(
            'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­',
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
            '$dateLabel  Ã¢â‚¬Â¢  $gregLabel',
            style: TextStyle(
              color: theme.textColor.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Ã Â¦Â¶Ã Â§ÂÃ Â¦Â­Ã Â§â€¡Ã Â¦Å¡Ã Â§ÂÃ Â¦â€ºÃ Â¦Â¾Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡',
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
            'Ã°Å¸ÂªÂ· Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾',
            style: TextStyle(
              color: theme.textColor.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          // Play Store-Ã Â¦Â Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¶ Ã Â¦Â¹Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â° Ã Â¦ÂªÃ Â¦Â° AppLinks.playStore-Ã Â¦Â Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€šÃ Â¦â€¢ Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡
          // Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â¦Â²Ã Â§â€¹Ã Â¦Â¡-Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å“Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂÃ Â¦Â®Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¤Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡; Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿
          // Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â¾ Ã Â¦â€¦Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¥Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¬Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¶ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿) Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦Â²Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â§â€¡
          if (AppLinks.playStore.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Ã°Å¸â€œÂ² Play Store-Ã Â¦Â Ã Â¦Â¡Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â¦Â²Ã Â§â€¹Ã Â¦Â¡ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
// Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¸
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
          const _ScreenHeader(
            title: 'Ã¢Å¡â„¢Ã¯Â¸Â Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¸',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Ã Â¦Â­Ã Â¦Â¾Ã Â¦Â·Ã Â¦Â¾',
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
                    items:
                        ['Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾', 'Hindi', 'English']
                            .map(
                              (l) => DropdownMenuItem(value: l, child: Text(l)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _lang = v ?? _lang),
                  ),
                ),
                const SizedBox(height: 16),
                _switchTile(
                  'Ã°Å¸â€œÂ Live Location Weather',
                  _weather,
                  (v) => setState(() => _weather = v),
                ),
                _switchTile(
                  'Ã°Å¸Å’Å’ Live Sky Animation',
                  _skyAnim,
                  (v) => setState(() => _skyAnim = v),
                ),
                _switchTile(
                  'Ã°Å¸â€â€ Notifications',
                  _notifications,
                  (v) => setState(() => _notifications = v),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ã Â¦â€¦Ã Â¦Å¸Ã Â§â€¹ Ã Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _switchTile(
                  'Ã°Å¸Âªâ€ Ã Â¦Â¸Ã Â¦Â¨Ã Â§ÂÃ Â¦Â§Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¦Ã Â§â‚¬Ã Â¦Âª (Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ real Ã Â¦Â¸Ã Â§â€šÃ Â¦Â°Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡)',
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
                        const SnackBar(
                          content: Text(
                            'Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¸ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD36E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¿Ã Â¦â€šÃ Â¦Â¸ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§â€¡Ã Â¦Å“Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ "Ã Â¦Å¸Ã Â¦Âª Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°" Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ Ã¢â‚¬â€ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â²Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â°Ã Â¦Â¿ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€¡
// Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€“Ã Â§ÂÃ Â¦Â²Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²/Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ _PremiumGate Ã Â¦Â²Ã Â¦â€¢ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡,
// Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â¡ Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¤Ã Â§â€¡ Ã Â¦â€”Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦â€“Ã Â§ÂÃ Â¦ÂÃ Â¦Å“Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾)Ã Â¥Â¤ Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â®Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°
// Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å“Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬ Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡ screenBuilder Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡ Ã¢â‚¬â€ Ã Â¦Â¤Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¯Ã Â§â€¹Ã Â¦â€”Ã Â§ÂÃ Â¦Â¯ Ã Â¦Â¨Ã Â¦Â¯Ã Â¦Â¼Ã Â¥Â¤
// =====================================================================

class _PremiumFeature {
  final String emoji;
  final String title;
  final Widget Function()? screenBuilder;
  const _PremiumFeature(this.emoji, this.title, [this.screenBuilder]);
}

final List<_PremiumFeature> _premiumFeatures = [
  _PremiumFeature(
    'Ã°Å¸ÂªÂ',
    'Ã Â¦Å¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¦Ã Â§ÂÃ Â¦Â° Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸',
    () => const KundliScreen(),
  ),
  _PremiumFeature(
    'Ã°Å¸â€™Å¾',
    'Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â²Ã Â¦Â¨',
    () => const KundliMilanScreen(),
  ),
  _PremiumFeature(
    'Ã°Å¸â€œâ€ž',
    'Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾ PDF Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸',
    () => const PdfExportScreen(),
  ),
  _PremiumFeature(
    'Ã¢ËœÂÃ¯Â¸Â',
    'Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª',
    () => const CloudBackupScreen(),
  ),
  _PremiumFeature(
    'Ã°Å¸â€Â®',
    'Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â¦ÂªÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â°Ã Â§ÂÃ Â¦Â¶ Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š',
    () => const AstrologerBookingScreen(),
  ),
  const _PremiumFeature(
    'Ã°Å¸Å¡Â«',
    'Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â®Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¤ Ã Â¦â€¦Ã Â¦Â­Ã Â¦Â¿Ã Â¦Å“Ã Â§ÂÃ Â¦Å¾Ã Â¦Â¤Ã Â¦Â¾',
  ),
];

// =====================================================================
// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§â€¡Ã Â¦Å“Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂÃ Â¦â€¢Ã Â¦Â¦Ã Â¦Â® Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡ Ã¢â‚¬â€ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®, Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“, Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾,
// Ã Â¦Â¸Ã Â¦Â¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿ Ã Â¦â€œ Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¸ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å“ (Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²/Ã Â¦Â¸Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨)Ã Â¥Â¤ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â° Ã¢Å“ÂÃ¯Â¸Â
// Ã Â¦â€ Ã Â¦â€¡Ã Â¦â€¢Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂÃ Â¦Â¡Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â² Ã Â¦ÂªÃ Â§â€¡Ã Â¦Å“Ã Â§â€¡ Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â¤Ã Â§â€¡ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¨Ã Â¦Â¾Ã Â¥Â¤
// =====================================================================

class _MemberDetailsCard extends StatefulWidget {
  // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ (Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€œ Ã Â¦Â¨Ã Â¦Â¾) Ã Â¦ÂÃ Â¦â€¡ Ã Â¦Â¬Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â§â€¡Ã Â¦Â° Ã Â¦Â­Ã Â§â€¡Ã Â¦Â¤Ã Â¦Â°Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â®Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â¿Ã Â¦â€¢/Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â·Ã Â¦Â¿Ã Â¦â€¢
  // Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¨ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â¦Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Å¡Ã Â§â€¡ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡ Ã Â¦Â°Ã Â¦Â¾Ã Â¦â€“Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿
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
                'Ã Â¦Â¸Ã Â¦Â¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿: ${s.memberId}',
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
                s.isPremiumActive
                    ? 'Ã Â¦Â¸Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨'
                    : 'Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²',
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
              tooltip: 'Ã Â¦ÂÃ Â¦Â¡Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®: ${s.profileName.isEmpty ? 'Ã¢â‚¬â€' : s.profileName}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 3),
        Text(
          'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“: ${s.profileDob == null ? 'Ã¢â‚¬â€' : '${s.profileDob!.day}/${s.profileDob!.month}/${s.profileDob!.year}'}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 3),
        Text(
          'Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾: ${s.profileAddress.isEmpty ? 'Ã¢â‚¬â€' : s.profileAddress}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        if (widget.showPlans) ...[
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 14),
          const Text(
            'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¨',
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
                          : 'Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨',
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
              'Backend Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¸Ã Â§â€¡Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿ Ã¢â‚¬â€ main.dart Ã Â¦ÂÃ Â¦Â° '
              'PaymentService.baseUrl Ã Â¦Â Laravel Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â­Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° URL '
              'Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â§Â Ã Â¦Â¹Ã Â¦Â¬Ã Â§â€¡Ã Â¥Â¤',
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
          'Ã Â¦Â¤Ã Â¦Â¥Ã Â§ÂÃ Â¦Â¯ Ã Â¦ÂÃ Â¦Â¡Ã Â¦Â¿Ã Â¦Å¸ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
            hintText: 'Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®',
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
              ? 'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦â€œ Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¨'
              : '${_dob!.day}/${_dob!.month}/${_dob!.year} Ã¢â‚¬â€ ${TimeOfDay.fromDateTime(_dob!).format(context)}',
          onChanged: (dt) => setState(() => _dob = dt),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _addressController,
          maxLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾',
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
                  'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â²',
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
                  'Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¬Ã Â¦Â¸Ã Â§ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¶Ã Â¦Â¨ Ã¢â‚¬â€ Razorpay checkout (Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â®Ã Â§â€¹Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â² app Ã Â¦Â, Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦Â¬Ã Â§â€¡
// razorpay_flutter Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Å“ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¬Ã Â¦Â²Ã Â§â€¡ Ã Â¦Â¸Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡ Ã Â¦Â¸Ã Â¦â€šÃ Â¦â€”Ã Â§ÂÃ Â¦Â°Ã Â¦Â¹Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¤Ã Â¦Â¾ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼)
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
    // Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦â€“Ã Â§â€¹Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¡ backend Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Â¸Ã Â¦Â¤Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Â° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¸
    // Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦â€¢Ã Â¦Â°Ã Â§â€¡ Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼ (Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¦ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¥Ã Â¦Â¾Ã Â¦â€¢Ã Â¦Â²Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â§Ã Â¦Â°Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Â¡Ã Â¦Â¼Ã Â¦Â¬Ã Â§â€¡)
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
        'name':
            'Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€šÃ Â¦Â²Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Å¾Ã Â§ÂÃ Â¦Å“Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾',
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
        const SnackBar(
          content: Text(
            'Ã°Å¸Å½â€° Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¸Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Å¡Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥: ${e.toString().replaceFirst('Exception: ', '')}',
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
        content: Text(
          'Ã Â¦ÂªÃ Â§â€¡Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â°Ã Â§ÂÃ Â¦Â¥ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡: ${response.message ?? ''}',
        ),
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
              const _ScreenHeader(
                title:
                    'Ã¢Å“Â¨ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â®',
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²/Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¯Ã Â§â€¡Ã Â¦Å¸Ã Â¦Â¾Ã Â¦â€¡ Ã Â¦Â¹Ã Â§â€¹Ã Â¦â€¢ Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨, Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿ Ã Â¦Å“Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â°Ã Â§â€¡Ã Â¦Å¸ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡
                    // Ã Â¦â€”Ã Â§â€¡Ã Â¦Â²Ã Â§â€¡Ã Â¦â€¡ Ã Â¦ÂÃ Â¦â€¡ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Â¡Ã Â§â€¡ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®/Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“/Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾/Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿ + Ã Â¦ÂÃ Â¦Â¡Ã Â¦Â¿Ã Â¦Å¸
                    // Ã Â¦â€¦Ã Â¦ÂªÃ Â¦Â¶Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¸Ã Â¦Â®Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€°Ã Â¦ÂªÃ Â¦Â°Ã Â§â€¡ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼
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
                              'Ã°Å¸Å½â€° Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¿ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¸Ã Â¦Â¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯',
                              style: TextStyle(
                                color: Color(0xFFFFD36E),
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            if (AppSettings.instance.premiumExpiry != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¦ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·: ${AppSettings.instance.premiumExpiry!.day}/${AppSettings.instance.premiumExpiry!.month}/${AppSettings.instance.premiumExpiry!.year}',
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
                          'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦â€¢Ã Â§â€¡Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¬Ã Â¦Â¿Ã Â¦Â§Ã Â¦Â¾ Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â§Ã Â§Â Ã Â¦Â®Ã Â§â€¹Ã Â¦Â¬Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â² Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦ÂªÃ Â§â€¡ '
                          'Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼ Ã¢â‚¬â€ Android/iOS Ã Â¦â€¦Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Âª Ã Â¦Â¥Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¡ Ã Â¦Å¡Ã Â§â€¡Ã Â¦Â·Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨Ã Â¥Â¤',
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
                              ? 'Ã°Å¸Å½Â Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Å¡Ã Â¦Â²Ã Â¦â€ºÃ Â§â€¡ Ã¢â‚¬â€ Ã Â¦â€ Ã Â¦Â° ${bnNum(s.trialDaysLeft)} Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â§â€šÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¨Ã Â¥Â¤'
                              : (s.trialActivated
                                    ? 'Ã°Å¸â€â€™ Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â§Â©Ã Â§Â¦ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â· Ã¢â‚¬â€ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸, PDF Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸, Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª Ã Â¦â€œ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â²Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦â€¢Ã Â¦Â¿Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¨Ã Â¥Â¤'
                                    : 'Ã°Å¸Å½Â Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸, PDF Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸, Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š Ã¢â‚¬â€ Ã Â¦Â¯Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€“Ã Â§ÂÃ Â¦Â²Ã Â¦Â²Ã Â§â€¡Ã Â¦â€¡ Ã Â§Â©Ã Â§Â¦ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â«Ã Â¦Â°Ã Â§ÂÃ Â¦Â® Ã Â¦â€ Ã Â¦Â¸Ã Â¦Â¬Ã Â§â€¡Ã Â¥Â¤'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const Text(
                        'Ã¢Å“Â¨ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â®Ã Â§â€¡ Ã Â¦Â¯Ã Â¦Â¾ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¨ Ã¢â‚¬â€ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦ÂªÃ Â¦Â²Ã Â§â€¡Ã Â¦â€¡ Ã Â¦â€“Ã Â§ÂÃ Â¦Â²Ã Â¦Â¬Ã Â§â€¡',
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
// Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â²
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
              const _ScreenHeader(
                title:
                    'Ã°Å¸â€˜Â¤ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â²',
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ------- Ã Â¦Â¸Ã Â¦Â¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯Ã Â¦ÂªÃ Â¦Â¦ Ã Â¦Â¸Ã Â§ÂÃ Â¦Å¸Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Å¸Ã Â¦Â¾Ã Â¦Â¸ (Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² / Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â®) -------
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
                                ? 'Ã¢Å“Â¨ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦Â¸Ã Â¦Â¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯'
                                : (s.inTrialPeriod
                                      ? 'Ã°Å¸Å½Â Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Å¡Ã Â¦Â²Ã Â¦â€ºÃ Â§â€¡'
                                      : (s.trialActivated
                                            ? 'Ã°Å¸â€â€™ Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·'
                                            : 'Ã°Å¸Å½Â Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨Ã Â§â€¹ Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¨Ã Â¦Â¿')),
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
                                  'Ã Â¦Â¸Ã Â¦Â¦Ã Â¦Â¸Ã Â§ÂÃ Â¦Â¯ Ã Â¦â€ Ã Â¦â€¡Ã Â¦Â¡Ã Â¦Â¿: ${s.memberId}',
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
                                        ? 'Ã Â¦Â¸Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨'
                                        : 'Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â²',
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
                                'Ã Â¦Â®Ã Â§â€¡Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â¦ Ã Â¦Â¶Ã Â§â€¡Ã Â¦Â·: ${s.premiumExpiry!.day}/${s.premiumExpiry!.month}/${s.premiumExpiry!.year}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
                          ] else if (s.inTrialPeriod)
                            Text(
                              'Ã Â¦â€ Ã Â¦Â° ${bnNum(s.trialDaysLeft)} Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨ Ã Â¦Â¸Ã Â¦Â¬ Ã Â¦Â«Ã Â¦Â¿Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â§â€šÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â§â€¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¬Ã Â¦Â¹Ã Â¦Â¾Ã Â¦Â° Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¨Ã Â¥Â¤',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            )
                          else if (s.trialActivated)
                            const Text(
                              'Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸, PDF Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸, Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª Ã Â¦â€œ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š Ã Â¦ÂÃ Â¦â€“Ã Â¦Â¨ Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â¸Ã Â¦Â¾Ã Â¦Â¥Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦â€œÃ Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾ Ã Â¦Â¯Ã Â¦Â¾Ã Â¦Â¬Ã Â§â€¡Ã Â¥Â¤',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            )
                          else
                            const Text(
                              'Ã Â¦â€¢Ã Â§ÂÃ Â¦Â·Ã Â§ÂÃ Â¦Â Ã Â¦Â¿ Ã Â¦Å¡Ã Â¦Â¾Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸, PDF Ã Â¦ÂÃ Â¦â€¢Ã Â§ÂÃ Â¦Â¸Ã Â¦ÂªÃ Â§â€¹Ã Â¦Â°Ã Â§ÂÃ Â¦Å¸, Ã Â¦â€¢Ã Â§ÂÃ Â¦Â²Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¡ Ã Â¦Â¬Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦â€¢Ã Â¦â€ Ã Â¦Âª Ã Â¦Â¬Ã Â¦Â¾ Ã Â¦Å“Ã Â§ÂÃ Â¦Â¯Ã Â§â€¹Ã Â¦Â¤Ã Â¦Â¿Ã Â¦Â·Ã Â§â‚¬ Ã Â¦Â¬Ã Â§ÂÃ Â¦â€¢Ã Â¦Â¿Ã Â¦â€š Ã¢â‚¬â€ Ã Â¦Â¯Ã Â§â€¡Ã Â¦â€¢Ã Â§â€¹Ã Â¦Â¨Ã Â§â€¹ Ã Â¦ÂÃ Â¦â€¢Ã Â¦Å¸Ã Â¦Â¾ Ã Â¦â€“Ã Â§ÂÃ Â¦Â²Ã Â¦Â²Ã Â§â€¡Ã Â¦â€¡ Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®/Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“/Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡ Ã Â§Â©Ã Â§Â¦ Ã Â¦Â¦Ã Â¦Â¿Ã Â¦Â¨Ã Â§â€¡Ã Â¦Â° Ã Â¦Â«Ã Â§ÂÃ Â¦Â°Ã Â¦Â¿ Ã Â¦Å¸Ã Â§ÂÃ Â¦Â°Ã Â¦Â¾Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â² Ã Â¦Â¶Ã Â§ÂÃ Â¦Â°Ã Â§Â Ã Â¦â€¢Ã Â¦Â°Ã Â¦Â¤Ã Â§â€¡ Ã Â¦ÂªÃ Â¦Â¾Ã Â¦Â°Ã Â¦Â¬Ã Â§â€¡Ã Â¦Â¨Ã Â¥Â¤',
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
                                  'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â¦Â¿Ã Â¦Â®Ã Â¦Â¿Ã Â¦Â¯Ã Â¦Â¼Ã Â¦Â¾Ã Â¦Â® Ã Â¦ÂªÃ Â§ÂÃ Â¦Â²Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â¨ Ã Â¦Â¦Ã Â§â€¡Ã Â¦â€“Ã Â§ÂÃ Â¦Â¨',
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
                      'Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®',
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
                      'Ã Â¦Â¶Ã Â¦Â¹Ã Â¦Â°',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cityController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Ã Â¦Â¯Ã Â§â€¡Ã Â¦Â®Ã Â¦Â¨: Ã Â¦â€¢Ã Â¦Â²Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¤Ã Â¦Â¾',
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
                      'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“',
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
                              ? 'Ã Â¦Å“Ã Â¦Â¨Ã Â§ÂÃ Â¦Â® Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â°Ã Â¦Â¿Ã Â¦â€“ Ã Â¦Â¬Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡ Ã Â¦Â¨Ã Â¦Â¿Ã Â¦Â¨'
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
                      'Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'Ã Â¦â€ Ã Â¦ÂªÃ Â¦Â¨Ã Â¦Â¾Ã Â¦Â° Ã Â¦Â Ã Â¦Â¿Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¨Ã Â¦Â¾',
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
                              content: Text(
                                'Ã Â¦ÂªÃ Â§ÂÃ Â¦Â°Ã Â§â€¹Ã Â¦Â«Ã Â¦Â¾Ã Â¦â€¡Ã Â¦Â² Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦Â¹Ã Â¦Â¯Ã Â¦Â¼Ã Â§â€¡Ã Â¦â€ºÃ Â§â€¡',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD36E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Ã Â¦Â¸Ã Â§â€¡Ã Â¦Â­ Ã Â¦â€¢Ã Â¦Â°Ã Â§ÂÃ Â¦Â¨',
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
