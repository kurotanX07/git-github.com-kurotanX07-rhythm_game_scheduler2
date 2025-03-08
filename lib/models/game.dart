class Game {
  final String id;
  final String name;
  final String imageUrl;
  final String developer;
  final bool isSelected;
  final bool isFavorite;
  final String? description;
  final String? officialUrl;

  Game({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.developer,
    this.isSelected = false,
    this.isFavorite = false,
    this.description,
    this.officialUrl,
  });

  Game copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? developer,
    bool? isSelected,
    bool? isFavorite,
    String? description,
    String? officialUrl,
  }) {
    return Game(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      developer: developer ?? this.developer,
      isSelected: isSelected ?? this.isSelected,
      isFavorite: isFavorite ?? this.isFavorite,
      description: description ?? this.description,
      officialUrl: officialUrl ?? this.officialUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'developer': developer,
      'description': description,
      'officialUrl': officialUrl,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'] ?? '',
      developer: map['developer'] ?? '',
      description: map['description'],
      officialUrl: map['officialUrl'],
    );
  }
}