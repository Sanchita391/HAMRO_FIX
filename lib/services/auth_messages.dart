import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import 'package:hamro_fix/services/location_service.dart';
import 'package:hamro_fix/services/report_service.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthMessages {
  static String from(Object error) {
    if (error is AuthFailure) return error.message;
    if (error is AuthReportFailure) return error.message;
    if (error is LocationFailure) return error.message;
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'invalid-password':
        case 'INVALID_LOGIN_CREDENTIALS':
          return 'Invalid email or password.';
        case 'user-not-found':
          return 'This account does not exist.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'email-already-in-use':
          return 'This email already has a HamroFix account for another role. Use that role\'s sign-in page, or register with a different email.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'weak-password':
          return 'Please choose a stronger password.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Please check your internet connection.';
        case 'operation-not-allowed':
          return 'Email sign-in is not enabled for this project.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
        case 'unauthorized':
        case 'unauthenticated':
          return 'You do not have permission to complete this action.';
        case 'unavailable':
        case 'deadline-exceeded':
        case 'retry-limit-exceeded':
          return 'Cannot reach Firestore. Check Wi‑Fi or mobile data, then try again.';
        case 'object-not-found':
        case 'not-found':
          return 'Unable to load your account. Please try again.';
        case 'canceled':
          return 'The upload was cancelled. Please try again.';
        case 'quota-exceeded':
          return 'Storage limit reached. Try a smaller photo.';
        default:
          return 'Unable to complete this action. Please try again.';
      }
    }

    if (error is PlatformException &&
        (error.code.contains('network') ||
            (error.message ?? '').toLowerCase().contains('network'))) {
      return 'Please check your internet connection.';
    }

    final text = error.toString().toLowerCase();
    if (text.contains('socket') ||
        text.contains('network') ||
        text.contains('failed host lookup')) {
      return 'Please check your internet connection.';
    }

    return 'Something went wrong. Please try again.';
  }
}
