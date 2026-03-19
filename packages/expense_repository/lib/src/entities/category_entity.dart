class CategoryEntity {
  String categoryId;
  String name;
  int totalExpenses;
  String icon;
  String color;

  CategoryEntity({
    required this.categoryId,
    required this.name,
    required this.totalExpenses,
    required this.icon,
    required this.color,
  });

  Map<String, Object?> toDocument() {
    return {
      'categoryId': categoryId,
      'name': name,
      'totalExpenses': totalExpenses,
      'icon': icon,
      'color': color,
    };
  }

  static CategoryEntity fromDocument(Map<String, dynamic> doc) {
    final categoryId = doc['categoryId'] ?? doc['categoryid'] ?? '';
    final name = doc['name'] ?? '';
    final totalExpenses = doc['totalExpenses'] ?? doc['totalexpenses'] ?? 0;
    final icon = doc['icon'] ?? '';
    final color = doc['color'] ?? '';

    return CategoryEntity(
      categoryId: categoryId.toString(),
      name: name.toString(),
      totalExpenses: totalExpenses is int
          ? totalExpenses
          : int.tryParse(totalExpenses.toString()) ?? 0,
      icon: icon.toString(),
      color: color.toString(),
    );
  }
}
