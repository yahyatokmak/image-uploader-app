import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/image_upload/image_upload_cubit.dart';
import 'cubits/history/history_cubit.dart';
import 'pages/image_upload_page.dart';
import 'pages/history_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await Firebase.initializeApp();
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (context) => AuthCubit()),
        BlocProvider<ImageUploadCubit>(create: (context) => ImageUploadCubit()),
        BlocProvider<HistoryCubit>(create: (context) => HistoryCubit()),
      ],
      child: MaterialApp(
        title: 'Image Uploader',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AppWrapper(),
        routes: {'/history': (context) => const HistoryPage()},
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    if (!AuthService.isAuthenticated) {
      await context.read<AuthCubit>().signInAnonymously();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Initializing application...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is AuthError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authentication error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthCubit>().signInAnonymously();
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is AuthAuthenticated || state is AuthUnauthenticated) {
          return const ImageUploadPage();
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
