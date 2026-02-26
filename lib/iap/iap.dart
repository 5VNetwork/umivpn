import 'package:in_app_purchase/in_app_purchase.dart';

// Gives the option to override in tests.
class IAPConnection {
  static InAppPurchase? _instance;
  static set instance(InAppPurchase value) {
    _instance = value;
  }

  static InAppPurchase get instance {
    _instance ??= InAppPurchase.instance;
    return _instance!;
  }
}

class ProductData {
  final String productId;
  final ProductType type;

  const ProductData(this.productId, this.type);
}

enum ProductType { subscription, upgrade, consume }

const androidProductData = <ProductData>[
  ProductData('umivpn_air', ProductType.subscription),
  ProductData('umivpn_pro', ProductType.subscription),
];

const iosProductData = <ProductData>[
  ProductData('umivpn_air_year', ProductType.subscription),
  ProductData('umivpn_pro_month', ProductType.subscription),
  ProductData('umivpn_pro_year', ProductType.subscription),
];
