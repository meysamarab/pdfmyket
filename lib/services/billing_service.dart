import 'package:flutter_poolakey/flutter_poolakey.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class BillingService {
  // RSA Public Key from Bazaar Panel.
  static const String _rsaKey = 'MIHNMA0GCSqGSIb3DQEBAQUAA4G7ADCBtwKBywCWpYyS/mJ9...'; 
  static const String premiumId = 'annual_sub_pdf';
  static const String _premiumCacheKey = 'is_premium';

  /// Connect to Bazaar service
  static Future<bool> init() async {
    try {
      return await FlutterPoolakey.connect(_rsaKey);
    } catch (e) {
      debugPrint("Poolakey Connection Failed: $e");
      return false;
    }
  }

  /// Check if user is premium (checks cache first, then Bazaar API)
  static Future<bool> checkPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Check local cache for offline support
    if (prefs.getBool(_premiumCacheKey) ?? false) return true;

    try {
      // 2. Verify with Bazaar API
      // getAllPurchasedProducts returns both one-time purchases and active subscriptions
      final purchases = await FlutterPoolakey.getAllPurchasedProducts();
      bool active = purchases.any((p) => p.productId == premiumId);
      
      // 3. Update cache
      await prefs.setBool(_premiumCacheKey, active);
      return active;
    } catch (e) {
      debugPrint("Error checking purchases: $e");
      return false;
    }
  }

  /// Launch Subscription Flow
  static Future<bool> purchaseSubscription() async {
    try {
      final result = await FlutterPoolakey.subscribe(premiumId);
      if (result.productId == premiumId) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_premiumCacheKey, true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Subscription Purchase Failed: $e");
      return false;
    }
  }
}
