import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Full-screen popup with the admin's posters, reels and Instagram reels.
/// Made simple for kids:
///   • closes BY ITSELF — poster after 10 s, reel when the video ends,
///     Instagram reel after 60 s — and goes to the next post if there is one
///   • big "Close ✕" button with a countdown ring, so they see it will close
///   • bars on top (like Instagram stories) show how many posts and how long is left
///   await PromoPopup.show(context, promos);
class PromoPopup extends StatefulWidget {
  final List<Map<String, dynamic>> promos;
  const PromoPopup({super.key, required this.promos});

  static const int posterSeconds = 10;
  static const int instagramSeconds = 60;

  static Future<void> show(BuildContext context, List<Map<String, dynamic>> promos) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Announcement',
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => PromoPopup(promos: promos),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }

  @override
  State<PromoPopup> createState() => _PromoPopupState();
}

enum _Kind { poster, reel, instagram }

class _PromoItem {
  final _Kind kind;
  final String url;
  final String fallbackUrl;
  final String thumbUrl;
  final double aspect; // width / height (0 = unknown)
  final String title;
  final String caption;
  final String openUrl; // Instagram: the normal link (open in the Instagram app)

  const _PromoItem({
    required this.kind,
    required this.url,
    this.fallbackUrl = '',
    this.thumbUrl = '',
    this.aspect = 0,
    required this.title,
    required this.caption,
    this.openUrl = '',
  });
}

class _PromoPopupState extends State<PromoPopup> {
  late final List<_PromoItem> items;
  final PageController pageCtrl = PageController();
  int index = 0;

  // ⏱ auto-close: progress of the current item 0..1
  Timer? _ticker;
  double _progress = 0;
  double _elapsed = 0; // seconds (posters / Instagram)
  double _reelSeconds = 0; // reel length (from the player)
  bool _paused = false; // student paused the reel / opened zoom
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    items = [];
    for (final p in widget.promos) {
      final title = (p['title'] ?? '').toString().trim();
      final caption = (p['caption'] ?? '').toString().trim();
      final img = p['image'];
      final vid = p['video'];
      final ig = p['instagram'];
      double aspectOf(Map m) {
        final w = (m['width'] as num?)?.toDouble() ?? 0;
        final h = (m['height'] as num?)?.toDouble() ?? 0;
        return (w > 0 && h > 0) ? w / h : 0;
      }

      if (img is Map && (img['url'] ?? '').toString().isNotEmpty) {
        items.add(_PromoItem(
          kind: _Kind.poster,
          url: img['url'].toString(),
          fallbackUrl: (img['originalUrl'] ?? '').toString(),
          aspect: aspectOf(img),
          title: title,
          caption: caption,
        ));
      }
      if (vid is Map && (vid['url'] ?? '').toString().isNotEmpty) {
        items.add(_PromoItem(
          kind: _Kind.reel,
          url: vid['url'].toString(),
          fallbackUrl: (vid['originalUrl'] ?? '').toString(),
          thumbUrl: (vid['thumbUrl'] ?? '').toString(),
          aspect: aspectOf(vid),
          title: title,
          caption: caption,
        ));
      }
      if (ig is Map && (ig['embedUrl'] ?? '').toString().isNotEmpty) {
        items.add(_PromoItem(
          kind: _Kind.instagram,
          url: ig['embedUrl'].toString(),
          openUrl: (ig['url'] ?? '').toString(),
          aspect: 9 / 16,
          title: title,
          caption: caption,
        ));
      }
    }
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    pageCtrl.dispose();
    super.dispose();
  }

  _PromoItem? get _current => items.isEmpty ? null : items[index];

  /// Posters and Instagram reels use a timer; uploaded reels follow the video itself.
  void _tick() {
    final it = _current;
    if (it == null || _closing || _paused || it.kind == _Kind.reel) return;
    final total = (it.kind == _Kind.poster ? PromoPopup.posterSeconds : PromoPopup.instagramSeconds).toDouble();
    _elapsed += 0.1;
    setState(() => _progress = (_elapsed / total).clamp(0, 1));
    if (_elapsed >= total) _next();
  }

  // reel player reports where it is
  void _onReelProgress(double position, double duration) {
    if (!mounted || duration <= 0) return;
    _reelSeconds = duration;
    setState(() => _progress = (position / duration).clamp(0, 1));
  }

  void _onReelFinished() => _next();

  void _onReelFailed() {
    // could not play → treat it like a poster (closes after 10 s)
    if (!mounted) return;
    setState(() {
      _reelSeconds = 0;
      _elapsed = 0;
      items[index] = _PromoItem(
        kind: _Kind.poster,
        url: '',
        title: items[index].title,
        caption: items[index].caption,
      );
    });
  }

  /// Next post, or close after the last one → back to the home screen
  void _next() {
    if (_closing || !mounted) return;
    if (index < items.length - 1) {
      pageCtrl.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    } else {
      _close();
    }
  }

  void _onPageChanged(int i) {
    setState(() {
      index = i;
      _elapsed = 0;
      _progress = 0;
      _reelSeconds = 0;
      _paused = false;
    });
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    _ticker?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  int get _secondsLeft {
    final it = _current;
    if (it == null) return 0;
    switch (it.kind) {
      case _Kind.poster:
        return (PromoPopup.posterSeconds - _elapsed).ceil().clamp(0, PromoPopup.posterSeconds);
      case _Kind.instagram:
        return (PromoPopup.instagramSeconds - _elapsed).ceil().clamp(0, PromoPopup.instagramSeconds);
      case _Kind.reel:
        return _reelSeconds <= 0 ? 0 : (_reelSeconds * (1 - _progress)).ceil();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _close();
      });
      return const SizedBox.shrink();
    }
    final current = items[index];
    final left = _secondsLeft;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(); // phone back button also closes
      },
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Column(
            children: [
              // ---- story bars (one per post) ----
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Row(
                  children: List.generate(items.length, (i) {
                    final value = i < index ? 1.0 : (i == index ? _progress : 0.0);
                    return Expanded(
                      child: Container(
                        height: 3.5,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // ---- top bar: brand + BIG close button with countdown ----
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📢', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Text("Let's Speak",
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _closeButton(left),
                  ],
                ),
              ),

              // ---- media ----
              Expanded(
                child: PageView.builder(
                  controller: pageCtrl,
                  itemCount: items.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    final active = i == index;
                    Widget child;
                    switch (it.kind) {
                      case _Kind.poster:
                        child = it.url.isEmpty
                            ? _mediaError('Could not load this post')
                            : _PosterImage(
                                item: it,
                                onZoom: (open) => setState(() => _paused = open),
                              );
                        break;
                      case _Kind.reel:
                        child = _ReelPlayer(
                          item: it,
                          active: active,
                          onProgress: active ? _onReelProgress : null,
                          onFinished: active ? _onReelFinished : null,
                          onFailed: active ? _onReelFailed : null,
                        );
                        break;
                      case _Kind.instagram:
                        child = active ? _InstagramReel(item: it) : _instagramPlaceholder();
                        break;
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Center(child: child),
                    );
                  },
                ),
              ),

              // ---- caption + hint ----
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: Column(
                  children: [
                    if (current.title.isNotEmpty)
                      Text(
                        current.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.25),
                      ),
                    if (current.caption.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        current.caption,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.78), fontSize: 12, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _paused
                          ? 'Paused'
                          : index < items.length - 1
                              ? 'Next post in ${left}s  •  swipe →'
                              : (left > 0 ? 'Going back home in ${left}s' : ''),
                      style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Big, clear close button: countdown ring + "Close" text (easy for kids)
  Widget _closeButton(int secondsLeft) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: _close,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1 - _progress,
                      strokeWidth: 3,
                      backgroundColor: Colors.black.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFD6336C)),
                    ),
                    secondsLeft > 0
                        ? Text('$secondsLeft',
                            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w800))
                        : const Icon(Icons.close_rounded, color: Colors.black87, size: 18),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('Close',
                  style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              const Icon(Icons.close_rounded, color: Colors.black87, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _instagramPlaceholder() => AspectRatio(
        aspectRatio: 9 / 16,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF833AB4), Color(0xFFD6336C), Color(0xFFF08C00)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 40)),
        ),
      );
}

// =====================================================
// POSTER
// =====================================================
class _PosterImage extends StatefulWidget {
  final _PromoItem item;
  final ValueChanged<bool> onZoom; // true = zoom open (pause the countdown)
  const _PosterImage({required this.item, required this.onZoom});

  @override
  State<_PosterImage> createState() => _PosterImageState();
}

class _PosterImageState extends State<_PosterImage> {
  bool useFallback = false;

  @override
  Widget build(BuildContext context) {
    final url = useFallback && widget.item.fallbackUrl.isNotEmpty ? widget.item.fallbackUrl : widget.item.url;
    return GestureDetector(
      onTap: () => _openZoom(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return AspectRatio(
              aspectRatio: widget.item.aspect > 0 ? widget.item.aspect : 4 / 5,
              child: Container(
                color: Colors.white.withValues(alpha: 0.06),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (_, __, ___) {
            if (!useFallback && widget.item.fallbackUrl.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => useFallback = true);
              });
            }
            return _mediaError('Could not load the poster');
          },
        ),
      ),
    );
  }

  Future<void> _openZoom(BuildContext context, String url) async {
    widget.onZoom(true);
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(minScale: 1, maxScale: 4, child: Image.network(url, fit: BoxFit.contain)),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    widget.onZoom(false);
  }
}

Widget _mediaError(String text) => Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 30),
          const SizedBox(height: 8),
          Text(text, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );

// =====================================================
// REEL (uploaded video): plays ONCE, then the popup moves on / closes
// =====================================================
class _ReelPlayer extends StatefulWidget {
  final _PromoItem item;
  final bool active; // the visible page
  final void Function(double position, double duration)? onProgress;
  final VoidCallback? onFinished;
  final VoidCallback? onFailed;
  const _ReelPlayer({required this.item, required this.active, this.onProgress, this.onFinished, this.onFailed});

  @override
  State<_ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<_ReelPlayer> {
  VideoPlayerController? ctrl;
  bool ready = false;
  bool failed = false;
  bool muted = true;
  bool triedFallback = false;
  bool showPauseIcon = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _init(widget.item.url);
  }

  Future<void> _init(String url) async {
    final old = ctrl;
    ctrl = null;
    old?.removeListener(_listen);
    await old?.dispose();

    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    ctrl = c;
    try {
      await c.initialize();
      if (!mounted || ctrl != c) return;
      await c.setLooping(false); // play once → then go home
      await c.setVolume(muted ? 0 : 1);
      c.addListener(_listen);
      if (widget.active) await c.play();
      setState(() {
        ready = true;
        failed = false;
      });
    } catch (e) {
      debugPrint('Reel load error ($url): $e');
      if (!mounted || ctrl != c) return;
      // The 720p copy may still be processing on Cloudinary → play the original upload
      if (!triedFallback && widget.item.fallbackUrl.isNotEmpty && widget.item.fallbackUrl != url) {
        triedFallback = true;
        _init(widget.item.fallbackUrl);
        return;
      }
      setState(() => failed = true);
      widget.onFailed?.call();
    }
  }

  void _listen() {
    final c = ctrl;
    if (c == null || !c.value.isInitialized) return;
    final dur = c.value.duration.inMilliseconds / 1000.0;
    final pos = c.value.position.inMilliseconds / 1000.0;
    widget.onProgress?.call(pos, dur);
    // video ended → popup goes to the next post / home
    if (!_finished && dur > 0 && pos >= dur - 0.25 && !c.value.isPlaying) {
      _finished = true;
      widget.onFinished?.call();
    }
  }

  @override
  void didUpdateWidget(covariant _ReelPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = ctrl;
    if (c == null || !ready) return;
    if (widget.active && !oldWidget.active) {
      _finished = false;
      c.seekTo(Duration.zero);
      c.play();
    }
    if (!widget.active && oldWidget.active) c.pause();
  }

  @override
  void dispose() {
    ctrl?.removeListener(_listen);
    ctrl?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = ctrl;
    if (c == null || !ready) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
        showPauseIcon = true;
      } else {
        c.play();
        showPauseIcon = false;
      }
    });
  }

  void _toggleMute() {
    final c = ctrl;
    if (c == null) return;
    setState(() => muted = !muted);
    c.setVolume(muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    if (failed) return _mediaError('Could not play the reel');

    final c = ctrl;
    final aspect = (ready && c != null && c.value.aspectRatio > 0)
        ? c.value.aspectRatio
        : (widget.item.aspect > 0 ? widget.item.aspect : 9 / 16);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: aspect,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black),
            if (!ready && widget.item.thumbUrl.isNotEmpty)
              Image.network(widget.item.thumbUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            if (ready && c != null) GestureDetector(onTap: _togglePlay, child: VideoPlayer(c)),
            if (!ready) const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            if (ready && showPauseIcon)
              IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                  ),
                ),
              ),
            Positioned(top: 10, left: 10, child: _reelBadge('Reel')),
            if (ready)
              Positioned(
                right: 10,
                bottom: 14,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white, size: 16),
                        if (muted) ...[
                          const SizedBox(width: 5),
                          Text('Tap for sound',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _reelBadge(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF833AB4), Color(0xFFD6336C), Color(0xFFF08C00)]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.movie_filter_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );

// =====================================================
// INSTAGRAM REEL (link from the admin) — Instagram's own embed player
// =====================================================
class _InstagramReel extends StatefulWidget {
  final _PromoItem item;
  const _InstagramReel({required this.item});

  @override
  State<_InstagramReel> createState() => _InstagramReelState();
}

class _InstagramReelState extends State<_InstagramReel> {
  late final WebViewController web;
  bool loading = true;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => loading = false);
          },
          onWebResourceError: (e) {
            if (mounted && (e.isForMainFrame ?? true)) setState(() => failed = true);
          },
          // taps on "View on Instagram" etc. open the Instagram app instead of navigating away
          onNavigationRequest: (req) {
            if (req.url.contains('/embed')) return NavigationDecision.navigate;
            _openInInstagram(req.url);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.item.url));
  }

  Future<void> _openInInstagram([String? url]) async {
    final link = Uri.tryParse(url ?? widget.item.openUrl);
    if (link == null) return;
    try {
      await launchUrl(link, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black),
                  if (!failed) WebViewWidget(controller: web),
                  if (loading && !failed) const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  if (failed) _mediaError('Could not load the Instagram reel'),
                  Positioned(top: 10, left: 10, child: IgnorePointer(child: _reelBadge('Instagram'))),
                ],
              ),
            ),
          ),
        ),
        if (widget.item.openUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _openInInstagram,
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.white70, size: 16),
            label: Text('Open in Instagram',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }
}
