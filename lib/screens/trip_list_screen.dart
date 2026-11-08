import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../widgets/session_history_item.dart';
import 'trip_detail_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final DatabaseService _dbService = DatabaseService.instance;
  List<SessionModel> _allTrips = [];
  bool _isLoading = true;
  int _selectedFilter = 0; // 0: Барлығы, 1: Қауіпсіз, 2: Қауіп тіркелген
  String _sortBy = 'start_time'; // 'start_time', 'safety_score'
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _dbService.getSessions(
        statusFilter: _selectedFilter == 1 ? 'Қауіпсіз' : null,
        onlyWithAlerts: _selectedFilter == 2,
        sortBy: _sortBy,
        ascending: _ascending,
      );
      if (mounted) {
        setState(() {
          _allTrips = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Сапарларды жүктеу кезінде қате: $e'),
          ),
        );
      }
    }
  }

  Future<bool?> _confirmDeleteSession(SessionModel session) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Сапарды өшіру'),
        content: Text('${session.duration.inMinutes} минуттық сапарды деректер қорынан өшіруді қалайсыз ба?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Жоқ'),
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
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Сапарларды сұрыптау',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.access_time_rounded, color: AppColors.primary),
              title: const Text('Уақыты бойынша'),
              trailing: _sortBy == 'start_time'
                  ? Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward,
                      color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() {
                  if (_sortBy == 'start_time') {
                    _ascending = !_ascending;
                  } else {
                    _sortBy = 'start_time';
                    _ascending = false;
                  }
                });
                Navigator.pop(ctx);
                _loadSessions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety_rounded, color: AppColors.primary),
              title: const Text('Қауіпсіздік ұпайы бойынша'),
              trailing: _sortBy == 'safety_score'
                  ? Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward,
                      color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() {
                  if (_sortBy == 'safety_score') {
                    _ascending = !_ascending;
                  } else {
                    _sortBy = 'safety_score';
                    _ascending = false;
                  }
                });
                Navigator.pop(ctx);
                _loadSessions();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalMinutes = 0;
    for (final s in _allTrips) {
      totalMinutes += s.duration.inMinutes;
    }
    final totalHours = totalMinutes ~/ 60;
    final remMins = totalMinutes % 60;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Сапарлар тарихы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Сұрыптау',
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSessions,
          child: Column(
            children: [
              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(0, 'Барлық сапарлар (${_allTrips.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip(1, 'Қауіпсіз'),
                      const SizedBox(width: 8),
                      _buildFilterChip(2, 'Қауіп дабылдары бар'),
                    ],
                  ),
                ),
              ),

              // Summary Stats Pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Жалпы бақыланған қашықтық:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        '$totalHours сағ $remMins мин',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Trips List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _allTrips.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_toggle_off_rounded,
                                    size: 48, color: AppColors.textMuted),
                                SizedBox(height: 12),
                                Text(
                                  'Бұл санатта әзірге сапарлар жоқ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Жаңа сапарды бастап, бақылауды жүргізіңіз',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            itemCount: _allTrips.length,
                            itemBuilder: (context, index) {
                              final trip = _allTrips[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Dismissible(
                                  key: Key(trip.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.danger,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(
                                      Icons.delete_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  confirmDismiss: (dir) => _confirmDeleteSession(trip),
                                  onDismissed: (dir) async {
                                    await _dbService.deleteSession(trip.id);
                                    _loadSessions();
                                  },
                                  child: SessionHistoryItem(
                                    session: trip,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TripDetailScreen(session: trip),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = index);
        _loadSessions();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
