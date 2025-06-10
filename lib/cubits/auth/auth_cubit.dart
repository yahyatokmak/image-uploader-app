import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  late final StreamSubscription<User?> _authSubscription;

  AuthCubit() : super(AuthInitial()) {
    // Listen to auth state changes
    _authSubscription = AuthService.authStateChanges.listen((User? user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  /// Sign in anonymously
  Future<void> signInAnonymously() async {
    try {
      emit(AuthLoading());
      await AuthService.signInAnonymously();
      // State will be automatically updated via stream listener
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      emit(AuthLoading());
      await AuthService.signOut();
      // State will be automatically updated via stream listener
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Get current user ID
  String? get currentUserId => AuthService.currentUserId;

  /// Check if user is authenticated
  bool get isAuthenticated => AuthService.isAuthenticated;

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
