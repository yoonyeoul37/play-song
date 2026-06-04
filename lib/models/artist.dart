import 'song.dart';

class Artist {
  final String name;
  final List<Song> songs;

  const Artist({
    required this.name,
    required this.songs,
  });

  String get displayName => name.isEmpty ? '알 수 없는 아티스트' : name;
  int get songCount => songs.length;
  int get albumCount => songs.map((s) => s.albumDisplay).toSet().length;
}