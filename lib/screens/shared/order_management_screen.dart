import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import '../../theme/pet_care_theme.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderService>(context, listen: false).loadOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildModernAppBar(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: PetCareTheme.backgroundGradient,
          ),
        ),
        child: Column(
          children: [
            _buildSearchAndFilters(),
            _buildStatsCards(),
            Expanded(child: _buildOrdersList()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: PetCareTheme.primaryGradient,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: PetCareTheme.primaryBeige,
      title: Text(
        'Order Management',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: PetCareTheme.primaryBeige,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: PetCareTheme.primaryBeige.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: PetCareTheme.primaryBeige.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: PetCareTheme.primaryBeige,
              size: 20,
            ),
            onPressed: () {
              Provider.of<OrderService>(context, listen: false).loadOrders();
            },
            tooltip: 'Refresh Orders',
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: PetCareTheme.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [PetCareTheme.cardShadow],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search orders...',
                hintStyle: TextStyle(
                  color: PetCareTheme.textLight,
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: PetCareTheme.primaryBrown,
                  size: 24,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: PetCareTheme.textLight,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<OrderService>(context, listen: false).searchOrders('');
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              style: TextStyle(
                color: PetCareTheme.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              onChanged: (value) {
                Provider.of<OrderService>(context, listen: false).searchOrders(value);
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusFilters(),
        ],
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Consumer<OrderService>(
      builder: (context, orderService, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All', null, orderService.selectedStatus),
              const SizedBox(width: 8),
              ...OrderStatus.values.map((status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  status.displayName,
                  status,
                  orderService.selectedStatus,
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, OrderStatus? status, OrderStatus? selectedStatus) {
    final isSelected = status == selectedStatus;
    
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected 
            ? LinearGradient(colors: PetCareTheme.accentGradient)
            : null,
        color: isSelected ? null : PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected 
              ? PetCareTheme.accentGold.withOpacity(0.3)
              : PetCareTheme.lightBrown.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isSelected 
            ? [
                BoxShadow(
                  color: PetCareTheme.accentGold.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [PetCareTheme.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Provider.of<OrderService>(context, listen: false).filterByStatus(
              isSelected ? null : status,
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                if (isSelected) const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : PetCareTheme.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Consumer<OrderService>(
      builder: (context, orderService, child) {
        // Calculate total revenue safely
        final totalRevenue = orderService.orders.fold<double>(0.0, (sum, order) => sum + order.total);
        
        // Calculate monthly revenue (current month)
        final now = DateTime.now();
        final monthlyRevenue = orderService.orders.where((order) {
          return order.createdAt.year == now.year && order.createdAt.month == now.month;
        }).fold<double>(0.0, (sum, order) => sum + order.total);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  '${orderService.orders.length}',
                  Icons.shopping_cart_checkout_rounded,
                  PetCareTheme.accentGold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Revenue',
                  '\$${totalRevenue.toStringAsFixed(2)}',
                  Icons.payments_rounded,
                  PetCareTheme.softGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'This Month',
                  '\$${monthlyRevenue.toStringAsFixed(2)}',
                  Icons.trending_up_rounded,
                  PetCareTheme.warmPurple,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.05),
              color.withOpacity(0.02),
              Colors.white.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Section
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Value Section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: PetCareTheme.primaryBrown,
                      letterSpacing: -0.5,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: PetCareTheme.lightBrown.withOpacity(0.9),
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return Consumer<OrderService>(
      builder: (context, orderService, child) {
        if (orderService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = orderService.filteredOrders;
        
        if (orders.isEmpty) {
          return const Center(
            child: Text('No orders found'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: order.statusColor),
                  ),
                  child: Text(
                    order.statusDisplayName,
                    style: TextStyle(
                      color: order.statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Customer: ${order.userName}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            Text(
              'Email: ${order.userEmail}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            Text(
              'Total: \$${order.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Placed: ${_formatDate(order.createdAt)}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            if (order.trackingNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                'Tracking: ${order.trackingNumber}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showOrderDetails(order),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showStatusUpdateDialog(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Update Status'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Customer', order.userName),
              _buildDetailRow('Email', order.userEmail),
              _buildDetailRow('Phone', order.userPhone),
              _buildDetailRow('Status', order.statusDisplayName),
              _buildDetailRow('Payment', order.paymentStatusDisplayName),
              _buildDetailRow('Total', '\$${order.total.toStringAsFixed(2)}'),
              _buildDetailRow('Items', '${order.items.length} items'),
              if (order.trackingNumber != null)
                _buildDetailRow('Tracking', order.trackingNumber!),
              const SizedBox(height: 16),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• ${item.itemName} x${item.quantity}'),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order #${order.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OrderStatus.values.map((status) {
            return ListTile(
              title: Text(status.displayName),
              leading: Radio<OrderStatus>(
                value: status,
                groupValue: order.status,
                onChanged: (value) {
                  if (value != null) {
                    _updateOrderStatus(order, value);
                    Navigator.pop(context);
                  }
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(OrderModel order, OrderStatus newStatus) async {
    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      await orderService.updateOrderStatus(
        order.id,
        newStatus,
        note: 'Status updated by veterinarian',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
