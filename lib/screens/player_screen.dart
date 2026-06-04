import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../providers/lyrics_provider.dart';
import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import 'edit_song_screen.dart';
import 'lyrics_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _equalizerController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _equalizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerProvider = context.read<PlayerProvider>();
      final lyricsProvider = context.read<LyricsProvider>();

      final currentSong = playerProvider.currentSong;
      if (currentSong != null) {
        lyricsProvider.fetchLyrics(
          currentSong.titleDisplay,
          currentSong.artistDisplay,
          filePath: currentSong.uri,
        );
      }

playerProvider.onSongChanged = (song) {
        lyricsProvider.clearLyrics();
        lyricsProvider.fetchLyrics(
          song.titleDisplay,
          song.artistDisplay,
          filePath: song.uri,
        );
      };
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _equalizerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final song = playerProvider.currentSong;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (playerProvider.isPlaying) {
      _rotationController.repeat();
      _equalizerController.repeat(reverse: true);
    } else {
      _rotationController.stop();
      _equalizerController.stop();
    }

    if (song == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Text('재생 중인 곡이 없습니다',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, playerProvider, primaryColor),
            Expanded(flex: 5, child: _buildAlbumArt(song, primaryColor)),
            _buildEqualizer(playerProvider, primaryColor),
            _buildCurrentLyrics(playerProvider, primaryColor),
            Expanded(
                flex: 4,
                child: _buildControls(
                    context, playerProvider, musicProvider, song, primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
    final song = playerProvider.currentSong;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down,
                color: AppTheme.textPrimary, size: 30),
          ),
          const Expanded(
            child: Text('지금 재생 중',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2)),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
            color: AppTheme.surfaceVariant,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: primaryColor, size: 18),
                    const SizedBox(width: 10),
                    const Text('곡 정보 편집',
                        style: TextStyle(color: AppTheme.textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'playlist',
                child: Row(
                  children: [
                    Icon(Icons.playlist_add, color: primaryColor, size: 18),
                    const SizedBox(width: 10),
                    const Text('재생목록에 추가',
                        style: TextStyle(color: AppTheme.textPrimary)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (song == null) return;
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditSongScreen(song: song),
                  ),
                );
              } else if (value == 'playlist') {
                _showAddToPlaylistDialog(context, song, primaryColor);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(song, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * pi,
                child: child,
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A1A1A),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(
                      color: primaryColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  heightFactor: 0.8,
                  child: ClipOval(
                    child: song.albumArt != null
                        ? Image.memory(
                            Uint8List.fromList(song.albumArt!),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.surfaceVariant,
                                  primaryColor.withOpacity(0.3),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(Icons.music_note,
                                  color: primaryColor.withOpacity(0.7),
                                  size: 60),
                            ),
                          ),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.background,
                    border: Border.all(
                      color: primaryColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEqualizer(PlayerProvider playerProvider, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _equalizerController,
            builder: (context, child) {
              final value = playerProvider.isPlaying
                  ? (0.3 + (index % 3) * 0.2 + _equalizerController.value * 0.5)
                  : 0.2;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 4,
                height: 24 * value,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildCurrentLyrics(PlayerProvider playerProvider, Color primaryColor) {
    final lyricsProvider = context.read<LyricsProvider>();
    if (!lyricsProvider.hasLyrics || lyricsProvider.lyrics.isEmpty) {
      return const SizedBox.shrink();
    }
    lyricsProvider.updateCurrentLine(playerProvider.position);
    final currentLine = lyricsProvider.lyrics[lyricsProvider.currentLineIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Text(
        currentLine.text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, PlayerProvider playerProvider,
      MusicProvider musicProvider, song, Color primaryColor) {
    final isFav = musicProvider.isFavorite(song.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.titleDisplay,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(song.artistDisplay,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => musicProvider.toggleFavorite(song),
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.redAccent : AppTheme.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: playerProvider.progress,
            onChanged: (value) {
              final position = Duration(
                milliseconds:
                    (value * playerProvider.duration.inMilliseconds).toInt(),
              );
              playerProvider.seekTo(position);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(playerProvider.formatDuration(playerProvider.position),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
              Text(playerProvider.formatDuration(playerProvider.duration),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => playerProvider.playPrevious(),
                icon: const Icon(Icons.skip_previous),
                color: AppTheme.textPrimary,
                iconSize: 36,
              ),
              GestureDetector(
                onTap: playerProvider.togglePlayPause,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(primaryColor, Colors.white, 0.2)!,
                        primaryColor,
                        Color.lerp(primaryColor, Colors.black, 0.2)!,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: playerProvider.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.black),
                        )
                      : Icon(
                          playerProvider.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.black,
                          size: 36,
                        ),
                ),
              ),
              IconButton(
                onPressed: () => playerProvider.playNext(),
                icon: const Icon(Icons.skip_next),
                color: AppTheme.textPrimary,
                iconSize: 36,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () => playerProvider.toggleShuffle(),
                icon: Icon(Icons.shuffle,
                    color: playerProvider.isShuffled
                        ? primaryColor
                        : AppTheme.textHint),
                iconSize: 22,
              ),
              IconButton(
                              onPressed: () => _showLoopModeDialog(context, playerProvider, primaryColor),
                              icon: Icon(
                                  playerProvider.loopMode == LoopMode.one
                                      ? Icons.repeat_one
                                      : Icons.repeat,
                                  color: playerProvider.loopMode != LoopMode.off
                                      ? primaryColor
                                      : AppTheme.textHint),
                              iconSize: 22,
                            ),
              IconButton(
                onPressed: () => _showSleepTimerDialog(context, playerProvider, primaryColor),
                icon: Icon(Icons.bedtime,
                    color: playerProvider.isSleepTimerActive
                        ? primaryColor
                        : AppTheme.textHint),
                iconSize: 22,
              ),
              IconButton(
                onPressed: () => _showSpeedDialog(context, playerProvider, primaryColor),
                icon: Icon(Icons.speed,
                    color: playerProvider.playbackSpeed != 1.0
                        ? primaryColor
                        : AppTheme.textHint),
                iconSize: 22,
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LyricsScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.lyrics_outlined, color: AppTheme.textHint),
                iconSize: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, song, Color primaryColor) {
    final playlistProvider = context.read<PlaylistProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text('재생목록에 추가',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: playlistProvider.playlists.isEmpty
            ? const Text('재생목록이 없습니다.\n재생목록 탭에서 먼저 만들어주세요.',
                style: TextStyle(color: AppTheme.textSecondary))
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlistProvider.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlistProvider.playlists[index];
                    return ListTile(
                      leading: Icon(Icons.playlist_play, color: primaryColor),
                      title: Text(playlist.name,
                          style: const TextStyle(color: AppTheme.textPrimary)),
                      subtitle: Text('${playlist.songCount}곡',
                          style: const TextStyle(color: AppTheme.textSecondary)),
                      onTap: () {
                        playlistProvider.addSongToPlaylist(playlist.id, song);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${playlist.name}에 추가됐습니다'),
                            backgroundColor: AppTheme.surfaceVariant,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('닫기', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
    showDialog(
      context: context,
      builder: (ctx) => _SleepTimerDialog(playerProvider: playerProvider, primaryColor: primaryColor),
    );
  }

  void _showSpeedDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
    showDialog(
      context: context,
      builder: (ctx) => _SpeedDialog(playerProvider: playerProvider, primaryColor: primaryColor),
    );
  }
}

void _showLoopModeDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceVariant,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.repeat, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  const Text('반복 모드',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              _buildLoopOption(
                ctx,
                icon: Icons.arrow_forward,
                title: '반복 없음',
                subtitle: '목록 끝나면 정지',
                isSelected: playerProvider.loopMode == LoopMode.off,
                primaryColor: primaryColor,
                onTap: () {
                  playerProvider.setLoopMode(LoopMode.off);
                  setDialogState(() {});
                  Navigator.pop(ctx);
                },
              ),
              _buildLoopOption(
                ctx,
                icon: Icons.repeat_one,
                title: '현재 노래 반복',
                subtitle: '현재 노래를 계속 반복',
                isSelected: playerProvider.loopMode == LoopMode.one,
                primaryColor: primaryColor,
                onTap: () {
                  playerProvider.setLoopMode(LoopMode.one);
                  setDialogState(() {});
                  Navigator.pop(ctx);
                },
              ),
              _buildLoopOption(
                ctx,
                icon: Icons.repeat,
                title: '전체 반복',
                subtitle: '목록 전체를 계속 반복',
                isSelected: playerProvider.loopMode == LoopMode.all,
                primaryColor: primaryColor,
                onTap: () {
                  playerProvider.setLoopMode(LoopMode.all);
                  setDialogState(() {});
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoopOption(
    BuildContext ctx, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withOpacity(0.15)
                    : AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: isSelected ? primaryColor : AppTheme.textHint,
                  size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: isSelected
                              ? primaryColor
                              : AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

class _SleepTimerDialog extends StatefulWidget {
  final PlayerProvider playerProvider;
  final Color primaryColor;
  const _SleepTimerDialog({required this.playerProvider, required this.primaryColor});

  @override
  State<_SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<_SleepTimerDialog> {
  int selectedHours = 0;
  int selectedMinutes = 30;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.playerProvider.isSleepTimerActive &&
        widget.playerProvider.sleepTimerEnd != null) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final end = widget.playerProvider.sleepTimerEnd;
    if (end != null) {
      _remaining = end.difference(DateTime.now());
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final end = widget.playerProvider.sleepTimerEnd;
      if (end == null) {
        timer.cancel();
        return;
      }
      setState(() {
        _remaining = end.difference(DateTime.now());
        if (_remaining.isNegative) {
          _remaining = Duration.zero;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatRemaining(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) return '$hours시간 $minutes분 $seconds초 후 종료';
    return '$minutes분 $seconds초 후 종료';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.playerProvider.isSleepTimerActive;
    final primaryColor = widget.primaryColor;

    return Dialog(
      backgroundColor: AppTheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 타이틀
            Row(
              children: [
                Icon(Icons.bedtime, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text('수면 타이머',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),

            if (isActive) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.timer, color: primaryColor, size: 32),
                    const SizedBox(height: 8),
                    Text(_formatRemaining(_remaining),
                        style: TextStyle(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.playerProvider.cancelSleepTimer();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('타이머 취소'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('닫기'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // 시간 표시
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${selectedHours > 0 ? '${selectedHours}시간 ' : ''}${selectedMinutes}분',
                    style: TextStyle(
                        color: primaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 분 슬라이더
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('분',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ),
                  Expanded(
                    child: Slider(
                      value: selectedMinutes.toDouble(),
                      min: 0, max: 59, divisions: 59,
                      onChanged: (value) =>
                          setState(() => selectedMinutes = value.toInt()),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    child: Text('$selectedMinutes',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ),
                ],
              ),

              // 시간 슬라이더
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('시',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ),
                  Expanded(
                    child: Slider(
                      value: selectedHours.toDouble(),
                      min: 0, max: 6, divisions: 6,
                      onChanged: (value) =>
                          setState(() => selectedHours = value.toInt()),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    child: Text('$selectedHours',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textHint,
                        side: const BorderSide(color: AppTheme.divider),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final total = selectedHours * 60 + selectedMinutes;
                        if (total > 0) {
                          widget.playerProvider.setSleepTimer(
                            Duration(
                                hours: selectedHours,
                                minutes: selectedMinutes),
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                '${selectedHours > 0 ? '${selectedHours}시간 ' : ''}${selectedMinutes}분 후 종료'),
                            backgroundColor: AppTheme.surfaceVariant,
                            duration: const Duration(seconds: 2),
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('설정',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SpeedDialog extends StatefulWidget {
  final PlayerProvider playerProvider;
  final Color primaryColor;
  const _SpeedDialog(
      {required this.playerProvider, required this.primaryColor});

  @override
  State<_SpeedDialog> createState() => _SpeedDialogState();
}

class _SpeedDialogState extends State<_SpeedDialog> {
  late double _speed;

  @override
  void initState() {
    super.initState();
    _speed = widget.playerProvider.playbackSpeed;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor;
    return Dialog(
      backgroundColor: AppTheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 타이틀
            Row(
              children: [
                Icon(Icons.speed, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text('재생 속도',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            // 속도 표시
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${_speed.toStringAsFixed(2)}x',
                  style: TextStyle(
                      color: primaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 슬라이더
            Slider(
              value: _speed,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              onChanged: (value) {
                setState(() => _speed = value);
                widget.playerProvider.setPlaybackSpeed(value);
              },
            ),
            const SizedBox(height: 8),

            // 프리셋 버튼
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0].map((speed) {
                final isSelected = (_speed - speed).abs() < 0.01;
                return GestureDetector(
                  onTap: () {
                    setState(() => _speed = speed);
                    widget.playerProvider.setPlaybackSpeed(speed);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : AppTheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : AppTheme.divider),
                    ),
                    child: Text(
                      '${speed}x',
                      style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _speed = 1.0);
                      widget.playerProvider.setPlaybackSpeed(1.0);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textHint,
                      side: const BorderSide(color: AppTheme.divider),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('기본값'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('닫기',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}