import 'package:driftfin/jellyfin/jellyfin_open_api.enums.swagger.dart';

/// The structured Jellyfin query translated from a free-text "Ask Driftfin"
/// search, e.g. "cozy slow-burn mysteries under 2 hours I haven't seen".
class NaturalLanguageQuery {
  final List<String> genres;
  final Duration? maxRuntime;
  final bool unseenOnly;
  final bool favoritesOnly;
  final String? searchTerm;

  const NaturalLanguageQuery({
    this.genres = const [],
    this.maxRuntime,
    this.unseenOnly = false,
    this.favoritesOnly = false,
    this.searchTerm,
  });

  List<ItemFilter> get filters => [
        if (unseenOnly) ItemFilter.isunplayed,
      ];

  bool get hasStructuredSignal =>
      genres.isNotEmpty || maxRuntime != null || unseenOnly || favoritesOnly || (searchTerm?.isNotEmpty ?? false);
}

/// Translates a free-text mood/natural-language query into a structured
/// Jellyfin query, entirely client-side (no external NLP service). This is
/// what upgrades `search_provider.dart` from a single `searchTerm`-only
/// `itemsGet` call into something that understands mood, runtime budgets
/// and "haven't seen" style constraints.
class NaturalLanguageQueryParser {
  const NaturalLanguageQueryParser._();

  static const Map<String, List<String>> _moodGenres = {
    'cozy': ['Family', 'Romance', 'Drama'],
    'wholesome': ['Family', 'Comedy'],
    'feel-good': ['Family', 'Comedy'],
    'uplifting': ['Family', 'Adventure'],
    'thrilling': ['Thriller', 'Action'],
    'thriller': ['Thriller'],
    'thrillers': ['Thriller'],
    'scary': ['Horror'],
    'horror': ['Horror'],
    'funny': ['Comedy'],
    'comedy': ['Comedy'],
    'comedies': ['Comedy'],
    'mystery': ['Mystery'],
    'mysteries': ['Mystery'],
    'romantic': ['Romance'],
    'romance': ['Romance'],
    'action': ['Action'],
    'animated': ['Animation'],
    'animation': ['Animation'],
    'documentary': ['Documentary'],
    'documentaries': ['Documentary'],
    'sci-fi': ['Science Fiction'],
    'scifi': ['Science Fiction'],
    'fantasy': ['Fantasy'],
    'crime': ['Crime'],
    'war': ['War'],
    'musical': ['Music'],
    'family': ['Family'],
    'kids': ['Family'],
    'gritty': ['Crime', 'Drama'],
    'slow-burn': [],
    'slow': [],
  };

  static final RegExp _runtimeHours = RegExp(r'(?:under|less than|within)\s+(\d+(?:\.\d+)?)\s*hours?');
  static final RegExp _runtimeMinutes = RegExp(r'(?:under|less than|within)\s+(\d+)\s*(?:minutes|mins?)');
  static final RegExp _wordSplit = RegExp(r"[a-z0-9'-]+");

  static const List<String> _unseenPhrases = [
    "haven't seen",
    'havent seen',
    'never seen',
    'not seen',
    'unwatched',
    'new to me',
  ];

  static const Set<String> _stopWords = {
    'a',
    'an',
    'the',
    'i',
    'me',
    'my',
    'that',
    'this',
    'to',
    'of',
    'for',
    'and',
    'or',
    'in',
    'on',
    'with',
    'is',
    'are',
    'movie',
    'movies',
    'show',
    'shows',
    'something',
    'watch',
    'tonight',
  };

  static NaturalLanguageQuery parse(String rawQuery) {
    final lower = rawQuery.toLowerCase();

    Duration? maxRuntime;
    final hoursMatch = _runtimeHours.firstMatch(lower);
    if (hoursMatch != null) {
      final hours = double.tryParse(hoursMatch.group(1) ?? '');
      if (hours != null) maxRuntime = Duration(minutes: (hours * 60).round());
    } else {
      final minutesMatch = _runtimeMinutes.firstMatch(lower);
      if (minutesMatch != null) {
        final minutes = int.tryParse(minutesMatch.group(1) ?? '');
        if (minutes != null) maxRuntime = Duration(minutes: minutes);
      }
    }

    final unseenOnly = _unseenPhrases.any(lower.contains);
    final favoritesOnly = lower.contains('favorite') || lower.contains('favourite');

    var remaining = lower.replaceAll(_runtimeHours, ' ').replaceAll(_runtimeMinutes, ' ');
    for (final phrase in _unseenPhrases) {
      remaining = remaining.replaceAll(phrase, ' ');
    }
    remaining = remaining
        .replaceAll('favorites', ' ')
        .replaceAll('favourites', ' ')
        .replaceAll('favorite', ' ')
        .replaceAll('favourite', ' ');

    final words = _wordSplit.allMatches(remaining).map((m) => m.group(0)!).toList();

    final genres = <String>{};
    final leftoverWords = <String>[];
    for (final word in words) {
      final mapped = _moodGenres[word];
      if (mapped != null) {
        genres.addAll(mapped);
      } else if (!_stopWords.contains(word)) {
        leftoverWords.add(word);
      }
    }

    return NaturalLanguageQuery(
      genres: genres.toList(),
      maxRuntime: maxRuntime,
      unseenOnly: unseenOnly,
      favoritesOnly: favoritesOnly,
      searchTerm: leftoverWords.isNotEmpty ? leftoverWords.join(' ') : null,
    );
  }
}
