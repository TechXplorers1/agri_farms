import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agriculture/l10n/app_localizations.dart';
import 'verify_otp_screen.dart';
import '../../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedRole;
  bool _isLogin = true; // Default to Login
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  List<String> _getRoles(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    return [l10n.generalUser, l10n.farmer];
  }

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validateInput);
    _nameController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _validateInput() {
    setState(() {
      if (_isLogin) {
        // Login: Only Phone required
        _isButtonEnabled = _phoneController.text.length == 10;
      } else {
        // Sign Up: All fields required
        _isButtonEnabled = _phoneController.text.length == 10 &&
          _nameController.text.trim().isNotEmpty &&
          _selectedRole != null;
      }
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
            onPressed: () {
              Navigator.of(context).pop();
              if (title == 'Account Not Found') {
                setState(() {
                  _isLogin = false;
                  _validateInput();
                });
              } else if (title == 'Account Exists') {
                setState(() {
                  _isLogin = true;
                  _validateInput();
                });
              }
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF00AA55))),
          ),
        ],
      ),
    );
  }

  Future<void> _getOtp() async {
    if (_isButtonEnabled) {
      setState(() {
        _isLoading = true;
      });

      try {
        final apiService = ApiService();
        
        if (_isLogin) {
          try {
            await apiService.getUserByPhone(_phoneController.text);
          } catch (e) {
            if (e.toString().contains('404') || e.toString().contains('Not Found')) {
              if (mounted) _showErrorDialog('Account Not Found', 'Please sign up or register to get logged in.');
              return;
            } else {
              if (mounted) _showErrorDialog('Error', 'Failed to verify account: $e');
              return;
            }
          }
        } else {
          try {
            await apiService.getUserByPhone(_phoneController.text);
            if (mounted) _showErrorDialog('Account Exists', 'This mobile number is already registered. Please login instead.');
            return;
          } catch (e) {
            if (e.toString().contains('404') || e.toString().contains('Not Found')) {
              // Expected missing user
            } else {
              if (mounted) _showErrorDialog('Error', 'Failed to check account: $e');
              return;
            }
          }
        }

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VerifyOtpScreen(
                mobileNumber: _phoneController.text,
                fullName: _isLogin ? '' : _nameController.text, // Empty for login
                role: _isLogin ? '' : _selectedRole!,        // Empty for login
                isLogin: _isLogin,
              ),
            ),
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

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _validateInput(); // Re-validate on toggle
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Premium Brand Header
            Stack(
              children: [
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1B5E20),
                        Color(0xFF2E7D32),
                        Color(0xFF00AA55),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Animated Logo Container
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30),
                            ],
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 48,
                            color: Color(0xFF00AA55),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Agri Farms',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.welcomeTitle,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Form Content
            Transform.translate(
              offset: const Offset(0, -50),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLogin ? 'Welcome Back' : 'Get Started',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B5E20),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isLogin ? 'Login to continue' : 'Join the community',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00AA55).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isLogin ? Icons.login_rounded : Icons.person_add_rounded,
                              color: const Color(0xFF00AA55),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Sign Up Unique Fields
                      if (!_isLogin) ...[
                        _buildLabel(l10n.fullName),
                        const SizedBox(height: 8),
                        _buildInputField(
                          controller: _nameController,
                          hint: l10n.fullNameHint,
                          icon: Icons.badge_outlined,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 24),
                        _buildLabel(l10n.chooseRole),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FBF9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8F5E9)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedRole,
                              hint: Text(l10n.selectRole, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500)),
                              isExpanded: true,
                              icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF00AA55)),
                              items: _getRoles(context).map((String role) {
                                return DropdownMenuItem<String>(
                                  value: role,
                                  child: Text(role, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedRole = newValue;
                                  _validateInput();
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      _buildLabel(l10n.mobileNumber),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8F1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE8F5E9)),
                            ),
                            child: const Text(
                              '+91',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1B5E20),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInputField(
                              controller: _phoneController,
                              hint: '0000 000 000',
                              icon: null,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Action Button (Premium Lush)
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            if (_isButtonEnabled)
                              BoxShadow(
                                color: const Color(0xFF00AA55).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isButtonEnabled && !_isLoading ? _getOtp : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00AA55),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE8F5E9),
                            disabledForegroundColor: Colors.grey[400],
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                            : Text(
                                _isLogin ? 'Sign In'.toUpperCase() : 'Create Account'.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      // Toggle Auth Mode
                      Center(
                        child: GestureDetector(
                          onTap: _toggleAuthMode,
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                              children: [
                                TextSpan(text: _isLogin ? "Don't have an account? " : "Already have an account? "),
                                TextSpan(
                                  text: _isLogin ? "Sign Up" : "Login",
                                  style: const TextStyle(
                                    color: Color(0xFF00AA55),
                                    fontWeight: FontWeight.w900,
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
              ),
            ),
            
            // Premium Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF00AA55), size: 20),
                  const SizedBox(height: 12),
                  Text(
                    l10n.termsPolicy,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1B5E20),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F5E9)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, size: 22, color: const Color(0xFF00AA55)) : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: icon != null ? 16 : 20, vertical: 14),
          hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
