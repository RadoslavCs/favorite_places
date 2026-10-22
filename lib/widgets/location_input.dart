import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import '../models/place.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:favorite_places/screens/map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationInput extends StatefulWidget {
  const LocationInput({super.key, required this.onSelectLocation});

  final void Function(PlaceLocation location) onSelectLocation;

  @override
  State<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  PlaceLocation? pickedLocation;
  var isGettingLocation = false;

  Future<void> _selectOnMap() async {
    final selectedLocation = await Navigator.of(context)
        .push<LatLng>(MaterialPageRoute(builder: (ctx) => const MapScreen()));

    if (selectedLocation == null || !mounted) {
      return;
    }

    await _savePlace(selectedLocation.latitude, selectedLocation.longitude);
  }

  String get locationImage {
    if (pickedLocation == null) {
      return '';
    }

    final lat = pickedLocation!.latitude;
    final lng = pickedLocation!.longitude;
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng'
        '&zoom=16'
        '&size=600x300'
        '&maptype=roadmap'
        '&markers=color:red%7Clabel:A%7C$lat,$lng'
        '&key=$apiKey';
  }

  Future<void> _getCurrentLocation() async {
    final location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    final locationData = await location.getLocation();

    final lat = locationData.latitude;
    final lng = locationData.longitude;

    if (!mounted) {
      return;
    }

    await _savePlace(lat, lng);
  }

  Future<void> _savePlace(double latitude, double longitude) async {
    setState(() {
      isGettingLocation = true;
    });

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

    final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$latitude,$longitude',
      'key': apiKey ?? '',
    });

    http.Response response;

    try {
      response = await http.get(url).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Chyba pri komunikacii s Google API: $e');

      if (!mounted) return;

      setState(() {
        isGettingLocation = false;
      });
      return;
    }

    if (!mounted) return;

    if (response.statusCode != 200) {
      debugPrint('Google API HTTP error: ${response.statusCode}');

      setState(() {
        isGettingLocation = false;
      });
      return;
    }

    try {
      final resData = json.decode(response.body);

      if (resData['status'] == 'OK' &&
          (resData['results'] as List).isNotEmpty) {
        final address = resData['results'][0]['formatted_address'] as String;

        final newLocation = PlaceLocation(
          latitude: latitude,
          longitude: longitude,
          address: address,
        );

        setState(() {
          pickedLocation = newLocation;
          isGettingLocation = false;
        });

        widget.onSelectLocation(newLocation);

        debugPrint('Latitude: $latitude, Longitude: $longitude');
        debugPrint('Address: $address');
      } else {
        debugPrint('Geocoding error: ${resData['status']}');

        setState(() {
          isGettingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Chyba pri spracovani odpovede: $e');

      if (!mounted) return;

      setState(() {
        isGettingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget previewContent = const Text(
      'No location chosen.',
      textAlign: TextAlign.center,
    );

    if (isGettingLocation) {
      previewContent = const CircularProgressIndicator();
    } else if (pickedLocation != null) {
      previewContent = Image.network(
        locationImage,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return Column(
      children: [
        Container(
          alignment: Alignment.center,
          height: 170,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              width: 1,
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.2),
            ),
          ),
          child: previewContent,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.location_on),
              label: const Text('Get Current Location'),
            ),
            TextButton.icon(
              onPressed: isGettingLocation ? null : _selectOnMap,
              icon: const Icon(Icons.map),
              label: const Text('Select on Map'),
            ),
          ],
        ),
      ],
    );
  }
}
