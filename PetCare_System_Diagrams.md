# PetCare System Diagrams

## 1. System Architecture Diagram

```mermaid
graph TB
    subgraph "Client Layer"
        A[Pet Owner App] 
        B[Veterinarian App]
        C[Shelter Owner App]
        D[Admin App]
        E[Web Interface]
    end
    
    subgraph "Application Layer"
        F[Flutter Framework]
        G[Provider State Management]
        H[Service Layer]
    end
    
    subgraph "Firebase Backend"
        I[Firebase Auth]
        J[Firestore Database]
        K[Firebase Storage]
        L[Firebase Messaging]
    end
    
    subgraph "External Services"
        M[Payment Gateway]
        N[Email Service]
        O[Push Notifications]
    end
    
    A --> F
    B --> F
    C --> F
    D --> F
    E --> F
    
    F --> G
    G --> H
    
    H --> I
    H --> J
    H --> K
    H --> L
    
    H --> M
    H --> N
    H --> O
```

## 2. User Role Flow Diagram

```mermaid
flowchart TD
    Start([User Opens App]) --> Auth{Authenticated?}
    Auth -->|No| Login[Login/Register]
    Auth -->|Yes| Role{Check User Role}
    
    Login --> Role
    
    Role -->|Pet Owner| PO[Pet Owner Dashboard]
    Role -->|Veterinarian| Vet[Veterinarian Dashboard]
    Role -->|Shelter Owner| SO[Shelter Owner Dashboard]
    Role -->|Admin| Admin[Admin Dashboard]
    
    PO --> PO1[Manage Pets]
    PO --> PO2[Book Appointments]
    PO --> PO3[Browse Store]
    PO --> PO4[View Adoptions]
    
    Vet --> Vet1[Manage Patients]
    Vet --> Vet2[Schedule Appointments]
    Vet --> Vet3[Create Health Records]
    Vet --> Vet4[View Analytics]
    
    SO --> SO1[Manage Pet Listings]
    SO --> SO2[Process Adoptions]
    SO --> SO3[Create Success Stories]
    SO --> SO4[Manage Volunteers]
    
    Admin --> Admin1[User Management]
    Admin --> Admin2[System Analytics]
    Admin --> Admin3[Store Management]
    Admin --> Admin4[Content Moderation]
```

## 3. Pet Management Data Flow

```mermaid
sequenceDiagram
    participant PO as Pet Owner
    participant UI as Flutter UI
    participant PS as PetService
    participant FS as Firestore
    participant SS as Storage
    
    PO->>UI: Add New Pet
    UI->>PS: createPet(petData)
    PS->>FS: Save pet document
    FS-->>PS: Document ID
    PS->>UI: Return success
    
    PO->>UI: Upload Pet Photo
    UI->>SS: Upload image file
    SS-->>UI: Image URL
    UI->>PS: addPhotoToPet(petId, imageUrl)
    PS->>FS: Update pet document
    FS-->>PS: Success
    PS->>UI: Photo added
    UI->>PO: Pet updated
```

## 4. Appointment Booking Flow

```mermaid
flowchart TD
    A[Pet Owner wants to book appointment] --> B[Select Pet]
    B --> C[Choose Veterinarian]
    C --> D[Select Date & Time]
    D --> E{Time Slot Available?}
    E -->|No| F[Show Alternative Times]
    F --> D
    E -->|Yes| G[Enter Appointment Details]
    G --> H[Confirm Booking]
    H --> I[Create Appointment Record]
    I --> J[Schedule Notifications]
    J --> K[Send Confirmation]
    K --> L[Update Veterinarian Calendar]
    L --> M[Appointment Booked]
```

## 5. Database Entity Relationship Diagram

```mermaid
erDiagram
    USERS ||--o{ PETS : owns
    USERS ||--o{ APPOINTMENTS : books
    USERS ||--o{ APPOINTMENTS : provides
    USERS ||--o{ PET_LISTINGS : creates
    USERS ||--o{ ADOPTION_REQUESTS : submits
    USERS ||--o{ ADOPTION_REQUESTS : receives
    
    PETS ||--o{ APPOINTMENTS : has
    PETS ||--o{ HEALTH_RECORDS : has
    
    PET_LISTINGS ||--o{ ADOPTION_REQUESTS : generates
    
    USERS {
        string id PK
        string email
        string firstName
        string lastName
        string role
        string phoneNumber
        string profileImageUrl
        timestamp createdAt
        boolean isActive
    }
    
    PETS {
        string id PK
        string ownerId FK
        string name
        string species
        string breed
        string gender
        timestamp dateOfBirth
        string healthStatus
        array photoUrls
        timestamp createdAt
        boolean isActive
    }
    
    APPOINTMENTS {
        string id PK
        string petOwnerId FK
        string petId FK
        string veterinarianId FK
        timestamp appointmentDate
        string timeSlot
        string type
        string status
        string reason
        string diagnosis
        number cost
        timestamp createdAt
    }
    
    PET_LISTINGS {
        string id PK
        string shelterOwnerId FK
        string name
        string type
        string breed
        string status
        string description
        array photoUrls
        timestamp createdAt
        boolean isActive
    }
    
    ADOPTION_REQUESTS {
        string id PK
        string petListingId FK
        string petOwnerId FK
        string shelterOwnerId FK
        string reasonForAdoption
        string status
        timestamp createdAt
        boolean isActive
    }
    
    STORE_ITEMS {
        string id PK
        string name
        string description
        number price
        string category
        array imageUrls
        string brand
        boolean isInStock
        number rating
        timestamp createdAt
        boolean isActive
    }
```

## 6. Authentication Flow Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant A as AuthService
    participant FA as Firebase Auth
    participant FS as Firestore
    participant UI as UI Components
    
    U->>A: Login Request
    A->>FA: signInWithEmailAndPassword
    FA-->>A: User Credentials
    A->>FS: Get User Document
    FS-->>A: User Data
    A->>A: Parse UserModel
    A->>UI: Update Auth State
    UI->>U: Navigate to Dashboard
    
    Note over U,UI: User is now authenticated and role-based navigation occurs
```

## 7. Store Purchase Flow

```mermaid
flowchart TD
    A[Browse Store] --> B[Filter Products]
    B --> C[View Product Details]
    C --> D[Add to Cart]
    D --> E{Continue Shopping?}
    E -->|Yes| A
    E -->|No| F[Review Cart]
    F --> G[Proceed to Checkout]
    G --> H[Enter Payment Details]
    H --> I[Validate Payment]
    I --> J{Payment Success?}
    J -->|No| K[Show Error]
    K --> H
    J -->|Yes| L[Create Order]
    L --> M[Update Inventory]
    M --> N[Send Confirmation]
    N --> O[Order Complete]
```

## 8. Analytics Data Flow

```mermaid
graph LR
    subgraph "User Actions"
        A[Item View]
        B[Item Click]
        C[Search Query]
        D[Favorite Action]
    end
    
    subgraph "Analytics Service"
        E[Track Event]
        F[Update Counters]
        G[Store in Firestore]
    end
    
    subgraph "Analytics Storage"
        H[Item Views Collection]
        I[Item Clicks Collection]
        J[Search Queries Collection]
        K[User Interests Collection]
    end
    
    subgraph "Admin Dashboard"
        L[View Analytics]
        M[Generate Reports]
        N[Export Data]
    end
    
    A --> E
    B --> E
    C --> E
    D --> E
    
    E --> F
    F --> G
    
    G --> H
    G --> I
    G --> J
    G --> K
    
    H --> L
    I --> L
    J --> L
    K --> L
    
    L --> M
    M --> N
```

## 9. Notification System Flow

```mermaid
sequenceDiagram
    participant AS as AppointmentService
    participant NS as NotificationService
    participant LN as Local Notifications
    participant PN as Push Notifications
    participant U as User Device
    
    AS->>NS: Schedule Appointment Reminders
    NS->>LN: Schedule 24h Reminder
    NS->>LN: Schedule 1h Reminder
    
    Note over LN: Local notifications scheduled
    
    LN->>U: Show 24h Reminder
    LN->>U: Show 1h Reminder
    
    AS->>NS: Cancel Appointment
    NS->>LN: Cancel All Reminders
    LN->>U: Reminders Cancelled
```

## 10. Multi-Platform Architecture

```mermaid
graph TB
    subgraph "Development Environment"
        A[Flutter SDK]
        B[Dart Language]
        C[Provider Package]
        D[Firebase SDK]
    end
    
    subgraph "Target Platforms"
        E[Android APK]
        F[iOS App]
        G[Web App]
        H[Windows App]
        I[macOS App]
        J[Linux App]
    end
    
    subgraph "Shared Codebase"
        K[Models]
        L[Services]
        M[UI Components]
        N[Business Logic]
    end
    
    A --> E
    A --> F
    A --> G
    A --> H
    A --> I
    A --> J
    
    B --> K
    B --> L
    B --> M
    B --> N
    
    C --> K
    C --> L
    C --> M
    C --> N
    
    D --> K
    D --> L
    D --> M
    D --> N
```

These diagrams provide a comprehensive visual representation of the PetCare system architecture, data flows, and user interactions, complementing the detailed documentation provided earlier.
