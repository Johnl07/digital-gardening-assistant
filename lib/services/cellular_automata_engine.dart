import 'dart:math';
import '../models/plant_input.dart';

/// Crop-specific base timeline (days) for each growth stage transition.
class CropTimeline {
  final int seedlingEnd;
  final int youngPlantEnd;
  final int floweringEnd;
  final int fruitingEnd;
  final int harvestDay;

  const CropTimeline({
    required this.seedlingEnd,
    required this.youngPlantEnd,
    required this.floweringEnd,
    required this.fruitingEnd,
    required this.harvestDay,
  });
}

/// Represents the predicted state of a plant on a specific day.
class DayPrediction {
  final int day;
  final GrowthStage stage;
  final double healthScore; // 0.0 to 1.0
  final String milestone; // Empty if no milestone on this day
  final String dailyTip;

  const DayPrediction({
    required this.day,
    required this.stage,
    required this.healthScore,
    required this.milestone,
    required this.dailyTip,
  });
}

/// Full prediction result for a plant's lifecycle.
class GrowthPredictionResult {
  final List<DayPrediction> timeline;
  final int totalDaysToHarvest;
  final Map<GrowthStage, int> stageStartDays;
  final double overallHealthScore;

  const GrowthPredictionResult({
    required this.timeline,
    required this.totalDaysToHarvest,
    required this.stageStartDays,
    required this.overallHealthScore,
  });
}

class CellularAutomataEngine {
  static const int gridSize = 5;

  /// Base timelines for each crop (in ideal conditions).
  static const Map<String, CropTimeline> _cropTimelines = {
    'Tomato': CropTimeline(
      seedlingEnd: 21,
      youngPlantEnd: 45,
      floweringEnd: 70,
      fruitingEnd: 100,
      harvestDay: 110,
    ),
    'Eggplant': CropTimeline(
      seedlingEnd: 25,
      youngPlantEnd: 55,
      floweringEnd: 80,
      fruitingEnd: 120,
      harvestDay: 135,
    ),
    'Siling Labuyo': CropTimeline(
      seedlingEnd: 20,
      youngPlantEnd: 40,
      floweringEnd: 60,
      fruitingEnd: 85,
      harvestDay: 95,
    ),
  };

  /// Runs the Cellular Automata internally and produces a day-by-day prediction timeline.
  static GrowthPredictionResult predictGrowth(PlantInput input) {
    // 1. Calculate environmental factor using CA neighborhood rules
    double envFactor = _calculateEnvironmentFactor(input);

    // 2. Get base timeline for the crop
    final baseTimeline = _cropTimelines[input.vegetableType] ??
        _cropTimelines['Tomato']!;

    // 3. Adjust timeline based on environment factor
    //    Good conditions (factor > 0.7) = faster growth
    //    Poor conditions (factor < 0.4) = slower growth
    double speedMultiplier = _calculateSpeedMultiplier(envFactor);

    int adjSeedlingEnd = (baseTimeline.seedlingEnd * speedMultiplier).round();
    int adjYoungEnd = (baseTimeline.youngPlantEnd * speedMultiplier).round();
    int adjFloweringEnd = (baseTimeline.floweringEnd * speedMultiplier).round();
    int adjFruitingEnd = (baseTimeline.fruitingEnd * speedMultiplier).round();
    int adjHarvestDay = (baseTimeline.harvestDay * speedMultiplier).round();

    // 4. Determine starting day offset based on current stage
    int startDay = _getStartDayForStage(input.currentStage, adjSeedlingEnd, adjYoungEnd, adjFloweringEnd, adjFruitingEnd);

    // 5. Build stage start days map (relative to startDay so day 0 = user's selected stage)
    Map<GrowthStage, int> stageStartDays = {
      GrowthStage.seedling: (0 - startDay).clamp(0, adjHarvestDay),
      GrowthStage.youngPlant: (adjSeedlingEnd - startDay).clamp(0, adjHarvestDay),
      GrowthStage.flowering: (adjYoungEnd - startDay).clamp(0, adjHarvestDay),
      GrowthStage.fruiting: (adjFloweringEnd - startDay).clamp(0, adjHarvestDay),
    };

    // 6. Run internal CA simulation to refine health scores per day (over full lifecycle)
    List<double> healthPerDay = _runInternalCA(input, envFactor, adjHarvestDay);

    // 7. Generate day-by-day predictions starting from the user's selected stage
    //    Day 0 in the timeline = startDay in the full lifecycle
    List<DayPrediction> timeline = [];
    final int remainingDays = adjHarvestDay - startDay;
    for (int offset = 0; offset <= remainingDays; offset++) {
      final int absoluteDay = startDay + offset;
      GrowthStage stage = _getStageForDay(absoluteDay, adjSeedlingEnd, adjYoungEnd, adjFloweringEnd, adjFruitingEnd);
      String milestone = _getMilestone(absoluteDay, adjSeedlingEnd, adjYoungEnd, adjFloweringEnd, adjFruitingEnd, adjHarvestDay, input.vegetableType);
      String tip = _getDailyTip(absoluteDay, stage, input, envFactor, adjHarvestDay);
      double health = absoluteDay < healthPerDay.length ? healthPerDay[absoluteDay] : envFactor;

      timeline.add(DayPrediction(
        day: offset, // relative day: 0 = today (user's selected stage)
        stage: stage,
        healthScore: health,
        milestone: milestone,
        dailyTip: tip,
      ));
    }

    double overallHealth = healthPerDay.isEmpty
        ? envFactor
        : healthPerDay.reduce((a, b) => a + b) / healthPerDay.length;

    return GrowthPredictionResult(
      timeline: timeline,
      totalDaysToHarvest: remainingDays, // remaining days from the selected stage
      stageStartDays: stageStartDays,
      overallHealthScore: overallHealth.clamp(0.0, 1.0),
    );
  }

  // ---- Internal CA Simulation (runs on a 5x5 grid behind the scenes) ----

  static List<double> _runInternalCA(PlantInput input, double envFactor, int totalDays) {
    final random = Random(42); // Fixed seed for reproducibility
    List<double> healthScores = [];

    // Initialize 5x5 grid with starting stage
    int initVal = _stageToInt(input.currentStage);
    List<List<int>> grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));
    grid[2][2] = initVal;
    grid[1][2] = max(0, initVal - 1);
    grid[3][2] = max(0, initVal - 1);
    grid[2][1] = max(0, initVal - 1);
    grid[2][3] = max(0, initVal - 1);

    // Run CA steps (one step per ~10 days of real time)
    int caSteps = (totalDays / 10).ceil();
    List<List<List<int>>> caHistory = [_cloneGrid(grid)];

    for (int step = 0; step < caSteps; step++) {
      List<List<int>> nextGrid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));

      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          int state = grid[r][c];
          if (state == 0) {
            nextGrid[r][c] = 0;
          } else if (state < 4) {
            // Decay check
            if (envFactor < 0.4) {
              double decayChance = (0.4 - envFactor) * 0.3;
              if (random.nextDouble() < decayChance) {
                nextGrid[r][c] = max(0, state - 1);
                continue;
              }
            }
            // Growth check
            int neighbors = _countActiveNeighbors(grid, r, c);
            double growthChance = envFactor * 0.6 + (neighbors / 8.0) * 0.4;
            if (random.nextDouble() < growthChance) {
              nextGrid[r][c] = min(4, state + 1);
            } else {
              nextGrid[r][c] = state;
            }
          } else {
            nextGrid[r][c] = 4; // Fruiting stays
          }
        }
      }
      grid = nextGrid;
      caHistory.add(_cloneGrid(grid));
    }

    // Convert CA grid history to daily health scores
    for (int day = 0; day <= totalDays; day++) {
      int caStep = (day / 10).floor().clamp(0, caHistory.length - 1);
      List<List<int>> dayGrid = caHistory[caStep];

      // Health = ratio of active (non-zero) cells and their growth progress
      int totalActive = 0;
      int totalProgress = 0;
      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          if (dayGrid[r][c] > 0) {
            totalActive++;
            totalProgress += dayGrid[r][c];
          }
        }
      }
      double health = totalActive > 0 ? (totalProgress / (totalActive * 4.0)) : 0.5;
      health = (health * 0.7 + envFactor * 0.3).clamp(0.0, 1.0);
      healthScores.add(health);
    }

    return healthScores;
  }

  // ---- Helper Methods ----

  static double _calculateSpeedMultiplier(double envFactor) {
    // High envFactor = faster growth (lower multiplier on days)
    // Low envFactor = slower growth (higher multiplier on days)
    if (envFactor >= 0.8) return 0.85; // 15% faster
    if (envFactor >= 0.6) return 1.0;  // Normal
    if (envFactor >= 0.4) return 1.2;  // 20% slower
    return 1.45; // 45% slower for poor conditions
  }

  static int _getStartDayForStage(GrowthStage stage, int seedEnd, int youngEnd, int flowerEnd, int fruitEnd) {
    switch (stage) {
      case GrowthStage.seedling:
        return 0;
      case GrowthStage.youngPlant:
        return seedEnd;
      case GrowthStage.flowering:
        return youngEnd;
      case GrowthStage.fruiting:
        return flowerEnd;
    }
  }

  static GrowthStage _getStageForDay(int day, int seedEnd, int youngEnd, int flowerEnd, int fruitEnd) {
    if (day < seedEnd) return GrowthStage.seedling;
    if (day < youngEnd) return GrowthStage.youngPlant;
    if (day < flowerEnd) return GrowthStage.flowering;
    return GrowthStage.fruiting;
  }

  static String _getMilestone(int day, int seedEnd, int youngEnd, int flowerEnd, int fruitEnd, int harvestDay, String crop) {
    if (day == 0) return '🌱 Start of Planting!';
    if (day == seedEnd) return '🌿 Grown into a Young Plant!';
    if (day == youngEnd) return '🌼 Started Flowering!';
    if (day == flowerEnd) return '🍎 Started Fruiting!';
    if (day == harvestDay) return '🎉 Ready for Harvest!';
    return '';
  }

  static String _getDailyTip(int day, GrowthStage stage, PlantInput input, double envFactor, int harvestDay) {
    final String crop = input.vegetableType;
    final bool isTomato = crop.toLowerCase().contains('tomato');
    final bool isEggplant = crop.toLowerCase().contains('eggplant');
    final int daysLeft = harvestDay - day;

    // Environmental warnings take priority
    if (input.water == WaterLevel.high && input.season == Season.wet) {
      return 'Warning: Soil is too wet. Reduce watering to avoid root rot.';
    }
    if (input.water == WaterLevel.low && input.sunlight == SunlightLevel.high) {
      return 'Warning: Plant may wilt. Increase watering, especially at midday.';
    }
    if (input.soil == SoilQuality.poor) {
      return 'Apply organic compost or fertilizer to improve soil quality.';
    }

    // Stage-specific tips
    switch (stage) {
      case GrowthStage.seedling:
        if (day <= 3) return 'Newly planted! Water lightly. Protect from direct hot sunlight.';
        if (day <= 7) return 'Watch for the first leaves. Keep soil moist.';
        if (isTomato) return 'Tomato seedlings need 6-8 hours of sunlight daily.';
        if (isEggplant) return 'Eggplant seedlings are sensitive to cold. Keep them in a warm area.';
        return 'Watch out for pests like aphids on new shoots.';

      case GrowthStage.youngPlant:
        if (isTomato) return 'Install stakes to support the growing tomato plant.';
        if (isEggplant) return 'Ensure 8-10 hours of sunlight for healthy eggplant growth.';
        return 'Prune stray branches to focus the plant\'s energy on the main stem.';

      case GrowthStage.flowering:
        if (isTomato) return 'Reduce Nitrogen fertilizer. Increase Potassium for more flowers.';
        if (isEggplant) return 'Do not let the soil dry out while the eggplant is flowering.';
        return 'Avoid heavy watering on the flowers to prevent them from dropping.';

      case GrowthStage.fruiting:
        if (daysLeft <= 14) return '🎉 Harvest is near! Estimated $daysLeft days remaining.';
        if (daysLeft <= 30) return 'Fruits are ripening! About $daysLeft days to harvest.';
        if (isTomato) return 'Support branches with fruit using stakes. Water regularly.';
        if (isEggplant) return 'Eggplants are ready to harvest when the skin is glossy and firm.';
        return 'Regularly inspect the fruit for signs of pests or disease.';
    }
  }

  static double _calculateEnvironmentFactor(PlantInput input) {
    double sunScore = 0;
    double waterScore = 0;
    double soilScore = 0;

    final String crop = input.vegetableType.toLowerCase();
    final bool isTomato = crop.contains('tomato');
    final bool isEggplant = crop.contains('eggplant');
    final bool isChili = crop.contains('siling');

    // Sunlight scoring (crop-specific)
    switch (input.sunlight) {
      case SunlightLevel.low:
        sunScore = isTomato ? 0.25 : isEggplant ? 0.3 : 0.35;
        break;
      case SunlightLevel.medium:
        sunScore = isTomato ? 0.7 : isEggplant ? 0.65 : 0.8;
        break;
      case SunlightLevel.high:
        sunScore = isTomato ? 1.0 : isEggplant ? 0.95 : 0.9;
        break;
    }

    // Water scoring
    switch (input.water) {
      case WaterLevel.low:
        waterScore = isTomato ? 0.3 : isEggplant ? 0.25 : 0.4;
        break;
      case WaterLevel.medium:
        waterScore = 0.85;
        break;
      case WaterLevel.high:
        waterScore = input.season == Season.wet ? 0.5 : 0.7;
        break;
    }

    // Soil scoring
    switch (input.soil) {
      case SoilQuality.poor:
        soilScore = 0.3;
        break;
      case SoilQuality.moderate:
        soilScore = 0.7;
        break;
      case SoilQuality.rich:
        soilScore = 1.0;
        break;
    }

    // Season modifier
    double seasonMod = input.season == Season.wet ? 0.9 : 1.0;

    return ((sunScore * 0.35 + waterScore * 0.35 + soilScore * 0.3) * seasonMod).clamp(0.0, 1.0);
  }

  static int _stageToInt(GrowthStage stage) {
    switch (stage) {
      case GrowthStage.seedling:
        return 1;
      case GrowthStage.youngPlant:
        return 2;
      case GrowthStage.flowering:
        return 3;
      case GrowthStage.fruiting:
        return 4;
    }
  }

  static int _countActiveNeighbors(List<List<int>> grid, int r, int c) {
    int count = 0;
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        int nr = r + dr;
        int nc = c + dc;
        if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
          if (grid[nr][nc] > 0) count++;
        }
      }
    }
    return count;
  }

  static List<List<int>> _cloneGrid(List<List<int>> grid) {
    return grid.map((row) => List<int>.from(row)).toList();
  }
}
