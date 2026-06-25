import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meeting/models/quick_phrase.dart';
import 'package:meeting/services/quick_phrase_service.dart';

class QuickPhraseSheet extends StatefulWidget {
  final Function(QuickPhrase) onPhraseSelected;

  const QuickPhraseSheet({
    super.key,
    required this.onPhraseSelected,
  });

  @override
  State<QuickPhraseSheet> createState() => _QuickPhraseSheetState();
}

class _QuickPhraseSheetState extends State<QuickPhraseSheet> with SingleTickerProviderStateMixin {
  final QuickPhraseService _service = QuickPhraseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<QuickPhrase> _favorites = [];
  String _searchQuery = '';
  PhraseCategory? _selectedCategory;
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadFavorites();
    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _service.getFavorites();
    if (mounted) {
      setState(() {
        _favorites = favorites;
      });
    }
  }

  List<QuickPhrase> get _filteredPhrases {
    final query = _searchQuery.trim().toLowerCase();
    return _service.allPhrases.where((p) {
      final matchesSearch = query.isEmpty || 
          p.text.toLowerCase().contains(query) || 
          p.preview.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == null || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 40, spreadRadius: 10),
        ],
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                if (_favorites.isNotEmpty && _searchQuery.isEmpty && _selectedCategory == null) ...[
                  _buildSectionTitle('المفضلة', Icons.star_rounded, Colors.orangeAccent),
                  _buildPhraseGrid(_favorites, isFavSection: true),
                  const SizedBox(height: 24),
                ],
                _buildSectionTitle(
                  _selectedCategory != null ? _getCategoryName(_selectedCategory!) : 'جميع الجمل',
                  Icons.grid_view_rounded,
                  const Color(0xFF3B82F6),
                ),
                _buildPhraseGrid(_filteredPhrases),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF0D2652).withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'جمل سريعة',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D2652),
              letterSpacing: 1,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF0D2652), size: 28),
            style: IconButton.styleFrom(backgroundColor: const Color(0xFF0D2652).withOpacity(0.05)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D2652).withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: _searchController,
          textAlign: TextAlign.right,
          style: const TextStyle(color: Color(0xFF0D2652), fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'ابحث عن جملة...',
            hintStyle: TextStyle(color: Color(0xFF0D2652).withOpacity(0.4)),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3B82F6)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: PhraseCategory.values.length + 1,
        itemBuilder: (context, index) {
          final category = index == 0 ? null : PhraseCategory.values[index - 1];
          final name = index == 0 ? 'الكل' : _getCategoryName(category!);
          return _buildCategoryChip(category, name, index);
        },
      ),
    );
  }

  Widget _buildCategoryChip(PhraseCategory? category, String name, int index) {
    final isSelected = _selectedCategory == category;
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _listController,
        curve: Interval(0.1 + (index * 0.05).clamp(0.0, 0.4), 0.6, curve: Curves.easeOut),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: FilterChip(
          selected: isSelected,
          label: Text(name),
          onSelected: (val) => setState(() => _selectedCategory = val ? category : null),
          backgroundColor: Color(0xFF0D2652).withOpacity(0.05),
          selectedColor: Color(0xFF3B82F6).withOpacity(0.1),
          checkmarkColor: const Color(0xFF3B82F6),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF3B82F6) : Color(0xFF0D2652).withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isSelected ? const Color(0xFF3B82F6) : Color(0xFF0D2652).withOpacity(0.1)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0D2652)),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: color, size: 22),
        ],
      ),
    );
  }

  Widget _buildPhraseGrid(List<QuickPhrase> phrases, {bool isFavSection = false}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: phrases.length,
      itemBuilder: (context, index) {
        final phrase = phrases[index];
        final isFav = _favorites.any((f) => f.id == phrase.id);

        return AnimatedBuilder(
          animation: _listController,
          builder: (context, child) {
            final delay = (index * 0.05).clamp(0.0, 0.5);
            final anim = CurvedAnimation(
              parent: _listController,
              curve: Interval(delay, delay + 0.4, curve: Curves.easeOutCubic),
            );
            return Transform.translate(
              offset: Offset(0, 30 * (1 - anim.value)),
              child: Opacity(opacity: anim.value, child: child),
            );
          },
          child: InkWell(
            onTap: () => widget.onPhraseSelected(phrase),
            onLongPress: () async {
              await _service.toggleFavorite(phrase.id);
              _loadFavorites();
              HapticFeedback.heavyImpact();
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Color(0xFF0D2652).withOpacity(0.1), width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Stack(
                children: [
                  if (isFav)
                    const Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 20),
                    ),
                  Center(
                    child: Text(
                      phrase.preview,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D2652),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getCategoryName(PhraseCategory category) {
    switch (category) {
      case PhraseCategory.confirmation: return 'تأكيد';
      case PhraseCategory.clarification: return 'توضيح';
      case PhraseCategory.questions: return 'أسئلة';
      case PhraseCategory.problems: return 'مشاكل';
      case PhraseCategory.politeness: return 'لطف';
      case PhraseCategory.time: return 'الوقت';
    }
  }
}
