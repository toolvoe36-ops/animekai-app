import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/anime_model.dart';

class AnimeService {
  static const String baseUrl = 'https://animekai.be';
  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Referer': 'https://animekai.be/',
    'X-Requested-With': 'XMLHttpRequest',
  };

  /// Fetch Featured Banners
  Future<List<AnimeItem>> fetchFeaturedAnime() async {
    final data = await fetchHomeScreenData();
    return data['featured'] ?? [];
  }

  /// Fetch Latest Anime Movies
  Future<List<AnimeItem>> fetchMovies({int page = 1}) async {
    return fetchMoviesByBrowse(page: page);
  }

  /// Fetch Anime Movies / Series By Genre
  Future<List<AnimeItem>> fetchByGenre(String genre, {int page = 1}) async {
    return fetchMoviesByBrowse(page: page, genre: genre);
  }

  /// Fetch HomeScreen Combined Data
  Future<Map<String, List<AnimeItem>>> fetchHomeScreenData() async {
    try {
      // 1. Featured items from /home
      List<AnimeItem> featured = [];
      final homeResponse = await http.get(Uri.parse('$baseUrl/home'), headers: _headers);
      if (homeResponse.statusCode == 200) {
        final document = html_parser.parse(homeResponse.body);
        final swiperSlides = document.querySelectorAll('.swiper-slide, .hero-slider .item, .featured-item');
        for (var slide in swiperSlides) {
          final titleElem = slide.querySelector('.title, .film-name, h2');
          final imgElem = slide.querySelector('img');
          final linkElem = slide.querySelector('a[href*="/watch/"]');

          if (titleElem != null && linkElem != null) {
            final title = titleElem.text.trim();
            final href = linkElem.attributes['href'] ?? '';
            final slug = href.replaceAll('$baseUrl/watch/', '').replaceAll('/watch/', '');
            final img = imgElem?.attributes['src'] ?? imgElem?.attributes['data-src'] ?? '';
            final type = slide.querySelector('.badge, .type')?.text.trim() ?? 'MOVIE';

            if (title.isNotEmpty && slug.isNotEmpty) {
              featured.add(AnimeItem(
                title: title,
                slug: slug,
                posterUrl: img,
                type: type,
                releaseYear: '2026',
              ));
            }
          }
        }
      }

      // 2. Movies list from /movie
      List<AnimeItem> latestMovies = await fetchMoviesByBrowse(page: 1);

      if (featured.isEmpty && latestMovies.isNotEmpty) {
        featured = latestMovies.take(5).toList();
      }

      return {
        'featured': featured,
        'latest': latestMovies,
      };
    } catch (e) {
      // Ignore
    }
    return {'featured': [], 'latest': []};
  }

  /// Fetch Anime Movies via /movie or /browse Page
  Future<List<AnimeItem>> fetchMoviesByBrowse({int page = 1, String? genre}) async {
    try {
      String url = '$baseUrl/movie?page=$page';
      if (genre != null && genre.isNotEmpty) {
        url = '$baseUrl/genres/$genre?page=$page';
      }

      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        List<AnimeItem> movies = [];

        final items = document.querySelectorAll('.aitem, .flw-item, .item, .col-6, .col-md-3');
        for (var item in items) {
          final link = item.querySelector('a[href*="/watch/"]');
          final titleElem = item.querySelector('.title, .film-name, h3, h2');
          final imgElem = item.querySelector('img');

          if (link != null && titleElem != null) {
            final href = link.attributes['href'] ?? '';
            final slug = href.replaceAll('$baseUrl/watch/', '').replaceAll('/watch/', '');
            final title = titleElem.text.trim();
            final img = imgElem?.attributes['src'] ?? imgElem?.attributes['data-src'] ?? '';
            final type = item.querySelector('.info span:last-child')?.text.trim() ?? 'MOVIE';

            if (slug.isNotEmpty && title.isNotEmpty) {
              movies.add(AnimeItem(
                title: title,
                slug: slug,
                posterUrl: img,
                type: type,
              ));
            }
          }
        }
        return movies;
      }
    } catch (e) {
      // Ignore
    }
    return [];
  }

  /// Search Anime Movies / Series
  Future<List<AnimeItem>> searchAnime(String keyword) async {
    try {
      final url = '$baseUrl/browse?keyword=${Uri.encodeComponent(keyword)}';
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        List<AnimeItem> results = [];

        final items = document.querySelectorAll('.aitem, .flw-item, .item, .col-6');
        for (var item in items) {
          final link = item.querySelector('a[href*="/watch/"]');
          final titleElem = item.querySelector('.title, .film-name, h3');
          final img = item.querySelector('img')?.attributes['src'] ?? '';

          if (link != null && titleElem != null) {
            final href = link.attributes['href'] ?? '';
            final slug = href.replaceAll('$baseUrl/watch/', '').replaceAll('/watch/', '');
            final title = titleElem.text.trim();

            if (slug.isNotEmpty && title.isNotEmpty) {
              results.add(AnimeItem(
                title: title,
                slug: slug,
                posterUrl: img,
                type: 'ANIME',
              ));
            }
          }
        }
        return results;
      }
    } catch (e) {
      // Ignore
    }
    return [];
  }

  /// Fetch Anime / Movie Detail Page & Parse ALL Episodes (1 to 1171+)
  Future<AnimeDetail?> fetchAnimeDetail(String slug) async {
    try {
      final cleanSlug = slug.replaceAll('$baseUrl/watch/', '').replaceAll('/watch/', '');
      final url = '$baseUrl/watch/$cleanSlug';
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);

        final title = document.querySelector('h1.title')?.text.trim() ??
            document.querySelector('.title')?.text.trim() ??
            'Anime Movie';
        final jpTitle = document.querySelector('.al-title')?.text.trim();

        // Poster image
        final posterImg = document.querySelector('.poster img')?.attributes['src'] ??
            document.querySelector('.poster-wrap .poster img')?.attributes['src'] ??
            '';

        // Backdrop image from style
        final bgElem = document.querySelector('.watch-section-bg, .player-bg');
        String backdropUrl = posterImg;
        if (bgElem != null) {
          final styleAttr = bgElem.attributes['style'] ?? '';
          final match = RegExp(r'url\((.*?)\)', caseSensitive: false).firstMatch(styleAttr);
          if (match != null && match.group(1) != null) {
            backdropUrl = match.group(1)!.replaceAll("'", "").replaceAll('"', '');
          }
        }

        // Synopsis
        final synopsis = document.querySelector('#synopsis-text')?.text.trim() ??
            document.querySelector('.desc')?.text.trim() ??
            'No description available.';

        // Score & reviews
        final score = document.querySelector('#rating-value')?.text.trim() ?? '9.5';
        final reviewCount = document.querySelector('#rating-count')?.text.trim() ?? 'Reviews';

        // Details metadata
        List<String> genres = [];
        final genreLinks = document.querySelectorAll('.detail a[href*="/genres/"]');
        for (var link in genreLinks) {
          genres.add(link.text.trim());
        }

        String? country;
        String? status;
        String? duration;
        String? premiered;
        String? dateAired;
        String? studio;

        final detailDivs = document.querySelectorAll('.detail div div');
        for (var div in detailDivs) {
          final text = div.text.trim();
          if (text.startsWith('Country:')) {
            country = text.replaceFirst('Country:', '').trim();
          } else if (text.startsWith('Status:')) {
            status = text.replaceFirst('Status:', '').trim();
          } else if (text.startsWith('Duration:')) {
            duration = text.replaceFirst('Duration:', '').trim();
          } else if (text.startsWith('Premiered:')) {
            premiered = text.replaceFirst('Premiered:', '').trim();
          } else if (text.startsWith('Date aired:')) {
            dateAired = text.replaceFirst('Date aired:', '').trim();
          } else if (text.startsWith('Studios:')) {
            studio = text.replaceFirst('Studios:', '').trim();
          }
        }

        // Stream Servers
        List<ServerSource> servers = [];
        final serverElements = document.querySelectorAll('.server-items .server');
        for (var s in serverElements) {
          final sName = s.text.trim();
          final sUrl = s.attributes['data-url'] ?? '';
          final parentLang = s.parent?.attributes['data-id'] ?? 'sub';

          if (sUrl.isNotEmpty) {
            servers.add(ServerSource(
              name: sName.isNotEmpty ? sName : 'Server 1',
              streamUrl: sUrl,
              langType: parentLang,
            ));
          }
        }

        // Deep Parse ALL Episode Items across range lists
        List<EpisodeItem> episodes = [];
        final Map<int, EpisodeItem> epMap = {};
        int maxEpNum = 1;

        // 1. Direct HTML Episode Links
        final epLinks = document.querySelectorAll('.eplist a, .range li a, a[href*="/ep-"], .episode-section a[num]');
        for (var ep in epLinks) {
          final numStr = ep.attributes['num'] ?? ep.text.trim();
          final epNum = int.tryParse(numStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
          final epTitle = ep.querySelector('span')?.text.trim() ?? 'Episode $epNum';
          var epWatchUrl = ep.attributes['href'] ?? '';
          if (epWatchUrl.isEmpty) {
            epWatchUrl = '/watch/$cleanSlug/ep-$epNum';
          }

          if (epNum > maxEpNum) maxEpNum = epNum;

          epMap[epNum] = EpisodeItem(
            number: epNum.toString(),
            title: epTitle,
            watchUrl: epWatchUrl,
          );
        }

        // 2. Range Dropdowns Detection (e.g., "1101-1171")
        final rangeItems = document.querySelectorAll('.range-options .item, [data-range]');
        for (var item in rangeItems) {
          final rangeStr = item.attributes['data-range'] ?? item.text.trim();
          if (rangeStr.contains('-')) {
            final parts = rangeStr.split('-');
            if (parts.length == 2) {
              final endNum = int.tryParse(parts[1].trim()) ?? 0;
              if (endNum > maxEpNum) {
                maxEpNum = endNum;
              }
            }
          }
        }

        // 3. Complete Episode Generator up to maxEpNum
        for (int i = 1; i <= maxEpNum; i++) {
          if (epMap.containsKey(i)) {
            episodes.add(epMap[i]!);
          } else {
            episodes.add(EpisodeItem(
              number: i.toString(),
              title: 'Episode $i',
              watchUrl: '/watch/$cleanSlug/ep-$i',
            ));
          }
        }

        return AnimeDetail(
          title: title,
          jpTitle: jpTitle,
          posterUrl: posterImg,
          backdropUrl: backdropUrl.isNotEmpty ? backdropUrl : posterImg,
          synopsis: synopsis,
          score: score,
          reviewCount: reviewCount,
          country: country,
          genres: genres.isNotEmpty ? genres : ['Anime', 'Series'],
          premiered: premiered,
          dateAired: dateAired,
          duration: duration,
          status: status,
          studio: studio,
          servers: servers,
          episodes: episodes,
        );
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }
}
