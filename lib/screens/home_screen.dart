import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_input.dart';
import '../models/prediction_log.dart';
import '../services/cellular_automata_engine.dart';
import '../services/recommendation_engine.dart';
import '../services/storage_service.dart';

// ─── Minimalist Green & White Design System ──────────────────────────────────
class _Theme {
  static const primary = Color(0xFF2D6A4F);      // Fresh forest green
  static const primaryDark = Color(0xFF1B4332);  // Deep forest green
  static const accent = Color(0xFF52B788);       // Bright mint accent
  static const bg = Color(0xFFFAFAFA);           // Clean off-white background
  static const cardBg = Colors.white;            // White card background
  static const border = Color(0xFFE9EFEA);       // Very thin soft green-grey border
  static const textPrimary = Color(0xFF1B2E24);  // Charcoal deep green-black
  static const textSecondary = Color(0xFF5A7365);// Muted soft green-grey
  static const textTertiary = Color(0xFF9EBAAA); // Muted light green-grey

  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));

  static BoxDecoration card = BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: border, width: 1),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasStarted = false; // Tracks Onboarding/Intro state
  int _onboardingStep = 1;  // Onboarding step (1: intro, 2: name)
  String _userName = '';
  final _nameController = TextEditingController();
  int _tabIndex = 0;       // Bottom navigation index (0: Home, 1: Add Plant, 2: View Plants)

  // Form states
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
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
      _hasStarted = prefs.getBool('has_started') ?? false;
      if (_userName.isNotEmpty) {
        _nameController.text = _userName;
      }
    });
  }

  Future<void> _saveUserInfo(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setBool('has_started', true);
    setState(() {
      _userName = name;
      _hasStarted = true;
    });
  }

  Future<void> _loadHistoryLogs() async {
    final logs = await StorageService.loadLogs();
    setState(() => _historyLogs = logs);
  }

  (double, bool, List<String>) _getDynamicHealth(PredictionLog plant) {
    final pred = CellularAutomataEngine.predictGrowth(plant.input);
    final elapsed = DateTime.now().difference(plant.input.plantingDate).inDays;
    final currentDay = (elapsed + 1).clamp(1, pred.totalDaysToHarvest + 1);
    final dayPred = pred.timeline[(currentDay - 1).clamp(0, pred.totalDaysToHarvest)];
    final filteredLogs = plant.careLogs.where((l) => l.dayOffset == currentDay).toList();

    final dailyValidation = RecommendationEngine.validateDailyActions(
      crop: plant.input.vegetableType,
      stage: dayPred.stage,
      actions: filteredLogs,
    );

    final double rawHealth = dayPred.healthScore;
    final double adjustedHealth = (rawHealth + (dailyValidation.healthScoreModifier / 100)).clamp(0.0, 1.0);

    final isHealthyStatus = plant.healthStatus == 'Healthy' && 
                            dailyValidation.warnings.isEmpty && 
                            adjustedHealth >= 0.4;

    return (adjustedHealth, isHealthyStatus, dailyValidation.warnings);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _Theme.primary,
        content: Text('${_cropName(_selectedVegetable)} added successfully!', style: const TextStyle(fontWeight: FontWeight.w600)),
        duration: const Duration(seconds: 2),
      ));
      setState(() => _tabIndex = 2); // Switch to View Plants page
    }
  }

  Future<void> _deletePlant(String id) async {
    await StorageService.deleteLog(id);
    await _loadHistoryLogs();
  }

  Future<void> _clearAllPlants() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All?'),
        content: const Text('This action will delete all plants in your garden.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (clear == true) {
      await StorageService.clearLogs();
      await _loadHistoryLogs();
    }
  }

  String _cropName(String v) => v.contains('Tomato') ? 'Tomato' : v.contains('Eggplant') ? 'Eggplant' : 'Chili';
  String _cropEmoji(String v) => v.contains('Tomato') ? '🍅' : v.contains('Eggplant') ? '🍆' : '🌶️';

  @override
  Widget build(BuildContext context) {
    if (!_hasStarted) {
      return _buildOnboardingScreen();
    }

    return Scaffold(
      backgroundColor: _Theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),
            Expanded(
              child: IndexedStack(index: _tabIndex, children: [
                _buildHomeDashboardTab(),
                _buildAddPlantTab(),
                _buildViewPlantsTab(),
              ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ─── 1. ONBOARDING / INTRO SCREEN ──────────────────────────────────────────

  Widget _buildOnboardingScreen() {
    if (_onboardingStep == 1) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _Theme.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🌿', style: TextStyle(fontSize: 72)),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Digital Gardening\nAssistant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: _Theme.primaryDark,
                    height: 1.2,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'A virtual plant doctor and smart calendar tracker powered by Cellular Automata models.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _Theme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => setState(() => _onboardingStep = 2),
                  child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Text(
                  'What should we\ncall you?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: _Theme.primaryDark,
                    height: 1.2,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Enter your name...',
                    hintStyle: const TextStyle(color: _Theme.textTertiary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _Theme.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _Theme.primary, width: 2),
                    ),
                  ),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _Theme.textPrimary),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isNotEmpty) {
                      _saveUserInfo(name);
                    }
                  },
                  child: const Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    }
  }

  // ─── 2. TOP HEADER ─────────────────────────────────────────────────────────

  Widget _buildTopHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _Theme.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          const Text('🌿', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          const Text(
            'Garden Assistant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _Theme.primaryDark,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          if (_tabIndex == 2 && _historyLogs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              onPressed: _clearAllPlants,
              tooltip: 'Clear All Plants',
            ),
        ],
      ),
    );
  }

  // ─── 3. BOTTOM NAVIGATION BAR ──────────────────────────────────────────────

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _Theme.border, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _Theme.primary,
        unselectedItemColor: _Theme.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), activeIcon: Icon(Icons.add_circle), label: 'Add Plant'),
          BottomNavigationBarItem(icon: Icon(Icons.yard_outlined), activeIcon: Icon(Icons.yard), label: 'My Garden'),
        ],
      ),
    );
  }

  // ─── TAB 1: HOME / DASHBOARD & STATS ───────────────────────────────────────

  Widget _buildHomeDashboardTab() {
    final total = _historyLogs.length;
    final healthy = _historyLogs.where((l) => _getDynamicHealth(l).$2).length;
    final deficient = total - healthy;

    final tomatoes = _historyLogs.where((l) => l.input.vegetableType == 'Tomato').length;
    final eggplants = _historyLogs.where((l) => l.input.vegetableType == 'Eggplant').length;
    final chilis = _historyLogs.where((l) => l.input.vegetableType == 'Siling Labuyo').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Welcome Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _Theme.card,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _Theme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Text('🌱', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hello, ${_userName.isEmpty ? 'Gardener' : _userName}!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _Theme.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  total == 0 ? 'Start your digital garden by adding your first plant.' : 'Your digital garden is doing well. Explore stats below.',
                  style: const TextStyle(fontSize: 13, color: _Theme.textSecondary, height: 1.4),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // Statistics Title
        const Text('PLANT STATISTICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _Theme.textSecondary, letterSpacing: 0.8)),
        const SizedBox(height: 12),

        // Core Stats Grid
        Row(children: [
          Expanded(child: _statCard('Active Plants', '$total', 'Total', Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _statCard('Healthy', '$healthy', 'Status', _Theme.primary)),
          const SizedBox(width: 12),
          Expanded(child: _statCard('At Risk', '$deficient', 'At Risk', Colors.orange[800]!)),
        ]),
        const SizedBox(height: 24),

        // Crop Breakdown
        const Text('CROP DISTRIBUTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _Theme.textSecondary, letterSpacing: 0.8)),
        const SizedBox(height: 12),
        _buildCropDistributionBarGraph(tomatoes, eggplants, chilis, total),
        const SizedBox(height: 24),

        // Expert System Tip
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _Theme.primary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _Theme.primary.withOpacity(0.1)),
          ),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('DAILY GARDEN TIP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _Theme.textSecondary, letterSpacing: 0.8)),
                const SizedBox(height: 6),
                Text(
                  'Regular watering in the morning reduces leaf dampness and prevents fungal infections in high humidity climates.',
                  style: TextStyle(fontSize: 13.5, color: _Theme.textPrimary, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _statCard(String label, String value, String unit, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: _Theme.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _Theme.textSecondary)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: accentColor)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _Theme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropDistributionBarGraph(int tomatoes, int eggplants, int chilis, int total) {
    return Container(
      decoration: _Theme.card,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCropBar('🍅 Tomato', tomatoes, total, Colors.red[400]!),
          const SizedBox(height: 16),
          _buildCropBar('🍆 Eggplant', eggplants, total, Colors.purple[400]!),
          const SizedBox(height: 16),
          _buildCropBar('🌶️ Chili', chilis, total, Colors.orange[400]!),
        ],
      ),
    );
  }

  Widget _buildCropBar(String name, int count, int total, Color barColor) {
    final double percent = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _Theme.textPrimary),
            ),
            Text(
              '$count (${(percent * 100).round()}%)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _Theme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth * percent,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [barColor, barColor.withOpacity(0.8)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ],
              );
            }
          ),
        ),
      ],
    );
  }

  // ─── TAB 2: ADD PLANT TAB ──────────────────────────────────────────────────

  Widget _buildAddPlantTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          sliver: SliverList(delegate: SliverChildListDelegate([
            _buildGroupHeader('Select Plant'),
            _buildCropPicker(),
            const SizedBox(height: 24),

            _buildGroupHeader('Planting Date'),
            _buildDateRow(),
            const SizedBox(height: 24),

            _buildGroupHeader('Current Stage'),
            _buildStagePicker(),
            const SizedBox(height: 24),

            _buildGroupHeader('Season'),
            _buildSeasonPicker(),
            const SizedBox(height: 24),

            _buildGroupHeader('Conditions'),
            _buildEnvironmentGroup(),
            const SizedBox(height: 32),

            _buildAddButton(),
          ])),
        ),
      ],
    );
  }

  Widget _buildGroupHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _Theme.textSecondary, letterSpacing: 0.8)),
    );
  }

  Widget _buildCropPicker() {
    final crops = [
      ('Tomato', '🍅', 'Tomato'),
      ('Eggplant', '🍆', 'Eggplant'),
      ('Siling Labuyo', '🌶️', 'Chili'),
    ];
    return Row(
      children: crops.map((crop) {
        final (value, emoji, label) = crop;
        final isSel = _selectedVegetable == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedVegetable = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isSel ? Colors.white : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSel ? _Theme.primary : _Theme.border,
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        color: isSel ? _Theme.textPrimary : _Theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRow() {
    return Container(
      decoration: _Theme.card,
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2025),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: _Theme.primary,
                    onPrimary: Colors.white,
                    onSurface: _Theme.textPrimary,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() => _selectedDate = picked);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: _Theme.primary),
            const SizedBox(width: 14),
            const Expanded(child: Text('Planting Date', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _Theme.textPrimary))),
            Text(
              '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _Theme.primary),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: _Theme.textTertiary),
          ]),
        ),
      ),
    );
  }

  Widget _buildStagePicker() {
    final stages = [
      (GrowthStage.seedling, '🌱', 'Seedling'),
      (GrowthStage.youngPlant, '🌿', 'Young Plant'),
      (GrowthStage.flowering, '🌼', 'Flowering'),
      (GrowthStage.fruiting, '🍎', 'Fruiting'),
    ];
    return Row(
      children: stages.map((stage) {
        final (value, emoji, label) = stage;
        final isSel = _selectedStage == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => setState(() => _selectedStage = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSel ? _Theme.primary.withOpacity(0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSel ? _Theme.primary : _Theme.border,
                    width: isSel ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        color: isSel ? _Theme.primary : _Theme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeasonPicker() {
    final seasons = [
      (Season.dry, '☀️', 'Dry Season'),
      (Season.wet, '🌧️', 'Wet Season'),
    ];
    return Row(
      children: seasons.map((season) {
        final (value, emoji, label) = season;
        final isSel = _selectedSeason == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedSeason = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSel ? _Theme.primary.withOpacity(0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSel ? _Theme.primary : _Theme.border,
                    width: isSel ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        color: isSel ? _Theme.primary : _Theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEnvironmentGroup() {
    return Container(
      decoration: _Theme.card,
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        _buildEnvRow(
          icon: Icons.wb_sunny_outlined, iconColor: Colors.amber[700]!,
          label: 'Sunlight',
          values: SunlightLevel.values, selected: _selectedSunlight,
          labelFor: (v) => (v as SunlightLevel).nameEnglish,
          onChanged: (v) => setState(() => _selectedSunlight = v as SunlightLevel),
          isLast: false,
        ),
        _buildEnvRow(
          icon: Icons.water_drop_outlined, iconColor: Colors.blue[600]!,
          label: 'Water Level',
          values: WaterLevel.values, selected: _selectedWater,
          labelFor: (v) => (v as WaterLevel).nameEnglish,
          onChanged: (v) => setState(() => _selectedWater = v as WaterLevel),
          isLast: false,
        ),
        _buildEnvRow(
          icon: Icons.layers_outlined, iconColor: Colors.brown[600]!,
          label: 'Soil Quality',
          values: SoilQuality.values, selected: _selectedSoil,
          labelFor: (v) => (v as SoilQuality).nameEnglish,
          onChanged: (v) => setState(() => _selectedSoil = v as SoilQuality),
          isLast: true,
        ),
      ]),
    );
  }

  Future<void> _showPicker(BuildContext context, String title, List<dynamic> items, dynamic selected, Function(dynamic) onChanged, String Function(dynamic) labelFor) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 16),
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _Theme.primaryDark),
              ),
            ),
            ...items.map((item) {
              final isSel = selected == item;
              return ListTile(
                onTap: () { onChanged(item); Navigator.pop(ctx); },
                title: Text(
                  labelFor(item),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                    color: isSel ? _Theme.primary : _Theme.textPrimary,
                  ),
                ),
                trailing: isSel ? const Icon(Icons.check, color: _Theme.primary) : null,
              );
            }),
          ],
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _Theme.textPrimary)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _Theme.border.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: values.map((val) {
              final isSel = selected == val;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: () => onChanged(val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSel ? Border.all(color: _Theme.border) : null,
                    ),
                    child: Center(child: Text(
                      labelFor(val),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        color: isSel ? _Theme.primary : _Theme.textSecondary,
                      ),
                    )),
                  ),
                ),
              ));
            }).toList()),
          ),
        ]),
      ),
      if (!isLast) const Divider(height: 1, color: _Theme.border),
    ]);
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _addPlantToGarden,
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_circle_outline, size: 20),
          SizedBox(width: 8),
          Text('Add to Garden', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }

  // ─── TAB 3: MY GARDEN / VIEW PLANTS ────────────────────────────────────────

  Widget _buildViewPlantsTab() {
    if (_historyLogs.isEmpty) {
      return _buildEmptyGarden();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: _Theme.bg,
              pinned: true,
              expandedHeight: 50,
              elevation: 0,
              scrolledUnderElevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
                title: Text(
                  'My Garden (${_historyLogs.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _Theme.textPrimary),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: isWide
                ? SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 160,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPlantCard(_historyLogs[index]),
                      childCount: _historyLogs.length,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPlantCard(_historyLogs[index]),
                      ),
                      childCount: _historyLogs.length,
                    ),
                  ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildEmptyGarden() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🪴', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('No Plants in Garden', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _Theme.textPrimary)),
      const SizedBox(height: 6),
      const Text('Add plants to monitor growth statistics.', style: TextStyle(color: _Theme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => setState(() => _tabIndex = 1), // Redirect to Add Plant tab
        child: const Text('Go to Add Plant'),
      ),
    ]));
  }

  Widget _buildPlantCard(PredictionLog plant) {
    final pred = CellularAutomataEngine.predictGrowth(plant.input);
    final elapsed = DateTime.now().difference(plant.input.plantingDate).inDays;
    final daysLeft = (pred.totalDaysToHarvest - elapsed).clamp(0, pred.totalDaysToHarvest);
    final progress = (elapsed / pred.totalDaysToHarvest).clamp(0.0, 1.0);
    final isHealthy = _getDynamicHealth(plant).$2;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, PageRouteBuilder(
          pageBuilder: (ctx, anim, anim2) => PlantDetailScreen(
            plant: plant,
            onUpdate: (updated) async {
              await StorageService.updateLog(updated);
              _loadHistoryLogs();
            },
          ),
          transitionsBuilder: (ctx, anim, anim2, child) => FadeTransition(opacity: anim, child: child),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: _Theme.border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(_cropEmoji(plant.input.vegetableType), style: const TextStyle(fontSize: 32))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          _cropName(plant.input.vegetableType),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _Theme.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isHealthy ? _Theme.primary.withOpacity(0.08) : Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isHealthy ? 'Healthy' : 'Deficient',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isHealthy ? _Theme.primary : Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      daysLeft > 0 ? '$daysLeft days to harvest' : 'Ready to harvest! 🎉',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: daysLeft <= 14 ? Colors.orange[800] : _Theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: _Theme.border,
                        valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? _Theme.accent : _Theme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.chevron_right, size: 20, color: _Theme.textTertiary),
                  const SizedBox(height: 24),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: () async {
                      final delete = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Plant'),
                          content: const Text('Are you sure you want to remove this plant?'),
                          actions: [
                            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx, false)),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Delete'), 
                              onPressed: () => Navigator.pop(ctx, true),
                            ),
                          ],
                        ),
                      );
                      if (delete == true) {
                        await _deletePlant(plant.id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PLANT DETAIL SCREEN (PLANT STATUS VIEW) ──────────────────────────────────

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

  final List<String> _actions = [
    'Watered',
    'Fertilized',
    'Weeded',
    'Protected from Rain',
    'Moved Location',
  ];

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    _prediction = CellularAutomataEngine.predictGrowth(_plant.input);
    final elapsed = DateTime.now().difference(_plant.input.plantingDate).inDays;
    _currentDay = (elapsed + 1).clamp(1, _prediction.totalDaysToHarvest + 1);
  }

  Future<void> _showAddActionDialog() async {
    String selectedAction = _actions[0];
    final dayPred = _prediction.timeline[(_currentDay - 1).clamp(0, _prediction.totalDaysToHarvest)];
    final (minRec, maxRec) = RecommendationEngine.getWateringRange(_plant.input.vegetableType, dayPred.stage);
    final averageWater = (minRec + maxRec) ~/ 2;

    final quantityController = TextEditingController(text: '${averageWater} mL');
    final descriptionController = TextEditingController();

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          bool showQuantity = false;
          bool showDescription = true;
          String quantityLabel = 'QUANTITY';
          String quantityHint = 'e.g. 50g, 10mL';
          String descriptionLabel = 'DETAILS / NOTES';
          String descriptionHint = 'Add any additional notes...';

          if (selectedAction == 'Watered') {
            showQuantity = true;
            quantityLabel = 'WATER QUANTITY';
            quantityHint = 'e.g. 300 mL';
            descriptionLabel = 'WATERING NOTES (OPTIONAL)';
            descriptionHint = 'e.g. morning watering, rainwater...';
          } else if (selectedAction == 'Fertilized') {
            showQuantity = true;
            quantityLabel = 'FERTILIZER QUANTITY';
            quantityHint = 'e.g. 15g, 10 mL';
            descriptionLabel = 'FERTILIZER BRAND / TYPE';
            descriptionHint = 'e.g. Organic Compost, 14-14-14 NPK';
          } else if (selectedAction == 'Weeded') {
            showQuantity = false;
            descriptionLabel = 'WEEDING DETAILS';
            descriptionHint = 'e.g. cleared crabgrass around base...';
          } else if (selectedAction == 'Protected from Rain') {
            showQuantity = false;
            descriptionLabel = 'PROTECTION DETAILS';
            descriptionHint = 'e.g. moved under roof canopy...';
          } else if (selectedAction == 'Moved Location') {
            showQuantity = false;
            descriptionLabel = 'NEW LOCATION DETAILS (SUNLIGHT, ETC.)';
            descriptionHint = 'e.g. moved to east window with 6h direct sunlight...';
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Log Daily Care',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _Theme.primaryDark, letterSpacing: -0.5),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: _Theme.textSecondary),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('SELECT ACTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _Theme.textSecondary, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _actions.map((act) {
                    final isSel = selectedAction == act;
                    String emoji = '🔧';
                    if (act == 'Watered') emoji = '💧';
                    if (act == 'Fertilized') emoji = '🧪';
                    if (act == 'Weeded') emoji = '🌿';
                    if (act == 'Protected from Rain') emoji = '🌧️';
                    if (act == 'Moved Location') emoji = '🚚';

                    return ChoiceChip(
                      label: Text(
                        '$emoji $act',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          color: isSel ? Colors.white : _Theme.textSecondary,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: _Theme.primary,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: isSel ? _Theme.primary : _Theme.border, width: 1),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setModalState(() {
                            selectedAction = act;
                            if (selectedAction == 'Watered') {
                              quantityController.text = '${averageWater} mL';
                            } else {
                              quantityController.text = '';
                            }
                            descriptionController.text = '';
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                if (showQuantity) ...[
                  Text(quantityLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _Theme.textSecondary, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  if (selectedAction == 'Watered') ...[
                    Text(
                      'Recommended daily limit: $minRec - $maxRec mL for this stage.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _Theme.primary),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      hintText: quantityHint,
                      hintStyle: const TextStyle(color: _Theme.textTertiary, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: const Color(0xFFF8FAF9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Theme.textPrimary),
                  ),
                  const SizedBox(height: 20),
                ],
                if (showDescription) ...[
                  Text(descriptionLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _Theme.textSecondary, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      hintText: descriptionHint,
                      hintStyle: const TextStyle(color: _Theme.textTertiary, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: const Color(0xFFF8FAF9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Theme.textPrimary),
                  ),
                  const SizedBox(height: 24),
                ],
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Theme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Action Log', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ),
          );
        }
      ),
    );

    if (confirm == true) {
      final updatedLogs = List<DailyAction>.from(_plant.careLogs)
        ..add(DailyAction(
          dayOffset: _currentDay,
          action: selectedAction,
          timestamp: DateTime.now(),
          quantity: quantityController.text.trim(),
          description: descriptionController.text.trim(),
        ));

      setState(() {
        _plant = PredictionLog(
          id: _plant.id, input: _plant.input, predictedStage: _plant.predictedStage,
          healthStatus: _plant.healthStatus, recommendations: _plant.recommendations,
          timestamp: _plant.timestamp, careLogs: updatedLogs,
        );
      });
      widget.onUpdate(_plant);
    }
  }

  String _cropEmoji(String v) => v.contains('Tomato') ? '🍅' : v.contains('Eggplant') ? '🍆' : '🌶️';
  String _cropName(String v) => v.contains('Tomato') ? 'Tomato' : v.contains('Eggplant') ? 'Eggplant' : 'Chili';

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
    final dayPred = _prediction.timeline[(_currentDay - 1).clamp(0, _prediction.totalDaysToHarvest)];
    final daysLeft = (_prediction.totalDaysToHarvest + 1 - _currentDay).clamp(0, _prediction.totalDaysToHarvest + 1);
    final progress = ((_currentDay - 1) / _prediction.totalDaysToHarvest).clamp(0.0, 1.0);
    final filteredLogs = _plant.careLogs.where((l) => l.dayOffset == _currentDay).toList();

    // Calculate dynamic health based on care logs
    final dailyValidation = RecommendationEngine.validateDailyActions(
      crop: _plant.input.vegetableType,
      stage: dayPred.stage,
      actions: filteredLogs,
    );
    final double rawHealth = dayPred.healthScore;
    final double adjustedHealth = (rawHealth + (dailyValidation.healthScoreModifier / 100)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _Theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _Theme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _cropName(_plant.input.vegetableType),
          style: const TextStyle(color: _Theme.textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── Plant Status Hero View ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _Theme.border, width: 1),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _Theme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Text(_cropEmoji(_plant.input.vegetableType), style: const TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: 16),
              Text(
                daysLeft > 0 ? 'Harvest in $daysLeft Days' : 'Ready for Harvest! 🎉',
                style: const TextStyle(color: _Theme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text('Day $_currentDay / ${_prediction.totalDaysToHarvest + 1}', style: const TextStyle(color: _Theme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Date: ${_plant.input.plantingDate.add(Duration(days: _currentDay - 1)).month}/${_plant.input.plantingDate.add(Duration(days: _currentDay - 1)).day}/${_plant.input.plantingDate.add(Duration(days: _currentDay - 1)).year}',
                style: const TextStyle(color: _Theme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
                value: progress, minHeight: 8,
                backgroundColor: _Theme.border,
                valueColor: const AlwaysStoppedAnimation(_Theme.primary),
              )),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Stats row ──
          Row(children: [
            Expanded(child: _infoTile(_stageEmoji(dayPred.stage), dayPred.stage.nameEnglish, 'Stage')),
            const SizedBox(width: 10),
            Expanded(child: _infoTile(
              adjustedHealth >= 0.7 ? '💚' : adjustedHealth >= 0.4 ? '💛' : '❤️',
              '${(adjustedHealth * 100).round()}%', 'Health',
            )),
          ]),
          const SizedBox(height: 12),

          // ── Milestone ──
          if (dayPred.milestone.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _Theme.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _Theme.primary.withOpacity(0.2), width: 1),
              ),
              child: Row(children: [
                const Icon(Icons.flag_outlined, color: _Theme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(dayPred.milestone, style: const TextStyle(color: _Theme.primary, fontWeight: FontWeight.w800, fontSize: 13.5))),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // ── Tip / Recommendations ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _Theme.card,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(
                dailyValidation.warnings.isNotEmpty ? Icons.warning_amber_rounded : Icons.lightbulb_outline_rounded,
                color: dailyValidation.warnings.isNotEmpty ? Colors.orange[900] : Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  dailyValidation.warnings.isNotEmpty ? 'AGRICULTURAL WARNINGS' : 'RECOMMENDATIONS',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                    color: dailyValidation.warnings.isNotEmpty ? Colors.orange[800] : _Theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dailyValidation.warnings.isNotEmpty
                    ? dailyValidation.warnings.join('\n\n')
                    : (_plant.recommendations.isNotEmpty ? _plant.recommendations.join('\n') : dayPred.dailyTip),
                  style: const TextStyle(fontSize: 13.5, color: _Theme.textPrimary, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ])),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Log Daily Action Button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showAddActionDialog,
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_box_outlined, size: 20),
                SizedBox(width: 8),
                Text('Log Daily Care Action', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
            ),
          ),
          const SizedBox(height: 24),

          // ── Logged for this day ──
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'LOGGED ACTIVITIES (${filteredLogs.length})'.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _Theme.textSecondary, letterSpacing: 0.8),
            ),
          ),
          Container(
            decoration: _Theme.card,
            clipBehavior: Clip.antiAlias,
            child: filteredLogs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(
                    child: Text(
                      'No activities logged for this day.',
                      style: TextStyle(color: _Theme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                )
              : Column(children: List.generate(filteredLogs.length, (i) {
                  final log = filteredLogs[i];
                  final isLast = i == filteredLogs.length - 1;
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(children: [
                        const Icon(Icons.check_circle_outline, color: _Theme.primary, size: 18),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            log.quantity.isNotEmpty && log.description.isNotEmpty
                                ? '${log.action} (${log.quantity}) — ${log.description}'
                                : log.quantity.isNotEmpty
                                    ? '${log.action} (${log.quantity})'
                                    : log.description.isNotEmpty
                                        ? '${log.action} — ${log.description}'
                                        : log.action, 
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _Theme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            log.timestamp.toLocal().toString().substring(11, 16),
                            style: const TextStyle(fontSize: 11, color: _Theme.textSecondary),
                          ),
                        ])),
                      ]),
                    ),
                    if (!isLast) const Divider(height: 1, color: _Theme.border),
                  ]);
                })),
          ),
        ]),
      ),
    );
  }

  Widget _infoTile(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _Theme.card,
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _Theme.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _Theme.textSecondary)),
      ]),
    );
  }
}
