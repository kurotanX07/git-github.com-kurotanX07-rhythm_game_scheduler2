class Game {
  final String id;
  final String name;
  final String imageUrl;
  final String developer;
  final bool isSelected;

  Game({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.developer,
    this.isSelected = false,
  });

  Game copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? developer,
    bool? isSelected,
  }) {
    return Game(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      developer: developer ?? this.developer,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'developer': developer,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'],
      developer: map['developer'],
    );
  }
}