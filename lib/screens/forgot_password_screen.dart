import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController(text: 'driver@antisleep.kz');
  bool _codeSent = false;
  final List<TextEditingController> _codeControllers =
      List.generate(4, (_) => TextEditingController());
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    for (var c in _codeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _sendCode() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _codeSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Қалпына келтіру коды поштаңызға жіберілді!'),
          ),
        );
      }
    });
  }

  void _verifyAndReset() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success),
                SizedBox(width: 8),
                Text('Сәтті аяқталды'),
              ],
            ),
            content: const Text(
                'Құпиясөзіңіз сәтті қалпына келтірілді. Енді жаңа құпиясөзбен кіре аласыз.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Кіру экранына өту'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Құпиясөзді қалпына келтіру'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 20),
              const Text(
                'Құпиясөзді ұмыттыңыз ба?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Тіркелген электрондық поштаңызды немесе телефоныңызды енгізіңіз, біз растау кодын жібереміз.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Электрондық пошта немесе Телефон',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'мысалы, driver@mail.kz',
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!_codeSent)
                CustomButton(
                  text: 'Растау кодын жіберу',
                  icon: Icons.send_rounded,
                  isLoading: _isLoading,
                  onPressed: _sendCode,
                )
              else ...[
                const Text(
                  '4 таңбалы растау кодын енгізіңіз:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (index) => SizedBox(
                      width: 64,
                      height: 56,
                      child: TextField(
                        controller: _codeControllers[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.primaryLight.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.primary),
                          ),
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty && index < 3) {
                            FocusScope.of(context).nextFocus();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Растау және жаңа құпиясөз орнату',
                  icon: Icons.check_circle_outline,
                  isLoading: _isLoading,
                  onPressed: _verifyAndReset,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
