//import 'package:uuid/uuid.dart';
import 'dart:io';

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