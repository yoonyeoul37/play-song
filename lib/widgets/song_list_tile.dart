import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import '../screens/player_screen.dart';
import '../screens/edit_song_screen.dart';
import '../screens/ringtone_screen.dart';

class SongListTile extends StatelessWidget {
  final Song song;
  final int index;
  final List<Song> songList;

  const SongListTile({
    super.key,
    required this.song,
    required this.index,
    required this.songList,
  });

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final isCurrentSong = playerProvider.currentSong?.id == song.id;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isFav = musicProvider.isFavorite(song.id);

    return InkWell(
      onTap: () {
        context.read<PlayerProvider>().playFromList(songList, index);
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentSong
              ? primaryColor.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _buildAlbumArt(isCurrentSong, playerProvider, primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.titleDisplay,
                    style: TextStyle(
                      color: isCurrentSong ? primaryColor : AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: isCurrentSong
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${song.artistDisplay} • ${song.albumDisplay}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              song.durationFormatted,
              style: TextStyle(
                color: isCurrentSong ? primaryColor : AppTheme.textHint,
                fontSize: 12,
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: isCurrentSong ? primaryColor : AppTheme.textHint,
                  size: 18),
              color: AppTheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => [
                _buildPopupItem(Icons.play_arrow, '지금 재생', 'play', primaryColor),
                _buildPopupItem(Icons.skip_next, '다음에 재생', 'play_next', primaryColor),
                _buildPopupItem(Icons.playlist_add, '재생목록에 추가', 'playlist', primaryColor),
                _buildPopupItem(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  isFav ? '즐겨찾기 제거' : '즐겨찾기 추가',
                  'favorite',
                  isFav ? Colors.redAccent : primaryColor,
                ),
                _buildPopupItem(Icons.music_note, '벨소리로 설정', 'ringtone', primaryColor),
                _buildPopupItem(Icons.info_outline, '곡 정보', 'info', primaryColor),
              ],
              onSelected: (value) => _handleMenuAction(context, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArt(bool isCurrentSong, PlayerProvider playerProvider, Color primaryColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: song.albumArt != null
              ? Image.memory(
                  Uint8List.fromList(song.albumArt!),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  cacheWidth: 48,
                  cacheHeight: 48,
                )
              : Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.music_note,
                      color: primaryColor.withOpacity(0.6), size: 24),
                ),
        ),
        if (isCurrentSong)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              playerProvider.isPlaying ? Icons.equalizer : Icons.pause,
              color: primaryColor,
              size: 20,
            ),
          ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(
      IconData icon, String label, String value, Color primaryColor) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final playerProvider = context.read<PlayerProvider>();
    final musicProvider = context.read<MusicProvider>();

    switch (action) {
      case 'play':
        playerProvider.playFromList(songList, index);
        break;
      case 'play_next':
        playerProvider.addToPlayNext(song);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('다음에 재생됩니다'),
            backgroundColor: AppTheme.surfaceVariant,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'playlist':
        _showAddToPlaylistDialog(context, song);
        break;
      case 'favorite':
        musicProvider.toggleFavorite(song);
        final isFav = musicProvider.isFavorite(song.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFav ? '즐겨찾기에 추가됐습니다' : '즐겨찾기에서 제거됐습니다'),
            backgroundColor: AppTheme.surfaceVariant,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'ringtone':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RingtoneScreen(initialSong: song),
          ),
        );
        break;
      case 'info':
        _showSongInfo(context);
        break;
    }
  }

  void _showAddToPlaylistDialog(BuildContext context, song) {
    final playlistProvider = context.read<PlaylistProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;
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
                          style:
                              const TextStyle(color: AppTheme.textPrimary)),
                      subtitle: Text('${playlist.songCount}곡',
                          style: const TextStyle(
                              color: AppTheme.textSecondary)),
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

  void _showSongInfo(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text('곡 정보',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('제목', song.titleDisplay, primaryColor),
            _infoRow('아티스트', song.artistDisplay, primaryColor),
            _infoRow('앨범', song.albumDisplay, primaryColor),
            _infoRow('재생 시간', song.durationFormatted, primaryColor),
            if (song.uri != null) _infoRow('경로', song.uri!, primaryColor),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditSongScreen(song: song),
                ),
              );
            },
            child: Text('편집', style: TextStyle(color: primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기',
                style: TextStyle(color: AppTheme.textHint)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: primaryColor, fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}