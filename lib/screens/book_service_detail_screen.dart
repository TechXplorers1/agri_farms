import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/booking_manager.dart';
import '../utils/ui_utils.dart';
import 'booking_confirmation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/booking_dto.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class BookServiceDetailScreen extends StatefulWidget {
  final String providerName;
  final String serviceName;
  final String providerId;
  final String assetId;
  final String priceInfo;
  final String? ownerProfileImage;

  const BookServiceDetailScreen({
    super.key,
    required this.providerName,
    required this.serviceName,
    required this.providerId,
    required this.assetId,
    required this.priceInfo,
    this.ownerProfileImage,
  });

  @override
  State<BookServiceDetailScreen> createState() => _BookServiceDetailScreenState();
}

class _BookServiceDetailScreenState extends State<BookServiceDetailScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, String?> _fieldErrors = {};
  
  // GlobalKeys for scrolling
  final GlobalKey _qtySectionKey = GlobalKey();
  final GlobalKey _addressSectionKey = GlobalKey();
  final GlobalKey _dateSectionKey = GlobalKey();
  final GlobalKey _timeSectionKey = GlobalKey();
  DateTime? _selectedDate;
  List<BookingDTO> _existingBookings = [];
  bool _isLoadingBookings = false;
  bool _isSubmitting = false;

  // Time Slot Configuration
  final int _startHour = 6;
  final int _endHour = 20;
  int? _selectedStartHour;
  int _durationHours = 1;

  List<int> get _selectedSlots {
    if (_selectedStartHour == null) return [];
    return List.generate(_durationHours, (i) => _selectedStartHour! + i);
  }

  // Electrician Specific Fields
  final List<String> _electricianPurposes = [
    'Pump Motor Repair',
    'Wiring Installation/Repair',
    'Solar Panel Maintenance',
    'Generator Servicing',
    'Control Panel Troubleshooting',
    'Lighting Installation',
    'Battery/Inverter Maintenance',
    'Others'
  ];

  final List<String> _electricianAssets = [
    'Submersible Pump',
    'Monoblock Pump',
    'Diesel Generator',
    'Solar System',
    'Farmhouse Wiring',
    'Cold Storage Unit',
    'Poultry House Ventilation',
    'Others'
  ];

  String? _selectedPurpose;
  String? _selectedAssetType;
  final TextEditingController _customPurposeController = TextEditingController();
  final TextEditingController _customAssetController = TextEditingController();

  // Real Logic: Check if a slot is blocked
  bool _isSlotBlocked(int hour) {
    if (_selectedDate == null) return false;
    
    DateTime slotStart = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, hour);
    DateTime slotEnd = slotStart.add(const Duration(hours: 1)); 

    // Block past time slots for today
    if (slotStart.isBefore(DateTime.now())) {
      return true;
    }

    for (var booking in _existingBookings) {
      if (booking.scheduledStartTime != null && booking.scheduledEndTime != null) {
        if (slotStart.isBefore(booking.scheduledEndTime!) && slotEnd.isAfter(booking.scheduledStartTime!)) {
           if (booking.status != 'CANCELLED' && booking.status != 'REJECTED') {
             return true;
           }
        }
      }
    }
    return false;
  }

  void _onSlotTap(int hour) {
    if (_selectedDate == null) {
      UiUtils.showCenteredToast(context, 'Please select a date first', isError: true);
      return;
    }
    if (_isSlotBlocked(hour)) {
      UiUtils.showCenteredToast(context, 'This slot is already booked', isError: true);
      return;
    }

    setState(() {
      _selectedStartHour = hour;
      _durationHours = 1;
    });
  }

  bool _isRangeAvailable(int startHour, int duration) {
    for (int i = 0; i < duration; i++) {
      if (_isSlotBlocked(startHour + i) || (startHour + i) >= _endHour) {
        return false;
      }
    }
    return true;
  }

  String _formatTime(int hour) {
      if (hour == 12) return '12 PM';
      if (hour > 12) return '${hour - 12} PM';
      return '$hour AM';
  }

  String _formatTimeRange(int hour) {
    return '${_formatTime(hour)} - ${_formatTime(hour + 1)}';
  }


  @override
  void initState() {
    super.initState();
    _loadAddress();
    _fetchAssetBookings();
  }

  Future<void> _fetchAssetBookings() async {
    setState(() {
      _isLoadingBookings = true;
    });
    try {
      final response = await ApiService().getAssetBookings(widget.assetId);
      final List<dynamic> data = response as List<dynamic>;
      setState(() {
        _existingBookings = data.map((json) => BookingDTO.fromJson(json)).toList();
      });
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    _quantityController.dispose();
    _customPurposeController.dispose();
    _customAssetController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _addressController.text = prefs.getString('user_address') ?? '';
      if (_addressController.text.isEmpty) {
        // Fallback for demo if address not set, set empty to prompt user
        _addressController.text = '';
      }
    });
  }

  void _scrollToField(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00AA55),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedStartHour = null;
        _durationHours = 1;
      });
    }
  }



  void _confirmBooking() async {
    bool isElectrician = widget.serviceName == 'Electricians';
    bool isQtyValid = isElectrician 
      ? (_selectedPurpose != null && (_selectedPurpose != 'Others' || _customPurposeController.text.isNotEmpty)) &&
        (_selectedAssetType != null && (_selectedAssetType != 'Others' || _customAssetController.text.isNotEmpty))
      : _quantityController.text.isNotEmpty;

    if (_selectedDate != null && isQtyValid && _addressController.text.isNotEmpty && _selectedSlots.isNotEmpty) {
      setState(() {
        _isSubmitting = true;
      });
      // Save address for future use if it changed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_address', _addressController.text);

      String bookingId = DateTime.now().millisecondsSinceEpoch.toString();
      String dateStr = _selectedDate.toString().split(' ')[0];
      
      // Format time slots
      String timeStr;
      if (_selectedSlots.length == 1) {
        timeStr = _formatTimeRange(_selectedSlots.first);
      } else {
         timeStr = '${_formatTime(_selectedSlots.first)} - ${_formatTime(_selectedSlots.last + 1)}'; // Simplified range display
      }

      final String? userId = prefs.getString('user_id');
      final String? userName = prefs.getString('user_name');

      final Map<String, dynamic> notesMap = {
        'Booked By': userName ?? 'Unknown User',
        'Provider': widget.providerName,
        'Service': widget.serviceName,
        'Location': _addressController.text,
        'Preferred Time': timeStr,
        'Notes': _notesController.text,
      };

      if (isElectrician) {
        notesMap['Purpose of Visit'] = _selectedPurpose == 'Others' ? _customPurposeController.text : _selectedPurpose;
        notesMap['Asset to Repair'] = _selectedAssetType == 'Others' ? _customAssetController.text : _selectedAssetType;
      } else {
        notesMap['Number of Acres'] = _quantityController.text;
      }

      DateTime start = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedSlots.first);
      DateTime end = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedSlots.last + 1);

      BookingDTO dto = BookingDTO(
        farmerId: userId,
        providerId: widget.providerId,
        assetId: widget.assetId,
        assetType: 'Service',
        bookingDate: DateTime.now(),
        scheduledStartTime: start,
        scheduledEndTime: end,
        status: 'PENDING',
        totalAmount: 0.0, // On Request
        addressText: _addressController.text,
        notes: jsonEncode(notesMap),
      );
      
      try {
        final newBooking = await BookingManager().createBooking(dto);
        
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingConfirmationScreen(
              bookingId: newBooking.bookingId ?? "ID-Error",
              bookingTitle: widget.serviceName,
            ),
          ),
        );
      } catch(e) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        UiUtils.showCustomAlert(context, 'Failed to submit booking: $e', isError: true);
      }
    } else {
      setState(() {
        _fieldErrors.clear();
        if (isElectrician) {
          if (_selectedPurpose == null) _fieldErrors['purpose'] = 'Please select purpose of visit';
          else if (_selectedPurpose == 'Others' && _customPurposeController.text.isEmpty) _fieldErrors['purpose_custom'] = 'Please specify purpose';
          
          if (_selectedAssetType == null) _fieldErrors['asset'] = 'Please select asset type';
          else if (_selectedAssetType == 'Others' && _customAssetController.text.isEmpty) _fieldErrors['asset_custom'] = 'Please specify asset name';
        } else {
          if (_quantityController.text.isEmpty) {
            _fieldErrors['qty'] = 'Please enter number of acres';
          }
        }
        
        if (_addressController.text.isEmpty) {
          _fieldErrors['address'] = 'Please enter service address';
        }
        if (_selectedDate == null) {
          _fieldErrors['date'] = 'Please select a date';
        }
        if (_selectedSlots.isEmpty) {
          _fieldErrors['slots'] = 'Please select at least one time slot';
        }
      });

      // Scroll to first error
      if (_fieldErrors.containsKey('purpose') || _fieldErrors.containsKey('purpose_custom') || 
          _fieldErrors.containsKey('asset') || _fieldErrors.containsKey('asset_custom') ||
          _fieldErrors.containsKey('qty')) {
        _scrollToField(_qtySectionKey);
      } else if (_fieldErrors.containsKey('address')) {
        _scrollToField(_addressSectionKey);
      } else if (_fieldErrors.containsKey('date')) {
        _scrollToField(_dateSectionKey);
      } else if (_fieldErrors.containsKey('slots')) {
        _scrollToField(_timeSectionKey);
      }

      UiUtils.showCenteredToast(context, AppLocalizations.of(context)!.fillAllDetails, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Book ${widget.serviceName}'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9), // Light Green
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                   GestureDetector(
                     onTap: () => _showFullImage(context, widget.ownerProfileImage, widget.providerName),
                     child: CircleAvatar(
                       radius: 30, // Increased size
                       backgroundColor: Colors.white,
                       backgroundImage: widget.ownerProfileImage != null
                           ? NetworkImage(ApiConfig.getFullImageUrl(widget.ownerProfileImage))
                           : null,
                       child: widget.ownerProfileImage == null
                           ? const Icon(Icons.agriculture, color: Color(0xFF00AA55), size: 30)
                           : null,
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           widget.providerName,
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           widget.priceInfo,
                           style: TextStyle(color: Colors.green[800], fontSize: 13, fontWeight: FontWeight.w600),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Requirement Details (Conditional)
            Text(
              key: _qtySectionKey,
              'Requirement Details',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: (_fieldErrors.containsKey('qty') || _fieldErrors.containsKey('purpose') || _fieldErrors.containsKey('asset')) ? Colors.red : Colors.black87
              ),
            ),
            const SizedBox(height: 12),
            
            if (widget.serviceName == 'Electricians') ...[
              // Purpose of Visit
              _buildDropdownField(
                label: 'Purpose of Visit',
                hint: 'Choose purpose of visit',
                value: _selectedPurpose,
                items: _electricianPurposes,
                errorKey: 'purpose',
                onChanged: (val) => setState(() => _selectedPurpose = val),
              ),
              if (_selectedPurpose == 'Others') ...[
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _customPurposeController,
                  label: 'Specify Purpose',
                  hint: 'Enter your custom purpose...',
                  errorKey: 'purpose_custom',
                ),
              ],
              const SizedBox(height: 16),
              
              // Type of Asset
              _buildDropdownField(
                label: 'Type of Asset',
                hint: 'Choose type of asset/machinery',
                value: _selectedAssetType,
                items: _electricianAssets,
                errorKey: 'asset',
                onChanged: (val) => setState(() => _selectedAssetType = val),
              ),
              if (_selectedAssetType == 'Others') ...[
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _customAssetController,
                  label: 'Specify Asset Name',
                  hint: 'Enter asset/machinery name...',
                  errorKey: 'asset_custom',
                ),
              ],
            ] else ...[
              // Default Acreage Input
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  if (_fieldErrors.containsKey('qty')) setState(() => _fieldErrors.remove('qty'));
                },
                decoration: InputDecoration(
                  labelText: 'Number of Acres',
                  hintText: 'e.g. 2 Acres',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _fieldErrors.containsKey('qty') ? Colors.red : Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _fieldErrors.containsKey('qty') ? Colors.red : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _fieldErrors.containsKey('qty') ? Colors.red : const Color(0xFF00AA55), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ],
            
            const SizedBox(height: 24),

            // Address
            Text(
              key: _addressSectionKey,
              'Service Address (Mandatory)',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: _fieldErrors.containsKey('address') ? Colors.red : Colors.black87
              ),
            ),
             const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 3,
              onChanged: (_) {
                if (_fieldErrors.containsKey('address')) setState(() => _fieldErrors.remove('address'));
              },
              decoration: InputDecoration(
                hintText: 'Enter full address for service...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _fieldErrors.containsKey('address') ? Colors.red : Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _fieldErrors.containsKey('address') ? Colors.red : Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _fieldErrors.containsKey('address') ? Colors.red : const Color(0xFF00AA55), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),

            const SizedBox(height: 24),

             // Date Selection
            Text(
              key: _dateSectionKey,
              AppLocalizations.of(context)!.selectDate,
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: _fieldErrors.containsKey('date') ? Colors.red : Colors.black87
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                await _selectDate(context);
                if (_selectedDate != null && _fieldErrors.containsKey('date')) {
                  setState(() => _fieldErrors.remove('date'));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _fieldErrors.containsKey('date') ? Colors.red : Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: _selectedDate == null ? Colors.grey[400] : const Color(0xFF00AA55)),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null 
                          ? AppLocalizations.of(context)!.chooseDate 
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate == null ? Colors.grey[500] : Colors.black87,
                        fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),





            // Time Selection
            Text(
              key: _timeSectionKey,
              AppLocalizations.of(context)!.preferredTime,
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: _fieldErrors.containsKey('slots') ? Colors.red : Colors.black87
              ),
            ),
            if (_selectedDate == null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Select a date first to view available slots', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ),
            const SizedBox(height: 12),
            
            // Slots Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, 
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _endHour - _startHour, 
              itemBuilder: (context, index) {
                int hour = _startHour + index;
                bool isBlocked = _isSlotBlocked(hour);
                bool isSelected = _selectedSlots.contains(hour);

                return InkWell(
                  onTap: () {
                    _onSlotTap(hour);
                    if (_selectedSlots.isNotEmpty && _fieldErrors.containsKey('slots')) {
                      setState(() => _fieldErrors.remove('slots'));
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBlocked ? Colors.grey[200] : (isSelected ? const Color(0xFF00AA55) : Colors.white),
                      border: Border.all(
                        color: isBlocked 
                            ? Colors.transparent 
                            : (isSelected ? const Color(0xFF00AA55) : (_fieldErrors.containsKey('slots') ? Colors.red.withOpacity(0.5) : Colors.grey[300]!)),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _formatTimeRange(hour),
                      style: TextStyle(
                        color: isBlocked ? Colors.grey[400] : (isSelected ? Colors.white : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                        decoration: isBlocked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                );
              },
            ),

            if (_selectedStartHour != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Select Duration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildDurationButton(
                          icon: Icons.remove,
                          onPressed: _durationHours > 1 
                            ? () => setState(() => _durationHours--)
                            : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            '$_durationHours ${_durationHours == 1 ? 'Hour' : 'Hours'}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        _buildDurationButton(
                          icon: Icons.add,
                          onPressed: _isRangeAvailable(_selectedStartHour!, _durationHours + 1)
                            ? () => setState(() => _durationHours++)
                            : null,
                        ),
                      ],
                    ),
                    Text(
                      '${_formatTime(_selectedStartHour!)} to ${_formatTime(_selectedStartHour! + _durationHours)}',
                      style: const TextStyle(color: Color(0xFF00AA55), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (!_isRangeAvailable(_selectedStartHour!, _durationHours + 1) && (_selectedStartHour! + _durationHours) < _endHour)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Next slot is already booked or unavailable',
                    style: TextStyle(color: Colors.orange[800], fontSize: 12),
                  ),
                ),
            ],

            const SizedBox(height: 24),

            // Notes
             TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Any specific instructions...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 40),

            // Button
             SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0E21),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      AppLocalizations.of(context)!.confirmRequest,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String? imageUrl, String title) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  ApiConfig.getFullImageUrl(imageUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(40),
                    child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationButton({required IconData icon, VoidCallback? onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed == null ? Colors.grey[200] : const Color(0xFFE8F5E9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: onPressed == null ? Colors.grey[400] : const Color(0xFF00AA55)),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required String errorKey,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
        ),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _fieldErrors.containsKey(errorKey) ? Colors.red : Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _fieldErrors.containsKey(errorKey) ? Colors.red : Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _fieldErrors.containsKey(errorKey) ? Colors.red : const Color(0xFF00AA55), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (val) {
            onChanged(val);
            if (_fieldErrors.containsKey(errorKey)) setState(() => _fieldErrors.remove(errorKey));
            if (errorKey == 'purpose' && _fieldErrors.containsKey('purpose_custom')) setState(() => _fieldErrors.remove('purpose_custom'));
            if (errorKey == 'asset' && _fieldErrors.containsKey('asset_custom')) setState(() => _fieldErrors.remove('asset_custom'));
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String errorKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
        ),
        TextField(
          controller: controller,
          onChanged: (_) {
            if (_fieldErrors.containsKey(errorKey)) setState(() => _fieldErrors.remove(errorKey));
          },
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _fieldErrors.containsKey(errorKey) ? Colors.red : Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _fieldErrors.containsKey(errorKey) ? Colors.red : Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _fieldErrors.containsKey(errorKey) ? Colors.red : const Color(0xFF00AA55), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
