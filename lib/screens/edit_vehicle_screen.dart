import 'package:flutter/material.dart';
import '../models/emergency_contact_model.dart';
import '../models/vehicle_model.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class EditVehicleScreen extends StatefulWidget {
  const EditVehicleScreen({super.key});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService.instance;

  final _modelController = TextEditingController(text: 'Toyota Camry 70');
  final _plateController = TextEditingController(text: '02 KZ 777 AAA');
  final _yearController = TextEditingController(text: '2021');
  final _sosNameController = TextEditingController(text: 'Айгүл (Жұбайы)');
  final _sosPhoneController = TextEditingController(text: '+7 707 123 4567');

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final vehicle = await _dbService.getDefaultVehicle('usr-789');
      if (vehicle != null && mounted) {
        _modelController.text = '${vehicle.brand} ${vehicle.model}';
        _plateController.text = vehicle.plateNumber;
        _yearController.text = vehicle.year.toString();
      }

      final contact = await _dbService.getPrimaryEmergencyContact('usr-789');
      if (contact != null && mounted) {
        _sosNameController.text = '${contact.name} (${contact.relationship})';
        _sosPhoneController.text = contact.phone;
      }
    } catch (e) {
      debugPrint('Error loading initial vehicle data: $e');
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    _yearController.dispose();
    _sosNameController.dispose();
    _sosPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final fullModelStr = _modelController.text.trim();
        final parts = fullModelStr.split(' ');
        final brand = parts.isNotEmpty ? parts.first : 'Toyota';
        final model = parts.length > 1 ? parts.sublist(1).join(' ') : 'Авто';
        final year = int.tryParse(_yearController.text.trim()) ?? 2022;

        final vehicle = VehicleModel(
          id: 'veh-001',
          userId: 'usr-789',
          brand: brand,
          model: model,
          plateNumber: _plateController.text.trim(),
          year: year,
          isDefault: true,
        );
        await _dbService.saveVehicle(vehicle);

        final rawSos = _sosNameController.text.trim();
        String sosName = rawSos;
        String rel = 'Жұбайы';
        if (rawSos.contains('(') && rawSos.contains(')')) {
          final start = rawSos.indexOf('(');
          final end = rawSos.indexOf(')');
          sosName = rawSos.substring(0, start).trim();
          rel = rawSos.substring(start + 1, end).trim();
        }

        final contact = EmergencyContactModel(
          id: 'sos-001',
          userId: 'usr-789',
          name: sosName,
          phone: _sosPhoneController.text.trim(),
          relationship: rel,
          isPrimary: true,
        );
        await _dbService.saveEmergencyContact(contact);

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.success,
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Автокөлік пен SOS контакт сәтті сақталды!'),
                ],
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.danger,
              content: Text('Сақтау кезінде қате орын алды: $e'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Көлік және SOS баптаулары'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Section Title
                const Text(
                  'Автокөлік мәліметтері',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _modelController,
                        label: 'Көлік маркасы мен моделі',
                        hintText: 'Мысалы: Toyota Camry 70 / Scania R500',
                        prefixIcon: Icons.directions_car_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Көлік маркасы бос болмауы керек';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _plateController,
                        label: 'Мемлекеттік нөмірі (License Plate)',
                        hintText: 'Мысалы: 02 KZ 777 AAA',
                        prefixIcon: Icons.pin_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Мемлекеттік нөмірді енгізу міндетті';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _yearController,
                        label: 'Шыққан жылы',
                        hintText: 'Мысалы: 2021',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.calendar_today_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Шыққан жылын енгізіңіз';
                          }
                          final year = int.tryParse(value.trim());
                          if (year == null || year < 1980 || year > 2027) {
                            return 'Жыл 1980 мен 2026 аралығында болуы керек';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Emergency SOS Contact Section
                const Text(
                  'Шұғыл байланыс нөмірі (SOS Contact)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Көлік жүргізушісі ұйықтап кетіп, дабылға жауап бермеген жағдайда автоматты SMS жіберілетін нөмір.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _sosNameController,
                        label: 'Байланысатын тұлға (Аты / Кім болатыны)',
                        hintText: 'Мысалы: Айгүл (Жұбайы)',
                        prefixIcon: Icons.contact_emergency_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'SOS байланыс адамының атын жазыңыз';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _sosPhoneController,
                        label: 'Телефон нөмірі',
                        hintText: '+7 (707) 123-45-67',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'SOS телефон нөмірін енгізіңіз';
                          }
                          if (value.trim().length < 8) {
                            return 'Телефон нөмірі толық емес';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Save Changes Button
                CustomButton(
                  text: 'Өзгерістерді сақтау',
                  isLoading: _isLoading,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: _saveData,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
