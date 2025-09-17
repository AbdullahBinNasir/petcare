import '../models/pet_model.dart';
import '../utils/image_utils.dart';

class SamplePetData {
  static List<PetModel> getSamplePets() {
    final sampleImages = ImageUtils.getSampleBase64Images();
    final now = DateTime.now();

    return [
      PetModel(
        id: 'sample_pet_1',
        ownerId: 'sample_owner_1',
        name: 'Bruno',
        species: PetSpecies.dog,
        breed: 'Labrador Retriever',
        gender: PetGender.male,
        dateOfBirth: DateTime(2023, 1, 15),
        weight: 25.5,
        color: 'Golden',
        microchipId: 'CHIP123456789',
        photoUrls: [sampleImages['dog_food']!], // Using sample image as placeholder
        healthStatus: HealthStatus.healthy,
        medicalNotes: 'Healthy and active dog. Regular vaccinations up to date.',
        createdAt: now,
        updatedAt: now,
        isActive: true,
      ),
      PetModel(
        id: 'sample_pet_2',
        ownerId: 'sample_owner_1',
        name: 'Whiskers',
        species: PetSpecies.cat,
        breed: 'Persian',
        gender: PetGender.female,
        dateOfBirth: DateTime(2022, 6, 10),
        weight: 4.2,
        color: 'White',
        microchipId: 'CHIP987654321',
        photoUrls: [sampleImages['cat_toy']!], // Using sample image as placeholder
        healthStatus: HealthStatus.healthy,
        medicalNotes: 'Indoor cat with no health issues.',
        createdAt: now,
        updatedAt: now,
        isActive: true,
      ),
      PetModel(
        id: 'sample_pet_3',
        ownerId: 'sample_owner_2',
        name: 'Buddy',
        species: PetSpecies.dog,
        breed: 'Golden Retriever',
        gender: PetGender.male,
        dateOfBirth: DateTime(2021, 3, 20),
        weight: 30.0,
        color: 'Golden',
        microchipId: 'CHIP456789123',
        photoUrls: [sampleImages['kong_toy']!], // Using sample image as placeholder
        healthStatus: HealthStatus.healthy,
        medicalNotes: 'Very friendly and energetic dog.',
        createdAt: now,
        updatedAt: now,
        isActive: true,
      ),
    ];
  }

  /// Get sample pet with base64 image
  static PetModel getSamplePetWithBase64Image() {
    final sampleImages = ImageUtils.getSampleBase64Images();
    final now = DateTime.now();

    return PetModel(
      id: 'sample_pet_base64',
      ownerId: 'sample_owner_base64',
      name: 'Luna',
      species: PetSpecies.cat,
      breed: 'Maine Coon',
      gender: PetGender.female,
      dateOfBirth: DateTime(2022, 8, 5),
      weight: 6.5,
      color: 'Black and White',
      microchipId: 'CHIP111222333',
      photoUrls: [sampleImages['grooming_kit']!], // Using base64 image
      healthStatus: HealthStatus.healthy,
      medicalNotes: 'Large breed cat, very gentle and loving.',
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );
  }

  /// Create a simple base64 image for testing
  static String getSimpleBase64Image() {
    // This is a very small 1x1 pixel PNG image (base64 encoded)
    return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
  }

  /// Create a colored base64 image for testing
  static String getColoredBase64Image(String color) {
    // This creates a simple colored square image
    // For now, we'll use the same simple image but you can expand this
    return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
  }
}
