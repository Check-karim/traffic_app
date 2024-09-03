import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:open_route_service/open_route_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MapController mapController = MapController();
  LocationData? currentLocation;
  Location location = Location();
  TextEditingController destinationController = TextEditingController();
  List<LatLng> routePoints = [];
  List<String> destinationSuggestions = [];
  bool showSuggestions = false;

  final OpenRouteService client = OpenRouteService(apiKey: '5b3ce3597851110001cf624831003f4bc35c47fa8d6c2b66260fc127'); // Replace with your OpenRouteService API key

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  void getLocation() async {
    LocationData? locationData;
    try {
      locationData = await location.getLocation();
    } catch (e) {
      print('Error getting location: $e');
      locationData = null;
      showErrorMessage(
          'Failed to get location. Please check your GPS settings.');
    }

    setState(() {
      currentLocation = locationData;
      if (currentLocation != null) {
        mapController.move(
          LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          14.0,
        );
      }
    });
  }

  Future<void> fetchSuggestions(String query) async {
    final locationUrl =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json';
    try {
      final response = await http.get(Uri.parse(locationUrl), headers: {
        'User-Agent': 'MOVE TRAFFIC APP', // Replace with your app name
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          destinationSuggestions =
              data.map((item) => item['display_name']).toList().cast<String>();
          showSuggestions = true; // Show suggestions when data is fetched
        });
      } else {
        showErrorMessage(
            'Failed to fetch suggestions. Please try again later.');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      showErrorMessage('Failed to fetch suggestions. Please try again later.');
    }
  }

  Future<void> searchDestination(String destination) async {
    final locationUrl =
        'https://nominatim.openstreetmap.org/search?q=$destination&format=json';
    try {
      final response = await http.get(Uri.parse(locationUrl), headers: {
        'User-Agent': 'Flutter App', // Replace with your app name
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final double lat = double.parse(data[0]['lat']);
          final double lon = double.parse(data[0]['lon']);
          await getRoute(LatLng(lat, lon)); // Call getRoute asynchronously
          setState(() {
            showSuggestions =
            false; // Hide suggestions after selecting destination
          });
        } else {
          showErrorMessage('Destination not found.');
        }
      } else {
        showErrorMessage(
            'Failed to search destination. Please try again later.');
      }
    } catch (e) {
      print('Error searching destination: $e');
      showErrorMessage('Failed to search destination. Please try again later.');
    }
  }

  Future<void> getRoute(LatLng destination) async {
    if (currentLocation == null) return;

    try {
      // Define your start and end coordinates
      final coordinates = [
        ORSCoordinate(latitude: currentLocation!.latitude!, longitude: currentLocation!.longitude!),
        ORSCoordinate(latitude: destination.latitude, longitude: destination.longitude),
      ];

      // Get the route
      final route = await client.directionsRouteCoordsGet(
        startCoordinate: coordinates[0],
        endCoordinate: coordinates[1],
      );

      setState(() {
        routePoints = route.map((coord) => LatLng(coord.latitude, coord.longitude)).toList();
      });

    } catch (e) {
      print('Error getting route: $e');
      showErrorMessage('Failed to get route. Please try again later.');
    }
  }

  void showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MOVE TRAFFIC APP'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: destinationController,
              onChanged: (value) {
                fetchSuggestions(value);
              },
              decoration: InputDecoration(
                hintText: 'Enter destination',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    searchDestination(destinationController.text);
                  },
                ),
              ),
            ),
          ),
          if (showSuggestions)
            Expanded(
              child: ListView.builder(
                itemCount: destinationSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = destinationSuggestions[index];
                  return ListTile(
                    title: Text(suggestion),
                    onTap: () {
                      destinationController.text = suggestion;
                      searchDestination(suggestion);
                    },
                  );
                },
              ),
            ),
          Expanded(
            flex: 3,
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                center: currentLocation != null
                    ? LatLng(
                    currentLocation!.latitude!, currentLocation!.longitude!)
                    : LatLng(37.7749, -122.4194), // Default to San Francisco if location is null
                zoom: 14.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                if (currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: LatLng(
                          currentLocation!.latitude!,
                          currentLocation!.longitude!,
                        ),
                        builder: (ctx) => Container(
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        color: Colors.blue,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
