import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/responsive_layout.dart';
import '../constants/user_roles.dart';
import '../services/auth_service.dart';
import 'therapist_home_screen.dart';
import 'guardian_home_screen.dart';

/// 로그인 화면 - 의료/센터 전용 UX
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

/// 모바일 버전 - 아쿠랩케어 UX 원칙 적용
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
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 여백
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),
              
              // 로고 & 브랜드
              _buildBrandSection(),
              
              SizedBox(height: MediaQuery.of(context).size.height * 0.06),
              
              // 로그인 폼
              _buildLoginForm(),
              
              const SizedBox(height: 24),
              
              // 하단 액션 영역
              _buildBottomActions(),
              
              const SizedBox(height: 32),
              
              // 안내 메시지
              _buildInfoMessage(),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// 브랜드 섹션 (로고 + 앱명 + 서브카피)
  Widget _buildBrandSection() {
    return Column(
      children: [
        // 로고 아이콘
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade200,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.water_drop,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        
        // 앱 이름
        const Text(
          'AQU LAB Care',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        
        // 서브 카피 (3줄)
        const Text(
          '센터·치료사·보호자를 위한\nAI 기반 수중재활 관리 시스템',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Color(0xFF666666),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  /// 로그인 폼
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 구분선
          Container(
            height: 1,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.only(bottom: 24),
          ),
          
          // 이메일 입력
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: '이메일',
              hintText: '이메일을 입력하세요',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '이메일을 입력하세요';
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
              hintText: '비밀번호',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호를 입력하세요';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleLogin(),
          ),
          
          // 에러 메시지
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // 로그인 버튼
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 하단 액션 영역
  Widget _buildBottomActions() {
    return Column(
      children: [
        // 구분선
        Container(
          height: 1,
          color: Colors.grey.shade200,
          margin: const EdgeInsets.only(bottom: 20),
        ),
        
        // 초대코드로 가입하기 (강조)
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/invite-code');
            },
            icon: Icon(Icons.mail_outline, color: Colors.blue.shade700),
            label: Text(
              '초대코드로 가입하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
                letterSpacing: -0.3,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue.shade700, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // 비밀번호 재설정 (secondary)
        TextButton(
          onPressed: _handleForgotPassword,
          child: Text(
            '비밀번호를 잊으셨나요?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  /// 안내 메시지
  Widget _buildInfoMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '이 앱은 센터 초대 기반으로만\n이용할 수 있습니다.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.blue.shade900,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 로그인 처리
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final authService = AuthService();

      // Firestore 기반 로그인
      final user = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // 계정 상태 확인 (서비스에서 이미 확인함)

      // AppState에 사용자 정보 저장
      appState.setCurrentUser(user);

      if (!mounted) return;

      // 역할별 홈 화면으로 이동
      if (user.role == UserRole.guardian) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GuardianHomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TherapistHomeScreen()),
        );
      }

      // 환영 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('환영합니다, ${user.name}님!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      String errorMsg = '이메일 또는 비밀번호가 올바르지 않습니다';
      
      if (e.toString().contains('user-not-found')) {
        errorMsg = '등록되지 않은 이메일입니다';
      } else if (e.toString().contains('wrong-password')) {
        errorMsg = '비밀번호가 일치하지 않습니다';
      } else if (e.toString().contains('user-disabled')) {
        errorMsg = '이 계정은 현재 비활성화되어 있습니다.\n센터로 문의해 주세요.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMsg = '로그인 시도가 너무 많습니다.\n잠시 후 다시 시도해주세요.';
      }
      
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 비밀번호 재설정
  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 재설정'),
        content: const Text(
          '비밀번호 재설정이 필요한 경우\n센터 관리자에게 문의해주세요.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

/// 데스크톱/태블릿 버전 - 2칼럼 레이아웃
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
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // 좌측: 브랜드 영역
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 로고
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.water_drop,
                          size: 50,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // 앱 이름
                      const Text(
                        'AQU LAB Care',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 서브 카피
                      const Text(
                        '센터·치료사·보호자를 위한\nAI 기반 수중재활 관리 시스템',
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.8,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // 특징
                      _buildFeatureItem('🔐 보안 인증 시스템'),
                      _buildFeatureItem('📊 실시간 데이터 분석'),
                      _buildFeatureItem('👥 역할 기반 접근 제어'),
                      _buildFeatureItem('📱 모든 기기에서 접속 가능'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 우측: 로그인 폼
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.grey.shade50,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(60),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 제목
                        const Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '계정에 로그인하여 시작하세요',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // 로그인 폼 (모바일과 동일한 구조)
                        _buildLoginFormDesktop(),
                        
                        const SizedBox(height: 24),
                        
                        _buildBottomActionsDesktop(),
                        
                        const SizedBox(height: 32),
                        
                        _buildInfoMessageDesktop(),
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

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginFormDesktop() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: '이메일',
              hintText: '이메일을 입력하세요',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '이메일을 입력하세요';
              }
              if (!value.contains('@')) {
                return '올바른 이메일 형식이 아닙니다';
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
              hintText: '비밀번호',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호를 입력하세요';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleLogin(),
          ),
          
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '로그인',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionsDesktop() {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/invite-code');
            },
            icon: Icon(Icons.mail_outline, color: Colors.blue.shade700),
            label: Text(
              '초대코드로 가입하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue.shade700, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('비밀번호 재설정'),
                content: const Text(
                  '비밀번호 재설정이 필요한 경우\n센터 관리자에게 문의해주세요.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('확인'),
                  ),
                ],
              ),
            );
          },
          child: Text(
            '비밀번호를 잊으셨나요?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoMessageDesktop() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '이 앱은 센터 초대 기반으로만 이용할 수 있습니다.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final authService = AuthService();

      final user = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      appState.setCurrentUser(user);

      if (!mounted) return;

      if (user.role == UserRole.guardian) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GuardianHomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TherapistHomeScreen()),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('환영합니다, ${user.name}님!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errorMsg = '이메일 또는 비밀번호가 올바르지 않습니다';
      
      if (e.toString().contains('user-not-found')) {
        errorMsg = '등록되지 않은 이메일입니다';
      } else if (e.toString().contains('wrong-password')) {
        errorMsg = '비밀번호가 일치하지 않습니다';
      } else if (e.toString().contains('user-disabled')) {
        errorMsg = '이 계정은 현재 비활성화되어 있습니다.\n센터로 문의해 주세요.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMsg = '로그인 시도가 너무 많습니다.\n잠시 후 다시 시도해주세요.';
      }
      
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
