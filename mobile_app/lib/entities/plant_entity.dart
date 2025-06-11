class PlantEntity {
  final String id;
  final String name;
  final String type;
  final double confidence;
  final DateTime detectedAt;
  final String? imageUrl;
  
  const PlantEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.confidence,
    required this.detectedAt,
    this.imageUrl,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'confidence': confidence,
      'detectedAt': detectedAt.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }
  
  factory PlantEntity.fromJson(Map<String, dynamic> json) {
    return PlantEntity(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      confidence: json['confidence'].toDouble(),
      detectedAt: DateTime.parse(json['detectedAt']),
      imageUrl: json['imageUrl'],
    );
  }
}