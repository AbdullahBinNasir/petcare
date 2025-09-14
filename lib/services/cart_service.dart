import 'package:flutter/foundation.dart';
import '../models/store_item_model.dart';
import '../models/order_model.dart';

class CartItem {
  final StoreItemModel item;
  int quantity;

  CartItem({
    required this.item,
    this.quantity = 1,
  });

  double get totalPrice => item.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'itemId': item.id,
      'itemName': item.name,
      'itemImage': item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
      'price': item.price,
      'quantity': quantity,
      'category': item.category.toString().split('.').last,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map, StoreItemModel item) {
    return CartItem(
      item: item,
      quantity: map['quantity'] ?? 1,
    );
  }
}

class CartService extends ChangeNotifier {
  final List<CartItem> _cartItems = [];
  static const double _taxRate = 0.08; // 8% tax
  static const double _shippingRate = 5.99; // Fixed shipping cost

  List<CartItem> get cartItems => _cartItems;
  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get tax => subtotal * _taxRate;
  double get shipping => _cartItems.isNotEmpty ? _shippingRate : 0.0;
  double get total => subtotal + tax + shipping;
  bool get isEmpty => _cartItems.isEmpty;

  // Add item to cart
  void addToCart(StoreItemModel item, {int quantity = 1}) {
    final existingIndex = _cartItems.indexWhere((cartItem) => cartItem.item.id == item.id);
    
    if (existingIndex != -1) {
      _cartItems[existingIndex].quantity += quantity;
    } else {
      _cartItems.add(CartItem(item: item, quantity: quantity));
    }
    
    notifyListeners();
    debugPrint('Added ${item.name} to cart. Total items: $itemCount');
  }

  // Remove item from cart
  void removeFromCart(String itemId) {
    _cartItems.removeWhere((cartItem) => cartItem.item.id == itemId);
    notifyListeners();
    debugPrint('Removed item $itemId from cart. Total items: $itemCount');
  }

  // Update item quantity
  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(itemId);
      return;
    }

    final existingIndex = _cartItems.indexWhere((cartItem) => cartItem.item.id == itemId);
    if (existingIndex != -1) {
      _cartItems[existingIndex].quantity = quantity;
      notifyListeners();
    }
  }

  // Clear cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
    debugPrint('Cart cleared');
  }

  // Check if item is in cart
  bool isInCart(String itemId) {
    return _cartItems.any((cartItem) => cartItem.item.id == itemId);
  }

  // Get quantity of item in cart
  int getItemQuantity(String itemId) {
    final cartItem = _cartItems.firstWhere(
      (cartItem) => cartItem.item.id == itemId,
      orElse: () => CartItem(item: StoreItemModel(
        id: '',
        name: '',
        description: '',
        price: 0,
        category: StoreCategory.other,
        brand: '',
        externalUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )),
    );
    return cartItem.quantity;
  }

  // Convert cart to order items
  List<OrderItemModel> toOrderItems() {
    return _cartItems.map((cartItem) => OrderItemModel(
      itemId: cartItem.item.id,
      itemName: cartItem.item.name,
      itemImage: cartItem.item.imageUrls.isNotEmpty ? cartItem.item.imageUrls.first : '',
      price: cartItem.item.price,
      quantity: cartItem.quantity,
      category: cartItem.item.category.toString().split('.').last,
    )).toList();
  }

  // Get cart summary
  Map<String, dynamic> getCartSummary() {
    return {
      'itemCount': itemCount,
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'total': total,
      'items': _cartItems.map((item) => item.toMap()).toList(),
    };
  }
}
