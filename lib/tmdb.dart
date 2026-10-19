import 'dart:convert';
import 'package:http/http.dart' as http;

/// TMDB access — same API key the iQPlay website itself uses, so the app
/// shows identical catalog data (posters, ratings, metadata).
class Tmdb {
  static const String apiKey = '<redacted>';
  static const String base = 'https://api.themoviedb.org/3';
  static const String img500 = 'https://image.tmdb.org/t/p/w500';
  static const String img780 = 'https://image.tmdb.org/t/p/w780';
  static const String img185 = 'https://image.tmdb.org/t/p/w185';
  static const String img300 = 'https://image.tmdb.org/t/p/w300';

  static Future<dynamic> _get(String path,
      {Map<String, String>? params}) async {
    final query = <String, String>{'api_key': apiKey, ...?params};
    final uri = Uri.parse('$base$path').replace(queryParameters: query);
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('TMDB ${res.statusCode} for $path');
    }
    return jsonDecode(res.body);
  }

  static Future<List<MediaItem>> list(String path,
      {Map<String, String>? params, String? forcedType}) async {
    final data = await _get(path, params: params);
    final results = (data['results'] as List?) ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map((j) => MediaItem.fromJson(j, forcedType: forcedType))
        .where((m) => m.posterPath != null && m.title.isNotEmpty)
        .toList();
  }

  static Future<List<MediaItem>> trending() =>
      list('/trending/all/week');
  static Future<List<MediaItem>> nowPlaying() =>
      list('/movie/now_playing', forcedType: 'movie');
  static Future<List<MediaItem>> popularMovies() =>
      list('/movie/popular', forcedType: 'movie');
  static Future<List<MediaItem>> popularSeries() =>
      list('/tv/popular', forcedType: 'tv');
  static Future<List<MediaItem>> topRatedMovies() =>
      list('/movie/top_rated', forcedType: 'movie');
  static Future<List<MediaItem>> topRatedSeries() =>
      list('/tv/top_rated', forcedType: 'tv');
  static Future<List<MediaItem>> airingToday() =>
      list('/tv/airing_today', forcedType: 'tv');
  static Future<List<MediaItem>> onTheAir() =>
      list('/tv/on_the_air', forcedType: 'tv');

  static Future<List<MediaItem>> discover(
    String type, {
    int? genreId,
    String? language,
    int page = 1,
    String sortBy = 'popularity.desc',
  }) {
    final params = <String, String>{
      'page': '$page',
      'sort_by': sortBy,
    };
    if (genreId != null) params['with_genres'] = '$genreId';
    if (language != null) params['with_original_language'] = language;
    return list('/discover/$type', params: params, forcedType: type);
  }

  static Future<List<MediaItem>> searchMulti(String query) =>
      list('/search/multi', params: {'query': query});

  static Future<Map<String, dynamic>> details(MediaItem item) async {
    final data = await _get('/${item.type}/${item.id}', params: {
      'append_to_response': 'credits,recommendations,similar',
    });
    return data as Map<String, dynamic>;
  }

  static Future<List<Episode>> seasonEpisodes(int tvId, int season) async {
    final data = await _get('/tv/$tvId/season/$season');
    final eps = (data['episodes'] as List?) ?? const [];
    return eps.whereType<Map<String, dynamic>>().map(Episode.fromJson).toList();
  }

  static Future<List<Genre>> genres(String type) async {
    final data = await _get('/genre/$type/list');
    final gs = (data['genres'] as List?) ?? const [];
    return gs
        .whereType<Map<String, dynamic>>()
        .map((j) => Genre(j['id'] as int, j['name'] as String))
        .toList();
  }
}

class Genre {
  final int id;
  final String name;
  const Genre(this.id, this.name);
}

class MediaItem {
  final int id;
  final String type; // 'movie' or 'tv'
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final double rating;
  final String year;
  final String overview;

  const MediaItem({
    required this.id,
    required this.type,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.rating = 0,
    this.year = '',
    this.overview = '',
  });

  factory MediaItem.fromJson(Map<String, dynamic> j, {String? forcedType}) {
    final type = forcedType ?? (j['media_type'] as String?) ?? 'movie';
    final dateStr =
        (j['release_date'] as String?) ?? (j['first_air_date'] as String?) ?? '';
    return MediaItem(
      id: j['id'] as int,
      type: type == 'tv' ? 'tv' : 'movie',
      title: (j['title'] as String?) ?? (j['name'] as String?) ?? '',
      posterPath: j['poster_path'] as String?,
      backdropPath: j['backdrop_path'] as String?,
      rating: (j['vote_average'] as num?)?.toDouble() ?? 0,
      year: dateStr.length >= 4 ? dateStr.substring(0, 4) : '',
      overview: (j['overview'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'posterPath': posterPath,
        'backdropPath': backdropPath,
        'rating': rating,
        'year': year,
        'overview': overview,
      };

  factory MediaItem.fromStore(Map<String, dynamic> j) => MediaItem(
        id: j['id'] as int,
        type: j['type'] as String,
        title: j['title'] as String,
        posterPath: j['posterPath'] as String?,
        backdropPath: j['backdropPath'] as String?,
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        year: (j['year'] as String?) ?? '',
        overview: (j['overview'] as String?) ?? '',
      );

  String get posterUrl =>
      posterPath != null ? '${Tmdb.img500}$posterPath' : '';
  String get backdropUrl =>
      backdropPath != null ? '${Tmdb.img780}$backdropPath' : posterUrl;

  @override
  bool operator ==(Object other) =>
      other is MediaItem && other.id == id && other.type == type;
  @override
  int get hashCode => Object.hash(id, type);
}

class Episode {
  final int number;
  final String name;
  final String? stillPath;
  final String overview;
  final double rating;
  const Episode({
    required this.number,
    required this.name,
    this.stillPath,
    this.overview = '',
    this.rating = 0,
  });
  factory Episode.fromJson(Map<String, dynamic> j) => Episode(
        number: (j['episode_number'] as num?)?.toInt() ?? 0,
        name: (j['name'] as String?) ?? '',
        stillPath: j['still_path'] as String?,
        overview: (j['overview'] as String?) ?? '',
        rating: (j['vote_average'] as num?)?.toDouble() ?? 0,
      );
}

class CastMember {
  final String name;
  final String character;
  final String? profilePath;
  const CastMember(this.name, this.character, this.profilePath);
  String get profileUrl =>
      profilePath != null ? '${Tmdb.img185}$profilePath' : '';
}

List<CastMember> parseCast(Map<String, dynamic> details) {
  final cast = (details['credits']?['cast'] as List?) ?? const [];
  return cast
      .whereType<Map<String, dynamic>>()
      .take(15)
      .map((j) => CastMember(
            (j['name'] as String?) ?? '',
            (j['character'] as String?) ?? '',
            j['profile_path'] as String?,
          ))
      .toList();
}

List<MediaItem> parseRecommendations(
    Map<String, dynamic> details, String type) {
  final rec = details['recommendations']?['results'] as List?;
  final sim = details['similar']?['results'] as List?;
  final src = (rec != null && rec.isNotEmpty) ? rec : (sim ?? const []);
  return src
      .whereType<Map<String, dynamic>>()
      .map((j) => MediaItem.fromJson(j, forcedType: type))
      .where((m) => m.posterPath != null)
      .toList();
}
