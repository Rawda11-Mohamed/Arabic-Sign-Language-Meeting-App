enum PhraseCategory {
  confirmation,
  clarification,
  questions,
  problems,
  politeness,
  time,
}

class QuickPhrase {
  final String id;
  final String text;
  final PhraseCategory category;

  QuickPhrase({
    required this.id,
    required this.text,
    required this.category,
  });

  String get preview {
    final words = text.split(' ');
    if (words.length <= 4) return text;
    return '${words.take(4).join(' ')}...';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'category': category.index,
  };

  factory QuickPhrase.fromJson(Map<String, dynamic> json) => QuickPhrase(
    id: json['id'],
    text: json['text'],
    category: PhraseCategory.values[json['category']],
  );
}
