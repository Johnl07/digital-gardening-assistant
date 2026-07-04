import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/plant_input.dart';
import '../models/prediction_log.dart';
import '../services/cellular_automata_engine.dart';
import '../services/recommendation_engine.dart';
import '../services/storage_service.dart';

// ─── iOS Design Tokens ────────────────────────────────────────────────────────
class _iOS {
  // System Colors (Light mode, matching iOS exactly)
  static const bg = Colors.white;
  static const cardBg       = Color(0xFFFFFFFF);
  static const groupedBg    = Color(0xFFFFFFFF);
  static const separator    = Color(0xFFC6C6C8);
  static const fill         = Color(0xFFE5E5EA);

  static const labelPrimary   = Color(0xFF000000);
  static const labelSecondary = Color(0xFF8E8E93);
  static const labelTertiary  = Color(0xFFC7C7CC);

  static const systemGreen = Color(0xFF34C759);
  static const systemBlue  = Color(0xFF007AFF);
  static const systemRed   = Color(0xFFFF3B30);
  static const systemAmber = Color(0xFFFF9500);

  // Radius
  static const r10 = BorderRadius.all(Radius.circular(10));
  static const r13 = BorderRadius.all(Radius.circular(13));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));

  static BoxDecoration card({double radius = 13}) => BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))],
  );

  static BoxDecoration groupedCard = BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(13),
  );
}
// ──────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  final _formKey = GlobalKey<FormState>();
  String _selectedVegetable = 'Tomato';
  DateTime _selectedDate = DateTime.now();
  GrowthStage _selectedStage = GrowthStage.seedling;
  Season _selectedSeason = Season.dry;
  SunlightLevel _selectedSunlight = SunlightLevel.medium;
  WaterLevel _selectedWater = WaterLevel.medium;
  SoilQuality _selectedSoil = SoilQuality.moderate;

  List<PredictionLog> _historyLogs = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryLogs();
  }

  Future<void> _loadHistoryLogs() async {
    final logs = await StorageService.loadLogs();
    setState(() => _historyLogs = logs);
  }

  Future<void> _addPlantToGarden() async {

    final input = PlantInput(
      vegetableType: _selectedVegetable,
      plantingDate: _selectedDate,
      currentStage: _selectedStage,
      season: _selectedSeason,
      sunlight: _selectedSunlight,
      water: _selectedWater,
      soil: _selectedSoil,
    );

    final prediction = CellularAutomataEngine.predictGrowth(input);
    final recs = RecommendationEngine.evaluate(input);

    final newPlant = PredictionLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      input: input,
      predictedStage: prediction.timeline.last.stage,
      healthStatus: recs.healthStatus,
      recommendations: recs.recommendations,
      timestamp: DateTime.now(),
      careLogs: [],
    );

    await StorageService.saveLog(newPlant);
    await _loadHistoryLogs();

    if (mounted) {
      _showIOSSnackbar(context, '${_cropName(_selectedVegetable)} added to Garden!', _iOS.systemGreen);
      setState(() => _tabIndex = 1);
    }
  }

  Future<void> _deletePlant(String id) async {
    await StorageService.deleteLog(id);
    await _loadHistoryLogs();
  }

  Future<void> _clearAllPlants() async {
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete All?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () async {
            Navigator.pop(ctx);
            await StorageService.clearLogs();
            await _loadHistoryLogs();
          }, child: const Text('Delete')),
        ],
      ),
    );
  }

  void _showIOSSnackbar(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: color,
      content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      duration: const Duration(seconds: 2),
    ));
  }

  String _cropName(String v) => v.contains('Tomato') ? 'Tomato' : v.contains('Eggplant') ? 'Eggplant' : 'Chili';
  String _cropEmoji(String v) => v.contains('Tomato') ? '🍅' : v.contains('Eggplant') ? '🍆' : '🌶️';

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _iOS.bg,
      body: IndexedStack(index: _tabIndex, children: [
        _buildAddTab(),
        _buildGardenTab(),
      ]),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        border: Border(top: BorderSide(color: _iOS.separator, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(0, CupertinoIcons.plus_circle_fill, 'Add'),
              _buildTabItem(1, CupertinoIcons.leaf_arrow_circlepath, 'Garden'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isActive = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 100,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 26, color: isActive ? _iOS.systemGreen : _iOS.labelTertiary),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? _iOS.systemGreen : _iOS.labelTertiary)),
        ]),
      ),
    );
  }

  // ─── ADD PLANT TAB ────────────────────────────────────────────────────────────

  Widget _buildAddTab() {
    return CustomScrollView(
      slivers: [
        // Large iOS-style Navigation Title
        SliverAppBar(
          backgroundColor: _iOS.bg,
          pinned: true,
          expandedHeight: 110,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          surfaceTintColor: Colors.transparent,
          shadowColor: _iOS.separator,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 14),
            title: const Text('Add Plant', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _iOS.labelPrimary)),
            expandedTitleScale: 1.9,
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(delegate: SliverChildListDelegate([
            // Welcome card
            _buildWelcomeCard(),
            const SizedBox(height: 28),

            // Crop picker
            _buildGroupHeader('Select Plant'),
            _buildCropPicker(),
            const SizedBox(height: 28),

            // Date
            _buildGroupHeader('Planting Date'),
            _buildDateRow(),
            const SizedBox(height: 28),

            // Stage & Season
            _buildGroupHeader('Stage & Season'),
            _buildStageSeasonGroup(),
            const SizedBox(height: 28),

            // Environment
            _buildGroupHeader('Conditions'),
            _buildEnvironmentGroup(),
            const SizedBox(height: 32),

            // Submit
            _buildiOSButton(),
            const SizedBox(height: 16),
          ])),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_iOS.systemGreen.withOpacity(0.12), _iOS.systemGreen.withOpacity(0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _iOS.systemGreen.withOpacity(0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        const Text('🌿', style: TextStyle(fontSize: 36)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Welcome to Digital Garden!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _iOS.labelPrimary)),
          const SizedBox(height: 3),
          Text('${_historyLogs.length} plants in your garden. Add a new one and track its growth.', style: const TextStyle(fontSize: 12.5, color: _iOS.labelSecondary, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _buildGroupHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _iOS.labelSecondary, letterSpacing: 0.5)),
    );
  }

  Widget _buildCropPicker() {
    final crops = [
      ('Tomato', '🍅', 'Tomato'),
      ('Eggplant', '🍆', 'Eggplant'),
      ('Siling Labuyo', '🌶️', 'Chili'),
    ];
    return Container(
      decoration: _iOS.groupedCard,
      clipBehavior: Clip.antiAlias,
      child: Column(children: List.generate(crops.length, (i) {
        final (value, emoji, label) = crops[i];
        final isSel = _selectedVegetable == value;
        final isLast = i == crops.length - 1;
        return Column(children: [
          InkWell(
            onTap: () => setState(() => _selectedVegetable = value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: const TextStyle(fontSize: 16, color: _iOS.labelPrimary))),
                if (isSel) const Icon(CupertinoIcons.checkmark_alt, size: 18, color: _iOS.systemGreen),
              ]),
            ),
          ),
          if (!isLast) const Divider(height: 0.5, indent: 52, color: _iOS.separator),
        ]);
      })),
    );
  }

  Widget _buildDateRow() {
    return Container(
      decoration: _iOS.groupedCard,
      child: InkWell(
        onTap: () async {
          final picked = await showCupertinoModalPopup<DateTime>(
            context: context,
            builder: (ctx) {
              DateTime temp = _selectedDate;
              return Container(
                height: 300,
                color: _iOS.cardBg,
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    CupertinoButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
                    CupertinoButton(child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)), onPressed: () => Navigator.pop(ctx, temp)),
                  ]),
                  Expanded(child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _selectedDate,
                    maximumDate: DateTime.now(),
                    minimumDate: DateTime(2025),
                    onDateTimeChanged: (d) => temp = d,
                  )),
                ]),
              );
            },
          );
          if (picked != null) setState(() => _selectedDate = picked);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            const Icon(CupertinoIcons.calendar, size: 20, color: _iOS.systemRed),
            const SizedBox(width: 14),
            const Expanded(child: Text('Planting Date', style: TextStyle(fontSize: 16, color: _iOS.labelPrimary))),
            Text(
              '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
              style: const TextStyle(fontSize: 15, color: _iOS.labelSecondary),
            ),
            const SizedBox(width: 6),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: _iOS.labelTertiary),
          ]),
        ),
      ),
    );
  }

  Widget _buildStageSeasonGroup() {
    return Container(
      decoration: _iOS.groupedCard,
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // Stage row
        InkWell(
          onTap: () => _showPicker(
            context, 'Select Stage', GrowthStage.values,
            _selectedStage, (v) => setState(() => _selectedStage = v as GrowthStage),
            (v) => '${(v as GrowthStage).nameEnglish}',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              const Icon(CupertinoIcons.tree, size: 20, color: _iOS.systemGreen),
              const SizedBox(width: 14),
              const Expanded(child: Text('Current Stage', style: TextStyle(fontSize: 16, color: _iOS.labelPrimary))),
              Text(_selectedStage.nameEnglish, style: const TextStyle(fontSize: 14, color: _iOS.labelSecondary)),
              const SizedBox(width: 6),
              const Icon(CupertinoIcons.chevron_right, size: 14, color: _iOS.labelTertiary),
            ]),
          ),
        ),
        const Divider(height: 0.5, indent: 50, color: _iOS.separator),

        // Season row
        InkWell(
          onTap: () => _showPicker(
            context, 'Select Season', Season.values,
            _selectedSeason, (v) => setState(() => _selectedSeason = v as Season),
            (v) => '${(v as Season).nameEnglish}',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              const Icon(CupertinoIcons.cloud_sun, size: 20, color: _iOS.systemAmber),
              const SizedBox(width: 14),
              const Expanded(child: Text('Season', style: TextStyle(fontSize: 16, color: _iOS.labelPrimary))),
              Text(_selectedSeason.nameEnglish, style: const TextStyle(fontSize: 14, color: _iOS.labelSecondary)),
              const SizedBox(width: 6),
              const Icon(CupertinoIcons.chevron_right, size: 14, color: _iOS.labelTertiary),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _showPicker(BuildContext context, String title, List<dynamic> items, dynamic selected, Function(dynamic) onChanged, String Function(dynamic) labelFor) {
    return showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        color: _iOS.bg,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            color: _iOS.cardBg,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              GestureDetector(onTap: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: _iOS.systemGreen, fontSize: 16))),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              GestureDetector(onTap: () => Navigator.pop(ctx), child: const Text('Done', style: TextStyle(color: _iOS.systemGreen, fontWeight: FontWeight.w700, fontSize: 16))),
            ]),
          ),
          ...items.map((item) {
            final isSel = selected == item;
            return Column(children: [
              InkWell(
                onTap: () { onChanged(item); Navigator.pop(ctx); },
                child: Container(
                  color: _iOS.cardBg,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(children: [
                    Expanded(child: Text(labelFor(item), style: const TextStyle(fontSize: 16, color: _iOS.labelPrimary))),
                    if (isSel) const Icon(CupertinoIcons.checkmark_alt, color: _iOS.systemGreen, size: 18),
                  ]),
                ),
              ),
              const Divider(height: 0.5, indent: 20, color: _iOS.separator),
            ]);
          }),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildEnvironmentGroup() {
    return Container(
      decoration: _iOS.groupedCard,
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        _buildEnvRow(
          icon: CupertinoIcons.sun_max_fill, iconColor: _iOS.systemAmber,
          label: 'Sunlight',
          values: SunlightLevel.values, selected: _selectedSunlight,
          labelFor: (v) => (v as SunlightLevel).nameEnglish,
          onChanged: (v) => setState(() => _selectedSunlight = v as SunlightLevel),
          isLast: false,
        ),
        _buildEnvRow(
          icon: CupertinoIcons.drop_fill, iconColor: _iOS.systemBlue,
          label: 'Water Level',
          values: WaterLevel.values, selected: _selectedWater,
          labelFor: (v) => (v as WaterLevel).nameEnglish,
          onChanged: (v) => setState(() => _selectedWater = v as WaterLevel),
          isLast: false,
        ),
        _buildEnvRow(
          icon: CupertinoIcons.layers_fill, iconColor: const Color(0xFF8B572A),
          label: 'Soil Quality',
          values: SoilQuality.values, selected: _selectedSoil,
          labelFor: (v) => (v as SoilQuality).nameEnglish,
          onChanged: (v) => setState(() => _selectedSoil = v as SoilQuality),
          isLast: true,
        ),
      ]),
    );
  }

  Widget _buildEnvRow({
    required IconData icon, required Color iconColor,
    required String label,
    required List<dynamic> values, required dynamic selected,
    required String Function(dynamic) labelFor,
    required Function(dynamic) onChanged, required bool isLast,
  }) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _iOS.labelPrimary)),
          ]),
          const SizedBox(height: 10),
          Row(children: values.map((val) {
            final isSel = selected == val;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => onChanged(val),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isSel ? _iOS.systemGreen : _iOS.fill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text(
                    labelFor(val),
                    style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.w700 : FontWeight.normal, color: isSel ? Colors.white : _iOS.labelSecondary),
                  )),
                ),
              ),
            ));
          }).toList()),
        ]),
      ),
      if (!isLast) const Divider(height: 0.5, indent: 16, color: _iOS.separator),
    ]);
  }

  Widget _buildiOSButton() {
    return GestureDetector(
      onTap: _addPlantToGarden,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _iOS.systemGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(CupertinoIcons.add_circled_solid, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('Add to Garden', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  // ─── GARDEN TAB ───────────────────────────────────────────────────────────────

  Widget _buildGardenTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: _iOS.bg,
          pinned: true,
          expandedHeight: 110,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          surfaceTintColor: Colors.transparent,
          shadowColor: _iOS.separator,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 14),
            title: Text(
              _historyLogs.isEmpty ? 'Garden' : 'Garden  (${_historyLogs.length})',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _iOS.labelPrimary),
            ),
            expandedTitleScale: 1.9,
          ),
          actions: [
            if (_historyLogs.isNotEmpty)
              CupertinoButton(
                padding: const EdgeInsets.only(right: 16),
                onPressed: _clearAllPlants,
                child: const Text('Clear All', style: TextStyle(color: _iOS.systemRed, fontSize: 14)),
              ),
          ],
        ),

        if (_historyLogs.isEmpty)
          SliverFillRemaining(child: _buildEmptyGarden())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (context, index) {
                final plant = _historyLogs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPlantRow(plant),
                );
              },
              childCount: _historyLogs.length,
            )),
          ),
      ],
    );
  }

  Widget _buildEmptyGarden() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🪴', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('No Plants Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _iOS.labelPrimary)),
      const SizedBox(height: 6),
      const Text('Tap Add to get started.', style: TextStyle(color: _iOS.labelSecondary, fontSize: 14)),
      const SizedBox(height: 24),
      CupertinoButton(
        color: _iOS.systemGreen,
        borderRadius: BorderRadius.circular(12),
        onPressed: () => setState(() => _tabIndex = 0),
        child: const Text('Add Plant'),
      ),
    ]));
  }

  Widget _buildPlantRow(PredictionLog plant) {
    final pred = CellularAutomataEngine.predictGrowth(plant.input);
    final elapsed = DateTime.now().difference(plant.input.plantingDate).inDays;
    final daysLeft = (pred.totalDaysToHarvest - elapsed).clamp(0, pred.totalDaysToHarvest);
    final progress = (elapsed / pred.totalDaysToHarvest).clamp(0.0, 1.0);
    final isHealthy = plant.healthStatus == 'Healthy';

    return GestureDetector(
      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (ctx) => PlantDetailScreen(
        plant: plant,
        onUpdate: (updated) async {
          await StorageService.updateLog(updated);
          _loadHistoryLogs();
        },
      ))),
      child: Container(
        decoration: _iOS.card(radius: 16),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          // Crop emoji circle
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: _iOS.fill, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(_cropEmoji(plant.input.vegetableType), style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(_cropName(plant.input.vegetableType), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _iOS.labelPrimary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isHealthy ? _iOS.systemGreen.withOpacity(0.12) : _iOS.systemAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(isHealthy ? 'Healthy' : 'Deficient', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isHealthy ? _iOS.systemGreen : _iOS.systemAmber)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              daysLeft > 0 ? '🌾  $daysLeft days until harvest' : '🎉  Ready for harvest!',
              style: TextStyle(fontSize: 12.5, color: daysLeft <= 14 ? _iOS.systemAmber : _iOS.labelSecondary),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress, minHeight: 5,
                backgroundColor: _iOS.fill,
                valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? _iOS.systemAmber : _iOS.systemGreen),
              ),
            ),
            const SizedBox(height: 4),
            Text('${plant.careLogs.length} activities logged', style: const TextStyle(fontSize: 11, color: _iOS.labelTertiary)),
          ])),

          // Chevron
          const SizedBox(width: 8),
          Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Icon(CupertinoIcons.chevron_right, size: 16, color: _iOS.labelTertiary),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () async {
                await showCupertinoDialog(context: context, builder: (ctx) => CupertinoAlertDialog(
                  title: const Text('Delete?'),
                  content: const Text('Are you sure you want to delete this plant?'),
                  actions: [
                    CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(ctx), child: const Text('No')),
                    CupertinoDialogAction(isDestructiveAction: true, onPressed: () async { Navigator.pop(ctx); await _deletePlant(plant.id); }, child: const Text('Delete')),
                  ],
                ));
              },
              child: const Icon(CupertinoIcons.trash, size: 16, color: _iOS.systemRed),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── PLANT DETAIL SCREEN ──────────────────────────────────────────────────────

class PlantDetailScreen extends StatefulWidget {
  final PredictionLog plant;
  final Function(PredictionLog) onUpdate;
  const PlantDetailScreen({super.key, required this.plant, required this.onUpdate});
  @override State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late PredictionLog _plant;
  late GrowthPredictionResult _prediction;
  late int _currentDay;

  final List<(IconData, String)> _quickActions = [
    (CupertinoIcons.drop_fill, 'Watered'),
    (CupertinoIcons.leaf_arrow_circlepath, 'Fertilized'),
    (CupertinoIcons.scissors, 'Weeded'),
    (CupertinoIcons.cloud_rain, 'Protected from Rain'),
    (CupertinoIcons.arrow_swap, 'Moved Location'),
  ];

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    _prediction = CellularAutomataEngine.predictGrowth(_plant.input);
    final elapsed = DateTime.now().difference(_plant.input.plantingDate).inDays;
    _currentDay = elapsed.clamp(0, _prediction.totalDaysToHarvest);
  }

  Future<void> _logAction(String action) async {
    final exists = _plant.careLogs.any((l) => l.dayOffset == _currentDay);
    if (exists) {
      final confirm = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Add Again?'),
          content: Text('An activity already exists for Day $_currentDay. Add anyway?'),
          actions: [
            CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final updatedLogs = List<DailyAction>.from(_plant.careLogs)
      ..add(DailyAction(dayOffset: _currentDay, action: action, timestamp: DateTime.now()));

    setState(() {
      _plant = PredictionLog(id: _plant.id, input: _plant.input, predictedStage: _plant.predictedStage,
        healthStatus: _plant.healthStatus, recommendations: _plant.recommendations,
        timestamp: _plant.timestamp, careLogs: updatedLogs);
    });
    widget.onUpdate(_plant);
  }

  String _cropEmoji(String v) => v.contains('Tomato') ? '🍅' : v.contains('Eggplant') ? '🍆' : '🌶️';
  String _cropName(String v) => v.contains('Tomato') ? 'Kamatis' : v.contains('Eggplant') ? 'Talong' : 'Sili';

  String _stageEmoji(GrowthStage s) {
    switch (s) {
      case GrowthStage.seedling: return '🌱';
      case GrowthStage.youngPlant: return '🌿';
      case GrowthStage.flowering: return '🌼';
      case GrowthStage.fruiting: return '🍎';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayPred = _prediction.timeline[_currentDay];
    final daysLeft = _prediction.totalDaysToHarvest - _currentDay;
    final progress = _currentDay / _prediction.totalDaysToHarvest;
    final filteredLogs = _plant.careLogs.where((l) => l.dayOffset == _currentDay).toList();

    return Scaffold(
      backgroundColor: _iOS.bg,
      appBar: AppBar(
        backgroundColor: _iOS.bg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: _iOS.separator,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(CupertinoIcons.back, color: _iOS.systemGreen),
            SizedBox(width: 2),
            Text('Garden', style: TextStyle(color: _iOS.systemGreen)),
          ]),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 100,
        title: Text(_cropName(_plant.input.vegetableType), style: const TextStyle(color: _iOS.labelPrimary, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── Harvest Hero ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: daysLeft <= 14 ? _iOS.systemAmber : _iOS.systemGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              Text(_cropEmoji(_plant.input.vegetableType), style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 10),
              Text(
                daysLeft > 0 ? 'Harvest sa $daysLeft na Araw' : 'Handa na para Anihin! 🎉',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text('Araw $_currentDay / ${_prediction.totalDaysToHarvest}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 14),
              ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
                value: progress, minHeight: 8,
                backgroundColor: Colors.white30,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              )),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Day Navigator ──
          Container(
            decoration: _iOS.card(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: _currentDay > 0 ? () => setState(() => _currentDay--) : null,
                child: const Icon(CupertinoIcons.back, size: 20, color: _iOS.systemGreen),
              ),
              Column(children: [
                Text('Araw $_currentDay', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _iOS.labelPrimary)),
                Text(
                  '${_plant.input.plantingDate.add(Duration(days: _currentDay)).month}/${_plant.input.plantingDate.add(Duration(days: _currentDay)).day}/${_plant.input.plantingDate.add(Duration(days: _currentDay)).year}',
                  style: const TextStyle(fontSize: 12, color: _iOS.labelSecondary),
                ),
              ]),
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: _currentDay < _prediction.totalDaysToHarvest ? () => setState(() => _currentDay++) : null,
                child: const Icon(CupertinoIcons.forward, size: 20, color: _iOS.systemGreen),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Stats row ──
          Row(children: [
            Expanded(child: _infoTile(_stageEmoji(dayPred.stage), dayPred.stage.nameTagalog, 'Stage')),
            const SizedBox(width: 10),
            Expanded(child: _infoTile(
              dayPred.healthScore >= 0.7 ? '💚' : dayPred.healthScore >= 0.4 ? '💛' : '❤️',
              '${(dayPred.healthScore * 100).round()}%', 'Kalusugan',
            )),
          ]),
          const SizedBox(height: 12),

          // ── Milestone ──
          if (dayPred.milestone.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _iOS.systemAmber.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _iOS.systemAmber.withOpacity(0.3))),
              child: Row(children: [
                const Icon(CupertinoIcons.flag_fill, color: _iOS.systemAmber, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(dayPred.milestone, style: const TextStyle(color: _iOS.systemAmber, fontWeight: FontWeight.w600, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // ── Tip ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _iOS.card(),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(CupertinoIcons.lightbulb_fill, color: _iOS.systemAmber, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('PAYO NGAYON', style: TextStyle(fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w700, color: _iOS.labelSecondary)),
                const SizedBox(height: 4),
                Text(dayPred.dailyTip, style: const TextStyle(fontSize: 13.5, color: _iOS.labelPrimary, height: 1.5)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Log Activity Section ──
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text('I-LOG ANG AKTIBIDAD — ARAW $_currentDay'.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _iOS.labelSecondary, letterSpacing: 0.4)),
          ),
          Container(
            decoration: _iOS.groupedCard,
            clipBehavior: Clip.antiAlias,
            child: Column(children: List.generate(_quickActions.length, (i) {
              final (icon, action) = _quickActions[i];
              final isLast = i == _quickActions.length - 1;
              return Column(children: [
                InkWell(
                  onTap: () => _logAction(action),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    child: Row(children: [
                      Icon(icon, size: 18, color: _iOS.systemGreen),
                      const SizedBox(width: 14),
                      Expanded(child: Text(action, style: const TextStyle(fontSize: 15, color: _iOS.labelPrimary))),
                      const Icon(CupertinoIcons.add, size: 16, color: _iOS.systemGreen),
                    ]),
                  ),
                ),
                if (!isLast) const Divider(height: 0.5, indent: 48, color: _iOS.separator),
              ]);
            })),
          ),
          const SizedBox(height: 20),

          // ── Logged for this day ──
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text('NAITALA (${filteredLogs.length})'.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _iOS.labelSecondary, letterSpacing: 0.4)),
          ),
          Container(
            decoration: _iOS.groupedCard,
            clipBehavior: Clip.antiAlias,
            child: filteredLogs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Wala pang naitalang aktibidad sa araw na ito.', style: TextStyle(color: _iOS.labelSecondary, fontSize: 14)),
                )
              : Column(children: List.generate(filteredLogs.length, (i) {
                  final log = filteredLogs[i];
                  final isLast = i == filteredLogs.length - 1;
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: [
                        const Icon(CupertinoIcons.checkmark_circle_fill, color: _iOS.systemGreen, size: 18),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(log.action, style: const TextStyle(fontSize: 14, color: _iOS.labelPrimary)),
                          Text('${log.timestamp.toLocal().toString().substring(0, 16)}', style: const TextStyle(fontSize: 11, color: _iOS.labelSecondary)),
                        ])),
                      ]),
                    ),
                    if (!isLast) const Divider(height: 0.5, indent: 46, color: _iOS.separator),
                  ]);
                })),
          ),
        ]),
      ),
    );
  }

  Widget _infoTile(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: _iOS.card(),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _iOS.labelPrimary)),
        Text(label, style: const TextStyle(fontSize: 11, color: _iOS.labelSecondary)),
      ]),
    );
  }
}
