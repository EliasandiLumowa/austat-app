class IndicatorModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final int activeDocumentsCount;
  final bool isActive;

  const IndicatorModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    this.activeDocumentsCount = 0,
    this.isActive = true,
  });

  factory IndicatorModel.fromJson(Map<String, dynamic> json) {
    return IndicatorModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      icon: json['icon'],
      activeDocumentsCount: json['active_documents_count'] is int
          ? json['active_documents_count']
          : int.tryParse(json['active_documents_count']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'active_documents_count': activeDocumentsCount,
      'is_active': isActive,
    };
  }
}
