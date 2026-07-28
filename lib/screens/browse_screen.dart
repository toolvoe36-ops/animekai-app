import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/anime_model.dart';
import '../services/anime_service.dart';
import '../theme/app_theme.dart';
import '../widgets/anime_card.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final AnimeService _animeService = AnimeService();
  String _selectedGenre = 'action';
  List<AnimeItem> _genreMovies = [];
  bool _isLoading = true;

  final Map<String, String> _genres = {
    'action': 'Action ⚔️',
    'adventure': 'Adventure 🗺️',
    'comedy': 'Comedy 😂',
    'drama': 'Drama 🎭',
    'fantasy': 'Fantasy 🧙',
    'horror': 'Horror 👻',
    'isekai': 'Isekai 🌀',
    'romance': 'Romance ❤️',
    'sci-fi': 'Sci-Fi 🚀',
    'shounen': 'Shounen 🔥',
    'supernatural': 'Supernatural 🔮',
    'suspense': 'Suspense 🕵️',
  };

  @override
  void initState() {
    super.initState();
    _loadGenreMovies(_selectedGenre);
  }

  Future<void> _loadGenreMovies(String genreSlug) async {
    setState(() {
      _selectedGenre = genreSlug;
      _isLoading = true;
    });

    final movies = await _animeService.fetchByGenre(genreSlug);
    if (mounted) {
      setState(() {
        _genreMovies = movies;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Browse Genres',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horizontal Genre Filter Chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _genres.length,
              itemBuilder: (context, index) {
                final key = _genres.keys.elementAt(index);
                final label = _genres[key]!;
                final isSelected = key == _selectedGenre;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      label,
                      style: GoogleFonts.outfit(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryAccent,
                    backgroundColor: AppTheme.cardSurface,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryAccent
                          : AppTheme.cardBorder,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        _loadGenreMovies(key);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Genre Title Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '${_genres[_selectedGenre]} Movies',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Genre Movies Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryAccent,
                    ),
                  )
                : _genreMovies.isEmpty
                    ? Center(
                        child: Text(
                          'No movies found for this genre.',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _genreMovies.length,
                        itemBuilder: (context, index) {
                          return AnimeCard(
                            anime: _genreMovies[index],
                            width: double.infinity,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
