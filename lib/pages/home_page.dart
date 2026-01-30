import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:mingming/game/mingming_game.dart';
import 'package:mingming/pages/paywall_page.dart';
import 'package:mingming/utils/constants.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late MingmingGame _game;
  Timer? _timer;

  DateTime? _nextFeedTime;
  int _feedsUsedToday = 0;

  int _maxFeedsPerDay = 1;
  Duration _cooldownDuration = const Duration(hours: 24);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _game = MingmingGame();
    _loadFeedingData();
    _applyEntitlements();

    // Listen for subscription changes
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      debugPrint('Customer info updated');
      _applyEntitlements();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh entitlements when app comes to foreground
      _applyEntitlements();
    }
  }

  // -------------------------
  // Entitlements
  // -------------------------

  Future<void> _applyEntitlements() async {
    try {
      final info = await Purchases.getCustomerInfo();

      debugPrint('Active entitlements: ${info.entitlements.active.keys}');

      // Check for active entitlements - match your RevenueCat entitlement identifiers
      if (info.entitlements.active.containsKey('premium_caretaker')) {
        _maxFeedsPerDay = 12;
        _cooldownDuration = const Duration(hours: 2);
        debugPrint('Applied premium tier');
      } else if (info.entitlements.active.containsKey('basic_caretaker')) {
        _maxFeedsPerDay = 3;
        _cooldownDuration = const Duration(hours: 8);
        debugPrint('Applied basic tier');
      } else {
        // Free tier
        _maxFeedsPerDay = 1;
        _cooldownDuration = const Duration(hours: 24);
        debugPrint('Applied free tier');
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Entitlement check failed: $e');
    }
  }

  // -------------------------
  // Persistence
  // -------------------------

  Future<void> _loadFeedingData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedDate = prefs.getString('lastFeedDate');
    final today = DateTime.now().toString().substring(0, 10);

    if (savedDate != today) {
      // New day - reset feeds
      _feedsUsedToday = 0;
      await prefs.setInt('feedsUsedToday', 0);
      await prefs.setString('lastFeedDate', today);
      await prefs.remove('nextFeedTime'); // Clear cooldown on new day
      _nextFeedTime = null;
    } else {
      _feedsUsedToday = prefs.getInt('feedsUsedToday') ?? 0;

      final nextFeedMs = prefs.getInt('nextFeedTime');
      if (nextFeedMs != null) {
        _nextFeedTime = DateTime.fromMillisecondsSinceEpoch(nextFeedMs);
      }
    }

    if (mounted) setState(() {});
  }

  // -------------------------
  // Feeding logic
  // -------------------------

  bool get _canFeedNow {
    if (_feedsUsedToday >= _maxFeedsPerDay) return false;
    if (_nextFeedTime == null) return true;
    return DateTime.now().isAfter(_nextFeedTime!);
  }

  double get _timerProgress {
    if (_nextFeedTime == null || _canFeedNow) return 1.0;

    final now = DateTime.now();
    final startTime = _nextFeedTime!.subtract(_cooldownDuration);
    final elapsed = now.difference(startTime);

    return (elapsed.inSeconds / _cooldownDuration.inSeconds).clamp(0.0, 1.0);
  }

  String get _timeRemaining {
    if (_nextFeedTime == null || _canFeedNow) return "Ready!";

    final remaining = _nextFeedTime!.difference(DateTime.now());
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);

    if (h > 0) return "${h}h ${m}m";
    if (m > 0) return "${m}m ${s}s";
    return "${s}s";
  }

  String get _catStatusText {
    if (_game.isEating) return "NOM NOM!";
    if (_game.isHappy) return "BELLY FULL";
    return "I'M HUNGRY!";
  }

  Future<void> _handleFeed() async {
    if (!_canFeedNow) return;

    // Pass the cooldown duration as hunger duration to sync with subscription tier
    await _game.feed(hungerDuration: _cooldownDuration);

    setState(() {
      _feedsUsedToday++;
      _nextFeedTime = DateTime.now().add(_cooldownDuration);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('feedsUsedToday', _feedsUsedToday);
    await prefs.setInt('nextFeedTime', _nextFeedTime!.millisecondsSinceEpoch);
    await prefs.setString(
      'lastFeedDate',
      DateTime.now().toString().substring(0, 10),
    );
  }

  // -------------------------
  // UI
  // -------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const PaywallPage()),
                    );

                    // Refresh entitlements after returning from paywall
                    if (result == true && mounted) {
                      await _applyEntitlements();
                    }
                  },
                  child: Image.asset(
                    'assets/images/sprites/catfood.png',
                    width: 32,
                  ),
                ),
              ),
            ),

            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 128,
                    height: 128,
                    child: GameWidget(game: _game),
                  ),
                  const SizedBox(height: 12),
                  Text(_catStatusText, style: kPixelifyTitleMedium),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_feedsUsedToday/$_maxFeedsPerDay',
                    style: kPixelifyTitleMedium.copyWith(fontSize: 18),
                  ),
                  Text(
                    _timeRemaining,
                    style: kPixelifyTitleMedium.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              height: 12,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _timerProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    _canFeedNow ? Colors.green : kSecondary,
                  ),
                ),
              ),
            ),

            GestureDetector(
              onTap: _handleFeed,
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                height: 64,
                decoration: BoxDecoration(
                  color: _canFeedNow ? kSecondary : kSecondary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _canFeedNow ? 'FEED' : 'WAIT...',
                    style: kPixelifyHeadlineSmall,
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