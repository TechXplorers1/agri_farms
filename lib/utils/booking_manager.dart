import 'package:flutter/foundation.dart';
import '../data/services/api_service.dart';
import '../data/models/booking_model.dart';

enum BookingCategory {
  all,
  farmWorkers,
  rentals,
  transport,
  services,
}

class BookingDetails {
  final String id;
  final String title;
  final String date;
  final String price;
  final String status;
  final BookingCategory category;
  final Map<String, dynamic> details; // Extra details like worker counts, slots etc.
  final String? providerId;

  BookingDetails({
    required this.id,
    required this.title,
    required this.date,
    required this.price,
    required this.status,
    required this.category,
    this.details = const {},
    this.providerId,
  });
}

class BookingManager extends ChangeNotifier {
  static final BookingManager _instance = BookingManager._internal();
  factory BookingManager() => _instance;

  BookingManager._internal() {
      // Initialize with some dummy data or fetch from API in future
      // For now, keeping the dummy data but adding API integration for new bookings
      _bookings.addAll([
          BookingDetails(
            id: '101', 
            title: 'Farm Workers Request', 
            date: '2025-01-12', 
            price: '₹2200',  
            status: 'Pending', 
            category: BookingCategory.farmWorkers,
            providerId: '2', 
            details: {
              'male_count': 2,
              'female_count': 3,
              'duration': '8 hours',
              'task_type': 'Weeding'
            }
          ),
          // ... (Existing dummy data kept for UI testing)
      ]);
  }

  final ApiService _apiService = ApiService();

  final List<BookingDetails> _bookings = [];

  List<BookingDetails> get bookings => List.unmodifiable(_bookings);

  List<BookingDetails> getBookingsByCategory(BookingCategory category) {
    if (category == BookingCategory.all) {
      return _bookings;
    }
    return _bookings.where((b) => b.category == category).toList();
  }
  
  List<BookingDetails> getBookingsForProvider(String providerId) {
    return _bookings.where((b) => b.providerId == providerId).toList();
  }

  Future<void> addBooking(BookingDetails booking) async {
    try {
      // Map BookingDetails to backend Booking model
      // Note: mapping is best effort as BookingDetails is UI centric
      final backendBooking = Booking(
        farmerId: 'user-123', // Hardcoded for now
        providerId: booking.providerId ?? 'unknown',
        assetId: booking.providerId, // Using providerId as assetId for now based on UI usage
        assetType: booking.title,
        status: booking.status.toUpperCase(),
        totalAmount: double.tryParse(booking.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
        bookingDate: booking.date,
      );

      final createdBooking = await _apiService.createBooking(backendBooking);
      print('Booking created on backend with ID: ${createdBooking.bookingId}');
      
      // Update the local booking with the ID from backend if needed
      // For now just adding the local object
    } catch (e) {
      print('Failed to sync booking to backend: $e');
    }

    _bookings.insert(0, booking); // Add to top
    notifyListeners();
  }
  
  // Method to clear dummy data or reset
  void clearBookings() {
    _bookings.clear();
    notifyListeners();
  }

  void updateBookingStatus(String id, String newStatus) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      final old = _bookings[index];
      _bookings[index] = BookingDetails(
        id: old.id,
        title: old.title,
        date: old.date,
        price: old.price,
        status: newStatus,
        category: old.category,
        details: old.details,
        providerId: old.providerId,
      );
      notifyListeners();
    }
  }
}
