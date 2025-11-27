import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth/auth_service.dart';
import 'services/storage/local_storage_service.dart';
import 'services/task/task_service.dart';
import 'services/team/team_service.dart';
import 'ui/pages/settings_page.dart';
import 'ui/pages/sign_in_page.dart';
import 'ui/pages/sign_up_page.dart';
import 'ui/pages/tasks_page.dart';
import 'ui/pages/teams_page.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb && kDebugMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      final exceptionString = details.exception.toString();
      if (exceptionString.contains('_debugDuringDeviceUpdate') ||
          exceptionString.contains('isDisposed') ||
          exceptionString.contains('EngineFlutterView')) {
        return;
      }
      FlutterError.presentError(details);
    };
  }

  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final localStorage = LocalStorageService();
  await localStorage.init();
  runApp(TodoApp(localStorage: localStorage));
}

class TodoApp extends StatefulWidget {
  final LocalStorageService localStorage;

  const TodoApp({super.key, required this.localStorage});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.localStorage.getThemeMode();
    _listenToThemeChanges();
  }

  void _listenToThemeChanges() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final newMode = widget.localStorage.getThemeMode();
        if (newMode != _themeMode) {
          setState(() {
            _themeMode = newMode;
          });
        }
        _listenToThemeChanges();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalStorageService>.value(value: widget.localStorage),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<TaskService>(create: (_) => TaskService()),
        Provider<TeamService>(create: (_) => TeamService()),
        StreamProvider<User?>(
          create: (ctx) => ctx.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Todo List',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
        locale: const Locale('fr', 'FR'),
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');
          if (uri.path == '/') {
            return MaterialPageRoute(builder: (_) => const HomeGate());
          }
          switch (uri.path) {
            case SignInPage.route:
              return MaterialPageRoute(
                builder: (_) => const SignInPage(),
                settings: settings,
              );

            case SignUpPage.route:
              return MaterialPageRoute(
                builder: (_) => const SignUpPage(),
                settings: settings,
              );

            case TasksPage.route:
              return MaterialPageRoute(
                builder: (_) => const TasksPage(),
                settings: settings,
              );

            case TeamsPage.route:
              return MaterialPageRoute(
                builder: (_) => const TeamsPage(),
                settings: settings,
              );

            case SettingsPage.route:
              return MaterialPageRoute(
                builder: (_) => const SettingsPage(),
                settings: settings,
              );

            default:
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Page introuvable')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '404',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Page non trouvée: ${uri.path}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Builder(
                          builder: (context) => FilledButton.icon(
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/',
                              (route) => false,
                            ),
                            icon: const Icon(Icons.home_rounded),
                            label: const Text('Retour à l\'accueil'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}

class HomeGate extends StatelessWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    if (user == null) {
      return const SignInPage();
    }

    return const TasksPage();
  }
}
