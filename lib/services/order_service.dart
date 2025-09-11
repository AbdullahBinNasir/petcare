import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';

class OrderService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<OrderModel> _orders = [];
  List<OrderModel> _userOrders = [];
  bool _isLoading = false;
  String _searchQuery = '';
  OrderStatus? _selectedStatus;

  List<OrderModel> get orders => _orders;
  List<OrderModel> get userOrders => _userOrders;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  OrderStatus? get selectedStatus => _selectedStatus;

  // Load all orders (for admin/vet)
  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      _orders = querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      debugPrint('Loaded ${_orders.length} orders');
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load orders for specific user
  Future<void> loadUserOrders(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _userOrders = querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      debugPrint('Loaded ${_userOrders.length} orders for user $userId');
    } catch (e) {
      debugPrint('Error loading user orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new order
  Future<String> createOrder(OrderModel order) async {
    try {
      debugPrint('Converting order to Firestore format...');
      final orderData = order.toFirestore();
      debugPrint('Order data: $orderData');
      
      debugPrint('Adding order to Firestore...');
      final docRef = await _firestore.collection('orders').add(orderData);
      debugPrint('Order added to Firestore with ID: ${docRef.id}');
      
      // Add initial status to history
      debugPrint('Adding status history...');
      await _firestore.collection('orders').doc(docRef.id).update({
        'statusHistory': {
          '${DateTime.now().millisecondsSinceEpoch}': {
            'status': order.status.toString().split('.').last,
            'timestamp': Timestamp.fromDate(DateTime.now()),
            'note': 'Order created',
          }
        }
      });

      debugPrint('Order created successfully with ID: ${docRef.id}');
      await loadOrders(); // Refresh orders list
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating order: $e');
      debugPrint('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus, {String? note}) async {
    try {
      final now = DateTime.now();
      final statusHistory = {
        '${now.millisecondsSinceEpoch}': {
          'status': newStatus.toString().split('.').last,
          'timestamp': Timestamp.fromDate(now),
          'note': note ?? 'Status updated to ${newStatus.toString().split('.').last}',
        }
      };

      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(now),
        'statusHistory': FieldValue.arrayUnion([statusHistory]),
      });

      debugPrint('Order $orderId status updated to $newStatus');
      await loadOrders(); // Refresh orders list
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(String orderId, PaymentStatus newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'paymentStatus': newStatus.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('Order $orderId payment status updated to $newStatus');
      await loadOrders(); // Refresh orders list
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      rethrow;
    }
  }

  // Add tracking number
  Future<void> addTrackingNumber(String orderId, String trackingNumber, {String? estimatedDelivery}) async {
    try {
      final updates = {
        'trackingNumber': trackingNumber,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (estimatedDelivery != null) {
        updates['estimatedDelivery'] = estimatedDelivery;
      }

      await _firestore.collection('orders').doc(orderId).update(updates);

      debugPrint('Tracking number added to order $orderId: $trackingNumber');
      await loadOrders(); // Refresh orders list
    } catch (e) {
      debugPrint('Error adding tracking number: $e');
      rethrow;
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting order by ID: $e');
      return null;
    }
  }

  // Search orders
  void searchOrders(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  // Filter by status
  void filterByStatus(OrderStatus? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  // Get filtered orders
  List<OrderModel> get filteredOrders {
    List<OrderModel> filtered = List.from(_orders);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        return order.id.toLowerCase().contains(_searchQuery) ||
               order.userName.toLowerCase().contains(_searchQuery) ||
               order.userEmail.toLowerCase().contains(_searchQuery) ||
               order.trackingNumber?.toLowerCase().contains(_searchQuery) == true;
      }).toList();
    }

    // Apply status filter
    if (_selectedStatus != null) {
      filtered = filtered.where((order) => order.status == _selectedStatus).toList();
    }

    return filtered;
  }

  // Get filtered user orders
  List<OrderModel> get filteredUserOrders {
    List<OrderModel> filtered = List.from(_userOrders);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        return order.id.toLowerCase().contains(_searchQuery) ||
               order.trackingNumber?.toLowerCase().contains(_searchQuery) == true;
      }).toList();
    }

    // Apply status filter
    if (_selectedStatus != null) {
      filtered = filtered.where((order) => order.status == _selectedStatus).toList();
    }

    return filtered;
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _selectedStatus = null;
    notifyListeners();
  }

  // Get order statistics
  Map<String, int> getOrderStatistics() {
    final stats = <String, int>{};
    
    for (final status in OrderStatus.values) {
      stats[status.toString().split('.').last] = 
          _orders.where((order) => order.status == status).length;
    }
    
    return stats;
  }

  // Get recent orders (last 7 days)
  List<OrderModel> getRecentOrders() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _orders.where((order) => order.createdAt.isAfter(sevenDaysAgo)).toList();
  }

  // Get total revenue
  double getTotalRevenue() {
    return _orders
        .where((order) => order.paymentStatus == PaymentStatus.paid)
        .fold(0.0, (sum, order) => sum + order.total);
  }

  // Get monthly revenue
  double getMonthlyRevenue() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    return _orders
        .where((order) => 
            order.paymentStatus == PaymentStatus.paid &&
            order.createdAt.isAfter(startOfMonth))
        .fold(0.0, (sum, order) => sum + order.total);
  }
}
