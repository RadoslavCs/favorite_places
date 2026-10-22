import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/place.dart';

Future<Database> _getDatabase() async {
  final dbPath = await getDatabasesPath();

  final db = await openDatabase(
    path.join(dbPath, 'places.db'),
    version: 1,
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE user_places('
        'id TEXT PRIMARY KEY, '
        'title TEXT, '
        'image TEXT, '
        'lat REAL, '
        'lng REAL, '
        'address TEXT'
        ')',
      );
    },
  );

  return db;
}

class UserPlacesNotifier extends StateNotifier<List<Place>> {
  UserPlacesNotifier() : super(const []);

  Future<void> addPlace(
    String title,
    File image,
    PlaceLocation location,
  ) async {
    final appDir = await getApplicationDocumentsDirectory();

    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}_${path.basename(image.path)}';

    final savedImage = await image.copy(path.join(appDir.path, fileName));

    final newPlace = Place(title: title, image: savedImage, location: location);

    try {
      final db = await _getDatabase();

      await db.insert('user_places', {
        'id': newPlace.id,
        'title': newPlace.title,
        'image': savedImage.path,
        'lat': newPlace.location.latitude,
        'lng': newPlace.location.longitude,
        'address': newPlace.location.address,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      state = [newPlace, ...state];
    } catch (e) {
      // Ak databázový zápis zlyhá, odstránime novú kópiu obrázka.
      if (await savedImage.exists()) {
        await savedImage.delete();
      }
      rethrow;
    }
  }

  Future<void> loadPlaces() async {
    final db = await _getDatabase();

    final data = await db.query('user_places', orderBy: 'rowid DESC');

    final places = data.map((row) {
      return Place(
        id: row['id'] as String,
        title: row['title'] as String,
        image: File(row['image'] as String),
        location: PlaceLocation(
          latitude: row['lat'] as double,
          longitude: row['lng'] as double,
          address: row['address'] as String,
        ),
      );
    }).toList();

    state = places;
  }
}

final userPlacesProvider =
    StateNotifierProvider<UserPlacesNotifier, List<Place>>(
      (ref) => UserPlacesNotifier(),
    );
