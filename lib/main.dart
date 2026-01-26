import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'constants/app_theme.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/assessment_input_screen.dart';
import 'screens/content_recommendation_screen.dart';
import 'models/patient.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: 'AQU LAB Care',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const LoginScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
        },
        onGenerateRoute: (settings) {
          // 동적 라우팅 처리
          if (settings.name == '/assessment_input') {
            final patient = settings.arguments as Patient;
            return MaterialPageRoute(
              builder: (context) => AssessmentInputScreen(
                patient: patient,
              ),
            );
          }
          if (settings.name == '/content_recommendation') {
            final patient = settings.arguments as Patient;
            return MaterialPageRoute(
              builder: (context) => ContentRecommendationScreen(
                patient: patient,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
