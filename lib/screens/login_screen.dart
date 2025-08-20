import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isSignUp = false;

  // Error state variables
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Clear errors when user starts typing
  void _clearEmailError() {
    if (_emailError != null) {
      setState(() {
        _emailError = null;
      });
    }
  }

  void _clearPasswordError() {
    if (_passwordError != null) {
      setState(() {
        _passwordError = null;
      });
    }
  }

  // Clear all errors
  void _clearAllErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
  }

  Future<void> _submitForm() async {
    // Clear previous errors
    _clearAllErrors();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSignUp) {
        await _authService.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        // Account created successfully - no snackbar needed
      } else {
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        // Success - no need to show message, navigation will happen automatically
        // If user needs email verification, they'll be redirected to the verification screen
      }
    } catch (e) {
      if (mounted) {
        // Parse the error message to determine which field it belongs to
        String errorMessage = e.toString();

        if (errorMessage.contains('email') ||
            errorMessage.contains('Email') ||
            errorMessage.contains('user-not-found') ||
            errorMessage.contains('email-already-in-use') ||
            errorMessage.contains('invalid-email')) {
          setState(() {
            _emailError = errorMessage;
          });
        } else if (errorMessage.contains('password') ||
            errorMessage.contains('Password') ||
            errorMessage.contains('wrong-password') ||
            errorMessage.contains('weak-password')) {
          setState(() {
            _passwordError = errorMessage;
          });
        } else {
          // Generic error - show under password field
          setState(() {
            _passwordError = errorMessage;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // Top section with logo and title
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo/icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.menu,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // App name with gradient
                    ShaderMask(
                      shaderCallback:
                          (bounds) => const LinearGradient(
                            colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                          ).createShader(bounds),
                      child: const Text(
                        'Listick',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Where lists meet social media',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),

              // Login form section
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Tabs
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isSignUp = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        !_isSignUp
                                            ? const Color(0xFF1A1A1A)
                                            : Colors.transparent,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Login',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          !_isSignUp
                                              ? Colors.white
                                              : Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isSignUp = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _isSignUp
                                            ? const Color(0xFF1A1A1A)
                                            : Colors.transparent,
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Sign Up',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          _isSignUp
                                              ? Colors.white
                                              : Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Welcome message
                                Text(
                                  _isSignUp
                                      ? 'Create account'
                                      : 'Welcome back!',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                Text(
                                  _isSignUp
                                      ? 'Start your list journey today'
                                      : 'Sign in to continue',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[400],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Email field
                                Text(
                                  'Email',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'you@example.com',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[500],
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF2A2A2A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  onChanged: (_) => _clearEmailError(),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                if (_emailError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      _emailError!,
                                      style: TextStyle(
                                        color: Colors.red[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 10),

                                // Password field
                                Text(
                                  'Password',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                TextFormField(
                                  controller: _passwordController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[500],
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF2A2A2A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                  obscureText: true,
                                  onChanged: (_) => _clearPasswordError(),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                if (_passwordError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      _passwordError!,
                                      style: TextStyle(
                                        color: Colors.red[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 14),

                                // Remember Me checkbox
                                Row(
                                  children: [
                                    Checkbox(
                                      value:
                                          false, // Remember me functionality coming soon
                                      onChanged: (value) {
                                        // Handle remember me
                                      },
                                      activeColor: const Color(0xFFE91E63),
                                      checkColor: Colors.white,
                                    ),
                                    Text(
                                      'Remember me',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Sign in button
                                Container(
                                  width: double.infinity,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFE91E63),
                                        Color(0xFF9C27B0),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child:
                                        _isLoading
                                            ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                            : Text(
                                              _isSignUp
                                                  ? 'Create Account'
                                                  : 'Sign In',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        'or continue with',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Social sign-in buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: OutlinedButton.icon(
                                          onPressed:
                                              _isLoading
                                                  ? null
                                                  : () async {
                                                    try {
                                                      setState(() {
                                                        _isLoading = true;
                                                      });
                                                      await _authService
                                                          .signInWithGoogle();
                                                    } catch (e) {
                                                      if (mounted) {
                                                        // Show generic error under password field for social sign-in errors
                                                        setState(() {
                                                          _passwordError =
                                                              'Error signing in with Google';
                                                        });
                                                      }
                                                    } finally {
                                                      if (mounted) {
                                                        setState(() {
                                                          _isLoading = false;
                                                        });
                                                      }
                                                    }
                                                  },
                                          icon: Image.asset(
                                            'assets/images/google.png',
                                            height: 18,
                                            width: 18,
                                          ),
                                          label: const Text('Google'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey[600]!,
                                            ),
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: OutlinedButton.icon(
                                          onPressed:
                                              _isLoading
                                                  ? null
                                                  : () async {
                                                    try {
                                                      setState(() {
                                                        _isLoading = true;
                                                      });
                                                      await _authService
                                                          .signInWithApple();
                                                    } catch (e) {
                                                      if (mounted) {
                                                        // Show generic error under password field for social sign-in errors
                                                        setState(() {
                                                          _passwordError =
                                                              'Error signing in with Apple';
                                                        });
                                                      }
                                                    } finally {
                                                      if (mounted) {
                                                        setState(() {
                                                          _isLoading = false;
                                                        });
                                                      }
                                                    }
                                                  },
                                          icon: Image.asset(
                                            'assets/images/apple.png',
                                            height: 18,
                                            width: 18,
                                          ),
                                          label: const Text('Apple'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey[600]!,
                                            ),
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
            ],
          ),
        ),
      ),
    );
  }
}
