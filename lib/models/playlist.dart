import 'song.dart';

class Playlist {
  final String id;
  String name;
  List<Song> songs;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    required this.songs,
    required this.createdAt,
  });

  int get songCount => songs.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songIds': songs.map((s) => s.id).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}