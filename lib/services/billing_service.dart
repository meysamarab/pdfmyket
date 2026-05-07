import 'package:flutter_poolakey/flutter_poolakey.dart';
import 'package:flutter/foundation.dart';

class BillingService {
  // Placeholder RSA Key. User must replace this from Cafe Bazaar panel.
  static const String _rsaKey = 'MIHNMA0GCSqGSIb3DQEBAQUAA4G7ADCBtwKBywCWpYyS/mJ9...'; 
  static const String annualSubscriptionId = 'annual_sub_pdf';

  static Future<bool> init() async {
    try {
      await FlutterPoolakey.connect(
        _rsaKey,
        onSucceed: () => debugPrint('Poolakey: Connected'),
        onFailed: (e) => debugPrint('Poolakey: Connection Failed - $e'),
        onDisconnected: () => debugPrint('Poolakey: Disconnected'),
      );
      return true;
    } catch (e) {
      debugPrint('Poolakey Connect Error: $e');
      return false;
    }
  }

  /// Check if user has an active annual subscription
  static Future<bool> checkSubscriptionStatus() async {
    try {
      final subscriptions = await FlutterPoolakey.getAllSubscribedProducts();
      return subscriptions.any((p) => p.productId == annualSubscriptionId);
    } catch (e) {
      debugPrint('Check Subscription Error: $e');
      return false;
    }
  }

  /// Start the subscription process
  static Future<bool> purchaseSubscription() async {
    try {
      final purchaseInfo = await FlutterPoolakey.subscribe(
        annualSubscriptionId,
      );
      return purchaseInfo.productId == annualSubscriptionId;
    } catch (e) {
      debugPrint('Purchase Error: $e');
      return false;
    }
  }
}
