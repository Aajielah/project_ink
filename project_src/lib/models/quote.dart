class QuoteModel {
  final String id;
  final String text;
  final String author;
  final String category;
  final String mood;

  const QuoteModel({
    required this.id,
    required this.text,
    required this.author,
    required this.category,
    required this.mood,
  });

  QuoteModel copyWith({
    String? id,
    String? text,
    String? author,
    String? category,
    String? mood,
  }) {
    return QuoteModel(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      category: category ?? this.category,
      mood: mood ?? this.mood,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'category': category,
      'mood': mood,
    };
  }

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      id: json['id'] as String,
      text: json['text'] as String,
      author: json['author'] as String,
      category: json['category'] as String,
      mood: json['mood'] as String,
    );
  }
}
