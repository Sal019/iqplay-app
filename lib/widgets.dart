import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'store.dart';

import 'tmdb.dart';

Widget netImage(String url,
    {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (url.isEmpty) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF23242A),
      child: const Icon(Icons.movie_outlined, color: Colors.white24),
    );
  }
  return CachedNetworkImage(
    imageUrl: url,
    width: width,
    height: height,
    fit: fit,
    placeholder: (c, u) => Container(
      width: width,
      height: height,
      color: const Color(0xFF23242A),
    ),
    errorWidget: (c, u, e) => Container(
      width: width,
      height: height,
      color: const Color(0xFF23242A),
      child: const Icon(Icons.broken_image_outlined, color: Colors.white24),
    ),
  );
}

/// Top header — present on every screen, like the site: wordmark, search,
/// watchlist/bookmark button (with count badge).
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final p = state.palette;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: p.background,
        border: Border(bottom: BorderSide(color: p.border, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => scope.nav.goTab(0),
            child: ShaderMask(
              shaderCallback: (r) => state.accent.gradient.createShader(r),
              child: const Text(
                'iQPlay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.search, color: p.text, size: 24),
            onPressed: () => scope.nav.push(SearchPage()),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.bookmark_border, color: p.text, size: 24),
                onPressed: () => scope.nav.push(BookmarksPage()),
              ),
              if (state.bookmarks.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      gradient: state.accent.gradient,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${state.bookmarks.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom navigation — Home · Movies · Series · Account on every screen.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final p = state.palette;
    final current = scope.nav.currentTab;
    final items = <(IconData, IconData, String)>[
      (Icons.home_outlined, Icons.home, 'Home'),
      (Icons.movie_outlined, Icons.movie, 'Movies'),
      (Icons.tv_outlined, Icons.tv, 'Series'),
      (Icons.person_outline, Icons.person, 'Account'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: p.sidebar,
        border: Border(top: BorderSide(color: p.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => scope.nav.goTab(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          current == i ? items[i].$2 : items[i].$1,
                          size: 24,
                          color: current == i
                              ? state.accent.primary
                              : p.secondary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].$3,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: current == i
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: current == i
                                ? state.accent.primary
                                : p.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Portrait poster card used in the horizontal rows (site style: poster,
/// rating pill, title, year/type line).
class PosterCard extends StatelessWidget {
  final MediaItem item;
  final double width;
  const PosterCard(this.item, {super.key, this.width = 116});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final p = scope.state.palette;
    final ratingPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 10, color: Color(0xFFFFC107)),
          const SizedBox(width: 2),
          Text(
            item.rating.toStringAsFixed(1),
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    final poster = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          netImage(item.posterUrl),
          Positioned(left: 5, top: 5, child: ratingPill),
        ],
      ),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(aspectRatio: 2 / 3, child: poster),
        const SizedBox(height: 6),
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: p.text, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        Text(
          '${item.year} · ${item.type == 'tv' ? 'Series' : 'Movie'}',
          style: TextStyle(color: p.secondary, fontSize: 11),
        ),
      ],
    );
    return GestureDetector(
      onTap: () => scope.nav.push(DetailsPage(item)),
      child: width.isInfinite
          ? content
          : SizedBox(width: width, child: content),
    );
  }
}

/// A titled horizontal poster row with a "See All" affordance, like the
/// site's home sections.
class SectionRow extends StatelessWidget {
  final String title;
  final Future<List<MediaItem>> future;
  final VoidCallback? onSeeAll;
  const SectionRow(this.title, this.future, {super.key, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).state.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                    color: p.textStrong,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text('See All',
                      style: TextStyle(
                          color: p.secondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 224,
          child: FutureBuilder<List<MediaItem>>(
            future: future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              if (!snap.hasData || snap.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              final items = snap.data!;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => PosterCard(items[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const GradientButton(this.label,
      {super.key, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = AppScope.of(context).state.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          gradient: accent.gradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).state.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
      child: Text(
        text,
        style: TextStyle(
            color: p.textStrong, fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}
