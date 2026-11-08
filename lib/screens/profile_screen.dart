import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';
import 'edit_vehicle_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel _user = UserModel.current();
  VehicleModel? _vehicle;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final auth = context.read<AuthProvider>();
      final currentUser = auth.currentUser;
      final userId = currentUser?.id ?? 'usr-789';
      final user = await DatabaseService.instance.getUser(userId);
      final vehicle = await DatabaseService.instance.getDefaultVehicle(userId);
      if (mounted) {
        setState(() {
          if (currentUser != null) {
            _user = currentUser;
          } else if (user != null) {
            _user = user;
          }
          _vehicle = vehicle ?? auth.currentVehicle;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleName = _vehicle != null
        ? '${_vehicle!.brand} ${_vehicle!.model}'
        : _user.vehicleModel;
    final plateNumber = _vehicle?.plateNumber ?? _user.plateNumber;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Жүргізуші профилі'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // User Identity Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 46,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _user.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Quick Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildUserStat('Қауіпсіз уақыт', '${_user.totalSafeHours} сағ',
                            Icons.shield_outlined),
                        Container(
                            height: 30,
                            width: 1,
                            color: AppColors.border),
                        _buildUserStat('Жалпы сапар', '${_user.totalTrips} рет',
                            Icons.alt_route_rounded),
                        Container(
                            height: 30,
                            width: 1,
                            color: AppColors.border),
                        _buildUserStat('Рейтинг', '98%',
                            Icons.star_outline_rounded),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Vehicle Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.directions_car_rounded,
                          color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Тіркелген автокөлік',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            vehicleName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            plateNumber,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.primary),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EditVehicleScreen(),
                          ),
                        );
                        _loadProfileData();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Achievements Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Қауіпсіз жүргізу жетістіктері 🏆',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildAchievementItem(
                icon: Icons.verified_user_rounded,
                color: AppColors.success,
                title: '«Қырағы жүргізуші» белгісі',
                description: 'Соңғы 20 сапарда бірде-бір қауіп дабылы тіркелмеді.',
              ),
              const SizedBox(height: 8),
              _buildAchievementItem(
                icon: Icons.nightlight_round,
                color: AppColors.primary,
                title: '«Түнгі күзетші» шебері',
                description: 'Түнгі сағат 00:00-05:00 аралығында 5 сағаттық қауіпсіз жол.',
              ),
              const SizedBox(height: 8),
              _buildAchievementItem(
                icon: Icons.bolt_rounded,
                color: AppColors.warning,
                title: '«Шапшаң реакция» сертификаты',
                description: 'Дабыл қағылған сәттен кейін 1.2 секунд ішінде жауап берілді.',
              ),
              const SizedBox(height: 24),

              // Жүйеден шығу (Logout) батырмасы
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
                  onPressed: () => _confirmLogout(context),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
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
  }

  Widget _buildUserStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
