import 'extensions.dart';

class Recipe {
  const Recipe({this.id, this.path});

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(id: json['id'] as String, path: json['path'] as String);
  }

  final String id;
  final String path;

  Map<String, String> toJson() => {'id': id, 'path': path};

  String get name {
    return path.allBetween('https://www.cuisinez-pour-bebe.fr/', '/');
  }

  @override
  String toString() => 'Recipe(id: $id, path: $path)';
}
