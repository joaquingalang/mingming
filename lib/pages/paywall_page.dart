import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mingming/utils/constants.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  int _selectedTier = 0; // 0 = Free, 1 = Basic, 2 = Premium
  bool _loading = true;
  bool _purchasing = false;

  Package? _basicPackage;
  Package? _premiumPackage;

  final List<Map<String, dynamic>> _tiers = [
    {
      'name': 'Free Caretaker',
      'feeds': 1,
      'cooldown': '24 hours',
    },
    {
      'name': 'Basic Caretaker',
      'feeds': 3,
      'cooldown': '8 hours',
    },
    {
      'name': 'Premium Caretaker',
      'feeds': 12,
      'cooldown': '2 hours',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;

      if (offering != null) {
        for (final package in offering.availablePackages) {
          // Match your RevenueCat package identifiers
          if (package.identifier.contains('basic')) {
            _basicPackage = package;
          } else if (package.identifier.contains('premium')) {
            _premiumPackage = package;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load offerings: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _purchasePackage(Package package) async {
    setState(() => _purchasing = true);

    try {
      final purchaseResult = await Purchases.purchasePackage(package);

      // Access customerInfo from the purchase result
      final customerInfo = purchaseResult.customerInfo;

      // Check if purchase was successful
      if (customerInfo.entitlements.active.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Subscription successful!',
                style: kPixelifyTitleMedium,
              ),
              backgroundColor: kSecondary,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate purchase
        }
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Purchase failed: ${e.message}',
                style: kPixelifyTitleMedium,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Unexpected purchase error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'An error occurred',
              style: kPixelifyTitleMedium,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _purchasing = false);
      }
    }
  }

  Future<void> _handleContinue() async {
    if (_purchasing) return;

    if (_selectedTier == 1) {
      if (_basicPackage != null) {
        await _purchasePackage(_basicPackage!);
      } else {
        _showPackageUnavailable();
      }
    } else if (_selectedTier == 2) {
      if (_premiumPackage != null) {
        await _purchasePackage(_premiumPackage!);
      } else {
        _showPackageUnavailable();
      }
    } else {
      // Free tier - just go back
      if (mounted) {
        Navigator.pop(context, false);
      }
    }
  }

  void _showPackageUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'This package is not available',
          style: kPixelifyTitleMedium,
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _priceForTier(int index) {
    switch (index) {
      case 0:
        return 'Free';
      case 1:
        return _basicPackage?.storeProduct.priceString ?? 'Loading...';
      case 2:
        return _premiumPackage?.storeProduct.priceString ?? 'Loading...';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      body: SafeArea(
        child: _loading
            ? const Center(
          child: CircularProgressIndicator(color: kSecondary),
        )
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'CHOOSE YOUR',
                    style: kPixelifyTitleMedium.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CARETAKER TIER',
                    style: kPixelifyHeadlineSmall.copyWith(
                      color: kSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _tiers.length,
                itemBuilder: (context, index) {
                  final tier = _tiers[index];
                  final isSelected = _selectedTier == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedTier = index);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? kSecondary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kSecondary, width: 3),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tier['name'],
                                style: kPixelifyTitleMedium.copyWith(
                                  fontSize: 18,
                                  color: isSelected
                                      ? kPrimary
                                      : Colors.white,
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: kPrimary,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${tier['feeds']} feed${tier['feeds'] > 1 ? 's' : ''} per day',
                            style: kPixelifyTitleMedium.copyWith(
                              fontSize: 14,
                              color:
                              isSelected ? kPrimary : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cooldown: ${tier['cooldown']}',
                            style: kPixelifyTitleMedium.copyWith(
                              fontSize: 14,
                              color:
                              isSelected ? kPrimary : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _priceForTier(index),
                            style: kPixelifyHeadlineSmall.copyWith(
                              fontSize: 20,
                              color: isSelected ? kPrimary : kSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            GestureDetector(
              onTap: _purchasing ? null : _handleContinue,
              child: Container(
                margin: const EdgeInsets.all(24),
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  color: _purchasing
                      ? kSecondary.withOpacity(0.5)
                      : kSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _purchasing
                      ? const CircularProgressIndicator(
                    color: kPrimary,
                  )
                      : Text(
                    _selectedTier == 0 ? 'CONTINUE' : 'SUBSCRIBE',
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