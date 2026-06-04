import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final song = playerProvider.currentSong;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const PlayerScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(
              color: primaryColor.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                value: playerProvider.progress,
                backgroundColor: AppTheme.divider,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: song.albumArt != null
                          ? Image.memory(
                              Uint8List.fromList(song.albumArt!),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.music_note,
                                  color: primaryColor, size: 20),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.titleDisplay,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artistDisplay,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: playerProvider.hasPrevious
                          ? () => playerProvider.playPrevious()
                          : null,
                      icon: Icon(Icons.skip_previous,
                          color: playerProvider.hasPrevious
                              ? AppTheme.textPrimary
                              : AppTheme.textHint),
                      iconSize: 24,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                          minWidth: 36, minHeight: 36),
                    ),
                    GestureDetector(
                      onTap: playerProvider.togglePlayPause,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: playerProvider.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : Icon(
                                playerProvider.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                                color: Colors.black,
                                size: 20,
                                ),
                      ),
                    ),
                    IconButton(
                      onPressed: playerProvider.hasNext
                          ? () => playerProvider.playNext()
                          : null,
                      icon: Icon(Icons.skip_next,
                          color: playerProvider.hasNext
                              ? AppTheme.textPrimary
                              : AppTheme.textHint),
                      iconSize: 24,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                          minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}