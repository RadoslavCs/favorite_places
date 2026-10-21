import 'package:uuid/uuid.dart';
import 'dart:io';

const uuid = Uuid();

class PlaceLocation {
  final double latitude;
  final double longitude;
  final String address;

  const PlaceLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class Place {
  Place({
    required this.id,
    required this.title,
    required this.image,
  });

  final String id;
  final String title;
  final File image;
}