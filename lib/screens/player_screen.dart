import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/anime_model.dart';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String watchUrl; // e.g. "https://animekai.be/watch/one-piece" or streamUrl
  final List<ServerSource> servers;
  final int selectedServerIndex;

  const PlayerScreen({
    super.key,
    required this.title,
    required this.watchUrl,
    required this.servers,
    this.selectedServerIndex = 0,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _isFullscreenMode = false;
  late int _currentServerIndex;

  // uBlock Origin Lite - Precise Ad Domains Blacklist
  static const Set<String> _uBlockAdDomains = {
    'stoitercoppin',
    'llvpn',
    'straitsveiler',
    'profiton',
    'exoclick',
    'juicyads',
    'propellerads',
    'monetag',
    'adcash',
    'clickadu',
    'popcash',
    'popads',
    'adsterra',
    'hilltopads',
    'syndication',
    'luugy.com',
    'roboforex.com',
    'doubleclick.net',
    'googletagmanager',
    'google-analytics',
    'cloudflareinsights',
    'beacon.min.js',
    'sharethis.com',
    'disqus.com',
    'bet365',
    '1xbet',
  };

  @override
  void initState() {
    super.initState();
    _currentServerIndex = widget.selectedServerIndex;
    _initWebview(widget.watchUrl);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _toggleNativeFullscreen() {
    setState(() {
      _isFullscreenMode = !_isFullscreenMode;
    });

    if (_isFullscreenMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  bool _shouldBlockRequest(String url) {
    final lower = url.toLowerCase();

    // Always allow clean video stream servers & essential assets
    if (lower.contains('animekai.be') ||
        lower.contains('megaplay.buzz') ||
        lower.contains('myanimelist.net') ||
        lower.contains('jwpcdn.com') ||
        lower.contains('jwplayer') ||
        lower.contains('.m3u8') ||
        lower.contains('.mp4') ||
        lower.contains('blob:') ||
        lower.startsWith('about:blank')) {
      return false;
    }

    // uBlock Rule Match against Ad Domains
    for (var domain in _uBlockAdDomains) {
      if (lower.contains(domain)) {
        return true;
      }
    }

    // Block any external link triggered by video player click
    return true;
  }

  void _initWebview(String targetUrl) {
    setState(() {
      _isLoading = true;
    });

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0E14))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            // 1. Block any ad or non-essential navigation on video click
            if (_shouldBlockRequest(url)) {
              debugPrint('🛑 [Anti-Clickjack AdBlock] Prevented Ad Navigation: $url');
              return NavigationDecision.prevent;
            }

            // 2. Main Frame Popunder Protection
            if (request.isMainFrame) {
              final lower = url.toLowerCase();
              if (!lower.contains('animekai.be') &&
                  !lower.contains('megaplay.buzz') &&
                  !lower.startsWith('about:blank')) {
                debugPrint('🛑 [Anti-Clickjack AdBlock] Main-Frame Redirect Blocked: $url');
                return NavigationDecision.prevent;
              }
            }

            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _injectUBolScriptlets();
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _startUBolCosmeticCleaner();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Webview resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(
        Uri.parse(targetUrl),
        headers: {
          'Referer': 'https://animekai.be/',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        },
      );
  }

  /// Inject uBlock Origin Lite Anti-Clickjack Scriptlets
  void _injectUBolScriptlets() {
    _webViewController.runJavaScript('''
      // 1. Array & String Polyfills
      if (!Array.prototype.at) {
        Array.prototype.at = function(n) {
          n = Math.trunc(n) || 0;
          if (n < 0) n += this.length;
          if (n < 0 || n >= this.length) return undefined;
          return this[n];
        };
      }
      if (!String.prototype.at) {
        String.prototype.at = function(n) {
          n = Math.trunc(n) || 0;
          if (n < 0) n += this.length;
          if (n < 0 || n >= this.length) return undefined;
          return this[n];
        };
      }

      // 2. Kill Window Popup Triggers
      window.open = function() { console.log('🛑 window.open blocked'); return null; };
      window.showModalDialog = function() { return null; };
      window.alert = function() { return null; };

      // 3. Destroy Transparent Clickjack Overlays over Video Player on Pointerdown & Click
      const killClickjackOverlays = function(e) {
        // Destroy target if it is an external link overlay
        const a = e.target.closest('a');
        if (a) {
          const href = a.getAttribute('href') || '';
          if (href.startsWith('http') && !href.includes('animekai.be') && !href.includes('megaplay.buzz')) {
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();
            a.remove();
            console.log('🛑 Clickjack Overlay Link Destroyed:', href);
          }
        }

        // Intercept Fullscreen button click cleanly
        const isFullscreenBtn = e.target.closest('#btn-expand, .fa-expand, .jw-icon-fullscreen, .vjs-fullscreen-control, [title*="Expand"], [title*="Full"]');
        if (isFullscreenBtn) {
          e.stopPropagation();
          console.log('🛑 Fullscreen Click Intercepted (Ad Suppressed)');
          const playerElem = document.getElementById('player-main') || document.getElementById('player') || document.querySelector('iframe');
          if (playerElem) {
            if (playerElem.requestFullscreen) {
              playerElem.requestFullscreen();
            } else if (playerElem.webkitRequestFullscreen) {
              playerElem.webkitRequestFullscreen();
            }
          }
        }
      };

      document.addEventListener('pointerdown', killClickjackOverlays, true);
      document.addEventListener('click', killClickjackOverlays, true);
      document.addEventListener('touchend', killClickjackOverlays, true);

      // 4. uBOL Precise Cosmetic CSS Rules
      const style = document.createElement('style');
      style.id = 'ubol-cosmetic-rules';
      style.innerHTML = `
        body, html {
          background-color: #0B0E14 !important;
          color: #FFFFFF !important;
        }
        #social-sharing, .sharing-info, .alert-secondary,
        iframe[src*="stoitercoppin"], iframe[src*="llvpn"], iframe[src*="luugy"],
        script[src*="straitsveiler"], script[src*="profiton"], script[src*="googletagmanager"],
        script[src*="cloudflareinsights"], script[src*="llvpn"], script[src*="exoclick"],
        .popunder, .ad-banner, .banner-ad,
        a[target="_blank"][href*="http"]:not([href*="animekai.be"]):not([href*="megaplay.buzz"]) {
          display: none !important;
          visibility: hidden !important;
          opacity: 0 !important;
          pointer-events: none !important;
        }
      `;
      if (!document.getElementById('ubol-cosmetic-rules')) {
        document.head.appendChild(style);
      }
    ''');
  }

  /// Start Dynamic Anti-Clickjack Cleaner Loop
  void _startUBolCosmeticCleaner() {
    _webViewController.runJavaScript('''
      function uBolPurgeAdElements() {
        window.open = function() { return null; };

        // Remove transparent ad overlays placed on top of player
        const adSelectors = [
          '#social-sharing',
          '.sharing-info',
          '.alert-secondary',
          'iframe[src*="stoitercoppin"]',
          'iframe[src*="llvpn"]',
          'iframe[src*="luugy"]',
          'script[src*="straitsveiler"]',
          'script[src*="profiton"]',
          'script[src*="googletagmanager"]',
          'script[src*="cloudflareinsights"]',
          'script[src*="exoclick"]',
          '.popunder',
          'a[target="_blank"][href*="http"]:not([href*="animekai.be"]):not([href*="megaplay.buzz"])'
        ];

        adSelectors.forEach(selector => {
          document.querySelectorAll(selector).forEach(el => el.remove());
        });

        // Remove fixed/absolute overlay divs covering the video frame
        document.querySelectorAll('div[style*="position: absolute"], div[style*="position: fixed"]').forEach(el => {
          const zIndex = parseInt(window.getComputedStyle(el).zIndex) || 0;
          if (zIndex > 100 && !el.querySelector('video') && !el.querySelector('iframe')) {
            el.remove();
          }
        });

        // Auto click video play button if present
        const playBtn = document.getElementById('player-play-btn');
        if (playBtn && playBtn.offsetParent !== null) {
          playBtn.click();
        }
      }

      uBolPurgeAdElements();

      if (window.MutationObserver && !window._uBolObserver) {
        window._uBolObserver = new MutationObserver(function() {
          uBolPurgeAdElements();
        });
        window._uBolObserver.observe(document.body || document.documentElement, {
          childList: true,
          subtree: true
        });
      }

      setInterval(uBolPurgeAdElements, 500);
    ''');
  }

  void _switchServer(int index) {
    if (index >= 0 && index < widget.servers.length) {
      setState(() {
        _currentServerIndex = index;
      });
      _webViewController.loadRequest(
        Uri.parse(widget.servers[index].streamUrl),
        headers: {'Referer': 'https://animekai.be/'},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _isFullscreenMode
          ? null
          : AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.shield_rounded,
                          color: AppTheme.cyanAccent, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Anti-Clickjack AdBlock • 100% Clean Touch',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: AppTheme.cyanAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              backgroundColor: AppTheme.background,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(_isFullscreenMode
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded),
                  tooltip: 'Native App Fullscreen',
                  onPressed: _toggleNativeFullscreen,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => _webViewController.reload(),
                ),
              ],
            ),
      body: Column(
        children: [
          // Main Webview Player Frame
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: AppTheme.background,
                  child: WebViewWidget(controller: _webViewController),
                ),
                if (_isLoading)
                  Container(
                    color: AppTheme.background,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.primaryAccent,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Loading Ad-Free Stream...',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Floating Exit Fullscreen Button when in Fullscreen Mode
                if (_isFullscreenMode)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      backgroundColor: Colors.black.withValues(alpha: 0.7),
                      foregroundColor: Colors.white,
                      onPressed: _toggleNativeFullscreen,
                      child: const Icon(Icons.fullscreen_exit_rounded),
                    ),
                  ),
              ],
            ),
          ),

          // Server Selector Chips if available & not in fullscreen mode
          if (widget.servers.isNotEmpty && !_isFullscreenMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.cardSurface,
              child: Row(
                children: [
                  Text(
                    'Servers: ',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(widget.servers.length, (index) {
                          final server = widget.servers[index];
                          final isSelected = index == _currentServerIndex;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              label: Text(
                                '${server.name} (${server.langType.toUpperCase()})',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryAccent,
                              backgroundColor: AppTheme.background,
                              onSelected: (selected) {
                                if (selected) {
                                  _switchServer(index);
                                }
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
