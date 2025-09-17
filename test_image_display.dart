import 'dart:convert';
import 'dart:typed_data';

void main() {
  print('Testing image display...');
  
  // Test the base64 image we're using
  final base64Image = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
  
  print('Base64 image: $base64Image');
  
  try {
    // Test decoding
    final base64String = base64Image.split(',')[1];
    final decoded = base64Decode(base64String);
    print('Successfully decoded base64 image, size: ${decoded.length} bytes');
    
    // Test creating Uint8List
    final uint8List = Uint8List.fromList(decoded);
    print('Successfully created Uint8List, size: ${uint8List.length} bytes');
    
    print('✅ Image decoding test passed!');
  } catch (e) {
    print('❌ Image decoding test failed: $e');
  }
}
