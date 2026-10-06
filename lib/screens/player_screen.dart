import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../data/catalog.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/cards.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.episode});

  final Episode episode;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  static const _introStart = Duration(seconds: 3);
  static const _introEnd = Duration(seconds: 85);
  static const _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  late final AppState _state;
  late VideoPlayerController _controller;
  Timer? _saveTimer;
  Timer? _hideTimer;
  Timer? _nextTimer;
  bool _showControls = true;
  bool _ended = false;
  int _countdown = 5;
  Object? _error;

  Episode get _episode => widget.episode;

  @override
  void initState() {
    super.initState();
    _state = context.read<AppState>();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _init();
  }

  Future<void> _init() async {
    setState(() => _error = null);
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(_episode.videoUrl),
    );
    try {
      await _controller.initialize();
      if (!mounted) return;
      final resume = _resumePosition();
      if (resume > Duration.zero) await _controller.seekTo(resume);
      _controller.addListener(_onTick);
      await _controller.play();
      _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _save());
      _scheduleHide();
      setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// La posizione salvata è sulla durata di catalogo: la riportiamo
  /// alla durata reale del video.
  Duration _resumePosition() {
    final saved = _state.resumePositionOf(_episode);
    final real = _controller.value.duration;
    if (saved == Duration.zero || real == Duration.zero) return Duration.zero;
    final ratio = saved.inMilliseconds / _episode.duration.inMilliseconds;
    return real * ratio.clamp(0.0, 0.98);
  }

  void _onTick() {
    final v = _controller.value;
    if (!v.isInitialized || _ended) return;
    if (v.duration > Duration.zero &&
        v.position >= v.duration - const Duration(milliseconds: 300)) {
      _ended = true;
      _save();
      _startNextCountdown();
      setState(() => _showControls = true);
    }
  }

  void _save({bool deferNotify = false}) {
    final v = _controller.value;
    if (!v.isInitialized || v.position == Duration.zero) return;
    _state.saveProgress(
      _episode,
      v.position,
      total: v.duration,
      deferNotify: deferNotify,
    );
  }

  Episode? get _next {
    final next = _state.episodeAfter(_episode);
    if (next == null || _state.isLocked(next)) return null;
    return next;
  }

  void _startNextCountdown() {
    if (!_state.autoplay || _next == null) return;
    _countdown = 5;
    _nextTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_countdown <= 1) {
        t.cancel();
        _goNext();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _goNext() {
    final next = _state.episodeAfter(_episode);
    if (next == null) return;
    _nextTimer?.cancel();
    if (_state.isLocked(next)) {
      showPremiumSheet(context);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PlayerScreen(episode: next)),
    );
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  void _seekBy(Duration delta) {
    final v = _controller.value;
    var target = v.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (target > v.duration) target = v.duration;
    _controller.seekTo(target);
    _scheduleHide();
  }

  void _togglePlay() {
    final v = _controller.value;
    if (v.isPlaying) {
      _controller.pause();
      _save();
    } else {
      if (_ended) {
        _ended = false;
        _nextTimer?.cancel();
        _controller.seekTo(Duration.zero);
      }
      _controller.play();
      _scheduleHide();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _save(deferNotify: true);
    _saveTimer?.cancel();
    _hideTimer?.cancel();
    _nextTimer?.cancel();
    _controller.removeListener(_onTick);
    _controller.dispose();
    SystemChrome.setPreferredOrientations([]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final series = Catalog.byId(_episode.seriesId);
    return Scaffold(
      backgroundColor: Colors.black,
      body: _error != null
          ? _ErrorView(
              onRetry: () {
                _controller.dispose();
                _init();
              },
            )
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              onDoubleTapDown: (d) {
                final w = MediaQuery.sizeOf(context).width;
                _seekBy(
                  Duration(seconds: d.localPosition.dx < w / 2 ? -10 : 10),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (_, v, _) => v.isInitialized
                          ? AspectRatio(
                              aspectRatio: v.aspectRatio,
                              child: VideoPlayer(_controller),
                            )
                          : const CircularProgressIndicator(),
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (_, v, _) => v.isBuffering && v.isInitialized
                        ? const Center(child: CircularProgressIndicator())
                        : const SizedBox.shrink(),
                  ),
                  AnimatedOpacity(
                    opacity: _showControls ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: _Controls(
                        controller: _controller,
                        title: series.title,
                        subtitle: '${_episode.code} - ${_episode.title}',
                        speeds: _speeds,
                        hasNext: _state.episodeAfter(_episode) != null,
                        onBack: () => Navigator.pop(context),
                        onTogglePlay: _togglePlay,
                        onSeekBy: _seekBy,
                        onNext: _goNext,
                        onInteract: _scheduleHide,
                      ),
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (_, v, _) {
                      final inIntro =
                          v.isInitialized &&
                          v.position >= _introStart &&
                          v.position < _introEnd &&
                          v.duration > _introEnd * 2;
                      if (!inIntro) return const SizedBox.shrink();
                      return Positioned(
                        right: 24,
                        bottom: 90,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          onPressed: () => _controller.seekTo(_introEnd),
                          child: const Text('Salta intro'),
                        ),
                      );
                    },
                  ),
                  if (_ended && _state.autoplay && _next != null)
                    Positioned(
                      right: 24,
                      bottom: 90,
                      child: FilledButton.icon(
                        onPressed: _goNext,
                        icon: const Icon(Icons.skip_next),
                        label: Text('Prossimo episodio tra $_countdown s'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.controller,
    required this.title,
    required this.subtitle,
    required this.speeds,
    required this.hasNext,
    required this.onBack,
    required this.onTogglePlay,
    required this.onSeekBy,
    required this.onNext,
    required this.onInteract,
  });

  final VideoPlayerController controller;
  final String title;
  final String subtitle;
  final List<double> speeds;
  final bool hasNext;
  final VoidCallback onBack;
  final VoidCallback onTogglePlay;
  final void Function(Duration) onSeekBy;
  final VoidCallback onNext;
  final VoidCallback onInteract;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black87,
            Colors.transparent,
            Colors.transparent,
            Colors.black87,
          ],
          stops: [0, 0.3, 0.65, 1],
        ),
      ),
      child: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, v, _) {
            final total = v.duration;
            final pos = v.position > total ? total : v.position;
            return Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Indietro',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<double>(
                      tooltip: 'Velocità',
                      icon: const Icon(Icons.speed, color: Colors.white),
                      initialValue: v.playbackSpeed,
                      onOpened: onInteract,
                      onSelected: controller.setPlaybackSpeed,
                      itemBuilder: (_) => [
                        for (final s in speeds)
                          PopupMenuItem(value: s, child: Text('${s}x')),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Indietro 10 secondi',
                      iconSize: 40,
                      onPressed: () => onSeekBy(const Duration(seconds: -10)),
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                    ),
                    const SizedBox(width: 32),
                    IconButton(
                      tooltip: v.isPlaying ? 'Pausa' : 'Riproduci',
                      iconSize: 64,
                      onPressed: onTogglePlay,
                      icon: Icon(
                        v.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 32),
                    IconButton(
                      tooltip: 'Avanti 10 secondi',
                      iconSize: 40,
                      onPressed: () => onSeekBy(const Duration(seconds: 10)),
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                    ),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        formatDuration(pos),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Expanded(
                        child: Slider(
                          value: total.inMilliseconds == 0
                              ? 0
                              : pos.inMilliseconds / total.inMilliseconds,
                          activeColor: AppColors.accent2,
                          inactiveColor: Colors.white24,
                          onChanged: total.inMilliseconds == 0
                              ? null
                              : (f) {
                                  onInteract();
                                  controller.seekTo(total * f);
                                },
                        ),
                      ),
                      Text(
                        formatDuration(total),
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (hasNext)
                        IconButton(
                          tooltip: 'Episodio successivo',
                          onPressed: onNext,
                          icon: const Icon(
                            Icons.skip_next,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          IconButton(
            tooltip: 'Indietro',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Impossibile caricare il video.\nControlla la connessione.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: const Text('Riprova')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
