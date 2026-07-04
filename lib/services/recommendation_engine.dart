import '../models/plant_input.dart';

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
    int empty = 0;
    int seedling = 0;
    int young = 0;
    int flowering = 0;
    int fruiting = 0;
    
    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        switch (grid[r][c]) {
          case 0: empty++; break;
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
