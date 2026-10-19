import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'store.dart';
import 'theme.dart';
import 'tmdb.dart';
import 'widgets.dart';

/// Wide list row used on the Bookmarks and Library pages (the site's
/// bookmark-item look: poster thumb, title, meta, trash button).
class MediaListTile extends StatelessWidget {
  final MediaItem item;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const MediaListTile({
    super.key,
    required this.item,
    this.subtitle,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).state.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: netImage(item.posterUrl, width: 52, height: 76),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: p.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 12, color: Color(0xFFFFC107)),
                      const SizedBox(width: 3),
                      Text(
                        '${item.rating.toStringAsFixed(1)} · ${item.year} · ${subtitle ?? (item.type == 'tv' ? 'Series' : 'Movie')}',
                        style: TextStyle(color: p.secondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Color(0xFFE57373), size: 22),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  final String title;
  const _BackHeader(this.title);
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final p = scope.state.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 14, 6),
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

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final p = state.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BackHeader('Bookmarks'),
        Expanded(
          child: state.bookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_border,
                          size: 52, color: p.secondary),
                      const SizedBox(height: 10),
                      Text('No bookmarks yet.',
                          style: TextStyle(color: p.secondary)),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    for (final item in state.bookmarks)
                      MediaListTile(
                        item: item,
                        onTap: () => scope.nav.push(DetailsPage(item)),
                        onRemove: () => state.removeBookmark(item),
                      ),
                    const SizedBox(height: 14),
                  ],
                ),
        ),
      ],
    );
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final p = state.palette;
    return ListView(
      children: [
        const _BackHeader('Library'),
        const SectionTitle('Continue Watching'),
        if (state.history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('Nothing here yet — titles you open will appear here.',
                style: TextStyle(color: p.secondary)),
          )
        else
          for (final h in state.history)
            MediaListTile(
              item: h.item,
              subtitle: h.label,
              onTap: () => scope.nav.push(PlayerPage(h.item,
                  season: h.season, episode: h.episode)),
              onRemove: () => state.removeHistory(h.item),
            ),
        const SectionTitle('My Bookmarks'),
        if (state.bookmarks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('No bookmarks yet.',
                style: TextStyle(color: p.secondary)),
          )
        else
          for (final item in state.bookmarks.take(5))
            MediaListTile(
              item: item,
              onTap: () => scope.nav.push(DetailsPage(item)),
              onRemove: () => state.removeBookmark(item),
            ),
        if (state.bookmarks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
            child: GradientButton(
              'View All Bookmarks',
              icon: Icons.bookmark,
              onTap: () => scope.nav.push(BookmarksPage()),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _pickAvatar(BuildContext context, AppState state) async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await state.setProfile(state.profile.name, base64Encode(bytes));
  }

  Future<void> _editName(BuildContext context, AppState state) async {
    final controller = TextEditingController(text: state.profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await state.setProfile(name, state.profile.avatarBase64);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final p = state.palette;
    final profile = state.profile;
    final menu = <(IconData, String, VoidCallback)>[
      (Icons.home_outlined, 'Home', () => scope.nav.goTab(0)),
      (Icons.movie_outlined, 'Movies', () => scope.nav.goTab(1)),
      (Icons.tv_outlined, 'TV Series', () => scope.nav.goTab(2)),
      (Icons.animation_outlined, 'Animation',
          () => scope.nav.push(GridPage('Animation', 'tv', genreId: 16))),
      (Icons.video_library_outlined, 'Library',
          () => scope.nav.push(LibraryPage())),
      (Icons.bookmark_border, 'Bookmarks',
          () => scope.nav.push(BookmarksPage())),
      (Icons.palette_outlined, 'Appearance',
          () => scope.nav.push(AppearancePage())),
      (Icons.privacy_tip_outlined, 'Privacy Policy',
          () => scope.nav.push(StaticPage('privacy'))),
      (Icons.description_outlined, 'Disclaimer',
          () => scope.nav.push(StaticPage('disclaimer'))),
      (Icons.info_outline, 'About Us',
          () => scope.nav.push(StaticPage('about'))),
    ];
    return ListView(
      children: [
        // Profile card (like the site's Account page header)
        Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _pickAvatar(context, state),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: p.background,
                      backgroundImage: profile.avatarBase64 != null
                          ? MemoryImage(base64Decode(profile.avatarBase64!))
                          : null,
                      child: profile.avatarBase64 == null
                          ? Icon(Icons.person, size: 34, color: p.secondary)
                          : null,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: state.accent.gradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: p.textStrong,
                                fontSize: 18,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: p.secondary),
                          onPressed: () => _editName(context, state),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    Text('Local profile — saved on this device only',
                        style: TextStyle(color: p.secondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Menu
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < menu.length; i++) ...[
                ListTile(
                  leading: Icon(menu[i].$1, color: p.text, size: 22),
                  title: Text(menu[i].$2,
                      style: TextStyle(color: p.text, fontSize: 14.5)),
                  trailing:
                      Icon(Icons.chevron_right, color: p.secondary, size: 20),
                  onTap: menu[i].$3,
                ),
                if (i < menu.length - 1)
                  Divider(height: 1, indent: 56, color: p.border),
              ],
            ],
          ),
        ),
        // Clear cache footer (the site's account-page footer action)
        Padding(
          padding: const EdgeInsets.all(14),
          child: OutlinedButton.icon(
            onPressed: () async {
              await DefaultCacheManager().emptyCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Cache cleared!'),
                      duration: Duration(seconds: 1)),
                );
              }
            },
            icon: const Icon(Icons.cleaning_services_outlined, size: 18),
            label: const Text('Clear Cache'),
            style: OutlinedButton.styleFrom(
              foregroundColor: p.text,
              side: BorderSide(color: p.border),
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ),
        Center(
          child: Text('iQPlay v1.0',
              style: TextStyle(color: p.secondary, fontSize: 12)),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final p = state.palette;
    return ListView(
      children: [
        const _BackHeader('Appearance'),
        const SectionTitle('Theme Mode'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              for (final darkMode in [true, false])
                Expanded(
                  child: GestureDetector(
                    onTap: () => state.setTheme(darkMode),
                    child: Container(
                      margin: EdgeInsets.only(right: darkMode ? 10 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: darkMode
                            ? const Color(0xFF121314)
                            : const Color(0xFFFDFDFD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: state.dark == darkMode
                              ? state.accent.primary
                              : p.border,
                          width: state.dark == darkMode ? 1.6 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            darkMode
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                            color: darkMode ? Colors.white : Colors.black87,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            darkMode ? 'Dark' : 'Light',
                            style: TextStyle(
                              color: darkMode ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SectionTitle('Accent Style'),
        for (var i = 0; i < kAccentStyles.length; i++)
          GestureDetector(
            onTap: () => state.setAccent(i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.accentIndex == i
                      ? state.accent.primary
                      : p.border,
                  width: state.accentIndex == i ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: kAccentStyles[i].gradient,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(kAccentStyles[i].name,
                      style: TextStyle(color: p.text, fontSize: 14.5)),
                  const Spacer(),
                  if (state.accentIndex == i)
                    Icon(Icons.check_circle,
                        color: state.accent.primary, size: 21),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class StaticTextScreen extends StatelessWidget {
  final String kind;
  const StaticTextScreen({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).state.palette;
    final (title, body) = switch (kind) {
      'privacy' => ('Privacy Policy', kPrivacyText),
      'disclaimer' => ('Disclaimer', kDisclaimerText),
      _ => ('About Us', kAboutText),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackHeader(title),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Text(
              body,
              style: TextStyle(color: p.secondary, fontSize: 14, height: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

const String kAboutText =
    '''Welcome to iQPlay, your go-to destination for curated movies, series, and premium entertainment content from around the world.

At iQPlay, we are passionate about storytelling in all its forms — whether it's the heart-fluttering romance of K-dramas, the thrilling plot twists of C-dramas, the rich animation of anime, or the cinematic excellence of Western films and series.

We believe that entertainment should be accessible, enjoyable, and organized for all fans, no matter where they are. Our platform was built with simplicity and speed in mind. We provide an ad-light, clean, and user-friendly interface that allows you to explore thousands of titles across multiple genres. You can easily find what you're looking for through categorized collections and regular episode updates — all in one seamless experience.

What sets us apart is our commitment to quality and community. We do not simply dump links or trailers — we curate, verify, and organize content so you can enjoy safe and trustworthy access without the noise. We also listen to our users. Your feedback helps shape the features and future of this platform.

Whether you're binge-watching the latest drama, exploring classic hits, or looking for a new favorite, iQPlay is here to make your viewing experience smooth, fun, and worthwhile. We're constantly evolving — with new features, better recommendations, and faster updates — so make sure to check in often.

Thank you for visiting and supporting iQPlay. If you have questions, feature suggestions, or partnership inquiries, feel free to reach out through our contact form or social media channels. We're always happy to hear from our community!''';

const String kPrivacyText =
    '''Effective Date: August 8, 2025

At iQPlay, we value your privacy. This Privacy Policy outlines the types of information we collect and how we use, store, and protect it.

1. Information We Collect
We may collect the following types of information:
• Personal Information: such as your name or email address, only when voluntarily submitted (e.g., through a contact form or newsletter).
• Non-Personal Information: including browser type, device information, IP address, and pages visited. This data helps us improve user experience.

2. Cookies
Our site may use cookies to:
• Analyze traffic and user behavior
• Enhance your browsing experience
• Store preferences or session data
You can choose to disable cookies through your browser settings.

3. Third-Party Services
We may use third-party services like:
• Google Analytics – for understanding visitor behavior
• Ad networks (e.g., Google AdSense) – to serve relevant ads
• Embedded content (e.g., videos from other platforms) – which may collect data through their own policies
Please review the privacy policies of these third-party services for more information.

4. Data Security
We implement reasonable measures to protect your information. However, no method of transmission over the internet is 100% secure.

5. Links to Other Sites
Our website may contain links to other websites. We are not responsible for the privacy practices of those sites.

6. Children's Privacy
We do not knowingly collect personal data from children under the age of 13. If you believe such data has been collected, please contact us immediately.

7. Your Consent
By using our website, you consent to this Privacy Policy.

8. Changes to This Policy
We may update this Privacy Policy at any time. Any changes will be posted on this page with a new effective date.

9. Contact Us
If you have any questions or concerns about this Privacy Policy, please contact us at: abeflixoriginal@gmail.com''';

const String kDisclaimerText =
    '''The content provided by iQPlay is for general entertainment and informational purposes only.

iQPlay does not host any files on its servers. All titles, artwork and metadata displayed in this app are provided by third-party services (such as TMDB) for informational purposes, and all media content is provided by third-party sources that are freely available on the internet.

All trademarks, artwork and copyrights belong to their respective owners. If you are a copyright owner and believe that any content available through this app infringes your rights, please contact us and we will take appropriate action.

We make no warranties about the completeness, reliability or accuracy of the information provided, and we are not responsible for the content of any external sites linked from this app. Your use of this app is at your own discretion and risk.''';
