import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_list_tile.dart';

class RecentScreen extends StatelessWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final recentSongs = musicProvider.recentSongs;
    final primaryColor = Theme.of(context).colorScheme.primary;

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
                    const Text('최근 재생',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text('${recentSongs.length}곡',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (recentSongs.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history,
                      size: 72, color: primaryColor.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('최근 재생한 곡이 없습니다',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('음악을 재생해보세요',
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
                  return SongListTile(
                    song: recentSongs[index],
                    index: index,
                    songList: recentSongs,
                  );
                },
                childCount: recentSongs.length,
              ),
            ),
          ),
        if (recentSongs.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: ElevatedButton(
                onPressed: () {
                  context.read<PlayerProvider>().playFromList(recentSongs, 0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('전체 재생',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }
}