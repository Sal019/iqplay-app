import 'dart:async';
import 'package:flutter/material.dart';
import 'store.dart';
import 'tmdb.dart';
import 'widgets.dart';

const List<String> kHomeCategories = [
  'For You',
  'Movies',
  'Anime',
  'Series',
  'K-Drama',
  'C-Drama',
];

/// Category row under the header — shown ONLY on Home (site rule).
class HomeCategoryRow extends StatelessWidget {
  const HomeCategoryRow({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final p = state.palette;
    final selected = scope.nav.homeCategory;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.border, width: 0.5)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        itemCount: kHomeCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => scope.nav.setHomeCategory(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                gradient: active ? state.accent.gradient : null,
                color: active ? null : p.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.border),
              ),
              child: Text(
                kHomeCategories[i],
                style: TextStyle(
                  color: active ? Colors.white : p.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Futures are cached so rebuilds (theme/nav notifications) don't refetch.
  late final Map<String, Future<List<MediaItem>>> _rows = {
    'trending': Tmdb.trending(),
    'nowPlaying': Tmdb.nowPlaying(),
    'popularMovies': Tmdb.popularMovies(),
    'popularSeries': Tmdb.popularSeries(),
    'topMovies': Tmdb.topRatedMovies(),
    'topSeries': Tmdb.topRatedSeries(),
    'airing': Tmdb.airingToday(),
    'onAir': Tmdb.onTheAir(),
    'animMovies': Tmdb.discover('movie', genreId: 16),
    'animSeries': Tmdb.discover('tv', genreId: 16),
    'kdrama': Tmdb.discover('tv', language: 'ko', sortBy: 'vote_average.desc'),
    'cdrama': Tmdb.discover('tv', language: 'zh', sortBy: 'vote_average.desc'),
    'action': Tmdb.discover('movie', genreId: 28),
    'romance': Tmdb.discover('movie', genreId: 10749),
    'horror': Tmdb.discover('movie', genreId: 27),
    'crime': Tmdb.discover('movie', genreId: 80),
    'scifi': Tmdb.discover('movie', genreId: 878),
  };

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return switch (scope.nav.homeCategory) {
      1 => const GridScreen(title: 'Movies', type: 'movie', embedded: true),
      2 => const GridScreen(
          title: 'Anime', type: 'tv', genreId: 16, embedded: true),
      3 => const GridScreen(title: 'Series', type: 'tv', embedded: true),
      4 => const GridScreen(
          title: 'K-Drama', type: 'tv', language: 'ko', embedded: true),
      5 => const GridScreen(
          title: 'C-Drama', type: 'tv', language: 'zh', embedded: true),
      _ => _forYou(context),
    };
  }

  Widget _forYou(BuildContext context) {
    final scope = AppScope.of(context);
    return ListView(
      children: [
        _HeroCarousel(future: _rows['trending']!),
        SectionRow('Trending This Week', _rows['trending']!),
        SectionRow('Now Playing', _rows['nowPlaying']!,
            onSeeAll: () => scope.nav.push(
                GridPage('Now Playing Movies', 'movie'))),
        SectionRow('Popular Movies', _rows['popularMovies']!,
            onSeeAll: () =>
                scope.nav.push(GridPage('Popular Movies', 'movie'))),
        SectionRow('Popular Series', _rows['popularSeries']!,
            onSeeAll: () =>
                scope.nav.push(GridPage('Popular Series', 'tv'))),
        SectionRow('Top Rated Movies', _rows['topMovies']!),
        SectionRow('Top Rated Series', _rows['topSeries']!),
        SectionRow('Airing Today', _rows['airing']!),
        SectionRow('On The Air', _rows['onAir']!),
        SectionRow('Animation Movies', _rows['animMovies']!,
            onSeeAll: () => scope.nav
                .push(GridPage('Animation Movies', 'movie', genreId: 16))),
        SectionRow('Animation Series', _rows['animSeries']!,
            onSeeAll: () => scope.nav
                .push(GridPage('Animation Series', 'tv', genreId: 16))),
        SectionRow('Korean Drama', _rows['kdrama']!,
            onSeeAll: () => scope.nav
                .push(GridPage('Korean Drama', 'tv', language: 'ko'))),
        SectionRow('C-Drama', _rows['cdrama']!,
            onSeeAll: () => scope.nav
                .push(GridPage('C-Drama', 'tv', language: 'zh'))),
        SectionRow('Action', _rows['action']!,
            onSeeAll: () =>
                scope.nav.push(GridPage('Action Movies', 'movie', genreId: 28))),
        SectionRow('Romance', _rows['romance']!),
        SectionRow('Horror', _rows['horror']!),
        SectionRow('Crime', _rows['crime']!),
        SectionRow('Sci-Fi', _rows['scifi']!),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Auto-scrolling backdrop hero, like the site's home slider.
class _HeroCarousel extends StatefulWidget {
  final Future<List<MediaItem>> future;
  const _HeroCarousel({required this.future});
  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAuto(int count) {
    _timer?.cancel();
    if (count < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % count;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return FutureBuilder<List<MediaItem>>(
      future: widget.future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 210,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final items =
            snap.data!.where((m) => m.backdropPath != null).take(8).toList();
        if (items.isEmpty) return const SizedBox.shrink();
        if (_timer == null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _startAuto(items.length));
        }
        return SizedBox(
          height: 216,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final m = items[i];
                  return GestureDetector(
                    onTap: () => scope.nav.push(DetailsPage(m)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        netImage(m.backdropUrl),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.88),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 13, color: Color(0xFFFFC107)),
                                  const SizedBox(width: 3),
                                  Text(
                                    m.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${m.year} · ${m.type == 'tv' ? 'Series' : 'Movie'}',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                right: 12,
                bottom: 10,
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Container(
                        width: i == _page ? 16 : 6,
                        height: 6,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: i == _page
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Discover grid used by the Movies/Series tabs, home categories,
/// genre rows and the account menu shortcuts.
class GridScreen extends StatefulWidget {
  final String title;
  final String type;
  final int? genreId;
  final String? language;
  final bool embedded;
  const GridScreen({
    super.key,
    required this.title,
    required this.type,
    this.genreId,
    this.language,
    this.embedded = false,
  });

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  late Future<List<MediaItem>> _future;
  int? _genreId;

  @override
  void initState() {
    super.initState();
    _genreId = widget.genreId;
    _load();
  }

  void _load() {
    _future = Tmdb.discover(widget.type,
        genreId: _genreId, language: widget.language);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final p = scope.state.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded)
          _SubHeader(title: widget.title)
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Text(
              widget.title,
              style: TextStyle(
                  color: p.textStrong,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
            ),
          ),
        GenreChips(
          type: widget.type,
          selected: _genreId,
          onSelect: (id) => setState(() {
            _genreId = id;
            _load();
          }),
        ),
        Expanded(
          child: FutureBuilder<List<MediaItem>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || snap.data!.isEmpty) {
                return Center(
                  child: Text('Nothing found',
                      style: TextStyle(color: p.secondary)),
                );
              }
              return PosterGrid(items: snap.data!);
            },
          ),
        ),
      ],
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String title;
  const _SubHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final p = scope.state.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 14, 2),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: p.text),
            onPressed: () => scope.nav.pop(),
          ),
          Text(
            title,
            style: TextStyle(
                color: p.textStrong,
                fontSize: 17,
                fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class GenreChips extends StatefulWidget {
  final String type;
  final int? selected;
  final ValueChanged<int?> onSelect;
  const GenreChips(
      {super.key,
      required this.type,
      required this.selected,
      required this.onSelect});

  @override
  State<GenreChips> createState() => _GenreChipsState();
}

class _GenreChipsState extends State<GenreChips> {
  late final Future<List<Genre>> _genres = Tmdb.genres(widget.type);

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final p = state.palette;
    return FutureBuilder<List<Genre>>(
      future: _genres,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(height: 44);
        final genres = snap.data!;
        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            itemCount: genres.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final id = i == 0 ? null : genres[i - 1].id;
              final label = i == 0 ? 'All' : genres[i - 1].name;
              final active = widget.selected == id;
              return GestureDetector(
                onTap: () => widget.onSelect(id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: active ? state.accent.gradient : null,
                    color: active ? null : p.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.border),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active ? Colors.white : p.text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class PosterGrid extends StatelessWidget {
  final List<MediaItem> items;
  const PosterGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.52,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => PosterCard(items[i], width: double.infinity),
    );
  }
}

/// Movies / Series bottom-nav tabs.
class BrowseScreen extends StatelessWidget {
  final String type;
  const BrowseScreen({super.key, required this.type});
  @override
  Widget build(BuildContext context) {
    return GridScreen(
      title: type == 'movie' ? 'Movies' : 'Series',
      type: type,
      embedded: true,
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Future<List<MediaItem>>? _future;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _future = q.trim().isEmpty ? null : Tmdb.searchMulti(q.trim());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final p = scope.state.palette;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 14, 6),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: p.text),
                onPressed: () => scope.nav.pop(),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onChanged,
                  style: TextStyle(color: p.text, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search movies, series, anime...',
                    hintStyle: TextStyle(color: p.secondary),
                    prefixIcon: Icon(Icons.search, color: p.secondary),
                    filled: true,
                    fillColor: p.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: p.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: p.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _future == null
              ? Center(
                  child: Text('Search TMDB for any title',
                      style: TextStyle(color: p.secondary)),
                )
              : FutureBuilder<List<MediaItem>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = (snap.data ?? [])
                        .where((m) => m.posterPath != null)
                        .toList();
                    if (items.isEmpty) {
                      return Center(
                        child: Text('No results',
                            style: TextStyle(color: p.secondary)),
                      );
                    }
                    return PosterGrid(items: items);
                  },
                ),
        ),
      ],
    );
  }
}
