import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../../models/store_item_model.dart';
import '../../services/store_service.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import '../../theme/pet_care_theme.dart';
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
            _buildModernAppBar(),
            Expanded(
              child: Column(
                children: [
                  _buildSearchSection(),
                  if (_showFilters) _buildFiltersSection(),
                  Expanded(child: _buildStoreGrid()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: PetCareTheme.primaryGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Pet Store',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: PetCareTheme.primaryBeige,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Row(
                children: [
                  Consumer<CartService>(
                    builder: (context, cartService, child) {
                      return Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.shopping_cart_rounded,
                              color: PetCareTheme.primaryBeige,
                              size: 24,
                            ),
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
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: PetCareTheme.accentGradient),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: PetCareTheme.shadowColor,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
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
                    icon: Icon(
                      _showFilters ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
                      color: PetCareTheme.primaryBeige,
                      size: 24,
                    ),
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
                            icon: Icon(
                              Icons.favorite_rounded,
                              color: PetCareTheme.primaryBeige,
                              size: 24,
                            ),
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
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: PetCareTheme.accentGradient),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: PetCareTheme.shadowColor,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [PetCareTheme.elevatedShadow],
        border: Border.all(
          color: PetCareTheme.primaryBrown.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(
            color: PetCareTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: PetCareTheme.primaryBrown,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: PetCareTheme.primaryBrown,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    Provider.of<StoreService>(context, listen: false).searchItems('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: PetCareTheme.primaryBrown.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: PetCareTheme.primaryBrown.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: PetCareTheme.primaryBrown,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: PetCareTheme.primaryBeige.withValues(alpha: 0.05),
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
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: PetCareTheme.cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [PetCareTheme.elevatedShadow],
            border: Border.all(
              color: PetCareTheme.primaryBrown.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<StoreCategory?>(
                      value: storeService.selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(
                          color: PetCareTheme.primaryBrown,
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: PetCareTheme.primaryBrown.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: PetCareTheme.primaryBrown.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: PetCareTheme.primaryBrown,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: PetCareTheme.primaryBeige.withValues(alpha: 0.05),
                      ),
                      dropdownColor: PetCareTheme.cardWhite,
                      style: TextStyle(
                        color: PetCareTheme.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            'All Categories',
                            style: TextStyle(color: PetCareTheme.textDark),
                          ),
                        ),
                        ...StoreCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              _getCategoryName(category),
                              style: TextStyle(color: PetCareTheme.textDark),
                            ),
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
                      decoration: InputDecoration(
                        labelText: 'Sort By',
                        labelStyle: TextStyle(
                          color: PetCareTheme.primaryBrown,
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: PetCareTheme.primaryBrown.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: PetCareTheme.primaryBrown.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: PetCareTheme.primaryBrown,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: PetCareTheme.primaryBeige.withValues(alpha: 0.05),
                      ),
                      dropdownColor: PetCareTheme.cardWhite,
                      style: TextStyle(
                        color: PetCareTheme.textDark,
                        fontWeight: FontWeight.w500,
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: PetCareTheme.accentGradient),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: PetCareTheme.shadowColor,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        storeService.clearFilters();
                        _searchController.clear();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Clear Filters'),
                    ),
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
          return Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: PetCareTheme.cardWhite.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(PetCareTheme.primaryBrown),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Products...',
                    style: TextStyle(
                      color: PetCareTheme.primaryBrown,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (storeService.storeItems.isEmpty) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: PetCareTheme.cardWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [PetCareTheme.elevatedShadow],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          PetCareTheme.primaryBrown.withValues(alpha: 0.1),
                          PetCareTheme.lightBrown.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 50,
                      color: PetCareTheme.primaryBrown.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Products Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: PetCareTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Try adjusting your search or filters',
                    style: TextStyle(
                      fontSize: 16,
                      color: PetCareTheme.textLight,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return MasonryGridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
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

    return Container(
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PetCareTheme.primaryBrown.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: item.imageUrls.isNotEmpty
                        ? _buildImageWidget(item.imageUrls.first)
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  PetCareTheme.primaryBeige.withValues(alpha: 0.1),
                                  PetCareTheme.lightBrown.withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.shopping_bag_rounded,
                              size: 32,
                              color: PetCareTheme.primaryBrown.withValues(alpha: 0.6),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: PetCareTheme.cardWhite,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: PetCareTheme.shadowColor,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite ? PetCareTheme.warmRed : PetCareTheme.textLight,
                        size: 18,
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
                                backgroundColor: PetCareTheme.softGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                action: SnackBarAction(
                                  label: 'View Wishlist',
                                  textColor: Colors.white,
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
                                backgroundColor: PetCareTheme.warmRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Please log in to add items to wishlist'),
                              backgroundColor: PetCareTheme.accentGold,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                if (!item.isInStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: PetCareTheme.accentGradient),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: PetCareTheme.shadowColor,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Out of Stock',
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: PetCareTheme.textDark,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.brand,
                    style: TextStyle(
                      color: PetCareTheme.textLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        item.formattedPrice,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: PetCareTheme.softGreen,
                        ),
                      ),
                      const Spacer(),
                      if (item.rating != null) ...[
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: PetCareTheme.accentGold,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          item.rating!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: PetCareTheme.textDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: PetCareTheme.primaryBrown.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: PetCareTheme.primaryBrown.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getCategoryName(item.category),
                      style: TextStyle(
                        color: PetCareTheme.primaryBrown,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (item.isInStock)
                    Consumer<CartService>(
                      builder: (context, cartService, child) {
                        final isInCart = cartService.isInCart(item.id);
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: isInCart 
                                ? LinearGradient(colors: [PetCareTheme.softGreen, PetCareTheme.softGreen])
                                : LinearGradient(colors: PetCareTheme.accentGradient),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: PetCareTheme.shadowColor,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              cartService.addToCart(item);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.name} added to cart'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: PetCareTheme.softGreen,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  action: SnackBarAction(
                                    label: 'Go to Cart',
                                    textColor: Colors.white,
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
                              isInCart ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
                              size: 14,
                            ),
                            label: Text(
                              isInCart ? 'Added' : 'Add to Cart',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
            _buildModernAppBar(context),
            Expanded(child: _buildFavoritesContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: PetCareTheme.primaryGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: PetCareTheme.primaryBeige,
                  size: 24,
                ),
              ),
              Expanded(
                child: Text(
                  'My Wishlist',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: PetCareTheme.primaryBeige,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Consumer2<StoreService, AuthService>(
                builder: (context, storeService, authService, child) {
                  final userId = authService.currentUserModel?.id ?? '';
                  final hasFavorites = storeService.hasFavorites(userId);
                  
                  if (!hasFavorites) return const SizedBox.shrink();
                  
                  return PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: PetCareTheme.primaryBeige,
                      size: 24,
                    ),
                    onSelected: (value) async {
                      if (value == 'add_all_to_cart') {
                        await _addAllToCart(context, storeService, userId);
                      } else if (value == 'order_all') {
                        await _orderAllItems(context, storeService, userId);
                      } else if (value == 'clear_all') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: PetCareTheme.cardWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Text(
                              'Clear Wishlist',
                              style: TextStyle(
                                color: PetCareTheme.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to remove all items from your wishlist?',
                              style: TextStyle(color: PetCareTheme.textLight),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: PetCareTheme.textLight),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: PetCareTheme.accentGradient),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Clear All',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirmed == true) {
                          try {
                            await storeService.clearAllFavorites(userId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Wishlist cleared successfully'),
                                backgroundColor: PetCareTheme.softGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error clearing wishlist: ${e.toString()}'),
                                backgroundColor: PetCareTheme.warmRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'add_all_to_cart',
                        child: Row(
                          children: [
                            Icon(Icons.add_shopping_cart_rounded, color: PetCareTheme.softGreen),
                            const SizedBox(width: 8),
                            Text('Add All to Cart', style: TextStyle(color: PetCareTheme.textDark)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'order_all',
                        child: Row(
                          children: [
                            Icon(Icons.shopping_bag_rounded, color: PetCareTheme.accentGold),
                            const SizedBox(width: 8),
                            Text('Order All', style: TextStyle(color: PetCareTheme.textDark)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'clear_all',
                        child: Row(
                          children: [
                            Icon(Icons.clear_all_rounded, color: PetCareTheme.warmRed),
                            const SizedBox(width: 8),
                            Text('Clear All', style: TextStyle(color: PetCareTheme.warmRed)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesContent() {
    return Consumer2<StoreService, AuthService>(
      builder: (context, storeService, authService, child) {
        final userId = authService.currentUserModel?.id ?? '';
        final favoriteItems = storeService.getFavoriteItems(userId);

        if (favoriteItems.isEmpty) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: PetCareTheme.cardWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [PetCareTheme.elevatedShadow],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          PetCareTheme.primaryBrown.withValues(alpha: 0.1),
                          PetCareTheme.lightBrown.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_border_rounded,
                      size: 50,
                      color: PetCareTheme.primaryBrown.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your Wishlist is Empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: PetCareTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start adding items to your wishlist by tapping the heart icon on any product',
                    style: TextStyle(
                      fontSize: 16,
                      color: PetCareTheme.textLight,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: PetCareTheme.accentGradient),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: PetCareTheme.shadowColor,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.shopping_bag_rounded),
                      label: const Text('Browse Products'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: favoriteItems.length,
          itemBuilder: (context, index) {
            final item = favoriteItems[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildFavoriteItemCard(context, item, storeService, userId),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoriteItemCard(BuildContext context, StoreItemModel item, 
      StoreService storeService, String userId) {
    return Container(
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PetCareTheme.primaryBrown.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: item.imageUrls.isNotEmpty
                        ? _buildImageWidget(item.imageUrls.first)
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  PetCareTheme.primaryBeige.withValues(alpha: 0.1),
                                  PetCareTheme.lightBrown.withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.shopping_bag_rounded,
                              size: 32,
                              color: PetCareTheme.primaryBrown.withValues(alpha: 0.6),
                            ),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 20,
                      color: PetCareTheme.textDark,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.brand,
                    style: TextStyle(
                      color: PetCareTheme.textLight, 
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.formattedPrice,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: PetCareTheme.softGreen,
                      letterSpacing: 0.2,
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
                                size: 22,
                              ),
                              label: Text(
                                isInCart ? 'Added' : 'Add to Cart',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isInCart ? Colors.green : Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                          icon: const Icon(Icons.shopping_bag, size: 22),
                          label: const Text(
                            'Order Now',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
