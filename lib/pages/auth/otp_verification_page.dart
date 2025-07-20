import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'user_registration_page.dart';

class OTPVerificationPage extends StatefulWidget {
  final String phoneNumber;

  const OTPVerificationPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getOTPCode() {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);

    try {
      print('📱 [UI] Resending verification code to: ${widget.phoneNumber}');
      
      // Use the new resend method
      await _authService.resendPhoneVerification(widget.phoneNumber);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New verification code sent!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('📱 [UI] Error resending code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend code: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _verifyOTP() async {
    final otpCode = _getOTPCode();
    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit code')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('📱 [UI] Verifying OTP code: $otpCode');
      print('📱 [UI] Verification ID available: ${_authService.hasVerificationId}');
      print('📱 [UI] Is test number: ${_authService.isTestNumber(widget.phoneNumber)}');
      
      UserCredential? userCredential;
      
      if (_authService.isTestNumber(widget.phoneNumber)) {
        print('📱 [UI] Test number detected - using test verification');
        userCredential = await _authService.verifyTestPhoneCode(
          widget.phoneNumber, 
          otpCode
        );
      } else {
        print('📱 [UI] Real number detected - using standard verification');
        userCredential = await _authService.verifyPhoneCode(otpCode);
      }
      
      if (userCredential != null && userCredential.user != null) {
        print('📱 [UI] Verification successful! User ID: ${userCredential.user!.uid}');
        
        // For test numbers, create a user document in Firestore to simulate a complete user
        if (_authService.isTestNumber(widget.phoneNumber)) {
          try {
            print('📱 [UI] Creating user document for test number...');
            await _authService.createUserDocument(
              uid: userCredential.user!.uid,
              phoneNumber: widget.phoneNumber,
              name: 'Test User',
              username: 'testuser_${widget.phoneNumber.replaceAll('+', '')}',
            );
            print('📱 [UI] User document created successfully for test number');
          } catch (e) {
            print('📱 [UI] Error creating user document for test number: $e');
            // Continue anyway - the user is still authenticated
          }
        }
        
        if (mounted) {
          // Navigate to main app and clear the navigation stack
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/main',
            (route) => false,
          );
        }
      } else {
        print('📱 [UI] Verification returned null user credential');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification failed. Please try again.')),
          );
        }
      }
      
    } catch (e) {
      print('📱 [UI] Error in _verifyOTP:');
      print('📱 [UI] Error type: ${e.runtimeType}');
      print('📱 [UI] Error message: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Verify your phone',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isTestNumber(widget.phoneNumber) 
                ? 'Enter the test code for ${widget.phoneNumber} (use 123456)'
                : 'Enter the code sent to ${widget.phoneNumber}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    onChanged: (value) => _onCodeChanged(value, index),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFFFB74D)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_isTestNumber(widget.phoneNumber)) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Test number detected! Use code: 123456',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB74D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: (_isLoading || _isResending) ? null : _resendCode,
                child: _isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFFB74D),
                        ),
                      )
                    : const Text(
                        'Resend Code',
                        style: TextStyle(
                          color: Color(0xFFFFB74D),
                          fontSize: 16,
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