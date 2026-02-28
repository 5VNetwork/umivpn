import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart'; // Add this import
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umivpn/common/common.dart';
import 'package:http/http.dart' as http;
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/utils/logger.dart';
import 'package:flutter_common/auth/auth_provider.dart';

import './iap.dart';

enum StoreState { loading, available, notAvailable }

class ProPurchases extends ChangeNotifier {
  StoreState storeState = StoreState.loading;
  bool buying = false;

  /// latest purchase detail
  PurchaseDetails? purchaseDetails;

  /// error message when purchaseDetail status is purchased/restored but verification failed
  String? verifyErrorMessage;

  bool _shouldReverifyWhenLoggedIn = false;

  late StreamSubscription<List<PurchaseDetails>> _subscription; // Add this line
  late StreamSubscription<Session?> _userSubscription;
  List<PurchasableProduct> products = [];
  final iapConnection = IAPConnection.instance;
  final AuthProvider authProvider;

  Future<void> loadPurchases(List<ProductData> productDatas) async {
    try {
      final available = await iapConnection.isAvailable();
      if (!available) {
        storeState = StoreState.notAvailable;
        notifyListeners();
        return;
      }

      final response = await iapConnection
          .queryProductDetails(productDatas.map((e) => e.productId).toSet());
      products = response.productDetails
          .map((e) => PurchasableProduct(
              e,
              productDatas
                  .firstWhere((element) => element.productId == e.id)
                  .type))
          .toList();
      logger.d('response.productDetails:');
      inspect(response.productDetails);
      storeState = StoreState.available;
      notifyListeners();
      // await restore();
    } catch (e) {
      storeState = StoreState.notAvailable;
      notifyListeners();
      reportError('IAP loadPurchases error', e);
    }
  }

  ProPurchases(List<ProductData> productDatas, this.authProvider) {
    _userSubscription = authProvider.sessionStreams.listen((session) async {
      if (session != null &&
          _shouldReverifyWhenLoggedIn &&
          purchaseDetails != null) {
        _shouldReverifyWhenLoggedIn = false;
        await _verifyAndFulfill(purchaseDetails!);
      }
    });
    final purchaseUpdated = iapConnection.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );
    loadPurchases(productDatas);
  }

  Future<void> _onPurchaseUpdate(
      List<PurchaseDetails> purchaseDetailsList) async {
    logger.d('_onPurchaseUpdate: $purchaseDetailsList');
    for (var purchaseDetails in purchaseDetailsList) {
      try {
        this.purchaseDetails = purchaseDetails;
        await _handlePurchase(purchaseDetails);
      } catch (e) {
        logger.e(e);
        reportError('IAP _handlePurchase error', e);
      }
    }
    notifyListeners();
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    logger.d('purchaseDetails inspect:');
    inspect(purchaseDetails);
    logger.d(
        'purchaseDetails: status: ${purchaseDetails.status}, orderId: ${purchaseDetails.purchaseID}, verificationData: ${purchaseDetails.verificationData.serverVerificationData}');
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      if (!purchaseDetails.pendingCompletePurchase) {
        logger.w('purchaseDetails is not pending complete purchase');
        return;
      }
      await _verifyAndFulfill(purchaseDetails);
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      if (purchaseDetails.pendingCompletePurchase) {
        await iapConnection.completePurchase(purchaseDetails);
      }
      buying = false;
      notifyListeners();
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      reportError('purchaseDetails error', purchaseDetails.error);
      buying = false;
      notifyListeners();
    } else if (purchaseDetails.status == PurchaseStatus.pending) {
      if (purchaseDetails.pendingCompletePurchase) {
        await iapConnection.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> reverify() async {
    await _verifyAndFulfill(purchaseDetails!);
  }

  Future<void> restore() async {
    await iapConnection.restorePurchases();
  }

  /// Complete _buyCompleter
  Future<void> _verifyAndFulfill(PurchaseDetails purchaseDetails) async {
    if (!buying) {
      buying = true;
      notifyListeners();
    }

    logger.d('verifying: ${purchaseDetails.status}');
    final userId = authProvider.currentSession?.user.id;
    if (userId == null) {
      _shouldReverifyWhenLoggedIn = true;
      return;
    }
    // Send to server
    try {
      final response = await supabase.functions.invoke(
        'iap',
        body: {
          'source': purchaseDetails.verificationData.source,
          'productId': purchaseDetails.productID,
          'verificationData':
              purchaseDetails.verificationData.serverVerificationData,
          'userId': userId,
          'transactionId': purchaseDetails.purchaseID,
        },
        headers: {
          'Authorization': 'Bearer ${authProvider.currentSession?.accessToken}',
        },
      );
      if (response.status == 200) {
        if (response.data == 'valid and fulfilled') {
          logger.d('verify success');
          if (purchaseDetails.pendingCompletePurchase) {
            logger.d('completing purchase');
            await iapConnection.completePurchase(purchaseDetails);
          }
          verifyErrorMessage = null;
          buying = false;
          notifyListeners();
          return;
        } else {
          logger.e('invalidPurchase: ${purchaseDetails.status}');
          reportError(
              'invalidPurchase ${purchaseDetails.toString()}', '无法验证购买');
          throw 'Invalid Purchase';
        }
      } else if (response.status == 500) {
        throw Exception('internal server error');
      } else {
        throw Exception('server returned ${response.status}');
      }
    } catch (e) {
      logger.e("_verifyAndFulfill error", error: e);
      reportError('IAP _verifyAndFulfill error', e);
      verifyErrorMessage = e.toString();
      buying = false;
      notifyListeners();
    }
  }

  void _updateStreamOnDone() {
    _subscription.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    //Handle error here
    logger.e(error);
    reportError('IAP updateStreamOnError', error);
  }

  @override
  void dispose() {
    _subscription.cancel();
    _userSubscription.cancel();
    super.dispose();
  }

  Future<void> buy(PurchaseParam purchaseParam) async {
    buying = true;
    notifyListeners();
    try {
      await iapConnection.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      logger.e(e);
      if (e is PlatformException &&
          (e.message?.contains('cancelled') ?? false)) {
        return;
      }
      rethrow;
    }
  }
}

enum ProductStatus {
  purchasable,
  purchased,
  pending,
}

class PurchasableProduct {
  String get id => productDetails.id;
  String get title => productDetails.title;
  String get description => productDetails.description;
  String get price => productDetails.price;
  ProductStatus status;
  ProductDetails productDetails;
  ProductType type;

  PurchasableProduct(this.productDetails, this.type)
      : status = ProductStatus.purchasable;
}

class VerifyFailedException implements Exception {
  final String message;
  VerifyFailedException(this.message);

  String toLocalString(BuildContext context) {
    if (message.contains('userId is null')) {
      return AppLocalizations.of(context)!.pleaseLoginFirst;
    }
    if (message.contains('internal server error')) {
      return AppLocalizations.of(context)!.serverError;
    }
    return message;
  }
}
