import 'package:flutter/material.dart';
import '../models/route_model.dart';
import '../services/route_repository.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final RouteRepository _repository = RouteRepository();
  final TextEditingController _searchController = TextEditingController();

  List<RouteModel> _routes = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filters & Sorting state
  int _activeTab = 0; // 0: Барлық бағыттар, 1: Таңдаулылар
  String _selectedRisk = 'Барлығы'; // 'Барлығы', 'Төмен', 'Орташа', 'Қатерлі'
  String _sortBy = 'created_at'; // 'created_at', 'distance_km', 'avg_duration_minutes'
  bool _ascending = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadRoutes();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final routes = await _repository.getAllRoutes(
        query: _searchQuery,
        onlyFavorites: _activeTab == 1,
        riskFilter: _selectedRisk == 'Барлығы' ? null : _selectedRisk,
        sortBy: _sortBy,
        ascending: _ascending,
      );
      if (mounted) {
        setState(() {
          _routes = routes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Деректерді жүктеу кезінде қате орын алды: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(_errorMessage!),
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite(RouteModel route) async {
    try {
      final newFav = await _repository.toggleFavorite(route.id);
      await _loadRoutes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1),
            backgroundColor: newFav ? AppColors.warning : AppColors.textSecondary,
            content: Text(
              newFav
                  ? '«${route.title}» таңдаулыларға қосылды ⭐'
                  : '«${route.title}» таңдаулылардан алынды',
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Таңдаулы мәртебесін өзгерту сәтсіз: $e');
    }
  }

  Future<void> _confirmDeleteRoute(RouteModel route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Бағытты өшіру', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('«${route.title}» бағытын деректер қорынан өшіруді растайсыз ба?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Жоқ', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Өшіру'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteRoute(route.id);
        await _loadRoutes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.textPrimary,
              content: Text('Бағыт сәтті өшірілді 🗑️'),
            ),
          );
        }
      } catch (e) {
        _showErrorSnackBar('Өшіру кезінде қате орын алды: $e');
      }
    }
  }

  void _showAddOrEditRouteDialog({RouteModel? existingRoute}) {
    final isEdit = existingRoute != null;
    final titleCtrl = TextEditingController(text: existingRoute?.title ?? '');
    final distCtrl = TextEditingController(
      text: existingRoute != null ? existingRoute.distanceKm.toString() : '',
    );
    final durCtrl = TextEditingController(
      text: existingRoute != null ? existingRoute.avgDurationMinutes.toString() : '',
    );
    final notesCtrl = TextEditingController(text: existingRoute?.notes ?? '');
    String selectedRisk = existingRoute?.riskLevel ?? 'Төмен (Жарықтандырылған)';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Бағытты өңдеу (Update)' : 'Жаңа бағыт қосу (Create)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: titleCtrl,
                        label: 'Бағыт атауы',
                        hintText: 'Мысалы: Павлодар — Семей',
                        prefixIcon: Icons.alt_route_rounded,
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Атауын жазыңыз' : null,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: distCtrl,
                        label: 'Қашықтығы (км)',
                        hintText: 'Мысалы: 340',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.straighten_rounded,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Қашықтықты енгізіңіз';
                          }
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Оң сандық мән енгізіңіз';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: durCtrl,
                        label: 'Орташа уақыты (минутпен)',
                        hintText: 'Мысалы: 240 (4 сағат)',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.timer_outlined,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Уақытты минутпен жазыңыз';
                          }
                          final parsed = int.tryParse(val.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Дұрыс минут санын енгізіңіз';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Қауіп деңгейі:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          'Төмен (Жарықтандырылған)',
                          'Орташа (Түнгі учаскелер)',
                          'Қатерлі (Монотонды жол)',
                        ].map((level) {
                          final isSelected = selectedRisk == level;
                          return ChoiceChip(
                            label: Text(
                              level,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceMuted,
                            onSelected: (val) {
                              if (val) {
                                setModalState(() => selectedRisk = level);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: notesCtrl,
                        label: 'Қосымша ескертпелер',
                        hintText: 'Жол сапасы, демалыс орындары туралы',
                        prefixIcon: Icons.notes_rounded,
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        text: isEdit ? 'Өзгерістерді сақтау' : 'Бағытты сақтау',
                        onPressed: () async {
                          if (formKey.currentState?.validate() ?? false) {
                            final route = RouteModel(
                              id: existingRoute?.id ??
                                  'route-${DateTime.now().millisecondsSinceEpoch}',
                              title: titleCtrl.text.trim(),
                              distanceKm: double.parse(distCtrl.text.trim()),
                              avgDurationMinutes: int.parse(durCtrl.text.trim()),
                              riskLevel: selectedRisk,
                              isFavorite: existingRoute?.isFavorite ?? false,
                              notes: notesCtrl.text.trim(),
                              createdAt: existingRoute?.createdAt ?? DateTime.now(),
                            );

                            try {
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);
                              if (isEdit) {
                                await _repository.updateRoute(route);
                              } else {
                                await _repository.addRoute(route);
                              }
                              navigator.pop();
                              await _loadRoutes();
                              messenger.showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.success,
                                  content: Text(
                                    isEdit
                                        ? 'Бағыт өзгерістері сақталды! ✅'
                                        : 'Жаңа бағыт сәтті қосылды! ✅',
                                  ),
                                ),
                              );
                            } catch (e) {
                              _showErrorSnackBar('Сақтау кезінде қате орын алды: $e');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(message),
        ),
      );
    }
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Бағыттарды сұрыптау',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.schedule_rounded, color: AppColors.primary),
                title: const Text('Қосылған уақыты бойынша'),
                trailing: _sortBy == 'created_at'
                    ? Icon(
                        _ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_sortBy == 'created_at') {
                      _ascending = !_ascending;
                    } else {
                      _sortBy = 'created_at';
                      _ascending = false;
                    }
                  });
                  Navigator.of(ctx).pop();
                  _loadRoutes();
                },
              ),
              ListTile(
                leading: const Icon(Icons.straighten_rounded, color: AppColors.primary),
                title: const Text('Қашықтығы бойынша (км)'),
                trailing: _sortBy == 'distance_km'
                    ? Icon(
                        _ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_sortBy == 'distance_km') {
                      _ascending = !_ascending;
                    } else {
                      _sortBy = 'distance_km';
                      _ascending = true;
                    }
                  });
                  Navigator.of(ctx).pop();
                  _loadRoutes();
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: AppColors.primary),
                title: const Text('Орташа уақыты бойынша'),
                trailing: _sortBy == 'avg_duration_minutes'
                    ? Icon(
                        _ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_sortBy == 'avg_duration_minutes') {
                      _ascending = !_ascending;
                    } else {
                      _sortBy = 'avg_duration_minutes';
                      _ascending = true;
                    }
                  });
                  Navigator.of(ctx).pop();
                  _loadRoutes();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForRisk(String risk) {
    if (risk.contains('Қатерлі')) return Icons.terrain_rounded;
    if (risk.contains('Төмен')) return Icons.alt_route_rounded;
    return Icons.directions_car_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Іздеу және Бағыттар'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: AppColors.primary),
            tooltip: 'Сұрыптау',
            onPressed: _showSortDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Бағыт қосу',
            onPressed: () => _showAddOrEditRouteDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRoutes,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input Box
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Сапар немесе тасжолды іздеу...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Tabs (Барлығы / Таңдаулылар)
                Container(
                  height: 42,
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
                            setState(() => _activeTab = 0);
                            _loadRoutes();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _activeTab == 0 ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _activeTab == 0
                                  ? const [
                                      BoxShadow(
                                        color: AppColors.shadow,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Барлық бағыттар',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _activeTab == 0
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
                            setState(() => _activeTab = 1);
                            _loadRoutes();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _activeTab == 1 ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _activeTab == 1
                                  ? const [
                                      BoxShadow(
                                        color: AppColors.shadow,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: _activeTab == 1
                                      ? AppColors.warning
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _activeTab == 1 ? 'Таңдаулылар (${_routes.length})' : 'Таңдаулылар',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _activeTab == 1
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Risk Filter Chips (Сүзгілер)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'Барлығы',
                      'Төмен',
                      'Орташа',
                      'Қатерлі',
                    ].map((risk) {
                      final isSelected = _selectedRisk == risk;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(risk),
                          selected: isSelected,
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _selectedRisk = risk;
                            });
                            _loadRoutes();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Header Info Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _activeTab == 0 ? 'Тасжолдар тізімі 🛣️' : 'Таңдаулы трассалар ⭐',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_routes.length} бағыт',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Body content: Loading / Empty State / List
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_routes.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Бағыттар табылмады',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchQuery.isNotEmpty
                              ? '«$_searchQuery» бойынша сәйкес бағыт табылмады'
                              : _activeTab == 1
                                  ? 'Сізде әлі таңдаулыға сақталған бағыттар жоқ'
                                  : 'Деректер қоры бос. Жаңа бағыт қосыңыз!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_searchQuery.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => _searchController.clear(),
                            icon: const Icon(Icons.clear_all_rounded, size: 18),
                            label: const Text('Іздеуді тазарту'),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () => _showAddOrEditRouteDialog(),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Жаңа бағыт қосу'),
                          ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _routes.length,
                    itemBuilder: (context, index) {
                      final route = _routes[index];
                      final isFav = route.isFavorite;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getIconForRisk(route.riskLevel),
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    route.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${route.formattedDistance} • ${route.formattedDuration}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (route.notes.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      route.notes,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      route.riskLevel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Action buttons: Edit, Delete, Favorite
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded,
                                  color: AppColors.textSecondary, size: 20),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showAddOrEditRouteDialog(existingRoute: route);
                                } else if (val == 'delete') {
                                  _confirmDeleteRoute(route);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_rounded,
                                          size: 18, color: AppColors.primary),
                                      SizedBox(width: 8),
                                      Text('Өңдеу'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded,
                                          size: 18, color: AppColors.danger),
                                      SizedBox(width: 8),
                                      Text('Өшіру'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: isFav ? AppColors.warning : AppColors.textMuted,
                                size: 24,
                              ),
                              onPressed: () => _toggleFavorite(route),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
