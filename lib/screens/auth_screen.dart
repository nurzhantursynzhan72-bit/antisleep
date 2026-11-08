import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AuthScreen extends StatefulWidget {
  final bool initialIsLogin;
  const AuthScreen({super.key, this.initialIsLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isLogin;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'driver@antisleep.kz');
  final _passwordController = TextEditingController(text: '123456');
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _plateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    if (_isLogin) {
      final success = await auth.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;

      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Қош келдіңіз! Жүйеге сәтті кірдіңіз.'),
              ],
            ),
          ),
        );
        nav.pushReplacementNamed(AppRoutes.home);
      } else {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(auth.errorMessage ?? 'Қате email немесе пароль!'),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      final success = await auth.register(
        fullName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        vehicleModel: _vehicleController.text,
        plateNumber: _plateController.text,
      );
      if (!mounted) return;

      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Тіркелу сәтті аяқталды! Қауіпсіз сапар тілейміз.'),
              ],
            ),
          ),
        );
        nav.pushReplacementNamed(AppRoutes.home);
      } else {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(auth.errorMessage ?? 'Тіркелу кезінде қате болды!'),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  void _continueAsGuest() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Brand Icon Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AntiSleep AI',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Title & Subtitle in Kazakh
              Text(
                _isLogin ? 'Қайта оралуыңызбен!' : 'Жаңа аккаунт ашу',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Қауіпсіз сапарыңызды бастау үшін жүйеге кіріңіз'
                    : 'Жеке көлігіңіз бен сапар тарихын бақылау үшін тіркеліңіз',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Mode Switcher Tabs (Login / Register)
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isLogin = true;
                            _formKey.currentState?.reset();
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isLogin ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _isLogin
                                ? const [
                                    BoxShadow(
                                      color: AppColors.shadow,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Кіру',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _isLogin
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isLogin = false;
                            _formKey.currentState?.reset();
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_isLogin ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: !_isLogin
                                ? const [
                                    BoxShadow(
                                      color: AppColors.shadow,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Тіркелу',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: !_isLogin
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form fields with full validation
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isLogin) ...[
                      CustomTextField(
                        controller: _nameController,
                        label: 'Аты-жөніңіз',
                        hintText: 'Мысалы: Арман Жұмабаев',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Жүргізушінің аты-жөнін жазыңыз';
                          }
                          if (value.trim().length < 2) {
                            return 'Аты-жөні кемінде 2 таңбадан тұруы керек';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Байланыс телефоны',
                        hintText: '+7 (707) 123-45-67',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Телефон нөмірін енгізіңіз';
                          }
                          if (value.trim().length < 10) {
                            return 'Телефон нөмірі толық емес';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _vehicleController,
                              label: 'Көлік моделі',
                              hintText: 'Toyota Camry',
                              prefixIcon: Icons.drive_eta_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Марканы көрсетіңіз';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: _plateController,
                              label: 'Мемл. нөмірі',
                              hintText: '02 KZ 777 AAA',
                              prefixIcon: Icons.badge_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Нөмірді жазыңыз';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    CustomTextField(
                      controller: _emailController,
                      label: 'Электрондық пошта (Email)',
                      hintText: 'driver@antisleep.kz',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.mail_outline_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Электрондық поштаны енгізіңіз';
                        }
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Email пішімі қате (мысалы: driver@antisleep.kz)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _passwordController,
                      label: 'Құпиясөз (Пароль)',
                      hintText: '••••••••',
                      isPassword: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Құпиясөз өрісі бос болмауы керек';
                        }
                        if (value.length < 6) {
                          return 'Құпиясөз кемінде 6 таңбадан тұруы тиіс';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    if (!_isLogin) ...[
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'Құпиясөзді қайталаңыз',
                        hintText: '••••••••',
                        isPassword: true,
                        prefixIcon: Icons.lock_reset_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Құпиясөзді растаңыз';
                          }
                          if (value != _passwordController.text) {
                            return 'Құпиясөздер бір-біріне сәйкес келмейді!';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (_isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Құпиясөзді ұмыттыңыз ба?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Primary Submit Button with Provider isLoading
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return CustomButton(
                          text: _isLogin ? 'Жүйеге кіру' : 'Тіркелуді аяқтау',
                          isLoading: auth.isLoading,
                          onPressed: _handleAuth,
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Guest mode button
                    CustomButton(
                      text: 'Тіркелмей, қонақ ретінде сынау',
                      isOutlined: true,
                      onPressed: _continueAsGuest,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),
              // Security badge note
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
                    SizedBox(width: 6),
                    Text(
                      'Edge AI: Барлық деректер құрылғы ішінде өңделеді',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
