import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'app_theme.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GymTrackerApp());
}

class GymTrackerApp extends StatefulWidget {
  const GymTrackerApp({super.key});

  @override
  State<GymTrackerApp> createState() => _GymTrackerAppState();
}

class _GymTrackerAppState extends State<GymTrackerApp> {
  late Future<AppController> _controller = AppController.create();

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Gym Tracker',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: FutureBuilder<AppController>(
      future: _controller,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StartupError(
            message: snapshot.error.toString(),
            onRetry: () => setState(() => _controller = AppController.create()),
          );
        }
        if (!snapshot.hasData) return const _StartupScreen();
        return MainShell(controller: snapshot.data!);
      },
    ),
  );
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storage_rounded, size: 36),
            const SizedBox(height: 16),
            Text(
              'Could not open local workout storage',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    ),
  );
}
