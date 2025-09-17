import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/image_utils.dart';

class UniversalImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const UniversalImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final urlPreview = imageUrl != null && imageUrl!.length > 100 
        ? '${imageUrl!.substring(0, 100)}...'
        : imageUrl;
    print('UniversalImageWidget: Building image with URL: $urlPreview');
    
    if (imageUrl == null || imageUrl!.isEmpty) {
      print('UniversalImageWidget: No image URL provided');
      return _buildErrorWidget();
    }

    final imageSourceType = ImageUtils.getImageSourceType(imageUrl);
    print('UniversalImageWidget: Image source type: $imageSourceType');

    Widget imageWidget;

    switch (imageSourceType) {
      case ImageSourceType.base64:
        print('UniversalImageWidget: Creating base64 image');
        try {
          final bytes = _getBase64Bytes(imageUrl!);
          print('UniversalImageWidget: Successfully decoded ${bytes.length} bytes');
          imageWidget = Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              print('UniversalImageWidget: Error building base64 image: $error');
              print('UniversalImageWidget: Stack trace: $stackTrace');
              return _buildErrorWidget();
            },
          );
        } catch (e) {
          print('UniversalImageWidget: Failed to decode base64 image: $e');
          return _buildErrorWidget();
        }
        break;
      case ImageSourceType.network:
        print('UniversalImageWidget: Creating network image: ${imageUrl!}');
        imageWidget = Image.network(
          imageUrl!,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              print('UniversalImageWidget: Network image loaded successfully');
              return child;
            }
            final progress = loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null;
            print('UniversalImageWidget: Loading network image... Progress: ${progress?.toStringAsFixed(2) ?? 'unknown'}');
            return _buildPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) {
            print('UniversalImageWidget: Error building network image: $error');
            print('UniversalImageWidget: Network error stack trace: $stackTrace');
            return _buildErrorWidget();
          },
        );
        break;
      case ImageSourceType.asset:
        print('UniversalImageWidget: Creating asset image');
        imageWidget = Image.asset(
          imageUrl!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            print('UniversalImageWidget: Error building asset image: $error');
            return _buildErrorWidget();
          },
        );
        break;
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Uint8List _getBase64Bytes(String base64DataUrl) {
    try {
      print('Decoding base64 image: ${base64DataUrl.substring(0, base64DataUrl.length > 100 ? 100 : base64DataUrl.length)}...');
      
      // Handle both data:image/...;base64,xxx and direct base64 strings
      String base64String;
      if (base64DataUrl.contains(',')) {
        base64String = base64DataUrl.split(',')[1];
      } else {
        base64String = base64DataUrl;
      }
      
      if (base64String.isEmpty) {
        throw Exception('Empty base64 string');
      }
      
      final decoded = base64Decode(base64String);
      print('Successfully decoded base64 image, size: ${decoded.length} bytes');
      return Uint8List.fromList(decoded);
    } catch (e) {
      print('Error decoding base64 image: $e');
      print('Base64 data URL length: ${base64DataUrl.length}');
      print('Base64 data URL preview: ${base64DataUrl.substring(0, base64DataUrl.length > 200 ? 200 : base64DataUrl.length)}...');
      // Return a minimal valid PNG instead of empty bytes
      return _createErrorImage();
    }
  }

  Uint8List _createErrorImage() {
    // Create a simple 1x1 pixel PNG for error cases
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 pixel
      0x08, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, // IEND
      0xAE, 0x42, 0x60, 0x82,
    ]);
  }

  Widget _buildPlaceholder() {
    return placeholder ?? Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    print('UniversalImageWidget: Displaying error widget');
    return errorWidget ?? Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: Colors.grey[600],
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            'Image failed',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Specialized widget for store item images
class StoreItemImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const StoreItemImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return UniversalImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      placeholder: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(
            Icons.store,
            color: Colors.grey,
            size: 32,
          ),
        ),
      ),
    );
  }
}

/// Specialized widget for pet images
class PetImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const PetImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return UniversalImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      placeholder: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(
            Icons.pets,
            color: Colors.grey,
            size: 32,
          ),
        ),
      ),
    );
  }
}
