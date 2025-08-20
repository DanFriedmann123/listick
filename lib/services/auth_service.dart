import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:developer' as developer;
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService();

  // Rate limiting for email verification
  DateTime? _lastVerificationEmailSent;
  static const Duration _verificationCooldown = Duration(minutes: 1);

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Stream that emits when user verification status changes
  Stream<User?> get userVerificationChanges {
    return _auth.userChanges();
  }

  // Check if user needs email verification
  bool needsEmailVerification(User user) {
    // Social sign-in users are automatically verified
    if (user.providerData.isNotEmpty) {
      final providerId = user.providerData.first.providerId;
      if (providerId == 'google.com' || providerId == 'apple.com') {
        return false;
      }
    }
    // Email/password users need verification
    return !user.emailVerified;
  }

  // Check if enough time has passed since last verification email
  bool canSendVerificationEmail() {
    if (_lastVerificationEmailSent == null) {
      return true;
    }
    final timeSinceLastEmail = DateTime.now().difference(
      _lastVerificationEmailSent!,
    );
    return timeSinceLastEmail >= _verificationCooldown;
  }

  // Get remaining cooldown time
  Duration getRemainingCooldown() {
    if (_lastVerificationEmailSent == null) {
      return Duration.zero;
    }
    final timeSinceLastEmail = DateTime.now().difference(
      _lastVerificationEmailSent!,
    );
    if (timeSinceLastEmail >= _verificationCooldown) {
      return Duration.zero;
    }
    return _verificationCooldown - timeSinceLastEmail;
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      developer.log('Error sending email verification: ${e.toString()}');
      throw 'Failed to send verification email: ${e.toString()}';
    }
  }

  // Send email verification with custom action code settings
  Future<void> sendEmailVerificationWithSettings() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification(
          ActionCodeSettings(
            url: 'https://listick.page.link/verify',
            handleCodeInApp: true,
            iOSBundleId: 'com.dodapps.listick',
            androidPackageName: 'com.dodapps.listick',
            androidInstallApp: true,
            androidMinimumVersion: '12',
          ),
        );
      }
    } catch (e) {
      developer.log(
        'Error sending email verification with settings: ${e.toString()}',
      );
      throw 'Failed to send verification email: ${e.toString()}';
    }
  }

  // Reload user to get latest verification status
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      developer.log('Error reloading user: ${e.toString()}');
      throw 'Failed to reload user: ${e.toString()}';
    }
  }

  // Trigger a verification status check
  Future<void> checkVerificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        // This will trigger the userChanges stream and update the UI
      }
    } catch (e) {
      developer.log('Error checking verification status: ${e.toString()}');
      throw 'Failed to check verification status: ${e.toString()}';
    }
  }

  // Check if user needs username setup (deprecated - use OnboardingService instead)
  bool needsUsernameSetup(User user) {
    // This method is deprecated. Use OnboardingService.hasCompletedOnboarding() instead
    return false;
  }

  // Save username to user profile (deprecated - use OnboardingService instead)
  Future<void> saveUsername(String username) async {
    // This method is deprecated. Use OnboardingService.saveUsername() instead
    throw UnimplementedError('Use OnboardingService.saveUsername() instead');
  }

  // Check if username is available (deprecated - use OnboardingService instead)
  Future<bool> isUsernameAvailable(String username) async {
    // This method is deprecated. Use OnboardingService.isUsernameAvailable() instead
    throw UnimplementedError(
      'Use OnboardingService.isUsernameAvailable() instead',
    );
  }

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user needs email verification
      if (userCredential.user != null &&
          needsEmailVerification(userCredential.user!)) {
        // Send verification email if not already sent
        await sendEmailVerification();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      if (userCredential.user != null) {
        await _userService.createOrUpdateUser(
          uid: userCredential.user!.uid,
          email: email,
        );

        // Send verification email automatically
        await userCredential.user!.sendEmailVerification();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Sign in with Google (using dedicated google_sign_in package)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      developer.log('Starting Google sign-in process');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        developer.log('Google sign-in was cancelled by user');
        throw 'Google sign-in was cancelled';
      }

      developer.log('Google user account obtained: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      developer.log('Google authentication details obtained');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      developer.log('Google credential created, signing in with Firebase');

      // Sign in with the credential
      final result = await _auth.signInWithCredential(credential);

      // Create or update user profile in Firestore
      if (result.user != null) {
        await _userService.createOrUpdateUser(
          uid: result.user!.uid,
          email: result.user!.email ?? '',
          displayName: result.user!.displayName,
          avatarUrl: result.user!.photoURL,
        );
      }

      developer.log('Google sign-in completed successfully');
      return result;
    } on FirebaseAuthException catch (e) {
      developer.log(
        'Firebase Auth Exception in Google sign-in: ${e.code} - ${e.message}',
      );
      throw _handleAuthException(e);
    } catch (e) {
      developer.log('General Exception in Google sign-in: ${e.toString()}');
      // Handle other errors gracefully
      if (e.toString().contains('cancelled') ||
          e.toString().contains('canceled')) {
        throw 'Google sign-in was cancelled';
      }
      throw 'Google sign-in failed: ${e.toString()}';
    }
  }

  // Sign in with Apple (using dedicated sign_in_with_apple package)
  Future<UserCredential?> signInWithApple() async {
    try {
      developer.log('Starting Apple sign-in process');

      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      developer.log('Apple credential obtained');

      // Create an `OAuthCredential` from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      developer.log('Apple OAuth credential created, signing in with Firebase');

      // Sign in with the credential
      final result = await _auth.signInWithCredential(oauthCredential);

      // Create or update user profile in Firestore
      if (result.user != null) {
        await _userService.createOrUpdateUser(
          uid: result.user!.uid,
          email: result.user!.email ?? '',
          displayName: result.user!.displayName,
          avatarUrl: result.user!.photoURL,
        );
      }

      developer.log('Apple sign-in completed successfully');
      return result;
    } on FirebaseAuthException catch (e) {
      developer.log(
        'Firebase Auth Exception in Apple sign-in: ${e.code} - ${e.message}',
      );
      throw _handleAuthException(e);
    } catch (e) {
      developer.log('General Exception in Apple sign-in: ${e.toString()}');
      // Handle other errors gracefully
      if (e.toString().contains('cancelled') ||
          e.toString().contains('canceled')) {
        throw 'Apple sign-in was cancelled';
      }
      throw 'Apple sign-in failed: ${e.toString()}';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    developer.log('Handling Firebase Auth Exception: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'popup-closed-by-user':
        return 'Sign-in was cancelled.';
      case 'popup-blocked':
        return 'Sign-in popup was blocked. Please allow popups.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'invalid-credential':
        return 'Invalid credentials provided.';
      case 'operation-cancelled':
        return 'Operation was cancelled.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      case 'auth/operation-not-allowed':
        return 'Social sign-in is not enabled. Please contact support.';
      case 'auth/configuration-not-found':
        return 'Authentication configuration not found. Please contact support.';
      case 'auth/unauthorized-domain':
        return 'This domain is not authorized for sign-in.';
      case 'auth/invalid-api-key':
        return 'Invalid API key. Please contact support.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  // Check if user is fully authenticated (email verified and username set up)
  bool isFullyAuthenticated(User user) {
    return !needsEmailVerification(user) && !needsUsernameSetup(user);
  }

  // Force refresh user data from Firebase
  Future<void> refreshUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      developer.log('Error refreshing user: ${e.toString()}');
      throw 'Failed to refresh user data: ${e.toString()}';
    }
  }

  // Check if user can access the app (email verified and username set up)
  bool canAccessApp(User user) {
    return isFullyAuthenticated(user);
  }

  // Get user authentication status
  String getUserAuthStatus(User user) {
    if (needsEmailVerification(user)) {
      return 'Email verification required';
    } else if (needsUsernameSetup(user)) {
      return 'Username setup required';
    } else {
      return 'Fully authenticated';
    }
  }

  // Check if user needs to complete onboarding
  bool needsOnboarding(User user) {
    return needsEmailVerification(user) || needsUsernameSetup(user);
  }

  // Get next onboarding step for user
  String getNextOnboardingStep(User user) {
    if (needsEmailVerification(user)) {
      return 'Verify your email address';
    } else if (needsUsernameSetup(user)) {
      return 'Set up your username';
    } else {
      return 'Ready to go!';
    }
  }
}
