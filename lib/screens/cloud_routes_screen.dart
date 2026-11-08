import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../controllers/cloud_routes_controller.dart';
import '../models/route_model.dart';
import '../services/api_exception.dart';
import '../utils/app_colors.dart';

/// Практикалық жұмыс №5: REST API арқылы бағыттарды басқару экраны.
/// GET (тізім), POST (қосу), PUT (өзгерту), PATCH (таңдаулы), DELETE (өшіру).
class CloudRoutesScreen extends StatefulWidget {
  final CloudRoutesController? controller;

  const CloudRoutesScreen({super.key, this.controller});

  @override
  State<CloudRoutesScreen> createState() => _CloudRoutesScreenState();
}

class _CloudRoutesScreenState extends State<CloudRoutesScreen> {
  late final CloudRoutesController _c;

  @override
  void initState() {
    super.initState();
    _c = widget.controller ?? CloudRoutesController();
    _c.loadRoutes();
  }

  @override
  void dispose() {
    if (widget.controller == null) _c.dispose();
    super.dispose();
  }

  // ==========================================
  // Операциялар
  // ==========================================

  Future<void> _run(Future<void> Function() action, String successText) async {
    try {
      await action();
      _showSnack(successText, AppColors.success, Icons.check_circle_rounded);
    } on ApiException catch (e) {
      _showSnack('${e.title}: ${e.message}', AppColors.danger,
          Icons.error_outline_rounded);
    } catch (e) {
      _showSnack('Қате: $e', AppColors.danger, Icons.error_outline_rounded);
    }
  }

  Future<void> _onAdd() async {
    final draft = await _openForm();
    if (draft == null) return;
    await _run(() => _c.addRoute(draft), 'POST: «${draft.title}» серверге қосылды');
  }

  Future<void> _onEdit(RouteModel route) async {
    final edited = await _openForm(initial: route);
    if (edited == null) return;
    await _run(() => _c.updateRoute(edited), 'PUT: «${edited.title}» жаңартылды');
  }

  Future<void> _onToggleFavorite(RouteModel route) async {
    await _run(
      () => _c.toggleFavorite(route),
      route.isFavorite
          ? 'PATCH: таңдаулылардан алынды'
          : 'PATCH: таңдаулыларға қосылды',
    );
  }

  Future<void> _onDelete(RouteModel route) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Бағытты өшіру'),
        content: Text('«${route.title}» серверден өшірілсін бе?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Болдырмау'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Өшіру'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() => _c.deleteRoute(route.id), 'DELETE: «${route.title}» өшірілді');
  }

  void _showSnack(String text, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ));
  }

  Future<RouteModel?> _openForm({RouteModel? initial}) {
    return showModalBottomSheet<RouteModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RouteForm(initial: initial),
    );
  }

  // ==========================================
  // UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Бұлттағы бағыттар',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'REST API · GET / POST / PUT / PATCH / DELETE',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              IconButton(
                key: const Key('refresh_button'),
                tooltip: 'Жаңарту (GET)',
                icon: const Icon(Icons.refresh_rounded),
                onPressed:
                    _c.status == RequestStatus.loading ? null : _c.loadRoutes,
              ),
              _buildSimulationMenu(),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: (_c.isMutating ||
                      (_c.status == RequestStatus.loading &&
                          _c.routes.isNotEmpty))
                  ? const LinearProgressIndicator(minHeight: 3)
                  : const SizedBox(height: 3),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('add_route_fab'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            onPressed: _c.isMutating ? null : _onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Қосу (POST)'),
          ),
          body: AbsorbPointer(
            absorbing: _c.isMutating,
            child: _buildBody(),
          ),
        );
      },
    );
  }

  Widget _buildSimulationMenu() {
    return PopupMenuButton<ApiSimulation>(
      tooltip: 'Тест режимі',
      icon: Icon(
        Icons.science_outlined,
        color: _c.simulation == ApiSimulation.none
            ? AppColors.textSecondary
            : AppColors.warning,
      ),
      initialValue: _c.simulation,
      onSelected: (v) {
        _c.simulation = v;
        _showSnack(
          switch (v) {
            ApiSimulation.none => 'Тест режимі: қалыпты сервер',
            ApiSimulation.slow =>
              'Тест режимі: баяу сервер (timeout ${ApiConfig.requestTimeout.inSeconds} с)',
            ApiSimulation.serverError => 'Тест режимі: сервер 500 қатесін береді',
          },
          AppColors.primary,
          Icons.science_outlined,
        );
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: ApiSimulation.none,
          child: ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('Қалыпты режим'),
          ),
        ),
        PopupMenuItem(
          value: ApiSimulation.slow,
          child: ListTile(
            leading: Icon(Icons.timer_off_outlined),
            title: Text('Баяу сервер (timeout)'),
          ),
        ),
        PopupMenuItem(
          value: ApiSimulation.serverError,
          child: ListTile(
            leading: Icon(Icons.dns_outlined),
            title: Text('Сервер қатесі (500)'),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    // 1. Loading күйі (алғашқы жүктеу)
    if ((_c.status == RequestStatus.loading ||
            _c.status == RequestStatus.initial) &&
        _c.routes.isEmpty) {
      return const Center(
        key: Key('loading_state'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Серверден деректер жүктелуде...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // 2. Error күйі
    if (_c.status == RequestStatus.error) {
      return _ErrorView(error: _c.error!, onRetry: _c.loadRoutes);
    }

    // 3. Success күйі
    return RefreshIndicator(
      onRefresh: _c.loadRoutes,
      child: ListView(
        key: const Key('success_state'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _buildSyncBanner(),
          const SizedBox(height: 12),
          if (_c.routes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: Text(
                  'Серверде бағыттар жоқ.\n«Қосу» батырмасы арқылы жаңасын қосыңыз.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ..._c.routes.map((r) => _RouteCard(
                  route: r,
                  readOnly: _c.fromCache,
                  onFavorite: () => _onToggleFavorite(r),
                  onEdit: () => _onEdit(r),
                  onDelete: () => _onDelete(r),
                )),
        ],
      ),
    );
  }

  Widget _buildSyncBanner() {
    final cached = _c.fromCache;
    final color = cached ? AppColors.warning : AppColors.success;
    final time = _c.lastSync;
    final timeText = time == null
        ? ''
        : ' · ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

    return Container(
      key: Key(cached ? 'cache_banner' : 'synced_banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(cached ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
              color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cached
                      ? 'Офлайн режим: локалды SQLite деректері'
                      : 'Сервермен синхрондалды$timeText',
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
                Text(
                  cached
                      ? '${_c.error?.title ?? ''}. Өзгерту үшін серверге қосылыңыз.'
                      : '${_c.routes.length} бағыт · локалды дерекқорға сақталды',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Қате күйінің виджеті
// ==========================================

class _ErrorView extends StatelessWidget {
  final ApiException error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  IconData get _icon {
    switch (error.type) {
      case ApiErrorType.noInternet:
        return Icons.wifi_off_rounded;
      case ApiErrorType.timeout:
        return Icons.timer_off_rounded;
      case ApiErrorType.server:
        return Icons.dns_rounded;
      case ApiErrorType.parsing:
        return Icons.data_object_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('error_state'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 48, color: AppColors.danger),
            ),
            const SizedBox(height: 20),
            Text(
              error.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (error.type == ApiErrorType.noInternet) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const SelectableText(
                  'dart run server/antisleep_api_server.dart',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('retry_button'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Қайталау'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Бағыт карточкасы
// ==========================================

class _RouteCard extends StatelessWidget {
  final RouteModel route;
  final bool readOnly;
  final VoidCallback onFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RouteCard({
    required this.route,
    required this.readOnly,
    required this.onFavorite,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _riskColor {
    if (route.riskLevel.contains('Қатерлі')) return AppColors.danger;
    if (route.riskLevel.contains('Орташа')) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  route.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Таңдаулы (PATCH)',
                onPressed: readOnly ? null : onFavorite,
                icon: Icon(
                  route.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: route.isFavorite
                      ? AppColors.warning
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(Icons.straighten_rounded, route.formattedDistance,
                  AppColors.primary),
              _chip(Icons.schedule_rounded, route.formattedDuration,
                  AppColors.primary),
              _chip(Icons.shield_outlined, route.riskLevel, _riskColor),
            ],
          ),
          if (route.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              route.notes,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'ID: ${route.id}',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: readOnly ? null : onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('PUT'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                onPressed: readOnly ? null : onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('DELETE'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Қосу / өзгерту формасы
// ==========================================

class _RouteForm extends StatefulWidget {
  final RouteModel? initial;

  const _RouteForm({this.initial});

  @override
  State<_RouteForm> createState() => _RouteFormState();
}

class _RouteFormState extends State<_RouteForm> {
  static const _risks = ['Төмен', 'Орташа', 'Қатерлі'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _distance;
  late final TextEditingController _duration;
  late final TextEditingController _notes;
  late String _risk;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _title = TextEditingController(text: r?.title ?? '');
    _distance = TextEditingController(
        text: r == null ? '' : r.distanceKm.toStringAsFixed(0));
    _duration = TextEditingController(
        text: r == null ? '' : r.avgDurationMinutes.toString());
    _notes = TextEditingController(text: r?.notes ?? '');
    _risk = _risks.firstWhere(
      (x) => r?.riskLevel.startsWith(x) ?? false,
      orElse: () => _risks.first,
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _distance.dispose();
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.initial;
    // Бұрынғы толық мәнді («Төмен (Жарықтандырылған)») сақтау,
    // егер деңгей өзгертілмесе.
    final risk = (base != null && base.riskLevel.startsWith(_risk))
        ? base.riskLevel
        : _risk;
    final result = RouteModel(
      id: base?.id ?? '',
      title: _title.text.trim(),
      distanceKm: double.parse(_distance.text.replaceAll(',', '.')),
      avgDurationMinutes: int.parse(_duration.text),
      riskLevel: risk,
      isFavorite: base?.isFavorite ?? false,
      notes: _notes.text.trim(),
      createdAt: base?.createdAt ?? DateTime.now(),
    );
    Navigator.pop(context, result);
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Толтырыңыз' : null;

  String? _positiveNumber(String? v) {
    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
    if (n == null || n <= 0) return 'Оң сан енгізіңіз';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEdit ? 'Бағытты өзгерту (PUT)' : 'Жаңа бағыт (POST)',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('form_title'),
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Бағыт атауы',
                  hintText: 'Алматы — Талдықорған',
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('form_distance'),
                      controller: _distance,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Қашықтық, км'),
                      validator: _positiveNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const Key('form_duration'),
                      controller: _duration,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Уақыты, мин'),
                      validator: (v) => int.tryParse(v ?? '') == null ||
                              int.parse(v!) <= 0
                          ? 'Бүтін сан'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _risk,
                decoration:
                    const InputDecoration(labelText: 'Қауіптілік деңгейі'),
                items: _risks
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _risk = v ?? _risk),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Ескертпе'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('form_submit'),
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_isEdit ? 'Серверде жаңарту' : 'Серверге жіберу'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

