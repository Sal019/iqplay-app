import 'package:flutter/material.dart';
import 'store.dart';
import 'tmdb.dart';
import 'widgets.dart';

class DetailsScreen extends StatefulWidget {
  final MediaItem item;
  const DetailsScreen({super.key, required this.item});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late final Future<Map<String, dynamic>> _future = Tmdb.details(widget.item);
  int _season = 1;
  Future<List<Episode>>? _episodes;

  void _loadEpisodes(int season) {
    _episodes = Tmdb.seasonEpisodes(widget.item.id, season);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final p = state.palette;
    final item = widget.item;
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        final d = snap.data;
        final genres = <String>[
          if (d != null)
            ...((d['genres'] as List?) ?? const [])
                .whereType<Map<String, dynamic>>()
                .map((g) => g['name'] as String),
        ];
        final runtime = d?['runtime'] as int?;
        final seasonsCount = (d?['number_of_seasons'] as int?) ?? 0;
        final seasons = <int>[
          if (d != null)
            ...((d['seasons'] as List?) ?? const [])
                .whereType<Map<String, dynamic>>()
                .map((s) => (s['season_number'] as num).toInt())
                .where((n) => n > 0),
        ];
        if (item.type == 'tv' && seasons.isNotEmpty && _episodes == null) {
          _season = seasons.first;
          _loadEpisodes(_season);
        }
        final cast = d != null ? parseCast(d) : const <CastMember>[];
        final recs = d != null
            ? parseRecommendations(d, item.type)
            : const <MediaItem>[];
        final bookmarked = state.isBookmarked(item);
        return ListView(
          children: [
            // Backdrop header
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: netImage(item.backdropUrl),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          p.background.withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 4,
                  top: 4,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => scope.nav.pop(),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -34),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: netImage(item.posterUrl, width: 96, height: 144),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                                color: p.textStrong,
                                fontSize: 19,
                                fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 14, color: Color(0xFFFFC107)),
                              const SizedBox(width: 3),
                              Text(item.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                      color: p.text,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(width: 10),
                              Text(
                                [
                                  item.year,
                                  if (runtime != null) '${runtime}m',
                                  if (item.type == 'tv' && seasonsCount > 0)
                                    '$seasonsCount Season${seasonsCount > 1 ? 's' : ''}',
                                ].where((s) => s.isNotEmpty).join(' · '),
                                style: TextStyle(color: p.secondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: Row(
                children: [
                  GradientButton(
                    'Play',
                    icon: Icons.play_arrow,
                    onTap: () => scope.nav.push(PlayerPage(item,
                        season: item.type == 'tv' ? _season : null,
                        episode: item.type == 'tv' ? 1 : null)),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await state.toggleBookmark(item);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(bookmarked
                              ? 'Removed from Watchlist'
                              : 'Added to Watchlist'),
                          duration: const Duration(seconds: 1),
                        ));
                      }
                    },
                    icon: Icon(
                        bookmarked ? Icons.bookmark : Icons.bookmark_border,
                        size: 18),
                    label: const Text('My List'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.text,
                      side: BorderSide(color: p.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                    ),
                  ),
                ],
              ),
            ),
            if (genres.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final g in genres)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.border),
                        ),
                        child: Text(g,
                            style:
                                TextStyle(color: p.secondary, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            const SectionTitle('Synopsis'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                item.overview.isEmpty
                    ? 'No synopsis available.'
                    : item.overview,
                style: TextStyle(color: p.secondary, height: 1.5),
              ),
            ),
            if (item.type == 'tv' && seasons.isNotEmpty) ...[
              const SectionTitle('Episodes'),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: seasons.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final s = seasons[i];
                    final active = s == _season;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _season = s;
                        _loadEpisodes(s);
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient:
                              active ? state.accent.gradient : null,
                          color: active ? null : p.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: p.border),
                        ),
                        child: Text('Season $s',
                            style: TextStyle(
                                color: active ? Colors.white : p.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              if (_episodes != null)
                FutureBuilder<List<Episode>>(
                  future: _episodes,
                  builder: (context, esnap) {
                    if (!esnap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(18),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return Column(
                      children: [
                        for (final ep in esnap.data!)
                          EpisodeTile(item: item, season: _season, ep: ep),
                      ],
                    );
                  },
                ),
            ],
            if (cast.isNotEmpty) ...[
              const SectionTitle('Cast'),
              SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: cast.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _CastTile(cast[i]),
                ),
              ),
            ],
            if (recs.isNotEmpty)
              SectionRow('Recommendations',
                  Future.value(recs)),
            const SizedBox(height: 26),
          ],
        );
      },
    );
  }
}

class EpisodeTile extends StatelessWidget {
  final MediaItem item;
  final int season;
  final Episode ep;
  final bool playing;
  final VoidCallback? onSelect;
  const EpisodeTile({
    super.key,
    required this.item,
    required this.season,
    required this.ep,
    this.playing = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final p = state.palette;
    return GestureDetector(
      onTap: onSelect ??
          () => scope.nav
              .push(PlayerPage(item, season: season, episode: ep.number)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: playing ? state.accent.primary : p.border,
              width: playing ? 1.4 : 1),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: ep.stillPath != null
                  ? netImage('${Tmdb.img300}${ep.stillPath}',
                      width: 104, height: 60)
                  : netImage(item.backdropUrl, width: 104, height: 60),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'E${ep.number} · ${ep.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: p.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    playing
                        ? 'Now Playing'
                        : (ep.overview.isEmpty
                            ? 'Episode ${ep.number}'
                            : ep.overview),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: playing
                            ? state.accent.primary
                            : p.secondary,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(playing ? Icons.equalizer : Icons.play_circle_outline,
                color: playing ? state.accent.primary : p.secondary,
                size: 26),
          ],
        ),
      ),
    );
  }
}

class _CastTile extends StatelessWidget {
  final CastMember member;
  const _CastTile(this.member);
  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).state.palette;
    return SizedBox(
      width: 74,
      child: Column(
        children: [
          ClipOval(
            child: netImage(member.profileUrl, width: 62, height: 62),
          ),
          const SizedBox(height: 6),
          Text(
            member.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text, fontSize: 11.5),
          ),
          Text(
            member.character,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.secondary, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

/// Player screen — fully native UI mirroring the site's player page:
/// player frame (backdrop + play overlay + control bar look), title/meta,
/// server selection, season/episode picker for series, synopsis, cast,
/// recommendations. Stream playback wiring is intentionally left to be
/// connected later (Salman's reserved piece) — no embeds, no WebView.
class PlayerScreen extends StatefulWidget {
  final MediaItem item;
  final int? season;
  final int? episode;
  const PlayerScreen({super.key, required this.item, this.season, this.episode});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late int _season = widget.season ?? 1;
  late int _episode = widget.episode ?? 1;
  late final Future<Map<String, dynamic>> _future =
      Tmdb.details(widget.item);
  Future<List<Episode>>? _episodes;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.type == 'tv') {
      _episodes = Tmdb.seasonEpisodes(widget.item.id, _season);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_recorded) {
      _recorded = true;
      final state = AppScope.of(context).state;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.addHistory(widget.item,
            season: widget.item.type == 'tv' ? _season : null,
            episode: widget.item.type == 'tv' ? _episode : null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final p = state.palette;
    final item = widget.item;
    return ListView(
      children: [
        // ---- Player frame (native recreation of the site's player look)
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              netImage(item.backdropUrl),
              Container(color: Colors.black.withValues(alpha: 0.45)),
              Center(
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: state.accent.gradient,
                    boxShadow: [
                      BoxShadow(
                        color: state.accent.primary.withValues(alpha: 0.5),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 38),
                ),
              ),
              Positioned(
                left: 10,
                top: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => scope.nav.pop(),
                ),
              ),
              // control-bar look: progress + icons
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 3,
                      color: Colors.white24,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: 0.22,
                        child: Container(
                          decoration:
                              BoxDecoration(gradient: state.accent.gradient),
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: const Row(
                        children: [
                          Icon(Icons.play_arrow,
                              color: Colors.white, size: 20),
                          SizedBox(width: 14),
                          Icon(Icons.volume_up,
                              color: Colors.white, size: 19),
                          SizedBox(width: 14),
                          Text('00:00 / 00:00',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                          Spacer(),
                          Icon(Icons.settings_outlined,
                              color: Colors.white, size: 19),
                          SizedBox(width: 14),
                          Icon(Icons.fullscreen,
                              color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ---- Title / meta
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.type == 'tv'
                    ? '${item.title} — Season $_season Episode $_episode'
                    : item.title,
                style: TextStyle(
                    color: p.textStrong,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                  const SizedBox(width: 3),
                  Text(item.rating.toStringAsFixed(1),
                      style: TextStyle(color: p.text)),
                  const SizedBox(width: 10),
                  Text(
                    '${item.year} · ${item.type == 'tv' ? 'Series' : 'Movie'} · ${state.server}',
                    style: TextStyle(color: p.secondary),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                        state.isBookmarked(item)
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: p.text),
                    onPressed: () => state.toggleBookmark(item),
                  ),
                ],
              ),
            ],
          ),
        ),
        // ---- Server selection
        const SectionTitle('Select Server'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              for (final s in AppState.kServers)
                GestureDetector(
                  onTap: () => state.setServer(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: state.server == s
                            ? state.accent.primary
                            : p.border,
                        width: state.server == s ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.dns_outlined,
                            size: 18,
                            color: state.server == s
                                ? state.accent.primary
                                : p.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: p.text,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: state.server == s
                                ? state.accent.gradient
                                : null,
                            color: state.server == s ? null : p.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            state.server == s ? 'ACTIVE' : 'SELECT',
                            style: TextStyle(
                              color: state.server == s
                                  ? Colors.white
                                  : p.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // ---- Episodes (series)
        if (item.type == 'tv')
          FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snap) {
              final seasons = <int>[
                if (snap.data != null)
                  ...((snap.data!['seasons'] as List?) ?? const [])
                      .whereType<Map<String, dynamic>>()
                      .map((s) => (s['season_number'] as num).toInt())
                      .where((n) => n > 0),
              ];
              if (seasons.isEmpty) return const SizedBox.shrink();
              if (!seasons.contains(_season)) {
                // keep the requested season even if list is still loading
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Episodes'),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: seasons.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final s = seasons[i];
                        final active = s == _season;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _season = s;
                            _episode = 1;
                            _episodes =
                                Tmdb.seasonEpisodes(item.id, s);
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient:
                                  active ? state.accent.gradient : null,
                              color: active ? null : p.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: p.border),
                            ),
                            child: Text('Season $s',
                                style: TextStyle(
                                    color: active ? Colors.white : p.text,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_episodes != null)
                    FutureBuilder<List<Episode>>(
                      future: _episodes,
                      builder: (context, esnap) {
                        if (!esnap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child:
                                Center(child: CircularProgressIndicator()),
                          );
                        }
                        return Column(
                          children: [
                            for (final ep in esnap.data!)
                              EpisodeTile(
                                item: item,
                                season: _season,
                                ep: ep,
                                playing: ep.number == _episode,
                                onSelect: () {
                                  setState(() => _episode = ep.number);
                                  state.addHistory(item,
                                      season: _season, episode: ep.number);
                                },
                              ),
                          ],
                        );
                      },
                    ),
                ],
              );
            },
          ),
        // ---- Synopsis / cast / recommendations
        const SectionTitle('Synopsis'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            item.overview.isEmpty
                ? 'No synopsis available.'
                : item.overview,
            style: TextStyle(color: p.secondary, height: 1.5),
          ),
        ),
        FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final cast = parseCast(snap.data!);
            final recs = parseRecommendations(snap.data!, item.type);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cast.isNotEmpty) ...[
                  const SectionTitle('Cast'),
                  SizedBox(
                    height: 118,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: cast.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _CastTile(cast[i]),
                    ),
                  ),
                ],
                if (recs.isNotEmpty)
                  SectionRow('Recommendations', Future.value(recs)),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
      ],
    );
  }
}
