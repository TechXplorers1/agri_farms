import 'package:flutter/foundation.dart';

import 'dart:convert';
import '../models/booking_dto.dart';
import '../services/api_service.dart';

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
  final Map<String, dynamic> details;
  final String? providerId;
  final String? farmerId;
  final DateTime rawBookingDate;
  final DateTime? rawScheduledStartTime;

  BookingDetails({
    required this.id,
    required this.title,
    required this.date,
    required this.price,
    required this.status,
    required this.category,
    this.details = const {},
    this.providerId,
    this.farmerId,
    required this.rawBookingDate,
    this.rawScheduledStartTime,
  });

  factory BookingDetails.fromDTO(BookingDTO dto) {
    String priceStr = dto.totalAmount != null ? '₹${dto.totalAmount!.toStringAsFixed(0)}' : 'On Request';
    BookingCategory cat = BookingCategory.all;
    if (dto.assetType == 'Transport') cat = BookingCategory.transport;
    else if (dto.assetType == 'Equipment') cat = BookingCategory.rentals;
    else if (dto.assetType == 'Service') cat = BookingCategory.services;
    else if (dto.assetType == 'Workers') cat = BookingCategory.farmWorkers;
    
    Map<String, dynamic> parsedDetails = {};
    if (dto.notes != null && dto.notes!.isNotEmpty) {
      try {
        parsedDetails = jsonDecode(dto.notes!);
      } catch(e) {}
    }
    
    String title = "Booking";
    if (parsedDetails.containsKey('Service')) title = '${parsedDetails['Service']} Booking';
    else if (parsedDetails.containsKey('Equipment')) title = '${parsedDetails['Equipment']} Rental';
    else if (parsedDetails.containsKey('Vehicle Type')) title = '${parsedDetails['Vehicle Type']} Service';
    else if (parsedDetails.containsKey('Provider')) title = parsedDetails['Provider'];
    else if (cat == BookingCategory.farmWorkers) title = 'Farm Workers Request';
    
    return BookingDetails(
      id: dto.bookingId ?? '',
      title: title,
      date: dto.scheduledStartTime?.toString().split(' ')[0] ?? dto.bookingDate?.toString().split(' ')[0] ?? '',
      price: priceStr,
      status: dto.status ?? 'Pending',
      category: cat,
      providerId: dto.providerId,
      farmerId: dto.farmerId,
      details: parsedDetails,
      rawBookingDate: dto.bookingDate ?? DateTime.now(),
      rawScheduledStartTime: dto.scheduledStartTime,
    );
  }
}

class BookingManager extends ChangeNotifier {
  static final BookingManager _instance = BookingManager._internal();
  factory BookingManager() => _instance;

  final ApiService _apiService = ApiService();

  BookingManager._internal() {
    // Optionally fetch initial bookings if a user ID is known
  }

  List<BookingDetails> _bookings = [];
  bool isLoading = false;

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

  Future<void> fetchFarmerBookings(String farmerId) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getFarmerBookings(farmerId);
      List<BookingDTO> fetchedDTOs = (response as List).map((e) => BookingDTO.fromJson(e)).toList();
      _bookings = fetchedDTOs.map((dto) => BookingDetails.fromDTO(dto)).toList();
      // Sort newest first
      _bookings.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      print('Error fetching bookings: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProviderBookings(String providerId) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getProviderBookings(providerId);
      List<BookingDTO> fetchedDTOs = (response as List).map((e) => BookingDTO.fromJson(e)).toList();
      _bookings = fetchedDTOs.map((dto) => BookingDetails.fromDTO(dto)).toList();
      // Sort newest first
      _bookings.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      print('Error fetching provider bookings: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createBooking(BookingDTO dto) async {
    try {
      final response = await _apiService.createBooking(dto.toJson());
      final newDto = BookingDTO.fromJson(response);
      _bookings.insert(0, BookingDetails.fromDTO(newDto));
      notifyListeners();
    } catch (e) {
      print('Error creating booking: $e');
      throw e;
    }
  }

  // Fallback for backwards compatibility while migrating screens
  void addBooking(BookingDetails booking) {
    _bookings.insert(0, booking);
    notifyListeners();
  }
  
  void clearBookings() {
    _bookings.clear();
    notifyListeners();
  }

  Future<void> updateBookingStatus(String id, String newStatus, {String? providerId}) async {
    try {
      await _apiService.updateBookingStatus(id, newStatus);
      // Immediately update local state for faster perceived performance
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
          farmerId: old.farmerId,
          rawBookingDate: old.rawBookingDate,
          rawScheduledStartTime: old.rawScheduledStartTime,
        );
        notifyListeners();
      }
      
      // Also fetch from server to guarantee sync
      if (providerId != null) {
        await fetchProviderBookings(providerId);
      }
    } catch (e) {
      print('Error updating status: $e');
    }
  }
}
