import 'package:myket_iap/myket_iap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class BillingService {
  static const String _rsaKey =
      'MIHNMA0GCSqGSIb3DQEBAQUAA4G7ADCBtwKBrwCwF6NWqIntwMW0zqFtXmJEg3brmPutlValzeQLYn1PKf1v3gVY/knsHMlCVzA1a7pS2okclSzbpeq+svD5YFNGovqmkOhU9QrbCOUBNv/Qjj4xssBpFKTYCyO4qiBrpiRHkRa5ifF/m5gfxV4qmu+3lQo1mq+jqcCYPWRVIKguV+Hrhg9n9CPEKQm+qC4jrvdaQvth7xZQcfmJfma627vC2CNhlVzocsV/TJbiyvkCAwEAAQ==';
  static const String productId = 'ccpooli';
  static const String premiumCacheKey = 'is_premium';

  /// Connect to Myket service
  static Future<bool> init() async {
    try {
      final result = await MyketIAP.init(rsaKey: _rsaKey);
      return result.isSuccess();
    } catch (e) {
      debugPrint('Myket Connection Failed: $e');
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
      // 2. Verify with Myket API - query inventory
      final result = await MyketIAP.queryInventory(querySkuDetails: true);
      final IabResult iabResult = result[MyketIAP.RESULT];
      
      if (iabResult.isSuccess()) {
        final Inventory inventory = result[MyketIAP.INVENTORY];
        bool active = inventory.hasPurchase(productId);

        // 3. Update cache only if we found a purchase
        if (active) {
          await prefs.setBool(premiumCacheKey, true);
        }
        return active;
      }
      return isCached;
    } catch (e) {
      debugPrint('Error checking purchases: $e');
      return isCached;
    }
  }

  /// Launch purchase flow
  static Future<bool> purchase() async {
    try {
      final result = await MyketIAP.launchPurchaseFlow(sku: productId);
      final IabResult iabResult = result[MyketIAP.RESULT];
      final Purchase? purchase = result[MyketIAP.PURCHASE];

      if (iabResult.isSuccess() && purchase != null && purchase.sku == productId) {
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
