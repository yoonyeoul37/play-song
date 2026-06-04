import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_list_tile.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final playlists = playlistProvider.playlists;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: AppTheme.background,
          expandedHeight: 80,
          flexibleSpace: FlexibleSpaceBar(
            background: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('재생목록',
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showCreateDialog(context),
                      icon: Icon(Icons.add, color: primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (playlists.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_add,
                      size: 72, color: primaryColor.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('재생목록이 없습니다',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('+ 버튼을 눌러 만들어보세요',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildPlaylistTile(context, playlists[index], primaryColor);
                },
                childCount: playlists.length,
              ),
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }

  Widget _buildPlaylistTile(BuildContext context, Playlist playlist, Color primaryColor) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistDetailScreen(playlist: playlist),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.surfaceVariant,
                    primaryColor.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.playlist_play, color: primaryColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playlist.name,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text('${playlist.songCount}곡',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.textHint),
              color: AppTheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => [
                _buildPopupItem(Icons.edit, '이름 변경', 'rename', primaryColor),
                _buildPopupItem(Icons.delete, '삭제', 'delete', primaryColor),
              ],
              onSelected: (value) {
                if (value == 'rename') {
                  _showRenameDialog(context, playlist);
                } else if (value == 'delete') {
                  _showDeleteDialog(context, playlist);
                }
              },
            ),
          ],
        ),
      ),
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

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text('새 재생목록',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: '재생목록 이름',
            hintStyle: const TextStyle(color: AppTheme.textHint),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소',
                style: TextStyle(color: AppTheme.textHint)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<PlaylistProvider>().createPlaylist(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: Text('만들기', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Playlist playlist) {
    final controller = TextEditingController(text: playlist.name);
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text('이름 변경',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소',
                style: TextStyle(color: AppTheme.textHint)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<PlaylistProvider>().renamePlaylist(
                    playlist.id, controller.text);
                Navigator.pop(ctx);
              }
            },
            child: Text('변경', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Playlist playlist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text('재생목록 삭제',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('${playlist.name}을 삭제할까요?',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소',
                style: TextStyle(color: AppTheme.textHint)),
          ),
          TextButton(
            onPressed: () {
              context.read<PlaylistProvider>().deletePlaylist(playlist.id);
              Navigator.pop(ctx);
            },
            child: const Text('삭제',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.background,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios,
                  color: AppTheme.textPrimary),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primaryColor.withOpacity(0.3),
                      AppTheme.background,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.surfaceVariant,
                            primaryColor.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.playlist_play,
                          color: primaryColor, size: 50),
                    ),
                    const SizedBox(height: 8),
                    Text(playlist.name,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text('${playlist.songCount}곡',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          if (playlist.songs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_note,
                        size: 64,
                        color: AppTheme.textHint.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text('곡이 없습니다',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('곡 목록에서 추가해보세요',
                        style: TextStyle(
                            color: AppTheme.textHint, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return SongListTile(
                      song: playlist.songs[index],
                      index: index,
                      songList: playlist.songs,
                    );
                  },
                  childCount: playlist.songs.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      bottomSheet: playlist.songs.isEmpty
          ? null
          : _buildPlayAllButton(context, primaryColor),
    );
  }

  Widget _buildPlayAllButton(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.background,
      child: ElevatedButton(
        onPressed: () {
          context.read<PlayerProvider>().playFromList(playlist.songs, 0);
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
        ),
        child: const Text('전체 재생',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}