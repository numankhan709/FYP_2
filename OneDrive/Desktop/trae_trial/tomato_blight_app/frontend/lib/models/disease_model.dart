import 'package:json_annotation/json_annotation.dart';

part 'disease_model.g.dart';

@JsonSerializable()
class Disease {
  final String id;
  final String name;
  final String description;
  final List<String> symptoms;
  final List<String> causes;
  final List<String> treatments;
  final List<String> prevention;
  final String imageUrl;
  final List<String> affectedParts; // 'leaves', 'fruits', 'stems', etc.
  final Map<String, dynamic>? additionalInfo;

  Disease({
    required this.id,
    required this.name,
    required this.description,
    required this.symptoms,
    required this.causes,
    required this.treatments,
    required this.prevention,
    required this.imageUrl,
    required this.affectedParts,
    this.additionalInfo,
  });

  factory Disease.fromJson(Map<String, dynamic> json) => _$DiseaseFromJson(json);
  Map<String, dynamic> toJson() => _$DiseaseToJson(this);

  Disease copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? symptoms,
    List<String>? causes,
    List<String>? treatments,
    List<String>? prevention,
    String? imageUrl,
    List<String>? affectedParts,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Disease(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      symptoms: symptoms ?? this.symptoms,
      causes: causes ?? this.causes,
      treatments: treatments ?? this.treatments,
      prevention: prevention ?? this.prevention,
      imageUrl: imageUrl ?? this.imageUrl,
      affectedParts: affectedParts ?? this.affectedParts,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  @override
  String toString() {
    return 'Disease{id: $id, name: $name}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Disease && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Predefined common tomato diseases
class TomatoDiseases {
  static List<Disease> getCommonDiseases() {
    return [
      Disease(
        id: 'early_blight',
        name: 'Early Blight',
        description: 'A fungal disease caused by Alternaria solani that affects tomato plants, causing dark spots on leaves and fruits.',
        symptoms: [
          'Dark brown spots with concentric rings on older leaves',
          'Yellow halos around spots',
          'Leaf yellowing and dropping',
          'Dark, sunken spots on fruits',
          'Stem lesions near soil line'
        ],
        causes: [
          'Alternaria solani fungus',
          'High humidity (above 90%)',
          'Warm temperatures (24-29°C)',
          'Poor air circulation',
          'Overhead watering',
          'Plant stress'
        ],
        treatments: [
          'Apply copper-based fungicides',
          'Use chlorothalonil fungicide',
          'Remove affected plant parts',
          'Improve air circulation',
          'Avoid overhead watering',
          'Apply organic neem oil'
        ],
        prevention: [
          'Choose resistant varieties',
          'Rotate crops annually',
          'Mulch around plants',
          'Water at soil level',
          'Ensure proper spacing',
          'Remove plant debris'
        ],
        imageUrl: 'assets/images/Early_blight.jpg',
        affectedParts: ['leaves', 'fruits', 'stems'],
      ),
      Disease(
        id: 'late_blight',
        name: 'Late Blight',
        description: 'A devastating disease caused by Phytophthora infestans that can destroy entire tomato crops rapidly.',
        symptoms: [
          'Water-soaked spots on leaves',
          'White fuzzy growth on leaf undersides',
          'Brown to black lesions',
          'Rapid plant collapse',
          'Dark, firm spots on fruits',
          'Foul odor from affected tissues'
        ],
        causes: [
          'Phytophthora infestans oomycete',
          'Cool, wet weather',
          'High humidity (above 95%)',
          'Temperature range 15-20°C',
          'Poor drainage',
          'Infected seed or transplants'
        ],
        treatments: [
          'Apply copper fungicides immediately',
          'Use systemic fungicides (metalaxyl)',
          'Remove and destroy affected plants',
          'Improve drainage',
          'Increase air circulation',
          'Apply preventive sprays'
        ],
        prevention: [
          'Use certified disease-free seeds',
          'Choose resistant varieties',
          'Ensure good drainage',
          'Avoid overhead irrigation',
          'Monitor weather conditions',
          'Apply preventive fungicides'
        ],
        imageUrl: 'assets/images/late_blight.jpg',
        affectedParts: ['leaves', 'fruits', 'stems'],
      ),
      Disease(
        id: 'bacterial_spot',
        name: 'Bacterial Spot',
        description: 'A bacterial disease that causes small, dark spots on leaves and fruits, leading to defoliation and fruit damage.',
        symptoms: [
          'Small, dark brown spots on leaves',
          'Yellow halos around spots',
          'Raised, scab-like spots on fruits',
          'Leaf yellowing and drop',
          'Reduced fruit quality',
          'Stem cankers'
        ],
        causes: [
          'Xanthomonas bacteria',
          'Warm, humid conditions',
          'Overhead watering',
          'Contaminated seeds',
          'Infected transplants',
          'Mechanical damage'
        ],
        treatments: [
          'Apply copper-based bactericides',
          'Use streptomycin sprays',
          'Remove affected plant parts',
          'Improve air circulation',
          'Avoid working with wet plants',
          'Disinfect tools regularly'
        ],
        prevention: [
          'Use pathogen-free seeds',
          'Choose resistant varieties',
          'Avoid overhead irrigation',
          'Ensure proper plant spacing',
          'Rotate crops',
          'Sanitize equipment'
        ],
        imageUrl: 'assets/images/bactorial_spot.png',
        affectedParts: ['leaves', 'fruits'],
      ),
      Disease(
        id: 'mosaic_virus',
        name: 'Mosaic Virus',
        description: 'A viral disease that causes mottled patterns on leaves, stunted growth, and reduced fruit production.',
        symptoms: [
          'Mottled yellow and green patterns on leaves',
          'Stunted plant growth',
          'Distorted leaf shape',
          'Reduced fruit size and yield',
          'Yellowing of leaf veins',
          'Brittle leaves'
        ],
        causes: [
          'Tobacco mosaic virus (TMV)',
          'Tomato mosaic virus (ToMV)',
          'Aphid transmission',
          'Contaminated tools',
          'Infected seeds',
          'Mechanical transmission'
        ],
        treatments: [
          'Remove infected plants immediately',
          'Control aphid populations',
          'Disinfect tools with bleach solution',
          'No chemical cure available',
          'Focus on prevention',
          'Improve plant nutrition'
        ],
        prevention: [
          'Use virus-free seeds',
          'Choose resistant varieties',
          'Control aphid vectors',
          'Sanitize tools regularly',
          'Avoid smoking near plants',
          'Remove infected plants promptly'
        ],
        imageUrl: 'assets/images/mosac_virus.jpg',
        affectedParts: ['leaves', 'fruits'],
      ),
      Disease(
        id: 'yellow_virus',
        name: 'Yellow Virus',
        description: 'A viral disease causing yellowing of leaves, stunted growth, and poor fruit development.',
        symptoms: [
          'Yellowing of upper leaves',
          'Stunted plant growth',
          'Reduced fruit production',
          'Leaf curling',
          'Interveinal chlorosis',
          'Poor fruit quality'
        ],
        causes: [
          'Tomato yellow leaf curl virus',
          'Whitefly transmission',
          'High temperatures',
          'Infected transplants',
          'Poor sanitation',
          'Stress conditions'
        ],
        treatments: [
          'Remove infected plants',
          'Control whitefly populations',
          'Use reflective mulches',
          'Apply insecticidal soaps',
          'No direct chemical treatment',
          'Support plant health'
        ],
        prevention: [
          'Use resistant varieties',
          'Control whitefly vectors',
          'Use physical barriers',
          'Monitor regularly',
          'Remove weeds',
          'Quarantine new plants'
        ],
        imageUrl: 'assets/images/yellow_virus.jpg',
        affectedParts: ['leaves', 'fruits'],
      ),
      Disease(
        id: 'leaf_mold',
        name: 'Leaf Mold',
        description: 'A fungal disease that causes yellow spots on upper leaf surfaces and fuzzy growth on undersides.',
        symptoms: [
          'Yellow spots on upper leaf surface',
          'Fuzzy olive-green growth on leaf undersides',
          'Leaf yellowing and browning',
          'Premature leaf drop',
          'Reduced photosynthesis',
          'Poor fruit development'
        ],
        causes: [
          'Passalora fulva fungus',
          'High humidity (above 85%)',
          'Poor air circulation',
          'Temperatures 22-24°C',
          'Overhead watering',
          'Dense plant canopy'
        ],
        treatments: [
          'Improve air circulation',
          'Reduce humidity levels',
          'Apply fungicide sprays',
          'Remove affected leaves',
          'Increase spacing between plants',
          'Use resistant varieties'
        ],
        prevention: [
          'Ensure good ventilation',
          'Avoid overhead watering',
          'Choose resistant varieties',
          'Maintain proper spacing',
          'Monitor humidity levels',
          'Remove plant debris'
        ],
        imageUrl: 'assets/images/mold_leaf.png',
        affectedParts: ['leaves'],
      ),
      Disease(
        id: 'septoria_leaf_spot',
        name: 'Septoria Leaf Spot',
        description: 'A fungal disease causing small, circular spots with dark borders and light centers on leaves.',
        symptoms: [
          'Small circular spots with dark borders',
          'Light gray or tan centers',
          'Black specks in spot centers',
          'Yellow halos around spots',
          'Lower leaves affected first',
          'Progressive defoliation'
        ],
        causes: [
          'Septoria lycopersici fungus',
          'Warm, wet weather',
          'High humidity',
          'Overhead watering',
          'Poor air circulation',
          'Infected plant debris'
        ],
        treatments: [
          'Apply copper-based fungicides',
          'Remove affected lower leaves',
          'Improve air circulation',
          'Avoid overhead watering',
          'Mulch around plants',
          'Use preventive sprays'
        ],
        prevention: [
          'Choose resistant varieties',
          'Ensure proper plant spacing',
          'Water at soil level',
          'Remove plant debris',
          'Rotate crops annually',
          'Apply preventive fungicides'
        ],
        imageUrl: 'assets/images/septorial_leaf.jpg',
        affectedParts: ['leaves'],
      ),
    ];
  }
  
  static Disease? getByName(String name) {
    final diseases = getCommonDiseases();
    try {
      return diseases.firstWhere(
        (disease) => disease.name.toLowerCase() == name.toLowerCase() ||
                    disease.id == name,
      );
    } catch (e) {
      return null;
    }
  }
  
  static Disease? getById(String id) {
    final diseases = getCommonDiseases();
    try {
      return diseases.firstWhere((disease) => disease.id == id);
    } catch (e) {
      return null;
    }
  }
}

// Corn support removed: application is tomato-only

// Combined disease database
class DiseaseDatabase {
  static List<Disease> getAllDiseases() {
    // Tomato-only diseases
    return TomatoDiseases.getCommonDiseases();
  }

  static Disease? getById(String id) {
    return TomatoDiseases.getById(id);
  }

  static Disease? getByName(String name) {
    return TomatoDiseases.getByName(name);
  }

  static List<Disease> getDiseasesByPlantType(String plantType) {
    // Tomato-only
    return TomatoDiseases.getCommonDiseases();
  }
}