import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../models/store_item_model.dart';
import '../../services/store_service.dart';
import '../../services/auth_service.dart';

class EnhancedPetStoreScreen extends StatefulWidget {
  const EnhancedPetStoreScreen({super.key});

  @override
  State<EnhancedPetStoreScreen> createState() => _EnhancedPetStoreScreenState();
}

class _EnhancedPetStoreScreenState extends State<EnhancedPetStoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  RangeValues _priceRange = const RangeValues(0, 1000);
  double _minRating = 0;
  String _selectedBrand = '';
  bool _inStockOnly = false;
  GridView _viewType = GridView.count(crossAxisCount: 2, children: const []);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeService = Provider.of<StoreService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      storeService.loadStoreItems();
      if (authService.currentUserModel != null) {
        storeService.loadUserFavorites(authService.currentUserModel!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Store'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              Provider.of<StoreService>(context, listen: false).sortItems(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Name A-Z')),
              const PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
              const PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')),
              const PopupMenuItem(value: 'rating', child: Text('Highest Rated')),
              const PopupMenuItem(value: 'popularity', child: Text('Most Popular')),
              const PopupMenuItem(value: 'newest', child: Text('Newest First')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<StoreService>(context, listen: false).searchItems('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onChanged: (value) {
                Provider.of<StoreService>(context, listen: false).searchItems(value);
              },
            ),
          ),

          // Filter panel
          if (_showFilters) _buildFilterPanel(),

          // Products grid
          Expanded(
            child: Consumer<StoreService>(
              builder: (context, storeService, child) {
                if (storeService.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (storeService.storeItems.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No products found'),
                      ],
                    ),
                  );
                }

                return MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  padding: const EdgeInsets.all(16),
                  itemCount: storeService.storeItems.length,
                  itemBuilder: (context, index) {
                    final item = storeService.storeItems[index];
                    return _buildProductCard(item, storeService);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  setState(() {
                    _priceRange = const RangeValues(0, 1000);
                    _minRating = 0;
                    _selectedBrand = '';
                    _inStockOnly = false;
                  });
                  Provider.of<StoreService>(context, listen: false).clearFilters();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          
          // Price Range
          const Text('Price Range'),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1000,
            divisions: 20,
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() => _priceRange = values);
              Provider.of<StoreService>(context, listen: false)
                  .filterByPriceRange(values.start, values.end);
            },
          ),
          
          // Rating filter
          Row(
            children: [
              const Text('Min Rating: '),
              Expanded(
                child: Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: _minRating == 0 ? 'Any' : '${_minRating.round()}★',
                  onChanged: (value) {
                    setState(() => _minRating = value);
                    Provider.of<StoreService>(context, listen: false)
                        .filterByRating(value);
                  },
                ),
              ),
            ],
          ),
          
          // In stock filter
          CheckboxListTile(
            title: const Text('In Stock Only'),
            value: _inStockOnly,
            onChanged: (value) {
              setState(() => _inStockOnly = value ?? false);
              if (value == true) {
                Provider.of<StoreService>(context, listen: false).filterInStock();
              }
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(StoreItemModel item, StoreService storeService) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUserModel;
    final isFavorite = currentUser != null
        ? storeService.isItemFavorite(item.id, currentUser.id)
        : false;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                if (item.imageUrls.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: item.imageUrls.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 50),
                    ),
                  )
                else
                  Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.pets, size: 50, color: Colors.grey),
                    ),
                  ),
                
                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                        size: 16,
                      ),
                      onPressed: currentUser != null
                          ? () => storeService.toggleFavorite(item.id, currentUser.id)
                          : null,
                    ),
                  ),
                ),
                
                // Discount badge
                if (item.rating != null && item.rating! >= 4.5)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Top Rated',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Product Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand
                Text(
                  item.brand,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Product Name
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Rating and Reviews
                if (item.rating != null)
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange, size: 16),
                      Text(
                        ' ${item.rating!.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        ' (${item.reviewCount})',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                
                // Price
                Text(
                  item.formattedPrice,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Stock Status
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: item.isInStock ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.isInStock ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                        color: item.isInStock ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Purchase Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handlePurchaseClick(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Buy Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePurchaseClick(StoreItemModel item) async {
    final storeService = Provider.of<StoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUserModel;

    if (currentUser != null) {
      // Track the click
      await storeService.trackItemClick(item.id, currentUser.id);
      await storeService.trackExternalPurchaseClick(item.id, currentUser.id);
    }

    // Launch external URL
    if (item.externalUrl.isNotEmpty) {
      final Uri url = Uri.parse(item.externalUrl);
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $e')),
          );
        }
      }
    } else {
      // Show item details dialog
      _showItemDetailsDialog(item);
    }
  }

  void _showItemDetailsDialog(StoreItemModel item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image
              if (item.imageUrls.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrls.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              
              // Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.brand,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.formattedPrice,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            if (item.externalUrl.isNotEmpty) {
                              launchUrl(Uri.parse(item.externalUrl));
                            }
                          },
                          child: const Text('Buy Now'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
