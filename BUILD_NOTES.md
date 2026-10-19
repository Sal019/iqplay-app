# iQPlay — Flutter App Build Notes

A real Flutter recreation of Salman's iQPlay website. **No WebView, no HTML
files anywhere** — every screen is native Flutter widgets. Package:
`com.salman.iqplay`. Local verification done in the VM: `flutter analyze`
→ **No issues found**; `flutter build web --release` → succeeded (compile
smoke test). APK is built by GitHub Actions (`.github/workflows/build.yml`,
flutter-action → `flutter build apk --release`, artifact `app-release`).

## Structure

| File | Contents |
|---|---|
| `lib/main.dart` | Entry, root shell: status-bar style + `SafeArea` (content always BELOW the status bar), site header + bottom nav chrome on every screen, in-app page-stack routing |
| `lib/theme.dart` | Exact site palette (dark bg `#121314`, cards `#1a1a1a`, modal `#1b1d21`, text `#f9f9f9`, secondary `#ccc`, border `rgba(65,69,83,.38)`; light palette per site CSS) + 6 selectable accent gradients (default `#ee0979 → #ff6a00`) |
| `lib/tmdb.dart` | TMDB REST client + models (uses the SAME API key the website uses, extracted from the site's own config at runtime) |
| `lib/store.dart` | `AppState` (shared_preferences): theme `user_preferred_theme`, accent `user_preferred_style`, bookmarks `abefilm_bookmarks`, history `iqplay_history`, profile `iqplay_profile` {name, avatar base64}, server choice; `NavController` page stack |
| `lib/widgets.dart` | Header (iQPlay wordmark in accent gradient, search, bookmark button with count badge), bottom nav (Home · Movies · Series · Account), poster cards, section rows, gradient buttons |
| `lib/screens_home.dart` | Home (hero backdrop carousel + rows), category row (Home only), Movies/Series browse grids with genre chips, generic discover grid, TMDB search |
| `lib/screens_detail.dart` | Details (backdrop, poster, meta, genre chips, synopsis, season chips + episode list, cast, recommendations) and Player |
| `lib/screens_misc.dart` | Library (continue watching + bookmarks), Bookmarks, Account (editable local profile, avatar picker, 10-item menu, Clear Cache), Appearance (dark/light + accents), About / Privacy / Disclaimer pages |

## Screens (9, matching the site)
Home · Details · Player · Library · Bookmarks · Account · About Us ·
Privacy Policy · Disclaimer. Bottom nav and header on every screen;
the header category row (For You / Movies / Anime / Series / K-Drama /
C-Drama) appears ONLY on Home, exactly as Salman specified. Category taps
swap Home to the matching discover grid.

## TMDB endpoints used
`/trending/all/week`, `/movie/now_playing`, `/movie/popular`, `/tv/popular`,
`/movie/top_rated`, `/tv/top_rated`, `/tv/airing_today`, `/tv/on_the_air`,
`/discover/movie|tv` (genres, original-language ko/zh for K-/C-Drama),
`/genre/movie|tv/list`, `/search/multi`, `/movie|tv/{id}` with
`append_to_response=credits,recommendations,similar`, `/tv/{id}/season/{n}`.
Home rows: Trending, Now Playing, Popular Movies, Popular Series,
Top Rated Movies/Series, Airing Today, On The Air, Animation Movies/Series,
Korean Drama, C-Drama, Action, Romance, Horror, Crime, Sci-Fi.

## Player screen
Fully native recreation of the site's player page: 16:9 frame with the
backdrop, gradient play button and control-bar look; title/meta; **server
selection cards** for the site's six sources (Moviesapi, Vidsrc v2, VidLink,
Videasy, VidRock, Vidsrc — selection persisted, ACTIVE/SELECT states);
season chips + episode list for series (in-place episode switching);
synopsis, cast, recommendations. Opening the player records the title into
Library → Continue Watching. **No embed loading and no playback wiring** —
that piece is reserved for Salman to connect himself, per his instruction.

## Simplifications / notes
- The site's hero is an auto-advancing PageView of trending backdrops
  (5 s interval) rather than the template's JS slider — same look/behaviour.
- Home "Western Movies/Series" rows from the template config were folded
  into the genre rows to keep the home feed fast (16 rows already load).
- About text is the site's own About copy with the brand name set to
  iQPlay (the template text still said "Movie Box"); Privacy text is the
  site's verbatim text; the Disclaimer body is rendered by JS on the site,
  so a standard disclaimer matching the site's intent was written.
- Bookmarks use the site's own storage key name (`abefilm_bookmarks`) and
  profile the site's `iqplay_profile` shape, keeping parity with the web
  version's local-data model.
- App icon is Flutter's default launcher icon with the label "iQPlay";
  a custom icon can be dropped into `android/app/src/main/res` later.
