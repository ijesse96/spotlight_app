import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import 'otp_verification_page.dart';
import 'welcome_page.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode

class PhoneInputPage extends StatefulWidget {
  const PhoneInputPage({super.key});

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  
  // Country code data
  String _selectedCountryCode = '+1';
  String _selectedCountryFlag = '🇺🇸';
  String _selectedCountryName = 'United States';

  // Popular country codes
  final List<Map<String, String>> _countries = [
    {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'Canada', 'code': '+1', 'flag': '🇨🇦'},
    {'name': 'Australia', 'code': '+61', 'flag': '🇦🇺'},
    {'name': 'Germany', 'code': '+49', 'flag': '🇩🇪'},
    {'name': 'France', 'code': '+33', 'flag': '🇫🇷'},
    {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
    {'name': 'China', 'code': '+86', 'flag': '🇨🇳'},
    {'name': 'Japan', 'code': '+81', 'flag': '🇯🇵'},
    {'name': 'Brazil', 'code': '+55', 'flag': '🇧🇷'},
    {'name': 'Mexico', 'code': '+52', 'flag': '🇲🇽'},
    {'name': 'Spain', 'code': '+34', 'flag': '🇪🇸'},
    {'name': 'Italy', 'code': '+39', 'flag': '🇮🇹'},
    {'name': 'Netherlands', 'code': '+31', 'flag': '🇳🇱'},
    {'name': 'Sweden', 'code': '+46', 'flag': '🇸🇪'},
    {'name': 'Norway', 'code': '+47', 'flag': '🇳🇴'},
    {'name': 'Denmark', 'code': '+45', 'flag': '🇩🇰'},
    {'name': 'Finland', 'code': '+358', 'flag': '🇫🇮'},
    {'name': 'Switzerland', 'code': '+41', 'flag': '🇨🇭'},
    {'name': 'Austria', 'code': '+43', 'flag': '🇦🇹'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber => '$_selectedCountryCode${_phoneController.text}';

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('📱 [UI] Sending OTP for phone: $_fullPhoneNumber');
      
      // Check if this is a test number
      bool isTestNumber = _isTestNumber(_fullPhoneNumber);
      print('📱 [UI] Is test number: $isTestNumber');
      
      // Test Firebase connection first
      await _authService.testFirebaseConnection();
      
      await _authService.sendPhoneVerification(_fullPhoneNumber);
      print('📱 [UI] OTP sent successfully');
      
      // Debug the verification state
      _authService.debugVerificationState();
      
      // Navigate to OTP page for both test and real numbers
      // Test numbers can be manually verified if auto-verification doesn't work
      if (mounted) {
        print('📱 [UI] Navigating to verification page');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(
              phoneNumber: _fullPhoneNumber,
            ),
          ),
        );
      }
    } catch (e) {
      print('📱 [UI] Error sending OTP:');
      print('📱 [UI] Error type: ${e.runtimeType}');
      print('📱 [UI] Error message: $e');
      
      if (mounted) {
        String errorMessage = 'Failed to send verification code';
        
        if (e.toString().contains('invalid-phone-number')) {
          errorMessage = 'Invalid phone number format. Please check your number.';
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = 'Too many requests. Please try again later.';
        } else if (e.toString().contains('quota-exceeded')) {
          errorMessage = 'SMS quota exceeded. Please try again later.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Check if the phone number is a test number
  bool _isTestNumber(String phoneNumber) {
    // Common test number patterns
    final testPatterns = [
      '+15555550000', // Firebase test number
      '+15555550001',
      '+15555550002',
      '+15555550003',
      '+15555550004',
      '+15555550005',
      '+15555550006',
      '+15555550007',
      '+15555550008',
      '+15555550009',
    ];
    return testPatterns.contains(phoneNumber);
  }

  Future<void> _debugPhoneAuth() async {
    try {
      print('🔍 [DEBUG] Starting Phone Auth debug...');
      
      // Test Firebase Auth configuration
      await _authService.testFirebaseAuth();
      
      // Check phone number format
      String phoneNumber = _fullPhoneNumber;
      print('🔍 [DEBUG] Full phone number: $phoneNumber');
      print('🔍 [DEBUG] Country code: $_selectedCountryCode');
      print('🔍 [DEBUG] Phone digits: ${_phoneController.text}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debug completed! Check console for details.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('🔍 [DEBUG] Debug error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Select Country',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _countries.length,
                itemBuilder: (context, index) {
                  final country = _countries[index];
                  return ListTile(
                    leading: Text(
                      country['flag']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(country['name']!),
                    subtitle: Text(country['code']!),
                    trailing: _selectedCountryCode == country['code'] && 
                              _selectedCountryName == country['name']
                        ? const Icon(Icons.check, color: Color(0xFFFFB74D))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCountryCode = country['code']!;
                        _selectedCountryFlag = country['flag']!;
                        _selectedCountryName = country['name']!;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const WelcomePage(),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Enter your phone number',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We\'ll send you a verification code',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              
              // Phone number input field
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // Country code selector
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCountryFlag,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedCountryCode,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Phone number input
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Phone number',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          
                          // Check minimum length (varies by country)
                          int minLength = 7; // Default minimum
                          if (_selectedCountryCode == '+1') minLength = 10; // US/Canada
                          if (_selectedCountryCode == '+44') minLength = 10; // UK
                          if (_selectedCountryCode == '+91') minLength = 10; // India
                          
                          if (value.length < minLength) {
                            return 'Please enter a valid phone number';
                          }
                          
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Preview of full phone number
              if (_phoneController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB74D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 16,
                        color: Color(0xFFFFB74D),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Full number: $_fullPhoneNumber',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFFFB74D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB74D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Send Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : _debugPhoneAuth,
                child: const Text(
                  'Debug Phone Auth',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
} 