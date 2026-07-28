class AnimeItem {
  final String title;
  final String? jpTitle;
  final String slug; // e.g. "jujutsu-kaisen-0" or full URL
  final String posterUrl;
  final String? subEpCount;
  final String? dubEpCount;
  final String? type; // MOVIE, TV, etc.
  final String? releaseYear;
  final String? rating;

  AnimeItem({
    required this.title,
    this.jpTitle,
    required this.slug,
    required this.posterUrl,
    this.subEpCount,
    this.dubEpCount,
    this.type = 'MOVIE',
    this.releaseYear,
    this.rating,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'jpTitle': jpTitle,
        'slug': slug,
        'posterUrl': posterUrl,
        'subEpCount': subEpCount,
        'dubEpCount': dubEpCount,
        'type': type,
        'releaseYear': releaseYear,
        'rating': rating,
      };

  factory AnimeItem.fromJson(Map<String, dynamic> json) => AnimeItem(
        title: json['title'] ?? '',
        jpTitle: json['jpTitle'],
        slug: json['slug'] ?? '',
        posterUrl: json['posterUrl'] ?? '',
        subEpCount: json['subEpCount'],
        dubEpCount: json['dubEpCount'],
        type: json['type'] ?? 'MOVIE',
        releaseYear: json['releaseYear'],
        rating: json['rating'],
      );
}

class ServerSource {
  final String name; // e.g. "Server 1"
  final String streamUrl; // e.g. "https://megaplay.buzz/stream/mal/48561/1/sub"
  final String langType; // "sub" or "dub"

  ServerSource({
    required this.name,
    required this.streamUrl,
    required this.langType,
  });
}

class EpisodeItem {
  final String number;
  final String title;
  final String watchUrl;

  EpisodeItem({
    required this.number,
    required this.title,
    required this.watchUrl,
  });
}

class AnimeDetail {
  final String title;
  final String? jpTitle;
  final String posterUrl;
  final String backdropUrl;
  final String synopsis;
  final String? score;
  final String? reviewCount;
  final String? country;
  final List<String> genres;
  final String? premiered;
  final String? dateAired;
  final String? duration;
  final String? status;
  final String? studio;
  final List<ServerSource> servers;
  final List<EpisodeItem> episodes;

  AnimeDetail({
    required this.title,
    this.jpTitle,
    required this.posterUrl,
    required this.backdropUrl,
    required this.synopsis,
    this.score,
    this.reviewCount,
    this.country,
    required this.genres,
    this.premiered,
    this.dateAired,
    this.duration,
    this.status,
    this.studio,
    required this.servers,
    required this.episodes,
  });
}
