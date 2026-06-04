import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/album.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_list_tile.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final albums = musicProvider.albums;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (albums.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.album, size: 72, color: AppTheme.textHint),
            SizedBox(height: 16),
            Text('앨범이 없습니다',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: AppTheme.background,
          expandedHeight: 80 * MediaQuery.of(context).textScaler.scale(1.0),
          flexibleSpace: FlexibleSpaceBar(
            background: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('앨범',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    Text('${albums.length}개',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildAlbumCard(context, albums[index], primaryColor);
              },
              childCount: albums.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }

  Widget _buildAlbumCard(BuildContext context, album, Color primaryColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailScreen(album: album),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.surfaceVariant,
                        primaryColor.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: album.songs.first.albumArt != null
                      ? Image.memory(
                          Uint8List.fromList(album.songs.first.albumArt!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          gaplessPlayback: true,
                        )
                      : Center(
                          child: Icon(Icons.album,
                              color: primaryColor.withOpacity(0.7),
                              size: 56),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(album.displayName,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(album.displayArtist,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${album.songCount}곡',
                      style: const TextStyle(
                          color: AppTheme.textHint, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlbumDetailScreen extends StatelessWidget {
  final album;

  const AlbumDetailScreen({super.key, required this.album});

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
                    Icon(Icons.album,
                        color: primaryColor.withOpacity(0.8), size: 80),
                    const SizedBox(height: 8),
                    Text(album.displayName,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text(album.displayArtist,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return SongListTile(
                    song: album.songs[index],
                    index: index,
                    songList: album.songs,
                  );
                },
                childCount: album.songs.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      bottomSheet: _buildPlayAllButton(context, primaryColor),
    );
  }

  Widget _buildPlayAllButton(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.background,
      child: ElevatedButton(
        onPressed: () {
          context.read<PlayerProvider>().playFromList(album.songs, 0);
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