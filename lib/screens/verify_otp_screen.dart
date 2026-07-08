import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../services/api_service.dart';
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';


class VerifyOtpScreen extends StatefulWidget {
  final String mobileNumber;
  final String fullName;
  final String role;
  final bool isLogin;
  final String verificationId;

  const VerifyOtpScreen({
    super.key,
    required this.mobileNumber,
    required this.fullName,
    required this.role,
    required this.isLogin,
    required this.verificationId,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  late String _currentVerificationId;
  int _secondsRemaining = 30;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _otpController.addListener(_validateInput);
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _validateInput() {
    setState(() {
      _isButtonEnabled = _otpController.text.length == 6;
    });
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00AA55))),
          ),
        ],
      ),
    );
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await OTPWidget.sendOTP({
        'identifier': '91' + widget.mobileNumber,
      });
      
      if (response != null && response['type'] == 'success') {
        final String newReqId = response['message']?.toString() ?? '';
        setState(() {
          _currentVerificationId = newReqId;
        });
        _startTimer();
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code resent successfully.'),
              backgroundColor: Color(0xFF00AA55),
            ),
          );
        }
      } else {
        final errorMsg = response != null ? (response['message'] ?? 'Failed to send OTP') : 'Failed to send OTP';
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Error', e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (!_isButtonEnabled || _isLoading) return;

    final entered = _otpController.text.trim();
    if (entered.length != 6 || int.tryParse(entered) == null) {
      _showErrorDialog('Invalid OTP', 'Please enter a valid 6-digit code.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Verify OTP via MSG91 Widget SDK
      final response = await OTPWidget.verifyOTP({
        'reqId': _currentVerificationId,
        'otp': entered,
      });

      if (response != null && response['type'] == 'success') {
        // 2. On success, login/register user in the backend
        final apiService = ApiService();
        final role = widget.role.isNotEmpty ? widget.role : 'Farmer';
        final name = widget.fullName.isNotEmpty ? widget.fullName : 'User';

        final backendResponse = await apiService.staticLogin(
          mobileNumber: widget.mobileNumber,
          role: role,
          fullName: name,
          isLogin: widget.isLogin,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_phone', backendResponse['phoneNumber']?.toString() ?? widget.mobileNumber);
        await prefs.setString('user_role', backendResponse['role'] ?? role);
        await prefs.setString('user_name', backendResponse['fullName'] ?? name);
        await prefs.setString('user_id', backendResponse['userId']?.toString() ?? '');

        if (mounted) {
          setState(() => _isLoading = false);
          final finalRole = backendResponse['role'] ?? role;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomeScreen(userRole: finalRole),
            ),
            (route) => false,
          );
        }
      } else {
        final errorMsg = response != null ? (response['message'] ?? 'OTP verification failed') : 'OTP verification failed';
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Verification Failed', e.toString().replaceAll('Exception: ', ''));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B5E20)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF00AA55).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  size: 32,
                  color: Color(0xFF00AA55),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter Verification Code',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B5E20),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We have sent a 6-digit OTP code to verified number +91 ${widget.mobileNumber}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),
              
              // OTP Fields Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: Color(0xFF1B5E20),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        hintStyle: TextStyle(
                          color: Colors.grey[300],
                          letterSpacing: 8,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF00AA55), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Resend Timer Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _canResend 
                              ? "Didn't receive the code? " 
                              : "Resend code in ",
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                        _canResend
                            ? GestureDetector(
                                onTap: _resendCode,
                                child: const Text(
                                  "Resend OTP",
                                  style: TextStyle(
                                    color: Color(0xFF00AA55),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : Text(
                                "$_secondsRemaining s",
                                style: const TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isButtonEnabled && !_isLoading ? _verifyOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AA55),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF00AA55).withOpacity(0.5),
                    disabledForegroundColor: Colors.white.withOpacity(0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Verify & Proceed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
