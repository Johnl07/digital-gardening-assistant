import 'dart:async';
import 'package:flutter/material.dart';
import '../models/plant_input.dart';
import '../models/prediction_log.dart';
import '../services/cellular_automata_engine.dart';
import '../services/recommendation_engine.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Fields State
  final _formKey = GlobalKey<FormState>();
  String _selectedVegetable = 'Tomato';
  DateTime _selectedDate = DateTime.now();
  GrowthStage _selectedStage = GrowthStage.seedling;
  Season _selectedSeason = Season.dry;
  SunlightLevel _selectedSunlight = SunlightLevel.medium;
  WaterLevel _selectedWater = WaterLevel.medium;
  SoilQuality _selectedSoil = SoilQuality.moderate;

  // History Log State (The Container of Added Plants)
  List<PredictionLog> _historyLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistoryLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryLogs() async {
    final logs = await StorageService.loadLogs();
    setState(() {
      _historyLogs = logs;
    });
  }

  Future<void> _addPlantToGarden() async {
    if (!_formKey.currentState!.validate()) return;

    final input = PlantInput(
      vegetableType: _selectedVegetable,
      plantingDate: _selectedDate,
      currentStage: _selectedStage,
      season: _selectedSeason,
      sunlight: _selectedSunlight,
      water: _selectedWater,
      soil: _selectedSoil,
    );

    // Predict growth lifecycle
    final prediction = CellularAutomataEngine.predictGrowth(input);
    final lastDay = prediction.timeline.last;

    // Evaluate health rules
    final recs = RecommendationEngine.evaluate(input);

    final newPlant = PredictionLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      input: input,
      predictedStage: lastDay.stage,
      healthStatus: recs.healthStatus,
      recommendations: recs.recommendations,
      timestamp: DateTime.now(),
      careLogs: [],
    );

    await StorageService.saveLog(newPlant);
    await _loadHistoryLogs();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Idinagdag ang ${input.vegetableType == 'Tomato' ? 'Kamatis' : input.vegetableType == 'Eggplant' ? 'Talong' : 'Sili'} sa Taniman!'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      // Navigate to My Garden tab
      _tabController.animateTo(1);
    }
  }

  Future<void> _deletePlant(String id) async {
    await StorageService.deleteLog(id);
    await _loadHistoryLogs();
  }

  Future<void> _clearAllPlants() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Burahin Lahat?'),
          ],
        ),
        content: const Text('Sigurado ka bang nais mong burahin ang lahat ng halaman sa iyong garden?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hindi')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Burahin', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.clearLogs();
      await _loadHistoryLogs();
    }
  }

  String _getCropEmoji(String crop) {
    if (crop.toLowerCase().contains('tomato')) return '🍅';
    if (crop.toLowerCase().contains('eggplant')) return '🍆';
    return '🌶️';
  }

  String _getStageEmoji(GrowthStage stage) {
    switch (stage) {
      case GrowthStage.seedling: return '🌱';
      case GrowthStage.youngPlant: return '🌿';
      case GrowthStage.flowering: return '🌼';
      case GrowthStage.fruiting: return '🍎';
    }
  }

  // ---- BUILD ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade800, Colors.teal.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.eco, size: 26, color: Colors.amber),
            SizedBox(width: 8),
            Text('My Digital Garden', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
        elevation: 0,
        actions: [
          if (_tabController.index == 1 && _historyLogs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              tooltip: 'Burahin lahat ng halaman',
              onPressed: _clearAllPlants,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.amber.shade700,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(child: Text('MAGDAGDAG NG TANIM')),
                Tab(child: Text('MGA HALAMAN (CONTAINER)')),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFormTab(),
            _buildGardenContainerTab(),
          ],
        ),
      ),
    );
  }

  // ---- FORM TAB (Page 1) ----

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome & App Introduction
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.green.shade200, width: 1),
              ),
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🌿', style: TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kamusta, Ka-Garden! 👋',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Maligayang pagdating sa iyong Digital Gardening Assistant. Hulaan ang araw ng paglaki at i-log ang iyong pag-aalaga sa halaman araw-araw.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.green.shade800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('1. Pumili ng Gulay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildCropCard('Tomato', '🍅 Kamatis', Colors.red.shade400),
                const SizedBox(width: 8),
                _buildCropCard('Eggplant', '🍆 Talong', Colors.deepPurple.shade300),
                const SizedBox(width: 8),
                _buildCropCard('Siling Labuyo', '🌶️ Sili', Colors.orange.shade600),
              ],
            ),
            const SizedBox(height: 20),

            const Text('2. Petsa ng Pagtatanim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2025),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month, color: Colors.green.shade700),
                          const SizedBox(width: 12),
                          const Text('Petsa:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade900, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('3. Mga Kondisyon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green.shade900)),
                    const Divider(height: 20),

                    const Text('Kasalukuyang Stage:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<GrowthStage>(
                      value: _selectedStage,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.grain),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: GrowthStage.values
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text('${s.nameTagalog} (${s.nameEnglish})'),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedStage = val!),
                    ),
                    const SizedBox(height: 16),

                    const Text('Panahon:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<Season>(
                      value: _selectedSeason,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.cloud),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: Season.values
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text('${s.nameTagalog} (${s.nameEnglish})'),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedSeason = val!),
                    ),
                    const SizedBox(height: 16),

                    _buildChipRow('Sikat ng Araw:', SunlightLevel.values, _selectedSunlight, (v) => setState(() => _selectedSunlight = v as SunlightLevel)),
                    const SizedBox(height: 12),
                    _buildChipRow('Dami ng Tubig:', WaterLevel.values, _selectedWater, (v) => setState(() => _selectedWater = v as WaterLevel)),
                    const SizedBox(height: 12),
                    _buildChipRow('Kalidad ng Lupa:', SoilQuality.values, _selectedSoil, (v) => setState(() => _selectedSoil = v as SoilQuality)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: [Colors.green.shade700, Colors.teal.shade700]),
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _addPlantToGarden,
                icon: const Icon(Icons.add_circle_outline, size: 24),
                label: const Text('I-tanim sa Garden (Add Plant)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- GARDEN CONTAINER TAB (Page 2) ----

  Widget _buildGardenContainerTab() {
    if (_historyLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Walang Tanim sa Garden',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Text('Pumunta sa MAGDAGDAG tab upang magtanim ng bago.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _historyLogs.length,
      itemBuilder: (context, index) {
        final plant = _historyLogs[index];
        final isHealthy = plant.healthStatus == 'Healthy';
        String cropName = plant.input.vegetableType == 'Tomato'
            ? 'Kamatis'
            : plant.input.vegetableType == 'Eggplant'
                ? 'Talong'
                : 'Sili';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlantDetailScreen(
                    plant: plant,
                    onUpdate: (updatedPlant) async {
                      await StorageService.updateLog(updatedPlant);
                      _loadHistoryLogs();
                    },
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _deletePlant(plant.id),
                    ),
                  ),
                  Text(_getCropEmoji(plant.input.vegetableType), style: const TextStyle(fontSize: 48)),
                  Text(
                    cropName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isHealthy ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isHealthy ? Colors.green.shade300 : Colors.orange.shade300),
                    ),
                    child: Text(
                      isHealthy ? 'Healthy' : 'Deficient',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isHealthy ? Colors.green.shade900 : Colors.orange.shade900,
                      ),
                    ),
                  ),
                  Text(
                    'Aktibidad: ${plant.careLogs.length} logs',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- HELPER WIDGETS ----

  Widget _buildCropCard(String value, String label, Color activeColor) {
    final isSel = _selectedVegetable == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedVegetable = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSel ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSel ? activeColor : Colors.grey.shade300, width: 2),
            boxShadow: isSel
                ? [BoxShadow(color: activeColor.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSel ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChipRow(String label, List<dynamic> values, dynamic selected, Function(dynamic) onChanged) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: values.map((val) {
            final isSel = selected == val;
            String text = '';
            if (val is SunlightLevel) text = val.nameTagalog;
            if (val is WaterLevel) text = val.nameTagalog;
            if (val is SoilQuality) text = val.nameTagalog;
            return ChoiceChip(
              label: Text(text),
              labelStyle: TextStyle(
                color: isSel ? Colors.white : Colors.black87,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
              selected: isSel,
              onSelected: (s) {
                if (s) onChanged(val);
              },
              selectedColor: Colors.green.shade700,
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---- PLANT DETAIL SCREEN & CARE LOGGER ----

class PlantDetailScreen extends StatefulWidget {
  final PredictionLog plant;
  final Function(PredictionLog) onUpdate;

  const PlantDetailScreen({
    super.key,
    required this.plant,
    required this.onUpdate,
  });

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late PredictionLog _plant;
  late GrowthPredictionResult _prediction;
  int _currentDay = 0;

  final List<String> _quickActions = [
    'Nagdilig (Watered)',
    'Naglagay ng pataba (Fertilized)',
    'Binawasan ang damo (Weeded)',
    'Pinrotektahan sa ulan',
    'Inilipat ng pwesto',
  ];

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    _prediction = CellularAutomataEngine.predictGrowth(_plant.input);
    
    // Default current day to the days elapsed since planting date
    final elapsed = DateTime.now().difference(_plant.input.plantingDate).inDays;
    _currentDay = elapsed.clamp(0, _prediction.totalDaysToHarvest);
  }

  Future<void> _logAction(String action) async {
    // Check if an action already exists for the selected day offset
    final exists = _plant.careLogs.any((log) => log.dayOffset == _currentDay);

    if (exists) {
      // Show confirmation dialog to ask if they want to add it again
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text('Idagdag Muli?'),
            ],
          ),
          content: Text('May naitalang aktibidad na sa Araw $_currentDay. Nais mo ba itong idagdag muli?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Kanselahin')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Idagdag', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    final newAction = DailyAction(
      dayOffset: _currentDay,
      action: action,
      timestamp: DateTime.now(),
    );

    final updatedLogs = List<DailyAction>.from(_plant.careLogs)..add(newAction);

    setState(() {
      _plant = PredictionLog(
        id: _plant.id,
        input: _plant.input,
        predictedStage: _plant.predictedStage,
        healthStatus: _plant.healthStatus,
        recommendations: _plant.recommendations,
        timestamp: _plant.timestamp,
        careLogs: updatedLogs,
      );
    });

    widget.onUpdate(_plant);
  }

  String _getCropEmoji(String crop) {
    if (crop.toLowerCase().contains('tomato')) return '🍅';
    if (crop.toLowerCase().contains('eggplant')) return '🍆';
    return '🌶️';
  }

  String _getStageEmoji(GrowthStage stage) {
    switch (stage) {
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
    final predictedDate = _plant.input.plantingDate.add(Duration(days: _currentDay));
    final filteredLogs = _plant.careLogs.where((log) => log.dayOffset == _currentDay).toList();

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade800, Colors.teal.shade700],
            ),
          ),
        ),
        title: Text('${_plant.input.vegetableType == 'Tomato' ? 'Kamatis' : _plant.input.vegetableType == 'Eggplant' ? 'Talong' : 'Sili'} Tracker'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Harvest Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: daysLeft <= 14
                      ? [Colors.amber.shade700, Colors.orange.shade800]
                      : [Colors.green.shade700, Colors.teal.shade800],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(_getCropEmoji(_plant.input.vegetableType), style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    daysLeft > 0 ? 'Harvest sa $daysLeft araw!' : 'Handa na para sa Pag-aani!',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('Araw $_currentDay / ${_prediction.totalDaysToHarvest}', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Slider
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.first_page),
                          onPressed: _currentDay > 0 ? () => setState(() => _currentDay = 0) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentDay > 0 ? () => setState(() => _currentDay--) : null,
                        ),
                        Column(
                          children: [
                            Text('Araw $_currentDay', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('${predictedDate.year}-${predictedDate.month}-${predictedDate.day}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentDay < _prediction.totalDaysToHarvest ? () => setState(() => _currentDay++) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.last_page),
                          onPressed: _currentDay < _prediction.totalDaysToHarvest ? () => setState(() => _currentDay = _prediction.totalDaysToHarvest) : null,
                        ),
                      ],
                    ),
                    Slider(
                      value: _currentDay.toDouble(),
                      min: 0,
                      max: _prediction.totalDaysToHarvest.toDouble(),
                      divisions: _prediction.totalDaysToHarvest,
                      onChanged: (v) => setState(() => _currentDay = v.round()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Health & Stage card
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(_getStageEmoji(dayPred.stage), style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 4),
                          Text(dayPred.stage.nameTagalog, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Icon(Icons.favorite, color: Colors.red, size: 32),
                          const SizedBox(height: 4),
                          Text('${(dayPred.healthScore * 100).round()}% Kalusugan', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Care Logger Form
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('I-log ang Aktibidad sa Araw na Ito', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _quickActions.map((action) {
                        return ActionChip(
                          avatar: const Icon(Icons.add, size: 14),
                          label: Text(action),
                          onPressed: () => _logAction(action),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Care Activity History for Current Day
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Mga Na-log na Aktibidad (Araw $_currentDay)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(height: 20),
                    if (filteredLogs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Walang naitalang aktibidad para sa araw na ito.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      )
                    else
                      ...filteredLogs.map((log) => ListTile(
                            leading: const Icon(Icons.check, color: Colors.green),
                            title: Text(log.action),
                            subtitle: Text('Na-log noong: ${log.timestamp.toLocal().toString().substring(0, 16)}'),
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
