import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meeting/models/quick_phrase.dart';

class QuickPhraseService {
  static const String _favoritesKey = 'quick_phrase_favorites';
  static const int _maxFavorites = 8;

  final List<QuickPhrase> allPhrases = [
    // Confirmation
    QuickPhrase(id: 'c1', text: 'أيوة، فاهم قصدك بالظبط.', category: PhraseCategory.confirmation),
    QuickPhrase(id: 'c2', text: 'كلامك صح، أنا معاك.', category: PhraseCategory.confirmation),
    QuickPhrase(id: 'c3', text: 'تمام، هنعمل كدة.', category: PhraseCategory.confirmation),
    QuickPhrase(id: 'c4', text: 'واضح جداً، تسلم.', category: PhraseCategory.confirmation),

    // Clarification
    QuickPhrase(id: 'cl1', text: 'مش فاهم قوي، ممكن توضح أكتر؟', category: PhraseCategory.clarification),
    QuickPhrase(id: 'cl2', text: 'معلش، ممكن تعيد الحركة دي تاني؟', category: PhraseCategory.clarification),
    QuickPhrase(id: 'cl3', text: 'تقصد إيه بالكلمة دي بالظبط؟', category: PhraseCategory.clarification),
    QuickPhrase(id: 'cl4', text: 'ممكن تبطأ شوية وأنت بتشاور؟', category: PhraseCategory.clarification),

    // Questions
    QuickPhrase(id: 'q1', text: 'عندك أي سؤال تاني؟', category: PhraseCategory.questions),
    QuickPhrase(id: 'q2', text: 'أقدر أساعدك إزاي في الموضوع ده؟', category: PhraseCategory.questions),
    QuickPhrase(id: 'q3', text: 'إيه رأيك في الفكرة دي؟', category: PhraseCategory.questions),
    QuickPhrase(id: 'q4', text: 'هنبدأ إمتى الخطوة اللي جاية؟', category: PhraseCategory.questions),

    // Problems
    QuickPhrase(id: 'p1', text: 'النور ضعيف، مش شايف الإشارة كويس.', category: PhraseCategory.problems),
    QuickPhrase(id: 'p2', text: 'النت مش تمام، الصورة بتقطع.', category: PhraseCategory.problems),
    QuickPhrase(id: 'p3', text: 'في دوشة ورايا مشوشة عليا.', category: PhraseCategory.problems),
    QuickPhrase(id: 'p4', text: 'الكاميرا عندي فيها مشكلة.', category: PhraseCategory.problems),

    // Politeness
    QuickPhrase(id: 'po1', text: 'شكراً جداً على وقتك وتعبك.', category: PhraseCategory.politeness),
    QuickPhrase(id: 'po2', text: 'اتشرفت جداً بالكلام معاك النهاردة.', category: PhraseCategory.politeness),
    QuickPhrase(id: 'po3', text: 'معلش قطعت كلامك، بس عندي ملحوظة.', category: PhraseCategory.politeness),
    QuickPhrase(id: 'po4', text: 'لو سمحت، ممكن أزود حاجة؟', category: PhraseCategory.politeness),

    // Time
    QuickPhrase(id: 't1', text: 'هحتاج دقيقة واحدة أتأكد من الحاجة دي.', category: PhraseCategory.time),
    QuickPhrase(id: 't2', text: 'ممكن نأجل الكلام ده لوقت تاني؟', category: PhraseCategory.time),
    QuickPhrase(id: 't3', text: 'وقت الاجتماع قرب يخلص.', category: PhraseCategory.time),
    QuickPhrase(id: 't4', text: 'هرد عليك في أقرب وقت ممكن.', category: PhraseCategory.time),
  ];

  Future<List<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  Future<List<QuickPhrase>> getFavorites() async {
    final ids = await getFavoriteIds();
    return allPhrases.where((p) => ids.contains(p.id)).toList();
  }

  Future<bool> toggleFavorite(String phraseId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await getFavoriteIds();
    
    if (ids.contains(phraseId)) {
      ids.remove(phraseId);
    } else {
      if (ids.length >= _maxFavorites) return false;
      ids.add(phraseId);
    }
    
    await prefs.setStringList(_favoritesKey, ids);
    return true;
  }

  Future<bool> isFavorite(String phraseId) async {
    final ids = await getFavoriteIds();
    return ids.contains(phraseId);
  }
}
