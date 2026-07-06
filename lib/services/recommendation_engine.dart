import '../models/plant_input.dart';
import '../models/prediction_log.dart';

class RecommendationEngine {
  /// Evaluates plant environmental factors and returns health status and recommendations.
  static RecommendationResult evaluate(PlantInput input) {
    List<String> recommendations = [];
    List<String> flaggedDeficiencies = [];

    final String crop = input.vegetableType.toLowerCase();
    final bool isTomato = crop.contains('tomato') || crop.contains('kamatis');
    final bool isEggplant = crop.contains('eggplant') || crop.contains('talong');
    final bool isChili = crop.contains('siling labuyo') || crop.contains('chili') || crop.contains('pepper');

    // 1. Evaluate Sunlight
    if (input.sunlight == SunlightLevel.low) {
      flaggedDeficiencies.add("Low Sunlight");
      if (isTomato) {
        recommendations.add(
          "Tomatoes need at least 6-8 hours of direct sunlight. Move to a sunnier spot to prevent stunted growth.",
        );
      } else if (isEggplant) {
        recommendations.add(
          "Eggplants need sufficient heat and sunlight. Place it in a sunny spot to speed up flowering.",
        );
      } else if (isChili) {
        recommendations.add(
          "Chili peppers become spicier and produce more fruit with full sunlight. Place it in an open area.",
        );
      } else {
        recommendations.add(
          "The plant needs sufficient sunlight. Move it to a spot with direct daily sunlight.",
        );
      }
    } else if (input.sunlight == SunlightLevel.medium) {
      if (isTomato) {
        recommendations.add(
          "Medium sunlight. It's better to increase exposure for sweeter and redder tomatoes.",
        );
      }
    }

    // 2. Evaluate Water
    if (input.water == WaterLevel.low) {
      flaggedDeficiencies.add("Low Water");
      if (isTomato) {
        recommendations.add(
          "Water tomatoes daily, especially in the morning. Lack of water causes blossom end rot.",
        );
      } else if (isEggplant) {
        recommendations.add(
          "Increase watering for eggplants. Eggplant flowers fall off easily when underwatered.",
        );
      } else if (isChili) {
        recommendations.add(
          "Although chili is drought-tolerant, water it when the soil surface is dry to prevent leaves from wilting.",
        );
      } else {
        recommendations.add(
          "Increase watering. Ensure the soil is damp enough for plant growth.",
        );
      }
    } else if (input.water == WaterLevel.high) {
      flaggedDeficiencies.add("Excessive Water");
      if (isTomato) {
        recommendations.add(
          "Reduce watering for tomatoes. Overwatered soil causes root rot and split fruit.",
        );
      } else if (isEggplant) {
        recommendations.add(
          "Avoid waterlogging the eggplant soil. Ensure proper drainage in the pot or plot.",
        );
      } else if (isChili) {
        recommendations.add(
          "Chili peppers are sensitive to excessive water. Waterlogged soil causes leaf drop and fungal wilt.",
        );
      } else {
        recommendations.add(
          "Reduce watering. Excess water can harm the plant's roots.",
        );
      }
    }

    // 3. Evaluate Soil Quality
    if (input.soil == SoilQuality.poor) {
      flaggedDeficiencies.add("Poor Soil Quality");
      if (isTomato) {
        recommendations.add(
          "Apply organic compost or vermicast. Tomatoes need soil rich in Calcium and Phosphorus for quality fruit.",
        );
      } else if (isEggplant) {
        recommendations.add(
          "Mix organic compost or poultry manure into eggplant soil to boost Nitrogen for leafy growth.",
        );
      } else if (isChili) {
        recommendations.add(
          "Apply mulch, compost, or organic fertilizer to chili plants to enrich the soil and encourage branching.",
        );
      } else {
        recommendations.add(
          "Apply organic compost or fertilizer to enrich soil nutrients.",
        );
      }
    }

    // 4. Evaluate Season Specifics
    if (input.season == Season.wet) {
      if (isTomato && input.water == WaterLevel.high) {
        recommendations.add(
          "Rainy Season Alert: Tomatoes are susceptible to fungal diseases when constantly wet. Ensure roots are not waterlogged.",
        );
      } else if (isChili) {
        recommendations.add(
          "Rainy Season Alert: Protect chili peppers from heavy rains that can knock off flowers and fruit.",
        );
      }
    } else if (input.season == Season.dry) {
      if (isTomato && input.water == WaterLevel.medium) {
        recommendations.add(
          "Dry Season Tip: Use mulch (like straw) to keep tomato soil cool and retain moisture.",
        );
      } else if (isEggplant && input.water == WaterLevel.low) {
        recommendations.add(
          "Dry Season Tip: Eggplants dry out easily in summer. Water them twice a day (morning and afternoon).",
        );
      }
    }

    // If no recommendations generated (ideal setup), provide positive reinforcement
    if (recommendations.isEmpty) {
      recommendations.add(
        "Excellent conditions! Continue with your current care routine.",
      );
    }

    String healthStatus = flaggedDeficiencies.isEmpty ? "Healthy" : "Deficient";

    return RecommendationResult(
      healthStatus: healthStatus,
      flaggedDeficiencies: flaggedDeficiencies,
      recommendations: recommendations,
    );
  }

  /// Parses fertilizer quantity text (e.g., "15g", "20 grams") into numerical grams.
  static int? parseFertilizerQuantity(String text) {
    if (text.isEmpty) return null;
    final cleaned = text.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final numberMatch = RegExp(r'^[\d]+(\.\d+)?').firstMatch(cleaned);
    if (numberMatch == null) return null;
    final double value = double.tryParse(numberMatch.group(0)!) ?? 0;
    // Convert kg to g if needed
    if (cleaned.contains('kg')) return (value * 1000).round();
    return value.round(); // Default is grams
  }

  /// Returns (minRecommended, maxRecommended) fertilizer in grams per plant per application.
  static (int, int) getFertilizerRange(String crop, GrowthStage stage) {
    final c = crop.toLowerCase();
    final bool isTomato = c.contains('tomato') || c.contains('kamatis');
    final bool isEggplant = c.contains('eggplant') || c.contains('talong');

    if (isTomato) {
      switch (stage) {
        case GrowthStage.seedling: return (0, 0);
        case GrowthStage.youngPlant: return (8, 12);
        case GrowthStage.flowering: return (12, 18);
        case GrowthStage.fruiting: return (8, 12);
      }
    } else if (isEggplant) {
      switch (stage) {
        case GrowthStage.seedling: return (0, 0);
        case GrowthStage.youngPlant: return (10, 15);
        case GrowthStage.flowering: return (12, 18);
        case GrowthStage.fruiting: return (8, 12);
      }
    } else { // Chili
      switch (stage) {
        case GrowthStage.seedling: return (0, 0);
        case GrowthStage.youngPlant: return (8, 10);
        case GrowthStage.flowering: return (8, 12);
        case GrowthStage.fruiting: return (6, 10);
      }
    }
  }

  /// Parses text quantities (e.g., "10000ml", "1.5L", "500") into numerical milliliters.
  static int? parseWaterQuantity(String text) {
    if (text.isEmpty) return null;
    final cleaned = text.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final numberMatch = RegExp(r'^\d+(\.\d+)?').firstMatch(cleaned);
    if (numberMatch == null) return null;
    
    final double value = double.tryParse(numberMatch.group(0)!) ?? 0;
    
    if (cleaned.contains('liters') || cleaned.contains('liter') || (cleaned.contains('l') && !cleaned.contains('ml'))) {
      return (value * 1000).round();
    }
    return value.round(); // Default is mL
  }

  /// Returns (minRecommended, maxRecommended) watering limit per crop and growth stage.
  static (int, int) getWateringRange(String crop, GrowthStage stage) {
    final c = crop.toLowerCase();
    final bool isTomato = c.contains('tomato') || c.contains('kamatis');
    final bool isEggplant = c.contains('eggplant') || c.contains('talong');
    
    if (isTomato) {
      switch (stage) {
        case GrowthStage.seedling: return (100, 250);
        case GrowthStage.youngPlant: return (250, 450);
        case GrowthStage.flowering:
        case GrowthStage.fruiting: return (450, 800);
      }
    } else if (isEggplant) {
      switch (stage) {
        case GrowthStage.seedling: return (150, 300);
        case GrowthStage.youngPlant: return (300, 650);
        case GrowthStage.flowering:
        case GrowthStage.fruiting: return (650, 1200);
      }
    } else { // Chili / Siling Labuyo
      switch (stage) {
        case GrowthStage.seedling: return (80, 180);
        case GrowthStage.youngPlant: return (180, 350);
        case GrowthStage.flowering:
        case GrowthStage.fruiting: return (350, 650);
      }
    }
  }

  /// Returns fertilizer recommendation per crop and growth stage.
  static FertilizerRecommendation getFertilizerRecommendation(String crop, GrowthStage stage) {
    final c = crop.toLowerCase();
    final bool isTomato = c.contains('tomato') || c.contains('kamatis');
    final bool isEggplant = c.contains('eggplant') || c.contains('talong');

    // Seedling stage: fertilizer NOT recommended for any crop
    if (stage == GrowthStage.seedling) {
      return FertilizerRecommendation(
        needed: false,
        type: 'None',
        amount: 'N/A',
        frequency: 'N/A',
        tip: 'Do not fertilize at seedling stage — roots are too tender and can get burned by fertilizer.',
      );
    }

    if (isTomato) {
      switch (stage) {
        case GrowthStage.seedling:
          return FertilizerRecommendation(needed: false, type: 'None', amount: 'N/A', frequency: 'N/A', tip: 'Do not fertilize at seedling stage.');
        case GrowthStage.youngPlant:
          return FertilizerRecommendation(
            needed: true,
            type: 'Nitrogen-rich (e.g. Urea 46-0-0 or Ammonium Sulfate)',
            amount: '10g per plant',
            frequency: 'Every 2 weeks',
            tip: 'Focus on Nitrogen to boost leaf and stem growth.',
          );
        case GrowthStage.flowering:
          return FertilizerRecommendation(
            needed: true,
            type: 'Phosphorus & Potassium-rich (e.g. 0-46-0 or 14-14-14)',
            amount: '15g per plant',
            frequency: 'Every 2 weeks',
            tip: 'Reduce Nitrogen. Increase Phosphorus and Potassium to encourage more flowers and fruit set.',
          );
        case GrowthStage.fruiting:
          return FertilizerRecommendation(
            needed: true,
            type: 'Low-Nitrogen, Potassium-rich (e.g. 0-0-60 Muriate of Potash)',
            amount: '10g per plant',
            frequency: 'Every 2 weeks',
            tip: 'Potassium improves fruit quality and sweetness. Avoid excess Nitrogen which causes leafy growth at the expense of fruit.',
          );
      }
    } else if (isEggplant) {
      switch (stage) {
        case GrowthStage.seedling:
          return FertilizerRecommendation(needed: false, type: 'None', amount: 'N/A', frequency: 'N/A', tip: 'Do not fertilize at seedling stage.');
        case GrowthStage.youngPlant:
          return FertilizerRecommendation(
            needed: true,
            type: 'Balanced NPK (e.g. 14-14-14 complete fertilizer)',
            amount: '10–15g per plant',
            frequency: 'Every 2 weeks',
            tip: 'Balanced fertilizer supports even growth of roots, stems, and early leaves.',
          );
        case GrowthStage.flowering:
          return FertilizerRecommendation(
            needed: true,
            type: 'Potassium-rich (e.g. 0-0-60 or 12-12-17)',
            amount: '15g per plant',
            frequency: 'Every 2 weeks',
            tip: 'Boost Potassium during flowering to prevent flower drop and support fruit development.',
          );
        case GrowthStage.fruiting:
          return FertilizerRecommendation(
            needed: true,
            type: 'Light Potassium feed (e.g. 12-12-17)',
            amount: '10g per plant',
            frequency: 'Every 2 weeks',
            tip: 'Light feeding keeps the plant productive. Heavy fertilization at this stage causes more leaves, not more fruit.',
          );
      }
    } else { // Siling Labuyo / Chili
      switch (stage) {
        case GrowthStage.seedling:
          return FertilizerRecommendation(needed: false, type: 'None', amount: 'N/A', frequency: 'N/A', tip: 'Do not fertilize at seedling stage.');
        case GrowthStage.youngPlant:
          return FertilizerRecommendation(
            needed: true,
            type: 'Balanced NPK (e.g. 14-14-14)',
            amount: '8–10g per plant',
            frequency: 'Every 2 weeks',
            tip: 'Balanced NPK encourages bushy, branching growth which leads to more fruit sites.',
          );
        case GrowthStage.flowering:
          return FertilizerRecommendation(
            needed: true,
            type: 'Phosphorus-rich (e.g. 0-46-0 Superphosphate)',
            amount: '10g per plant',
            frequency: 'Every 2 weeks',
            tip: 'High Phosphorus promotes strong flower formation. More flowers means more chilis!',
          );
        case GrowthStage.fruiting:
          return FertilizerRecommendation(
            needed: true,
            type: 'Light Potassium feed (e.g. 0-0-60)',
            amount: '8g per plant',
            frequency: 'Every 2 weeks',
            tip: 'Light Potassium keeps fruits firm and spicy. Avoid heavy fertilization to prevent leaf burn.',
          );
      }
    }
  }

  /// Evaluates current day's care logs and returns safety flags/warnings and health score offsets.
  static DailyValidationResult validateDailyActions({
    required String crop,
    required GrowthStage stage,
    required List<DailyAction> actions,
  }) {
    int healthScoreModifier = 0;
    List<String> warnings = [];

    // Evaluate Water logs
    final wateringActions = actions.where((a) => a.action == 'Watered').toList();
    if (wateringActions.isNotEmpty) {
      int totalWaterMl = 0;
      for (var action in wateringActions) {
        final ml = parseWaterQuantity(action.quantity);
        if (ml != null) {
          totalWaterMl += ml;
        }
      }

      if (totalWaterMl > 0) {
        final (minRec, maxRec) = getWateringRange(crop, stage);
        
        if (totalWaterMl > maxRec * 3) { // Severe overwatering
          warnings.add("Severe Overwatering: $totalWaterMl mL is extremely high! Excessive water floods the soil, choking roots of oxygen and leading to root rot.");
          healthScoreModifier -= 40;
        } else if (totalWaterMl > maxRec) { // Mild overwatering
          warnings.add("Overwatering Alert: $totalWaterMl mL is higher than the recommended maximum ($maxRec mL). Keep soil damp but not soggy.");
          healthScoreModifier -= 15;
        } else if (totalWaterMl < minRec) { // Underwatering
          warnings.add("Underwatering Alert: $totalWaterMl mL is below the recommended minimum ($minRec mL). Increase watering to prevent wilting.");
          healthScoreModifier -= 15;
        }
      }
    }

    // Evaluate Fertilization logs
    final fertilizingActions = actions.where((a) => a.action == 'Fertilized').toList();
    if (fertilizingActions.isNotEmpty) {
      // Check if fertilizer is even needed at this stage
      final fertRec = getFertilizerRecommendation(crop, stage);
      if (!fertRec.needed) {
        warnings.add("Fertilizer Not Recommended: Applying fertilizer at ${stage.nameEnglish} stage can burn tender roots. Skip fertilization at this stage.");
        healthScoreModifier -= 20;
      } else {
        // Parse and validate total fertilizer quantity
        int totalFertG = 0;
        for (var action in fertilizingActions) {
          final g = parseFertilizerQuantity(action.quantity);
          if (g != null) totalFertG += g;
        }
        if (totalFertG > 0) {
          final (minRec, maxRec) = getFertilizerRange(crop, stage);
          if (totalFertG > maxRec * 2) { // Severe over-fertilization
            warnings.add("Severe Over-Fertilization: ${totalFertG}g applied is dangerously high! This causes nutrient burn — leaves will yellow and roots may be damaged. Max recommended: ${maxRec}g.");
            healthScoreModifier -= 40;
          } else if (totalFertG > maxRec) { // Mild over-fertilization
            warnings.add("Over-Fertilization Alert: ${totalFertG}g exceeds the recommended maximum (${maxRec}g). Excess fertilizer causes salt buildup in soil. Water thoroughly to dilute.");
            healthScoreModifier -= 20;
          }
        }
        if (fertilizingActions.length > 1) { // Multiple times same day
          warnings.add("Excessive Fertilization: Fertilizing multiple times in a single day causes nutrient burn. Limit to once every 2 weeks.");
          healthScoreModifier -= 15;
        }
      }
    }

    return DailyValidationResult(
      healthScoreModifier: healthScoreModifier,
      warnings: warnings,
    );
  }

  /// Generates a specific tip for a single day of the simulation based on the grid state and environment.
  static String getDaySuggestion({
    required int day,
    required List<List<int>> grid,
    required PlantInput input,
  }) {
    final String crop = input.vegetableType.toLowerCase();
    final bool isTomato = crop.contains('tomato') || crop.contains('kamatis');
    final bool isEggplant = crop.contains('eggplant') || crop.contains('talong');
    final bool isChili = crop.contains('siling') || crop.contains('chili') || crop.contains('pepper');

    // Count states
    int seedling = 0;
    int young = 0;
    int flowering = 0;
    int fruiting = 0;
    
    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        switch (grid[r][c]) {
          case 1: seedling++; break;
          case 2: young++; break;
          case 3: flowering++; break;
          case 4: fruiting++; break;
        }
      }
    }

    if (day == 0) {
      return "Day 0 (Start): Ensure the soil is damp. The first day of monitoring is critical for plant adaptation.";
    }

    // Check waterlogging risk
    if (input.water == WaterLevel.high && input.season == Season.wet) {
      return "Day $day: Warning! Soil is too wet due to the rainy season. Reduce watering to prevent mold and root rot.";
    }

    // Check severe drought
    if (input.water == WaterLevel.low && input.season == Season.dry) {
      return "Day $day: Dry Season Warning! Soil dries out quickly. It's best to water in the morning and afternoon to prevent leaves from wilting.";
    }

    // High presence of flowers
    if (flowering > fruiting && flowering >= 2) {
      if (isTomato) {
        return "Day $day: Tomato is flowering. Reduce Nitrogen fertilizer and apply Potassium-rich fertilizer for fruit development.";
      }
      if (isEggplant) {
        return "Day $day: Eggplant is flowering. Ensure adequate sunlight to prevent flowers from dropping.";
      }
      return "Day $day: The plant is starting to flower. Avoid disturbing or heavily wetting the flowers.";
    }

    // High presence of fruits
    if (fruiting >= 2) {
      if (isTomato) {
        return "Day $day: Tomato fruits are forming! Support the plant with stakes to prevent branches from breaking.";
      }
      if (isEggplant) {
        return "Day $day: Eggplant is fruiting. Water adequately to keep the skin smooth and healthy.";
      }
      return "Day $day: Fruits have formed! The crops are ready for the upcoming harvest.";
    }

    // Seedling stage dominant
    if (seedling > young && seedling >= 2) {
      return "Day $day: Plant is in the seedling stage. Water with a gentle mist to avoid displacing the roots.";
    }

    // Young plant stage dominant
    if (young > flowering && young >= 2) {
      return "Day $day: Rapid foliage and branch growth. Apply a little compost to support its nutrition.";
    }

    // Standard / Default day tips
    switch (day % 3) {
      case 0:
        return "Day $day: Regularly inspect under the leaves for pests like aphids or caterpillars.";
      case 1:
        return "Day $day: Keep the surroundings clean. Remove weeds that compete for nutrients.";
      default:
        return "Day $day: Ensure the plant receives at least 6 hours of sunlight in its current position.";
    }
  }
}

class RecommendationResult {
  final String healthStatus;
  final List<String> flaggedDeficiencies;
  final List<String> recommendations;

  RecommendationResult({
    required this.healthStatus,
    required this.flaggedDeficiencies,
    required this.recommendations,
  });
}

class DailyValidationResult {
  final int healthScoreModifier;
  final List<String> warnings;

  DailyValidationResult({
    required this.healthScoreModifier,
    required this.warnings,
  });
}

class FertilizerRecommendation {
  final bool needed;
  final String type;
  final String amount;
  final String frequency;
  final String tip;

  FertilizerRecommendation({
    required this.needed,
    required this.type,
    required this.amount,
    required this.frequency,
    required this.tip,
  });
}
