import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/equipment_model.dart';
import '../models/transport_vehicle_model.dart';
import '../models/service_offering_model.dart';
import '../models/booking_model.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web/Windows
  // static const String baseUrl = 'http://10.0.2.2:8083/api'; 
  static const String baseUrl = 'http://localhost:8083/api'; 

  Future<List<Equipment>> getEquipment({String? category}) async {
    final uri = Uri.parse('$baseUrl/inventory/equipment').replace(queryParameters: category != null ? {'category': category} : {});
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Equipment.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load equipment');
    }
  }

  Future<Equipment> addEquipment(Equipment equipment) async {
    final response = await http.post(
      Uri.parse('$baseUrl/inventory/equipment'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(equipment.toJson()),
    );

    if (response.statusCode == 200) {
      return Equipment.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add equipment');
    }
  }

  Future<List<TransportVehicle>> getVehicles({String? type}) async {
    final uri = Uri.parse('$baseUrl/inventory/vehicles').replace(queryParameters: type != null ? {'type': type} : {});
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => TransportVehicle.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  Future<TransportVehicle> addVehicle(TransportVehicle vehicle) async {
    final response = await http.post(
      Uri.parse('$baseUrl/inventory/vehicles'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(vehicle.toJson()),
    );

    if (response.statusCode == 200) {
      return TransportVehicle.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add vehicle');
    }
  }

  Future<List<ServiceOffering>> getServices({String? type}) async {
    final uri = Uri.parse('$baseUrl/inventory/services').replace(queryParameters: type != null ? {'type': type} : {});
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => ServiceOffering.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load services');
    }
  }

  Future<ServiceOffering> addService(ServiceOffering service) async {
    final response = await http.post(
      Uri.parse('$baseUrl/inventory/services'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(service.toJson()),
    );

    if (response.statusCode == 200) {
      return ServiceOffering.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add service');
    }
  }

  Future<Booking> createBooking(Booking booking) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(booking.toJson()),
    );

    if (response.statusCode == 200) {
      return Booking.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create booking');
    }
  }
}
