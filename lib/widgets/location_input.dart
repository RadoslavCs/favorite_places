import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/place.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationInput extends StatefulWidget {
  const LocationInput({super.key, required this.onSelectLocation});

  final void Function(PlaceLocation location) onSelectLocation;

  @override
  State<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  PlaceLocation? pickedLocation;
  var isGettingLocation = false;

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

    setState(() {
      isGettingLocation = true;
    });

    final locationData = await location.getLocation();

    final lat = locationData.latitude;
    final lng = locationData.longitude;

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey',
    );

    final response = await http.get(url);
    final resData = json.decode(response.body);

    print('Geocoding status: ${resData['status']}');

    if (resData['status'] == 'OK' && (resData['results'] as List).isNotEmpty) {
      final address = resData['results'][0]['formatted_address'];

      if (!mounted) return;

      /*setState(() {
        isGettingLocation = false;
        pickedLocation = PlaceLocation(
          latitude: lat,
          longitude: lng,
          address: address,
        );
      });*/

      final newLocation = PlaceLocation(
        latitude: lat,
        longitude: lng,
        address: address,
      );

      setState(() {
        isGettingLocation = false;
        pickedLocation = newLocation;
      });

      widget.onSelectLocation(
        newLocation,
      ); // 🔁 odoslanie polohy do parent widgetu

      print('Latitude: $lat, Longitude: $lng');
      print('Address: $address');
    } else {
      if (!mounted) return;

      setState(() {
        isGettingLocation = false;
      });

      print('Geocoding error: ${resData['error_message']}');
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
              onPressed: () {},
              icon: const Icon(Icons.map),
              label: const Text('Select on Map'),
            ),
          ],
        ),
      ],
    );
  }
}
