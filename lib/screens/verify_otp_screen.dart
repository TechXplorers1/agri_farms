import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import '../../services/api_service.dart';
import '../utils/ui_utils.dart';

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
    required this.verificationId,
    this.isLogin = false, 
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isButtonEnabled = false;
  bool _isLoading = false; 
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
      _timer?.cancel(); // Cancel/stop the timer immediately upon clicking verify
      setState(() {
        _isLoading = true;
      });

      final String otpCode = _controllers.map((c) => c.text).join();

      try {
        // 1. Firebase Verification or Developer Bypass
        if (widget.verificationId == "mock_bypass_verification_id") {
          if (otpCode != '123456') {
            throw Exception('Invalid verification code. Use 123456 for demo bypass.');
          }
        } else {
          final PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: widget.verificationId,
            smsCode: otpCode,
          );

          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
          } on FirebaseAuthException catch (e) {
            throw Exception('Invalid OTP: ${e.message}');
          }
        }

        // 2. Backend Sync
        final apiService = ApiService();
        dynamic user;

        if (widget.isLogin) {
          // Attempt to fetch existing user
          try {
            user = await apiService.getUserByPhone(widget.mobileNumber);
          } catch (e) {
            if (e.toString().contains('404') || e.toString().contains('Not Found')) {
              throw Exception('User not found in database. Please Sign Up first.');
            } else {
              throw Exception('Failed to fetch user: $e');
            }
          }
        } else {
          // Sign Up - Create user in backend
          try {
            // Check if exists
            user = await apiService.getUserByPhone(widget.mobileNumber);
            // If exists, just login? Or throw? Usually login is fine if Firebase verified.
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
        await prefs.setString('user_phone', widget.mobileNumber);
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
          UiUtils.showCustomAlert(context, '$e', isError: true);
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
      backgroundColor: const Color(0xFFF5F7F2),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Brand Header with Gradient
            Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height < 700 ? 180 : 240,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF00AA55),
                        Color(0xFF2E7D32),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                size: 35,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Verification',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // OTP Form Card
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(22.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Verify OTP',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the 6-digit code sent to\n${widget.mobileNumber}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // OTP Input Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return Container(
                            width: 38,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FBF9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _controllers[index].text.isNotEmpty
                                    ? const Color(0xFF00AA55)
                                    : const Color(0xFFE8F5E9),
                                width: 2,
                              ),
                              boxShadow: _controllers[index].text.isNotEmpty
                                  ? [BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.1), blurRadius: 8)]
                                  : null,
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
                                counterText: "",
                              ),
                              style: const TextStyle(
                                fontSize: 19, 
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                              onChanged: (value) => _onChanged(value, index),
                            ),
                          );
                        }),
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Timer/Resend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_outlined, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 6),
                          Text(
                            _secondsRemaining > 0 
                                ? 'Resend in ${_secondsRemaining}s'
                                : 'Didn\'t receive?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_secondsRemaining == 0) ...[
                            TextButton(
                              onPressed: () async {
                                setState(() {
                                  _secondsRemaining = 60;
                                  _isLoading = true;
                                });
                                _startTimer();
                                
                                try {
                                  await FirebaseAuth.instance.verifyPhoneNumber(
                                    phoneNumber: "+91${widget.mobileNumber}",
                                    verificationCompleted: (PhoneAuthCredential credential) {},
                                    verificationFailed: (FirebaseAuthException e) {
                                      if (mounted) UiUtils.showCustomAlert(context, e.message ?? 'Resend failed');
                                    },
                                    codeSent: (String verId, int? resendToken) {
                                      // Note: verificationId might change, but for simplicity we assume the user stays on this screen
                                      if (mounted) UiUtils.showCenteredToast(context, 'OTP Resent!');
                                    },
                                    codeAutoRetrievalTimeout: (String verId) {},
                                  );
                                } catch (e) {
                                  if (mounted) UiUtils.showCustomAlert(context, 'Error: $e');
                                } finally {
                                  if (mounted) setState(() => _isLoading = false);
                                }
                              },
                              child: const Text(
                                'Resend',
                                style: TextStyle(
                                  color: Color(0xFF00AA55),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isButtonEnabled && !_isLoading ? _verify : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00AA55),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: _isButtonEnabled ? 6 : 0,
                            shadowColor: const Color(0xFF00AA55).withOpacity(0.4),
                          ),
                          child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : const Text(
                                'Verify Now',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
