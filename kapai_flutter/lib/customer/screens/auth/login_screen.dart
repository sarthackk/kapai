import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';

enum _LoginStep { phone, otp }

class CustomerLoginScreen extends ConsumerStatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  ConsumerState<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends ConsumerState<CustomerLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  _LoginStep _step = _LoginStep.phone;
  String? _verificationId;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';

    await ref.read(authServiceProvider).sendOtp(
      formattedPhone,
      onAutoVerified: (credential) async {
        final user = await ref.read(authServiceProvider).verifyOtp(
          _verificationId ?? '', '',
        );
        if (user != null && mounted) _onSuccess();
      },
      onCodeSent: (verificationId, _) {
        setState(() {
          _verificationId = verificationId;
          _step = _LoginStep.otp;
          _loading = false;
        });
      },
      onFailed: (e) {
        setState(() {
          _error = e.message ?? 'Failed to send OTP';
          _loading = false;
        });
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _otpCtrl.text.length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final user = await ref.read(authServiceProvider).verifyOtp(_verificationId!, _otpCtrl.text);
      if (user != null && mounted) _onSuccess();
    } catch (e) {
      setState(() { _error = 'Invalid OTP. Try again.'; _loading = false; });
    }
  }

  void _onSuccess() => context.go('/app/home');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: BackButton(onPressed: () {
          if (_step == _LoginStep.otp) {
            setState(() { _step = _LoginStep.phone; _error = null; });
          } else {
            context.go('/');
          }
        }),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                _step == _LoginStep.phone ? 'Enter your\nphone number' : 'Enter OTP',
                style: AppTextStyles.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _step == _LoginStep.phone
                    ? 'We\'ll send a verification code'
                    : 'Sent to ${_phoneCtrl.text}',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMid),
              ),
              const SizedBox(height: 32),

              if (_step == _LoginStep.phone)
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Phone number',
                    prefixText: '+91 ',
                    prefixStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMid),
                  ),
                  onSubmitted: (_) => _sendOtp(),
                ),

              if (_step == _LoginStep.otp)
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  maxLength: 6,
                  style: AppTextStyles.displaySmall.copyWith(letterSpacing: 8),
                  decoration: const InputDecoration(
                    labelText: 'OTP',
                    counterText: '',
                  ),
                  onSubmitted: (_) => _verifyOtp(),
                ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : (_step == _LoginStep.phone ? _sendOtp : _verifyOtp),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_step == _LoginStep.phone ? 'Get OTP' : 'Verify'),
                ),
              ),

              if (_step == _LoginStep.otp) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : _sendOtp,
                    child: const Text('Resend OTP'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
