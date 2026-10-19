import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tmdb.dart';
import 'theme.dart';

class HistoryEntry {
  final MediaItem item;
  final int? season;
  final int? episode;
  final int watchedAt;
  const HistoryEntry(this.item, {this.season, this.episode, required this.watchedAt});

  Map<String, dynamic> toJson() => {
        'item': item.toJson(),
        'season': season,
        'episode': episode,
        'watchedAt': watchedAt,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        MediaItem.fromStore(j['item'] as Map<String, dynamic>),
        season: j['season'] as int?,
        episode: j['episode'] as int?,
        watchedAt: (j['watchedAt'] as num?)?.toInt() ?? 0,
      );

  String get label {
    if (item.type == 'tv' && season != null && episode != null) {
      return 'S$season · E$episode';
    }
    return item.type == 'tv' ? 'Series' : 'Movie';
  }
}

class Profile {
  final String name;
  final String? avatarBase64;
  const Profile({this.name = 'Guest', this.avatarBase64});
}

/// All persistent app state: theme/accent prefs (same keys the website used),
/// bookmarks, continue-watching history and the local profile.
class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

  bool dark = true;
  int accentIndex = 0;
  List<MediaItem> bookmarks = [];
  List<HistoryEntry> history = [];
  Profile profile = const Profile();
  String server = 'Moviesapi';

  static const List<String> kServers = [
    'Moviesapi',
    'Vidsrc v2',
    'VidLink',
    'Videasy',
    'VidRock',
    'Vidsrc',
  ];

  AppPalette get palette =>
      dark ? AppPalette.darkPalette : AppPalette.lightPalette;
  AccentStyle get accent => kAccentStyles[
      accentIndex.clamp(0, kAccentStyles.length - 1)];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    dark = (p.getString('user_preferred_theme') ?? 'dark') != 'light';
    final styleName = p.getString('user_preferred_style');
    if (styleName != null) {
      final i = kAccentStyles.indexWhere((s) => s.name == styleName);
      if (i >= 0) accentIndex = i;
    }
    server = p.getString('iqplay_server') ?? 'Moviesapi';
    bookmarks = _decodeItems(p.getString('abefilm_bookmarks'));
    history = _decodeHistory(p.getString('iqplay_history'));
    final profRaw = p.getString('iqplay_profile');
    if (profRaw != null) {
      try {
        final j = jsonDecode(profRaw) as Map<String, dynamic>;
        profile = Profile(
          name: (j['name'] as String?) ?? 'Guest',
          avatarBase64: j['avatar'] as String?,
        );
      } catch (_) {}
    }
    notifyListeners();
  }

  List<MediaItem> _decodeItems(String? raw) {
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(MediaItem.fromStore)
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<HistoryEntry> _decodeHistory(String? raw) {
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(HistoryEntry.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(String key, Object value) async {
    await _prefs?.setString(key, jsonEncode(value));
  }

  Future<void> setTheme(bool darkMode) async {
    dark = darkMode;
    await _prefs?.setString(
        'user_preferred_theme', darkMode ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setAccent(int index) async {
    accentIndex = index;
    await _prefs?.setString(
        'user_preferred_style', kAccentStyles[index].name);
    notifyListeners();
  }

  Future<void> setServer(String name) async {
    server = name;
    await _prefs?.setString('iqplay_server', name);
    notifyListeners();
  }

  bool isBookmarked(MediaItem item) => bookmarks.contains(item);

  Future<void> toggleBookmark(MediaItem item) async {
    if (bookmarks.contains(item)) {
      bookmarks.remove(item);
    } else {
      bookmarks.insert(0, item);
    }
    await _save(
        'abefilm_bookmarks', bookmarks.map((b) => b.toJson()).toList());
    notifyListeners();
  }

  Future<void> removeBookmark(MediaItem item) async {
    bookmarks.remove(item);
    await _save(
        'abefilm_bookmarks', bookmarks.map((b) => b.toJson()).toList());
    notifyListeners();
  }

  Future<void> addHistory(MediaItem item, {int? season, int? episode}) async {
    history.removeWhere((h) => h.item == item);
    history.insert(
      0,
      HistoryEntry(item,
          season: season,
          episode: episode,
          watchedAt: DateTime.now().millisecondsSinceEpoch),
    );
    if (history.length > 30) history = history.sublist(0, 30);
    await _save('iqplay_history', history.map((h) => h.toJson()).toList());
    notifyListeners();
  }

  Future<void> removeHistory(MediaItem item) async {
    history.removeWhere((h) => h.item == item);
    await _save('iqplay_history', history.map((h) => h.toJson()).toList());
    notifyListeners();
  }

  Future<void> setProfile(String name, String? avatarBase64) async {
    profile = Profile(name: name, avatarBase64: avatarBase64);
    await _prefs?.setString(
        'iqplay_profile',
        jsonEncode({'name': name, 'avatar': avatarBase64}));
    notifyListeners();
  }
}

/// Inherited access to [AppState] + [NavController].
class AppScope extends InheritedWidget {
  final AppState state;
  final NavController nav;
  const AppScope({
    super.key,
    required this.state,
    required this.nav,
    required super.child,
  });

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      state != oldWidget.state || nav != oldWidget.nav;
}

// ---------- Navigation (simple in-app stack so every screen keeps the
// site's header + bottom nav chrome) ----------

sealed class AppPage {}

class TabPage extends AppPage {
  final int tab; // 0 Home, 1 Movies, 2 Series, 3 Account
  TabPage(this.tab);
}

class DetailsPage extends AppPage {
  final MediaItem item;
  DetailsPage(this.item);
}

class PlayerPage extends AppPage {
  final MediaItem item;
  final int? season;
  final int? episode;
  PlayerPage(this.item, {this.season, this.episode});
}

class SearchPage extends AppPage {}

class BookmarksPage extends AppPage {}

class LibraryPage extends AppPage {}

class AppearancePage extends AppPage {}

class StaticPage extends AppPage {
  final String kind; // about | privacy | disclaimer
  StaticPage(this.kind);
}

class GridPage extends AppPage {
  final String title;
  final String type; // movie | tv
  final int? genreId;
  final String? language;
  GridPage(this.title, this.type, {this.genreId, this.language});
}

class NavController extends ChangeNotifier {
  List<AppPage> stack = [TabPage(0)];
  int homeCategory = 0; // index into home category row

  AppPage get top => stack.last;
  int get currentTab {
    for (final p in stack.reversed) {
      if (p is TabPage) return p.tab;
    }
    return 0;
  }

  void goTab(int tab) {
    stack = [TabPage(tab)];
    notifyListeners();
  }

  void push(AppPage page) {
    stack = [...stack, page];
    notifyListeners();
  }

  bool pop() {
    if (stack.length <= 1) return false;
    stack = stack.sublist(0, stack.length - 1);
    notifyListeners();
    return true;
  }

  void setHomeCategory(int i) {
    homeCategory = i;
    notifyListeners();
  }
}
