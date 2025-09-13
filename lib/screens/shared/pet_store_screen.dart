import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../models/store_item_model.dart';
import '../../services/store_service.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import 'store_item_details_screen.dart';
import 'shopping_cart_screen.dart';

class PetStoreScreen extends StatefulWidget {
  const PetStoreScreen({super.key});

  @override
  State<PetStoreScreen> createState() => _PetStoreScreenState();
}

class _PetStoreScreenState extends State<PetStoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStoreItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadStoreItems() {
    final storeService = Provider.of<StoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    storeService.loadStoreItems();
    if (authService.currentUserModel != null) {
      storeService.loadUserFavorites(authService.currentUserModel!.id);
    }
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
              child: const Icon(Icons.shopping_bag, size: 48),
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
        child: const Center(
          child: CircularProgressIndicator(),
        ),
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
      appBar: AppBar(
        title: const Text('Pet Store'),
        actions: [
          Consumer<CartService>(
            builder: (context, cartService, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShoppingCartScreen(),
                        ),
                      );
                    },
                  ),
                  if (cartService.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cartService.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          Consumer2<StoreService, AuthService>(
            builder: (context, storeService, authService, child) {
              final userId = authService.currentUserModel?.id ?? '';
              final wishlistCount = storeService.getFavoriteItemsCount(userId);
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoritesScreen(),
                        ),
                      );
                    },
                  ),
                  if (wishlistCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$wishlistCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showFilters) _buildFiltersSection(),
          Expanded(child: _buildStoreGrid()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          Provider.of<StoreService>(context, listen: false).searchItems(value);
        },
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Consumer<StoreService>(
      builder: (context, storeService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<StoreCategory?>(
                      value: storeService.selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...StoreCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(_getCategoryName(category)),
                          );
                        }),
                      ],
                      onChanged: (category) {
                        storeService.filterByCategory(category);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: storeService.sortBy,
                      decoration: const InputDecoration(
                        labelText: 'Sort By',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('Name')),
                        DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                        DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                        DropdownMenuItem(value: 'rating', child: Text('Rating')),
                        DropdownMenuItem(value: 'popularity', child: Text('Popularity')),
                      ],
                      onChanged: (sortBy) {
                        if (sortBy != null) {
                          storeService.sortItems(sortBy);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      storeService.clearFilters();
                      _searchController.clear();
                    },
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoreGrid() {
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
                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return MasonryGridView.count(
          crossAxisCount: 3,
          padding: const EdgeInsets.all(12),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: storeService.storeItems.length,
          itemBuilder: (context, index) {
            final item = storeService.storeItems[index];
            return _buildStoreItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildStoreItemCard(StoreItemModel item) {
    final authService = Provider.of<AuthService>(context);
    final storeService = Provider.of<StoreService>(context);
    final userId = authService.currentUserModel?.id ?? '';
    final isFavorite = storeService.isItemFavorite(item.id, userId);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          if (userId.isNotEmpty) {
            storeService.trackItemClick(item.id, userId);
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoreItemDetailsScreen(item: item),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: item.imageUrls.isNotEmpty
                        ? _buildImageWidget(item.imageUrls.first)
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.shopping_bag, size: 32),
                          ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                        size: 16,
                      ),
                      onPressed: () async {
                        if (userId.isNotEmpty) {
                          try {
                            await storeService.toggleFavorite(item.id, userId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFavorite 
                                    ? '${item.name} removed from wishlist'
                                    : '${item.name} added to wishlist',
                                ),
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'View Wishlist',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const FavoritesScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating wishlist: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please log in to add items to wishlist'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                if (!item.isInStock)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Out of Stock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.brand,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        item.formattedPrice,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      if (item.rating != null) ...[
                        Icon(Icons.star, size: 12, color: Colors.amber[600]),
                        const SizedBox(width: 2),
                        Text(
                          item.rating!.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getCategoryName(item.category),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (item.isInStock)
                    Consumer<CartService>(
                      builder: (context, cartService, child) {
                        final isInCart = cartService.isInCart(item.id);
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              cartService.addToCart(item);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.name} added to cart'),
                                  duration: const Duration(seconds: 2),
                                  action: SnackBarAction(
                                    label: 'Go to Cart',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ShoppingCartScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                            icon: Icon(
                              isInCart ? Icons.check : Icons.add_shopping_cart,
                              size: 14,
                            ),
                            label: Text(
                              isInCart ? 'Added' : 'Add to Cart',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInCart ? Colors.green : Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(StoreCategory category) {
    switch (category) {
      case StoreCategory.food:
        return 'Food';
      case StoreCategory.grooming:
        return 'Grooming';
      case StoreCategory.toys:
        return 'Toys';
      case StoreCategory.health:
        return 'Health';
      case StoreCategory.accessories:
        return 'Accessories';
      case StoreCategory.other:
        return 'Other';
    }
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

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
              child: const Icon(Icons.shopping_bag, size: 48),
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
        child: const Center(
          child: CircularProgressIndicator(),
        ),
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
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          Consumer2<StoreService, AuthService>(
            builder: (context, storeService, authService, child) {
              final userId = authService.currentUserModel?.id ?? '';
              final hasFavorites = storeService.hasFavorites(userId);
              
              if (!hasFavorites) return const SizedBox.shrink();
              
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'add_all_to_cart') {
                    await _addAllToCart(context, storeService, userId);
                  } else if (value == 'order_all') {
                    await _orderAllItems(context, storeService, userId);
                  } else if (value == 'clear_all') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Wishlist'),
                        content: const Text('Are you sure you want to remove all items from your wishlist?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed == true) {
                      try {
                        await storeService.clearAllFavorites(userId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Wishlist cleared successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error clearing wishlist: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_all_to_cart',
                    child: Row(
                      children: [
                        Icon(Icons.add_shopping_cart, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Add All to Cart'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'order_all',
                    child: Row(
                      children: [
                        Icon(Icons.shopping_bag, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Order All'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Clear All'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer2<StoreService, AuthService>(
        builder: (context, storeService, authService, child) {
          final userId = authService.currentUserModel?.id ?? '';
          final favoriteItems = storeService.getFavoriteItems(userId);

          if (favoriteItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border, 
                    size: 80, 
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your Wishlist is Empty',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start adding items to your wishlist by tapping the heart icon on any product',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Browse Products'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return MasonryGridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.all(12),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemCount: favoriteItems.length,
            itemBuilder: (context, index) {
              final item = favoriteItems[index];
              return _buildFavoriteItemCard(context, item, storeService, userId);
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoriteItemCard(BuildContext context, StoreItemModel item, 
      StoreService storeService, String userId) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          storeService.trackItemClick(item.id, userId);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoreItemDetailsScreen(item: item),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: item.imageUrls.isNotEmpty
                        ? _buildImageWidget(item.imageUrls.first)
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.shopping_bag, size: 48),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                      onPressed: () async {
                        try {
                          await storeService.toggleFavorite(item.id, userId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} removed from wishlist'),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () async {
                                  await storeService.toggleFavorite(item.id, userId);
                                },
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error removing item: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.brand,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.formattedPrice,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Add to Cart and Order buttons
                  Row(
                    children: [
                      Expanded(
                        child: Consumer<CartService>(
                          builder: (context, cartService, child) {
                            final isInCart = cartService.isInCart(item.id);
                            return ElevatedButton.icon(
                              onPressed: () {
                                cartService.addToCart(item);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.name} added to cart'),
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'View Cart',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ShoppingCartScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(
                                isInCart ? Icons.check : Icons.add_shopping_cart,
                                size: 16,
                              ),
                              label: Text(
                                isInCart ? 'Added' : 'Add to Cart',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isInCart ? Colors.green : Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showOrderDialog(context, item),
                          icon: const Icon(Icons.shopping_bag, size: 16),
                          label: const Text(
                            'Order Now',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show order dialog for individual item
  void _showOrderDialog(BuildContext context, StoreItemModel item) {
    final TextEditingController quantityController = TextEditingController(text: '1');
    final TextEditingController notesController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController cityController = TextEditingController();
    final TextEditingController stateController = TextEditingController();
    final TextEditingController zipCodeController = TextEditingController();
    final TextEditingController countryController = TextEditingController(text: 'Pakistan');
    
    // Pre-fill with user data if available
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;
    if (user != null) {
      addressController.text = user.address ?? '';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order ${item.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Item details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.imageUrls.isNotEmpty
                          ? _buildImageWidget(item.imageUrls.first)
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: const Icon(Icons.shopping_bag),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.brand,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Text(
                            item.formattedPrice,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Shipping Information Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Shipping Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Address
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Shipping Address *',
                        hintText: 'Enter your complete address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    
                    // City and State Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cityController,
                            decoration: const InputDecoration(
                              labelText: 'City *',
                              hintText: 'e.g., Karachi',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stateController,
                            decoration: const InputDecoration(
                              labelText: 'State/Province *',
                              hintText: 'e.g., Sindh',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.map),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Zip Code and Country Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: zipCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Postal Code *',
                              hintText: 'e.g., 75000',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.pin_drop),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: countryController,
                            decoration: const InputDecoration(
                              labelText: 'Country *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.public),
                            ),
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Quantity input
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_cart),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              // Notes input
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Order Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _placeOrderWithForm(
              context, 
              item, 
              quantityController.text, 
              notesController.text,
              addressController.text,
              cityController.text,
              stateController.text,
              zipCodeController.text,
              countryController.text,
            ),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
  }

  // Place order with form data
  Future<void> _placeOrderWithForm(
    BuildContext context, 
    StoreItemModel item, 
    String quantityText, 
    String notes,
    String address,
    String city,
    String state,
    String zipCode,
    String country,
  ) async {
    // Validate required fields
    if (address.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter shipping address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (city.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter city'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (state.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter state/province'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (zipCode.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter postal code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final quantity = int.tryParse(quantityText) ?? 1;
      if (quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid quantity'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final orderService = Provider.of<OrderService>(context, listen: false);
      
      final userId = authService.currentUserModel?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to place an order'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create order item
      final orderItem = OrderItemModel(
        itemId: item.id,
        itemName: item.name,
        itemImage: item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
        price: item.price,
        quantity: quantity,
        category: item.category.toString().split('.').last,
      );

      // Create order
      final user = authService.currentUserModel!;
      final order = OrderModel(
        id: '',
        userId: userId,
        userName: '${user.firstName} ${user.lastName}',
        userEmail: user.email,
        userPhone: user.phoneNumber ?? '',
        items: [orderItem],
        subtotal: item.price * quantity,
        tax: (item.price * quantity) * 0.08, // 8% tax
        shipping: 5.99, // Fixed shipping
        total: (item.price * quantity) + ((item.price * quantity) * 0.08) + 5.99,
        status: OrderStatus.pending,
        shippingAddress: address,
        city: city,
        state: state,
        zipCode: zipCode,
        country: country,
        notes: notes.isNotEmpty ? notes : '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Place order
      final orderId = await orderService.createOrder(order);
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Close order dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed successfully! Order ID: $orderId'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Place order for individual item (legacy method)
  Future<void> _placeOrder(BuildContext context, StoreItemModel item, String quantityText, String notes) async {
    try {
      final quantity = int.tryParse(quantityText) ?? 1;
      if (quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid quantity'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final orderService = Provider.of<OrderService>(context, listen: false);
      
      final userId = authService.currentUserModel?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to place an order'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create order item
      final orderItem = OrderItemModel(
        itemId: item.id,
        itemName: item.name,
        itemImage: item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
        price: item.price,
        quantity: quantity,
        category: item.category.toString().split('.').last,
      );

      // Create order
      final user = authService.currentUserModel!;
      final order = OrderModel(
        id: '',
        userId: userId,
        userName: '${user.firstName} ${user.lastName}',
        userEmail: user.email,
        userPhone: user.phoneNumber ?? '',
        items: [orderItem],
        subtotal: item.price * quantity,
        tax: (item.price * quantity) * 0.08, // 8% tax
        shipping: 5.99, // Fixed shipping
        total: (item.price * quantity) + ((item.price * quantity) * 0.08) + 5.99,
        status: OrderStatus.pending,
        shippingAddress: user.address ?? '',
        city: '', // Not available in UserModel
        state: '', // Not available in UserModel
        zipCode: '', // Not available in UserModel
        country: 'USA', // Default value
        notes: notes.isNotEmpty ? notes : '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Place order
      final orderId = await orderService.createOrder(order);
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Close order dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed successfully! Order ID: $orderId'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add all wishlist items to cart
  Future<void> _addAllToCart(BuildContext context, StoreService storeService, String userId) async {
    try {
      final favoriteItems = storeService.getFavoriteItems(userId);
      final cartService = Provider.of<CartService>(context, listen: false);
      
      int addedCount = 0;
      for (final item in favoriteItems) {
        if (item.isInStock) {
          cartService.addToCart(item);
          addedCount++;
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$addedCount items added to cart'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShoppingCartScreen(),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding items to cart: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Order all wishlist items
  Future<void> _orderAllItems(BuildContext context, StoreService storeService, String userId) async {
    try {
      final favoriteItems = storeService.getFavoriteItems(userId);
      if (favoriteItems.isEmpty) return;

      final authService = Provider.of<AuthService>(context, listen: false);
      final orderService = Provider.of<OrderService>(context, listen: false);
      
      if (authService.currentUserModel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to place an order'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show shipping form for bulk order
      final result = await _showBulkOrderForm(context, favoriteItems);
      if (result == null) return;

      // Extract form data
      final address = result['address'] as String;
      final city = result['city'] as String;
      final state = result['state'] as String;
      final zipCode = result['zipCode'] as String;
      final country = result['country'] as String;
      final notes = result['notes'] as String;

      // Create order items
      final orderItems = favoriteItems.map((item) => OrderItemModel(
        itemId: item.id,
        itemName: item.name,
        itemImage: item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
        price: item.price,
        quantity: 1,
        category: item.category.toString().split('.').last,
      )).toList();

      // Calculate totals
      final subtotal = favoriteItems.fold(0.0, (sum, item) => sum + item.price);
      final tax = subtotal * 0.08; // 8% tax
      const shipping = 5.99; // Fixed shipping
      final total = subtotal + tax + shipping;

      // Create order
      final user = authService.currentUserModel!;
      final order = OrderModel(
        id: '',
        userId: userId,
        userName: '${user.firstName} ${user.lastName}',
        userEmail: user.email,
        userPhone: user.phoneNumber ?? '',
        items: orderItems,
        subtotal: subtotal,
        tax: tax,
        shipping: shipping,
        total: total,
        status: OrderStatus.pending,
        shippingAddress: address,
        city: city,
        state: state,
        zipCode: zipCode,
        country: country,
        notes: notes.isNotEmpty ? notes : 'Order from wishlist',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Place order
      final orderId = await orderService.createOrder(order);
      
      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed successfully! Order ID: $orderId'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show bulk order form
  Future<Map<String, String>?> _showBulkOrderForm(BuildContext context, List<StoreItemModel> items) async {
    final TextEditingController addressController = TextEditingController();
    final TextEditingController cityController = TextEditingController();
    final TextEditingController stateController = TextEditingController();
    final TextEditingController zipCodeController = TextEditingController();
    final TextEditingController countryController = TextEditingController(text: 'Pakistan');
    final TextEditingController notesController = TextEditingController();
    
    // Pre-fill with user data if available
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;
    if (user != null) {
      addressController.text = user.address ?? '';
    }
    
    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order All Items (${items.length})'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Items summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items to Order:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...items.take(3).map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('• ${item.name} - ${item.formattedPrice}'),
                    )),
                    if (items.length > 3)
                      Text('... and ${items.length - 3} more items'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Shipping Information Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Shipping Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Address
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Shipping Address *',
                        hintText: 'Enter your complete address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    
                    // City and State Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cityController,
                            decoration: const InputDecoration(
                              labelText: 'City *',
                              hintText: 'e.g., Karachi',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stateController,
                            decoration: const InputDecoration(
                              labelText: 'State/Province *',
                              hintText: 'e.g., Sindh',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.map),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Zip Code and Country Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: zipCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Postal Code *',
                              hintText: 'e.g., 75000',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.pin_drop),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: countryController,
                            decoration: const InputDecoration(
                              labelText: 'Country *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.public),
                            ),
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Notes input
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Order Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate required fields
              if (addressController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter shipping address'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (cityController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter city'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (stateController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter state/province'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (zipCodeController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter postal code'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context, {
                'address': addressController.text,
                'city': cityController.text,
                'state': stateController.text,
                'zipCode': zipCodeController.text,
                'country': countryController.text,
                'notes': notesController.text,
              });
            },
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
  }
}
