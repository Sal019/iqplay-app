import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';
import 'screens_home.dart';
import 'screens_detail.dart';
import 'screens_misc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  runApp(IQPlayApp(state: state));
}

class IQPlayApp extends StatefulWidget {
  final AppState state;
  const IQPlayApp({super.key, required this.state});

  @override
  State<IQPlayApp> createState() => _IQPlayAppState();
}

class _IQPlayAppState extends State<IQPlayApp> {
  final NavController nav = NavController();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.state, nav]),
      builder: (context, _) {
        final state = widget.state;
        final p = state.palette;
        return AppScope(
          state: state,
          nav: nav,
          child: MaterialApp(
            title: 'iQPlay',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(p, state.accent),
            home: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                // Status bar stays visible (dark strip); app content is
                // laid out BELOW it via SafeArea in the shell — content is
                // never drawn under the status bar.
                statusBarColor: p.background,
                statusBarIconBrightness:
                    p.dark ? Brightness.light : Brightness.dark,
                statusBarBrightness:
                    p.dark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: p.sidebar,
                systemNavigationBarIconBrightness:
                    p.dark ? Brightness.light : Brightness.dark,
              ),
              child: PopScope(
                canPop: nav.stack.length <= 1,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) nav.pop();
                },
                child: const RootShell(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final nav = scope.nav;
    final state = scope.state;
    final page = nav.top;
    final showCategories = page is TabPage && page.tab == 0;
    return Scaffold(
      backgroundColor: state.palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(),
            if (showCategories) const HomeCategoryRow(),
            Expanded(child: _bodyFor(page)),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  Widget _bodyFor(AppPage page) {
    return switch (page) {
      TabPage(tab: 0) => const HomeScreen(),
      TabPage(tab: 1) => const BrowseScreen(type: 'movie'),
      TabPage(tab: 2) => const BrowseScreen(type: 'tv'),
      TabPage(tab: 3) => const AccountScreen(),
      TabPage() => const HomeScreen(),
      DetailsPage() => DetailsScreen(item: page.item),
      PlayerPage() => PlayerScreen(
          item: page.item, season: page.season, episode: page.episode),
      SearchPage() => const SearchScreen(),
      BookmarksPage() => const BookmarksScreen(),
      LibraryPage() => const LibraryScreen(),
      AppearancePage() => const AppearanceScreen(),
      StaticPage() => StaticTextScreen(kind: page.kind),
      GridPage() => GridScreen(
          title: page.title,
          type: page.type,
          genreId: page.genreId,
          language: page.language),
    };
  }
}
