import 'song.dart';

class Album {
  final String name;
  final String artist;
  final List<Song> songs;

  const Album({
    required this.name,
    required this.artist,
    required this.songs,
  });

  String get displayName => name.isEmpty ? '알 수 없는 앨범' : name;
  String get displayArtist => artist.isEmpty ? '알 수 없는 아티스트' : artist;
  int get songCount => songs.length;
}