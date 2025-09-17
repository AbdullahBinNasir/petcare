import '../models/store_item_model.dart';
import '../utils/image_utils.dart';

class SampleStoreItems {
  static List<StoreItemModel> getSampleItems() {
    final sampleImages = ImageUtils.getSampleBase64Images();
    final now = DateTime.now();

    return [
      // Food Category
      StoreItemModel(
        id: 'premium_dog_food',
        name: 'Royal Canin Adult Dog Food',
        description: 'Premium dry dog food formulated for adult dogs with balanced nutrition and high-quality proteins. Contains essential vitamins and minerals for optimal health.',
        price: 45.99,
        currency: 'USD',
        category: StoreCategory.food,
        imageUrls: [sampleImages['dog_food']!],
        brand: 'Royal Canin',
        isInStock: true,
        stockQuantity: 25,
        rating: 4.5,
        reviewCount: 128,
        externalUrl: 'https://example.com/royal-canin-dog-food',
        specifications: {
          'weight': '15 lbs',
          'ageRange': 'Adult (1-7 years)',
          'protein': '22%',
          'fat': '12%',
          'fiber': '3.5%',
          'ingredients': 'Chicken meal, Brown rice, Corn, Wheat, Chicken fat'
        },
        tags: ['premium', 'adult', 'dry food', 'chicken', 'grain'],
        createdAt: now,
        updatedAt: now,
        isActive: true,
      ),

      StoreItemModel(
        id: 'grain_free_cat_food',
        name: 'Blue Buffalo Wilderness Cat Food',
        description: 'Grain-free wet cat food with real chicken and turkey. High protein content perfect for indoor cats with sensitive stomachs.',
        price: 32.50,
        currency: 'USD',
        category: StoreCategory.food,
        imageUrls: [sampleImages['cat_toy']!], // Using cat toy image as placeholder
        brand: 'Blue Buffalo',
        isInStock: true,
        stockQuantity: 18,
        rating: 4.3,
        reviewCount: 95,
        externalUrl: 'https://example.com/blue-buffalo-cat-food',
        specifications: {
          'weight': '12 cans',
          'ageRange': 'All ages',
          'protein': '10%',
          'fat': '5%',
          'fiber': '1.5%',
          'ingredients': 'Chicken, Turkey, Chicken broth, Potato starch, Carrots'
        },
        tags: ['grain-free', 'wet food', 'chicken', 'indoor', 'sensitive stomach'],
        createdAt: now,
        updatedAt: now,
        isActive: true,
      ),

      // Grooming Category
      StoreItemModel(
        id: 'grooming_kit',
        name: 'Professional Pet Grooming Kit',
        description: 'Complete grooming set including brushes, combs, nail clippers, and shampoo. Perfect for maintaining your pet\'s hygiene at home.',
        price: 89.99,
        currency: 'USD',
        category: StoreCategory.grooming,
        imageUrls: [sampleImages['grooming_kit']!],
        brand: 'PetPro',
        isInStock: true,
        stockQuantity: 12,
        rating: 4.7,
        reviewCount: 67,
        externalUrl: 'https://example.com/grooming-kit',
        specifications: {
          'contents': 'Slicker brush, Undercoat rake, Nail clippers, Shampoo, Conditioner, Towel',
          'suitableFor': 'Dogs, Cats',
          'material': 'Stainless steel and plastic',
          'warranty': '1 year'
        },
        tags: ['complete kit', 'professional', 'home grooming', 'brushes', 'nail care'],
        createdAt: now,
        updatedAt: now,
        isActive: true,
      ),

      StoreItemModel(
        id: 'hypoallergenic_shampoo',
        name: 'Oatmeal & Aloe Pet Shampoo',
        description: 'Gentle, hypoallergenic shampoo perfect for pets with sensitive skin. Contains natural oatmeal and aloe vera for soothing relief.',
        price: 24.99,
        currency: 'USD',
        category: StoreCategory.grooming,
        imageUrls: [sampleImages['shampoo']!],
        brand: 'Natural Pet Care',
        isInStock: true,
        stockQuantity: 30,
        rating: 4.4,
        reviewCount: 156,
        externalUrl: 'https://example.com/oatmeal-shampoo',
        specifications: {
          'volume': '16 oz',
          'pH': '6.5-7.0',
          'ingredients': 'Oatmeal extract, Aloe vera, Coconut oil, Vitamin E',
          'suitableFor': 'Dogs, Cats, Sensitive skin',
          'fragrance': 'Light lavender'
        },
        tags: ['hypoallergenic', 'sensitive skin', 'oatmeal', 'aloe', 'natural'],
        createdAt: now,
        updatedAt: now,
        isActive: true,
      ),

      // Toys Category
      StoreItemModel(
        id: 'cat_laser_pointer',
        name: 'Electronic Cat Laser Pointer',
        description: 'Automatic laser pointer that moves in random patterns to keep your cat entertained. Features multiple speed settings and timer options.',
        price: 39.99,
        currency: 'USD',
        category: StoreCategory.toys,
        imageUrls: [sampleImages['laser_pointer']!],
        brand: 'Playful Paws',
        isInStock: true,
        stockQuantity: 20,
        rating: 4.2,
        reviewCount: 89,
        externalUrl: 'https://example.com/cat-laser-pointer',
        specifications: {
          'power': 'Battery operated (3 AA batteries)',
          'runtime': '15 minutes continuous',
          'patterns': '5 different movement patterns',
          'timer': '5, 10, 15 minute options',
          'safety': 'Auto-shutoff after 15 minutes'
        },
        tags: ['interactive', 'laser', 'automatic', 'exercise', 'indoor'],
        createdAt: now,
        updatedAt: now,
        isActive: true,
      ),

      StoreItemModel(
        id: 'kong_classic_toy',
        name: 'Kong Classic Dog Toy',
        description: 'Durable rubber toy perfect for chewing and treat dispensing. Can be filled with treats or frozen for extended playtime.',
        price: 18.99,
        currency: 'USD',
        category: StoreCategory.toys,
        imageUrls: [sampleImages['kong_toy']!],
        brand: 'Kong',
        isInStock: true,
        stockQuantity: 35,
        rating: 4.8,
        reviewCount: 234,
        externalUrl: 'https://example.com/kong-classic',
        specifications: {
          'material': 'Natural rubber',
          'sizes': 'XS, S, M, L, XL',
          'colors': 'Red, Blue, Black',
          'features': 'Treat dispensing, Bouncy, Chew-resistant',
          'ageRange': 'Puppy to Senior'
        },
        tags: ['durable', 'chew toy', 'treat dispenser', 'rubber', 'classic'],
        createdAt: now,
        updatedAt: now,
        isActive: true,
      ),

      // Health Category
      StoreItemModel(
        id: 'joint_supplements',
        name: 'Glucosamine & Chondroitin Dog Supplements',
        description: 'Advanced joint support formula with glucosamine, chondroitin, and MSM. Helps maintain healthy joints and mobility in aging dogs.',
        price: 42.99,
        currency: 'USD',
        category: StoreCategory.health,
        imageUrls: [sampleImages['health_supplements']!],
        brand: 'VetriScience',
        isInStock: true,
        stockQuantity: 22,
        rating: 4.6,
        reviewCount: 178,
        externalUrl: 'https://example.com/joint-supplements',
        specifications: {
          'count': '60 tablets',
          'dosage': '1 tablet per 25 lbs body weight',
          'ingredients': 'Glucosamine HCl, Chondroitin Sulfate, MSM, Vitamin C',
          'ageRange': 'Adult to Senior',
          'administration': 'With food'
        },
        tags: ['joint health', 'glucosamine', 'chondroitin', 'senior dogs', 'mobility'],
        createdAt: now,
        updatedAt: now,
        isActive: true,
      ),

      StoreItemModel(
        id: 'flea_tick_prevention',
        name: 'Monthly Flea & Tick Prevention Drops',
        description: 'Topical flea and tick prevention that provides 30 days of protection. Kills fleas, ticks, and prevents flea eggs from hatching.',
        price: 28.99,
        currency: 'USD',
        category: StoreCategory.health,
        imageUrls: [sampleImages['flea_prevention']!],
        brand: 'Frontline Plus',
        isInStock: true,
        stockQuantity: 40,
        rating: 4.3,
        reviewCount: 312,
        externalUrl: 'https://example.com/frontline-plus',
        specifications: {
          'weightRange': '45-88 lbs',
          'activeIngredients': 'Fipronil, S-Methoprene',
          'duration': '30 days',
          'application': 'Topical',
          'waterResistant': 'Yes, after 24 hours'
        },
        tags: ['flea prevention', 'tick prevention', 'monthly', 'topical', 'water resistant'],
        createdAt: now,
        updatedAt: now,
        isActive: true,
      ),

      // Accessories Category
      StoreItemModel(
        id: 'dog_harness',
        name: 'No-Pull Dog Harness with Leash',
        description: 'Comfortable, no-pull harness designed to discourage pulling while walking. Features padded chest plate and adjustable straps.',
        price: 34.99,
        currency: 'USD',
        category: StoreCategory.accessories,
        imageUrls: [sampleImages['dog_harness']!],
        brand: 'Ruffwear',
        isInStock: true,
        stockQuantity: 28,
        rating: 4.5,
        reviewCount: 145,
        externalUrl: 'https://example.com/no-pull-harness',
        specifications: {
          'sizes': 'XS, S, M, L, XL',
          'weightRange': '15-120 lbs',
          'material': 'Nylon webbing with foam padding',
          'colors': 'Black, Blue, Red, Green',
          'features': 'No-pull design, Padded chest, Adjustable straps, Leash included'
        },
        tags: ['harness', 'no-pull', 'walking', 'comfortable', 'adjustable'],
        createdAt: now,
        updatedAt: now,
        isActive: true,
      ),

      StoreItemModel(
        id: 'pet_carrier_backpack',
        name: 'Ventilated Pet Carrier Backpack',
        description: 'Comfortable backpack carrier for small dogs and cats. Features mesh windows for ventilation and multiple carrying options.',
        price: 79.99,
        currency: 'USD',
        category: StoreCategory.accessories,
        imageUrls: [sampleImages['pet_carrier']!],
        brand: 'Pet Gear',
        isInStock: true,
        stockQuantity: 15,
        rating: 4.4,
        reviewCount: 98,
        externalUrl: 'https://example.com/pet-carrier-backpack',
        specifications: {
          'weightLimit': '15 lbs',
          'dimensions': '12" x 8" x 16"',
          'material': 'Nylon with mesh panels',
          'features': 'Ventilated, Multiple carrying options, Padded straps, Zipper closure',
          'colors': 'Black, Gray, Navy'
        },
        tags: ['carrier', 'backpack', 'travel', 'ventilated', 'small pets'],
        createdAt: now,
        updatedAt: now,
        isActive: true,
      ),
    ];
  }

  /// Get sample items by category
  static List<StoreItemModel> getItemsByCategory(StoreCategory category) {
    return getSampleItems().where((item) => item.category == category).toList();
  }

  /// Get sample items with base64 images only
  static List<StoreItemModel> getItemsWithBase64Images() {
    return getSampleItems().where((item) => 
      item.imageUrls.isNotEmpty && 
      ImageUtils.isBase64DataUrl(item.imageUrls.first)
    ).toList();
  }
}
