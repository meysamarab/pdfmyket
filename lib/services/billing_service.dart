import 'package:flutter_poolakey/flutter_poolakey.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class BillingService {
  static const String _rsaKey =
      'MIHNMA0GCSqGSIb3DQEBAQUAA4G7ADCBtwKBrwCwF6NWqIntwMW0zqFtXmJEg3brmPutlValzeQLYn1PKf1v3gVY/knsHMlCVzA1a7pS2okclSzbpeq+svD5YFNGovqmkOhU9QrbCOUBNv/Qjj4xssBpFKTYCyO4qiBrpiRHkRa5ifF/m5gfxV4qmu+3lQo1mq+jqcCYPWRVIKguV+Hrhg9n9CPEKQm+qC4jrvdaQvth7xZQcfmJfma627vC2CNhlVzocsV/TJbiyvkCAwEAAQ==';
  static const String productId = 'ccpooli';
  static const String premiumCacheKey = 'is_premium';

  /// Connect to Bazaar service
  static Future<bool> init() async {
    try {
      await FlutterPoolakey.connect(_rsaKey);
      return true;
    } catch (e) {
      debugPrint('Poolakey Connection Failed: $e');
      return false;
    }
  }

  /// Check if user has purchased the product (cache-first approach)
  static Future<bool> checkPurchaseStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Check local cache first for immediate and offline support
    bool isCached = prefs.getBool(premiumCacheKey) ?? false;
    if (isCached) return true;

    try {
      // 2. Verify with Bazaar API - one-time purchase
      // We only do this if cache is false
      final purchases = await FlutterPoolakey.getAllPurchasedProducts();
      bool active = purchases.any((p) => p.productId == productId);

      // 3. Update cache only if we found a purchase
      if (active) {
        await prefs.setBool(premiumCacheKey, true);
      }
      return active;
    } catch (e) {
      debugPrint('Error checking purchases: $e');
      // If error occurs and we have no cache, we return false
      // but we don't overwrite any potential existing cache
      return isCached;
    }
  }

  /// Launch one-time purchase flow
  static Future<bool> purchase() async {
    try {
      final result = await FlutterPoolakey.purchase(productId);
      if (result.productId == productId) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(premiumCacheKey, true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Purchase Failed: $e');
      return false;
    }
  }
}
