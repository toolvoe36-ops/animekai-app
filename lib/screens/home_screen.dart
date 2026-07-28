import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/anime_model.dart';
import '../services/anime_service.dart';
import '../theme/app_theme.dart';
import '../widgets/anime_card.dart';
import '../widgets/featured_banner.dart';
import 'browse_screen.dart';
import 'search_screen.dart';
import 'watchlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MovieDashboardTab(),
    const BrowseScreen(),
    const SearchScreen(),
    const WatchlistScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          border: const Border(
            top: BorderSide(color: AppTheme.cardBorder, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryAccent,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.outfit(
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.movie_rounded),
              label: 'Movies',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_rounded),
              label: 'Browse',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_rounded),
              label: 'Watchlist',
            ),
          ],
        ),
      ),
    );
  }
}

class MovieDashboardTab extends StatefulWidget {
  const MovieDashboardTab({super.key});

  @override
  State<MovieDashboardTab> createState() => _MovieDashboardTabState();
}

class _MovieDashboardTabState extends State<MovieDashboardTab> {
  final AnimeService _animeService = AnimeService();
  List<AnimeItem> _featuredList = [];
  List<AnimeItem> _moviesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    final featuredFuture = _animeService.fetchFeaturedAnime();
    final moviesFuture = _animeService.fetchMovies();

    final results = await Future.wait([featuredFuture, moviesFuture]);
    final featured = results[0];
    final movies = results[1];

    if (mounted) {
      setState(() {
        _featuredList = featured;
        _moviesList = movies;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.play_circle_fill_rounded,
                color: AppTheme.primaryAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'AnimeKai Movies',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchDashboardData,
          ),
        ],
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: AppTheme.primaryAccent,
        backgroundColor: AppTheme.cardSurface,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryAccent,
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Featured Movie Swiper Banner
                    if (_featuredList.isNotEmpty) ...[
                      SizedBox(
                        height: 240,
                        child: PageView.builder(
                          itemCount: _featuredList.length,
                          itemBuilder: (context, index) {
                            return FeaturedBanner(anime: _featuredList[index]);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Section Title: Trending Anime Movies
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Popular Anime Movies',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'From animekai.be',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.primaryAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Movies Grid
                    if (_moviesList.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _moviesList.length,
                        itemBuilder: (context, index) {
                          return AnimeCard(
                            anime: _moviesList[index],
                            width: double.infinity,
                          );
                        },
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'No movies available right now.',
                            style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}
