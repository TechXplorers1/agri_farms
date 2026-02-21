import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../../services/api_service.dart'; // Import ApiService

class VerifyOtpScreen extends StatefulWidget {
  final String mobileNumber;
  final String fullName;
  final String role;
  final bool isLogin;

  const VerifyOtpScreen({
    super.key,
    required this.mobileNumber,
    required this.fullName,
    required this.role,
    this.isLogin = false, // Default false for backward compatibility if needed
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isButtonEnabled = false;
  bool _isLoading = false; // Add loading state
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    for (var controller in _controllers) {
      controller.addListener(_validateInput);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _validateInput() {
    bool allFilled = _controllers.every((controller) => controller.text.isNotEmpty);
    setState(() {
      _isButtonEnabled = allFilled;
    });
  }

  Future<void> _verify() async {
    if (_isButtonEnabled) {
      setState(() {
        _isLoading = true;
      });

      // Logic would go here to actually verify the OTP - Mock success assuming OTP is correct for now
      
      try {
        final apiService = ApiService();
        dynamic user;

        if (widget.isLogin) {
          // Attempt to fetch existing user
          try {
            user = await apiService.getUserByPhone(widget.mobileNumber);
          } catch (e) {
            if (e.toString().contains('404') || e.toString().contains('Not Found')) {
              throw Exception('User not found. Please Sign Up first.');
            } else {
              throw Exception('Failed to authenticate: $e');
            }
          }
        } else {
          // Sign Up - Create user in backend
          try {
            // First check if user already exists
            user = await apiService.getUserByPhone(widget.mobileNumber);
            throw Exception('User already exists. Please Login instead.');
          } catch (e) {
            if (e.toString().contains('404') || e.toString().contains('Not Found')) {
              // Create user
              user = await apiService.createUser({
                'fullName': widget.fullName,
                'phoneNumber': widget.mobileNumber,
                'role': widget.role,
              });
            } else {
              rethrow;
            }
          }
        }

        final String userRole = user['role'] ?? widget.role;
        final String userName = user['fullName'] ?? widget.fullName;

        // Save local session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', userName);
        await prefs.setString('user_mobile', widget.mobileNumber);
        await prefs.setString('user_role', userRole); 
        if (user['userId'] != null) {
          await prefs.setString('user_id', user['userId'].toString());
        }
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomeScreen(userRole: userRole)),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create account: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
       if (index > 0) {
         _focusNodes[index - 1].requestFocus();
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9), // Light Green
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined, // Shield Check
                  size: 50,
                  color: Color(0xFF00AA55),
                ),
              ),
              const SizedBox(height: 30),
              // Title
              const Text(
                'Verify OTP',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              // Subtitle
              Text(
                'Enter the 6-digit code sent to\n+91${widget.mobileNumber}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // OTP Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return Container(
                    width: 45,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _controllers[index].text.isNotEmpty
                            ? const Color(0xFF00AA55)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      onChanged: (value) => _onChanged(value, index),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
               // Timer
              Text(
                'Resend OTP in ${_secondsRemaining}s',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isButtonEnabled ? _verify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isButtonEnabled ? Colors.black : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : const Text(
                    'Verify',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
