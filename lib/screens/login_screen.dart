import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../constants/app_theme.dart';
import '../constants/user_roles.dart';
import 'therapist_home_screen.dart';
import 'guardian_home_screen.dart';
import 'admin_home_screen.dart';

/// 로그인 화면
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppState>();
    appState.setLoading(true);
    appState.clearError();

    try {
      // Mock 로그인 (Firebase 연동 전)
      await Future.delayed(const Duration(seconds: 1));

      // 이메일 기반 역할 판단 (임시)
      final email = _emailController.text.trim();
      final mockUser = email.contains('therapist')
          ? MockDataProvider.createMockTherapist()
          : email.contains('admin')
              ? MockDataProvider.createMockAdmin()
              : MockDataProvider.createMockGuardian();

      appState.setCurrentUser(mockUser);

      if (mounted) {
        // 역할에 따라 다른 홈 화면으로 이동
        final homeScreen = _getHomeScreenForRole(mockUser.role);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => homeScreen),
        );
      }
    } catch (e) {
      appState.setError('로그인 실패: $e');
    } finally {
      appState.setLoading(false);
    }
  }

  Widget _getHomeScreenForRole(UserRole role) {
    switch (role) {
      case UserRole.therapist:
      case UserRole.centerAdmin:
        return const TherapistHomeScreen();
      case UserRole.guardian:
        return const GuardianHomeScreen();
      case UserRole.superAdmin:
        return const AdminHomeScreen();
      default:
        return const TherapistHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 로고 영역
                  Icon(
                    Icons.water_drop,
                    size: 80,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AQU LAB Care',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '재활 서비스 표준화 플랫폼',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // 이메일 입력
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      hintText: 'example@aqualab.com',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      if (!value.contains('@')) {
                        return '올바른 이메일 형식이 아닙니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호 입력
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      hintText: '비밀번호를 입력하세요',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                        return '비밀번호를 입력해주세요';
                      }
                      if (value.length < 6) {
                        return '비밀번호는 6자 이상이어야 합니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // 에러 메시지
                  Consumer<AppState>(
                    builder: (context, appState, _) {
                      if (appState.errorMessage != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            appState.errorMessage!,
                            style: const TextStyle(color: AppTheme.error),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // 로그인 버튼
                  Consumer<AppState>(
                    builder: (context, appState, _) {
                      return ElevatedButton(
                        onPressed: appState.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: appState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('로그인'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 테스트용 빠른 로그인 버튼
                  if (kDebugMode) ...[
                    const Divider(height: 32),
                    Text(
                      '개발 모드: 빠른 로그인',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            _emailController.text = 'therapist@aqualab.com';
                            _passwordController.text = 'password';
                          },
                          child: const Text('치료사'),
                        ),
                        TextButton(
                          onPressed: () {
                            _emailController.text = 'guardian@aqualab.com';
                            _passwordController.text = 'password';
                          },
                          child: const Text('보호자'),
                        ),
                        TextButton(
                          onPressed: () {
                            _emailController.text = 'admin@aqualab.com';
                            _passwordController.text = 'password';
                          },
                          child: const Text('관리자'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
