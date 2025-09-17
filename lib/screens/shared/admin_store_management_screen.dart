import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../../models/store_item_model.dart';
import '../../services/store_service.dart';
import '../../theme/pet_care_theme.dart';
import 'create_store_item_screen.dart';

class AdminStoreManagementScreen extends StatefulWidget {
  const AdminStoreManagementScreen({super.key});

  @override
  State<AdminStoreManagementScreen> createState() => _AdminStoreManagementScreenState();
}

class _AdminStoreManagementScreenState extends State<AdminStoreManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoreService>(context, listen: false).loadStoreItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildImageWidget(String imageUrl) {
    try {
      if (imageUrl.startsWith('data:image')) {
        final base64Part = imageUrl.split(',').last;
        final bytes = base64Part.isNotEmpty ? base64Decode(base64Part) : null;
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.shopping_bag),
            ),
          );
        }
      }
    } catch (_) {}

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported),
      ),
    );
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
            _buildSearchBar(),
            _buildStatsCards(),
            Expanded(child: _buildItemsList()),
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
        'Store Management',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: PetCareTheme.primaryBeige,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
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
              Provider.of<StoreService>(context, listen: false).loadStoreItems();
            },
            tooltip: 'Refresh',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [PetCareTheme.accentGold, PetCareTheme.lightBrown],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: PetCareTheme.accentGold.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateStoreItemScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: PetCareTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [PetCareTheme.cardShadow],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search store items...',
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
                      Provider.of<StoreService>(context, listen: false).searchItems('');
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
            Provider.of<StoreService>(context, listen: false).searchItems(value);
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Consumer<StoreService>(
      builder: (context, storeService, child) {
        final totalItems = storeService.storeItems.length;
        final inStockItems = storeService.storeItems.where((item) => item.isInStock).length;
        final outOfStockItems = totalItems - inStockItems;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Items',
                  totalItems.toString(),
                  Icons.inventory_2_rounded,
                  PetCareTheme.accentGold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'In Stock',
                  inStockItems.toString(),
                  Icons.check_circle_rounded,
                  PetCareTheme.softGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Out of Stock',
                  outOfStockItems.toString(),
                  Icons.warning_amber_rounded,
                  PetCareTheme.warmRed,
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
                      fontSize: 20,
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

  Widget _buildItemsList() {
    return Consumer<StoreService>(
      builder: (context, storeService, child) {
        if (storeService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (storeService.storeItems.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No store items found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: storeService.storeItems.length,
          itemBuilder: (context, index) {
            final item = storeService.storeItems[index];
            return _buildItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildItemCard(StoreItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: item.imageUrls.isNotEmpty
                    ? _buildImageWidget(item.imageUrls.first)
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.shopping_bag),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.brand,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        item.formattedPrice,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.isInStock ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.isInStock ? 'In Stock' : 'Out of Stock',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, item),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_stock',
                  child: Row(
                    children: [
                      Icon(
                        item.isInStock ? Icons.remove_circle : Icons.add_circle,
                        color: item.isInStock ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(item.isInStock ? 'Mark Out of Stock' : 'Mark In Stock'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, StoreItemModel item) async {
    final storeService = Provider.of<StoreService>(context, listen: false);

    try {
      switch (action) {
        case 'edit':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateStoreItemScreen(existingItem: item),
            ),
          );
          break;
        case 'toggle_stock':
          final updatedItem = item.copyWith(
            isInStock: !item.isInStock,
            updatedAt: DateTime.now(),
          );
          await storeService.updateStoreItem(updatedItem);
          _showSnackBar('Stock status updated successfully');
          break;
        case 'delete':
          final confirmed = await _showDeleteConfirmation(item.name);
          if (confirmed) {
            await storeService.deleteStoreItem(item.id);
            _showSnackBar('Item deleted successfully');
          }
          break;
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<bool> _showDeleteConfirmation(String itemName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
