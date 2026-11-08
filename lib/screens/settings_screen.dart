import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';
import 'help_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _sensitivityThreshold = 0.28;
  double _alarmVolume = 0.9;
  bool _vibrationEnabled = true;
  bool _autoNightHud = true;
  bool _voiceWarnings = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Баптаулар'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // AI Detection Calibration Section
            _buildSectionHeader('AI Алгоритм және Сезімталдық'),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'EAR көз жұмылу шегі',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _sensitivityThreshold.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Көрсеткіш неғұрлым жоғары болса, жүйе соғұрлым сезімтал болады.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Slider(
                    value: _sensitivityThreshold,
                    min: 0.18,
                    max: 0.35,
                    divisions: 17,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _sensitivityThreshold = val);
                    },
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Түнгі автоматты HUD режимі',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Жарық аз кезде қараңғы интерфейске ауысу',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _autoNightHud,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _autoNightHud = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sound & Vibration Section
            _buildSectionHeader('Дабыл және Дыбыс'),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Сирена дауысының қаттылығы',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${(_alarmVolume * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _alarmVolume,
                    min: 0.2,
                    max: 1.0,
                    activeColor: AppColors.danger,
                    onChanged: (val) => setState(() => _alarmVolume = val),
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Смартфон дірілі (Vibration)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Дабыл кезінде үздіксіз діріл қосу',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _vibrationEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _vibrationEnabled = val),
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Дауыстық ескертулер (Voice)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      '«Сақ болыңыз!», «Көлікті тоқтатыңыз!» сөздері',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _voiceWarnings,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _voiceWarnings = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Help & App Info Tile
            _buildSectionHeader('Қосымша туралы'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.help_outline_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    title: const Text(
                      'Көмек және анықтама (FAQ)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const HelpScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  const ListTile(
                    leading: Icon(Icons.info_outline_rounded,
                        color: AppColors.textSecondary),
                    title: Text(
                      'Қосымша нұсқасы',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      'v1.0.4 • Edge AI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Жүйеден шығу батырмасы
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text(
                  'Жүйеден шығу',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Жүйеден шығу'),
                      content: const Text('Аккаунтыңыздан шығуды растайсыз ба?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Болдырмау'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.danger),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await context.read<AuthProvider>().logout();
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.auth,
                                (route) => false,
                              );
                            }
                          },
                          child: const Text('Шығу'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
