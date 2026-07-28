import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/anime_model.dart';
import '../services/anime_service.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final AnimeItem anime;

  const MovieDetailScreen({super.key, required this.anime});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final AnimeService _animeService = AnimeService();
  AnimeDetail? _detail;
  bool _isLoading = true;
  bool _isFavorite = false;
  int _selectedServerIndex = 0;

  // Episode Range & Search Filter State
  String _selectedRange = 'All';
  String _epSearchQuery = '';
  final TextEditingController _epSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _checkFavorite();
  }

  @override
  void dispose() {
    _epSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final detail = await _animeService.fetchAnimeDetail(widget.anime.slug);
    if (mounted) {
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorites') ?? [];
    setState(() {
      _isFavorite = favList.any((item) {
        final decoded = json.decode(item);
        return decoded['slug'] == widget.anime.slug;
      });
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favList = prefs.getStringList('favorites') ?? [];

    if (_isFavorite) {
      favList.removeWhere((item) {
        final decoded = json.decode(item);
        return decoded['slug'] == widget.anime.slug;
      });
    } else {
      favList.add(json.encode(widget.anime.toJson()));
    }

    await prefs.setStringList('favorites', favList);
    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite
              ? 'Added to your Watchlist!'
              : 'Removed from Watchlist'),
          backgroundColor: AppTheme.primaryAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _startWatching([String? customUrl]) {
    final targetWatchUrl = customUrl ?? 'https://animekai.be/watch/${widget.anime.slug}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(
          title: _detail?.title ?? widget.anime.title,
          watchUrl: targetWatchUrl,
          servers: _detail?.servers ?? [],
          selectedServerIndex: _selectedServerIndex,
        ),
      ),
    );
  }

  List<String> _getEpisodeRanges(int totalEpisodes) {
    if (totalEpisodes <= 100) return ['All'];
    List<String> ranges = ['All'];
    for (int i = 1; i <= totalEpisodes; i += 100) {
      int end = (i + 99) > totalEpisodes ? totalEpisodes : (i + 99);
      String rangeStr = '${i.toString().padLeft(3, '0')}-${end.toString().padLeft(3, '0')}';
      ranges.add(rangeStr);
    }
    return ranges;
  }

  List<EpisodeItem> _getFilteredEpisodes() {
    if (_detail == null || _detail!.episodes.isEmpty) return [];
    var list = _detail!.episodes;

    // Filter by Search Query
    if (_epSearchQuery.trim().isNotEmpty) {
      final q = _epSearchQuery.trim().toLowerCase();
      list = list.where((ep) {
        return ep.number.contains(q) || ep.title.toLowerCase().contains(q);
      }).toList();
    }

    // Filter by Selected Range
    if (_selectedRange != 'All') {
      final parts = _selectedRange.split('-');
      if (parts.length == 2) {
        int start = int.tryParse(parts[0]) ?? 1;
        int end = int.tryParse(parts[1]) ?? 100;
        list = list.where((ep) {
          int num = int.tryParse(ep.number) ?? 0;
          return num >= start && num <= end;
        }).toList();
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final allEpisodes = _detail?.episodes ?? [];
    final filteredEpisodes = _getFilteredEpisodes();
    final ranges = _getEpisodeRanges(allEpisodes.length);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Hero Header SliverAppBar
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppTheme.background,
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.bookmark_added : Icons.bookmark_border,
                  color: _isFavorite ? AppTheme.primaryAccent : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      _detail?.backdropUrl ?? widget.anime.posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[900],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            AppTheme.background.withValues(alpha: 0.7),
                            AppTheme.background,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Poster Image
                        Container(
                          width: 100,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.cardBorder, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            widget.anime.posterUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title & Rating
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _detail?.title ?? widget.anime.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (_detail?.jpTitle != null)
                                Text(
                                  _detail!.jpTitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: AppTheme.secondaryAccent,
                                      size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    _detail?.score ?? '9.7',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.secondaryAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryAccent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.anime.type ?? 'MOVIE',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details Body
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryAccent),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Watch Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => _startWatching(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                            icon: const Icon(Icons.play_circle_fill_rounded,
                                size: 24),
                            label: Text(
                              'WATCH AD-FREE NOW',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Genre Tags
                        if (_detail?.genres.isNotEmpty == true) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _detail!.genres.map((genre) {
                              return Chip(
                                label: Text(
                                  genre,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                backgroundColor: AppTheme.cardSurface,
                                side: const BorderSide(
                                    color: AppTheme.cardBorder),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Synopsis Section
                        Text(
                          'Synopsis',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _detail?.synopsis ?? 'No synopsis available.',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Movie Info Metadata Table
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Column(
                            children: [
                              _infoRow('Status', _detail?.status ?? 'Completed'),
                              const Divider(color: AppTheme.cardBorder),
                              _infoRow('Duration', _detail?.duration ?? 'N/A'),
                              const Divider(color: AppTheme.cardBorder),
                              _infoRow(
                                  'Premiered', _detail?.premiered ?? 'N/A'),
                              const Divider(color: AppTheme.cardBorder),
                              _infoRow('Studio', _detail?.studio ?? 'MAPPA'),
                              const Divider(color: AppTheme.cardBorder),
                              _infoRow('Country', _detail?.country ?? 'Japan'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Available Episodes / Parts Grid
                        if (allEpisodes.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Episodes / Parts',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${allEpisodes.length} Episodes Total',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppTheme.primaryAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Search / Find Episode Input
                          Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.cardSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: TextField(
                              controller: _epSearchController,
                              onChanged: (val) {
                                setState(() {
                                  _epSearchQuery = val;
                                });
                              },
                              style: GoogleFonts.outfit(
                                  color: AppTheme.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Find Episode Number (e.g. 1080)...',
                                hintStyle: GoogleFonts.outfit(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                                prefixIcon: const Icon(Icons.search_rounded,
                                    size: 18, color: AppTheme.textSecondary),
                                suffixIcon: _epSearchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            size: 16,
                                            color: AppTheme.textSecondary),
                                        onPressed: () {
                                          _epSearchController.clear();
                                          setState(() {
                                            _epSearchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Range Chips Selector (001-100, 101-200, etc.)
                          if (ranges.length > 1)
                            SizedBox(
                              height: 38,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: ranges.length,
                                itemBuilder: (context, index) {
                                  final r = ranges[index];
                                  final isSel = r == _selectedRange;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: ChoiceChip(
                                      label: Text(
                                        r,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: isSel
                                              ? Colors.white
                                              : AppTheme.textSecondary,
                                          fontWeight: isSel
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      selected: isSel,
                                      selectedColor: AppTheme.primaryAccent,
                                      backgroundColor: AppTheme.cardSurface,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _selectedRange = r;
                                          });
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 12),

                          // Filtered Episodes Grid
                          filteredEpisodes.isNotEmpty
                              ? GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    childAspectRatio: 2.2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: filteredEpisodes.length,
                                  itemBuilder: (context, index) {
                                    final ep = filteredEpisodes[index];
                                    return InkWell(
                                      onTap: () {
                                        final epUrl = ep.watchUrl.startsWith('http')
                                            ? ep.watchUrl
                                            : 'https://animekai.be${ep.watchUrl}';
                                        _startWatching(epUrl);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.cardSurface,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: AppTheme.cardBorder),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'EP ${ep.number}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      'No episodes found for "$_epSearchQuery".',
                                      style: GoogleFonts.outfit(
                                          color: AppTheme.textSecondary),
                                    ),
                                  ),
                                ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
