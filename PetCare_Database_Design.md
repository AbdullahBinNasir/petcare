# PetCare Database Design Documentation

## Table of Contents
1. [Database Overview](#database-overview)
2. [Collection Structure](#collection-structure)
3. [Data Models](#data-models)
4. [Indexing Strategy](#indexing-strategy)
5. [Security Rules](#security-rules)
6. [Query Patterns](#query-patterns)
7. [Performance Optimization](#performance-optimization)

---

## Database Overview

PetCare uses **Firebase Firestore** as its primary database, which is a NoSQL document database that provides real-time synchronization, offline support, and automatic scaling.

### Key Features
- **Document-based**: Data stored as JSON documents in collections
- **Real-time**: Automatic synchronization across all clients
- **Offline support**: Works offline with automatic sync when online
- **Scalable**: Automatically scales with usage
- **ACID transactions**: Supports atomic operations

---

## Collection Structure

### 1. Users Collection (`users`)

**Purpose**: Store user account information and role-specific data

```json
{
  "users": {
    "userId": {
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "phoneNumber": "+1234567890",
      "role": "petOwner",
      "profileImageUrl": "https://storage.googleapis.com/...",
      "bio": "Pet lover and owner",
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-01T00:00:00Z",
      "isActive": true,
      
      // Role-specific fields
      "clinicName": "Vet Clinic", // For veterinarians
      "licenseNumber": "VET123456", // For veterinarians
      "shelterName": "Happy Paws Shelter", // For shelter owners
      "address": "123 Main St, City, State"
    }
  }
}
```

**Indexes Required**:
- `role` (ascending)
- `email` (ascending)
- `isActive` (ascending)
- `createdAt` (descending)

### 2. Pets Collection (`pets`)

**Purpose**: Store pet information and health data

```json
{
  "pets": {
    "petId": {
      "ownerId": "userId",
      "name": "Buddy",
      "species": "dog",
      "breed": "Golden Retriever",
      "gender": "male",
      "dateOfBirth": "2020-05-15T00:00:00Z",
      "weight": 25.5,
      "color": "Golden",
      "microchipId": "123456789012345",
      "photoUrls": [
        "https://storage.googleapis.com/pet-photos/photo1.jpg",
        "https://storage.googleapis.com/pet-photos/photo2.jpg"
      ],
      "healthStatus": "healthy",
      "medicalNotes": "Regular checkups, up to date on vaccinations",
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-01T00:00:00Z",
      "isActive": true
    }
  }
}
```

**Indexes Required**:
- `ownerId` (ascending)
- `species` (ascending)
- `healthStatus` (ascending)
- `isActive` (ascending)
- `createdAt` (descending)
- Composite: `ownerId` + `isActive` + `createdAt`

### 3. Appointments Collection (`appointments`)

**Purpose**: Store appointment scheduling and medical records

```json
{
  "appointments": {
    "appointmentId": {
      "petOwnerId": "userId",
      "petId": "petId",
      "veterinarianId": "vetUserId",
      "appointmentDate": "2024-01-15T10:00:00Z",
      "timeSlot": "10:00",
      "type": "checkup",
      "status": "scheduled",
      "reason": "Annual checkup",
      "notes": "Pet seems healthy, no concerns",
      "diagnosis": "Healthy",
      "treatment": "Continue current diet",
      "prescription": "None needed",
      "cost": 75.00,
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-01T00:00:00Z"
    }
  }
}
```

**Indexes Required**:
- `petOwnerId` (ascending)
- `veterinarianId` (ascending)
- `petId` (ascending)
- `appointmentDate` (ascending)
- `status` (ascending)
- `type` (ascending)
- Composite: `veterinarianId` + `appointmentDate`
- Composite: `petOwnerId` + `appointmentDate`

### 4. Pet Listings Collection (`pet_listings`)

**Purpose**: Store pet adoption listings

```json
{
  "pet_listings": {
  "listingId": {
    "shelterOwnerId": "shelterUserId",
    "name": "Luna",
    "type": "cat",
    "breed": "Maine Coon",
    "gender": "female",
    "age": 24, // in months
    "weight": 4.2,
    "color": "Black and White",
    "microchipId": "987654321098765",
    "photoUrls": [
      "https://storage.googleapis.com/pet-listings/photo1.jpg"
    ],
    "healthStatus": "healthy",
    "medicalNotes": "Spayed, vaccinated, microchipped",
    "description": "Friendly and playful cat looking for a loving home",
    "specialNeeds": "None",
    "isVaccinated": true,
    "isSpayedNeutered": true,
    "status": "available",
    "dateArrived": "2024-01-01T00:00:00Z",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z",
    "isActive": true
  }
}
```

**Indexes Required**:
- `shelterOwnerId` (ascending)
- `type` (ascending)
- `status` (ascending)
- `isActive` (ascending)
- `createdAt` (descending)
- Composite: `status` + `isActive` + `createdAt`

### 5. Store Items Collection (`store_items`)

**Purpose**: Store e-commerce product information

```json
{
  "store_items": {
    "itemId": {
      "name": "Premium Dog Food",
      "description": "High-quality nutrition for adult dogs",
      "price": 29.99,
      "currency": "USD",
      "category": "food",
      "imageUrls": [
        "https://storage.googleapis.com/store-items/item1.jpg"
      ],
      "brand": "PetPro",
      "isInStock": true,
      "stockQuantity": 100,
      "rating": 4.5,
      "reviewCount": 150,
      "externalUrl": "https://example.com/product/123",
      "specifications": {
        "weight": "5kg",
        "ageGroup": "adult",
        "flavor": "chicken"
      },
      "tags": ["premium", "nutrition", "adult"],
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-01T00:00:00Z",
      "isActive": true
    }
  }
}
```

**Indexes Required**:
- `category` (ascending)
- `isInStock` (ascending)
- `isActive` (ascending)
- `price` (ascending)
- `rating` (descending)
- `createdAt` (descending)
- Composite: `category` + `isActive` + `isInStock`

### 6. Adoption Requests Collection (`adoption_requests`)

**Purpose**: Store pet adoption applications

```json
{
  "adoption_requests": {
    "requestId": {
      "petListingId": "listingId",
      "petOwnerId": "userId",
      "shelterOwnerId": "shelterUserId",
      "petOwnerName": "John Doe",
      "petOwnerEmail": "john@example.com",
      "petOwnerPhone": "+1234567890",
      "petName": "Luna",
      "petType": "cat",
      "reasonForAdoption": "Looking for a companion",
      "livingSituation": "House with yard",
      "experienceWithPets": "5 years with cats",
      "hasOtherPets": true,
      "otherPetsDescription": "One other cat, 3 years old",
      "hasChildren": false,
      "childrenAges": null,
      "homeDescription": "2-bedroom house with garden",
      "workSchedule": "Work from home",
      "additionalNotes": "Very excited to adopt",
      "status": "pending",
      "shelterResponse": null,
      "responseDate": null,
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-01T00:00:00Z",
      "isActive": true
    }
  }
}
```

**Indexes Required**:
- `petOwnerId` (ascending)
- `shelterOwnerId` (ascending)
- `petListingId` (ascending)
- `status` (ascending)
- `isActive` (ascending)
- `createdAt` (descending)
- Composite: `shelterOwnerId` + `status` + `createdAt`

### 7. Health Records Collection (`health_records`)

**Purpose**: Store detailed medical records

```json
{
  "health_records": {
    "recordId": {
      "petId": "petId",
      "veterinarianId": "vetUserId",
      "appointmentId": "appointmentId",
      "recordDate": "2024-01-15T10:00:00Z",
      "type": "checkup",
      "diagnosis": "Healthy",
      "symptoms": "None reported",
      "treatment": "Continue current diet and exercise",
      "medications": [
        {
          "name": "Heartworm Prevention",
          "dosage": "1 tablet monthly",
          "duration": "Ongoing"
        }
      ],
      "vaccinations": [
        {
          "name": "Rabies",
          "date": "2024-01-15T00:00:00Z",
          "nextDue": "2025-01-15T00:00:00Z"
        }
      ],
      "vitalSigns": {
        "temperature": 101.5,
        "heartRate": 80,
        "weight": 25.5
      },
      "notes": "Pet is in excellent health",
      "followUpRequired": false,
      "followUpDate": null,
      "createdAt": "2024-01-15T10:00:00Z",
      "updatedAt": "2024-01-15T10:00:00Z"
    }
  }
}
```

**Indexes Required**:
- `petId` (ascending)
- `veterinarianId` (ascending)
- `appointmentId` (ascending)
- `recordDate` (descending)
- `type` (ascending)
- Composite: `petId` + `recordDate`

### 8. Analytics Collections

#### 8.1 Item Views (`analytics/item_views/items`)

```json
{
  "itemId": {
    "viewCount": 150,
    "lastViewed": "2024-01-15T10:00:00Z",
    "category": "food"
  }
}
```

#### 8.2 Item Clicks (`analytics/item_clicks/items`)

```json
{
  "itemId": {
    "clickCount": 25,
    "lastClicked": "2024-01-15T10:00:00Z",
    "category": "food"
  }
}
```

#### 8.3 User Interests (`analytics/user_interests/users`)

```json
{
  "userId": {
    "interests": ["food", "toys"],
    "favoriteCategories": ["food", "grooming"],
    "lastActivity": "2024-01-15T10:00:00Z"
  }
}
```

---

## Data Models

### User Model
```dart
class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final UserRole role;
  final String? profileImageUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  
  // Role-specific fields
  final String? clinicName; // For veterinarians
  final String? licenseNumber; // For veterinarians
  final String? shelterName; // For shelter owners
  final String? address; // For vets and shelters
}
```

### Pet Model
```dart
class PetModel {
  final String id;
  final String ownerId;
  final String name;
  final PetSpecies species;
  final String breed;
  final PetGender gender;
  final DateTime? dateOfBirth;
  final double? weight;
  final String? color;
  final String? microchipId;
  final List<String> photoUrls;
  final HealthStatus healthStatus;
  final String? medicalNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
}
```

### Appointment Model
```dart
class AppointmentModel {
  final String id;
  final String petOwnerId;
  final String petId;
  final String veterinarianId;
  final DateTime appointmentDate;
  final String timeSlot;
  final AppointmentType type;
  final AppointmentStatus status;
  final String reason;
  final String? notes;
  final String? diagnosis;
  final String? treatment;
  final String? prescription;
  final double? cost;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

## Indexing Strategy

### 1. Single Field Indexes
- **Users**: `role`, `email`, `isActive`, `createdAt`
- **Pets**: `ownerId`, `species`, `healthStatus`, `isActive`, `createdAt`
- **Appointments**: `petOwnerId`, `veterinarianId`, `petId`, `appointmentDate`, `status`, `type`
- **Pet Listings**: `shelterOwnerId`, `type`, `status`, `isActive`, `createdAt`
- **Store Items**: `category`, `isInStock`, `isActive`, `price`, `rating`, `createdAt`
- **Adoption Requests**: `petOwnerId`, `shelterOwnerId`, `petListingId`, `status`, `isActive`, `createdAt`

### 2. Composite Indexes
- **Pets**: `ownerId + isActive + createdAt`
- **Appointments**: `veterinarianId + appointmentDate`
- **Appointments**: `petOwnerId + appointmentDate`
- **Pet Listings**: `status + isActive + createdAt`
- **Store Items**: `category + isActive + isInStock`
- **Adoption Requests**: `shelterOwnerId + status + createdAt`

### 3. Array Indexes
- **Store Items**: `tags` (for tag-based filtering)
- **Pets**: `photoUrls` (for image search)

---

## Security Rules

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Pets: owners can read/write their pets, vets can read assigned pets
    match /pets/{petId} {
      allow read, write: if request.auth != null && 
        (resource.data.ownerId == request.auth.uid || 
         isVeterinarian(request.auth.uid));
    }
    
    // Appointments: participants can read/write
    match /appointments/{appointmentId} {
      allow read, write: if request.auth != null && 
        (resource.data.petOwnerId == request.auth.uid || 
         resource.data.veterinarianId == request.auth.uid);
    }
    
    // Pet Listings: shelter owners can manage their listings
    match /pet_listings/{listingId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        resource.data.shelterOwnerId == request.auth.uid;
    }
    
    // Store Items: read-only for users, write for admins
    match /store_items/{itemId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && isAdmin(request.auth.uid);
    }
    
    // Adoption Requests: participants can read/write
    match /adoption_requests/{requestId} {
      allow read, write: if request.auth != null && 
        (resource.data.petOwnerId == request.auth.uid || 
         resource.data.shelterOwnerId == request.auth.uid);
    }
    
    // Health Records: vets and pet owners can access
    match /health_records/{recordId} {
      allow read, write: if request.auth != null && 
        (resource.data.veterinarianId == request.auth.uid || 
         isPetOwner(request.auth.uid, resource.data.petId));
    }
    
    // Helper functions
    function isVeterinarian(uid) {
      return get(/databases/$(database)/documents/users/$(uid)).data.role == 'veterinarian';
    }
    
    function isAdmin(uid) {
      return get(/databases/$(database)/documents/users/$(uid)).data.role == 'admin';
    }
    
    function isPetOwner(uid, petId) {
      return get(/databases/$(database)/documents/pets/$(petId)).data.ownerId == uid;
    }
  }
}
```

---

## Query Patterns

### 1. Common Query Patterns

#### Get User's Pets
```dart
FirebaseFirestore.instance
  .collection('pets')
  .where('ownerId', isEqualTo: userId)
  .where('isActive', isEqualTo: true)
  .orderBy('createdAt', descending: true)
  .get();
```

#### Get Veterinarian's Appointments
```dart
FirebaseFirestore.instance
  .collection('appointments')
  .where('veterinarianId', isEqualTo: vetId)
  .where('appointmentDate', isGreaterThanOrEqualTo: startDate)
  .where('appointmentDate', isLessThanOrEqualTo: endDate)
  .orderBy('appointmentDate')
  .get();
```

#### Search Store Items
```dart
FirebaseFirestore.instance
  .collection('store_items')
  .where('category', isEqualTo: category)
  .where('isActive', isEqualTo: true)
  .where('isInStock', isEqualTo: true)
  .orderBy('rating', descending: true)
  .get();
```

#### Get Available Pet Listings
```dart
FirebaseFirestore.instance
  .collection('pet_listings')
  .where('status', isEqualTo: 'available')
  .where('isActive', isEqualTo: true)
  .orderBy('createdAt', descending: true)
  .get();
```

### 2. Real-time Listeners

#### Listen to User's Pets
```dart
FirebaseFirestore.instance
  .collection('pets')
  .where('ownerId', isEqualTo: userId)
  .where('isActive', isEqualTo: true)
  .snapshots();
```

#### Listen to Today's Appointments
```dart
FirebaseFirestore.instance
  .collection('appointments')
  .where('veterinarianId', isEqualTo: vetId)
  .where('appointmentDate', isGreaterThanOrEqualTo: startOfDay)
  .where('appointmentDate', isLessThanOrEqualTo: endOfDay)
  .snapshots();
```

---

## Performance Optimization

### 1. Query Optimization
- **Use specific field filters** before range filters
- **Limit result sets** with `.limit()`
- **Use composite indexes** for complex queries
- **Avoid array-contains-any** for large arrays

### 2. Data Structure Optimization
- **Denormalize frequently accessed data**
- **Use subcollections** for large datasets
- **Batch operations** for multiple writes
- **Use server timestamps** for consistency

### 3. Caching Strategy
- **Local caching** with Provider state management
- **Image caching** with cached_network_image
- **Offline persistence** with Firestore offline support

### 4. Index Management
- **Monitor index usage** in Firebase Console
- **Remove unused indexes** to reduce costs
- **Optimize composite indexes** for common query patterns

---

## Backup and Recovery

### 1. Automated Backups
- **Firestore automatic backups** (daily)
- **Export to Cloud Storage** for long-term retention
- **Point-in-time recovery** for data restoration

### 2. Data Export
```bash
# Export all collections
gcloud firestore export gs://your-bucket/backup-$(date +%Y%m%d)

# Export specific collection
gcloud firestore export gs://your-bucket/backup-$(date +%Y%m%d) \
  --collection-ids=users,pets,appointments
```

### 3. Disaster Recovery
- **Multi-region deployment** for high availability
- **Cross-region replication** for data redundancy
- **Automated failover** for service continuity

---

This database design provides a robust, scalable foundation for the PetCare application with proper indexing, security, and performance optimization strategies.
