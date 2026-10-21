import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/place.dart';

class UserPlacesNotifier extends Notifier<List<Place>> {
  @override
  List<Place> build() {
    return [];
  }

  void addPlace(String title, File image) {
    final newPlace = Place(
      id: const Uuid().v4(),
      title: title,
      image: image,
    );

    state = [newPlace, ...state];
  }
}

final userPlacesProvider =
    NotifierProvider<UserPlacesNotifier, List<Place>>(
  UserPlacesNotifier.new,
);