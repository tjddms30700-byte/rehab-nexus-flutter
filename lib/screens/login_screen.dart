import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/responsive_layout.dart';
import '../constants/user_roles.dart';
import '../services/auth_service.dart';
import 'therapist_home_screen.dart';
import 'guardian_home_screen.dart';

/// 로그인 화면 - 반응형 웹/모바일
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _LoginScreenMobile(),
      desktop: const _LoginScreenDesktop(),
    );
  }
}

/// 모바일 버전 (기존)
class _LoginScreenMobile extends StatefulWidget {
  const _LoginScreenMobile();

  @override
  State<_LoginScreenMobile> createState() => _LoginScreenMobileState();
}

class _LoginScreenMobileState extends State<_LoginScreenMobile> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildLogo(),
              const SizedBox(height: 40),
              _buildLoginForm(),
              const SizedBox(height: 24),
              _buildTestAccounts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Icon(
          Icons.water_drop,
          size: 80,
          color: Colors.blue[700],
        ),
        const SizedBox(height: 16),
        const Text(
          'Rehab Nexus',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '재활치료 센터 관리 시스템',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: '이메일',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '이메일을 입력하세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: '비밀번호',
              prefixIcon: const Icon(Icons.lock),
              border: const OutlineInputBorder(),
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
                return '비밀번호를 입력하세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handleLogin,
              child: const Text('로그인', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 16),
          // 초대코드로 가입하기 버튼
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/invite-code');
              },
              icon: const Icon(Icons.mail_outline),
              label: const Text('초대코드로 가입하기', style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestAccounts() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '테스트 계정',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTestAccountButton(
              '치료사',
              'therapist@aqualab.com',
              'password',
            ),
            _buildTestAccountButton(
              '보호자',
              'guardian@aqualab.com',
              'password',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestAccountButton(String role, String email, String password) {
    return TextButton(
      onPressed: () {
        setState(() {
          _emailController.text = email;
          _passwordController.text = password;
        });
      },
      child: Text('$role: $email / $password'),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppState>();
    appState.setLoading(true);
    appState.clearError();

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // AuthService를 사용한 Firebase 로그인
      final authService = AuthService();
      final user = await authService.login(email, password);

      appState.setCurrentUser(user);

      if (!mounted) return;

      // 역할에 따라 홈 화면 결정
      Widget homeScreen;
      switch (user.role) {
        case UserRole.therapist:
        case UserRole.centerAdmin:
        case UserRole.superAdmin:
          homeScreen = const TherapistHomeScreen();
          break;
        case UserRole.guardian:
          homeScreen = const GuardianHomeScreen();
          break;
        default:
          homeScreen = const TherapistHomeScreen();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => homeScreen),
      );
    } catch (e) {
      appState.setError('로그인 실패: $e');
    } finally {
      appState.setLoading(false);
    }
  }
}

/// 데스크톱 웹 버전 - 분할 화면
class _LoginScreenDesktop extends StatefulWidget {
  const _LoginScreenDesktop();

  @override
  State<_LoginScreenDesktop> createState() => _LoginScreenDesktopState();
}

class _LoginScreenDesktopState extends State<_LoginScreenDesktop> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 좌측: 브랜드 영역
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[700]!,
                    Colors.blue[500]!,
                    Colors.lightBlue[400]!,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        size: 120,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Rehab Nexus',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '재활치료 센터 통합 관리 시스템',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 60),
                    _buildFeatureList(),
                  ],
                ),
              ),
            ),
          ),

          // 우측: 로그인 폼
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(80),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '계정에 로그인하여 시작하세요',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 48),
                        _buildLoginForm(),
                        const SizedBox(height: 32),
                        _buildTestAccounts(),
                        const SizedBox(height: 32),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureItem(Icons.calendar_today, '스마트 일정 관리'),
          const SizedBox(height: 20),
          _buildFeatureItem(Icons.people, '환자 정보 통합 관리'),
          const SizedBox(height: 20),
          _buildFeatureItem(Icons.assessment, '실시간 진료 기록'),
          const SizedBox(height: 20),
          _buildFeatureItem(Icons.insights, '데이터 분석 및 리포트'),
          const SizedBox(height: 20),
          _buildFeatureItem(Icons.cloud, 'Firebase 클라우드 연동'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: '이메일',
              hintText: 'example@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '이메일을 입력하세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: '비밀번호',
              hintText: '8자 이상 입력',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
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
                return '비밀번호를 입력하세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                '로그인',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestAccounts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                '테스트 계정',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTestAccountButton(
            '치료사 계정',
            'therapist@aqualab.com',
            Icons.medical_services,
          ),
          const SizedBox(height: 8),
          _buildTestAccountButton(
            '보호자 계정',
            'guardian@aqualab.com',
            Icons.family_restroom,
          ),
        ],
      ),
    );
  }

  Widget _buildTestAccountButton(String role, String email, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() {
          _emailController.text = email;
          _passwordController.text = 'password';
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$email / password',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '© 2024 Rehab Nexus. All rights reserved.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('이용약관', style: TextStyle(fontSize: 12)),
              ),
              Text('•', style: TextStyle(color: Colors.grey[400])),
              TextButton(
                onPressed: () {},
                child: const Text('개인정보처리방침', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppState>();
    appState.setLoading(true);
    appState.clearError();

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // AuthService를 사용한 Firebase 로그인
      final authService = AuthService();
      final user = await authService.login(email, password);

      appState.setCurrentUser(user);

      if (!mounted) return;

      // 역할에 따라 홈 화면 결정
      Widget homeScreen;
      switch (user.role) {
        case UserRole.therapist:
        case UserRole.centerAdmin:
        case UserRole.superAdmin:
          homeScreen = const TherapistHomeScreen();
          break;
        case UserRole.guardian:
          homeScreen = const GuardianHomeScreen();
          break;
        default:
          homeScreen = const TherapistHomeScreen();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => homeScreen),
      );
    } catch (e) {
      appState.setError('로그인 실패: $e');
    } finally {
      appState.setLoading(false);
    }
  }
}
