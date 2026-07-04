enum GrowthStage { seedling, youngPlant, flowering, fruiting }

enum Season { wet, dry }

enum SunlightLevel { low, medium, high }

enum WaterLevel { low, medium, high }

enum SoilQuality { poor, moderate, rich }

extension GrowthStageExtension on GrowthStage {
  String get nameEnglish {
    switch (this) {
      case GrowthStage.seedling:
        return 'Seedling';
      case GrowthStage.youngPlant:
        return 'Young Plant';
      case GrowthStage.flowering:
        return 'Flowering';
      case GrowthStage.fruiting:
        return 'Fruiting';
    }
  }

  String get nameTagalog {
    switch (this) {
      case GrowthStage.seedling:
        return 'Punla';
      case GrowthStage.youngPlant:
        return 'Pagsibol';
      case GrowthStage.flowering:
        return 'Namumulaklak';
      case GrowthStage.fruiting:
        return 'Namumunga';
    }
  }
}

extension SeasonExtension on Season {
  String get nameEnglish {
    switch (this) {
      case Season.wet:
        return 'Wet Season';
      case Season.dry:
        return 'Dry Season';
    }
  }

  String get nameTagalog {
    switch (this) {
      case Season.wet:
        return 'Tag-ulan';
      case Season.dry:
        return 'Tag-init';
    }
  }
}

extension SunlightLevelExtension on SunlightLevel {
  String get nameEnglish {
    switch (this) {
      case SunlightLevel.low:
        return 'Low Exposure';
      case SunlightLevel.medium:
        return 'Medium Exposure';
      case SunlightLevel.high:
        return 'High Exposure';
    }
  }

  String get nameTagalog {
    switch (this) {
      case SunlightLevel.low:
        return 'Mababa';
      case SunlightLevel.medium:
        return 'Katamtaman';
      case SunlightLevel.high:
        return 'Mataas';
    }
  }
}

extension WaterLevelExtension on WaterLevel {
  String get nameEnglish {
    switch (this) {
      case WaterLevel.low:
        return 'Low Availability';
      case WaterLevel.medium:
        return 'Medium Availability';
      case WaterLevel.high:
        return 'High Availability';
    }
  }

  String get nameTagalog {
    switch (this) {
      case WaterLevel.low:
        return 'Mababa';
      case WaterLevel.medium:
        return 'Katamtaman';
      case WaterLevel.high:
        return 'Mataas';
    }
  }
}

extension SoilQualityExtension on SoilQuality {
  String get nameEnglish {
    switch (this) {
      case SoilQuality.poor:
        return 'Poor Soil';
      case SoilQuality.moderate:
        return 'Moderate Soil';
      case SoilQuality.rich:
        return 'Rich Soil';
    }
  }

  String get nameTagalog {
    switch (this) {
      case SoilQuality.poor:
        return 'Mababa (Mahirap)';
      case SoilQuality.moderate:
        return 'Katamtaman';
      case SoilQuality.rich:
        return 'Mataas (Mayaman)';
    }
  }
}

class PlantInput {
  final String vegetableType; // Tomato, Eggplant, Siling Labuyo
  final DateTime plantingDate;
  final GrowthStage currentStage;
  final Season season;
  final SunlightLevel sunlight;
  final WaterLevel water;
  final SoilQuality soil;

  PlantInput({
    required this.vegetableType,
    required this.plantingDate,
    required this.currentStage,
    required this.season,
    required this.sunlight,
    required this.water,
    required this.soil,
  });

  String get vegetableTagalog {
    switch (vegetableType.toLowerCase()) {
      case 'tomato':
        return 'Kamatis';
      case 'eggplant':
        return 'Talong';
      case 'siling labuyo':
        return 'Siling Labuyo';
      default:
        return vegetableType;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'vegetableType': vegetableType,
      'plantingDate': plantingDate.toIso8601String(),
      'currentStage': currentStage.index,
      'season': season.index,
      'sunlight': sunlight.index,
      'water': water.index,
      'soil': soil.index,
    };
  }

  factory PlantInput.fromJson(Map<String, dynamic> json) {
    return PlantInput(
      vegetableType: json['vegetableType'] as String,
      plantingDate: DateTime.parse(json['plantingDate'] as String),
      currentStage: GrowthStage.values[json['currentStage'] as int],
      season: Season.values[json['season'] as int],
      sunlight: SunlightLevel.values[json['sunlight'] as int],
      water: WaterLevel.values[json['water'] as int],
      soil: SoilQuality.values[json['soil'] as int],
    );
  }
}
