import 'package:flutter/foundation.dart';

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

  BookingDetails({
    required this.id,
    required this.title,
    required this.date,
    required this.price,
    required this.status,
    required this.category,
    this.details = const {},
  });
}

class BookingManager extends ChangeNotifier {
  static final BookingManager _instance = BookingManager._internal();
  factory BookingManager() => _instance;

  BookingManager._internal();

  final List<BookingDetails> _bookings = [];

  List<BookingDetails> get bookings => List.unmodifiable(_bookings);

  List<BookingDetails> getBookingsByCategory(BookingCategory category) {
    if (category == BookingCategory.all) {
      return _bookings;
    }
    return _bookings.where((b) => b.category == category).toList();
  }

  void addBooking(BookingDetails booking) {
    _bookings.insert(0, booking); // Add to top
    notifyListeners();
  }
  
  // Method to clear dummy data or reset
  void clearBookings() {
    _bookings.clear();
    notifyListeners();
  }
}
