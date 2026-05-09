import 'package:myket_iap/myket_iap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class BillingService {
  static const String _rsaKey =
      'MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDbXHYP5GNWBHsqE+OfhoYSLP4E1QhivbC+sbuP6iqodRD6NI3Tt1jQRZ2Fc1SwIhBVI4/fpmwW0c1GB8MtvEU3BWZGvV73vcjkpmL27HccCR4ChyCyPcPo6TJJWhHC9VP4mX+TjcoKMCHlh9ELFokKTUM3bYwQmk3NA69l4BJWiQIDAQAB';
  static const String productId = 'ccpoooli';
  static const String premiumCacheKey = 'is_premium';

  /// Connect to Myket service
  static Future<bool> init() async {
    try {
      final result = await MyketIAP.init(rsaKey: _rsaKey);
      return result?.isSuccess() ?? false;
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
      final IabResult? iabResult = result[MyketIAP.RESULT];
      
      if (iabResult != null && iabResult.isSuccess()) {
        final Inventory? inventory = result[MyketIAP.INVENTORY];
        bool active = inventory?.hasPurchase(productId) ?? false;

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
      final IabResult? iabResult = result[MyketIAP.RESULT];
      final Purchase? purchase = result[MyketIAP.PURCHASE];

      if (iabResult != null && iabResult.isSuccess() && purchase != null && purchase.sku == productId) {
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
