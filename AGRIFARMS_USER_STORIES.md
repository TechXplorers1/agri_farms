AGRI FARMS — PRODUCT USER STORY & UI SPECIFICATION
Developer-Ready Specification Document

This document outlines the complete product user stories and UI specifications for the Agri Farms platform. It is based on the current codebase and intended to guide developers in maintaining and expanding the Flutter-based agricultural ecosystem.

1. Global Header & Navigation
• Greeting: "Namaste, [User Name]"
• Location Display: Village & District (e.g., "Your Village, Your District")
• Action Icons: Shopping Cart | Notifications (with badge count)
• Persistent Search Bar: Search for seeds, tractors, spraying, etc.
• Bottom Navigation: Home | Market | Rentals | Community | Profile

2. Home Page — Farmer Landing
• Hero Section: User greeting, location, and search bar
• Quick Service Access:
  - Book Services (Ploughing, Harvesting, Farm Workers)
  - Book Transport (Mini Truck, Tractor Trolley, Full Truck)
  - Rent Equipment (Tractors, Harvesters, Sprayers)
• Agri Tools Scrollable Strip:
  - Crop Advisory
  - Fertilizer Calculator
  - Pesticide Calculator (New)
  - Farming Calculator (New)
• Promotional Banners: "Free Soil Testing", "New Tractors Available"
• Info Widgets: Mandi Prices (Rates) | Weather Widget (Current temp & Forecast)
• Community Snippet: Recent questions (e.g., "How to treat leaf curl?")

3. Authentication
• Login Screen:
  - Mobile Number input (+91 prefix)
  - Full Name input
  - Role Selection Dropdown: General User, Farmer, Farm Worker, Vehicle Provider
  - "Get OTP" Trigger
• OTP Verification:
  - 4-Digit OTP entry
  - Auto-navigation to Home upon success

4. Service Booking (Agri Services)
• Service Categories Grid:
  - Ploughing, Harvesting, Farm Workers, Drone Spraying, Irrigation, Soil Testing, Vet Care
• Navigation: Tapping a category opens the Service Providers listing for that specific service type.
• Top Action: "My Bookings" quick access.

5. Equipment Rentals
• Layout: Mixed Grid and List
• Toggle Header: Switch between "Rent Equipment" and "My Rentals"
• Equipment Categories: Tractors, Harvesters, Sprayers, Trolleys (with availability counts)
• 'Nearby Equipment' Section:
  - Detailed cards with Image, Model Name (e.g., Mahindra Tractor 575 DI)
  - Availability Tag (Green "Available")
  - Hourly Rate (e.g., ₹500/hr) and Rating (4.7 stars)
  - Distance & Provider Name (e.g., "Suresh Patel • 4 km")

6. Service Providers Listing
• Dynamic Listing: Shows providers based on selected category (Service or Transport)
• Provider Card:
  - Name, Service Type, Rating
  - Distance from user
  - "Book Now" / "Call" actions

7. Upload & Provider Onboarding
• Access: Available to "Vehicle Provider", "Farmer", "Farm Worker" roles via specific screens (e.g., Equipment Rentals top bar).
• Category Context: Upload Transport vs. Upload Equipment vs. Farm Worker Profile.
• Input Fields (General):
  - Upload Picture
  - Item Type Selection (Chips: Tractor, Mini Truck, etc.)
  - Name/Title (e.g., Mahindra Tractor)
  - Capacity/Specs (e.g., 45 HP or 2 Tons)
  - Rental Price (per hour/trip)
  - Description
• Input Fields (Farm Worker Specific):
  - Group Name
  - Male/Female Worker Counts
  - Price per Male/Female worker
• Submission: "Upload Done" adds item to the marketplace (mocked).

8. Agri Tools & Calculators
• Fertilizer Calculator: Input land area and crop type to get dosage.
• Pesticide Calculator: Dosage recommendations.
• Crop Advisory: Best practices and seasonal advice.
• Farming Calculator: General yield or cost estimation.

9. User Profile & Settings
• Profile Sections:
  - My Services (Manage listed services)
  - My Rentals (History of rented equipment)
  - Help & Support
  - Terms & Privacy
  - Notification Settings
  - Language Selection
• Edit Profile: Update Name, Location details.

10. Non-Functional Requirements
• Platform: Flutter (Android/iOS)
• Design System: Green/Nature-themed palette (Primary: #00AA55, Backgrounds: Light Green/White)
• Localization: Structure ready for multi-language support (English/Hindi).
• Performance: Optimized for low-bandwidth rural areas.
