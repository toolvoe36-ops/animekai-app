import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/anime_model.dart';
import '../services/anime_service.dart';
import '../theme/app_theme.dart';
import '../widgets/anime_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AnimeService _animeService = AnimeService();
  List<AnimeItem> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  final List<String> _popularQueries = [
    'Jujutsu Kaisen',
    'One Piece',
    'Dragon Ball',
    'My Hero Academia',
    'Konosuba',
    'Attack on Titan',
    'Blue Lock',
    'Demon Slayer',
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    final results = await _animeService.searchAnime(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Search Anime Movies',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Box
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: (value) => _performSearch(value.trim()),
                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search movies e.g. Jujutsu Kaisen, One Piece...',
                  hintStyle: GoogleFonts.outfit(color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppTheme.primaryAccent),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: AppTheme.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Query Chips
            if (_searchController.text.isEmpty) ...[
              Text(
                'Popular Searches',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _popularQueries.map((query) {
                  return ActionChip(
                    label: Text(
                      query,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    backgroundColor: AppTheme.cardSurface,
                    side: const BorderSide(color: AppTheme.cardBorder),
                    onPressed: () {
                      _searchController.text = query;
                      _performSearch(query);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Search Results Body
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryAccent,
                      ),
                    )
                  : _searchResults.isEmpty && _searchController.text.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 64,
                                  color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'No movies found for "${_searchController.text}"',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            return AnimeCard(
                              anime: _searchResults[index],
                              width: double.infinity,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
