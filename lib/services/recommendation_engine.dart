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
      flaggedDeficiencies.add("Kakulangan sa Sikat ng Araw (Low Sunlight)");
      if (isTomato) {
        recommendations.add(
          "Ang kamatis ay nangangailangan ng hindi bababa sa 6-8 oras ng direktang sikat ng araw. Ilipat ito sa mas maaraw na lugar upang maiwasan ang pagkabansot.",
        );
      } else if (isEggplant) {
        recommendations.add(
          "Ang talong ay nangangailangan ng sapat na init at araw. Ilagay ito sa pwestong nasisikatan ng araw upang mapabilis ang pamumulaklak.",
        );
      } else if (isChili) {
        recommendations.add(
          "Ang siling labuyo ay mas nagiging maanghang at marami ang bunga kapag nakakakuha ng buong sikat ng araw. Ilagay ito sa open space.",
        );
      } else {
        recommendations.add(
          "Kailangan ng halaman ng sapat na sikat ng araw. Ilipat ito sa lugar na may direktang sikat ng araw araw-araw.",
        );
      }
    } else if (input.sunlight == SunlightLevel.medium) {
      if (isTomato) {
        recommendations.add(
          "Katamtamang sikat ng araw. Mas mainam kung madaragdagan pa ang exposure ng kamatis para sa mas matamis at mapulang bunga.",
        );
      }
    }

    // 2. Evaluate Water
    if (input.water == WaterLevel.low) {
      flaggedDeficiencies.add("Kakulangan sa Tubig (Low Water)");
      if (isTomato) {
        recommendations.add(
          "Diligan ang kamatis araw-araw, lalo na tuwing umaga. Ang kakulangan sa tubig ay nagdudulot ng 'blossom end rot' o pagkasira ng ilalim ng bunga.",
        );
      } else if (isEggplant) {
        recommendations.add(
          "Dagdagan ang pagdidilig sa talong. Kapag kulang sa tubig ang talong, mabilis malaglag ang mga bulaklak nito.",
        );
      } else if (isChili) {
        recommendations.add(
          "Bagamat matibay sa tuyong lupa ang sili, diligan ito kapag tuyo na ang ibabaw ng lupa upang hindi malanta ang mga dahon.",
        );
      } else {
        recommendations.add(
          "Dagdagan ang pagdidilig. Siguraduhing sapat ang basang lupa para sa paglaki ng halaman.",
        );
      }
    } else if (input.water == WaterLevel.high) {
      flaggedDeficiencies.add("Sobrang Tubig (Excessive Water)");
      if (isTomato) {
        recommendations.add(
          "Bawasan ang pagdidilig ng kamatis. Ang sobrang basang lupa ay sanhi ng pagkabulok ng ugat (root rot) at pagkabitak ng bunga.",
        );
      } else if (isEggplant) {
        recommendations.add(
          "Iwasan ang pagbaha sa lupa ng talong. Siguraduhing maayos ang drainage o daluyan ng tubig ng paso o plot.",
        );
      } else if (isChili) {
        recommendations.add(
          "Sensitibo ang siling labuyo sa labis na tubig. Ang basang-basang lupa ay nagiging sanhi ng pagkalagas ng dahon at fungal wilt.",
        );
      } else {
        recommendations.add(
          "Bawasan ang pagdidilig. Ang labis na tubig ay maaaring makasama sa ugat ng halaman.",
        );
      }
    }

    // 3. Evaluate Soil Quality
    if (input.soil == SoilQuality.poor) {
      flaggedDeficiencies.add("Mahinang Kalidad ng Lupa (Poor Soil Quality)");
      if (isTomato) {
        recommendations.add(
          "Maglagay ng organic compost o vermicast. Kailangan ng kamatis ng lupang mayaman sa Calcium at Phosphorus para sa magandang prutas.",
        );
      } else if (isEggplant) {
        recommendations.add(
          "Haluan ng pataba (compost o dumi ng manok) ang lupa ng talong upang madagdagan ang Nitrogen na kailangan para sa malalaking dahon.",
        );
      } else if (isChili) {
        recommendations.add(
          "Maglagay ng tuyong dahon, compost, o organic fertilizer sa sili para mapayaman ang lupa at lumago ang mga sanga nito.",
        );
      } else {
        recommendations.add(
          "Maglagay ng organic compost o pataba upang madagdagan ang mga sustansya sa lupa.",
        );
      }
    }

    // 4. Evaluate Season Specifics
    if (input.season == Season.wet) {
      if (isTomato && input.water == WaterLevel.high) {
        recommendations.add(
          "Babala sa Tag-ulan: Ang kamatis ay madaling kapitan ng fungal disease kapag palaging basa. Tiyaking hindi nabababad sa tubig ang ugat.",
        );
      } else if (isChili) {
        recommendations.add(
          "Babala sa Tag-ulan: Protektahan ang siling labuyo mula sa malalakas na ulan na maaaring makalaglag sa mga bulaklak at prutas nito.",
        );
      }
    } else if (input.season == Season.dry) {
      if (isTomato && input.water == WaterLevel.medium) {
        recommendations.add(
          "Payo sa Tag-init: Gumamit ng 'mulch' (tulad ng dayami) sa ibabaw ng lupa upang mapanatiling malamig at basa ang lupa ng kamatis.",
        );
      } else if (isEggplant && input.water == WaterLevel.low) {
        recommendations.add(
          "Payo sa Tag-init: Ang talong ay madaling matuyo sa tag-init. Siguraduhing madiligan ito ng dalawang beses sa isang araw (umaga at hapon).",
        );
      }
    }

    // If no recommendations generated (ideal setup), provide positive reinforcement
    if (recommendations.isEmpty) {
      recommendations.add(
        "Napakaganda ng kondisyon! Ipagpatuloy ang kasalukuyang pamamaraan ng pag-aalaga ng iyong halaman.",
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
      return "Araw 0 (Simula): Tiyaking mamasa-masa ang lupa. Ang unang araw ng pagmomonitor ay kritikal para sa pag-angkop ng halaman.";
    }

    // Check waterlogging risk
    if (input.water == WaterLevel.high && input.season == Season.wet) {
      return "Araw $day: Babala! Masyadong basa ang lupa dahil sa tag-ulan. Bawasan ang pagdidilig upang maiwasan ang amag at pagkabulok ng ugat.";
    }

    // Check severe drought
    if (input.water == WaterLevel.low && input.season == Season.dry) {
      return "Araw $day: Babala sa Tag-init! Mabilis natutuyo ang lupa. Mainam na magdilig sa umaga at hapon upang hindi malanta ang mga dahon.";
    }

    // High presence of flowers
    if (flowering > fruiting && flowering >= 2) {
      if (isTomato) {
        return "Araw $day: Namumulaklak na ang kamatis. Bawasan ang Nitrogen fertilizer at maglagay ng pataba na may Potassium para lumaki ang mga bunga.";
      }
      if (isEggplant) {
        return "Araw $day: Namumulaklak na ang talong. Siguraduhing may sapat na sikat ng araw upang hindi maglaglagan ang mga bulaklak.";
      }
      return "Araw $day: Nagsisimula nang mamulaklak ang halaman. Tiyaking hindi nayayanig o nababasa ng malakas ang mga bulaklak.";
    }

    // High presence of fruits
    if (fruiting >= 2) {
      if (isTomato) {
        return "Araw $day: May namumuong bunga ng kamatis! Suportahan ang halaman ng stakes (tukod) upang hindi mabali ang mga sanga.";
      }
      if (isEggplant) {
        return "Araw $day: May bunga na ang iyong talong. Diligan ito ng sapat upang maging makinis at malusog ang balat ng talong.";
      }
      return "Araw $day: May mga bunga na! Handang-handa na ang mga pananim para sa darating na pag-aani.";
    }

    // Seedling stage dominant
    if (seedling > young && seedling >= 2) {
      return "Araw $day: Nasa yugto ng seedling (punla) ang halaman. Magdilig gamit ang banayad na spray (mist) upang hindi maalis ang mga ugat sa lupa.";
    }

    // Young plant stage dominant
    if (young > flowering && young >= 2) {
      return "Araw $day: Mabilis ang paglaki ng mga dahon at sanga. Maglagay ng kaunting compost upang masuportahan ang nutrisyon nito.";
    }

    // Standard / Default day tips
    switch (day % 3) {
      case 0:
        return "Araw $day: Regular na suriin ang ilalim ng mga dahon para sa mga peste tulad ng aphids o uod.";
      case 1:
        return "Araw $day: Panatilihin ang kalinisan sa paligid ng halaman. Alisin ang mga ligaw na damo (weeds) na umaagaw sa sustansya.";
      default:
        return "Araw $day: Siguraduhing nakakatanggap ang halaman ng hindi bababa sa 6 na oras ng sikat ng araw sa pwesto nito.";
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
