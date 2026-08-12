import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/referral_link_service.dart';
import '../referral/services/referral_service.dart';
import '../../shared/widgets/main_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    ReferralLinkService.getPendingReferralCode().then((code) {
      if (code != null && code.isNotEmpty && mounted) {
        setState(() {
          _referralController.text = code;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signUpWithEmailAndPassword(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Apply referral code if present
      final refCode = _referralController.text.trim();
      if (refCode.isNotEmpty) {
        try {
          await ReferralService().applyReferralCode(referralCode: refCode);
          await ReferralLinkService.clearPendingReferralCode();
        } catch (_) {}
      }

      if (mounted) {
        // Redirect to MainScaffold and clear all navigation history
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScaffold()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Register error: $e");
      setState(() {
        _isLoading = false;
        // Parse Firebase Auth exceptions
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('email-already-in-use')) {
          _errorMessage = 'email_in_use'.tr();
        } else if (errStr.contains('weak-password')) {
          _errorMessage = 'weak_password'.tr();
        } else {
          _errorMessage = 'error_occurred'.tr();
        }
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential != null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScaffold()),
          (route) => false,
        );
      } else {
        // Sign-in canceled or failed
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Google Sign In error in register: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = 'error_occurred'.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Theme-sensitive branding colors
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFAF6F0);
    final cardColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final inputColor = isDarkMode ? const Color(0xFF333333) : const Color(0xFFF4EFE6);
    const primaryBlue = Color(0xFF1E3A8A);
    const accentBlue = Color(0xFF3B82F6);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1F2937);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  FadeInDown(
                    duration: const Duration(milliseconds: 1000),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          size: 64,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Titles
                  FadeInDown(
                    duration: const Duration(milliseconds: 1000),
                    delay: const Duration(milliseconds: 150),
                    child: Column(
                      children: [
                        Text(
                          'register_title'.tr(),
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: primaryBlue,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'register_subtitle'.tr(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Register Form Card
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name Field
                          Text(
                            'name'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'John Doe',
                              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
                              filled: true,
                              fillColor: inputColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.person_outline, color: primaryBlue),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'field_required'.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          Text(
                            'email'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'student@stustep.com',
                              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
                              filled: true,
                              fillColor: inputColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.email_outlined, color: primaryBlue),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'field_required'.tr();
                              }
                              final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegExp.hasMatch(value.trim())) {
                                return 'invalid_email'.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          Text(
                            'password'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
                              filled: true,
                              fillColor: inputColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryBlue),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: primaryBlue.withValues(alpha: 0.7),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'field_required'.tr();
                              }
                              if (value.length < 6) {
                                return 'password_too_short'.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Optional Referral Code Field
                          Text(
                            'referral.code_optional'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _referralController,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.done,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            decoration: InputDecoration(
                              hintText: 'referral.code_placeholder'.tr(),
                              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4), letterSpacing: 0),
                              filled: true,
                              fillColor: inputColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.card_giftcard_rounded, color: primaryBlue),
                            ),
                            onFieldSubmitted: (_) => _handleRegister(),
                          ),
                          const SizedBox(height: 24),

                          // Error Message Section
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red.shade700),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red.shade800,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Register Button / Spinner
                          SizedBox(
                            height: 52,
                            child: _isLoading
                                ? const Center(
                                    child: SpinKitThreeBounce(
                                      color: primaryBlue,
                                      size: 32,
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _handleRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'register'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 20),

                          // OR Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: textColor.withValues(alpha: 0.15))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'or_divider'.tr(),
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.4),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: textColor.withValues(alpha: 0.15))),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Google Sign-In Button
                          SizedBox(
                            height: 52,
                            child: _isLoading
                                ? const SizedBox.shrink()
                                : OutlinedButton.icon(
                                    onPressed: _handleGoogleSignIn,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: primaryBlue.withValues(alpha: 0.2)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const FaIcon(
                                      FontAwesomeIcons.google,
                                      color: Color(0xFF1E3A8A),
                                      size: 20,
                                    ),
                                    label: Text(
                                      'continue_with_google'.tr(),
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Redirect to Login
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    delay: const Duration(milliseconds: 150),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: accentBlue,
                      ),
                      child: Text(
                        'already_have_account'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
